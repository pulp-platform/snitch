// Copyright 2021 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

//! Peripherals
use crate::configuration::Callback;
use crate::periph_conf::create_peripherals;
use PeriphReq::{Load, Store};

pub struct Peripherals {
    peripherals: Vec<Box<dyn Peripheral>>,
    cluster_peripherals: Vec<Vec<(u32, usize)>>,
}

unsafe impl Sync for Peripherals {}

impl Peripherals {
    pub fn new() -> Self {
        Self {
            peripherals: create_peripherals(),
            cluster_peripherals: Default::default(),
        }
    }

    pub fn add_cluster(&mut self, callbacks: &Vec<Callback>) {
        self.cluster_peripherals.push(
            callbacks.iter().map(|x| {
                (
                    x.size,
                    self.peripherals
                    .iter()
                    .position(|p| x.name.eq(&p.get_name()))
                    .expect(&format!("One of the peripheral is not defined: {}", x.name)[..])
                  )
            }).collect()
            );
    }
    /*
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
                            .expect(&format!("One of the peripheral is not defined: {}", x.name)[..]),
                            ),
                            )
                })
            .collect(),
        }
    }
*/
    pub fn load(&self, cluster_id: usize, addr: u32, size: u8) -> u32 {
        self.load_store(cluster_id, addr, size, Load)
    }

    pub fn store(&self, cluster_id: usize, addr: u32, value: u32, mask: u32, size: u8) {
        self.load_store(cluster_id, addr, size, Store(value, mask));
    }

    fn load_store(&self, cluster_id: usize, mut addr: u32, size: u8, req: PeriphReq) -> u32 {
        for i in &self.cluster_peripherals[cluster_id] {
            if addr < i.0 {
                return match req {
                    Load => self.peripherals[i.1].load(addr, size),
                    Store(val, mask) => {
                        self.peripherals[i.1].store(addr, val, mask, size);
                        0
                    }
                };
            }
            addr = addr - i.0;
        }
        match req {
            Load => DefaultPeripheral.load(addr, size),
            Store(val, mask) => {
                DefaultPeripheral.store(addr, val, mask, size);
                0
            }
        }
    }
}

enum PeriphReq {
    Load,
    Store(u32, u32),
}

/// Trait representing a peripheral
pub trait Peripheral {
    /// should return the same name as in the config file
    fn get_name(&self) -> &'static str;
    /// store instruction
    fn store(&self, addr: u32, value: u32, mask: u32, size: u8);
    /// load instruction
    fn load(&self, addr: u32, size: u8) -> u32;
}

struct DefaultPeripheral;

impl Peripheral for DefaultPeripheral {
    fn get_name(&self) -> &'static str {
        "default"
    }

    fn store(&self, _: u32, _: u32, _: u32, _: u8) {
        trace!("PERIPHERALS DEFAULT CALLBACK: Store");
    }

    fn load(&self, _: u32, _: u8) -> u32 {
        trace!("PERIPHERALS DEFAULT CALLBACK: Load");
        0
    }
}
