// Copyright 2021 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/// Generic, memory-mapped peripherals implemented using runtime callbacks.
use crate::configuration::Callback;
use std::sync::atomic::{AtomicU32, Ordering};
use PeriphReq::{Load, Store};

/// Reference held by execution engine, referencing each peripheral instance in each cluster
pub struct Peripherals {
    peripherals: Vec<Box<dyn Peripheral>>,
    cluster_peripherals: Vec<Vec<(u32, usize)>>,
}

unsafe impl Sync for Peripherals {}

impl Peripherals {
    pub fn new() -> Self {
        Self {
            peripherals: get_peripheral_types(),
            cluster_peripherals: Default::default(),
        }
    }

    pub fn add_cluster(&mut self, callbacks: &Vec<Callback>) {
        self.cluster_peripherals.push(
            callbacks
                .iter()
                .map(|x| {
                    (
                        x.size,
                        self.peripherals
                            .iter()
                            .position(|p| x.name.eq(&p.get_name()))
                            .expect(&format!("Undefined peripheral type: {}", x.name)[..]),
                    )
                })
                .collect(),
        );
    }

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
                    Load => {
                        trace!(
                            "Periph load from {}: cluster_id {}, offs 0x{:x}, size {}",
                            self.peripherals[i.1].get_name(),
                            cluster_id,
                            addr,
                            size
                        );
                        self.peripherals[i.1].load(addr, size)
                    }
                    Store(val, mask) => {
                        trace!(
                            "Periph store to {}: cluster_id {}, offs 0x{:x}, size {}, mask 0x{:x}, val {}",
                            self.peripherals[i.1].get_name(),
                            cluster_id,
                            addr,
                            size,
                            mask,
                            val
                        );
                        self.peripherals[i.1].store(addr, val, mask, size);
                        0
                    }
                };
            }
            addr = addr - i.0;
        }
        // Handle unmapped accesses: have no side effect on peripherals
        // TODO: should we trigger an error-response-like exception here?
        match req {
            Load => trace!(
                "Unmapped periph load: cluster_id {}, addr {}, size {}",
                cluster_id,
                addr,
                size
            ),
            Store(val, mask) => trace!(
                "Unmapped periph store: cluster_id {}, addr {}, size {}, mask {}, val {}",
                cluster_id,
                addr,
                size,
                mask,
                val
            ),
        }
        0
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

/// Function called by the engine to get the peripheral types. This function should
/// return a vector containing an instance of each available peripherable type.
/// To add a new peripheral type, declare it below and add it here.
pub fn get_peripheral_types() -> Vec<Box<dyn Peripheral>> {
    vec![
        Box::new(Semaphores::default()),
        Box::new(Fence::default()),
        Box::new(ZeroMemory::default()),
    ]
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

#[derive(Default)]
struct ZeroMemory {}

impl Peripheral for ZeroMemory {
    fn get_name(&self) -> &'static str {
        "zero-memory"
    }

    fn store(&self, _: u32, _: u32, _: u32, _: u8) {}

    fn load(&self, _: u32, _: u8) -> u32 {
        0
    }
}
