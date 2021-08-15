// Copyright 2021 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

use crate::peripherals::Peripheral;
use std::sync::atomic::{AtomicU32, AtomicU8, Ordering};
use PeriphCounterState::{CountLoad, CountLoadStore, CountStore, Disabled};

/// Function called by the engine to get the peripherals. This function should return a vector
/// containing an instance of all the peripherals.
pub fn create_peripherals() -> Vec<Box<dyn Peripheral>> {
    vec![Box::new(Semaphores::default()), Box::new(Fence::default())]
}

#[derive(Default)]
struct PeriphCounter {
    state: AtomicU8,
    counter: AtomicU32,
}

impl Peripheral for PeriphCounter {
    fn get_name(&self) -> &'static str {
        "periph_counter"
    }

    fn store(&self, addr: u32, val: u32, mask: u32, _: u8) {
        if addr == 0 && (mask & 0x3) == 0x3 {
            let val = val & 0x3;
            if val == 0 {
                self.state.store(Disabled as u8, Ordering::SeqCst);
                self.counter.store(0, Ordering::SeqCst);
            } else if val == 1 {
                self.state.store(CountLoad as u8, Ordering::SeqCst);
                self.counter.store(0, Ordering::SeqCst);
            } else if val == 2 {
                self.state.store(CountStore as u8, Ordering::SeqCst);
                self.counter.store(0, Ordering::SeqCst);
            } else if val == 3 {
                self.state.store(CountLoadStore as u8, Ordering::SeqCst);
                self.counter.store(0, Ordering::SeqCst);
            } else if (self.state.load(Ordering::SeqCst) & 0x2) != 0 {
                self.counter.fetch_add(1, Ordering::SeqCst);
            }
        } else if (self.state.load(Ordering::SeqCst) & 0x2) != 0 {
            self.counter.fetch_add(1, Ordering::SeqCst);
        }
    }

    fn load(&self, addr: u32, _: u8) -> u32 {
        let mut res: u32 = 0;
        if addr > 3 {
            res = self.counter.load(Ordering::SeqCst) >> 8 * (addr - 4);
        } else if addr == 0 {
            res = self.state.load(Ordering::SeqCst) as u32;
        }
        let state = self.state.load(Ordering::SeqCst);
        if state == CountLoad as u8 || state == CountLoadStore as u8 {
            self.counter.fetch_add(1, Ordering::SeqCst);
        }
        res
    }
}

enum PeriphCounterState {
    Disabled = 0,
    CountLoad = 1,
    CountStore = 2,
    CountLoadStore = 3,
}

#[derive(Default)]
struct Fence{
    set: AtomicU32,
    current: AtomicU32,
}

impl Peripheral for Fence {
    fn get_name(&self) -> &'static str {
        "fence"
    }

    fn store(&self, addr: u32, val: u32, _mask: u32, _: u8) {
        println!("fence: {}", val);
        self.set.store(val, Ordering::SeqCst)
    }

    fn load(&self, _: u32, _: u8) -> u32 {
        println!("wait");
        self.current.fetch_add(1, Ordering::SeqCst);
        while self.set.load(Ordering::SeqCst) != self.current.load(Ordering::SeqCst) {}
        0
    }
}

#[derive(Default)]
struct Semaphores {
    emptyCount: AtomicU32,
    fullCount: AtomicU32,
    useQueue: AtomicU32,
}

impl Peripheral for Semaphores {
    fn get_name(&self) -> &'static str {
        "semaphores"
    }

    fn store(&self, addr: u32, val: u32, _mask: u32, _: u8) {
        println!("addr: {:x}, val: {}", addr, val);
        match addr {
            0x0 => self.emptyCount.store(val, Ordering::SeqCst),
            0x4 => {self.emptyCount.fetch_add(val, Ordering::SeqCst);}
            0x8 => while self.emptyCount.fetch_update(Ordering::SeqCst, Ordering::SeqCst, |x| if x >= val {
                Some(x - val)
            } else {
                None
            }
            ).is_err(){}
            0xc => self.fullCount.store(val, Ordering::SeqCst),
            0x10 => {self.fullCount.fetch_add(val, Ordering::SeqCst);}
            0x14 => while self.fullCount.fetch_update(Ordering::SeqCst, Ordering::SeqCst, |x| if x >= val {
                Some(x - val)
            } else {
                None
            }
            ).is_err(){}
            0x18 => self.useQueue.store(val, Ordering::SeqCst),
            0x1c => {self.useQueue.fetch_add(val, Ordering::SeqCst);}
            _ => while self.useQueue.fetch_update(Ordering::SeqCst, Ordering::SeqCst, |x| if x >= val {
                Some(x - val)
            } else {
                None
            }
            ).is_err(){}
        }
    }

    fn load(&self, _: u32, _: u8) -> u32 {
        0
    }
}
