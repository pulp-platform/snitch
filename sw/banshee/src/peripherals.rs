// Copyright 2021 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

//! Peripherals
use crate::configuration::Callback;
use crate::periph_conf::create_peripherals;
use PeriphReq::{Load, Store};

pub struct Peripherals {
    peripherals: Vec<(u32, Box<dyn Peripheral>)>,
}

unsafe impl Sync for Peripherals {}

impl Peripherals {
    pub fn new(callbacks: &Vec<Callback>) -> Self {
        let mut periphs = create_peripherals();
        Self {
            peripherals: callbacks
                .iter()
                .map(|x| {
                    (
                        x.size,
                        periphs.remove(
                            periphs
                                .iter()
                                .position(|p| x.name.eq(&p.get_name()))
                                .expect("One of the peripheral is not defined!"),
                        ),
                    )
                })
                .collect(),
        }
    }

    pub fn load(&self, addr: u32, size: u8) -> u32 {
        self.load_store(addr, size, Load)
    }

    pub fn store(&self, addr: u32, value: u32, size: u8) {
        self.load_store(addr, size, Store(value));
    }

    fn load_store(&self, mut addr: u32, size: u8, req: PeriphReq) -> u32 {
        for i in &self.peripherals {
            if addr < i.0 {
                return match req {
                    Load => i.1.load(addr, size),
                    Store(val) => {
                        i.1.store(addr, val, size);
                        0
                    }
                };
            }
            addr = addr - i.0;
        }
        match req {
            Load => DefaultPeripheral.load(addr, size),
            Store(val) => {
                DefaultPeripheral.store(addr, val, size);
                0
            }
        }
    }
}

enum PeriphReq {
    Load,
    Store(u32),
}

/// Trait represnting a peripheral
pub trait Peripheral {
    fn get_name(&self) -> &'static str;
    fn store(&self, addr: u32, value: u32, size: u8);
    fn load(&self, addr: u32, size: u8) -> u32;
}

struct DefaultPeripheral;

impl Peripheral for DefaultPeripheral {
    fn get_name(&self) -> &'static str {
        "default"
    }

    fn store(&self, _: u32, _: u32, _: u8) {
        trace!("PERIPHERALS DEFAULT CALLBACK: Store");
    }

    fn load(&self, _: u32, _: u8) -> u32 {
        trace!("PERIPHERALS DEFAULT CALLBACK: Load");
        0
    }
}