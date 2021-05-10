// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

//! Binary translation

use crate::{
    engine::{AtomicOp, Engine, TraceAccess},
    riscv,
};
use anyhow::{anyhow, bail, Context, Result};
use llvm_sys::{
    core::*, debuginfo::*, prelude::*, LLVMAtomicOrdering::*, LLVMAtomicRMWBinOp::*,
    LLVMIntPredicate::*, LLVMRealPredicate::*,
};
use std::{
    cell::{Cell, RefCell},
    collections::{BTreeSet, HashMap},
    ffi::CString,
};

static NONAME: &'static i8 = unsafe { std::mem::transmute("\0".as_ptr()) };

/// Base address of the stream semantic regsiters
static SSR_BASE: u64 = 0x204800;
static SSR_N_STREAMERS: u32 = 2;

/// Number of arguments the trace maximally shows per instruction.
const TRACE_BUFFER_LEN: u32 = 8;

/// The length of a sequencer's instruction ring buffer.
const SEQ_BUFFER_LEN: u8 = 16;

/// The sequencer's JIT iterators for loop emulation.
struct SequencerIterators {
    /// A u32* pointing to the repetition index.
    rpt_ptr_ref: LLVMValueRef,
    /// A u32* pointing to the repetition maximum.
    max_rpt_ref: LLVMValueRef,
}

/// The sequencer's context during section-level translation.
struct SequencerContext {
    /// Whether the sequencer is currently buffering instructions
    active: bool,
    /// The biggest instruction index to buffer.
    max_inst: u8,
    /// Whether repetition is block-first or instruction-first.
    is_outer: bool,
    /// The maximum stagger index.
    stagger_max: u8,
    /// A mask indicating which register numbers to stagger.
    stagger_mask: u8,
    /// The addresses for the instruction basic blocks buffered.
    inst_buffer: [(u64, riscv::Format); SEQ_BUFFER_LEN as usize],
    /// The current buffer insertion point.
    buffer_pos: u8,
}

impl SequencerContext {
    /// Create a new sequencer context.
    fn new() -> Self {
        SequencerContext {
            active: false,
            max_inst: 0,
            is_outer: false,
            stagger_max: 0,
            stagger_mask: 0,
            inst_buffer: [(0, riscv::Format::Illegal(0)); SEQ_BUFFER_LEN as usize],
            buffer_pos: 0,
        }
    }

    /// Initialize a sequence job.
    fn init_rep(
        &mut self,
        max_inst: u8,
        is_outer: bool,
        stagger_max: u8,
        stagger_mask: u8,
    ) -> Result<()> {
        if !self.active {
            self.active = true;
            self.max_inst = max_inst;
            self.is_outer = is_outer;
            self.stagger_mask = stagger_mask;
            self.stagger_max = stagger_max;
            self.buffer_pos = 0;
            if max_inst < SEQ_BUFFER_LEN {
                Ok(())
            } else {
                Err(anyhow!(
                    "Sequencer buffer not large enough: set {}, max {}",
                    max_inst,
                    SEQ_BUFFER_LEN
                ))
            }
        } else {
            Err(anyhow!("Illegal sequencer repetition nesting"))
        }
    }

    /// Push an instruction into the sequence buffer.
    fn push_rep_instruction(&mut self, addr: u64, inst: riscv::Format) -> Result<()> {
        if self.active {
            if self.buffer_pos <= self.max_inst {
                self.inst_buffer[self.buffer_pos as usize] = (addr, inst);
                self.buffer_pos += 1;
                Ok(())
            } else {
                Err(anyhow!(
                    "Sequence overflow: pos {}, max {}",
                    self.buffer_pos,
                    self.max_inst
                ))
            }
        } else {
            Err(anyhow!("No active sequence"))
        }
    }

    /// Whether repetition body is complete and ready for loop emission.
    fn is_body_complete(&self) -> bool {
        self.buffer_pos == self.max_inst + 1
    }
}

/// A translator for an entire ELF file.
pub struct ElfTranslator<'a> {
    pub elf: &'a elf::File,
    /// The translation engine.
    pub engine: &'a Engine,
    /// The debug info builder.
    pub di_builder: LLVMDIBuilderRef,
    /// The root compile unit debug info.
    pub di_cu: LLVMMetadataRef,
    /// The root file debug info.
    pub di_file: LLVMMetadataRef,
    /// Predicted branch target addresses.
    pub target_addrs: BTreeSet<u64>,
    /// Symbol name hints.
    pub symbol_hints: HashMap<u64, String>,
    /// Basic blocks for each instruction address.
    pub inst_bbs: HashMap<u64, LLVMBasicBlockRef>,
    /// Generate instruction tracing code.
    pub trace: bool,
    /// Generate instruction tracing code.
    pub latency: bool,
    /// Start address of the fast local scratchpad.
    pub tcdm_start: u32,
    /// End address of the fast local scratchpad.
    pub tcdm_end: u32,
}

impl<'a> ElfTranslator<'a> {
    /// Create a new ELF file translator.
    pub fn new(elf: &'a elf::File, engine: &'a Engine) -> Self {
        // Create the root debugging information.
        let (di_builder, di_cu, di_file) = unsafe {
            let dir_name = ".";
            let file_name = "binary.riscv";
            let producer = "banshee";

            let di_builder = LLVMCreateDIBuilder(engine.module);
            let di_file = LLVMDIBuilderCreateFile(
                di_builder,
                file_name.as_ptr() as *const _,
                file_name.len(),
                dir_name.as_ptr() as *const _,
                dir_name.len(),
            );
            let di_cu = LLVMDIBuilderCreateCompileUnit(
                di_builder,                                        // Builder
                LLVMDWARFSourceLanguage::LLVMDWARFSourceLanguageC, // Lang
                di_file,                                           // FileRef
                producer.as_ptr() as *const _,                     // Producer
                producer.len(),                                    // ProducerLen
                0,                                                 // isOptimized
                std::ptr::null(),                                  // Flags
                0,                                                 // FlagsLen
                0,                                                 // RuntimeVer
                std::ptr::null(),                                  // SplitName
                0,                                                 // SplitNameLen
                LLVMDWARFEmissionKind::LLVMDWARFEmissionKindFull,  // Kind
                0,                                                 // DWOId
                1,                                                 // SplitDebugInlining
                1,                                                 // DebugInfoForProfiling
            );
            (di_builder, di_cu, di_file)
        };

        Self {
            elf,
            engine,
            di_builder,
            di_cu,
            di_file,
            target_addrs: Default::default(),
            symbol_hints: Default::default(),
            inst_bbs: Default::default(),
            trace: engine.trace,
            latency: engine.latency,
            tcdm_start: engine.config.memory.tcdm.start,
            tcdm_end: engine.config.memory.tcdm.end,
        }
    }

    /// Get an iterator over the sections in the binary.
    pub fn sections(&self) -> impl Iterator<Item = &'a elf::Section> + '_ {
        self.elf
            .sections
            .iter()
            .filter(|section| (section.shdr.flags.0 & elf::types::SHF_EXECINSTR.0) != 0)
    }

    /// Get an iterator over the instructions in a section.
    pub fn instructions(
        &self,
        section: &'a elf::Section,
    ) -> impl Iterator<Item = (u64, riscv::Format)> + '_ {
        section
            .data
            .chunks(4)
            .enumerate()
            .map(move |(i, raw)| (section.shdr.addr + i as u64 * 4, riscv::parse(raw)))
    }

    /// Get an iterator over the `.symtab` sections.
    pub fn symtab_sections(&self) -> impl Iterator<Item = &'a elf::Section> + '_ {
        self.elf
            .sections
            .iter()
            .filter(|section| section.shdr.shtype == elf::types::SHT_SYMTAB)
    }

    /// Get an iterator over all instructions in the binary.
    pub fn all_instructions(&self) -> impl Iterator<Item = (u64, riscv::Format)> + '_ {
        self.sections().flat_map(move |s| self.instructions(s))
    }

    /// Analyze the binary and estimate the set of possible branch target
    /// addresses.
    pub fn update_target_addrs(&mut self) {
        let mut target_addrs = BTreeSet::new();
        let mut symbol_hints = HashMap::new();

        // Ensure that we can jump to the entry symbol.
        target_addrs.insert(self.elf.ehdr.entry);

        // Ensure that we can jump to the beginning of a section.
        for section in self.sections() {
            target_addrs.insert(section.shdr.addr);
        }

        // Ensure that we can jump to the beginning of symbols.
        let symbols = self
            .symtab_sections()
            .flat_map(|section| self.elf.get_symbols(section))
            .fold(vec![], |a, mut b| {
                b.extend(a);
                b
            });
        trace!("Loaded {} symbols", symbols.len());
        for sym in symbols {
            if sym.symtype == elf::types::STT_FUNC {
                debug!("Found symbol 0x{:x}: {}", sym.value, sym.name);
                target_addrs.insert(sym.value);
                symbol_hints.insert(sym.value, sym.name);
            }
        }

        // Estimate target addresses.
        for (addr, inst) in self.all_instructions() {
            match inst {
                riscv::Format::Imm12RdRs1(
                    fmt
                    @
                    riscv::FormatImm12RdRs1 {
                        op: riscv::OpcodeImm12RdRs1::Jalr,
                        ..
                    },
                ) => {
                    debug!("Found register jump 0x{:x}: {}", addr, inst);

                    // If we keep the PC around, we expect to jump back to the
                    // next instruction at some point.
                    if fmt.rd != 0 {
                        target_addrs.insert(addr + 4);
                    }
                }
                riscv::Format::Jimm20Rd(
                    fmt
                    @
                    riscv::FormatJimm20Rd {
                        op: riscv::OpcodeJimm20Rd::Jal,
                        ..
                    },
                ) => {
                    // Ensure that we can branch to the target address.
                    let target = (addr as i64).wrapping_add(fmt.jimm() as i64) as u64;
                    debug!(
                        "Found immediate jump 0x{:x}: {} to 0x{:x}",
                        addr, inst, target,
                    );
                    target_addrs.insert(target);

                    // If we keep the PC around, we expect to jump back to the
                    // next instruction at some point.
                    if fmt.rd != 0 {
                        target_addrs.insert(addr + 4);
                    }
                }
                riscv::Format::Bimm12hiBimm12loRs1Rs2(fmt) => {
                    let target = (addr as i64).wrapping_add(fmt.bimm() as i64) as u64;
                    debug!("Found branch 0x{:x}: {} to 0x{:x}", addr, inst, target,);
                    target_addrs.insert(target);
                    target_addrs.insert(addr + 4);
                }
                _ => (),
            }
        }

        // Dump what we have found.
        trace!("Predicted jump targets:");
        for &addr in &target_addrs {
            trace!("  - 0x{:x}", addr);
        }

        self.target_addrs = target_addrs;
        self.symbol_hints = symbol_hints;
    }

    /// Translate the binary.
    pub fn translate(&mut self) -> Result<()> {
        unsafe { self.translate_inner() }
    }

    unsafe fn translate_inner(&mut self) -> Result<()> {
        debug!("Translating binary");
        let builder = LLVMCreateBuilderInContext(self.engine.context);

        // Assemble the struct type which holds the CPU state.
        let state_type = LLVMGetTypeByName(self.engine.module, "Cpu\0".as_ptr() as *const _);
        let state_ptr_type = LLVMPointerType(state_type, 0u32);

        // Emit the function which will run the binary.
        let func_name = format!("execute_binary\0");
        let func_type = LLVMFunctionType(LLVMVoidType(), [state_ptr_type].as_mut_ptr(), 1, 0);
        let func = LLVMAddFunction(
            self.engine.module,
            func_name.as_ptr() as *const _,
            func_type,
        );
        let state_ptr = LLVMGetParam(func, 0);

        // Emit the subprogram debug information for this function.
        // let di_builder = LLVMCreateDIBuilder(self.engine.module);
        let di_builder = self.di_builder;
        let di_name = "execute_binary";
        let di_linkage_name = "execute_binary";
        let di_scope = LLVMDIBuilderCreateFunction(
            di_builder,                           // Builder
            self.di_file,                         // Scope
            di_name.as_ptr() as *const _,         // Name
            di_name.len(),                        // NameLen
            di_linkage_name.as_ptr() as *const _, // LinkageName
            di_linkage_name.len(),                // LinkageNameLen
            self.di_file,                         // File
            0,                                    // LineNo
            LLVMDIBuilderCreateSubroutineType(
                di_builder,
                self.di_file,
                [].as_mut_ptr(),
                0,
                LLVMDIFlagZero,
            ), // Ty
            0,                                    // IsLocalToUnit
            1,                                    // IsDefinition
            0,                                    // ScopeLine
            LLVMDIFlagPrototyped,                 // Flags
            0,                                    // IsOptimized
        );
        LLVMSetSubprogram(func, di_scope);
        let di_loc = LLVMDIBuilderCreateDebugLocation(
            self.engine.context,  // Ctx
            0,                    // Line
            0,                    // Column
            di_scope,             // Scope
            std::ptr::null_mut(), // InlinedAt
        );
        LLVMSetCurrentDebugLocation2(builder, di_loc);

        // Create the entry block.
        let entry_bb = LLVMAppendBasicBlockInContext(
            self.engine.context,
            func,
            b"entry\0".as_ptr() as *const _,
        );
        LLVMPositionBuilderAtEnd(builder, entry_bb);

        // Allocate space for tracing data, if needed.
        let (trace_access_buffer, trace_data_buffer) = if self.trace {
            (
                LLVMBuildAlloca(
                    builder,
                    LLVMArrayType(LLVMInt16Type(), TRACE_BUFFER_LEN),
                    NONAME,
                ),
                LLVMBuildAlloca(
                    builder,
                    LLVMArrayType(LLVMInt64Type(), TRACE_BUFFER_LEN),
                    NONAME,
                ),
            )
        } else {
            (std::ptr::null_mut(), std::ptr::null_mut())
        };

        // Allocate the sequencer iterators and init them as pointing to a zero constant.
        let const_zero_32 = LLVMConstInt(LLVMInt32Type(), 0, 0);
        let rpt_ptr_ref = LLVMBuildAlloca(
            builder,
            LLVMInt32Type(),
            b"frep_rpt_ptr\0".as_ptr() as *const _,
        );
        LLVMBuildStore(builder, const_zero_32, rpt_ptr_ref);
        let max_rpt_ref = LLVMBuildAlloca(
            builder,
            LLVMInt32Type(),
            b"frep_max_rpt\0".as_ptr() as *const _,
        );
        LLVMBuildStore(builder, const_zero_32, max_rpt_ref);
        let fseq_iter = SequencerIterators {
            rpt_ptr_ref,
            max_rpt_ref,
        };

        // Gather the set of executable addresses.
        let inst_addrs: BTreeSet<u64> = self
            .all_instructions()
            .map(|(addr, _)| addr)
            .chain(self.sections().map(|section| section.shdr.addr))
            .chain(
                self.sections()
                    .map(|section| section.shdr.addr + section.shdr.size),
            )
            .collect();

        // Create a basic block for every instruction address.
        let inst_bbs: HashMap<u64, LLVMBasicBlockRef> = inst_addrs
            .iter()
            .map(|&addr| {
                let name = match self.symbol_hints.get(&addr) {
                    Some(sym) => format!("{}_0x{:x}\0", sym, addr),
                    None => format!("inst_0x{:x}\0", addr),
                };
                let bb = LLVMAppendBasicBlockInContext(
                    self.engine.context,
                    func,
                    name.as_ptr() as *const _,
                );
                (addr, bb)
            })
            .collect();
        self.inst_bbs = inst_bbs;

        // Create a block for the fallback indirect jump table.
        let indirect_target_var = LLVMBuildAlloca(
            builder,
            LLVMInt32Type(),
            b"indirect_target\0".as_ptr() as *const _,
        );
        let indirect_addr_var = LLVMBuildAlloca(
            builder,
            LLVMInt32Type(),
            b"indirect_addr\0".as_ptr() as *const _,
        );
        let indirect_fail_bb = LLVMAppendBasicBlockInContext(
            self.engine.context,
            func,
            b"indirect_fail\0".as_ptr() as *const _,
        );
        let indirect_bb = LLVMAppendBasicBlockInContext(
            self.engine.context,
            func,
            b"indirect\0".as_ptr() as *const _,
        );
        LLVMPositionBuilderAtEnd(builder, indirect_bb);

        // Emit the switch statement with all branch targets.
        let indirect_target = LLVMBuildLoad(builder, indirect_target_var, NONAME);
        let sw = LLVMBuildSwitch(
            builder,
            indirect_target,
            indirect_fail_bb,
            inst_addrs.len() as u32,
        );
        for &addr in &inst_addrs {
            LLVMAddCase(
                sw,
                LLVMConstInt(LLVMInt32Type(), addr as u64, 0),
                self.inst_bbs[&addr],
            );
        }

        // Emit the illegal branch code.
        LLVMPositionBuilderAtEnd(builder, indirect_fail_bb);
        let indirect_addr = LLVMBuildLoad(builder, indirect_addr_var, NONAME);
        LLVMBuildCall(
            builder,
            LLVMGetNamedFunction(
                self.engine.module,
                "banshee_abort_illegal_branch\0".as_ptr() as *const _,
            ),
            [state_ptr, indirect_addr, indirect_target].as_mut_ptr(),
            3,
            NONAME,
        );
        LLVMBuildRetVoid(builder);
        LLVMPositionBuilderAtEnd(builder, entry_bb);

        // Emit the branch to the entry symbol.
        match self.inst_bbs.get(&self.elf.ehdr.entry) {
            Some(&bb) => {
                LLVMBuildBr(builder, bb);
            }
            None => {
                error!("No instruction at entry point 0x{:x}", self.elf.ehdr.entry);
                LLVMBuildBr(builder, entry_bb);
            }
        }

        // Emit the instructions for each section.
        let mut last_section_tran = None;
        let mut inst_index = 0;
        for section in self.sections() {
            debug!("Translating section `{}`", section.shdr.name);
            let tran = SectionTranslator {
                elf: self,
                section,
                engine: self.engine,
                di_scope,
                state_ptr,
                trace_access_buffer,
                trace_data_buffer,
                builder,
                addr_start: section.shdr.addr,
                addr_end: section.shdr.addr + section.shdr.size,
                indirect_target_var,
                indirect_addr_var,
                indirect_bb,
                fseq_iter: &fseq_iter,
            };
            tran.emit(&mut inst_index)?;
            last_section_tran = Some(tran);
        }

        // Emit escape abort code into all unpopulated instruction locations.
        for (&addr, &bb) in &self.inst_bbs {
            if LLVMGetBasicBlockTerminator(bb).is_null() {
                trace!("Plugging instruction slot hole at 0x{:x}", addr);
                LLVMPositionBuilderAtEnd(builder, bb);
                last_section_tran
                    .as_ref()
                    .expect("missing section; can't emit escape abort")
                    .emit_escape_abort(addr);
            }
        }

        // Clean up.
        LLVMDIBuilderFinalize(di_builder);
        LLVMDisposeBuilder(builder);
        Ok(())
    }

    unsafe fn lookup_func(&self, name: &str) -> LLVMValueRef {
        let n = CString::new(name).unwrap();
        let ptr = LLVMGetNamedFunction(self.engine.module, n.as_ptr() as *const _);
        assert!(
            !ptr.is_null(),
            "function `{}` not found in LLVM module",
            name
        );
        ptr
    }
}

/// A translator for a section.
pub struct SectionTranslator<'a> {
    elf: &'a ElfTranslator<'a>,
    section: &'a elf::Section,
    engine: &'a Engine,
    /// The debug info scope for additional debug info emitted in the section.
    di_scope: LLVMMetadataRef,
    /// An LLVM value that holds the pointer to the CPU state structure.
    state_ptr: LLVMValueRef,
    /// An LLVM value that holds the pointer to the trace access buffer.
    trace_access_buffer: LLVMValueRef,
    /// An LLVM value that holds the pointer to the trace data buffer.
    trace_data_buffer: LLVMValueRef,
    /// The builder to emit instructions with.
    builder: LLVMBuilderRef,
    /// The first address in the section.
    #[allow(dead_code)]
    addr_start: u64,
    /// The point beyond the last address in the section.
    #[allow(dead_code)]
    addr_end: u64,
    /// The alloca variable holding the indirect jump target address.
    indirect_target_var: LLVMValueRef,
    /// The alloca variable holding the indirect jump instruction address.
    indirect_addr_var: LLVMValueRef,
    /// The basic block to branch to to make a fallback indirect jump.
    indirect_bb: LLVMBasicBlockRef,
    /// The JIT-level sequencer iterators.
    fseq_iter: &'a SequencerIterators,
}

impl<'a> SectionTranslator<'a> {
    /// Emit the code to handle the case when the PC lands outside the sections
    /// of the binary.
    unsafe fn emit_escape_abort(&self, addr: u64) {
        trace!("Emit escape abort at 0x{:x}", addr);
        self.emit_call(
            "banshee_abort_escape",
            [
                self.state_ptr,
                LLVMConstInt(LLVMInt32Type(), addr as u64, 0),
            ],
        );
        LLVMBuildRetVoid(self.builder);
    }

    /// Emit the code to handle an illegal instruction.
    unsafe fn emit_illegal_abort(&self, addr: u64, inst: riscv::Format) {
        trace!(
            "Emit illegal instruction abort at 0x{:x} for {}",
            addr,
            inst
        );
        self.emit_call(
            "banshee_abort_illegal_inst",
            [
                self.state_ptr,
                LLVMConstInt(LLVMInt32Type(), addr as u64, 0),
                LLVMConstInt(LLVMInt32Type(), inst.raw() as u64, 0),
            ],
        );
        LLVMBuildRetVoid(self.builder);
    }

    /// Emit the code to handle a branch to an unpredicted instruction.
    #[allow(dead_code)]
    unsafe fn emit_branch_abort(&self, inst_addr: u64, target: LLVMValueRef) {
        trace!("Emit illegal branch abort at 0x{:x}", inst_addr);
        self.emit_call(
            "banshee_abort_illegal_branch",
            [
                self.state_ptr,
                LLVMConstInt(LLVMInt32Type(), inst_addr as u64, 0),
                target,
            ],
        );
        LLVMBuildRetVoid(self.builder);
    }

    /// Emit the code for the remaining iterations of a buffered FREP loop.
    unsafe fn emit_frep(
        &self,
        inst_index: &mut u32,
        fseq: &SequencerContext,
        curr_addr: u64,
    ) -> Result<()> {
        // Create dummy sequencer context for inner use
        let mut fseq_inner = SequencerContext::new();

        if fseq.is_outer {
            // Create basic block for first increment-and-branch ahead of time
            let mut bb_incr_branch = LLVMCreateBasicBlockInContext(self.engine.context, NONAME);

            // Jump to first increment-and-branch block from unterminated last frep instruction block
            if LLVMGetBasicBlockTerminator(LLVMGetInsertBlock(self.builder)).is_null() {
                LLVMBuildBr(self.builder, bb_incr_branch);
            } else {
                error!("Cannot add branch to FREP to already terminated instruction");
            }

            // Create staggered loop bodies if any
            for stg_offs in 1..=(fseq.stagger_max as u32) {
                // Place and start inserting into block for increment-and-branch
                LLVMInsertExistingBasicBlockAfterInsertBlock(self.builder, bb_incr_branch);
                LLVMPositionBuilderAtEnd(self.builder, bb_incr_branch);

                // Load repetition counter from stack.
                let rpt_cnt = LLVMBuildLoad(self.builder, self.fseq_iter.rpt_ptr_ref, NONAME);
                // Load max repetition from stack.
                let max_rpt = LLVMBuildLoad(self.builder, self.fseq_iter.max_rpt_ref, NONAME);
                // Compare to repetition maximum: repeat if less than maximum iteration.
                let rpt_cmp = LLVMBuildICmp(self.builder, LLVMIntULT, rpt_cnt, max_rpt, NONAME);
                // Increment rep counter, store
                let const_one = LLVMConstInt(LLVMTypeOf(rpt_cnt), 1, 0);
                let rpt_cnt_inc = LLVMBuildAdd(self.builder, rpt_cnt, const_one, NONAME);
                LLVMBuildStore(self.builder, rpt_cnt_inc, self.fseq_iter.rpt_ptr_ref);

                // Create basic block for first loop instruction ahead of time
                let mut bb_loop_inst = LLVMCreateBasicBlockInContext(self.engine.context, NONAME);
                // Insert branch terminating the FREP iterations or going to next loop body (following terminator will be omitted).
                LLVMBuildCondBr(
                    self.builder,
                    rpt_cmp,
                    bb_loop_inst,
                    self.elf.inst_bbs[&(curr_addr + 4)],
                );

                // Emit loop body for current stagger offset
                for &(addr, inst_nonstag) in fseq.inst_buffer[0..=(fseq.max_inst as usize)].iter() {
                    // Read register fields
                    let inst_raw = inst_nonstag.raw();
                    let mut rd = (inst_raw >> 7) & 0x1f;
                    let mut rs1 = (inst_raw >> 15) & 0x1f;
                    let mut rs2 = (inst_raw >> 20) & 0x1f;
                    let mut rs3 = (inst_raw >> 27) & 0x1f;
                    // Stagger register fields
                    if fseq.stagger_mask & 0b0001 != 0 {
                        rd = (rd + stg_offs) & 0x1f;
                    }
                    if fseq.stagger_mask & 0b0010 != 0 {
                        rs1 = (rs1 + stg_offs) & 0x1f;
                    }
                    if fseq.stagger_mask & 0b0100 != 0 {
                        rs2 = (rs2 + stg_offs) & 0x1f;
                    }
                    if fseq.stagger_mask & 0b1000 != 0 {
                        rs3 = (rs3 + stg_offs) & 0x1f;
                    }
                    // Assemble, return new instruction
                    const MREST: u32 =
                        0xffff_ffff ^ ((0x1f << 7) | (0x1f << 15) | (0x1f << 20) | (0x1f << 27));
                    let inst = riscv::parse_u32(
                        (inst_raw & MREST) | (rd << 7) | (rs1 << 15) | (rs2 << 20) | (rs3 << 27),
                    );

                    // Create translator for staggered instruction
                    let tran = InstructionTranslator {
                        section: self,
                        builder: self.builder,
                        addr,
                        inst,
                        was_terminator: Default::default(),
                        trace_accesses: Default::default(),
                        trace_emitted: Default::default(),
                        trace_disabled: Default::default(),
                        was_freppable: Default::default(),
                    };
                    // Place and start inserting into premade loop instruction block
                    LLVMInsertExistingBasicBlockAfterInsertBlock(self.builder, bb_loop_inst);
                    LLVMPositionBuilderAtEnd(self.builder, bb_loop_inst);
                    // Emit instruction into loop instruction block
                    match tran.emit(inst_index, &mut fseq_inner) {
                        Ok(()) => (),
                        Err(e) => {
                            error!("{}", e);
                            self.emit_illegal_abort(addr, inst);
                        }
                    }
                    // Create next loop instruction block ahead of time
                    bb_loop_inst = LLVMCreateBasicBlockInContext(self.engine.context, NONAME);
                    // Terminate with branch to next loop instruction block
                    if LLVMGetBasicBlockTerminator(LLVMGetInsertBlock(self.builder)).is_null() {
                        LLVMBuildBr(self.builder, bb_loop_inst);
                    } else {
                        error!("Cannot use terminating instruction inside an FREP");
                    }
                }

                // Use left-over loop instruction block as next increment-and-branch block
                bb_incr_branch = bb_loop_inst;
            }

            // Place and start inserting into final branch-and-increment block pointing back to original loop body
            LLVMInsertExistingBasicBlockAfterInsertBlock(self.builder, bb_incr_branch);
            LLVMPositionBuilderAtEnd(self.builder, bb_incr_branch);

            // Load repetition counter from stack.
            let rpt_cnt = LLVMBuildLoad(self.builder, self.fseq_iter.rpt_ptr_ref, NONAME);
            // Load max repetition from stack.
            let max_rpt = LLVMBuildLoad(self.builder, self.fseq_iter.max_rpt_ref, NONAME);
            // Compare to repetition maximum: repeat if less than maximum iteration.
            let rpt_cmp = LLVMBuildICmp(self.builder, LLVMIntULT, rpt_cnt, max_rpt, NONAME);
            // Increment rep counter, store
            let const_one = LLVMConstInt(LLVMTypeOf(rpt_cnt), 1, 0);
            let rpt_cnt_inc = LLVMBuildAdd(self.builder, rpt_cnt, const_one, NONAME);
            LLVMBuildStore(self.builder, rpt_cnt_inc, self.fseq_iter.rpt_ptr_ref);

            // Insert branch terminating the FREP iterations or going to original loop body (following terminator will be omitted).
            LLVMBuildCondBr(
                self.builder,
                rpt_cmp,
                self.elf.inst_bbs[&(fseq.inst_buffer[0].0)],
                self.elf.inst_bbs[&(curr_addr + 4)],
            );

            Ok(())
        } else {
            Err(anyhow!("Inner FREP not yet supported"))
        }
    }

    /// Emit the code for the entire section.
    unsafe fn emit(&self, inst_index: &mut u32) -> Result<()> {
        // Initialize floating point sequencer context.
        let mut fseq = SequencerContext::new();
        // iterate over section instructions
        for (addr, inst) in self.elf.instructions(self.section) {
            let tran = InstructionTranslator {
                section: self,
                builder: self.builder,
                addr,
                inst,
                was_terminator: Default::default(),
                trace_accesses: Default::default(),
                trace_emitted: Default::default(),
                trace_disabled: Default::default(),
                was_freppable: Default::default(),
            };
            LLVMPositionBuilderAtEnd(self.builder, self.elf.inst_bbs[&addr]);
            match tran.emit(inst_index, &mut fseq) {
                Ok(()) => (),
                Err(e) => {
                    error!("{}", e);
                    self.emit_illegal_abort(addr, inst);
                }
            }
            // Note that FREP itself is not freppable.
            if fseq.active && tran.was_freppable.get() {
                fseq.push_rep_instruction(addr, inst)?;
                if !fseq.is_outer || fseq.is_body_complete() {
                    self.emit_frep(inst_index, &fseq, addr)?;
                    fseq.active = false;
                }
            }
            // Place branch to next instruction only after processing of sequence
            if LLVMGetBasicBlockTerminator(LLVMGetInsertBlock(self.builder)).is_null() {
                LLVMBuildBr(self.builder, self.elf.inst_bbs[&(addr + 4)]);
            }
        }
        Ok(())
    }

    /// Emit a call to a named function.
    unsafe fn emit_call(&self, name: &str, args: impl AsRef<[LLVMValueRef]>) -> LLVMValueRef {
        self.emit_call_with_name(name, args, "")
    }

    /// Emit a call to a named function, and assign a name to the return value.
    unsafe fn emit_call_with_name(
        &self,
        name: &str,
        args: impl AsRef<[LLVMValueRef]>,
        result_name: &str,
    ) -> LLVMValueRef {
        let args = args.as_ref();
        let call = LLVMBuildCall(
            self.builder,
            self.elf.lookup_func(name),
            args.as_ptr() as *mut _,
            args.len() as u32,
            format!("{}\0", result_name).as_ptr() as *mut _,
        );
        // TODO(fschuiki): The following is very dangerous. It can cause the IR
        // to produce broken machine code if the attribute is set on a function
        // which has side effects. Not sure why a call to 0x0 is inserted in
        // that case, though. Anyway, since this is just a performance
        // optimization, keep it disabled for now.
        // let attr = "argmemonly";
        // let attr = LLVMGetEnumAttributeKindForName(attr.as_ptr() as *mut _, attr.len());
        // let attr = LLVMCreateEnumAttribute(self.engine.context, attr, 0);
        // LLVMAddCallSiteAttribute(call, LLVMAttributeFunctionIndex, attr);
        call
    }
}

/// A translator for a single instruction.
pub struct InstructionTranslator<'a> {
    section: &'a SectionTranslator<'a>,
    builder: LLVMBuilderRef,
    addr: u64,
    inst: riscv::Format,
    was_terminator: Cell<bool>,
    trace_accesses: RefCell<Vec<(TraceAccess, LLVMValueRef)>>,
    trace_emitted: Cell<bool>,
    trace_disabled: Cell<bool>,
    was_freppable: Cell<bool>,
}

impl<'a> InstructionTranslator<'a> {
    unsafe fn emit(&self, inst_index: &mut u32, fseq: &mut SequencerContext) -> Result<()> {
        // Emit some debug information that indicates what instruction we are
        // currently processing.
        *inst_index += 1;
        let di_line = *inst_index;
        let di_name = format!("0x{:x} {}", self.addr, self.inst);
        let di_scope = LLVMDIBuilderCreateFunction(
            self.section.elf.di_builder,  // Builder
            self.section.elf.di_file,     // Scope
            di_name.as_ptr() as *const _, // Name
            di_name.len(),                // NameLen
            di_name.as_ptr() as *const _, // LinkageName
            di_name.len(),                // LinkageNameLen
            self.section.elf.di_file,     // File
            di_line,                      // LineNo
            LLVMDIBuilderCreateSubroutineType(
                self.section.elf.di_builder, // Builder
                self.section.elf.di_file,    // File
                [].as_mut_ptr(),             // ParameterTypes
                0,                           // NumParameterTypes
                LLVMDIFlagZero,              // Flags
            ), // Ty
            0,                            // IsLocalToUnit
            1,                            // IsDefinition
            di_line,                      // ScopeLine
            LLVMDIFlagPrototyped,         // Flags
            0,                            // IsOptimized
        );
        let di_loc = LLVMDIBuilderCreateDebugLocation(
            self.section.engine.context, // Ctx
            di_line,                     // Line
            0,                           // Column
            self.section.di_scope,       // Scope
            std::ptr::null_mut(),        // InlinedAt
        );
        let di_loc = LLVMDIBuilderCreateDebugLocation(
            self.section.engine.context, // Ctx
            di_line,                     // Line
            0,                           // Column
            di_scope,                    // Scope
            di_loc,                      // InlinedAt
        );
        LLVMSetCurrentDebugLocation2(self.builder, di_loc);

        // Update the PC register to reflect this instruction.
        LLVMBuildStore(
            self.builder,
            LLVMConstInt(LLVMInt32Type(), self.addr, 0),
            self.pc_ptr(),
        );

        // Update the instret counter.
        let instret = LLVMBuildLoad(self.builder, self.instret_ptr(), NONAME);
        let instret = LLVMBuildAdd(
            self.builder,
            instret,
            LLVMConstInt(LLVMTypeOf(instret), 1, 0),
            NONAME,
        );
        LLVMBuildStore(self.builder, instret, self.instret_ptr());

        // reset ssr streamer flags to serve new values for SSR registers
        for i in 0..SSR_N_STREAMERS {
            self.section.emit_call("banshee_ssr_eoi", [self.ssr_ptr(i)]);
        }

        // Emit the code for the instruction itself.
        match self.inst {
            //  riscv::Format::AqrlRdRs1(x) => self.emit_aqrl_rd_rs1(x),
            riscv::Format::AqrlRdRs1Rs2(x) => self.emit_aqrl_rd_rs1_rs2(x),
            riscv::Format::Bimm12hiBimm12loRs1Rs2(x) => self.emit_bimm12hi_bimm12lo_rs1_rs2(x),
            riscv::Format::Imm5Rd(x) => self.emit_imm5_rd(x),
            riscv::Format::Imm12Rd(x) => self.emit_imm12_rd(x),
            riscv::Format::Imm5RdRs1(x) => self.emit_imm5_rd_rs1(x),
            riscv::Format::Imm12RdRs1(x) => self.emit_imm12_rd_rs1(x),
            riscv::Format::Imm12Rs1StaggerMaskStaggerMax(x) => {
                self.emit_imm12_rs1_staggermask_staggermax(x, fseq)
            }
            riscv::Format::Imm12Rs1(x) => self.emit_imm12_rs1(x),
            riscv::Format::Imm12hiImm12loRs1Rs2(x) => self.emit_imm12hi_imm12lo_rs1_rs2(x),
            riscv::Format::Imm20Rd(x) => self.emit_imm20_rd(x),
            riscv::Format::Jimm20Rd(x) => self.emit_jimm20_rd(x),
            riscv::Format::RdRmRs1(x) => self.emit_rd_rm_rs1(x),
            riscv::Format::RdRmRs1Rs2(x) => self.emit_rd_rm_rs1_rs2(x),
            riscv::Format::RdRmRs1Rs2Rs3(x) => self.emit_rd_rm_rs1_rs2_rs3(x),
            riscv::Format::RdRs1(x) => self.emit_rd_rs1(x),
            riscv::Format::RdRs1Rs2(x) => self.emit_rd_rs1_rs2(x),
            riscv::Format::RdRs1Shamt(x) => self.emit_rd_rs1_shamt(x),
            riscv::Format::Rs1(x) => self.emit_rs1(x),
            riscv::Format::Rs1Rs2(x) => self.emit_rs1_rs2(x),
            riscv::Format::RdRs2(x) => self.emit_rd_rs2(x),
            riscv::Format::Unit(x) => self.emit_unit(x),
            _ => Err(anyhow!("Unsupported instruction format")),
        }
        .with_context(|| format!("Unsupported instruction 0x{:x}: {}", self.addr, self.inst))?;

        // Emit the tracing code if requested.
        self.emit_trace();
        Ok(())
    }
    unsafe fn emit_aqrl_rd_rs1_rs2(&self, data: riscv::FormatAqrlRdRs1Rs2) -> Result<()> {
        trace!("{} x{} = x{}, x{}", data.op, data.rd, data.rs1, data.rs2);

        // AMOs are not freppable
        self.was_freppable.set(false);

        // Ordering
        let ordering = match data.aqrl {
            0x0 => LLVMAtomicOrderingMonotonic,
            0x1 => LLVMAtomicOrderingRelease,
            0x2 => LLVMAtomicOrderingAcquire,
            0x3 => LLVMAtomicOrderingAcquireRelease,
            _ => LLVMAtomicOrderingAcquireRelease,
        };

        // Decoding
        let op = match data.op {
            riscv::OpcodeAqrlRdRs1Rs2::AmoaddW => AtomicOp::Amoadd,
            riscv::OpcodeAqrlRdRs1Rs2::AmoandW => AtomicOp::Amoand,
            riscv::OpcodeAqrlRdRs1Rs2::AmoorW => AtomicOp::Amoor,
            riscv::OpcodeAqrlRdRs1Rs2::AmoswapW => AtomicOp::Amoswap,
            riscv::OpcodeAqrlRdRs1Rs2::AmoxorW => AtomicOp::Amoxor,
            riscv::OpcodeAqrlRdRs1Rs2::AmomaxuW => AtomicOp::Amomaxu,
            riscv::OpcodeAqrlRdRs1Rs2::AmomaxW => AtomicOp::Amomax,
            riscv::OpcodeAqrlRdRs1Rs2::AmominuW => AtomicOp::Amominu,
            riscv::OpcodeAqrlRdRs1Rs2::AmominW => AtomicOp::Amomin,
            _ => bail!("Unsupported opcode {}", data.op),
        };

        // Extract the values
        let addr = self.read_reg(data.rs1);
        let value = self.read_reg(data.rs2);

        self.trace_access(TraceAccess::RMWMem, addr);

        // Start emitting LLVM IR
        let bb_end = LLVMCreateBasicBlockInContext(self.section.engine.context, NONAME);
        LLVMInsertExistingBasicBlockAfterInsertBlock(self.builder, bb_end);

        // Make sure the access is aligned
        let is_aligned = LLVMBuildAnd(
            self.builder,
            addr,
            LLVMConstInt(LLVMInt32Type(), 3, 0),
            NONAME,
        );
        let is_aligned = LLVMBuildICmp(
            self.builder,
            LLVMIntEQ,
            is_aligned,
            LLVMConstInt(LLVMInt32Type(), 0, 0),
            NONAME,
        );
        let bb_valid = LLVMCreateBasicBlockInContext(self.section.engine.context, NONAME);
        let bb_invalid = LLVMCreateBasicBlockInContext(self.section.engine.context, NONAME);
        LLVMInsertExistingBasicBlockAfterInsertBlock(self.builder, bb_valid);
        LLVMInsertExistingBasicBlockAfterInsertBlock(self.builder, bb_invalid);
        LLVMBuildCondBr(self.builder, is_aligned, bb_valid, bb_invalid);

        // Abort due to unaligned AMO
        LLVMPositionBuilderAtEnd(self.builder, bb_invalid);
        self.section.emit_call(
            "banshee_abort_illegal_inst",
            [
                self.section.state_ptr,
                LLVMConstInt(LLVMInt32Type(), addr as u64, 0),
                LLVMConstInt(LLVMInt32Type(), self.inst.raw() as u64, 0),
            ],
        );
        LLVMBuildRetVoid(self.builder);

        // Check if the address is in the TCDM, and emit a fast access.
        LLVMPositionBuilderAtEnd(self.builder, bb_valid);
        let (is_tcdm, tcdm_ptr) = self.emit_tcdm_check(addr);
        let bb_tcdm = LLVMCreateBasicBlockInContext(self.section.engine.context, NONAME);
        let bb_notcdm = LLVMCreateBasicBlockInContext(self.section.engine.context, NONAME);
        LLVMInsertExistingBasicBlockAfterInsertBlock(self.builder, bb_tcdm);
        LLVMInsertExistingBasicBlockAfterInsertBlock(self.builder, bb_notcdm);
        LLVMBuildCondBr(self.builder, is_tcdm, bb_tcdm, bb_notcdm);

        // Emit the TCDM fast case.
        LLVMPositionBuilderAtEnd(self.builder, bb_tcdm);
        let value_tcdm = match op {
            AtomicOp::Amoadd => LLVMBuildAtomicRMW(
                self.builder,
                LLVMAtomicRMWBinOpAdd,
                tcdm_ptr,
                value,
                ordering,
                0,
            ),
            AtomicOp::Amoxor => LLVMBuildAtomicRMW(
                self.builder,
                LLVMAtomicRMWBinOpXor,
                tcdm_ptr,
                value,
                ordering,
                0,
            ),
            AtomicOp::Amoor => LLVMBuildAtomicRMW(
                self.builder,
                LLVMAtomicRMWBinOpOr,
                tcdm_ptr,
                value,
                ordering,
                0,
            ),
            AtomicOp::Amoand => LLVMBuildAtomicRMW(
                self.builder,
                LLVMAtomicRMWBinOpAnd,
                tcdm_ptr,
                value,
                ordering,
                0,
            ),
            AtomicOp::Amomin => LLVMBuildAtomicRMW(
                self.builder,
                LLVMAtomicRMWBinOpMin,
                tcdm_ptr,
                value,
                ordering,
                0,
            ),
            AtomicOp::Amomax => LLVMBuildAtomicRMW(
                self.builder,
                LLVMAtomicRMWBinOpMax,
                tcdm_ptr,
                value,
                ordering,
                0,
            ),
            AtomicOp::Amominu => LLVMBuildAtomicRMW(
                self.builder,
                LLVMAtomicRMWBinOpUMin,
                tcdm_ptr,
                value,
                ordering,
                0,
            ),
            AtomicOp::Amomaxu => LLVMBuildAtomicRMW(
                self.builder,
                LLVMAtomicRMWBinOpUMax,
                tcdm_ptr,
                value,
                ordering,
                0,
            ),
            AtomicOp::Amoswap => LLVMBuildAtomicRMW(
                self.builder,
                LLVMAtomicRMWBinOpXchg,
                tcdm_ptr,
                value,
                ordering,
                0,
            ),
        };
        LLVMBuildBr(self.builder, bb_end);

        // Encode the operation
        let op_value: u8 = std::mem::transmute(op as u8);
        let op = LLVMConstInt(LLVMInt8Type(), op_value as u64, 0);

        // Emit the regular slow case.
        LLVMPositionBuilderAtEnd(self.builder, bb_notcdm);
        let value_slow = LLVMBuildCall(
            self.builder,
            LLVMGetNamedFunction(
                self.section.engine.module,
                "banshee_rmw\0".as_ptr() as *const _,
            ),
            [self.section.state_ptr, addr, value, op].as_mut_ptr(),
            4,
            NONAME,
        );
        LLVMBuildBr(self.builder, bb_end);

        let bb_notcdm = LLVMGetInsertBlock(self.builder);

        // Build the PHI node to bring the two together.
        LLVMPositionBuilderAtEnd(self.builder, bb_end);
        let phi = LLVMBuildPhi(self.builder, LLVMInt32Type(), NONAME);
        LLVMAddIncoming(
            phi,
            [value_tcdm, value_slow].as_mut_ptr(),
            [bb_tcdm, bb_notcdm].as_mut_ptr(),
            2,
        );

        // Write the final result to the register
        self.write_reg(data.rd, phi);

        Ok(())
    }

    unsafe fn emit_bimm12hi_bimm12lo_rs1_rs2(
        &self,
        data: riscv::FormatBimm12hiBimm12loRs1Rs2,
    ) -> Result<()> {
        let target = (self.addr as i64).wrapping_add(data.bimm() as i64) as u64;
        trace!("{} x{}, x{}, 0x{:x}", data.op, data.rs1, data.rs2, target);
        let rs1 = self.read_reg(data.rs1);
        let rs2 = self.read_reg(data.rs2);
        let name = format!("{}_x{}_x{}\0", data.op, data.rs1, data.rs2);
        let name = name.as_ptr() as *const _;
        let predicate = match data.op {
            riscv::OpcodeBimm12hiBimm12loRs1Rs2::Beq => LLVMIntEQ,
            riscv::OpcodeBimm12hiBimm12loRs1Rs2::Bne => LLVMIntNE,
            riscv::OpcodeBimm12hiBimm12loRs1Rs2::Blt => LLVMIntSLT,
            riscv::OpcodeBimm12hiBimm12loRs1Rs2::Bge => LLVMIntSGE,
            riscv::OpcodeBimm12hiBimm12loRs1Rs2::Bltu => LLVMIntULT,
            riscv::OpcodeBimm12hiBimm12loRs1Rs2::Bgeu => LLVMIntUGE,
        };
        let cmp = LLVMBuildICmp(self.builder, predicate, rs1, rs2, name);
        let bb =
            LLVMCreateBasicBlockInContext(self.section.engine.context, b"\0".as_ptr() as *const _);
        LLVMInsertExistingBasicBlockAfterInsertBlock(self.builder, bb);
        self.emit_trace();
        LLVMBuildCondBr(self.builder, cmp, self.section.elf.inst_bbs[&target], bb);
        LLVMPositionBuilderAtEnd(self.builder, bb);
        Ok(())
    }

    unsafe fn emit_imm12_rs1(&self, data: riscv::FormatImm12Rs1) -> Result<()> {
        let imm = data.imm();
        trace!("{} x{}, {}", data.op, data.rs1, imm);

        // Compute the address.
        let rs1 = self.read_reg(data.rs1);

        // Perform the operation.
        // suppress compiler warning that detects the bail! statement as unrechable
        // Scfgwi is currently the OpcodeImm12Rs1 but this might change
        #[allow(unreachable_patterns)]
        match data.op {
            riscv::OpcodeImm12Rs1::Scfgwi => {
                // ssr write immediate holds address offset in imm12, content in rs1
                // imm12[11:5]=reg_word imm12[4:0]=dm -> addr_off = {dm, reg_word[4:0], 000}
                let dm = (imm as u64) & 0x1f;
                let reg_word = ((imm as u64) >> 5) & 0x1f;
                let addr_off = LLVMConstInt(LLVMInt32Type(), (dm << 8) | (reg_word << 3), 0);
                let addr = LLVMBuildAdd(
                    self.builder,
                    LLVMConstInt(LLVMInt32Type(), SSR_BASE, 0),
                    addr_off,
                    NONAME,
                );
                self.write_mem(addr, rs1, 2);
            }
            _ => bail!("Unsupported opcode {}", data.op),
        };
        Ok(())
    }

    unsafe fn emit_imm12hi_imm12lo_rs1_rs2(
        &self,
        data: riscv::FormatImm12hiImm12loRs1Rs2,
    ) -> Result<()> {
        let imm = data.imm();
        trace!("{} x{}, x{}, 0x{:x}", data.op, data.rs1, data.rs2, imm);

        // Compute the address.
        let rs1 = self.read_reg(data.rs1);
        let imm = LLVMConstInt(LLVMInt32Type(), (imm as i64) as u64, 0);
        let addr = LLVMBuildAdd(self.builder, rs1, imm, NONAME);

        // Perform the operation.
        match data.op {
            riscv::OpcodeImm12hiImm12loRs1Rs2::Sb => {
                self.write_mem(addr, self.read_reg(data.rs2), 0)
            }
            riscv::OpcodeImm12hiImm12loRs1Rs2::Sh => {
                self.write_mem(addr, self.read_reg(data.rs2), 1)
            }
            riscv::OpcodeImm12hiImm12loRs1Rs2::Sw => {
                self.write_mem(addr, self.read_reg(data.rs2), 2)
            }
            riscv::OpcodeImm12hiImm12loRs1Rs2::Fsw => {
                self.was_freppable.set(true);
                let rs2 = self.read_freg(data.rs2);
                let rs2_lo = LLVMBuildTrunc(self.builder, rs2, LLVMInt32Type(), NONAME);
                self.write_mem(addr, rs2_lo, 2);
            }
            riscv::OpcodeImm12hiImm12loRs1Rs2::Fsd => {
                self.was_freppable.set(true);
                let rs2 = self.read_freg(data.rs2);
                let rs2_lo = LLVMBuildTrunc(self.builder, rs2, LLVMInt32Type(), NONAME);
                let rs2_hi = LLVMBuildLShr(
                    self.builder,
                    rs2,
                    LLVMConstInt(LLVMInt64Type(), 32, 0),
                    NONAME,
                );
                let rs2_hi = LLVMBuildTrunc(self.builder, rs2_hi, LLVMInt32Type(), NONAME);
                self.write_mem(addr, rs2_lo, 2);
                self.write_mem(
                    LLVMBuildAdd(
                        self.builder,
                        addr,
                        LLVMConstInt(LLVMInt32Type(), 4, 0),
                        NONAME,
                    ),
                    rs2_hi,
                    2,
                );
            }
            _ => bail!("Unsupported opcode {}", data.op),
        };
        Ok(())
    }

    unsafe fn emit_imm5_rd(&self, data: riscv::FormatImm5Rd) -> Result<()> {
        let imm = data.imm5;
        trace!("{} x{} = 0x{:x}", data.op, data.rd, imm);
        let imm = LLVMConstInt(LLVMInt32Type(), (imm as i64) as u64, 0);
        let name = format!("{}\0", data.op);
        let _name = name.as_ptr() as *const _;

        let value = match data.op {
            riscv::OpcodeImm5Rd::Dmstati => self
                .section
                .emit_call("banshee_dma_stat", [self.dma_ptr(), imm]),
        };
        self.write_reg(data.rd, value);
        Ok(())
    }

    unsafe fn emit_imm12_rd(&self, data: riscv::FormatImm12Rd) -> Result<()> {
        let imm = data.imm();
        trace!("{} x{} = 0x{:x}", data.op, data.rd, imm);
        let name = format!("{}\0", data.op);
        let _name = name.as_ptr() as *const _;

        let ssr_start = LLVMConstInt(LLVMInt32Type(), SSR_BASE, 0);

        // suppress compiler warning that detects the bail! statement as unrechable
        // Scfgri is currently the OpcodeImm12Rd but this might change
        #[allow(unreachable_patterns)]
        match data.op {
            riscv::OpcodeImm12Rd::Scfgri => {
                // srr load immediate from offset in imm12
                // reorder imm12 to form address
                // imm12[11:5]=reg_word imm12[4:0]=dm -> addr_off = {dm, reg_word[4:0], 000}
                let dm = (imm as u64) & 0x1f;
                let reg_word = ((imm as u64) >> 5) & 0x1f;
                let addr_off = LLVMConstInt(LLVMInt32Type(), (dm << 8) | (reg_word << 3), 0);
                let value = self.emit_load(ssr_start, addr_off, 2, true);
                self.write_reg(data.rd, value);
            }
            _ => bail!("Unsupported opcode {}", data.op),
        };
        Ok(())
    }

    unsafe fn emit_imm5_rd_rs1(&self, data: riscv::FormatImm5RdRs1) -> Result<()> {
        let imm = data.imm5;
        let rs1 = self.read_reg(data.rs1);
        let imm = LLVMConstInt(LLVMInt32Type(), (imm as i64) as u64, 0);
        let value = match data.op {
            riscv::OpcodeImm5RdRs1::Dmcpyi => self.section.emit_call(
                "banshee_dma_strt",
                [self.dma_ptr(), self.section.state_ptr, rs1, imm],
            ),
            // _ => bail!("Unsupported opcode {}", data.op),
        };
        self.write_reg(data.rd, value);
        Ok(())
    }

    unsafe fn emit_imm12_rd_rs1(&self, data: riscv::FormatImm12RdRs1) -> Result<()> {
        let imm = data.imm();
        trace!("{} x{} = x{}, 0x{:x}", data.op, data.rd, data.rs1, imm);

        // Handle CSR instructions, since we don't want to gratuitously read
        // registers.
        match data.op {
            riscv::OpcodeImm12RdRs1::Csrrwi
            | riscv::OpcodeImm12RdRs1::Csrrsi
            | riscv::OpcodeImm12RdRs1::Csrrci => return self.emit_csr_imm(data),
            riscv::OpcodeImm12RdRs1::Csrrw
            | riscv::OpcodeImm12RdRs1::Csrrs
            | riscv::OpcodeImm12RdRs1::Csrrc => return self.emit_csr_reg(data),
            _ => (),
        }

        let rs1 = self.read_reg(data.rs1);
        let imm = LLVMConstInt(LLVMInt32Type(), (imm as i64) as u64, 0);
        let name = format!("{}\0", data.op);
        let name = name.as_ptr() as *const _;
        let value = match data.op {
            riscv::OpcodeImm12RdRs1::Addi => LLVMBuildAdd(self.builder, rs1, imm, name),
            riscv::OpcodeImm12RdRs1::Slti => LLVMBuildZExt(
                self.builder,
                LLVMBuildICmp(self.builder, LLVMIntSLT, rs1, imm, NONAME),
                LLVMInt32Type(),
                name,
            ),
            riscv::OpcodeImm12RdRs1::Sltiu => LLVMBuildZExt(
                self.builder,
                LLVMBuildICmp(self.builder, LLVMIntULT, rs1, imm, NONAME),
                LLVMInt32Type(),
                name,
            ),
            riscv::OpcodeImm12RdRs1::Andi => LLVMBuildAnd(self.builder, rs1, imm, name),
            riscv::OpcodeImm12RdRs1::Ori => LLVMBuildOr(self.builder, rs1, imm, name),
            riscv::OpcodeImm12RdRs1::Xori => LLVMBuildXor(self.builder, rs1, imm, name),
            riscv::OpcodeImm12RdRs1::Lb => self.emit_load(rs1, imm, 0, true),
            riscv::OpcodeImm12RdRs1::Lh => self.emit_load(rs1, imm, 1, true),
            riscv::OpcodeImm12RdRs1::Lw => self.emit_load(rs1, imm, 2, true),
            riscv::OpcodeImm12RdRs1::Lbu => self.emit_load(rs1, imm, 0, false),
            riscv::OpcodeImm12RdRs1::Lhu => self.emit_load(rs1, imm, 1, false),
            riscv::OpcodeImm12RdRs1::Csrrw
            | riscv::OpcodeImm12RdRs1::Csrrs
            | riscv::OpcodeImm12RdRs1::Csrrc
            | riscv::OpcodeImm12RdRs1::Csrrwi
            | riscv::OpcodeImm12RdRs1::Csrrsi
            | riscv::OpcodeImm12RdRs1::Csrrci => unreachable!("handled above"),
            riscv::OpcodeImm12RdRs1::Jalr => {
                // Compute the branch target address.
                let target = LLVMBuildAdd(self.builder, rs1, imm, name);

                // Write the link register.
                self.write_reg(
                    data.rd,
                    LLVMConstInt(LLVMInt32Type(), (self.addr + 4) as u64, 0),
                );
                self.emit_trace();

                // Use the prepared indirect jump switch statement.
                LLVMBuildStore(self.builder, target, self.section.indirect_target_var);
                LLVMBuildStore(
                    self.builder,
                    LLVMConstInt(LLVMInt32Type(), self.addr as u64, 0),
                    self.section.indirect_addr_var,
                );
                LLVMBuildBr(self.builder, self.section.indirect_bb);
                // self.section.emit_branch_abort(self.addr, target);
                return Ok(()); // we have already written the link register
            }
            riscv::OpcodeImm12RdRs1::Flw => {
                self.was_freppable.set(true);
                let raw = self.emit_load(rs1, imm, 2, false);
                let raw = LLVMBuildZExt(self.builder, raw, LLVMInt64Type(), NONAME);
                let pad = LLVMConstInt(LLVMInt64Type(), (-1i64 as u64) << 32, 0);
                let value = LLVMBuildOr(self.builder, raw, pad, NONAME);
                self.write_freg(data.rd, value);
                return Ok(());
            }
            riscv::OpcodeImm12RdRs1::Fld => {
                self.was_freppable.set(true);
                self.emit_fld(data.rd, LLVMBuildAdd(self.builder, rs1, imm, NONAME));
                return Ok(());
            }
            _ => bail!("Unsupported opcode {}", data.op),
        };
        self.write_reg(data.rd, value);
        Ok(())
    }

    unsafe fn emit_fld(&self, rd: u32, addr: LLVMValueRef) {
        let raw_lo = self.read_mem(addr, 2, false);
        let raw_hi = self.read_mem(
            LLVMBuildAdd(
                self.builder,
                addr,
                LLVMConstInt(LLVMInt32Type(), 4, 0),
                NONAME,
            ),
            2,
            false,
        );
        let raw_lo = LLVMBuildZExt(self.builder, raw_lo, LLVMInt64Type(), NONAME);
        let raw_hi = LLVMBuildZExt(self.builder, raw_hi, LLVMInt64Type(), NONAME);
        let raw_hi = LLVMBuildShl(
            self.builder,
            raw_hi,
            LLVMConstInt(LLVMInt64Type(), 32, 0),
            NONAME,
        );
        let value = LLVMBuildOr(self.builder, raw_lo, raw_hi, NONAME);
        self.write_freg(rd, value);
    }

    unsafe fn emit_imm20_rd(&self, data: riscv::FormatImm20Rd) -> Result<()> {
        let imm = data.imm20 << 12;
        trace!("{} x{} = 0x{:x}", data.op, data.rd, imm);
        let value = match data.op {
            riscv::OpcodeImm20Rd::Auipc => LLVMConstInt(
                LLVMInt32Type(),
                (self.addr as u32).wrapping_add(imm) as u64,
                0,
            ),
            riscv::OpcodeImm20Rd::Lui => LLVMConstInt(LLVMInt32Type(), imm as u64, 0),
        };
        self.write_reg(data.rd, value);
        Ok(())
    }

    unsafe fn emit_jimm20_rd(&self, data: riscv::FormatJimm20Rd) -> Result<()> {
        match data.op {
            riscv::OpcodeJimm20Rd::Jal => {
                let target = (self.addr as i64).wrapping_add(data.jimm() as i64) as u64;
                trace!("jal x{}, 0x{:x}", data.rd, target);
                self.write_reg(
                    data.rd,
                    LLVMConstInt(LLVMInt32Type(), (self.addr + 4) as u64, 0),
                );
                self.emit_trace(); // need to do this before we branch away
                LLVMBuildBr(self.builder, self.section.elf.inst_bbs[&target]);
                self.was_terminator.set(true);
                Ok(())
            }
        }
    }

    unsafe fn emit_rd_rm_rs1(&self, data: riscv::FormatRdRmRs1) -> Result<()> {
        trace!("{} x{}, f{}", data.op, data.rd, data.rs1);
        let name = format!("{}\0", data.op);
        let name = name.as_ptr() as *const _;
        match data.op {
            riscv::OpcodeRdRmRs1::FcvtDW => {
                let rs1 = self.read_reg(data.rs1);
                let value = LLVMBuildSIToFP(self.builder, rs1, LLVMDoubleType(), name);
                self.write_freg_f64(data.rd, value);
            }
            riscv::OpcodeRdRmRs1::FcvtDWu => {
                let rs1 = self.read_reg(data.rs1);
                let value = LLVMBuildUIToFP(self.builder, rs1, LLVMDoubleType(), name);
                self.write_freg_f64(data.rd, value);
            }
            riscv::OpcodeRdRmRs1::FcvtSW => {
                let rs1 = self.read_reg(data.rs1);
                let value = LLVMBuildSIToFP(self.builder, rs1, LLVMFloatType(), name);
                self.write_freg_f32(data.rd, value);
            }
            riscv::OpcodeRdRmRs1::FcvtSWu => {
                let rs1 = self.read_reg(data.rs1);
                let value = LLVMBuildUIToFP(self.builder, rs1, LLVMFloatType(), name);
                self.write_freg_f32(data.rd, value);
            }
            riscv::OpcodeRdRmRs1::FcvtWD => {
                let rs1 = self.read_freg_f64(data.rs1);
                let value = LLVMBuildFPToSI(self.builder, rs1, LLVMInt32Type(), name);
                self.write_reg(data.rd, value);
            }
            riscv::OpcodeRdRmRs1::FcvtWS => {
                let rs1 = self.read_freg_f32(data.rs1);
                let value = LLVMBuildFPToSI(self.builder, rs1, LLVMInt32Type(), name);
                self.write_reg(data.rd, value);
            }
            riscv::OpcodeRdRmRs1::FcvtWuS => {
                let rs1 = self.read_freg_f32(data.rs1);
                let value = LLVMBuildFPToUI(self.builder, rs1, LLVMInt32Type(), name);
                self.write_reg(data.rd, value);
            }
            riscv::OpcodeRdRmRs1::FcvtWuD => {
                let rs1 = self.read_freg_f64(data.rs1);
                let value = LLVMBuildFPToUI(self.builder, rs1, LLVMInt32Type(), name);
                self.write_reg(data.rd, value);
            }
            riscv::OpcodeRdRmRs1::FcvtDS => {
                let rs1 = self.read_freg_f32(data.rs1);
                let value = LLVMBuildFPCast(self.builder, rs1, LLVMDoubleType(), name);
                self.write_freg_f64(data.rd, value);
            }
            riscv::OpcodeRdRmRs1::FcvtSD => {
                let rs1 = self.read_freg_f64(data.rs1);
                let value = LLVMBuildFPCast(self.builder, rs1, LLVMFloatType(), name);
                self.write_freg_f32(data.rd, value);
            }
            _ => bail!("Unsupported opcode {}", data.op),
        };
        Ok(())
    }

    unsafe fn emit_rd_rs2(&self, data: riscv::FormatRdRs2) -> Result<()> {
        trace!("{} x{}, f{}", data.op, data.rd, data.rs2);
        let rs2 = self.read_reg(data.rs2);

        let value = match data.op {
            riscv::OpcodeRdRs2::Scfgr => {
                // reorder rs2 to form address
                // rs2[11:5]=reg_word rs2[4:0]=dm -> addr_off = {dm, reg_word[4:0], 000}
                let reg = LLVMBuildLShr(
                    self.builder,
                    rs2,
                    LLVMConstInt(LLVMInt32Type(), 2 as u64, 0),
                    NONAME,
                );
                let reg_masked = LLVMBuildAnd(
                    self.builder,
                    reg,
                    LLVMConstInt(LLVMInt32Type(), 0xf8 as u64, 0),
                    NONAME,
                );
                let rs2_dm = LLVMBuildAnd(
                    self.builder,
                    rs2,
                    LLVMConstInt(LLVMInt32Type(), 0x1f as u64, 0),
                    NONAME,
                );
                let rs2_dm_shifted = LLVMBuildShl(
                    self.builder,
                    rs2_dm,
                    LLVMConstInt(LLVMInt32Type(), 8 as u64, 0),
                    NONAME,
                );
                let addr_off = LLVMBuildOr(self.builder, rs2_dm_shifted, reg_masked, NONAME);
                // perform load
                self.emit_load(
                    LLVMConstInt(LLVMInt32Type(), SSR_BASE, 0),
                    addr_off,
                    2,
                    true,
                )
            }
            riscv::OpcodeRdRs2::Dmstat => self
                .section
                .emit_call("banshee_dma_stat", [self.dma_ptr(), rs2]),
            // _ => bail!("Unsupported opcode {}", data.op),
        };

        self.write_reg(data.rd, value);
        Ok(())
    }

    unsafe fn emit_rd_rm_rs1_rs2(&self, data: riscv::FormatRdRmRs1Rs2) -> Result<()> {
        self.was_freppable.set(true);
        trace!("{} f{} = f{}, f{}", data.op, data.rd, data.rs1, data.rs2);
        let name = format!("{}\0", data.op);
        let name = name.as_ptr() as *const _;
        self.was_freppable.set(true);
        match data.op {
            riscv::OpcodeRdRmRs1Rs2::FaddS => self.write_freg_f32(
                data.rd,
                LLVMBuildFAdd(
                    self.builder,
                    self.read_freg_f32(data.rs1),
                    self.read_freg_f32(data.rs2),
                    name,
                ),
            ),
            riscv::OpcodeRdRmRs1Rs2::FsubS => self.write_freg_f32(
                data.rd,
                LLVMBuildFSub(
                    self.builder,
                    self.read_freg_f32(data.rs1),
                    self.read_freg_f32(data.rs2),
                    name,
                ),
            ),
            riscv::OpcodeRdRmRs1Rs2::FmulS => self.write_freg_f32(
                data.rd,
                LLVMBuildFMul(
                    self.builder,
                    self.read_freg_f32(data.rs1),
                    self.read_freg_f32(data.rs2),
                    name,
                ),
            ),
            riscv::OpcodeRdRmRs1Rs2::FdivS => self.write_freg_f32(
                data.rd,
                LLVMBuildFDiv(
                    self.builder,
                    self.read_freg_f32(data.rs1),
                    self.read_freg_f32(data.rs2),
                    name,
                ),
            ),
            riscv::OpcodeRdRmRs1Rs2::FaddD => self.write_freg_f64(
                data.rd,
                LLVMBuildFAdd(
                    self.builder,
                    self.read_freg_f64(data.rs1),
                    self.read_freg_f64(data.rs2),
                    name,
                ),
            ),
            riscv::OpcodeRdRmRs1Rs2::FsubD => self.write_freg_f64(
                data.rd,
                LLVMBuildFSub(
                    self.builder,
                    self.read_freg_f64(data.rs1),
                    self.read_freg_f64(data.rs2),
                    name,
                ),
            ),
            riscv::OpcodeRdRmRs1Rs2::FmulD => self.write_freg_f64(
                data.rd,
                LLVMBuildFMul(
                    self.builder,
                    self.read_freg_f64(data.rs1),
                    self.read_freg_f64(data.rs2),
                    name,
                ),
            ),
            riscv::OpcodeRdRmRs1Rs2::FdivD => self.write_freg_f64(
                data.rd,
                LLVMBuildFDiv(
                    self.builder,
                    self.read_freg_f64(data.rs1),
                    self.read_freg_f64(data.rs2),
                    name,
                ),
            ),
            _ => bail!("Unsupported opcode {}", data.op),
        };
        Ok(())
    }

    unsafe fn emit_rd_rm_rs1_rs2_rs3(&self, data: riscv::FormatRdRmRs1Rs2Rs3) -> Result<()> {
        self.was_freppable.set(true);
        trace!(
            "{} f{} = f{}, f{}, f{}",
            data.op,
            data.rd,
            data.rs1,
            data.rs2,
            data.rs3
        );
        match data.op {
            riscv::OpcodeRdRmRs1Rs2Rs3::FmaddS
            | riscv::OpcodeRdRmRs1Rs2Rs3::FmsubS
            | riscv::OpcodeRdRmRs1Rs2Rs3::FnmaddS
            | riscv::OpcodeRdRmRs1Rs2Rs3::FnmsubS => self.write_freg_f32(
                data.rd,
                self.emit_fmadd(
                    data,
                    self.read_freg_f32(data.rs1),
                    self.read_freg_f32(data.rs2),
                    self.read_freg_f32(data.rs3),
                )?,
            ),
            riscv::OpcodeRdRmRs1Rs2Rs3::FmaddD
            | riscv::OpcodeRdRmRs1Rs2Rs3::FmsubD
            | riscv::OpcodeRdRmRs1Rs2Rs3::FnmaddD
            | riscv::OpcodeRdRmRs1Rs2Rs3::FnmsubD => self.write_freg_f64(
                data.rd,
                self.emit_fmadd(
                    data,
                    self.read_freg_f64(data.rs1),
                    self.read_freg_f64(data.rs2),
                    self.read_freg_f64(data.rs3),
                )?,
            ),
            _ => bail!("Unsupported opcode {}", data.op),
        };
        Ok(())
    }

    unsafe fn emit_imm12_rs1_staggermask_staggermax(
        &self,
        data: riscv::FormatImm12Rs1StaggerMaskStaggerMax,
        fseq: &mut SequencerContext,
    ) -> Result<()> {
        trace!(
            "{} x{}, {}, 0b{:b}, {}",
            data.op,
            data.rs1,          // register containing max repetition
            data.imm12,        // max instruction
            data.stagger_mask, // stagger mask
            data.stagger_max   // stagger max
        );
        // Initialize repetition iterator to 0
        LLVMBuildStore(
            self.builder,
            LLVMConstInt(LLVMInt32Type(), 0, 0),
            self.section.fseq_iter.rpt_ptr_ref,
        );
        // Initialize repetition bound
        LLVMBuildStore(
            self.builder,
            self.read_reg(data.rs1),
            self.section.fseq_iter.max_rpt_ref,
        );
        // suppress compiler warning that detects the bail! statement as unrechable
        // Frep* are currently the only OpcodeImm12Rs1Stagger_maskStagger_max but this might change
        #[allow(unreachable_patterns)]
        match data.op {
            riscv::OpcodeImm12Rs1StaggerMaskStaggerMax::FrepO => fseq.init_rep(
                data.imm12 as u8,
                true,
                data.stagger_max as u8,
                data.stagger_mask as u8,
            ),
            riscv::OpcodeImm12Rs1StaggerMaskStaggerMax::FrepI => fseq.init_rep(
                data.imm12 as u8,
                false,
                data.stagger_max as u8,
                data.stagger_mask as u8,
            ),
            _ => bail!("Unsupported opcode {}", data.op),
        }
    }

    unsafe fn emit_fmadd(
        &self,
        data: riscv::FormatRdRmRs1Rs2Rs3,
        rs1: LLVMValueRef,
        rs2: LLVMValueRef,
        rs3: LLVMValueRef,
    ) -> Result<LLVMValueRef> {
        let name = format!("{}\0", data.op);
        let name = name.as_ptr() as *const _;
        Ok(match data.op {
            riscv::OpcodeRdRmRs1Rs2Rs3::FmaddS
            | riscv::OpcodeRdRmRs1Rs2Rs3::FmaddD
            | riscv::OpcodeRdRmRs1Rs2Rs3::FmaddQ => LLVMBuildFAdd(
                self.builder,
                LLVMBuildFMul(self.builder, rs1, rs2, NONAME),
                rs3,
                name,
            ),
            riscv::OpcodeRdRmRs1Rs2Rs3::FmsubS
            | riscv::OpcodeRdRmRs1Rs2Rs3::FmsubD
            | riscv::OpcodeRdRmRs1Rs2Rs3::FmsubQ => LLVMBuildFSub(
                self.builder,
                LLVMBuildFMul(self.builder, rs1, rs2, NONAME),
                rs3,
                name,
            ),
            riscv::OpcodeRdRmRs1Rs2Rs3::FnmaddS
            | riscv::OpcodeRdRmRs1Rs2Rs3::FnmaddD
            | riscv::OpcodeRdRmRs1Rs2Rs3::FnmaddQ => LLVMBuildFAdd(
                self.builder,
                LLVMBuildFNeg(
                    self.builder,
                    LLVMBuildFMul(self.builder, rs1, rs2, NONAME),
                    NONAME,
                ),
                rs3,
                name,
            ),
            riscv::OpcodeRdRmRs1Rs2Rs3::FnmsubS
            | riscv::OpcodeRdRmRs1Rs2Rs3::FnmsubD
            | riscv::OpcodeRdRmRs1Rs2Rs3::FnmsubQ => LLVMBuildFSub(
                self.builder,
                LLVMBuildFNeg(
                    self.builder,
                    LLVMBuildFMul(self.builder, rs1, rs2, NONAME),
                    NONAME,
                ),
                rs3,
                name,
            ),
        })
    }

    unsafe fn emit_rd_rs1(&self, data: riscv::FormatRdRs1) -> Result<()> {
        trace!("{} x{} = x{}", data.op, data.rd, data.rs1);
        let name = format!("{}\0", data.op);
        let _name = name.as_ptr() as *const _;

        // Handle floating-point operations
        match data.op {
            riscv::OpcodeRdRs1::FmvXW => {
                // float (rs1) to integer (rd) register, bits are not modified
                let rs1 = self.read_freg_f32(data.rs1);
                // cast the integer reg pointer to a float pointer
                let raw_ptr = self.reg_ptr(data.rd);
                let ptr = LLVMBuildBitCast(
                    self.builder,
                    raw_ptr,
                    LLVMPointerType(LLVMFloatType(), 0),
                    NONAME,
                );
                // build the actual store and add trace
                LLVMBuildStore(self.builder, rs1, ptr);
                self.trace_access(
                    TraceAccess::WriteReg(data.rd as u8),
                    LLVMBuildLoad(self.builder, raw_ptr, NONAME),
                );
                return Ok(());
            }
            riscv::OpcodeRdRs1::FmvWX => {
                // integer (rs1) to float (rd) register, bits are not modified
                let rs1 = self.read_reg(data.rs1);
                // cast the float reg pointer to an integer pointer
                let raw_ptr = self.freg_ptr(data.rd);
                let ptr = LLVMBuildBitCast(
                    self.builder,
                    raw_ptr,
                    LLVMPointerType(LLVMInt32Type(), 0),
                    NONAME,
                );
                // build the actual store and add trace
                LLVMBuildStore(self.builder, rs1, ptr);
                self.trace_access(
                    TraceAccess::WriteFReg(data.rd as u8),
                    LLVMBuildLoad(self.builder, raw_ptr, NONAME),
                );
                return Ok(());
            }
            _ => (),
        }
        Ok(())
    }

    unsafe fn emit_rd_rs1_rs2(&self, data: riscv::FormatRdRs1Rs2) -> Result<()> {
        trace!("{} x{} = x{}, x{}", data.op, data.rd, data.rs1, data.rs2);
        let name = format!("{}\0", data.op);
        let name = name.as_ptr() as *const _;

        // Assume generally freppable, later exclude comparisons.
        self.was_freppable.set(true);

        // Handle floating-point operations.
        match data.op {
            // Sign injection
            riscv::OpcodeRdRs1Rs2::FsgnjS => {
                self.write_freg_f32(
                    data.rd,
                    self.emit_fsgnj(self.read_freg_f32(data.rs1), self.read_freg_f32(data.rs2)),
                );
                return Ok(());
            }
            riscv::OpcodeRdRs1Rs2::FsgnjnS => {
                self.write_freg_f32(
                    data.rd,
                    self.emit_fsgnjn(self.read_freg_f32(data.rs1), self.read_freg_f32(data.rs2)),
                );
                return Ok(());
            }
            riscv::OpcodeRdRs1Rs2::FsgnjxS => {
                self.write_freg_f32(
                    data.rd,
                    self.emit_fsgnjx(self.read_freg_f32(data.rs1), self.read_freg_f32(data.rs2)),
                );
                return Ok(());
            }
            riscv::OpcodeRdRs1Rs2::FsgnjD => {
                self.write_freg_f64(
                    data.rd,
                    self.emit_fsgnj(self.read_freg_f64(data.rs1), self.read_freg_f64(data.rs2)),
                );
                return Ok(());
            }
            riscv::OpcodeRdRs1Rs2::FsgnjnD => {
                self.write_freg_f64(
                    data.rd,
                    self.emit_fsgnjn(self.read_freg_f64(data.rs1), self.read_freg_f64(data.rs2)),
                );
                return Ok(());
            }
            riscv::OpcodeRdRs1Rs2::FsgnjxD => {
                self.write_freg_f64(
                    data.rd,
                    self.emit_fsgnjx(self.read_freg_f64(data.rs1), self.read_freg_f64(data.rs2)),
                );
                return Ok(());
            }

            // Max/min
            riscv::OpcodeRdRs1Rs2::FmaxS => {
                self.write_freg_f32(
                    data.rd,
                    self.emit_binary_float_intrinsic(
                        "llvm.maxnum",
                        self.read_freg_f32(data.rs1),
                        self.read_freg_f32(data.rs2),
                    ),
                );
                return Ok(());
            }
            riscv::OpcodeRdRs1Rs2::FminS => {
                self.write_freg_f32(
                    data.rd,
                    self.emit_binary_float_intrinsic(
                        "llvm.minnum",
                        self.read_freg_f32(data.rs1),
                        self.read_freg_f32(data.rs2),
                    ),
                );
                return Ok(());
            }
            riscv::OpcodeRdRs1Rs2::FmaxD => {
                self.write_freg_f64(
                    data.rd,
                    self.emit_binary_float_intrinsic(
                        "llvm.maxnum",
                        self.read_freg_f64(data.rs1),
                        self.read_freg_f64(data.rs2),
                    ),
                );
                return Ok(());
            }
            riscv::OpcodeRdRs1Rs2::FminD => {
                self.write_freg_f64(
                    data.rd,
                    self.emit_binary_float_intrinsic(
                        "llvm.minnum",
                        self.read_freg_f64(data.rs1),
                        self.read_freg_f64(data.rs2),
                    ),
                );
                return Ok(());
            }

            // Comparison
            riscv::OpcodeRdRs1Rs2::FeqS => {
                self.was_freppable.set(false);
                self.write_reg(
                    data.rd,
                    LLVMBuildZExt(
                        self.builder,
                        LLVMBuildFCmp(
                            self.builder,
                            LLVMRealOEQ,
                            self.read_freg_f32(data.rs1),
                            self.read_freg_f32(data.rs2),
                            name,
                        ),
                        LLVMInt32Type(),
                        NONAME,
                    ),
                );
                return Ok(());
            }
            riscv::OpcodeRdRs1Rs2::FltS => {
                self.was_freppable.set(false);
                self.write_reg(
                    data.rd,
                    LLVMBuildZExt(
                        self.builder,
                        LLVMBuildFCmp(
                            self.builder,
                            LLVMRealOLT,
                            self.read_freg_f32(data.rs1),
                            self.read_freg_f32(data.rs2),
                            name,
                        ),
                        LLVMInt32Type(),
                        NONAME,
                    ),
                );
                return Ok(());
            }
            riscv::OpcodeRdRs1Rs2::FleS => {
                self.was_freppable.set(false);
                self.write_reg(
                    data.rd,
                    LLVMBuildZExt(
                        self.builder,
                        LLVMBuildFCmp(
                            self.builder,
                            LLVMRealOLE,
                            self.read_freg_f32(data.rs1),
                            self.read_freg_f32(data.rs2),
                            name,
                        ),
                        LLVMInt32Type(),
                        NONAME,
                    ),
                );
                return Ok(());
            }
            riscv::OpcodeRdRs1Rs2::FeqD => {
                self.was_freppable.set(false);
                self.write_reg(
                    data.rd,
                    LLVMBuildZExt(
                        self.builder,
                        LLVMBuildFCmp(
                            self.builder,
                            LLVMRealOEQ,
                            self.read_freg_f64(data.rs1),
                            self.read_freg_f64(data.rs2),
                            name,
                        ),
                        LLVMInt32Type(),
                        NONAME,
                    ),
                );
                return Ok(());
            }
            riscv::OpcodeRdRs1Rs2::FltD => {
                self.was_freppable.set(false);
                self.write_reg(
                    data.rd,
                    LLVMBuildZExt(
                        self.builder,
                        LLVMBuildFCmp(
                            self.builder,
                            LLVMRealOLT,
                            self.read_freg_f64(data.rs1),
                            self.read_freg_f64(data.rs2),
                            name,
                        ),
                        LLVMInt32Type(),
                        NONAME,
                    ),
                );
                return Ok(());
            }
            riscv::OpcodeRdRs1Rs2::FleD => {
                self.was_freppable.set(false);
                self.write_reg(
                    data.rd,
                    LLVMBuildZExt(
                        self.builder,
                        LLVMBuildFCmp(
                            self.builder,
                            LLVMRealOLE,
                            self.read_freg_f64(data.rs1),
                            self.read_freg_f64(data.rs2),
                            name,
                        ),
                        LLVMInt32Type(),
                        NONAME,
                    ),
                );
                return Ok(());
            }
            _ => (),
        }

        // Handle other operations.
        let rs1 = self.read_reg(data.rs1);
        let rs2 = self.read_reg(data.rs2);
        let value = match data.op {
            riscv::OpcodeRdRs1Rs2::Add => LLVMBuildAdd(self.builder, rs1, rs2, name),
            riscv::OpcodeRdRs1Rs2::Sub => LLVMBuildSub(self.builder, rs1, rs2, name),
            riscv::OpcodeRdRs1Rs2::And => LLVMBuildAnd(self.builder, rs1, rs2, name),
            riscv::OpcodeRdRs1Rs2::Or => LLVMBuildOr(self.builder, rs1, rs2, name),
            riscv::OpcodeRdRs1Rs2::Xor => LLVMBuildXor(self.builder, rs1, rs2, name),
            riscv::OpcodeRdRs1Rs2::Mul => LLVMBuildMul(self.builder, rs1, rs2, name),
            riscv::OpcodeRdRs1Rs2::Mulhu => {
                let tmp = LLVMBuildMul(
                    self.builder,
                    LLVMBuildZExt(self.builder, rs1, LLVMInt64Type(), NONAME),
                    LLVMBuildZExt(self.builder, rs2, LLVMInt64Type(), NONAME),
                    name,
                );
                let tmp = LLVMBuildLShr(
                    self.builder,
                    tmp,
                    LLVMConstInt(LLVMInt64Type(), 32 as u64, 0),
                    NONAME,
                );
                LLVMBuildTrunc(self.builder, tmp, LLVMInt32Type(), NONAME)
            }
            riscv::OpcodeRdRs1Rs2::Mulh => {
                let tmp = LLVMBuildMul(
                    self.builder,
                    LLVMBuildSExt(self.builder, rs1, LLVMInt64Type(), NONAME),
                    LLVMBuildSExt(self.builder, rs2, LLVMInt64Type(), NONAME),
                    name,
                );
                let tmp = LLVMBuildLShr(
                    self.builder,
                    tmp,
                    LLVMConstInt(LLVMInt64Type(), 32 as u64, 0),
                    NONAME,
                );
                LLVMBuildTrunc(self.builder, tmp, LLVMInt32Type(), NONAME)
            }
            riscv::OpcodeRdRs1Rs2::Mulhsu => {
                let tmp = LLVMBuildMul(
                    self.builder,
                    LLVMBuildSExt(self.builder, rs1, LLVMInt64Type(), NONAME),
                    LLVMBuildZExt(self.builder, rs2, LLVMInt64Type(), NONAME),
                    name,
                );
                let tmp = LLVMBuildLShr(
                    self.builder,
                    tmp,
                    LLVMConstInt(LLVMInt64Type(), 32 as u64, 0),
                    NONAME,
                );
                LLVMBuildTrunc(self.builder, tmp, LLVMInt32Type(), NONAME)
            }
            riscv::OpcodeRdRs1Rs2::Div => LLVMBuildSDiv(self.builder, rs1, rs2, name),
            riscv::OpcodeRdRs1Rs2::Divu => LLVMBuildUDiv(self.builder, rs1, rs2, name),
            riscv::OpcodeRdRs1Rs2::Rem => LLVMBuildSRem(self.builder, rs1, rs2, name),
            riscv::OpcodeRdRs1Rs2::Remu => LLVMBuildURem(self.builder, rs1, rs2, name),
            riscv::OpcodeRdRs1Rs2::Slt => LLVMBuildZExt(
                self.builder,
                LLVMBuildICmp(self.builder, LLVMIntSLT, rs1, rs2, NONAME),
                LLVMInt32Type(),
                name,
            ),
            riscv::OpcodeRdRs1Rs2::Sltu => LLVMBuildZExt(
                self.builder,
                LLVMBuildICmp(self.builder, LLVMIntULT, rs1, rs2, NONAME),
                LLVMInt32Type(),
                name,
            ),
            riscv::OpcodeRdRs1Rs2::Sll => LLVMBuildShl(self.builder, rs1, rs2, name),
            riscv::OpcodeRdRs1Rs2::Srl => LLVMBuildLShr(self.builder, rs1, rs2, name),
            riscv::OpcodeRdRs1Rs2::Sra => LLVMBuildAShr(self.builder, rs1, rs2, name),
            riscv::OpcodeRdRs1Rs2::Dmcpy => self.section.emit_call(
                "banshee_dma_strt",
                [self.dma_ptr(), self.section.state_ptr, rs1, rs2],
            ),
            _ => bail!("Unsupported opcode {}", data.op),
        };
        self.write_reg(data.rd, value);
        Ok(())
    }

    unsafe fn emit_fsgnj(&self, rs1: LLVMValueRef, rs2: LLVMValueRef) -> LLVMValueRef {
        self.emit_fsgnj_common(rs1, rs2, |_, b| b)
    }

    unsafe fn emit_fsgnjn(&self, rs1: LLVMValueRef, rs2: LLVMValueRef) -> LLVMValueRef {
        self.emit_fsgnj_common(rs1, rs2, |_, b| LLVMBuildNot(self.builder, b, NONAME))
    }

    unsafe fn emit_fsgnjx(&self, rs1: LLVMValueRef, rs2: LLVMValueRef) -> LLVMValueRef {
        self.emit_fsgnj_common(rs1, rs2, |a, b| LLVMBuildXor(self.builder, a, b, NONAME))
    }

    unsafe fn emit_fsgnj_common(
        &self,
        rs1: LLVMValueRef,
        rs2: LLVMValueRef,
        combine: impl FnOnce(LLVMValueRef, LLVMValueRef) -> LLVMValueRef,
    ) -> LLVMValueRef {
        let fzero = LLVMConstNull(LLVMTypeOf(rs1));
        let sign_rs1 = LLVMBuildFCmp(self.builder, LLVMRealOLT, rs1, fzero, NONAME);
        let sign_rs2 = LLVMBuildFCmp(self.builder, LLVMRealOLT, rs2, fzero, NONAME);
        let exp = combine(sign_rs1, sign_rs2);
        let need_flip = LLVMBuildICmp(self.builder, LLVMIntNE, sign_rs1, exp, NONAME);
        let rs1_neg = LLVMBuildFNeg(self.builder, rs1, NONAME);
        LLVMBuildSelect(self.builder, need_flip, rs1_neg, rs1, NONAME)
    }

    unsafe fn emit_binary_float_intrinsic(
        &self,
        name: &str,
        rs1: LLVMValueRef,
        rs2: LLVMValueRef,
    ) -> LLVMValueRef {
        let id = LLVMLookupIntrinsicID(name.as_ptr() as *const _, name.len());
        let decl = LLVMGetIntrinsicDeclaration(
            self.section.engine.module,
            id,
            [LLVMTypeOf(rs1)].as_mut_ptr(),
            1,
        );
        LLVMBuildCall(self.builder, decl, [rs1, rs2].as_mut_ptr(), 2, NONAME)
    }

    unsafe fn emit_rd_rs1_shamt(&self, data: riscv::FormatRdRs1Shamt) -> Result<()> {
        trace!(
            "{} x{} = x{}, 0x{:x}",
            data.op,
            data.rd,
            data.rs1,
            data.shamt
        );
        let rs1 = self.read_reg(data.rs1);
        let shamt = LLVMConstInt(LLVMInt32Type(), data.shamt as u64, 0);
        let name = format!("{}\0", data.op);
        let name = name.as_ptr() as *const _;
        let value = match data.op {
            riscv::OpcodeRdRs1Shamt::Slli => LLVMBuildShl(self.builder, rs1, shamt, name),
            riscv::OpcodeRdRs1Shamt::Srli => LLVMBuildLShr(self.builder, rs1, shamt, name),
            riscv::OpcodeRdRs1Shamt::Srai => LLVMBuildAShr(self.builder, rs1, shamt, name),
            _ => bail!("Unsupported opcode {}", data.op),
        };
        self.write_reg(data.rd, value);
        Ok(())
    }

    unsafe fn emit_rs1(&self, data: riscv::FormatRs1) -> Result<()> {
        trace!("{} x{}", data.op, data.rs1);
        let name = format!("{}\0", data.op);
        let _name = name.as_ptr() as *const _;
        let rs1 = self.read_reg(data.rs1);

        // suppress compiler warning that detects the bail! statement as unrechable
        // Dmrep is currently the OpcodeRs1 but this might change
        #[allow(unreachable_patterns)]
        match data.op {
            riscv::OpcodeRs1::Dmrep => self
                .section
                .emit_call("banshee_dma_rep", [self.dma_ptr(), rs1]),
            _ => bail!("Unsupported opcode {}", data.op),
        };
        Ok(())
    }

    unsafe fn emit_rs1_rs2(&self, data: riscv::FormatRs1Rs2) -> Result<()> {
        trace!("{} x{}, x{}", data.op, data.rs1, data.rs2);
        let name = format!("{}\0", data.op);
        let _name = name.as_ptr() as *const _;
        let rs1 = self.read_reg(data.rs1);
        let rs2 = self.read_reg(data.rs2);

        // Perform the SSR write op
        match data.op {
            riscv::OpcodeRs1Rs2::Scfgw => {
                // reorder rs2 to form address
                // rs2[11:5]=reg_word rs2[4:0]=dm -> addr_off = {dm, reg_word[4:0], 000}
                let reg = LLVMBuildLShr(
                    self.builder,
                    rs2,
                    LLVMConstInt(LLVMInt32Type(), 2 as u64, 0),
                    NONAME,
                );
                let reg_masked = LLVMBuildAnd(
                    self.builder,
                    reg,
                    LLVMConstInt(LLVMInt32Type(), 0xf8 as u64, 0),
                    NONAME,
                );
                let rs2_dm = LLVMBuildAnd(
                    self.builder,
                    rs2,
                    LLVMConstInt(LLVMInt32Type(), 0x1f as u64, 0),
                    NONAME,
                );
                let rs2_dm_shifted = LLVMBuildShl(
                    self.builder,
                    rs2_dm,
                    LLVMConstInt(LLVMInt32Type(), 8 as u64, 0),
                    NONAME,
                );
                let addr_off = LLVMBuildOr(self.builder, rs2_dm_shifted, reg_masked, NONAME);

                let addr = LLVMBuildAdd(
                    self.builder,
                    LLVMConstInt(LLVMInt32Type(), SSR_BASE, 0),
                    addr_off,
                    NONAME,
                );
                self.write_mem(addr, rs1, 2);
                return Ok(());
            }
            _ => (),
        };

        match data.op {
            riscv::OpcodeRs1Rs2::Dmsrc => self
                .section
                .emit_call("banshee_dma_src", [self.dma_ptr(), rs1, rs2]),
            riscv::OpcodeRs1Rs2::Dmdst => self
                .section
                .emit_call("banshee_dma_dst", [self.dma_ptr(), rs1, rs2]),
            riscv::OpcodeRs1Rs2::Dmstr => self
                .section
                .emit_call("banshee_dma_str", [self.dma_ptr(), rs1, rs2]),
            _ => bail!("Unsupported opcode {}", data.op),
        };
        Ok(())
    }

    unsafe fn emit_unit(&self, data: riscv::FormatUnit) -> Result<()> {
        trace!("{}", data.op,);
        match data.op {
            riscv::OpcodeUnit::Wfi => {
                self.emit_trace();
                let terminate = self
                    .section
                    .emit_call("banshee_wfi", [self.section.state_ptr]);
                let terminate = LLVMBuildIntCast(self.builder, terminate, LLVMInt1Type(), NONAME);
                let bb_terminate =
                    LLVMCreateBasicBlockInContext(self.section.engine.context, NONAME);
                let bb_wake_up = LLVMCreateBasicBlockInContext(self.section.engine.context, NONAME);
                LLVMInsertExistingBasicBlockAfterInsertBlock(self.builder, bb_terminate);
                LLVMInsertExistingBasicBlockAfterInsertBlock(self.builder, bb_wake_up);
                LLVMBuildCondBr(self.builder, terminate, bb_terminate, bb_wake_up);
                // Terminate
                LLVMPositionBuilderAtEnd(self.builder, bb_terminate);
                LLVMBuildRetVoid(self.builder);
                // Continue
                LLVMPositionBuilderAtEnd(self.builder, bb_wake_up);
            }
            _ => bail!("Unsupported opcode {}", data.op),
        };
        Ok(())
    }

    unsafe fn emit_load(
        &self,
        base: LLVMValueRef,
        offset: LLVMValueRef,
        size: usize,
        sext: bool,
    ) -> LLVMValueRef {
        self.read_mem(LLVMBuildAdd(self.builder, base, offset, NONAME), size, sext)
    }

    /// Emit the code for instruction tracing.
    ///
    /// Only emits the code once if called multiple times. Does nothing if the
    /// parent `ElfTranslator` has tracing disabled.
    unsafe fn emit_trace(&self) {
        // Don't emit tracing twice, or if the current basic block has already been terminated.
        if self.trace_emitted.get()
            || !LLVMGetBasicBlockTerminator(LLVMGetInsertBlock(self.builder)).is_null()
        {
            return;
        }
        self.trace_emitted.set(true);

        // Track the cycle counter if enabled
        if self.section.elf.latency {
            // Check for read dependencies
            let accesses = self.trace_accesses.borrow();

            let mut cycles = Vec::new();
            for &(access, _data) in accesses.iter().take(TRACE_BUFFER_LEN as usize) {
                let cycle = match access {
                    TraceAccess::ReadReg(i) => LLVMBuildLoad(
                        self.builder,
                        self.reg_cycle_ptr(i as u32),
                        format!("x{}\0", i).as_ptr() as *const _,
                    ),
                    TraceAccess::ReadFReg(i) => LLVMBuildLoad(
                        self.builder,
                        self.freg_cycle_ptr(i as u32),
                        format!("f{}\0", i).as_ptr() as *const _,
                    ),
                    _ => continue,
                };
                cycles.push(cycle);
            }

            // Load the current cycle counter.
            let mut max_cycle = LLVMBuildLoad(self.builder, self.cycle_ptr(), NONAME);
            // Instruction takes at least one cycle even if all dependencies are ready
            max_cycle = LLVMBuildAdd(
                self.builder,
                max_cycle,
                LLVMConstInt(LLVMTypeOf(max_cycle), 1, 0),
                NONAME,
            );

            // Calculate the maximum
            for c in cycles {
                let is_umax = LLVMBuildICmp(self.builder, LLVMIntUGT, max_cycle, c, NONAME);
                max_cycle = LLVMBuildSelect(self.builder, is_umax, max_cycle, c, NONAME);
            }

            // Store the cycle at which all dependencies are ready and the inst is executed
            LLVMBuildStore(self.builder, max_cycle, self.cycle_ptr());

            // Check if instruction is a memory access
            let mem_access = accesses.iter().find(|(a, _)| match a {
                TraceAccess::ReadMem => true,
                TraceAccess::RMWMem => true,
                _ => false,
            });

            // Get the instruction mnemonic (generated by riscv-opcodes)
            let inst_name = riscv::inst_to_string(self.inst);

            let latency = if let Some(access) = mem_access {
                // Check config
                let (is_tcdm, _tcdm_ptr) = self.emit_tcdm_check(access.1);
                LLVMBuildSelect(
                    self.builder,
                    is_tcdm,
                    LLVMConstInt(
                        LLVMTypeOf(max_cycle),
                        self.section.engine.config.memory.tcdm.latency,
                        0,
                    ),
                    LLVMConstInt(
                        LLVMTypeOf(max_cycle),
                        self.section.engine.config.memory.dram.latency,
                        0,
                    ),
                    NONAME,
                )
            } else {
                // Get instruction's latency or use default of one cycle
                LLVMConstInt(
                    LLVMTypeOf(max_cycle),
                    self.get_latency(inst_name, 1) as u64,
                    0,
                )
            };

            // Add latency of this instruction
            let cycle = LLVMBuildAdd(self.builder, max_cycle, latency, NONAME);

            // Write new dependencies
            for &(access, _data) in accesses.iter().take(TRACE_BUFFER_LEN as usize) {
                match access {
                    // ReadMem => random latency,
                    TraceAccess::WriteReg(i) => {
                        LLVMBuildStore(self.builder, cycle, self.reg_cycle_ptr(i as u32))
                    }
                    TraceAccess::WriteFReg(i) => {
                        LLVMBuildStore(self.builder, cycle, self.freg_cycle_ptr(i as u32))
                    }
                    _ => continue,
                };
            }
        }

        // Don't emit tracing if disabled
        if !self.section.elf.trace {
            return;
        }

        // Compose a list of accesses.
        let accesses = self.trace_accesses.borrow();
        let mut val_access = LLVMConstNull(LLVMArrayType(LLVMInt16Type(), accesses.len() as u32));
        let mut val_data = LLVMConstNull(LLVMArrayType(LLVMInt64Type(), accesses.len() as u32));
        for (i, &(access, data)) in accesses.iter().enumerate().take(TRACE_BUFFER_LEN as usize) {
            let access: u16 = std::mem::transmute(access);
            let data = LLVMBuildZExt(self.builder, data, LLVMInt64Type(), NONAME);
            val_access = LLVMBuildInsertValue(
                self.builder,
                val_access,
                LLVMConstInt(LLVMInt16Type(), access as u64, 0),
                i as u32,
                NONAME,
            );
            val_data = LLVMBuildInsertValue(self.builder, val_data, data, i as u32, NONAME);
        }

        // Move the list of accesses to the stack.
        let ptr_access = LLVMBuildBitCast(
            self.builder,
            self.section.trace_access_buffer,
            LLVMPointerType(LLVMTypeOf(val_access), 0),
            NONAME,
        );
        let ptr_data = LLVMBuildBitCast(
            self.builder,
            self.section.trace_data_buffer,
            LLVMPointerType(LLVMTypeOf(val_data), 0),
            NONAME,
        );
        LLVMBuildStore(self.builder, val_access, ptr_access);
        LLVMBuildStore(self.builder, val_data, ptr_data);
        let ptr_access = LLVMBuildPtrToInt(self.builder, ptr_access, LLVMInt64Type(), NONAME);
        let ptr_data = LLVMBuildPtrToInt(self.builder, ptr_data, LLVMInt64Type(), NONAME);

        // Assemble the slice arguments in the format tha rust expects
        // `(ptr, len)`.
        let len = LLVMConstInt(LLVMInt64Type(), accesses.len() as u64, 0);
        let slice_access = LLVMConstNull(LLVMArrayType(LLVMInt64Type(), 2));
        let slice_access = LLVMBuildInsertValue(self.builder, slice_access, ptr_access, 0, NONAME);
        let slice_access = LLVMBuildInsertValue(self.builder, slice_access, len, 1, NONAME);
        let slice_data = LLVMConstNull(LLVMArrayType(LLVMInt64Type(), 2));
        let slice_data = LLVMBuildInsertValue(self.builder, slice_data, ptr_data, 0, NONAME);
        let slice_data = LLVMBuildInsertValue(self.builder, slice_data, len, 1, NONAME);

        // Call the trace function.
        let addr = LLVMConstInt(LLVMInt32Type(), self.addr as u64, 0);
        let inst = LLVMConstInt(LLVMInt32Type(), self.inst.raw() as u64, 0);
        self.section.emit_call(
            "banshee_trace",
            [self.section.state_ptr, addr, inst, slice_access, slice_data],
        );
    }

    /// Log an access for the trace.
    fn trace_access(&self, access: TraceAccess, data: LLVMValueRef) {
        if !self.trace_disabled.get() {
            self.trace_accesses.borrow_mut().push((access, data));
        }
    }

    /// Emit the code to read-modify-write a CSR with an immediate rs1.
    unsafe fn emit_csr_imm(&self, data: riscv::FormatImm12RdRs1) -> Result<()> {
        self.emit_csr(data, LLVMConstInt(LLVMInt32Type(), data.rs1 as u64, 0))
    }

    /// Emit the code to read-modify-write a CSR with a register rs1.
    unsafe fn emit_csr_reg(&self, data: riscv::FormatImm12RdRs1) -> Result<()> {
        self.emit_csr(data, self.read_reg(data.rs1))
    }

    /// Emit the code to read-modify-write a CSR with an rs1 LLVM value.
    unsafe fn emit_csr(&self, data: riscv::FormatImm12RdRs1, value: LLVMValueRef) -> Result<()> {
        match data.op {
            riscv::OpcodeImm12RdRs1::Csrrw | riscv::OpcodeImm12RdRs1::Csrrwi if data.rd == 0 => {
                self.write_csr(data.imm12, value);
            }
            riscv::OpcodeImm12RdRs1::Csrrw | riscv::OpcodeImm12RdRs1::Csrrwi => {
                let prev = self.read_csr(data.imm12);
                self.write_csr(data.imm12, value);
                self.write_reg(data.rd, prev);
            }
            riscv::OpcodeImm12RdRs1::Csrrs
            | riscv::OpcodeImm12RdRs1::Csrrsi
            | riscv::OpcodeImm12RdRs1::Csrrc
            | riscv::OpcodeImm12RdRs1::Csrrci
                if data.rs1 == 0 =>
            {
                self.write_reg(data.rd, self.read_csr(data.imm12))
            }
            riscv::OpcodeImm12RdRs1::Csrrs | riscv::OpcodeImm12RdRs1::Csrrsi => {
                let prev = self.read_csr(data.imm12);
                let value = LLVMBuildOr(self.builder, prev, value, NONAME);
                self.write_csr(data.imm12, value);
                self.write_reg(data.rd, prev);
            }
            riscv::OpcodeImm12RdRs1::Csrrc | riscv::OpcodeImm12RdRs1::Csrrci => {
                let prev = self.read_csr(data.imm12);
                let value = LLVMBuildAnd(
                    self.builder,
                    prev,
                    LLVMBuildNot(self.builder, value, NONAME),
                    NONAME,
                );
                self.write_csr(data.imm12, value);
                self.write_reg(data.rd, prev);
            }
            _ => unreachable!("non-csr inst {}", data),
        }
        Ok(())
    }

    /// Emit the code necessary to load a value from memory.
    unsafe fn read_mem(&self, addr: LLVMValueRef, size: usize, sext: bool) -> LLVMValueRef {
        self.trace_access(TraceAccess::ReadMem, addr);
        let bb_end = LLVMCreateBasicBlockInContext(self.section.engine.context, NONAME);
        LLVMInsertExistingBasicBlockAfterInsertBlock(self.builder, bb_end);

        // Align the address.
        let aligned_addr = LLVMBuildAnd(
            self.builder,
            addr,
            LLVMConstInt(LLVMInt32Type(), !3, 0),
            NONAME,
        );

        // Check if the address is in the TCDM, and emit a fast access.
        let (is_tcdm, tcdm_ptr) = self.emit_tcdm_check(aligned_addr);
        let bb_tcdm = LLVMCreateBasicBlockInContext(self.section.engine.context, NONAME);
        let bb_notcdm = LLVMCreateBasicBlockInContext(self.section.engine.context, NONAME);
        LLVMInsertExistingBasicBlockAfterInsertBlock(self.builder, bb_tcdm);
        LLVMInsertExistingBasicBlockAfterInsertBlock(self.builder, bb_notcdm);
        LLVMBuildCondBr(self.builder, is_tcdm, bb_tcdm, bb_notcdm);

        // Emit the TCDM fast case.
        LLVMPositionBuilderAtEnd(self.builder, bb_tcdm);
        let value_tcdm = LLVMBuildLoad(self.builder, tcdm_ptr, NONAME);
        LLVMBuildBr(self.builder, bb_end);
        let bb_tcdm = LLVMGetInsertBlock(self.builder);

        // Check if the address is in the SSR configuration space.
        LLVMPositionBuilderAtEnd(self.builder, bb_notcdm);
        let (is_ssr, ssr_ptr, ssr_addr) = self.emit_ssr_check(aligned_addr);
        let bb_ssr = LLVMCreateBasicBlockInContext(self.section.engine.context, NONAME);
        let bb_nossr = LLVMCreateBasicBlockInContext(self.section.engine.context, NONAME);
        LLVMInsertExistingBasicBlockAfterInsertBlock(self.builder, bb_ssr);
        LLVMInsertExistingBasicBlockAfterInsertBlock(self.builder, bb_nossr);
        LLVMBuildCondBr(self.builder, is_ssr, bb_ssr, bb_nossr);

        // Emit the SSR case,
        LLVMPositionBuilderAtEnd(self.builder, bb_ssr);
        let value_ssr = self
            .section
            .emit_call("banshee_ssr_read_cfg", [ssr_ptr, ssr_addr]);
        LLVMBuildBr(self.builder, bb_end);
        let bb_ssr = LLVMGetInsertBlock(self.builder);

        // Emit the regular slow case.
        LLVMPositionBuilderAtEnd(self.builder, bb_nossr);
        let value_slow = LLVMBuildCall(
            self.builder,
            LLVMGetNamedFunction(
                self.section.engine.module,
                "banshee_load\0".as_ptr() as *const _,
            ),
            [
                self.section.state_ptr,
                // LLVMBuildBitCast(
                //     self.builder,
                //     self.section.state_ptr,
                //     LLVMPointerType(LLVMInt8Type(), 0),
                //     NONAME,
                // ),
                aligned_addr,
                LLVMConstInt(LLVMInt8Type(), size as u64, 0),
            ]
            .as_mut_ptr(),
            3,
            NONAME,
        );
        LLVMBuildBr(self.builder, bb_end);
        let bb_nossr = LLVMGetInsertBlock(self.builder);

        // Build the PHI node to bring the two together.
        LLVMPositionBuilderAtEnd(self.builder, bb_end);
        let phi = LLVMBuildPhi(self.builder, LLVMInt32Type(), NONAME);
        LLVMAddIncoming(
            phi,
            [value_tcdm, value_ssr, value_slow].as_mut_ptr(),
            [bb_tcdm, bb_ssr, bb_nossr].as_mut_ptr(),
            3,
        );

        // Align the read.
        let shift = LLVMBuildAnd(
            self.builder,
            addr,
            LLVMConstInt(LLVMInt32Type(), 3, 0),
            NONAME,
        );
        let shift = LLVMBuildMul(
            self.builder,
            shift,
            LLVMConstInt(LLVMInt32Type(), 8, 0),
            NONAME,
        );
        let value = LLVMBuildLShr(self.builder, phi, shift, NONAME);

        // Align narrow reads, and perform truncation and extension.
        let ty = LLVMIntType(8 << size);
        let value = LLVMBuildTrunc(self.builder, value, ty, NONAME);
        let value = if sext {
            LLVMBuildSExt(self.builder, value, LLVMInt32Type(), NONAME)
        } else {
            LLVMBuildZExt(self.builder, value, LLVMInt32Type(), NONAME)
        };

        value
    }

    /// Emit the code necessary to store a value to memory.
    unsafe fn write_mem(&self, addr: LLVMValueRef, value: LLVMValueRef, size: usize) {
        self.trace_access(TraceAccess::WriteMem, addr);
        let bb_end = LLVMCreateBasicBlockInContext(self.section.engine.context, NONAME);
        LLVMInsertExistingBasicBlockAfterInsertBlock(self.builder, bb_end);

        // Check if the address is in the TCDM, and emit a fast access.
        let (is_tcdm, tcdm_ptr) = self.emit_tcdm_check(addr);
        let bb_tcdm = LLVMCreateBasicBlockInContext(self.section.engine.context, NONAME);
        let bb_notcdm = LLVMCreateBasicBlockInContext(self.section.engine.context, NONAME);
        LLVMInsertExistingBasicBlockAfterInsertBlock(self.builder, bb_tcdm);
        LLVMInsertExistingBasicBlockAfterInsertBlock(self.builder, bb_notcdm);
        LLVMBuildCondBr(self.builder, is_tcdm, bb_tcdm, bb_notcdm);

        // Emit the TCDM fast case.
        LLVMPositionBuilderAtEnd(self.builder, bb_tcdm);
        let ty = LLVMIntType(8 << size);
        {
            let pty = LLVMPointerType(ty, 0);
            let value = LLVMBuildTrunc(self.builder, value, ty, NONAME);
            let tcdm_ptr = LLVMBuildBitCast(self.builder, tcdm_ptr, pty, NONAME);
            LLVMBuildStore(self.builder, value, tcdm_ptr);
            LLVMBuildBr(self.builder, bb_end);
        }
        LLVMPositionBuilderAtEnd(self.builder, bb_notcdm);

        // Align the address.
        let aligned_addr = LLVMBuildAnd(
            self.builder,
            addr,
            LLVMConstInt(LLVMInt32Type(), !3, 0),
            NONAME,
        );

        // Compute the misalignment.
        let shift = LLVMBuildAnd(
            self.builder,
            addr,
            LLVMConstInt(LLVMInt32Type(), 3, 0),
            NONAME,
        );
        let shift = LLVMBuildMul(
            self.builder,
            shift,
            LLVMConstInt(LLVMInt32Type(), 8, 0),
            NONAME,
        );

        // Align the data to the address and generate a bit mask.
        let mask = LLVMConstNull(ty);
        let mask = LLVMBuildNot(self.builder, mask, NONAME);
        let mask = LLVMBuildZExt(self.builder, mask, LLVMInt32Type(), NONAME);
        let mask = LLVMBuildShl(self.builder, mask, shift, NONAME);
        let value = LLVMBuildShl(self.builder, value, shift, NONAME);

        // Check if the address is in the SSR configuration space.
        let (is_ssr, ssr_ptr, ssr_addr) = self.emit_ssr_check(aligned_addr);
        let bb_ssr = LLVMCreateBasicBlockInContext(self.section.engine.context, NONAME);
        let bb_nossr = LLVMCreateBasicBlockInContext(self.section.engine.context, NONAME);
        LLVMInsertExistingBasicBlockAfterInsertBlock(self.builder, bb_ssr);
        LLVMInsertExistingBasicBlockAfterInsertBlock(self.builder, bb_nossr);
        LLVMBuildCondBr(self.builder, is_ssr, bb_ssr, bb_nossr);

        // Emit the SSR case.
        LLVMPositionBuilderAtEnd(self.builder, bb_ssr);
        self.section.emit_call(
            "banshee_ssr_write_cfg",
            [ssr_ptr, self.section.state_ptr, ssr_addr, value, mask],
        );
        LLVMBuildBr(self.builder, bb_end);
        LLVMPositionBuilderAtEnd(self.builder, bb_nossr);

        // Emit the regular slow case.
        self.section.emit_call(
            "banshee_store",
            [
                self.section.state_ptr,
                aligned_addr,
                value,
                mask,
                LLVMConstInt(LLVMInt8Type(), size as u64, 0),
            ],
        );
        LLVMBuildBr(self.builder, bb_end);

        // Reconverge.
        LLVMPositionBuilderAtEnd(self.builder, bb_end);
    }

    /// Emit the code to check if an address is within the TCDM.
    ///
    /// Returns an `i1` indicating whether it is as first result, and a pointer
    /// to that location in the TCDM.
    unsafe fn emit_tcdm_check(&self, addr: LLVMValueRef) -> (LLVMValueRef, LLVMValueRef) {
        let tcdm_start = LLVMConstInt(LLVMInt32Type(), self.section.elf.tcdm_start as u64, 0);
        let tcdm_end = LLVMConstInt(LLVMInt32Type(), self.section.elf.tcdm_end as u64, 0);
        let in_range = LLVMBuildAnd(
            self.builder,
            LLVMBuildICmp(self.builder, LLVMIntUGE, addr, tcdm_start, NONAME),
            LLVMBuildICmp(self.builder, LLVMIntULT, addr, tcdm_end, NONAME),
            NONAME,
        );
        let index = LLVMBuildSub(self.builder, addr, tcdm_start, NONAME);
        let pty32 = LLVMPointerType(LLVMInt32Type(), 0);
        let pty8 = LLVMPointerType(LLVMInt8Type(), 0);
        let ptr = LLVMBuildGEP(
            self.builder,
            LLVMBuildBitCast(self.builder, self.tcdm_ptr(), pty8, NONAME),
            [index].as_mut_ptr(),
            1 as u32,
            b"ptr_tcdm\0".as_ptr() as *const _,
        );
        let ptr = LLVMBuildBitCast(self.builder, ptr, pty32, NONAME);
        (in_range, ptr)
    }

    /// Emit the code to check if an address is within the SSR config range.
    ///
    /// Returns an `i1` indicating whether it is as first result, a pointer to
    /// the corresponding SSR state as a second result, and an address within
    /// the SSR config as a third result.
    unsafe fn emit_ssr_check(
        &self,
        addr: LLVMValueRef,
    ) -> (LLVMValueRef, LLVMValueRef, LLVMValueRef) {
        let ssr_start = LLVMConstInt(LLVMInt32Type(), SSR_BASE, 0);
        let ssr_end = LLVMConstInt(
            LLVMInt32Type(),
            SSR_BASE + 32 * 8 * SSR_N_STREAMERS as u64,
            0,
        );
        let ssr_size = LLVMConstInt(LLVMInt32Type(), 32 * 8, 0);
        let in_range = LLVMBuildAnd(
            self.builder,
            LLVMBuildICmp(self.builder, LLVMIntUGE, addr, ssr_start, NONAME),
            LLVMBuildICmp(self.builder, LLVMIntULT, addr, ssr_end, NONAME),
            NONAME,
        );
        let index = LLVMBuildSub(self.builder, addr, ssr_start, NONAME);
        let subaddr = LLVMBuildURem(self.builder, index, ssr_size, NONAME);
        let index = LLVMBuildUDiv(self.builder, index, ssr_size, NONAME);
        let ptr = self.ssr_dyn_ptr(index);
        (in_range, ptr, subaddr)
    }

    /// Emit the code necessary to read a value from a register.
    unsafe fn read_reg(&self, rs: u32) -> LLVMValueRef {
        if rs == 0 {
            LLVMConstInt(LLVMInt32Type(), 0, 0)
        } else {
            let ptr = self.reg_ptr(rs);
            let data = LLVMBuildLoad(self.builder, ptr, format!("x{}\0", rs).as_ptr() as *const _);
            self.trace_access(TraceAccess::ReadReg(rs as u8), data);
            data
        }
    }

    /// Emit the code necessary to write a value to a register.
    unsafe fn write_reg(&self, rd: u32, data: LLVMValueRef) {
        if rd != 0 {
            let ptr = self.reg_ptr(rd);
            self.trace_access(TraceAccess::WriteReg(rd as u8), data);
            LLVMBuildStore(self.builder, data, ptr);
        }
    }

    /// Emit the code necessary to read a value from a float register.
    unsafe fn read_freg(&self, rs: u32) -> LLVMValueRef {
        self.emit_possible_ssr_read(rs);
        let ptr = self.freg_ptr(rs);
        let data = LLVMBuildLoad(self.builder, ptr, format!("f{}\0", rs).as_ptr() as *const _);
        self.trace_access(TraceAccess::ReadFReg(rs as u8), data);
        data
    }

    /// Emit the code necessary to write a value to a float register.
    unsafe fn write_freg(&self, rd: u32, data: LLVMValueRef) {
        let ptr = self.freg_ptr(rd);
        self.trace_access(TraceAccess::WriteFReg(rd as u8), data);
        LLVMBuildStore(self.builder, data, ptr);
    }

    /// Emit the code to read a f64 value from a float register.
    unsafe fn read_freg_f64(&self, rs: u32) -> LLVMValueRef {
        self.emit_possible_ssr_read(rs);
        let raw_ptr = self.freg_ptr(rs);
        self.trace_access(
            TraceAccess::ReadFReg(rs as u8),
            LLVMBuildLoad(self.builder, raw_ptr, NONAME),
        );
        let ptr = LLVMBuildBitCast(
            self.builder,
            raw_ptr,
            LLVMPointerType(LLVMDoubleType(), 0),
            NONAME,
        );
        LLVMBuildLoad(self.builder, ptr, format!("f{}\0", rs).as_ptr() as *const _)
    }

    /// Emit the code to read a f32 value from a float register.
    unsafe fn read_freg_f32(&self, rs: u32) -> LLVMValueRef {
        self.emit_possible_ssr_read(rs);
        let raw_ptr = self.freg_ptr(rs);
        self.trace_access(
            TraceAccess::ReadFReg(rs as u8),
            LLVMBuildLoad(self.builder, raw_ptr, NONAME),
        );
        let ptr = LLVMBuildBitCast(
            self.builder,
            raw_ptr,
            LLVMPointerType(LLVMFloatType(), 0),
            NONAME,
        );
        LLVMBuildLoad(self.builder, ptr, format!("f{}\0", rs).as_ptr() as *const _)
    }

    /// Emit the code to write a f64 value to a float register.
    unsafe fn write_freg_f64(&self, rd: u32, data: LLVMValueRef) {
        let raw_ptr = self.freg_ptr(rd);
        let ptr = LLVMBuildBitCast(
            self.builder,
            raw_ptr,
            LLVMPointerType(LLVMDoubleType(), 0),
            NONAME,
        );
        LLVMBuildStore(self.builder, data, ptr);
        self.trace_access(
            TraceAccess::WriteFReg(rd as u8),
            LLVMBuildLoad(self.builder, raw_ptr, NONAME),
        );
    }

    /// Emit the code to write a f32 value to a float register.
    unsafe fn write_freg_f32(&self, rd: u32, data: LLVMValueRef) {
        let raw_ptr = self.freg_ptr(rd);

        // Nanbox the value.
        let ptr_hi = LLVMBuildBitCast(
            self.builder,
            raw_ptr,
            LLVMPointerType(LLVMInt32Type(), 0),
            NONAME,
        );
        let ptr_hi = LLVMBuildGEP(
            self.builder,
            ptr_hi,
            [LLVMConstInt(LLVMInt32Type(), 1, 0)].as_mut_ptr(),
            1 as u32,
            NONAME,
        );
        LLVMBuildStore(
            self.builder,
            LLVMConstInt(LLVMInt32Type(), -1i32 as u64, 0),
            ptr_hi,
        );

        // Write the actual value.
        let ptr = LLVMBuildBitCast(
            self.builder,
            raw_ptr,
            LLVMPointerType(LLVMFloatType(), 0),
            NONAME,
        );
        LLVMBuildStore(self.builder, data, ptr);
        self.trace_access(
            TraceAccess::WriteFReg(rd as u8),
            LLVMBuildLoad(self.builder, raw_ptr, NONAME),
        );
    }

    /// Emit the code to load the next value of an SSR, if enabled.
    unsafe fn emit_possible_ssr_read(&self, rs: u32) {
        // Don't do anything for registers which are not SSR-enabled.
        if rs >= 2 {
            return;
        }

        // Check if SSRs are enabled.
        let enabled_ptr = self.ssr_enabled_ptr();
        let enabled = LLVMBuildLoad(self.builder, enabled_ptr, NONAME);
        let enabled = LLVMBuildTrunc(self.builder, enabled, LLVMInt1Type(), NONAME);

        let bb_ssron = LLVMCreateBasicBlockInContext(self.section.engine.context, NONAME);
        let bb_ssroff = LLVMCreateBasicBlockInContext(self.section.engine.context, NONAME);
        LLVMInsertExistingBasicBlockAfterInsertBlock(self.builder, bb_ssron);
        LLVMInsertExistingBasicBlockAfterInsertBlock(self.builder, bb_ssroff);
        LLVMBuildCondBr(self.builder, enabled, bb_ssron, bb_ssroff);

        // Emit the SSR load.
        LLVMPositionBuilderAtEnd(self.builder, bb_ssron);
        // Otherwise we trace the loads, which are conditional on SSRs being
        // enabled, which will cause the resulting IR to have dominance issues
        // (since execution might have taken the path through the non-ssr
        // access, but the tracing slot would still be allocated).
        let td = self.trace_disabled.replace(true);
        let addr = self.section.emit_call(
            "banshee_ssr_next",
            [self.ssr_ptr(rs), self.section.state_ptr],
        );
        self.emit_fld(rs, addr);
        self.trace_disabled.set(td);
        LLVMBuildBr(self.builder, bb_ssroff);

        // Emit a block for the remainder of the operation.
        LLVMPositionBuilderAtEnd(self.builder, bb_ssroff);
    }

    /// Emit the code necessary to read a value from a register.
    unsafe fn read_csr(&self, csr: u32) -> LLVMValueRef {
        LLVMBuildCall(
            self.builder,
            LLVMGetNamedFunction(
                self.section.engine.module,
                "banshee_csr_read\0".as_ptr() as *const _,
            ),
            [
                self.section.state_ptr,
                LLVMConstInt(LLVMInt16Type(), csr as u64, 0),
            ]
            .as_mut_ptr(),
            2,
            NONAME,
        )
    }

    /// Emit the code necessary to write a value to a register.
    unsafe fn write_csr(&self, csr: u32, data: LLVMValueRef) {
        LLVMBuildCall(
            self.builder,
            LLVMGetNamedFunction(
                self.section.engine.module,
                "banshee_csr_write\0".as_ptr() as *const _,
            ),
            [
                self.section.state_ptr,
                LLVMConstInt(LLVMInt16Type(), csr as u64, 0),
                data,
            ]
            .as_mut_ptr(),
            3,
            NONAME,
        );
    }

    unsafe fn reg_ptr(&self, r: u32) -> LLVMValueRef {
        assert!(r < 32);
        self.section.emit_call_with_name(
            "banshee_reg_ptr",
            [
                self.section.state_ptr,
                LLVMConstInt(LLVMInt32Type(), r as u64, 0),
            ],
            &format!("ptr_x{}", r),
        )
    }

    unsafe fn reg_cycle_ptr(&self, r: u32) -> LLVMValueRef {
        assert!(r < 32);
        self.section.emit_call_with_name(
            "banshee_reg_cycle_ptr",
            [
                self.section.state_ptr,
                LLVMConstInt(LLVMInt32Type(), r as u64, 0),
            ],
            &format!("ptr_x{}", r),
        )
    }

    unsafe fn freg_ptr(&self, r: u32) -> LLVMValueRef {
        assert!(r < 32);
        self.section.emit_call_with_name(
            "banshee_freg_ptr",
            [
                self.section.state_ptr,
                LLVMConstInt(LLVMInt32Type(), r as u64, 0),
            ],
            &format!("ptr_f{}", r),
        )
    }

    unsafe fn freg_cycle_ptr(&self, r: u32) -> LLVMValueRef {
        assert!(r < 32);
        self.section.emit_call_with_name(
            "banshee_freg_cycle_ptr",
            [
                self.section.state_ptr,
                LLVMConstInt(LLVMInt32Type(), r as u64, 0),
            ],
            &format!("ptr_f{}", r),
        )
    }

    unsafe fn pc_ptr(&self) -> LLVMValueRef {
        self.section
            .emit_call_with_name("banshee_pc_ptr", [self.section.state_ptr], "ptr_pc")
    }

    unsafe fn cycle_ptr(&self) -> LLVMValueRef {
        self.section
            .emit_call_with_name("banshee_cycle_ptr", [self.section.state_ptr], "ptr_cycle")
    }

    unsafe fn instret_ptr(&self) -> LLVMValueRef {
        self.section.emit_call_with_name(
            "banshee_instret_ptr",
            [self.section.state_ptr],
            "ptr_instret",
        )
    }

    unsafe fn tcdm_ptr(&self) -> LLVMValueRef {
        self.section
            .emit_call_with_name("banshee_tcdm_ptr", [self.section.state_ptr], "ptr_tcdm")
    }

    unsafe fn ssr_ptr(&self, ssr: u32) -> LLVMValueRef {
        assert!(ssr < SSR_N_STREAMERS);
        self.ssr_dyn_ptr(LLVMConstInt(LLVMInt32Type(), ssr as u64, 0))
    }

    unsafe fn ssr_dyn_ptr(&self, ssr: LLVMValueRef) -> LLVMValueRef {
        self.section.emit_call_with_name(
            "banshee_ssr_ptr",
            [self.section.state_ptr, ssr],
            "ptr_ssr",
        )
    }

    unsafe fn ssr_enabled_ptr(&self) -> LLVMValueRef {
        self.section.emit_call_with_name(
            "banshee_ssr_enabled_ptr",
            [self.section.state_ptr],
            "ptr_ssr_enabled",
        )
    }

    unsafe fn dma_ptr(&self) -> LLVMValueRef {
        self.section
            .emit_call_with_name("banshee_dma_ptr", [self.section.state_ptr], "ptr_dma")
    }

    /// Extract latency from the config file or assign default value
    unsafe fn get_latency(&self, op: String, default_value: u64) -> u64 {
        let latency = &self.section.engine.config.inst_latency.get(&op);
        if let Some(&val) = latency {
            val
        } else {
            default_value
        }
    }
}
