// Copyright 2021 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

use crate::peripherals::Peripheral;
use std::sync::atomic::AtomicPtr;

pub fn create_peripherals() -> Vec<Box<dyn Peripheral>> {
    vec![Box::new(PeriphCounter::default())]
}

#[derive(Default)]
struct PeriphCounter {
    state: AtomicPtr<PeriphCounterState>,
    counter: u32,
}

impl Peripheral for PeriphCounter {
    fn get_name(&self) -> &'static str {
        "periph_counter"
    }

    fn store(&self, addr: u32, val: u32, size: u8) {
        /*
        let val = val && 0x3;
        if val == 0 {
            sel
        }
        */
        println!("test");
    }

    fn load(&self, addr: u32, size: u8) -> u32 {
        0
    }
}

struct AtomicPeriphCounterState {}

enum PeriphCounterState {
    Disabled,
    CountLoad,
    CountStore,
    CountLoadStore,
}

impl Default for PeriphCounterState {
    fn default() -> Self {
        PeriphCounterState::Disabled
    }
}
