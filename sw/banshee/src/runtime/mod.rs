// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

//! Runtime structures shared with the translated binary
//!
//! This module contains various structures that are used by banshee and the
//! translated binary as it executes. Some code is needed only in banshee, some
//! only in the JITed binary, and some in both. The separation is as follows:
//!
//! - `mod.rs` (this file) contains the banshee-only code.
//!
//! - `jit.rs` contains the JIT-only code. It is compiled by `build.rs` into an
//!   LLVM IR file that is linked with the IR assembled during binary
//!   translation.
//!
//! - `common.rs` contains code shared between banshee and the JITed binary. Its
//!   goals is to mainly contain the runtime data structures that the JITed
//!   binary needs visibility into as well.
//!
//! - `jit.ll` is the initial content of the JITed binary module, before binary
//!   translation populates it with code.
//!
//! The LLVM IR module for the JITed binary is assembled as follows:
//!
//! - The `jit.ll` module is loaded to obtain the initial LLVM module.
//! - Binary translation emits code into the module.
//! - The module is linked with the LLVM IR obtained from `jit.rs`.

use crate::engine::Engine;
use itertools::Itertools;

include!("common.rs");

/// The initial contents of the LLVM module for the JITed binary.
///
/// These are the contents of the `jit.ll` file, and should contain any opaque
/// type declarations and function declarations needed by the binary
/// translation.
pub static JIT_INITIAL: &'static [u8] = include_bytes!("jit.ll");

/// The compiled version of `jit.rs`.
///
/// These are the compiled Rust code snippets that are needed to execute the
/// translated binary. This is also where most definitions corresponding to the
/// declaratiosn in `jit.ll` should go.
pub static JIT_GENERATED: &'static [u8] =
    include_bytes!(concat!(env!("OUT_DIR"), "/jit_generated.ll"));

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
            .field("cas_value", &self.cas_value)
            .field("pc", &format_args!("0x{:x}", self.pc))
            .field("cycle", &self.cycle)
            .field("instret", &self.instret)
            .field("ssrs", &self.ssrs)
            .field("dma", &self.dma)
            .field("wfi", &self.wfi)
            .finish()
    }
}

impl std::fmt::Debug for SsrState {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        f.debug_struct("SsrState")
            .field("index", &format_args!("{:?}", self.index))
            .field("bound", &format_args!("{:?}", self.bound))
            .field("stride", &format_args!("{:08x?}", self.stride))
            .field("ptr", &format_args!("{:08x}", self.ptr))
            .field("ptr_next", &format_args!("{:08x}", self.ptr_next))
            .field(
                "repeat",
                &format_args!("{} of {}", self.repeat_count, self.repeat_bound),
            )
            .field(
                "status",
                &format_args!(
                    "{{ done: {}, write: {}, dims: {} }}",
                    self.done, self.write, self.dims
                ),
            )
            .field("accessed", &format_args!("{}", self.accessed))
            .finish()
    }
}

impl std::fmt::Debug for DmaState {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        f.debug_struct("DmaState")
            .field("src", &format_args!("{:08x}", self.src))
            .field("dst", &format_args!("{:08x}", self.dst))
            .field("src stride", &format_args!("{:08x}", self.src_stride))
            .field("dst stride", &format_args!("{:08x}", self.dst_stride))
            .field("reps", &self.reps)
            .field("size", &self.size)
            .field("done_id", &self.done_id)
            .finish()
    }
}
