//! Engine for dynamic binary translation and execution

use crate::riscv;
use anyhow::{anyhow, Context, Result};
use llvm_sys::{core::*, prelude::*};
use std::collections::{BTreeSet, HashMap};

/// An execution engine.
pub struct Engine {
    /// The global LLVM context.
    pub context: LLVMContextRef,
    /// The LLVM module which contains the translated code.
    pub module: LLVMModuleRef,
}

impl Engine {
    /// Create a new execution engine.
    pub fn new(context: LLVMContextRef) -> Self {
        // Create a new LLVM module ot compile into.
        let module = unsafe {
            let module =
                LLVMModuleCreateWithNameInContext(b"banshee\0".as_ptr() as *const _, context);
            LLVMSetDataLayout(module, b"i8:8-i16:16-i32:32-i64:64\0".as_ptr() as *const _);
            module
        };

        // Wrap everything up in an engine struct.
        Self { context, module }
    }

    /// Translate an ELF binary.
    pub fn translate_elf(&self, elf: &elf::File) -> Result<()> {
        let mut tran = ElfTranslator::new(elf);

        // Dump the contents of the binary.
        debug!("Loading ELF binary");
        for section in tran.sections() {
            debug!(
                "Loading ELF section `{}` from 0x{:x} to 0x{:x}",
                section.shdr.name,
                section.shdr.addr,
                section.shdr.addr + section.shdr.size
            );
            for (addr, inst) in tran.instructions(section) {
                trace!("  - 0x{:x}: {}", addr, inst);
            }
        }

        // Estimate the branch target addresses.
        tran.update_target_addrs();

        // Translate the binary.
        tran.translate(self)?;

        Ok(())
    }
}

/// A translator for an entire ELF file.
pub struct ElfTranslator<'a> {
    pub elf: &'a elf::File,
    /// Predicted branch target addresses.
    pub target_addrs: BTreeSet<u64>,
}

impl<'a> ElfTranslator<'a> {
    /// Create a new ELF file translator.
    pub fn new(elf: &'a elf::File) -> Self {
        Self {
            elf,
            target_addrs: Default::default(),
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
                    let target = (addr as i64).wrapping_add((fmt.bimm() as i64) << 1) as u64;
                    debug!("Found branch 0x{:x}: {} to 0x{:x}", addr, inst, target,);
                    target_addrs.insert(target);
                    target_addrs.insert(addr + 4);
                }
                _ => (),
            }
        }

        // Dump what we have found.
        debug!("Predicted jump targets:");
        for &addr in &target_addrs {
            debug!("  - 0x{:x}", addr);
        }

        self.target_addrs = target_addrs;
    }

    /// Translate the binary.
    pub fn translate(&mut self, engine: &Engine) -> Result<()> {
        unsafe { self.translate_inner(engine) }
    }

    unsafe fn translate_inner(&mut self, engine: &Engine) -> Result<()> {
        debug!("Translating binary");
        let builder = LLVMCreateBuilderInContext(engine.context);

        // Assemble the struct type which holds the CPU state.
        let state_type = LLVMStructCreateNamed(
            engine.context,
            format!("cpu\0").as_bytes().as_ptr() as *const _,
        );
        let mut state_fields = [LLVMArrayType(LLVMInt32Type(), 32)];
        LLVMStructSetBody(
            state_type,
            state_fields.as_mut_ptr(),
            state_fields.len() as u32,
            0,
        );
        let state_ptr_type = LLVMPointerType(state_type, 0u32);

        // Emit the function which will run the binary.
        let func_name = format!("execute_binary\0");
        let func_type = LLVMFunctionType(LLVMVoidType(), [state_ptr_type].as_mut_ptr(), 1, 0);
        let func = LLVMAddFunction(
            engine.module,
            func_name.as_bytes().as_ptr() as *const _,
            func_type,
        );
        let state = LLVMGetParam(func, 0);

        // Create the entry block.
        let entry_bb =
            LLVMAppendBasicBlockInContext(engine.context, func, b"entry\0".as_ptr() as *const _);

        // Create a basic block for every jump target address.
        let target_bbs: HashMap<u64, LLVMBasicBlockRef> = self
            .target_addrs
            .iter()
            .map(|&addr| {
                let bb = LLVMAppendBasicBlockInContext(
                    engine.context,
                    func,
                    format!("inst_0x{:x}\0", addr).as_bytes().as_ptr() as *const _,
                );
                (addr, bb)
            })
            .collect();

        // Emit the branch to the entry symbol.
        LLVMPositionBuilderAtEnd(builder, entry_bb);
        LLVMBuildBr(builder, target_bbs[&self.elf.ehdr.entry]);

        // Emit the instructions.
        for (addr, inst) in self.all_instructions() {
            // Move to the appropriate block if this instruction is the first
            // one in that branch target.
            if let Some(&bb) = target_bbs.get(&addr) {
                // TODO(fschuiki): Check if we are at the last PC + 4 to insert
                // the branch. If we're anywhere else, insert a ret or a call to
                // a function that aborts with a message that we have left the
                // binary space.
                if addr != self.elf.ehdr.entry {
                    LLVMBuildBr(builder, bb);
                }
                LLVMPositionBuilderAtEnd(builder, bb);
                trace!("Moving to 0x{:x}", addr);
            }
            InstructionTranslator {
                elf_tran: self,
                engine,
                func,
                builder,
                addr,
                inst,
                state,
                target_bbs: &target_bbs,
            }
            .emit()
            .map_err(|e| error!("{}", e))
            .ok(); // TODO(fschuiki): Remove and make a `?`
        }

        // Clean up.
        LLVMDisposeBuilder(builder);
        Ok(())
    }
}

pub struct InstructionTranslator<'a> {
    elf_tran: &'a ElfTranslator<'a>,
    engine: &'a Engine,
    func: LLVMValueRef,
    builder: LLVMBuilderRef,
    addr: u64,
    inst: riscv::Format,
    state: LLVMValueRef,
    target_bbs: &'a HashMap<u64, LLVMBasicBlockRef>,
}

impl<'a> InstructionTranslator<'a> {
    unsafe fn emit(&self) -> Result<()> {
        // trace!("Translating {}", self.inst);
        match self.inst {
            riscv::Format::Bimm12hiBimm12loRs1Rs2(x) => self.emit_bimm12hi_bimm12lo_rs1_rs2(x),
            riscv::Format::Imm12RdRs1(x) => self.emit_imm12_rd_rs1(x),
            riscv::Format::Imm20Rd(x) => self.emit_imm20_rd(x),
            riscv::Format::Jimm20Rd(x) => self.emit_jimm20_rd(x),
            riscv::Format::RdRs1Rs2(x) => self.emit_rd_rs1_rs2(x),
            _ => Err(anyhow!("Unsupported instruction format")),
        }
        .with_context(|| format!("Unsupported instruction 0x{:x}: {}", self.addr, self.inst))
    }

    unsafe fn emit_bimm12hi_bimm12lo_rs1_rs2(
        &self,
        data: riscv::FormatBimm12hiBimm12loRs1Rs2,
    ) -> Result<()> {
        let target = (self.addr as i64).wrapping_add((data.bimm() as i64) << 1) as u64;
        trace!("{} x{}, x{}, 0x{:x}", data.op, data.rs1, data.rs2, target);
        let rs1 = self.read_reg(data.rs1);
        let rs2 = self.read_reg(data.rs2);
        let name = format!("{}_x{}_x{}\0", data.op, data.rs1, data.rs2);
        let name = name.as_bytes().as_ptr() as *const _;
        use llvm::LLVMIntPredicate::*;
        let predicate = match data.op {
            riscv::OpcodeBimm12hiBimm12loRs1Rs2::Beq => LLVMIntEQ,
            riscv::OpcodeBimm12hiBimm12loRs1Rs2::Bne => LLVMIntNE,
            riscv::OpcodeBimm12hiBimm12loRs1Rs2::Blt => LLVMIntSLT,
            riscv::OpcodeBimm12hiBimm12loRs1Rs2::Bge => LLVMIntSGE,
            riscv::OpcodeBimm12hiBimm12loRs1Rs2::Bltu => LLVMIntULT,
            riscv::OpcodeBimm12hiBimm12loRs1Rs2::Bgeu => LLVMIntUGE,
        };
        let cmp = LLVMBuildICmp(self.builder, predicate, rs1, rs2, name);
        let bb = LLVMAppendBasicBlockInContext(
            self.engine.context,
            self.func,
            b"\0".as_ptr() as *const _,
        );
        LLVMBuildCondBr(self.builder, cmp, self.target_bbs[&target], bb);
        LLVMPositionBuilderAtEnd(self.builder, bb);
        Ok(())
    }

    unsafe fn emit_imm12_rd_rs1(&self, data: riscv::FormatImm12RdRs1) -> Result<()> {
        match data.op {
            riscv::OpcodeImm12RdRs1::Addi => {
                let value = data.imm();
                trace!("addi x{} = x{} + 0x{:x}", data.rd, data.rs1, value);
                let rs1 = self.read_reg(data.rs1);
                let value = LLVMBuildAdd(
                    self.builder,
                    rs1,
                    LLVMConstInt(LLVMInt32Type(), (value as i64) as u64, 0),
                    format!("addi\0").as_bytes().as_ptr() as *const _,
                );
                self.write_reg(data.rd, value);
                Ok(())
            }
            _ => Err(anyhow!("Unsupported opcode {}", data.op)),
        }
    }

    unsafe fn emit_imm20_rd(&self, data: riscv::FormatImm20Rd) -> Result<()> {
        match data.op {
            riscv::OpcodeImm20Rd::Auipc => {
                let value = (self.addr as u32).wrapping_add(data.imm20 << 12);
                trace!("auipc x{} = 0x{:x}", data.rd, value);
                self.write_reg(data.rd, LLVMConstInt(LLVMInt32Type(), value as u64, 0));
                Ok(())
            }
            _ => Err(anyhow!("Unsupported opcode {}", data.op)),
        }
    }

    unsafe fn emit_jimm20_rd(&self, data: riscv::FormatJimm20Rd) -> Result<()> {
        match data.op {
            riscv::OpcodeJimm20Rd::Jal => {
                let target = (self.addr as i64).wrapping_add(data.jimm() as i64) as u64;
                trace!("jal x{}, 0x{:x}", data.rd, target);
                LLVMBuildBr(self.builder, self.target_bbs[&target]);
                Ok(())
            }
        }
    }

    unsafe fn emit_rd_rs1_rs2(&self, data: riscv::FormatRdRs1Rs2) -> Result<()> {
        trace!("{} x{} = x{}, x{}", data.op, data.rd, data.rs1, data.rs2);
        let rs1 = self.read_reg(data.rs1);
        let rs2 = self.read_reg(data.rs2);
        let name = format!("{}\0", data.op);
        let name = name.as_bytes().as_ptr() as *const _;
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
            _ => return Err(anyhow!("Unsupported opcode {}", data.op)),
        };
        self.write_reg(data.rd, value);
        Ok(())
    }

    unsafe fn read_reg(&self, rs: u32) -> LLVMValueRef {
        let ptr = self.reg_ptr(rs);
        LLVMBuildLoad(
            self.builder,
            ptr,
            format!("x{}\0", rs).as_bytes().as_ptr() as *const _,
        )
    }

    unsafe fn write_reg(&self, rd: u32, data: LLVMValueRef) {
        let ptr = self.reg_ptr(rd);
        LLVMBuildStore(self.builder, data, ptr);
    }

    unsafe fn reg_ptr(&self, r: u32) -> LLVMValueRef {
        assert!(r < 32);
        LLVMBuildGEP(
            self.builder,
            self.state,
            [
                LLVMConstInt(LLVMInt32Type(), 0, 0),
                LLVMConstInt(LLVMInt32Type(), 0, 0),
                LLVMConstInt(LLVMInt32Type(), r as u64, 0),
            ]
            .as_mut_ptr(),
            3 as u32,
            format!("ptr_x{}\0", r).as_bytes().as_ptr() as *const _,
        )
    }
}
