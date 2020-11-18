//! Binary translation

use crate::{
    engine::{Engine, TraceAccess},
    riscv,
};
use anyhow::{anyhow, bail, Context, Result};
use llvm_sys::{core::*, debuginfo::*, prelude::*, LLVMIntPredicate::*, LLVMRealPredicate::*};
use std::{
    cell::{Cell, RefCell},
    collections::{BTreeSet, HashMap},
    ffi::CString,
};

static NONAME: &'static i8 = unsafe { std::mem::transmute("\0".as_ptr()) };

/// Number of arguments the trace maximally shows per instruction.
const TRACE_BUFFER_LEN: u32 = 8;

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
    /// Basic blocks for each instruction address.
    pub inst_bbs: HashMap<u64, LLVMBasicBlockRef>,
    /// Generate instruction tracing code.
    pub trace: bool,
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
            inst_bbs: Default::default(),
            trace: engine.trace,
            tcdm_start: 0x000000,
            tcdm_end: 0x020000,
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

    /// Get an iterator over all instructions in the binary.
    pub fn all_instructions(&self) -> impl Iterator<Item = (u64, riscv::Format)> + '_ {
        self.sections().flat_map(move |s| self.instructions(s))
    }

    /// Analyze the binary and estimate the set of possible branch target
    /// addresses.
    pub fn update_target_addrs(&mut self) {
        let mut target_addrs = BTreeSet::new();

        // Ensure that we can jump to the entry symbol.
        target_addrs.insert(self.elf.ehdr.entry);

        // Ensure that we can jump to the beginning of a section.
        for section in self.sections() {
            target_addrs.insert(section.shdr.addr);
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
    }

    /// Translate the binary.
    pub fn translate(&mut self) -> Result<()> {
        unsafe { self.translate_inner() }
    }

    unsafe fn translate_inner(&mut self) -> Result<()> {
        debug!("Translating binary");
        let builder = LLVMCreateBuilderInContext(self.engine.context);

        // Assemble the struct type which holds the CPU state.
        let state_type = LLVMGetTypeByName(self.engine.module, "cpu\0".as_ptr() as *const _);
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
                let bb = LLVMAppendBasicBlockInContext(
                    self.engine.context,
                    func,
                    format!("inst_0x{:x}\0", addr).as_ptr() as *const _,
                );
                (addr, bb)
            })
            .collect();
        self.inst_bbs = inst_bbs;

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
        let ptr = LLVMGetNamedFunction(
            self.engine.module,
            CString::new(name).unwrap().as_ptr() as *const _,
        );
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

    /// Emit the code for the entire section.
    unsafe fn emit(&self, inst_index: &mut u32) -> Result<()> {
        for (addr, inst) in self.elf.instructions(self.section) {
            let tran = InstructionTranslator {
                section: self,
                builder: self.builder,
                addr,
                inst,
                was_terminator: Default::default(),
                trace_accesses: Default::default(),
                trace_emitted: Default::default(),
            };
            LLVMPositionBuilderAtEnd(self.builder, self.elf.inst_bbs[&addr]);
            match tran.emit(inst_index) {
                Ok(()) => (),
                Err(e) => {
                    error!("{}", e);
                    self.emit_illegal_abort(addr, inst);
                }
            }
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
}

impl<'a> InstructionTranslator<'a> {
    unsafe fn emit(&self, inst_index: &mut u32) -> Result<()> {
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

        // Emit the code for the instruction itself.
        match self.inst {
            riscv::Format::Bimm12hiBimm12loRs1Rs2(x) => self.emit_bimm12hi_bimm12lo_rs1_rs2(x),
            riscv::Format::Imm12Rd(x) => self.emit_imm12_rd(x),
            riscv::Format::Imm12RdRs1(x) => self.emit_imm12_rd_rs1(x),
            riscv::Format::Imm12hiImm12loRs1Rs2(x) => self.emit_imm12hi_imm12lo_rs1_rs2(x),
            riscv::Format::Imm20Rd(x) => self.emit_imm20_rd(x),
            riscv::Format::Jimm20Rd(x) => self.emit_jimm20_rd(x),
            riscv::Format::RdRmRs1(x) => self.emit_rd_rm_rs1(x),
            riscv::Format::RdRmRs1Rs2(x) => self.emit_rd_rm_rs1_rs2(x),
            riscv::Format::RdRmRs1Rs2Rs3(x) => self.emit_rd_rm_rs1_rs2_rs3(x),
            riscv::Format::RdRs1(x) => self.emit_rd_rs1(x),
            riscv::Format::RdRs1Rs2(x) => self.emit_rd_rs1_rs2(x),
            riscv::Format::RdRs1Shamt(x) => self.emit_rd_rs1_shamt(x),
            riscv::Format::Rs1Rs2(x) => self.emit_rs1_rs2(x),
            riscv::Format::Unit(x) => self.emit_unit(x),
            _ => Err(anyhow!("Unsupported instruction format")),
        }
        .with_context(|| format!("Unsupported instruction 0x{:x}: {}", self.addr, self.inst))?;

        // Emit the tracing code if requested.
        self.emit_trace();
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
                let rs2 = self.read_freg(data.rs2);
                let rs2_lo = LLVMBuildTrunc(self.builder, rs2, LLVMInt32Type(), NONAME);
                self.write_mem(addr, rs2_lo, 2);
            }
            riscv::OpcodeImm12hiImm12loRs1Rs2::Fsd => {
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

    unsafe fn emit_imm12_rd(&self, data: riscv::FormatImm12Rd) -> Result<()> {
        let imm = data.imm();
        trace!("{} x{} = 0x{:x}", data.op, data.rd, imm);
        let imm = LLVMConstInt(LLVMInt32Type(), (imm as i64) as u64, 0);
        let name = format!("{}\0", data.op);
        let _name = name.as_ptr() as *const _;
        let value = match data.op {
            riscv::OpcodeImm12Rd::DmStati => self
                .section
                .emit_call("banshee_dma_stat", [self.dma_ptr(), imm]),
            _ => bail!("Unsupported opcode {}", data.op),
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
            riscv::OpcodeImm12RdRs1::Lb => self.emit_load(rs1, imm, 0, false),
            riscv::OpcodeImm12RdRs1::Lh => self.emit_load(rs1, imm, 1, false),
            riscv::OpcodeImm12RdRs1::Lw => self.emit_load(rs1, imm, 2, false),
            riscv::OpcodeImm12RdRs1::Lbu => self.emit_load(rs1, imm, 0, true),
            riscv::OpcodeImm12RdRs1::Lhu => self.emit_load(rs1, imm, 1, true),
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

                // Create a basic block where we land in case of an unpredicted
                // branch target (not in the `target_addrs` set).
                let bb = LLVMCreateBasicBlockInContext(
                    self.section.engine.context,
                    b"\0".as_ptr() as *const _,
                );
                LLVMInsertExistingBasicBlockAfterInsertBlock(self.builder, bb);

                // Emit the switch statement with all branch targets.
                let target_addrs = &self.section.elf.target_addrs;
                let sw = LLVMBuildSwitch(self.builder, target, bb, target_addrs.len() as u32);
                for &addr in target_addrs {
                    LLVMAddCase(
                        sw,
                        LLVMConstInt(LLVMInt32Type(), addr as u64, 0),
                        self.section.elf.inst_bbs[&addr],
                    );
                }

                // Emit the illegal branch code.
                LLVMPositionBuilderAtEnd(self.builder, bb);
                self.section.emit_branch_abort(self.addr, target);
                return Ok(()); // we have already written the link register
            }
            riscv::OpcodeImm12RdRs1::Flw => {
                let raw = self.emit_load(rs1, imm, 2, false);
                let raw = LLVMBuildZExt(self.builder, raw, LLVMInt64Type(), NONAME);
                let pad = LLVMConstInt(LLVMInt64Type(), (-1i64 as u64) << 32, 0);
                let value = LLVMBuildOr(self.builder, raw, pad, NONAME);
                self.write_freg(data.rd, value);
                return Ok(());
            }
            riscv::OpcodeImm12RdRs1::Fld => {
                self.emit_fld(data.rd, LLVMBuildAdd(self.builder, rs1, imm, NONAME));
                return Ok(());
            }
            riscv::OpcodeImm12RdRs1::DmStrti => self.section.emit_call(
                "banshee_dma_strt",
                [
                    self.dma_ptr(),
                    LLVMBuildBitCast(
                        self.builder,
                        self.section.state_ptr,
                        LLVMPointerType(LLVMInt8Type(), 0),
                        NONAME,
                    ),
                    rs1,
                    imm,
                ],
            ),
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
            _ => bail!("Unsupported opcode {}", data.op),
        };
        Ok(())
    }

    unsafe fn emit_rd_rm_rs1_rs2(&self, data: riscv::FormatRdRmRs1Rs2) -> Result<()> {
        trace!("{} f{} = f{}, f{}", data.op, data.rd, data.rs1, data.rs2);
        let name = format!("{}\0", data.op);
        let name = name.as_ptr() as *const _;
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
        let rs1 = self.read_reg(data.rs1);
        let value = match data.op {
            riscv::OpcodeRdRs1::DmStat => self
                .section
                .emit_call("banshee_dma_stat", [self.dma_ptr(), rs1]),
            _ => bail!("Unsupported opcode {}", data.op),
        };
        self.write_reg(data.rd, value);
        Ok(())
    }

    unsafe fn emit_rd_rs1_rs2(&self, data: riscv::FormatRdRs1Rs2) -> Result<()> {
        trace!("{} x{} = x{}, x{}", data.op, data.rd, data.rs1, data.rs2);
        let name = format!("{}\0", data.op);
        let name = name.as_ptr() as *const _;

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
            riscv::OpcodeRdRs1Rs2::DmStrt => self
                .section
                .emit_call("banshee_dma_strt", [self.dma_ptr(), rs1, rs2]),
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

    unsafe fn emit_rs1_rs2(&self, data: riscv::FormatRs1Rs2) -> Result<()> {
        trace!("{} x{}, x{}", data.op, data.rs1, data.rs2);
        let name = format!("{}\0", data.op);
        let _name = name.as_ptr() as *const _;
        let rs1 = self.read_reg(data.rs1);
        let rs2 = self.read_reg(data.rs2);
        match data.op {
            riscv::OpcodeRs1Rs2::DmSrc => self
                .section
                .emit_call("banshee_dma_src", [self.dma_ptr(), rs1, rs2]),
            riscv::OpcodeRs1Rs2::DmDst => self
                .section
                .emit_call("banshee_dma_dst", [self.dma_ptr(), rs1, rs2]),
            _ => bail!("Unsupported opcode {}", data.op),
        };
        Ok(())
    }

    unsafe fn emit_unit(&self, data: riscv::FormatUnit) -> Result<()> {
        trace!("{}", data.op,);
        match data.op {
            riscv::OpcodeUnit::Wfi => {
                self.emit_trace();
                LLVMBuildRetVoid(self.builder)
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
        // Don't emit tracing twice, or if disabled, or if the current basic
        // block has already been terminated.
        if self.trace_emitted.get()
            || !self.section.elf.trace
            || !LLVMGetBasicBlockTerminator(LLVMGetInsertBlock(self.builder)).is_null()
        {
            return;
        }
        self.trace_emitted.set(true);

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
        self.trace_accesses.borrow_mut().push((access, data));
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

        // Check if the address is in the TCDM, and emit a fast access.
        let (is_tcdm, tcdm_ptr) = self.emit_tcdm_check(addr);
        let bb_tcdm = LLVMCreateBasicBlockInContext(self.section.engine.context, NONAME);
        let bb_notcdm = LLVMCreateBasicBlockInContext(self.section.engine.context, NONAME);
        LLVMInsertExistingBasicBlockAfterInsertBlock(self.builder, bb_tcdm);
        LLVMInsertExistingBasicBlockAfterInsertBlock(self.builder, bb_notcdm);
        LLVMBuildCondBr(self.builder, is_tcdm, bb_tcdm, bb_notcdm);

        // Emit the TCDM fast case.
        LLVMPositionBuilderAtEnd(self.builder, bb_tcdm);
        let value_tcdm = LLVMBuildLoad(self.builder, tcdm_ptr, NONAME);
        LLVMBuildBr(self.builder, bb_end);
        LLVMPositionBuilderAtEnd(self.builder, bb_notcdm);

        // Check if the address is in the SSR configuration space.
        let (is_ssr, ssr_ptr, ssr_addr) = self.emit_ssr_check(addr);
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
        LLVMPositionBuilderAtEnd(self.builder, bb_nossr);

        // Emit the regular slow case.
        let bb_slow = bb_nossr;
        let value = LLVMBuildCall(
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
                addr,
                LLVMConstInt(LLVMInt8Type(), size as u64, 0),
            ]
            .as_mut_ptr(),
            3,
            NONAME,
        );
        let value_slow = if sext {
            let ty = LLVMIntType(8 << size);
            let value = LLVMBuildTrunc(self.builder, value, ty, NONAME);
            let value = LLVMBuildSExt(self.builder, value, LLVMInt32Type(), NONAME);
            value
        } else {
            value
        };
        LLVMBuildBr(self.builder, bb_end);

        // Build the PHI node to bring the two together.
        LLVMPositionBuilderAtEnd(self.builder, bb_end);
        let phi = LLVMBuildPhi(self.builder, LLVMInt32Type(), NONAME);
        LLVMAddIncoming(
            phi,
            [value_tcdm, value_ssr, value_slow].as_mut_ptr(),
            [bb_tcdm, bb_ssr, bb_slow].as_mut_ptr(),
            3,
        );
        phi
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
        LLVMBuildStore(self.builder, value, tcdm_ptr);
        LLVMBuildBr(self.builder, bb_end);
        LLVMPositionBuilderAtEnd(self.builder, bb_notcdm);

        // Check if the address is in the SSR configuration space.
        let (is_ssr, ssr_ptr, ssr_addr) = self.emit_ssr_check(addr);
        let bb_ssr = LLVMCreateBasicBlockInContext(self.section.engine.context, NONAME);
        let bb_nossr = LLVMCreateBasicBlockInContext(self.section.engine.context, NONAME);
        LLVMInsertExistingBasicBlockAfterInsertBlock(self.builder, bb_ssr);
        LLVMInsertExistingBasicBlockAfterInsertBlock(self.builder, bb_nossr);
        LLVMBuildCondBr(self.builder, is_ssr, bb_ssr, bb_nossr);

        // Emit the SSR case.
        LLVMPositionBuilderAtEnd(self.builder, bb_ssr);
        self.section
            .emit_call("banshee_ssr_write_cfg", [ssr_ptr, ssr_addr, value]);
        LLVMBuildBr(self.builder, bb_end);
        LLVMPositionBuilderAtEnd(self.builder, bb_nossr);

        // Emit the regular slow case.
        LLVMBuildCall(
            self.builder,
            LLVMGetNamedFunction(
                self.section.engine.module,
                "banshee_store\0".as_ptr() as *const _,
            ),
            [
                self.section.state_ptr,
                // LLVMBuildBitCast(
                //     self.builder,
                //     self.section.state_ptr,
                //     LLVMPointerType(LLVMInt8Type(), 0),
                //     NONAME,
                // ),
                addr,
                value,
                LLVMConstInt(LLVMInt8Type(), size as u64, 0),
            ]
            .as_mut_ptr(),
            4,
            NONAME,
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
        let index = LLVMBuildUDiv(
            self.builder,
            index,
            LLVMConstInt(LLVMInt32Type(), 4, 0),
            NONAME,
        );
        let ptr = LLVMBuildLoad(self.builder, self.tcdm_ptr(), NONAME);
        let ptr = LLVMBuildGEP(
            self.builder,
            ptr,
            [index].as_mut_ptr(),
            1 as u32,
            b"ptr_tcdm\0".as_ptr() as *const _,
        );
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
        let ssr_start = LLVMConstInt(LLVMInt32Type(), 0x204800, 0);
        let ssr_end = LLVMConstInt(LLVMInt32Type(), 0x204800 + 32 * 8 * 2, 0);
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
        let ptr = LLVMBuildGEP(
            self.builder,
            self.section.state_ptr,
            [
                LLVMConstInt(LLVMInt32Type(), 0, 0),
                LLVMConstInt(LLVMInt32Type(), 5, 0),
                index,
            ]
            .as_mut_ptr(),
            3 as u32,
            b"ptr_ssrcfg\0".as_ptr() as *const _,
        );
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
        // LOAD
        let addr = self
            .section
            .emit_call("banshee_ssr_next", [self.ssr_ptr(rs)]);
        self.emit_fld(rs, addr);
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
        // self.section.emit_call_with_name(
        //     "banshee_reg_ptr",
        //     [LLVMConstInt(LLVMInt32Type(), r as u64, 0)],
        //     &format!("ptr_x{}", r),
        // )
        LLVMBuildGEP(
            self.builder,
            self.section.state_ptr,
            [
                LLVMConstInt(LLVMInt32Type(), 0, 0),
                LLVMConstInt(LLVMInt32Type(), 1, 0),
                LLVMConstInt(LLVMInt32Type(), r as u64, 0),
            ]
            .as_mut_ptr(),
            3 as u32,
            format!("ptr_x{}\0", r).as_ptr() as *const _,
        )
    }

    unsafe fn freg_ptr(&self, r: u32) -> LLVMValueRef {
        assert!(r < 32);
        LLVMBuildGEP(
            self.builder,
            self.section.state_ptr,
            [
                LLVMConstInt(LLVMInt32Type(), 0, 0),
                LLVMConstInt(LLVMInt32Type(), 2, 0),
                LLVMConstInt(LLVMInt32Type(), r as u64, 0),
            ]
            .as_mut_ptr(),
            3 as u32,
            format!("ptr_f{}\0", r).as_ptr() as *const _,
        )
    }

    unsafe fn pc_ptr(&self) -> LLVMValueRef {
        LLVMBuildGEP(
            self.builder,
            self.section.state_ptr,
            [
                LLVMConstInt(LLVMInt32Type(), 0, 0),
                LLVMConstInt(LLVMInt32Type(), 3, 0),
            ]
            .as_mut_ptr(),
            2 as u32,
            format!("ptr_pc\0").as_ptr() as *const _,
        )
    }

    unsafe fn instret_ptr(&self) -> LLVMValueRef {
        LLVMBuildGEP(
            self.builder,
            self.section.state_ptr,
            [
                LLVMConstInt(LLVMInt32Type(), 0, 0),
                LLVMConstInt(LLVMInt32Type(), 4, 0),
            ]
            .as_mut_ptr(),
            2 as u32,
            format!("ptr_instret\0").as_ptr() as *const _,
        )
    }

    unsafe fn tcdm_ptr(&self) -> LLVMValueRef {
        LLVMBuildGEP(
            self.builder,
            self.section.state_ptr,
            [
                LLVMConstInt(LLVMInt32Type(), 0, 0),
                LLVMConstInt(LLVMInt32Type(), 8, 0),
            ]
            .as_mut_ptr(),
            2 as u32,
            format!("ptr_tcdm\0").as_ptr() as *const _,
        )
    }

    unsafe fn ssr_ptr(&self, ssr: u32) -> LLVMValueRef {
        LLVMBuildGEP(
            self.builder,
            self.section.state_ptr,
            [
                LLVMConstInt(LLVMInt32Type(), 0, 0),
                LLVMConstInt(LLVMInt32Type(), 5, 0),
                LLVMConstInt(LLVMInt32Type(), ssr as u64, 0),
            ]
            .as_mut_ptr(),
            3 as u32,
            format!("ptr_ssr\0").as_ptr() as *const _,
        )
    }

    unsafe fn ssr_enabled_ptr(&self) -> LLVMValueRef {
        LLVMBuildGEP(
            self.builder,
            self.section.state_ptr,
            [
                LLVMConstInt(LLVMInt32Type(), 0, 0),
                LLVMConstInt(LLVMInt32Type(), 6, 0),
            ]
            .as_mut_ptr(),
            2 as u32,
            format!("ptr_ssr_enabled\0").as_ptr() as *const _,
        )
    }

    unsafe fn dma_ptr(&self) -> LLVMValueRef {
        LLVMBuildGEP(
            self.builder,
            self.section.state_ptr,
            [
                LLVMConstInt(LLVMInt32Type(), 0, 0),
                LLVMConstInt(LLVMInt32Type(), 7, 0),
            ]
            .as_mut_ptr(),
            2 as u32,
            format!("ptr_dma\0").as_ptr() as *const _,
        )
    }
}
