// Copyright 2021 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

use crate::peripherals::Peripheral;
use std::sync::atomic::{AtomicU32, Ordering};

/// Function called by the engine to get the peripherals. This function should return a vector
/// containing an instance of all the peripherals.
pub fn create_peripherals() -> Vec<Box<dyn Peripheral>> {
    vec![Box::new(Semaphores::default()), Box::new(Fence::default())]
}

#[derive(Default)]
struct Fence {
    set: AtomicU32,
    current: AtomicU32,
}

impl Peripheral for Fence {
    fn get_name(&self) -> &'static str {
        "fence"
    }

    fn store(&self, addr: u32, val: u32, _mask: u32, _: u8) {
        match addr {
            0x0 => self.set.store(val, Ordering::SeqCst),
            _ => self.current.store(val, Ordering::SeqCst),
        }
    }

    fn load(&self, _: u32, _: u8) -> u32 {
        self.current.fetch_add(1, Ordering::SeqCst);
        while self.set.load(Ordering::SeqCst) != self.current.load(Ordering::SeqCst) {}
        0
    }
}

#[derive(Default)]
struct Semaphores {
    empty_count: AtomicU32,
    full_count: AtomicU32,
    use_queue: AtomicU32,
}

impl Peripheral for Semaphores {
    fn get_name(&self) -> &'static str {
        "semaphores"
    }

    fn store(&self, addr: u32, val: u32, _mask: u32, _: u8) {
        match addr {
            0x0 => self.empty_count.store(val, Ordering::SeqCst),
            0x4 => {
                self.empty_count.fetch_add(val, Ordering::SeqCst);
            }
            0x8 => {
                while self
                    .empty_count
                    .fetch_update(Ordering::SeqCst, Ordering::SeqCst, |x| {
                        if x >= val {
                            Some(x - val)
                        } else {
                            None
                        }
                    })
                    .is_err()
                {}
            }
            0xc => self.full_count.store(val, Ordering::SeqCst),
            0x10 => {
                self.full_count.fetch_add(val, Ordering::SeqCst);
            }
            0x14 => {
                while self
                    .full_count
                    .fetch_update(Ordering::SeqCst, Ordering::SeqCst, |x| {
                        if x >= val {
                            Some(x - val)
                        } else {
                            None
                        }
                    })
                    .is_err()
                {}
            }
            0x18 => self.use_queue.store(val, Ordering::SeqCst),
            0x1c => {
                self.use_queue.fetch_add(val, Ordering::SeqCst);
            }
            _ => {
                while self
                    .use_queue
                    .fetch_update(Ordering::SeqCst, Ordering::SeqCst, |x| {
                        if x >= val {
                            Some(x - val)
                        } else {
                            None
                        }
                    })
                    .is_err()
                {}
            }
        }
    }

    fn load(&self, _: u32, _: u8) -> u32 {
        0
    }
}
