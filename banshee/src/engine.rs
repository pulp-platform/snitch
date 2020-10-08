//! Engine for dynamic binary translation and execution

use crate::tran::ElfTranslator;
use anyhow::Result;
use llvm_sys::{core::*, prelude::*};

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

        Ok(())
    }
}
