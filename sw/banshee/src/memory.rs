// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

//! Thread-safe memory

use std::sync::atomic::{AtomicU32, Ordering::SeqCst};

struct Memory {
    mem: Vec<AtomicU32>,
}

impl Memory {
    fn new(size: usize) -> Self {
        Self {
            mem: {
                let mut mem: Vec<AtomicU32> = Vec::with_capacity(size);
                mem.resize_with(size, Default::default);
                mem
            },
        }
    }

    fn store(&self, addr: u32, val: u32, mask: u32, size: u8) {
        if size == 3 {
            self.mem[addr as usize].store(val, SeqCst);
        } else {
            self.mem[addr as usize]
                .fetch_update(SeqCst, SeqCst, |x| Some((x & !mask) | (val & mask)))
                .unwrap();
        }
    }

    fn load(&self, addr: u32, _: u8) -> u32 {
        self.mem[addr as usize].load(SeqCst)
    }
}
