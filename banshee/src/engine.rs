//! Engine for dynamic binary translation and execution

use crate::riscv;
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
        debug!("Translating ELF binary");
        for section in &elf.sections {
            if (section.shdr.flags.0 & elf::types::SHF_EXECINSTR.0) != 0 {
                self.translate_section(section)?;
            }
        }
        Ok(())
    }

    /// Translate an ELF section.
    pub fn translate_section(&self, section: &elf::Section) -> Result<()> {
        debug!(
            "Translating ELF section `{}` from 0x{:x} to 0x{:x}",
            section.shdr.name,
            section.shdr.addr,
            section.shdr.addr + section.shdr.size
        );

        // Parse the instructions one by one.
        for (i, data) in section.data.chunks(4).enumerate() {
            let inst = riscv::parse(data).unwrap();
            trace!("0x{:x}: {}", section.shdr.addr + i as u64 * 4, inst);
        }

        Ok(())
    }
}
