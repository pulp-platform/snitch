// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// Runtime code shared between banshee and the translated binary.
//
// Be very careful what you put in here. This module should only contain code
// snippets that are absolutely essential to share between banshee and the
// translated binary. See `jit.rs` for additional considerations.
//
// Try to pack as much as possible into `mod.rs` (for banshee) or `jit.rs` (for
// the translated binary).

use std::sync::atomic::{AtomicU64, AtomicUsize};

/// A CPU pointer to be passed to the binary code.
#[repr(C)]
pub struct Cpu<'a, 'b> {
    pub engine: &'a Engine,
    pub state: CpuState,
    pub tcdm_ptr: &'b u32,
    pub hartid: usize,
    pub num_cores: usize,
    pub cluster_base_hartid: usize,
    /// The cluster's identifier.
    pub cluster_id: usize,
    /// The cluster's shared barrier state.
    pub barrier: &'b AtomicUsize,
    pub num_sleep: &'b AtomicUsize,
    pub wake_up: &'b Vec<AtomicU64>,
}

/// A representation of a single CPU core's state.
#[derive(Default)]
#[repr(C)]
pub struct CpuState {
    pub regs: [u32; 32],
    pub regs_cycle: [u64; 32],
    pub fregs: [u64; 32],
    pub fregs_cycle: [u64; 32],
    pub pc: u32,
    pub cycle: u64,
    pub instret: u64,
    pub ssrs: [SsrState; 2],
    pub ssr_enable: u32,
    pub dma: DmaState,
    pub wfi: bool,
}

/// A representation of a single SSR address generator's state.
#[derive(Default)]
#[repr(C)]
pub struct SsrState {
    index: [u32; 4],
    bound: [u32; 4],
    stride: [u32; 4],
    idx_shift: u32,
    idx_base: u32,
    idx_size: u32,
    idx_ptr: u32,
    ptr: u32,
    ptr_next: u32,
    repeat_count: u16,
    repeat_bound: u16,
    write: bool,
    dims: u8,
    done: bool,
    indir: bool,
    accessed: bool,
}

/// A representation of a DMA backend's state.
#[derive(Default)]
#[repr(C)]
pub struct DmaState {
    src: u64,
    dst: u64,
    src_stride: u32,
    dst_stride: u32,
    reps: u32,
    size: u32,
    done_id: u32,
}
