//! Engine for dynamic binary translation and execution

use crate::{riscv, tran::ElfTranslator};
use anyhow::{bail, Result};
use itertools::Itertools;
use llvm_sys::{
    core::*, execution_engine::*, prelude::*, support::*, transforms::pass_manager_builder::*,
};
use std::{
    cell::{Cell, RefCell},
    collections::HashMap,
};

/// An execution engine.
pub struct Engine {
    /// The global LLVM context.
    pub context: LLVMContextRef,
    /// The LLVM module which contains the translated code.
    pub module: LLVMModuleRef,
    /// The exit code set by the binary.
    pub exit_code: Cell<u32>,
    /// Optimize the LLVM IR.
    pub opt_llvm: bool,
    /// Optimize during JIT compilation.
    pub opt_jit: bool,
    /// Enable instruction tracing.
    pub trace: bool,
    /// The global memory.
    pub memory: RefCell<HashMap<u64, u32>>,
}

impl Engine {
    /// Create a new execution engine.
    pub fn new(context: LLVMContextRef) -> Self {
        // Create a new LLVM module ot compile into.
        let module = unsafe {
            let module =
                LLVMModuleCreateWithNameInContext(b"banshee\0".as_ptr() as *const _, context);
            // LLVMSetDataLayout(module, b"i8:8-i16:16-i32:32-i64:64\0".as_ptr() as *const _);
            module
        };

        // Wrap everything up in an engine struct.
        Self {
            context,
            module,
            exit_code: Default::default(),
            opt_llvm: true,
            opt_jit: true,
            trace: false,
            memory: Default::default(),
        }
    }

    /// Translate an ELF binary.
    pub fn translate_elf(&self, elf: &elf::File) -> Result<()> {
        let mut tran = ElfTranslator::new(elf, self);

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
        tran.translate()?;

        // Optimize the translation.
        if self.opt_llvm {
            unsafe { self.optimize() };
        }

        // Copy the executable sections into memory.
        {
            let mut mem = self.memory.borrow_mut();
            for section in &elf.sections {
                if (section.shdr.flags.0 & elf::types::SHF_ALLOC.0) == 0 {
                    continue;
                }
                use byteorder::{LittleEndian, ReadBytesExt};
                trace!("Preloading ELF section `{}`", section.shdr.name);
                mem.extend(
                    section
                        .data
                        .chunks(4)
                        .enumerate()
                        .map(|(offset, mut value)| {
                            let addr = section.shdr.addr + offset as u64 * 4;
                            let value = value.read_u32::<LittleEndian>().unwrap_or(0);
                            trace!("  - 0x{:x} = 0x{:x}", addr, value);
                            (addr, value)
                        }),
                );
            }
        }

        Ok(())
    }

    unsafe fn optimize(&self) {
        debug!("Optimizing IR");
        let mpm = LLVMCreatePassManager();
        // let fpm = LLVMCreateFunctionPassManagerForModule(self.module);

        trace!("Populating pass managers");
        let pmb = LLVMPassManagerBuilderCreate();
        LLVMPassManagerBuilderSetOptLevel(pmb, 3);
        // LLVMPassManagerBuilderPopulateFunctionPassManager(pmb, fpm);
        LLVMPassManagerBuilderPopulateModulePassManager(pmb, mpm);
        LLVMPassManagerBuilderDispose(pmb);

        // trace!("Optimizing function");
        // let func = LLVMGetNamedFunction(self.module, "execute_binary\0".as_ptr() as *const _);
        // LLVMInitializeFunctionPassManager(fpm);
        // LLVMRunFunctionPassManager(fpm, func);
        // LLVMFinalizeFunctionPassManager(fpm);

        trace!("Optimizing entire module");
        LLVMRunPassManager(mpm, self.module);

        LLVMDisposePassManager(mpm);
        // LLVMDisposePassManager(fpm);
    }

    // Execute the loaded memory.
    pub fn execute(&self) -> Result<()> {
        unsafe { self.execute_inner() }
    }

    unsafe fn execute_inner<'b>(&'b self) -> Result<()> {
        // Create a JIT compiler for the module (and consumes it).
        debug!("Creating JIT compiler for translated code");
        let mut ee = std::mem::MaybeUninit::uninit().assume_init();
        let mut errmsg = std::mem::MaybeUninit::zeroed().assume_init();
        let optlevel = if self.opt_jit { 3 } else { 0 };
        LLVMCreateJITCompilerForModule(&mut ee, self.module, optlevel, &mut errmsg);
        if !errmsg.is_null() {
            bail!(
                "Cannot create JIT compiler: {:?}",
                std::ffi::CStr::from_ptr(errmsg)
            )
        }

        // Lookup the function which executes the binary.
        let exec: extern "C" fn(&Cpu<'b>) = std::mem::transmute(LLVMGetFunctionAddress(
            ee,
            b"execute_binary\0".as_ptr() as *const _,
        ));
        debug!("Translated binary is at {:?}", exec as *const i8);

        // Create a CPU.
        let cpu = Cpu::new(self);
        trace!("Initial state: {:#?}", cpu.state);

        // Execute the binary.
        info!("Launching binary");
        let t0 = std::time::Instant::now();
        exec(&cpu);
        let t1 = std::time::Instant::now();
        let duration = (t1.duration_since(t0)).as_secs_f64();

        trace!("Final state: {:#?}", cpu.state);
        info!("Exit code is 0x{:x}", self.exit_code.get());
        info!(
            "Retired {} inst in {} s, {} inst/s",
            cpu.state.instret,
            duration,
            cpu.state.instret as f64 / duration
        );
        Ok(())
    }
}

pub unsafe fn add_llvm_symbols() {
    LLVMAddSymbol(
        b"banshee_load\0".as_ptr() as *const _,
        Cpu::binary_load as *mut _,
    );
    LLVMAddSymbol(
        b"banshee_store\0".as_ptr() as *const _,
        Cpu::binary_store as *mut _,
    );
    LLVMAddSymbol(
        b"banshee_csr_read\0".as_ptr() as *const _,
        Cpu::binary_csr_read as *mut _,
    );
    LLVMAddSymbol(
        b"banshee_csr_write\0".as_ptr() as *const _,
        Cpu::binary_csr_write as *mut _,
    );
    LLVMAddSymbol(
        b"banshee_abort_escape\0".as_ptr() as *const _,
        Cpu::binary_abort_escape as *mut _,
    );
    LLVMAddSymbol(
        b"banshee_abort_illegal_inst\0".as_ptr() as *const _,
        Cpu::binary_abort_illegal_inst as *mut _,
    );
    LLVMAddSymbol(
        b"banshee_abort_illegal_branch\0".as_ptr() as *const _,
        Cpu::binary_abort_illegal_branch as *mut _,
    );
    LLVMAddSymbol(
        b"banshee_trace\0".as_ptr() as *const _,
        Cpu::binary_trace as *mut _,
    );
}

/// A CPU pointer to be passed to the binary code.
#[repr(C)]
pub struct Cpu<'a> {
    engine: &'a Engine,
    state: CpuState,
}

impl<'a> Cpu<'a> {
    /// Create a new CPU in a default state.
    pub fn new(engine: &'a Engine) -> Self {
        Self {
            engine,
            state: Default::default(),
        }
    }

    fn binary_load(&self, addr: u32, size: u8) -> u32 {
        trace!("Load 0x{:x} ({}B)", addr, 8 << size);
        match addr {
            0x40000000 => 0x42000,                     // tcdm_start
            0x40000008 => 0x43000,                     // tcdm_end
            0x40000010 => 1,                           // nr_cores
            0x40000020 => self.engine.exit_code.get(), // scratch_reg
            _ => self
                .engine
                .memory
                .borrow()
                .get(&(addr as u64))
                .copied()
                .unwrap_or(0),
        }
    }

    fn binary_store(&self, addr: u32, value: u32, size: u8) {
        trace!("Store 0x{:x} = 0x{:x} ({}B)", addr, value, 8 << size);
        match addr {
            0x40000020 => self.engine.exit_code.set(value), // scratch_reg
            _ => {
                self.engine.memory.borrow_mut().insert(addr as u64, value);
            }
        }
    }

    fn binary_csr_read(&self, csr: u16) -> u32 {
        trace!("Read CSR 0x{:x}", csr);
        match csr {
            0xF14 => 0, // mhartid
            _ => 0,
        }
    }

    fn binary_csr_write(&self, csr: u16, value: u32) {
        trace!("Write CSR 0x{:x} = 0x{:?}", csr, value);
    }

    fn binary_abort_escape(&self, addr: u32) {
        error!("CPU escaped binary at 0x{:x}", addr);
    }

    fn binary_abort_illegal_inst(&self, addr: u32, inst_raw: u32) {
        error!(
            "Illegal instruction {} at 0x{:x}",
            riscv::parse_u32(inst_raw),
            addr
        );
    }

    fn binary_abort_illegal_branch(&self, addr: u32, target: u32) {
        error!(
            "Branch to unpredicted address 0x{:x} at 0x{:x}",
            target, addr
        );
    }

    fn binary_trace(&self, addr: u32, inst: u32, accesses: &[TraceAccess], data: &[u64]) {
        // Assemble the arguments.
        let args = accesses.iter().copied().zip(data.iter().copied());
        let mut args = args.map(|(access, data)| match access {
            TraceAccess::ReadMem => format!("RA:{:08x}", data as u32),
            TraceAccess::WriteMem => format!("WA:{:08x}", data as u32),
            TraceAccess::ReadReg(x) => format!("x{}:{:08x}", x, data as u32),
            TraceAccess::WriteReg(x) => format!("x{}={:08x}", x, data as u32),
            TraceAccess::ReadFReg(x) => format!("f{}:{:016x}", x, data),
            TraceAccess::WriteFReg(x) => format!("f{}={:016x}", x, data),
        });
        let args = args.join(" ");

        // Assemble the trace line.
        let line = format!("{:08x}  DASM({:08x})    # {}", addr, inst, args);
        println!("{}", line);
    }
}

/// A representation of a single CPU core's state.
#[derive(Default)]
#[repr(C)]
pub struct CpuState {
    regs: [u32; 32],
    fregs: [u64; 32],
    pc: u32,
    instret: u64,
}

impl std::fmt::Debug for CpuState {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        let regs = self
            .regs
            .iter()
            .copied()
            .enumerate()
            .map(|(i, value)| format!("x{:02}: 0x{:08x}", i, value))
            .chunks(4)
            .into_iter()
            .map(|mut chunk| chunk.join("  "))
            .join("\n");
        let fregs = self
            .fregs
            .iter()
            .copied()
            .enumerate()
            .map(|(i, value)| format!("f{:02}: 0x{:016x}", i, value))
            .chunks(4)
            .into_iter()
            .map(|mut chunk| chunk.join("  "))
            .join("\n");
        f.debug_struct("CpuState")
            .field("regs", &format_args!("\n{}", regs))
            .field("fregs", &format_args!("\n{}", fregs))
            .field("pc", &format_args!("0x{:x}", self.pc))
            .field("instret", &self.instret)
            .finish()
    }
}

/// A single register or memory access as recorded in a trace.
#[derive(Debug, Clone, Copy)]
#[repr(C, u8)]
pub enum TraceAccess {
    ReadMem,
    ReadReg(u8),
    ReadFReg(u8),
    WriteMem,
    WriteReg(u8),
    WriteFReg(u8),
}
