//! Runtime cod included as LLVM IR in the translated binary.

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

impl std::fmt::Debug for SsrState {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        f.debug_struct("SsrState")
            .field("index", &format_args!("{:?}", self.index))
            .field("bound", &format_args!("{:?}", self.bound))
            .field("stride", &format_args!("{:08x?}", self.stride))
            .field("ptr", &format_args!("{:08x}", self.ptr))
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
            .finish()
    }
}

/// Write to an SSR control register.
#[no_mangle]
pub unsafe fn banshee_ssr_write_cfg(ssr: &mut SsrState, addr: u32, value: u32) {
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

impl std::fmt::Debug for DmaState {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        f.debug_struct("DmaState")
            .field("src", &format_args!("{:08x}", self.src))
            .field("dst", &format_args!("{:08x}", self.dst))
            .field("done_id", &self.done_id)
            .finish()
    }
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
pub unsafe fn banshee_dma_strt(dma: &mut DmaState, cpu: *const u8, size: u32, flags: u32) -> u32 {
    extern "C" {
        fn banshee_load(cpu: *const u8, addr: u32, size: u8) -> u32;
        fn banshee_store(cpu: *const u8, addr: u32, value: u32, size: u8);
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
            banshee_store(cpu, (dst + j * 4) as u32, tmp, 2);
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
