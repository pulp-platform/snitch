// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

//! Runtime code included as LLVM IR in the translated binary.
//!
//! Be very careful about what exactly goes in here, as it has the potential to
//! greatly disrupt execution of the translated binary. Especially the linker
//! that resolves symbol references in the JITed binary is very brittle. As a
//! rule of thumb, avoid the following:
//!
//! - assertions
//! - index accesses; try `get_unchecked` and friends instead
//! - any of the macros from the `log` crate

// Include the common elements shared with the rust part of the engine.
include!("common.rs");
pub type Engine = i8;

/// Get a pointer to a register.
#[no_mangle]
#[inline(always)]
pub unsafe fn banshee_reg_ptr<'a>(cpu: &'a mut Cpu, reg: u32) -> &'a mut u32 {
    cpu.state.regs.get_unchecked_mut(reg as usize)
}

/// Get a pointer to a register's cycle.
#[no_mangle]
#[inline(always)]
pub unsafe fn banshee_reg_cycle_ptr<'a>(cpu: &'a mut Cpu, reg: u32) -> &'a mut u64 {
    cpu.state.regs_cycle.get_unchecked_mut(reg as usize)
}

/// Get a pointer to a float register.
#[no_mangle]
#[inline(always)]
pub unsafe fn banshee_freg_ptr<'a>(cpu: &'a mut Cpu, reg: u32) -> &'a mut u64 {
    cpu.state.fregs.get_unchecked_mut(reg as usize)
}

/// Get a pointer to a float register.
#[no_mangle]
#[inline(always)]
pub unsafe fn banshee_freg_cycle_ptr<'a>(cpu: &'a mut Cpu, reg: u32) -> &'a mut u64 {
    cpu.state.fregs_cycle.get_unchecked_mut(reg as usize)
}

/// Get a pointer to the program counter register.
#[no_mangle]
#[inline(always)]
pub unsafe fn banshee_pc_ptr<'a>(cpu: &'a mut Cpu) -> &'a mut u32 {
    &mut cpu.state.pc
}

/// Get a pointer to the cycle counter.
#[no_mangle]
#[inline(always)]
pub unsafe fn banshee_cycle_ptr<'a>(cpu: &'a mut Cpu) -> &'a mut u64 {
    &mut cpu.state.cycle
}

/// Get a pointer to the instret counter.
#[no_mangle]
#[inline(always)]
pub unsafe fn banshee_instret_ptr<'a>(cpu: &'a mut Cpu) -> &'a mut u64 {
    &mut cpu.state.instret
}

/// Get a pointer to the TCDM buffer.
#[no_mangle]
#[inline(always)]
pub unsafe fn banshee_tcdm_ptr<'a>(cpu: &'a mut Cpu) -> &'a mut u32 {
    &mut *(cpu.tcdm_ptr as *const _ as *mut _)
}

/// Get a pointer to an SSR.
#[no_mangle]
#[inline(always)]
pub unsafe fn banshee_ssr_ptr<'a>(cpu: &'a mut Cpu, ssr: u32) -> &'a mut SsrState {
    cpu.state.ssrs.get_unchecked_mut(ssr as usize)
}

/// Get a pointer to the SSR enable flag.
#[no_mangle]
#[inline(always)]
pub unsafe fn banshee_ssr_enabled_ptr<'a>(cpu: &'a mut Cpu) -> &'a mut u32 {
    &mut cpu.state.ssr_enable
}

/// Get a pointer to the DMA state.
#[no_mangle]
#[inline(always)]
pub unsafe fn banshee_dma_ptr<'a>(cpu: &'a mut Cpu) -> &'a mut DmaState {
    &mut cpu.state.dma
}

/// Write to an SSR control register.
#[no_mangle]
pub unsafe fn banshee_ssr_write_cfg(ssr: &mut SsrState, addr: u32, value: u32, mask: u32) {
    // TODO: Handle the mask!
    let addr = addr as usize / 8;
    match addr {
        0 => {
            ssr.ptr = value & ((1 << 28) - 1);
            ssr.done = ((value >> 31) & 1) != 0;
            ssr.write = ((value >> 30) & 1) != 0;
            ssr.dims = ((value >> 28) & 3) as u8;
        }
        1 => ssr.repeat_count = value as u16,
        2..=5 => *ssr.bound.get_unchecked_mut(addr - 2) = value,
        6..=9 => *ssr.stride.get_unchecked_mut(addr - 6) = value,
        24..=27 => {
            ssr.ptr = value;
            ssr.done = false;
            ssr.write = false;
            ssr.dims = (addr - 24) as u8;
        }
        28..=31 => {
            ssr.ptr = value;
            ssr.done = false;
            ssr.write = true;
            ssr.dims = (addr - 28) as u8;
        }
        // TODO: Issue an error
        _ => (),
    }
}

/// Read from an SSR control register.
#[no_mangle]
pub unsafe fn banshee_ssr_read_cfg(ssr: &mut SsrState, addr: u32) -> u32 {
    let addr = addr as usize / 8;
    match addr {
        0 => ssr.ptr | (ssr.done as u32) << 31 | (ssr.write as u32) << 30 | (ssr.dims as u32) << 28,
        1 => ssr.repeat_count as u32,
        2..=5 => *ssr.bound.get_unchecked(addr - 2),
        6..=9 => *ssr.stride.get_unchecked(addr - 6),
        // TODO: Issue an error
        _ => 0,
    }
}

/// Generate the next address from an SSR.
#[no_mangle]
pub unsafe fn banshee_ssr_next(ssr: &mut SsrState) -> u32 {
    // TODO: Assert that the SSR is not done.
    let ptr = ssr.ptr;
    if ssr.repeat_count == ssr.repeat_bound {
        ssr.repeat_count = 0;
        let mut stride = 0;
        ssr.done = true;
        for i in 0..=(ssr.dims as usize) {
            stride = *ssr.stride.get_unchecked(i);
            if *ssr.index.get_unchecked(i) == *ssr.bound.get_unchecked(i) {
                *ssr.index.get_unchecked_mut(i) = 0;
            } else {
                *ssr.index.get_unchecked_mut(i) += 1;
                ssr.done = false;
                break;
            }
        }
        ssr.ptr = ssr.ptr.wrapping_add(stride);
    } else {
        ssr.repeat_count += 1;
    }
    ptr
}

/// Implementation of the `dm.src` instruction.
#[no_mangle]
pub unsafe fn banshee_dma_src(dma: &mut DmaState, lo: u32, hi: u32) {
    dma.src = (hi as u64) << 32 | (lo as u64);
}

/// Implementation of the `dm.dst` instruction.
#[no_mangle]
pub unsafe fn banshee_dma_dst(dma: &mut DmaState, lo: u32, hi: u32) {
    dma.dst = (hi as u64) << 32 | (lo as u64);
}

/// Implementation of the `dm.strt` and `dm.strti` instructions.
#[no_mangle]
pub unsafe fn banshee_dma_strt(dma: &mut DmaState, cpu: &mut Cpu, size: u32, flags: u32) -> u32 {
    extern "C" {
        fn banshee_load(cpu: &mut Cpu, addr: u32, size: u8) -> u32;
        fn banshee_store(cpu: &mut Cpu, addr: u32, value: u32, mask: u32, size: u8);
    }

    let id = dma.done_id;
    dma.done_id += 1;

    // assert_eq!(
    //     size % 4,
    //     0,
    //     "DMA transfer size must be a multiple of 4B for now"
    // );
    let num_beats = size / 4;
    let enable_2d = (flags & (1 << 1)) != 0;
    let steps = if enable_2d { dma.reps } else { 1 };

    for i in 0..steps as u64 {
        let src = dma.src + i * dma.src_stride as u64;
        let dst = dma.dst + i * dma.dst_stride as u64;
        // assert_eq!(src % 4, 0, "DMA src transfer block must be 4-byte-aligned");
        // assert_eq!(dst % 4, 0, "DMA dst transfer block must be 4-byte-aligned");
        for j in 0..num_beats as u64 {
            let tmp = banshee_load(cpu, (src + j * 4) as u32, 2);
            banshee_store(cpu, (dst + j * 4) as u32, tmp, u32::max_value(), 2);
        }
    }

    id
}

/// Implementation of the `dm.stat` and `dm.stati` instructions.
#[no_mangle]
pub unsafe fn banshee_dma_stat(dma: &DmaState, addr: u32) -> u32 {
    match addr & 0x3 {
        0 => dma.done_id,     // completed_id
        1 => dma.done_id + 1, // next_id
        2 | 3 => 0,           // busy
        _ => 0,
    }
}
