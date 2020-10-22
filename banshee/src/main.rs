// This seems to be bug in the compiler.
#[macro_use]
extern crate clap;
#[macro_use]
extern crate log;
extern crate llvm_sys as llvm;

use anyhow::{bail, Context, Result};
use clap::Arg;
use llvm_sys::{bit_writer::*, core::*, execution_engine::*, initialization::*, target::*};
use std::{path::Path, ptr::null_mut};

pub mod engine;
pub mod riscv;
mod runtime;
mod softfloat;
pub mod tran;

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
        .get_matches();

    // Configure the logger.
    pretty_env_logger::init_custom_env("SNITCH_LOG");

    // Initialize the LLVM core.
    let context = unsafe {
        let pass_reg = LLVMGetGlobalPassRegistry();
        LLVMInitializeCore(pass_reg);
        LLVMLinkInMCJIT();
        LLVM_InitializeNativeTarget();
        LLVM_InitializeNativeAsmPrinter();
        engine::add_llvm_symbols();
        LLVMGetGlobalContext()
    };

    // Setup the execution engine.
    let mut engine = Engine::new(context);
    engine.opt_llvm = !matches.is_present("no-opt-llvm");
    engine.opt_jit = !matches.is_present("no-opt-jit");
    engine.trace = matches.is_present("trace");

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
