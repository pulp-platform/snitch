// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// This seems to be bug in the compiler.
#[macro_use]
extern crate clap;
#[macro_use]
extern crate log;
extern crate llvm_sys as llvm;

use anyhow::{bail, Context, Result};
use clap::Arg;
use llvm_sys::{
    bit_writer::*, core::*, execution_engine::*, initialization::*, support::*, target::*,
};
use std::{ffi::CString, os::raw::c_int, path::Path, ptr::null_mut};

pub mod engine;
pub mod riscv;
mod runtime;
mod softfloat;
pub mod tran;
pub mod util;

use crate::engine::*;

fn main() -> Result<()> {
    // Parse the command line arguments.
    let matches = app_from_crate!()
        .arg(
            Arg::with_name("binary")
                .help("RISC-V ELF binary to execute")
                .required(true),
        )
        .arg(
            Arg::with_name("dump-llvm")
                .long("dump-llvm")
                .short("d")
                .help("Dump the translated LLVM IR module"),
        )
        .arg(
            Arg::with_name("emit-llvm")
                .long("emit-llvm")
                .short("S")
                .takes_value(true)
                .help("Emit the translated LLVM assembly to a file"),
        )
        .arg(
            Arg::with_name("emit-bitcode")
                .long("emit-bitcode")
                .short("c")
                .takes_value(true)
                .help("Emit the translated LLVM bitcode to a file"),
        )
        .arg(
            Arg::with_name("dry-run")
                .long("dry-run")
                .short("n")
                .help("Translate the binary, but do not execute"),
        )
        .arg(
            Arg::with_name("no-opt-llvm")
                .long("no-opt-llvm")
                .help("Do not optimize LLVM IR"),
        )
        .arg(
            Arg::with_name("no-opt-jit")
                .long("no-opt-jit")
                .help("Do not optimize during JIT compilation"),
        )
        .arg(
            Arg::with_name("trace")
                .long("trace")
                .short("t")
                .help("Enable instruction tracing"),
        )
        .arg(
            Arg::with_name("latency")
                .long("latency")
                .short("l")
                .help("Enable instruction latency modeling"),
        )
        .arg(
            Arg::with_name("num-cores")
                .long("num-cores")
                .takes_value(true)
                .help("Number of cores to simulate"),
        )
        .arg(
            Arg::with_name("num-clusters")
                .long("num-clusters")
                .takes_value(true)
                .help("Number of clusters to simulate"),
        )
        .arg(
            Arg::with_name("base-hartid")
                .long("base-hartid")
                .takes_value(true)
                .help("The hartid of the first core"),
        )
        .arg(
            Arg::with_name("llvm-args")
                .short("L")
                .takes_value(true)
                .multiple(true)
                .help("Pass command line arguments to LLVM"),
        )
        .get_matches();

    // Configure the logger.
    pretty_env_logger::init_custom_env("SNITCH_LOG");

    // Initialize the LLVM core.
    let context = unsafe {
        LLVMLinkInMCJIT();
        LLVM_InitializeNativeTarget();
        LLVM_InitializeNativeAsmPrinter();

        // Initialize passes (inspired by llvm/tools/opt/opt.cpp:527).
        let pass_reg = LLVMGetGlobalPassRegistry();
        LLVMInitializeAggressiveInstCombiner(pass_reg);
        LLVMInitializeAnalysis(pass_reg);
        LLVMInitializeCodeGen(pass_reg);
        LLVMInitializeCore(pass_reg);
        LLVMInitializeIPA(pass_reg);
        LLVMInitializeIPO(pass_reg);
        LLVMInitializeInstCombine(pass_reg);
        LLVMInitializeInstrumentation(pass_reg);
        LLVMInitializeObjCARCOpts(pass_reg);
        LLVMInitializeScalarOpts(pass_reg);
        LLVMInitializeTarget(pass_reg);
        LLVMInitializeTransformUtils(pass_reg);
        LLVMInitializeVectorization(pass_reg);

        engine::add_llvm_symbols();
        LLVMGetGlobalContext()
    };

    // Pass command line arguments to LLVM.
    if let Some(args) = matches.values_of("llvm-args") {
        let exec_name = CString::new("banshee").unwrap();
        let args: Vec<_> = args.map(|a| CString::new(a).unwrap()).collect();
        let mut argv = vec![];
        argv.push(exec_name.as_ptr());
        argv.extend(args.iter().map(|a| (*a).as_ptr()));
        let overview = CString::new("Banshee is magic!").unwrap();
        unsafe {
            LLVMParseCommandLineOptions(
                argv.len() as c_int,
                argv.as_ptr(),
                overview.as_ptr() as *const _,
            );
        }
    }

    // Setup the execution engine.
    let mut engine = Engine::new(context);
    engine.opt_llvm = !matches.is_present("no-opt-llvm");
    engine.opt_jit = !matches.is_present("no-opt-jit");
    engine.trace = matches.is_present("trace");
    engine.latency = matches.is_present("latency");
    matches
        .value_of("num-cores")
        .map(|x| engine.num_cores = x.parse().unwrap());
    matches
        .value_of("num-clusters")
        .map(|x| engine.num_clusters = x.parse().unwrap());
    matches
        .value_of("base-hartid")
        .map(|x| engine.base_hartid = x.parse().unwrap());

    // Read the binary.
    let path = Path::new(matches.value_of("binary").unwrap());
    info!("Loading binary {}", path.display());
    let elf = match elf::File::open_path(&path) {
        Ok(f) => f,
        Err(e) => bail!("Failed to open binary {}: {:?}", path.display(), e),
    };

    // Translate the binary.
    engine
        .translate_elf(&elf)
        .context("Failed to translate ELF binary")?;

    // Write the module to disk if requested.
    if let Some(path) = matches.value_of("emit-llvm") {
        unsafe {
            LLVMPrintModuleToFile(
                engine.module,
                format!("{}\0", path).as_ptr() as *const _,
                null_mut(),
            );
        }
    }
    if let Some(path) = matches.value_of("emit-bitcode") {
        unsafe {
            LLVMWriteBitcodeToFile(engine.module, format!("{}\0", path).as_ptr() as *const _);
        }
    }

    // Dump the module if requested.
    if matches.is_present("dump-llvm") {
        unsafe {
            LLVMDumpModule(engine.module);
        }
    }

    // Execute the binary.
    if !matches.is_present("dry-run") {
        let return_code = engine.execute().context("Failed to execute ELF binary")?;
        std::process::exit(return_code as i32);
    }
    Ok(())
}
