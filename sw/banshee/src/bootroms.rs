// Copyright 2021 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/// Bootrom implementations for various architecture.
use crate::configuration::Callback;
use std::sync::atomic::{AtomicU32, AtomicU64, Ordering};

/// Reference held by execution engine, referencing each peripheral instance in each cluster
pub struct Bootroms {
    bootrom_types: Vec<Box<dyn Bootrom>>,
    bootrom: Vec<Vec<(u32, usize)>>,
}

impl Bootroms {
    pub fn new() -> Self {
        Self {
            bootrom_types: get_bootrom_types(),
            bootrom: Default::default(),
        }
    }

    pub fn add_bootrom(&mut self, callbacks: &Vec<Callback>) {
        self.bootrom.push(
            callbacks
                .iter()
                .map(|x| {
                    (
                        x.size,
                        self.bootrom_types
                            .iter()
                            .position(|p| x.name.eq(&p.get_name()))
                            .expect(&format!("Undefined bootrom type: {}", x.name)[..]),
                    )
                })
                .collect(),
        );
    }

    pub fn load(&self, addr: u32) -> u32 {
        for i in &self.bootrom[0] {
            if addr < i.0 {
                trace!(
                    "Bootrom load from {}: offs 0x{:x}",
                    self.bootrom_types[i.1].get_name(),
                    addr
                );
                debug!(
                    "Bootrom load from {}: offs 0x{:x}",
                    self.bootrom_types[i.1].get_name(),
                    addr
                );
                return self.bootrom_types[i.1].load(addr);
            }
            // addr = addr - i.0;
        }
        trace!("Unmapped periph load: addr {}", addr);
        0
    }
}

/// Trait representing a peripheral
pub trait Bootrom {
    /// should return the same name as in the config file
    fn get_name(&self) -> &'static str;
    /// load instruction
    fn load(&self, addr: u32) -> u32;
}

/// Function called by the engine to get the peripheral types. This function should
/// return a vector containing an instance of each available peripherable type.
/// To add a new peripheral type, declare it below and add it here.
pub fn get_bootrom_types() -> Vec<Box<dyn Bootrom>> {
    vec![
        Box::new(BootromOccamy::default()),
        Box::new(BootromCluster::default()),
        Box::new(BootromMultiCluster::default()),
    ]
}

struct BootromOccamy {
    boot_addr: AtomicU32,
    core_count: AtomicU32,
    hartid_base: AtomicU32,
    tcdm_start: AtomicU32,
    tcdm_size: AtomicU32,
    tcdm_offset: AtomicU32,
    global_mem_start: AtomicU64,
    global_mem_end: AtomicU64,
    cluster_count: AtomicU32,
    s1_quadrant_count: AtomicU32,
    clint_base: AtomicU32,
}

impl Default for BootromOccamy {
    fn default() -> Self {
        Self {
            boot_addr: AtomicU32::new(0x1000000),
            core_count: AtomicU32::new(9),
            hartid_base: AtomicU32::new(1),
            tcdm_start: AtomicU32::new(0x10000000),
            tcdm_size: AtomicU32::new(0x20000),
            tcdm_offset: AtomicU32::new(0x40000),
            global_mem_start: AtomicU64::new(0x80000000),
            global_mem_end: AtomicU64::new(0x100000000),
            cluster_count: AtomicU32::new(4),
            s1_quadrant_count: AtomicU32::new(8),
            clint_base: AtomicU32::new(0x4000000),
        }
    }
}

impl Bootrom for BootromOccamy {
    fn get_name(&self) -> &'static str {
        "bootrom-occamy"
    }

    fn load(&self, addr: u32) -> u32 {
        match addr {
            0x0 => self.boot_addr.load(Ordering::SeqCst),
            0x4 => self.core_count.load(Ordering::SeqCst),
            0x8 => self.hartid_base.load(Ordering::SeqCst),
            0xc => self.tcdm_start.load(Ordering::SeqCst),
            0x10 => self.tcdm_size.load(Ordering::SeqCst),
            0x14 => self.tcdm_offset.load(Ordering::SeqCst),
            0x18 => (self.global_mem_start.load(Ordering::SeqCst) & 0xfff) as u32,
            0x1c => ((self.global_mem_start.load(Ordering::SeqCst) >> 5) & 0xfff) as u32,
            0x20 => (self.global_mem_end.load(Ordering::SeqCst) & 0xfff) as u32,
            0x24 => ((self.global_mem_end.load(Ordering::SeqCst) >> 5) & 0xfff) as u32,
            0x28 => self.cluster_count.load(Ordering::SeqCst),
            0x2c => self.s1_quadrant_count.load(Ordering::SeqCst),
            0x30 => self.clint_base.load(Ordering::SeqCst),
            _ => 0,
        }
    }
}

struct BootromCluster {
    boot_addr: AtomicU32,
    core_count: AtomicU32,
    hartid_base: AtomicU32,
    tcdm_start: AtomicU32,
    tcdm_size: AtomicU32,
    tcdm_offset: AtomicU32,
    global_mem_start: AtomicU64,
    global_mem_end: AtomicU64,
    cluster_count: AtomicU32,
    s1_quadrant_count: AtomicU32,
    clint_base: AtomicU32,
}

impl Default for BootromCluster {
    fn default() -> Self {
        Self {
            boot_addr: AtomicU32::new(0x1000),
            core_count: AtomicU32::new(9),
            hartid_base: AtomicU32::new(0),
            tcdm_start: AtomicU32::new(0x100000),
            tcdm_size: AtomicU32::new(0x20000),
            tcdm_offset: AtomicU32::new(0x0),
            global_mem_start: AtomicU64::new(0x80000000),
            global_mem_end: AtomicU64::new(0x100000000),
            cluster_count: AtomicU32::new(1),
            s1_quadrant_count: AtomicU32::new(1),
            clint_base: AtomicU32::new(0xffff0000),
        }
    }
}

impl Bootrom for BootromCluster {
    fn get_name(&self) -> &'static str {
        "bootrom-cluster"
    }

    fn load(&self, addr: u32) -> u32 {
        match addr {
            0x0 => self.boot_addr.load(Ordering::SeqCst),
            0x4 => self.core_count.load(Ordering::SeqCst),
            0x8 => self.hartid_base.load(Ordering::SeqCst),
            0xc => self.tcdm_start.load(Ordering::SeqCst),
            0x10 => self.tcdm_size.load(Ordering::SeqCst),
            0x14 => self.tcdm_offset.load(Ordering::SeqCst),
            0x18 => (self.global_mem_start.load(Ordering::SeqCst) & 0xffffffff) as u32,
            0x1c => ((self.global_mem_start.load(Ordering::SeqCst) >> 32) & 0xffffffff) as u32,
            0x20 => (self.global_mem_end.load(Ordering::SeqCst) & 0xffffffff) as u32,
            0x24 => ((self.global_mem_end.load(Ordering::SeqCst) >> 32) & 0xffffffff) as u32,
            0x28 => self.cluster_count.load(Ordering::SeqCst),
            0x2c => self.s1_quadrant_count.load(Ordering::SeqCst),
            0x30 => self.clint_base.load(Ordering::SeqCst),
            _ => 0,
        }
    }
}

struct BootromMultiCluster {
    boot_addr: AtomicU32,
    core_count: AtomicU32,
    hartid_base: AtomicU32,
    tcdm_start: AtomicU32,
    tcdm_size: AtomicU32,
    tcdm_offset: AtomicU32,
    global_mem_start: AtomicU64,
    global_mem_end: AtomicU64,
    cluster_count: AtomicU32,
    s1_quadrant_count: AtomicU32,
    clint_base: AtomicU32,
}

impl Default for BootromMultiCluster {
    fn default() -> Self {
        Self {
            boot_addr: AtomicU32::new(0x1000000),
            core_count: AtomicU32::new(9),
            hartid_base: AtomicU32::new(1),
            tcdm_start: AtomicU32::new(0x10000000),
            tcdm_size: AtomicU32::new(0x20000),
            tcdm_offset: AtomicU32::new(0x40000),
            global_mem_start: AtomicU64::new(0x80000000),
            global_mem_end: AtomicU64::new(0x100000000),
            cluster_count: AtomicU32::new(2),
            s1_quadrant_count: AtomicU32::new(1),
            clint_base: AtomicU32::new(0x4000000),
        }
    }
}

impl Bootrom for BootromMultiCluster {
    fn get_name(&self) -> &'static str {
        "bootrom-multicluster"
    }

    fn load(&self, addr: u32) -> u32 {
        match addr {
            0x0 => self.boot_addr.load(Ordering::SeqCst),
            0x4 => self.core_count.load(Ordering::SeqCst),
            0x8 => self.hartid_base.load(Ordering::SeqCst),
            0xc => self.tcdm_start.load(Ordering::SeqCst),
            0x10 => self.tcdm_size.load(Ordering::SeqCst),
            0x14 => self.tcdm_offset.load(Ordering::SeqCst),
            0x18 => (self.global_mem_start.load(Ordering::SeqCst) & 0xfff) as u32,
            0x1c => ((self.global_mem_start.load(Ordering::SeqCst) >> 5) & 0xfff) as u32,
            0x20 => (self.global_mem_end.load(Ordering::SeqCst) & 0xfff) as u32,
            0x24 => ((self.global_mem_end.load(Ordering::SeqCst) >> 5) & 0xfff) as u32,
            0x28 => self.cluster_count.load(Ordering::SeqCst),
            0x2c => self.s1_quadrant_count.load(Ordering::SeqCst),
            0x30 => self.clint_base.load(Ordering::SeqCst),
            _ => 0,
        }
    }
}
