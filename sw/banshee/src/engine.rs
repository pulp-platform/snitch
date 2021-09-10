// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

//! Engine for dynamic binary translation and execution

use crate::{peripherals::Peripherals, riscv, tran::ElfTranslator, util::SiUnit, Configuration};
extern crate flexfloat;
extern crate termion;
use anyhow::{anyhow, bail, Result};
use itertools::Itertools;
use llvm_sys::{
    analysis::*, core::*, execution_engine::*, ir_reader::*, linker::*, prelude::*, support::*,
    target_machine::*, transforms::pass_manager_builder::*,
};
use std::{
    collections::HashMap,
    sync::{
        atomic::{AtomicBool, AtomicU32, AtomicU64, AtomicUsize, Ordering},
        Mutex,
    },
};
use termion::{color, style};

pub use crate::runtime::{Cpu, CpuState, DmaState, SsrState};

/// An execution engine.
pub struct Engine {
    /// The global LLVM context.
    pub context: LLVMContextRef,
    /// The LLVM modules which contains the translated code for each cluster.
    pub modules: Vec<LLVMModuleRef>,
    /// The exit code set by the binary.
    pub exit_code: AtomicU32,
    /// Whether an error occurred during execution.
    pub had_error: AtomicBool,
    /// Optimize the LLVM IR.
    pub opt_llvm: bool,
    /// Optimize during JIT compilation.
    pub opt_jit: bool,
    /// Enable interrupt support.
    pub interrupt: bool,
    /// Enable instruction tracing.
    pub trace: bool,
    /// Enable instruction latency.
    pub latency: bool,
    /// The base hartid.
    pub base_hartid: usize,
    /// The number of cores.
    pub num_cores: usize,
    /// The number of clusters.
    pub num_clusters: usize,
    /// The system configuration.
    pub config: Configuration,
    // pub config: Configuration,
    /// The global memory.
    pub memory: Mutex<HashMap<u64, u32>>,
    /// The per-core putchar buffers (per hartid).
    pub putchar_buffer: Mutex<HashMap<usize, Vec<u8>>>,
    /// The peripherals for each cluster
    peripherals: Peripherals,
}

// SAFETY: This is safe because only `context` and `module`
unsafe impl std::marker::Send for Engine {}
unsafe impl std::marker::Sync for Engine {}

impl Engine {
    /// Create a new execution engine.
    pub fn new(context: LLVMContextRef) -> Self {
        // Wrap everything up in an engine struct.
        Self {
            context,
            modules: Default::default(),
            exit_code: Default::default(),
            had_error: Default::default(),
            opt_llvm: true,
            opt_jit: true,
            interrupt: true,
            trace: false,
            latency: false,
            base_hartid: 0,
            num_cores: 1,
            num_clusters: 1,
            config: Default::default(),
            memory: Default::default(),
            putchar_buffer: Default::default(),
            peripherals: Peripherals::new(),
        }
    }

    /// Create a Module for each cluster
    pub fn create_modules(&mut self) {
        for i in 0..self.num_clusters {
            let module = unsafe {
                // Wrap the runtime IR up in an LLVM memory buffer.
                let mut initial_ir = crate::runtime::JIT_INITIAL
                    .replace("Cpu", format!("{}{}", "Cpu", i.to_string()).as_str())
                    .as_bytes()
                    .to_vec();
                initial_ir.push(0); // somehow this is needed despite RequireNullTerminated=0 below
                let initial_buf = LLVMCreateMemoryBufferWithMemoryRange(
                    initial_ir.as_ptr() as *const _,
                    initial_ir.len() - 1,
                    b"jit.ll\0".as_ptr() as *const _,
                    0,
                );

                // Parse the module.
                let mut module = std::mem::MaybeUninit::uninit().assume_init();
                let mut errmsg = std::mem::MaybeUninit::zeroed().assume_init();
                if LLVMParseIRInContext(self.context, initial_buf, &mut module, &mut errmsg) != 0
                    || !errmsg.is_null()
                {
                    error!(
                        "Cannot parse `jit.ll` IR: {:?}",
                        std::ffi::CStr::from_ptr(errmsg)
                    );
                }

                // let module =
                //     LLVMModuleCreateWithNameInContext(b"banshee\0".as_ptr() as *const _, context);
                // LLVMSetDataLayout(module, b"i8:8-i16:16-i32:32-i64:64\0".as_ptr() as *const _);
                module
            };

            self.modules.push(module);
        }
    }

    /// Translate an ELF binary.
    pub fn translate_elf(&self, elf: &elf::File) -> Result<()> {
        for i in 0..self.num_clusters {
            let mut tran = ElfTranslator::new(elf, self, i);

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

            // Load and link the LLVM IR for the `jit.rs` runtime library.
            unsafe {
                let mut runtime_ir = crate::runtime::JIT_GENERATED.to_vec();
                runtime_ir.push(0); // somehow this is needed despite RequireNullTerminated=0 below
                let runtime_buf = LLVMCreateMemoryBufferWithMemoryRange(
                    runtime_ir.as_ptr() as *const _,
                    runtime_ir.len() - 1,
                    b"jit.rs\0".as_ptr() as *const _,
                    0,
                );

                // Parse the module.
                let mut runtime = std::mem::MaybeUninit::uninit().assume_init();
                let mut errmsg = std::mem::MaybeUninit::zeroed().assume_init();
                if LLVMParseIRInContext(self.context, runtime_buf, &mut runtime, &mut errmsg) != 0
                    || !errmsg.is_null()
                {
                    error!(
                        "Cannot parse `jit.rs` IR: {:?}",
                        std::ffi::CStr::from_ptr(errmsg)
                    );
                }

                // Link the runtime module into the translated binary module.
                LLVMLinkModules2(self.modules[i], runtime);
            };

            // Verify that nothing is broken at this point.
            let failed = unsafe {
                LLVMVerifyModule(
                    self.modules[i],
                    LLVMVerifierFailureAction::LLVMPrintMessageAction,
                    std::ptr::null_mut(),
                )
            };
            if failed != 0 {
                let path = "/tmp/banshee_failed.ll";
                unsafe {
                    LLVMPrintModuleToFile(
                        self.modules[i],
                        format!("{}\0", path).as_ptr() as *const _,
                        std::ptr::null_mut(),
                    );
                }
                bail!(
                    "LLVM module did not pass verification (failing IR written to {})",
                    path
                );
            }
        }

        // Optimize the translation.
        if self.opt_llvm {
            unsafe { self.optimize() };
        }

        // Copy the executable sections into memory.
        {
            let mut mem = self.memory.lock().unwrap();
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

        // Create the pass managers.
        for i in 0..self.num_clusters {
            let func_passes = LLVMCreateFunctionPassManagerForModule(self.modules[i]);
            let module_passes = LLVMCreatePassManager();

            // Determine the target machine we are running on.
            let tm_triple = LLVMGetDefaultTargetTriple();
            let mut tm_target = std::ptr::null_mut();
            let mut tm_target_msg = std::ptr::null_mut();
            assert_eq!(
                LLVMGetTargetFromTriple(tm_triple, &mut tm_target, &mut tm_target_msg),
                0
            );
            let tm_cpu = LLVMGetHostCPUName();
            let tm_features = LLVMGetHostCPUFeatures();
            let tm = LLVMCreateTargetMachine(
                tm_target,
                tm_triple,
                tm_cpu,
                tm_features,
                LLVMCodeGenOptLevel::LLVMCodeGenLevelAggressive,
                LLVMRelocMode::LLVMRelocDefault,
                LLVMCodeModel::LLVMCodeModelJITDefault,
            );
            LLVMDisposeMessage(tm_triple);
            LLVMDisposeMessage(tm_cpu);
            LLVMDisposeMessage(tm_features);

            // Create a pass manager builder.
            let builder = LLVMPassManagerBuilderCreate();
            LLVMPassManagerBuilderSetOptLevel(builder, 3);
            LLVMPassManagerBuilderSetSizeLevel(builder, 0);
            LLVMPassManagerBuilderUseInlinerWithThreshold(builder, 275);

            LLVMPassManagerBuilderPopulateFunctionPassManager(builder, func_passes);
            LLVMAddAnalysisPasses(tm, module_passes);
            LLVMPassManagerBuilderPopulateLTOPassManager(builder, module_passes, 0, 1);
            LLVMPassManagerBuilderPopulateModulePassManager(builder, module_passes);

            // Create and run the function pass manager.
            LLVMInitializeFunctionPassManager(func_passes);
            let mut func = LLVMGetFirstFunction(self.modules[i]);
            while !func.is_null() {
                let mut name_len = 0;
                let name = LLVMGetValueName2(func, &mut name_len);
                let name = std::slice::from_raw_parts(name as *const u8, name_len as usize);
                let name = std::str::from_utf8_unchecked(name);
                trace!("  - Optimizing function {}", name);
                LLVMRunFunctionPassManager(func_passes, func);
                func = LLVMGetNextFunction(func);
            }
            LLVMFinalizeFunctionPassManager(func_passes);

            // Create and run the module pass manager.
            trace!("  - Optimizing module");
            LLVMRunPassManager(module_passes, self.modules[i]);

            // Clean up.
            LLVMPassManagerBuilderDispose(builder);
            LLVMDisposePassManager(func_passes);
            LLVMDisposePassManager(module_passes);
            LLVMDisposeTargetMachine(tm);
        }
    }

    pub fn init_periphs(&mut self) {
        (0..self.num_clusters).for_each(|i| {
            self.peripherals
                .add_cluster(&self.config.memory[i].periphs.callbacks)
        })
    }

    // Execute the loaded memory.
    pub fn execute(&self) -> Result<u32> {
        unsafe { self.execute_inner() }
    }

    unsafe fn execute_inner<'b>(&'b self) -> Result<u32> {
        // Create a JIT compiler for the module (and consumes it).
        debug!("Creating JIT compiler for translated code");
        let execs: Vec<_> = (0..self.num_clusters)
            .map(|i| {
                let mut ee = std::mem::MaybeUninit::uninit().assume_init();
                let mut errmsg = std::mem::MaybeUninit::zeroed().assume_init();
                let optlevel = if self.opt_jit { 3 } else { 0 };
                LLVMCreateJITCompilerForModule(&mut ee, self.modules[i], optlevel, &mut errmsg);
                if !errmsg.is_null() {
                    panic!(
                        "Cannot create JIT compiler: {:?}",
                        std::ffi::CStr::from_ptr(errmsg)
                    )
                }

                // Lookup the function which executes the binary.
                let exec: for<'c> extern "C" fn(&'c Cpu<'b, 'c>) = std::mem::transmute(
                    LLVMGetFunctionAddress(ee, b"execute_binary\0".as_ptr() as *const _),
                );
                debug!("Translated binary is at {:?}", exec as *const i8);
                exec
            })
            .collect();

        // Allocate some TCDM memories.
        let tcdms: Vec<_> = (0..self.num_clusters)
            .map(|i| {
                let mut tcdm = vec![
                    0u32;
                    ((self.config.memory[i].tcdm.end - self.config.memory[i].tcdm.start) / 4)
                        as usize
                ];

                for (&addr, &value) in self.memory.lock().unwrap().iter() {
                    if (addr as u32) >= self.config.memory[i].tcdm.start
                        && (addr as u32) < self.config.memory[i].tcdm.end
                    {
                        tcdm[((addr - (self.config.memory[i].tcdm.start as u64)) / 4) as usize] =
                            value;
                    }
                }

                tcdm
            })
            .collect();

        // External TCDM
        let ext_tcdms: Vec<_> = (0..self.num_clusters).map(|i| &tcdms[i][0]).collect();

        // Allocate some barriers.
        let barriers: Vec<_> = (0..self.num_clusters)
            .map(|_| AtomicUsize::new(0))
            .collect();

        // Allocate global variables to keep track of sleeping cores.
        let num_sleep = AtomicUsize::new(0);
        let wake_up: Vec<_> = (0..self.num_clusters * self.num_cores)
            .map(|_| AtomicU64::new(0))
            .collect();

        // Allocate CLINT registers
        let n_virt_cores = self.num_clusters * self.num_cores + self.base_hartid;
        let clint: Vec<_> = (0..(n_virt_cores + 32 - 1) / 32)
            .map(|_| AtomicU32::new(0))
            .collect();

        // Create the CPUs.
        let cpus: Vec<_> = (0..self.num_clusters)
            .flat_map(|j| (0..self.num_cores).map(move |i| (j, i)))
            .map(|(j, i)| {
                let base_hartid = self.base_hartid + j * self.num_cores;
                Cpu::new(
                    self,
                    &tcdms[j][0],
                    &ext_tcdms,
                    base_hartid + i,
                    self.num_cores,
                    base_hartid,
                    j,
                    &barriers[j],
                    &num_sleep,
                    &wake_up,
                    &clint,
                )
            })
            .collect();
        trace!(
            "Initial state hart {}: {:#?}",
            cpus[0].hartid,
            cpus[0].state
        );

        // Execute the binary.
        info!("Launching binary on {} harts", cpus.len());
        let t0 = std::time::Instant::now();
        crossbeam_utils::thread::scope(|s| {
            for cpu in &cpus {
                let exec = execs[cpu.cluster_id];
                s.spawn(move |_| {
                    exec(cpu);
                    debug!("Hart {} finished", cpu.hartid);
                });
            }
        })
        .unwrap();
        let t1 = std::time::Instant::now();
        let duration = (t1.duration_since(t0)).as_secs_f64();
        debug!("All {} harts finished", cpus.len());

        // Count the number of instructions that we have retired.
        let instret: u64 = cpus.iter().map(|cpu| cpu.state.instret).sum();

        // Print some final statistics.
        trace!("Final state hart {}: {:#?}", cpus[0].hartid, cpus[0].state);
        // Fetch the return value {ret[31:1] = exit_code, ret[0] = exit_code_valid}
        let ret = self.exit_code.load(Ordering::SeqCst);
        if (ret & 0x1) == 0x1 {
            info!("Exit code is 0x{:x}", ret >> 1);
        } else {
            warn!("Exit code register was empty.")
        }
        info!(
            "Retired {} ({}) in {}, {}",
            instret,
            (instret as isize).si_unit("inst"),
            duration.si_unit("s"),
            (instret as f64 / duration).si_unit("inst/s"),
        );
        if self.had_error.load(Ordering::SeqCst) {
            Err(anyhow!("Encountered an error during execution"))
        } else if (ret & 0x1) != 0x1 {
            // Call the police if no return value was specified
            Ok(117)
        } else {
            Ok(ret >> 1)
        }
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
        b"banshee_rmw\0".as_ptr() as *const _,
        Cpu::binary_rmw as *mut _,
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
    LLVMAddSymbol(
        b"banshee_wfi\0".as_ptr() as *const _,
        Cpu::binary_wfi as *mut _,
    );
    LLVMAddSymbol(
        b"banshee_check_clint\0".as_ptr() as *const _,
        Cpu::binary_check_clint as *mut _,
    );
    LLVMAddSymbol(
        b"banshee_fp16_op_cvt_from_f\0".as_ptr() as *const _,
        Cpu::binary_fp16_op_cvt_from_f as *mut _,
    );
    LLVMAddSymbol(
        b"banshee_fp64_op_cvt_to_f\0".as_ptr() as *const _,
        Cpu::binary_fp64_op_cvt_to_f as *mut _,
    );
    LLVMAddSymbol(
        b"banshee_fp32_op_cvt_to_f\0".as_ptr() as *const _,
        Cpu::binary_fp32_op_cvt_to_f as *mut _,
    );
    LLVMAddSymbol(
        b"banshee_fp16_op_cvt_to_f\0".as_ptr() as *const _,
        Cpu::binary_fp16_op_cvt_to_f as *mut _,
    );
    LLVMAddSymbol(
        b"banshee_fp8_op_cvt_from_f\0".as_ptr() as *const _,
        Cpu::binary_fp8_op_cvt_from_f as *mut _,
    );
    LLVMAddSymbol(
        b"banshee_fp8_op_cvt_to_f\0".as_ptr() as *const _,
        Cpu::binary_fp8_op_cvt_to_f as *mut _,
    );
    LLVMAddSymbol(
        b"banshee_fp16_op_cmp\0".as_ptr() as *const _,
        Cpu::binary_fp16_op_cmp as *mut _,
    );
    LLVMAddSymbol(
        b"banshee_fp8_op_cmp\0".as_ptr() as *const _,
        Cpu::binary_fp8_op_cmp as *mut _,
    );
    LLVMAddSymbol(
        b"banshee_fp16_op\0".as_ptr() as *const _,
        Cpu::binary_fp16_op as *mut _,
    );
    LLVMAddSymbol(
        b"banshee_fp8_op\0".as_ptr() as *const _,
        Cpu::binary_fp8_op as *mut _,
    );
    LLVMAddSymbol(
        b"banshee_fp16_to_fp32_op\0".as_ptr() as *const _,
        Cpu::binary_fp16_to_fp32_op as *mut _,
    );
    LLVMAddSymbol(
        b"banshee_fp8_to_fp16_op\0".as_ptr() as *const _,
        Cpu::binary_fp8_to_fp16_op as *mut _,
    );
    LLVMAddSymbol(
        b"banshee_fp8_to_fp32_op\0".as_ptr() as *const _,
        Cpu::binary_fp8_to_fp32_op as *mut _,
    );
}

// /// A representation of the system state.
// #[repr(C)]
// pub struct System<'a> {}

impl CpuState {
    /// Create a new CpuState
    pub fn new(num_dm: usize) -> Self {
        Self {
            regs: [0; 32],
            regs_cycle: [0; 32],
            fregs: [0; 32],
            fregs_cycle: [0; 32],
            cas_value: 0,
            pc: 0,
            cycle: 0,
            instret: 0,
            ssrs: (0..num_dm).map(|_| Default::default()).collect(),
            ssr_enable: 0,
            fpmode: 0,
            wfi: false,
            dma: Default::default(),
            irq: Default::default(),
        }
    }
}

impl<'a, 'b> Cpu<'a, 'b> {
    /// Create a new CPU in a default state.
    pub fn new(
        engine: &'a Engine,
        tcdm_ptr: &'b u32,
        tcdm_ext_ptr: &'b Vec<&'b u32>,
        hartid: usize,
        num_cores: usize,
        cluster_base_hartid: usize,
        cluster_id: usize,
        barrier: &'b AtomicUsize,
        num_sleep: &'b AtomicUsize,
        wake_up: &'b Vec<AtomicU64>,
        clint: &'b Vec<AtomicU32>,
    ) -> Self {
        Self {
            engine,
            state: CpuState::new(engine.config.ssr.num_dm),
            tcdm_ptr,
            tcdm_ext_ptr,
            hartid,
            num_cores,
            cluster_base_hartid,
            cluster_id,
            barrier,
            num_sleep,
            wake_up,
            clint,
        }
    }

    fn binary_load(&self, addr: u32, size: u8) -> u32 {
        match addr {
            x if x == self.engine.config.address.tcdm_start => {
                self.engine.config.memory[self.cluster_id].tcdm.start
            } // tcdm_start
            x if x == self.engine.config.address.tcdm_end => {
                self.engine.config.memory[self.cluster_id].tcdm.end
            } // tcdm_end
            x if x == self.engine.config.address.nr_cores => self.num_cores as u32, // nr_cores
            x if x == self.engine.config.address.scratch_reg => {
                self.engine.exit_code.load(Ordering::SeqCst)
            } // scratch_reg
            x if x == self.engine.config.address.barrier_reg => {
                self.cluster_barrier();
                0
            } // barrier_reg
            x if x == self.engine.config.address.cluster_base_hartid => {
                self.cluster_base_hartid as u32
            } // cluster_base_hartid
            x if x == self.engine.config.address.cluster_num => self.engine.num_clusters as u32, // cluster_num
            x if x == self.engine.config.address.cluster_id => self.cluster_id as u32, // cluster_id
            // TCDM
            x if x >= self.engine.config.memory[self.cluster_id].tcdm.start
                && x < self.engine.config.memory[self.cluster_id].tcdm.end =>
            {
                let tcdm_addr = addr - self.engine.config.memory[self.cluster_id].tcdm.start;
                let word_addr = tcdm_addr / 4;
                let word_offs = tcdm_addr - 4 * word_addr;
                let ptr: *const u32 = self.tcdm_ptr;
                let word = unsafe { *ptr.offset(word_addr as isize) };
                (word >> (8 * word_offs)) & ((((1 as u64) << (8 << size)) - 1) as u32)
            }
            // Peripherals
            x if x >= self.engine.config.memory[self.cluster_id].periphs.start
                && x < self.engine.config.memory[self.cluster_id].periphs.end =>
            {
                self.engine.peripherals.load(
                    self.cluster_id,
                    addr - self.engine.config.memory[self.cluster_id].periphs.start,
                    size,
                )
            }
            // access to the CLINT
            x if x >= self.engine.config.address.clint
                && x < self.engine.config.address.clint + 0x1000 =>
            {
                trace!(
                    "CLINT Load off 0x{:x}",
                    addr as u64 - self.engine.config.address.clint as u64
                );
                let word_addr = (addr - self.engine.config.address.clint) / 4;
                self.clint[word_addr as usize].load(Ordering::Relaxed)
            }
            _ => {
                trace!("Load 0x{:x} ({}B)", addr, 8 << size);
                self.engine
                    .memory
                    .lock()
                    .unwrap()
                    .get(&(addr as u64))
                    .copied()
                    .unwrap_or(0)
            }
        }
    }

    fn binary_store(&self, addr: u32, value: u32, mask: u32, size: u8) {
        match addr {
            x if x == self.engine.config.address.tcdm_start => (), // tcdm_start
            x if x == self.engine.config.address.tcdm_end => (),   // tcdm_end
            x if x == self.engine.config.address.nr_cores => (),   // nr_cores
            x if x == self.engine.config.address.scratch_reg => {
                self.engine.exit_code.store(value, Ordering::SeqCst)
            } // scratch_reg
            x if x == self.engine.config.address.wakeup_reg => {
                // wake_up
                let old_num_sleep = self.num_sleep.load(Ordering::Relaxed);
                if value as i32 == -1 {
                    self.num_sleep
                        .fetch_sub(self.wake_up.len(), Ordering::Relaxed);
                    for x in self.wake_up {
                        x.fetch_max(self.state.cycle + 1, Ordering::Release);
                    }
                } else if (value as usize) < self.wake_up.len() {
                    self.num_sleep.fetch_sub(1, Ordering::Relaxed);
                    self.wake_up[value as usize].fetch_max(self.state.cycle + 1, Ordering::Release);
                }
                if self.num_sleep.load(Ordering::Relaxed) > old_num_sleep {
                    error!("num_sleep has wrapped. Did you wake a core that was already running?")
                }
            } // wakeup_reg
            x if x == self.engine.config.address.barrier_reg => (), // barrier_reg
            x if x == self.engine.config.address.cluster_base_hartid => (), // cluster_base_hartid
            x if x == self.engine.config.address.cluster_num => (), // cluster_num
            x if x == self.engine.config.address.cluster_id => (), // cluster_id
            x if x == self.engine.config.address.uart => {
                let mut buffer = self.engine.putchar_buffer.lock().unwrap();
                let buffer = buffer.entry(self.hartid).or_default();
                if value == '\n' as u32 {
                    eprintln!(
                        "{}{} hart-{:03} {} {}",
                        style::Invert,
                        color::Fg(color::White),
                        self.hartid,
                        style::Reset,
                        String::from_utf8_lossy(buffer)
                    );
                    buffer.clear();
                } else {
                    buffer.push(value as u8);
                }
            }
            // TCDM
            // TODO: this is *not* thread-safe and *will* lead to undefined behavior on simultaneous access
            // by 2 harts. However, changing `tcdm_ptr` to a locked structure would require pervasive redesign.
            x if x >= self.engine.config.memory[self.cluster_id].tcdm.start
                && x < self.engine.config.memory[self.cluster_id].tcdm.end =>
            {
                let tcdm_addr = addr - self.engine.config.memory[self.cluster_id].tcdm.start;
                let word_addr = tcdm_addr / 4;
                let word_offs = tcdm_addr - 4 * word_addr;
                let ptr = self.tcdm_ptr as *const u32;
                let ptr_mut = ptr as *mut u32;
                let wmask = ((((1 as u64) << (8 << size)) - 1) as u32) << (8 * word_offs);
                unsafe {
                    let word_ptr = ptr_mut.offset(word_addr as isize);
                    let word = *word_ptr;
                    *word_ptr = (word & !wmask) | ((value << (8 * word_offs)) & wmask);
                }
            }
            // Peripherals
            x if x >= self.engine.config.memory[self.cluster_id].periphs.start
                && x < self.engine.config.memory[self.cluster_id].periphs.end =>
            {
                self.engine.peripherals.store(
                    self.cluster_id,
                    addr - self.engine.config.memory[self.cluster_id].periphs.start,
                    value,
                    mask,
                    size,
                )
            }
            // access to the CLINT
            x if x >= self.engine.config.address.clint
                && x < self.engine.config.address.clint + 0x1000 =>
            {
                let word_addr = (addr - self.engine.config.address.clint) / 4;
                trace!("CLINT store word off {:x} = 0x{:x}", word_addr, value,);
                let old_entry = self.clint[word_addr as usize].load(Ordering::Relaxed);
                let entry = (old_entry & !mask) | (value & mask);
                self.clint[word_addr as usize].store(entry, Ordering::Relaxed);
                // wake cores affected by this write

                let hart_base = 32 * word_addr as i32 - self.engine.base_hartid as i32;
                for i in 0..32 {
                    if ((!old_entry & entry) & (1 << i)) != 0 {
                        trace!("  wake_up[{}] PING", (hart_base + i as i32) as usize);
                        self.num_sleep.fetch_sub(1, Ordering::Relaxed);
                        self.wake_up[(hart_base + i as i32) as usize]
                            .fetch_max(self.state.cycle + 1, Ordering::Release);
                    }
                }
            }
            _ => {
                trace!(
                    "Store 0x{:x} = 0x{:x} if 0x{:x} ({}B)",
                    addr,
                    value,
                    mask,
                    8 << size
                );
                let mut data = self.engine.memory.lock().unwrap();
                let data = data.entry(addr as u64).or_default();
                *data &= !mask;
                *data |= value & mask;
            }
        }
    }

    fn binary_rmw(&self, addr: u32, value: u32, op: AtomicOp) -> u32 {
        trace!("RMW 0x{:x} (op={})= 0x{:x} (32B)", addr, op as u8, value);
        let mut data = self.engine.memory.lock().unwrap();
        let mut prev = data.get(&(addr as u64)).copied().unwrap_or(0);
        // Atomics
        let result = match op {
            AtomicOp::Amoadd => prev.wrapping_add(value),
            AtomicOp::Amoxor => prev ^ value,
            AtomicOp::Amoor => prev | value,
            AtomicOp::Amoand => prev & value,
            AtomicOp::Amomin => std::cmp::min(prev as i32, value as i32) as u32,
            AtomicOp::Amomax => std::cmp::max(prev as i32, value as i32) as u32,
            AtomicOp::Amominu => std::cmp::min(prev as u32, value as u32),
            AtomicOp::Amomaxu => std::cmp::max(prev as u32, value as u32),
            AtomicOp::Amoswap => value,
            AtomicOp::ScW => {
                if prev == self.state.cas_value {
                    prev = 0; // Store-conditional success
                    value
                } else {
                    return 1 as u32; // Store-conditional failed
                }
            }
        };
        data.insert(addr as u64, result);
        prev as u32
    }

    fn binary_csr_read(&self, csr: riscv::Csr, notrace: u32) -> u32 {
        if notrace == 0 {
            trace!("Read CSR {:?}", csr);
        }
        match csr {
            riscv::Csr::Ssr => self.state.ssr_enable,
            riscv::Csr::Fpmode => self.state.fpmode as u32,
            riscv::Csr::Mcycle => self.state.cycle as u32, // csr_mcycle
            riscv::Csr::Mcycleh => (self.state.cycle >> 32) as u32, // csr_mcycleh
            riscv::Csr::Minstret => self.state.instret as u32, // csr_minstret
            riscv::Csr::Minstreth => (self.state.instret >> 32) as u32, // csr_minstreth
            riscv::Csr::Mhartid => self.hartid as u32,     // mhartid
            riscv::Csr::Mstatus => self.state.irq.mstatus, // CSR_MSTATUS
            riscv::Csr::Mie => self.state.irq.mie,         // CSR_MIE
            riscv::Csr::Mip => self.state.irq.mip,         // CSR_MIP
            riscv::Csr::Mtvec => self.state.irq.mtvec,     // CSR_MTVEC
            riscv::Csr::Mepc => self.state.irq.mepc,       // CSR_MEPC
            riscv::Csr::Mcause => self.state.irq.mcause,   // CSR_MCAUSE
            riscv::Csr::Misa => {
                // RV32IMAFDX A - Atomic Instructions extension
                (1 << 0) | (1 << 3) | (1 << 5) | (1 << 8) | (1 << 12) | (1 << 23) | (1 << 30)
            }
            _ => 0,
        }
    }

    fn binary_csr_write(&mut self, csr: riscv::Csr, value: u32, notrace: u32) {
        if notrace == 0 {
            trace!("Write CSR {:?} = 0x{:?}", csr, value);
        }
        match csr {
            riscv::Csr::Ssr => self.state.ssr_enable = value,
            riscv::Csr::Fpmode => self.state.fpmode = value,
            riscv::Csr::Mstatus => self.state.irq.mstatus = value, // CSR_MSTATUS
            riscv::Csr::Mie => self.state.irq.mie = value,         // CSR_MIE
            riscv::Csr::Mip => self.state.irq.mip = value,         // CSR_MIP
            riscv::Csr::Mtvec => self.state.irq.mtvec = value,     // CSR_MTVEC
            riscv::Csr::Mepc => self.state.irq.mepc = value,       // CSR_MEPC
            riscv::Csr::Mcause => self.state.irq.mcause = value,   // CSR_MCAUSE
            _ => (),
        }
    }

    fn binary_abort_escape(&self, addr: u32) {
        error!("CPU escaped binary at 0x{:x}", addr);
        self.engine.had_error.store(true, Ordering::SeqCst);
    }

    fn binary_abort_illegal_inst(&self, addr: u32, inst_raw: u32) {
        error!(
            "Illegal instruction {} at 0x{:x}",
            riscv::parse_u32(inst_raw),
            addr
        );
        self.engine.had_error.store(true, Ordering::SeqCst);
    }

    fn binary_abort_illegal_branch(&self, addr: u32, target: u32) {
        error!(
            "Branch to unpredicted address 0x{:x} at 0x{:x}",
            target, addr
        );
        self.engine.had_error.store(true, Ordering::SeqCst);
    }

    fn binary_trace(&self, addr: u32, inst: u32, accesses: &[TraceAccess], data: &[u64]) {
        // Assemble the arguments.
        let args = accesses.iter().copied().zip(data.iter().copied());
        let mut args = args.map(|(access, data)| match access {
            TraceAccess::ReadMem => format!("RA:{:08x}", data as u32),
            TraceAccess::WriteMem => format!("WA:{:08x}", data as u32),
            TraceAccess::RMWMem => format!("AMO:{:08x}", data as u32),
            TraceAccess::ReadReg(x) => format!("x{}:{:08x}", x, data as u32),
            TraceAccess::WriteReg(x) => format!("x{}={:08x}", x, data as u32),
            TraceAccess::ReadFReg(x) => format!("f{}:{:016x}", x, data),
            TraceAccess::WriteFReg(x) => format!("f{}={:016x}", x, data),
        });
        let args = args.join(" ");

        // Assemble the trace line.
        let line = format!(
            "{:08} {:08} {:04} {:08x}  {:38}  # DASM({:08x})",
            self.state.cycle, self.state.instret, self.hartid, addr, args, inst
        );
        println!("{}", line);
    }

    fn binary_wfi(&mut self) -> u32 {
        // Set own wfi.
        self.state.wfi = true;
        self.num_sleep.fetch_add(1, Ordering::Release);
        // Wait for the wake up call
        let hartid = self.hartid - self.engine.base_hartid;
        while self.wake_up[hartid].load(Ordering::Relaxed) == 0 {
            // Check if everyone is sleeping
            if self.num_sleep.load(Ordering::Relaxed) == self.wake_up.len() {
                return 1;
            }
            std::thread::yield_now();
        }
        // Someone woke us up --> Clear the flag
        let cycle = self.wake_up[hartid].swap(0, Ordering::Relaxed);
        self.state.cycle = std::cmp::max(self.state.cycle, cycle as u64);
        self.state.wfi = false;
        // Trigger IRQ check on next instruction
        self.state.irq.sample_ctr = u32::MAX - 1;
        // The core waking us up, already decremented the `num_sleep` counter for us
        return 0;
    }

    fn binary_check_clint(&mut self) -> u32 {
        // read the clint software interrupt and return 1 if interrupt pending
        let hartid = self.hartid;
        return (self.clint[(hartid / 32) as usize].load(Ordering::Relaxed) & (1 << (hartid % 32)))
            >> (hartid % 32);
    }

    /// A simple barrier across all cores in the cluster.
    ///
    /// Uses an atomic barrier flag shared across all CPU threads in a cluster.
    /// Core 0 coordinates. In a first phase, it waits until all cores but
    /// itself have bumped the flag, then bumps itself and waits for all cores
    /// to make it through.
    fn cluster_barrier(&self) {
        let core_id = self.hartid - self.cluster_base_hartid;
        let core_num = self.num_cores;
        if core_id == 0 {
            while self.barrier.load(Ordering::Relaxed) < core_num - 1 {
                std::thread::yield_now();
            }
            self.barrier.fetch_add(1, Ordering::Relaxed);
            while self.barrier.load(Ordering::Relaxed) < 2 * core_num - 1 {
                std::thread::yield_now();
            }
            self.barrier.store(0, Ordering::Relaxed);
        } else {
            while self.barrier.load(Ordering::Relaxed) >= core_num {
                std::thread::yield_now();
            }
            self.barrier.fetch_add(1, Ordering::Relaxed);
            while self.barrier.load(Ordering::Relaxed) < core_num {
                std::thread::yield_now();
            }
            self.barrier.fetch_add(1, Ordering::Relaxed);
        }
    }

    /*
     * Flexfloat Conversions
     */
    pub unsafe fn binary_fp64_op_cvt_to_f(
        rs1: u64,
        op: flexfloat::FfOpCvt,
        fpmode_src: bool,
        fpmode_dst: bool,
    ) -> u64 {
        flexfloat::ff_instruction_cvt_to_d(rs1, op, fpmode_src, fpmode_dst)
    }

    pub unsafe fn binary_fp32_op_cvt_to_f(
        rs1: u64,
        op: flexfloat::FfOpCvt,
        fpmode_src: bool,
        fpmode_dst: bool,
    ) -> u32 {
        flexfloat::ff_instruction_cvt_to_s(rs1, op, fpmode_src, fpmode_dst)
    }

    pub unsafe fn binary_fp16_op_cvt_from_f(
        rs1: u64,
        op: flexfloat::FfOpCvt,
        fpmode_src: bool,
        fpmode_dst: bool,
    ) -> i32 {
        flexfloat::ff_instruction_cvt_from_h(rs1, op, fpmode_src, fpmode_dst)
    }

    pub unsafe fn binary_fp16_op_cvt_to_f(
        rs1: u64,
        op: flexfloat::FfOpCvt,
        fpmode_src: bool,
        fpmode_dst: bool,
    ) -> u16 {
        flexfloat::ff_instruction_cvt_to_h(rs1, op, fpmode_src, fpmode_dst)
    }

    pub unsafe fn binary_fp8_op_cvt_from_f(
        rs1: u64,
        op: flexfloat::FfOpCvt,
        fpmode_src: bool,
        fpmode_dst: bool,
    ) -> i32 {
        flexfloat::ff_instruction_cvt_from_b(rs1, op, fpmode_src, fpmode_dst)
    }

    pub unsafe fn binary_fp8_op_cvt_to_f(
        rs1: u64,
        op: flexfloat::FfOpCvt,
        fpmode_src: bool,
        fpmode_dst: bool,
    ) -> u8 {
        flexfloat::ff_instruction_cvt_to_b(rs1, op, fpmode_src, fpmode_dst)
    }

    /*
     * Flexfloat Comparisons
     */
    pub unsafe fn binary_fp16_op_cmp(
        rs1: u16,
        rs2: u16,
        op: flexfloat::FlexfloatOpCmp,
        fpmode_dst: bool,
    ) -> bool {
        flexfloat::ff_instruction_cmp_h(rs1, rs2, op, fpmode_dst)
    }

    pub unsafe fn binary_fp8_op_cmp(
        rs1: u8,
        rs2: u8,
        op: flexfloat::FlexfloatOpCmp,
        fpmode_dst: bool,
    ) -> bool {
        flexfloat::ff_instruction_cmp_b(rs1, rs2, op, fpmode_dst)
    }

    /*
     * Flexfloat Operations
     */
    pub unsafe fn binary_fp16_op(
        rs1: u16,
        rs2: u16,
        rs3: u16,
        op: flexfloat::FlexfloatOp,
        fpmode_dst: bool,
    ) -> u16 {
        flexfloat::ff_instruction_h(rs1, rs2, rs3, op, fpmode_dst)
    }
    pub unsafe fn binary_fp8_op(
        rs1: u8,
        rs2: u8,
        rs3: u8,
        op: flexfloat::FlexfloatOp,
        fpmode_dst: bool,
    ) -> u8 {
        flexfloat::ff_instruction_b(rs1, rs2, rs3, op, fpmode_dst)
    }
    pub unsafe fn binary_fp16_to_fp32_op(
        rs1: u16,
        rs2: u16,
        rs3: f32,
        op: flexfloat::FlexfloatOpExp,
        fpmode_src: bool,
    ) -> f32 {
        flexfloat::ff_fp16_to_fp32_op(rs1, rs2, rs3, op, fpmode_src)
    }
    pub unsafe fn binary_fp8_to_fp16_op(
        rs1: u8,
        rs2: u8,
        rs3: u16,
        op: flexfloat::FlexfloatOpExp,
        fpmode_src: bool,
        fpmode_dst: bool,
    ) -> u16 {
        flexfloat::ff_fp8_to_fp16_op(rs1, rs2, rs3, op, fpmode_src, fpmode_dst)
    }
    pub unsafe fn binary_fp8_to_fp32_op(
        rs1: u8,
        rs2: u8,
        rs3: f32,
        op: flexfloat::FlexfloatOpExp,
        fpmode_src: bool,
    ) -> f32 {
        flexfloat::ff_fp8_to_fp32_op(rs1, rs2, rs3, op, fpmode_src)
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
    RMWMem,
}

/// Which type of AMO to execute.
#[derive(Debug, Clone, Copy)]
#[repr(C)]
pub enum AtomicOp {
    Amoadd,
    Amoxor,
    Amoor,
    Amoand,
    Amomin,
    Amomax,
    Amominu,
    Amomaxu,
    Amoswap,
    ScW,
}
