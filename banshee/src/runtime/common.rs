// Runtime code shared between banshee and the translated binary.
//
// Be very careful what you put in here. This module should only contain code
// snippets that are absolutely essential to share between banshee and the
// translated binary. See `jit.rs` for additional considerations.
//
// Try to pack as much as possible into `mod.rs` (for banshee) or `jit.rs` (for
// the translated binary).

/// A representation of a single SSR address generator's state.
#[derive(Default)]
#[repr(C)]
pub struct SsrState {
    index: [u32; 4],
    bound: [u32; 4],
    stride: [u32; 4],
    ptr: u32,
    repeat_count: u16,
    repeat_bound: u16,
    write: bool,
    dims: u8,
    done: bool,
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
    done_id: u32,
}
