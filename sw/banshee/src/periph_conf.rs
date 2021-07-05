// Copyright 2021 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

use crate::peripherals::Peripheral;
use std::sync::atomic::{AtomicU32, AtomicU8, Ordering};
use PeriphCounterState::{CountLoad, CountLoadStore, CountStore, Disabled};

/// Function called by the engine to get the peripherals. This function should return a vector
/// containing an instance of all the peripherals.
pub fn create_peripherals() -> Vec<Box<dyn Peripheral>> {
    vec![Box::new(PeriphCounter::default())]
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

    fn store(&self, addr: u32, val: u32, _: u8) {
        if addr == 0 {
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
