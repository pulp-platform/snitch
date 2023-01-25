// Copyright 2021 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/// Generic, memory-mapped peripherals implemented using runtime callbacks.
use crate::configuration::Callback;
use crate::Cpu;
use ndarray::{s, Array1, Array2, Array3};
use std::sync::atomic::{AtomicI32, AtomicU32, Ordering};
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

    pub fn load(&self, cpu: &Cpu, cluster_id: usize, addr: u32, size: u8) -> u32 {
        self.load_store(cpu, cluster_id, addr, size, Load)
    }

    pub fn store(&self, cpu: &Cpu, cluster_id: usize, addr: u32, value: u32, mask: u32, size: u8) {
        self.load_store(cpu, cluster_id, addr, size, Store(value, mask));
    }

    fn load_store(
        &self,
        cpu: &Cpu,
        cluster_id: usize,
        mut addr: u32,
        size: u8,
        req: PeriphReq,
    ) -> u32 {
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
                        self.peripherals[i.1].load(cpu, addr, size)
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
                        self.peripherals[i.1].store(cpu, addr, val, mask, size);
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
    fn store(&self, cpu: &Cpu, addr: u32, value: u32, mask: u32, size: u8);
    /// load instruction
    fn load(&self, cpu: &Cpu, addr: u32, size: u8) -> u32;
}

/// Function called by the cpu to get the peripheral types. This function should
/// return a vector containing an instance of each available peripherable type.
/// To add a new peripheral type, declare it below and add it here.
pub fn get_peripheral_types() -> Vec<Box<dyn Peripheral>> {
    vec![
        Box::new(Semaphores::default()),
        Box::new(Fence::default()),
        Box::new(ZeroMemory::default()),
        Box::new(MemPoolDMA::default()),
        Box::new(MemPoolITA::default()),
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

    fn store(&self, _cpu: &Cpu, addr: u32, val: u32, _mask: u32, _: u8) {
        match addr {
            0x0 => self.set.store(val, Ordering::SeqCst),
            _ => self.current.store(val, Ordering::SeqCst),
        }
    }

    fn load(&self, _cpu: &Cpu, _: u32, _: u8) -> u32 {
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

    fn store(&self, _cpu: &Cpu, addr: u32, val: u32, _mask: u32, _: u8) {
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

    fn load(&self, _cpu: &Cpu, _: u32, _: u8) -> u32 {
        0
    }
}

#[derive(Default)]
struct ZeroMemory {}

impl Peripheral for ZeroMemory {
    fn get_name(&self) -> &'static str {
        "zero-memory"
    }

    fn store(&self, _cpu: &Cpu, _: u32, _: u32, _: u32, _: u8) {}

    fn load(&self, _cpu: &Cpu, _: u32, _: u8) -> u32 {
        0
    }
}

#[derive(Default)]
struct MemPoolDMA {
    src_addr: AtomicU32,
    dst_addr: AtomicU32,
    num_bytes: AtomicU32,
    conf: AtomicU32,
    status: AtomicU32,
    next_id: AtomicU32,
    done: AtomicU32,
}

impl Peripheral for MemPoolDMA {
    /// should return the same name as in the config file
    fn get_name(&self) -> &'static str {
        "mempool-dma"
    }
    /// store instruction
    fn store(&self, _cpu: &Cpu, addr: u32, value: u32, _mask: u32, _size: u8) {
        match addr {
            0x00 => self.src_addr.store(value, Ordering::SeqCst),
            0x04 => self.dst_addr.store(value, Ordering::SeqCst),
            0x08 => self.num_bytes.store(value, Ordering::SeqCst),
            0x0C => self.conf.store(value, Ordering::SeqCst),
            0x10 => (), /* status: Write has no effect */
            0x14 => (), /* next_id: Write has no effect */
            0x18 => (), /* done: Write has no effect */
            _ => unimplemented!(),
        }
        self.done.store(0, Ordering::SeqCst);
    }
    /// load instruction
    fn load(&self, cpu: &Cpu, addr: u32, _size: u8) -> u32 {
        match addr {
            0x00 => self.src_addr.load(Ordering::SeqCst),
            0x04 => self.dst_addr.load(Ordering::SeqCst),
            0x08 => self.num_bytes.load(Ordering::SeqCst),
            0x0C => self.conf.load(Ordering::SeqCst),
            0x10 => self.status.load(Ordering::SeqCst),
            0x14 => {
                cpu.binary_memcpy(
                    self.dst_addr.load(Ordering::SeqCst),
                    self.src_addr.load(Ordering::SeqCst),
                    self.num_bytes.load(Ordering::SeqCst),
                );
                self.done.store(1, Ordering::SeqCst);
                self.next_id.load(Ordering::SeqCst)
            }
            0x18 => self.done.load(Ordering::SeqCst),
            _ => unimplemented!(),
        }
    }
}

#[derive(Default)]
struct MemPoolITA {
    config: AtomicU32,
    start_address: AtomicU32,
    eps_mul: AtomicI32,
    right_shift: AtomicU32,
}

impl Peripheral for MemPoolITA {
    /// should return the same name as in the config file
    fn get_name(&self) -> &'static str {
        "mempool-ita"
    }
    /// store instruction
    fn store(&self, cpu: &Cpu, addr: u32, value: u32, _mask: u32, _size: u8) {
        match addr {
            0x00 => unsafe {
                self.config.store(value as u32, Ordering::SeqCst);
                // Out addresses are currently hardcoded in ITA
                let out_addresses: [u32; 4] = [0x000c0300, 0x000c0700, 0x000c0b00, 0x000c0f00];
                let head_config = std::mem::transmute::<u32, [u8; 4]>(value);
                let mut return_value = 0;
                for (i, c) in head_config.iter().enumerate() {
                    if *c & 0x1 == 1 {
                        // Start ITA
                        self.run_ita(
                            cpu,
                            self.start_address.load(Ordering::SeqCst),
                            out_addresses[i],
                            self.eps_mul.load(Ordering::SeqCst),
                            self.right_shift.load(Ordering::SeqCst),
                        );
                        // Set `config` to done
                        return_value |= 0x3a << (8 * i);
                    }
                }
                self.config.store(return_value, Ordering::SeqCst);
            },
            0x04 => self.start_address.store(value as u32, Ordering::SeqCst),
            0x08 => unsafe {
                self.eps_mul
                    .store(std::mem::transmute::<u32, i32>(value), Ordering::SeqCst)
            },
            0x0C => self.right_shift.store(value, Ordering::SeqCst),
            _ => unimplemented!(),
        }
    }
    /// load instruction
    fn load(&self, _cpu: &Cpu, addr: u32, _size: u8) -> u32 {
        match addr {
            0x00 => {
                let conf = self.config.load(Ordering::SeqCst);
                if conf == 0x3a3a3a3a {
                    self.config.store(0x04040404, Ordering::SeqCst);
                }
                conf
            }
            0x04 => self.start_address.load(Ordering::SeqCst),
            0x08 => unsafe { std::mem::transmute::<i32, u32>(self.eps_mul.load(Ordering::SeqCst)) },
            0x0C => self.right_shift.load(Ordering::SeqCst),
            _ => unimplemented!(),
        }
    }
}

impl MemPoolITA {
    fn transpose_3d(data: &mut Array3<i8>, m: u32, n: u32, p: u32) {
        let copy = data.clone();
        for j in 0..m {
            for i in 0..n {
                for h in 0..p {
                    data[[j as usize, i as usize, h as usize]] =
                        copy[[j as usize, h as usize, i as usize]];
                }
            }
        }
    }

    unsafe fn ita_load_2d(
        cpu: &Cpu,
        data: &mut Array2<i8>,
        mut address: u32,
        m: u32,
        n: u32,
        splits: u32,
    ) {
        for split in 0..splits {
            for j in 0..m {
                for i in (0..n / splits).step_by(4) {
                    let word = cpu.binary_load(address, 2);
                    let elements = std::mem::transmute::<u32, [i8; 4]>(word);
                    for (offset, e) in elements.iter().enumerate() {
                        data[[j as usize, ((n / splits) * split + i) as usize + offset]] = *e;
                    }
                    address += 4;
                }
            }
        }
    }

    unsafe fn ita_load_3d(
        cpu: &Cpu,
        data: &mut Array3<i8>,
        mut address: u32,
        m: u32,
        n: u32,
        p: u32,
        splits: u32,
    ) {
        for split in 0..splits {
            for j in 0..m {
                for i in 0..n {
                    for h in (0..p / splits).step_by(4) {
                        let word = cpu.binary_load(address, 2);
                        let elements = std::mem::transmute::<u32, [i8; 4]>(word);
                        for (offset, e) in elements.iter().enumerate() {
                            data[[
                                j as usize,
                                i as usize,
                                ((p / splits) * split + h) as usize + offset,
                            ]] = *e;
                        }
                        address += 4;
                    }
                }
            }
        }
    }

    unsafe fn ita_store_2d(
        cpu: &Cpu,
        data: &Array2<i8>,
        address: u32,
        m: u32,
        n: u32,
        splits: u32,
    ) {
        let mut address_offset = 0;
        for split in 0..splits {
            for j in 0..m {
                for i in (0..n / splits).step_by(4) {
                    let mut elements = [0u8; 4];
                    for offset in 0..elements.len() {
                        elements[offset] =
                            data[[j as usize, ((n / splits) * split + i) as usize + offset]] as u8;
                    }
                    // let word = std::mem::transmute::<[u8; 4], u32>(elements);
                    let word = u32::from_ne_bytes(elements);
                    cpu.binary_store(address + address_offset, word, u32::MAX, 2);
                    for y in 0..4 {
                        let test = cpu.binary_load(address + address_offset + y, 2);
                    }
                    address_offset += 4;
                    if address_offset % 0x100 == 0 {
                        address_offset -= 0x0100;
                        address_offset += 0x1000;
                    }
                }
            }
        }
    }

    unsafe fn run_ita(
        &self,
        cpu: &Cpu,
        start_address: u32,
        out_address: u32,
        _eps_mult: i32,
        _right_shift: u32,
    ) {
        // TODO `eps_mult` and `right_shift` are currently hardcoded
        // Setup of matrices for query_projection_space_transformation and key_projection_space_transformation
        // Sequence of addresses are hardcoded
        let start = start_address;
        let offset = 64 * 64;
        let w4_addr = start + offset * 0;
        let w3_addr = start + offset * 1;
        let w2_addr = start + offset * 2;
        let q_addr = start + offset * 3;
        let k_addr = start + offset * 4;
        let w1_addr = start + offset * 5;
        let b4_addr = start + offset * 6;
        let b3_addr = start + offset * 7;
        let b2_addr = start + offset * 8;
        let b1_addr = start + offset * 9;

        let mut q = Array2::<i8>::zeros((64, 64));
        MemPoolITA::ita_load_2d(cpu, &mut q, q_addr, 64, 64, 4);
        let mut w_q = Array3::<i8>::zeros((1, 64, 64));
        MemPoolITA::ita_load_3d(cpu, &mut w_q, w1_addr, 1, 64, 64, 4);
        MemPoolITA::transpose_3d(&mut w_q, 1, 64, 64);

        let mut k = Array2::<i8>::zeros((64, 64));
        MemPoolITA::ita_load_2d(cpu, &mut k, k_addr, 64, 64, 4);

        let mut w_k = Array3::<i8>::zeros((1, 64, 64));
        MemPoolITA::ita_load_3d(cpu, &mut w_k, w2_addr, 1, 64, 64, 1);
        MemPoolITA::transpose_3d(&mut w_k, 1, 64, 64);

        // Setup of matrices for value_projection_space_transformation
        let mut b_v = Array3::<i8>::zeros((1, 64, 64));
        MemPoolITA::ita_load_3d(cpu, &mut b_v, b3_addr, 1, 64, 64, 4);
        MemPoolITA::transpose_3d(&mut b_v, 1, 64, 64);

        let mut v = k.clone();
        let mut w_v = Array3::<i8>::zeros((1, 64, 64));
        MemPoolITA::ita_load_3d(cpu, &mut w_v, w3_addr, 1, 64, 64, 1);
        MemPoolITA::transpose_3d(&mut w_v, 1, 64, 64);

        let mut v_p = Array3::<i32>::zeros((1, 64, 64));

        // matrices in the query_projection_space_transformation
        let mut b_q = Array3::<i8>::zeros((1, 64, 64));
        MemPoolITA::ita_load_3d(cpu, &mut b_q, b1_addr, 1, 64, 64, 4);
        let mut q_p = Array3::<i32>::zeros((1, 64, 64));

        // matrices in the key_projection_space_transformation
        let mut b_k = Array3::<i8>::zeros((1, 64, 64));
        MemPoolITA::ita_load_3d(cpu, &mut b_k, b2_addr, 1, 64, 64, 4);

        let mut k_p = Array3::<i32>::zeros((1, 64, 64));

        // matrices in the streaming_partial_softmax
        let mut a_requant = Array3::<i8>::zeros((1, 64, 64));
        let mut a_partial_softmax = Array2::<i32>::zeros((64, 64));

        // matrices in multi_head_computation
        let mut out = Array3::<i32>::zeros((1, 64, 64));
        let mut b_o = Array3::<i8>::zeros((1, 64, 64));
        MemPoolITA::ita_load_3d(cpu, &mut b_o, b4_addr, 1, 64, 64, 4);
        let mut w_o = Array3::<i8>::zeros((1, 64, 64));
        MemPoolITA::ita_load_3d(cpu, &mut w_o, w4_addr, 1, 64, 64, 1);
        MemPoolITA::transpose_3d(&mut w_o, 1, 64, 64);

        // query_projection_space_transformation
        // query_projection_space_transformation(&mut q_p, &mut q, &mut w_q, &mut b_q, 1);
        MemPoolITA::projection_space_transformation(&mut q_p, &mut q, &mut w_q, &mut b_q, 1);
        // requantization of q_p
        let mut q_p_requant = Array3::<i8>::zeros((1, 64, 64));
        MemPoolITA::requantization_3d(&mut q_p, &mut q_p_requant, 52, 14);
        debug!("q_p_requant: {}", q_p_requant);

        // key_projection_space_transformation
        // key_projection_space_transformation(&mut k_p, &mut k, &mut w_k, &mut b_k, 1);
        MemPoolITA::projection_space_transformation(&mut k_p, &mut k, &mut w_k, &mut b_k, 1);
        // requantization of k_p
        let mut k_p_requant = Array3::<i8>::zeros((1, 64, 64));
        MemPoolITA::requantization_3d(&mut k_p, &mut k_p_requant, 66, 14);
        debug!("k_p_requant: {}", k_p_requant);

        // query_key_correlation
        let mut qk = Array3::<i32>::zeros((1, 64, 64));
        MemPoolITA::query_key_correlation(&mut q_p_requant, &mut k_p_requant, &mut qk);
        // requantization of qk
        MemPoolITA::requantization_3d(&mut qk, &mut a_requant, 19, 14);
        debug!("a_requant: {}", a_requant);

        // streaming_partial_softmax
        MemPoolITA::streaming_partial_softmax(&mut a_requant, &mut a_partial_softmax, 64);

        // value_projection_space_transformation
        // value_projection_space_transformation(&mut v_p, &mut v, &mut w_v, &mut b_v, 1);
        MemPoolITA::projection_space_transformation(&mut v_p, &mut v, &mut w_v, &mut b_v, 1);
        // requantization of v_p
        let mut v_p_requant = Array3::<i8>::zeros((1, 64, 64));
        MemPoolITA::requantization_3d(&mut v_p, &mut v_p_requant, 54, 14);
        debug!("v_p_requant: {}", v_p_requant);

        // single_head_computation
        let mut o_softmax = Array3::<i32>::zeros((1, 64, 64));
        MemPoolITA::single_head_computation(
            &mut a_partial_softmax,
            &mut v_p_requant,
            &mut o_softmax,
        );
        // requantization of o_softmax
        let mut o_softmax_requant = Array3::<i8>::zeros((1, 64, 64));
        MemPoolITA::requantization_3d(&mut o_softmax, &mut o_softmax_requant, 76, 14);
        debug!("o_softmax_requant: {}", o_softmax_requant);

        // multi_head_computation
        MemPoolITA::multi_head_computation(&mut o_softmax_requant, &mut out, &mut w_o, &mut b_o, 1);
        // parallel requantization of out
        let mut out_requant = Array2::<i8>::zeros((64, 64));
        MemPoolITA::parallel_requantize3d(&mut out, &mut out_requant, 6, 14);
        debug!("out_requant: {}", out_requant);

        // Store the output
        MemPoolITA::ita_store_2d(cpu, &out_requant, out_address, 64, 64, 1);
    }

    // NOTE: At the moment also the bias matrix is given
    // as input, but it should be initialized with random
    // numbers in the future.

    fn requantize_row(element: i32, eps_mult: i32, right_shift: i32) -> i8 {
        let shifted = (element * eps_mult) >> right_shift;
        if shifted > 127 {
            return 127;
        } else if shifted < -128 {
            return -128;
        } else {
            return shifted as i8;
        }
    }

    fn requantization_3d(
        m: &mut Array3<i32>,
        m_requant: &mut Array3<i8>,
        eps_mult: i32,
        right_shift: i32,
    ) {
        debug!("===================== 3D Requantization =====================");

        // Loop over the number of heads
        for i in 0..m.shape()[0] {
            // Loop over the head dimension
            for j in 0..m.shape()[1] {
                // print the column of the head matrix
                let row = m.slice(s![i, j, ..]);
                // Iterate over the row and requantize it
                for k in 0..row.len() {
                    m_requant[[i, j, k]] =
                        MemPoolITA::requantize_row(row[k], eps_mult, right_shift);
                }
            }
        }
    }

    fn parallel_requantize3d(
        m: &mut Array3<i32>,
        m_requant: &mut Array2<i8>,
        eps_mult: i32,
        right_shift: i32,
    ) {
        debug!("===================== Parallel 3D Requantization =====================");

        for i in 0..m.shape()[0] {
            for j in 0..m.shape()[1] {
                let row = m.slice(s![i, j, ..]);
                for k in 0..row.len() {
                    let shifted = MemPoolITA::requantize_row(row[k], eps_mult, right_shift) as i32
                        + m_requant[[i * m.shape()[1] + j, k]] as i32;
                    m_requant[[i * m.shape()[1] + j, k]] =
                        MemPoolITA::requantize_row(shifted, 1, 0);
                }
            }
        }
    }

    fn projection_space_transformation(
        p: &mut Array3<i32>,
        m: &mut Array2<i8>,
        w: &mut Array3<i8>,
        b: &mut Array3<i8>,
        bias: u8,
    ) {
        debug!("===================== Projection Space Transformation =====================");
        if bias == 1 {
            for i in 0..p.shape()[0] {
                for j in 0..p.shape()[1] {
                    for k in 0..p.shape()[2] {
                        p[[i, j, k]] = b[[i, j, k]] as i32;
                        for l in 0..m.shape()[1] {
                            p[[i, j, k]] += m[[j, l]] as i32 * w[[i, l, k]] as i32;
                        }
                    }
                }
            }
        } else {
            for i in 0..p.shape()[0] {
                for j in 0..p.shape()[1] {
                    for k in 0..p.shape()[2] {
                        p[[i, j, k]] = 0;
                        for l in 0..m.shape()[1] {
                            p[[i, j, k]] += m[[j, l]] as i32 * w[[i, l, k]] as i32;
                        }
                    }
                }
            }
        }

        debug!("projected matrix: {:?}", p);
    }

    fn query_key_correlation(
        qp_requant: &mut Array3<i8>,
        kp_requant: &mut Array3<i8>,
        qk: &mut Array3<i32>,
    ) {
        debug!("===================== Query Key Correlation =====================");

        // Loop over the number of heads
        for i in 0..qk.shape()[0] {
            // Loop over the number of queries
            for j in 0..qk.shape()[1] {
                // Loop over the number of keys
                for k in 0..qk.shape()[2] {
                    qk[[i, j, k]] = 0;
                    // Loop over the number of features
                    for l in 0..qk.shape()[1] {
                        qk[[i, j, k]] += qp_requant[[i, j, l as usize]] as i32
                            * kp_requant[[i, k, l as usize]] as i32;
                    }
                }
            }
        }

        debug!("qk: {:?}", qk);
    }

    //Compute the approximated softmax function.
    fn streaming_partial_softmax(
        a_requant: &mut Array3<i8>,
        a_partial_softmax: &mut Array2<i32>,
        seq_len: i32,
    ) {
        debug!("===================== Streaming Partial SoftMax =====================");

        // let log2e: f64 = f64::log2(f64::exp(1.0));
        // let b = 8;
        // let eps_x = b as f64 / (2.0f64.powi(b) * log2e);
        let mut exp_partial_sum = Array1::<i32>::zeros(seq_len as usize);
        let mut max = Array1::<i8>::zeros(64);
        let mut current_max = Array1::<i8>::zeros(64);

        for i in 0..4 {
            let a_requant_slice = a_requant.slice_mut(s![0, .., i * 16..(i + 1) * 16]);

            for n in 0..a_requant_slice.nrows() {
                current_max[[n]] = a_requant_slice.row(n).iter().copied().max().unwrap() as i8;
            }

            for j in 0..seq_len {
                let mut shift_sum;
                if i == 0 || current_max[j as usize] > max[[j as usize]] {
                    if i == 0 {
                        shift_sum = 0;
                    } else {
                        shift_sum = (current_max[j as usize] - max[[j as usize]]) / 32;
                        if (((current_max[j as usize] - max[[j as usize]]) / 32) - shift_sum) as f64
                            >= 0.5
                        {
                            shift_sum += 1;
                        }
                    }
                    max[j as usize] = current_max[j as usize];
                } else {
                    shift_sum = 0;
                }

                let qb = a_requant
                    .slice_mut(s![0, .., i * 16..(i + 1) * 16])
                    .mapv(|x| x - max[[j as usize]]);

                let mut qexp = 0;
                for k in 0..qb.ncols() {
                    let mut shift = (-qb[[j as usize, k]]) as i32 / 32;
                    let shift_int = (-qb[[j as usize, k]]) as i32;

                    if shift_int % 32 >= 16 {
                        shift += 1;
                    }

                    qexp += (2_u32.pow(10) >> shift as i32) as i32;
                }

                exp_partial_sum[[j as usize]] =
                    (exp_partial_sum[[j as usize]] >> shift_sum as i32) + qexp;
            }
        }
        for j in 0..seq_len {
            let factor =
                ((2.0f64.powi(8) - 1.0) * 2.0f64.powi(10)) as i32 / exp_partial_sum[j as usize];
            for k in 0..seq_len {
                let mut shift =
                    ((max[j as usize] - (a_requant[[0, j as usize, k as usize]])) / 32) as i32;
                let shift_int = max[j as usize] - (a_requant[[0, j as usize, k as usize]]) as i8;
                if shift_int % 32 >= 16 {
                    shift += 1;
                }
                a_partial_softmax[[j as usize, k as usize]] =
                    (factor as i32) / 2.0f64.powi(shift) as i32;
            }
        }

        debug!("a_partial_softmax: {}", a_partial_softmax);
    }

    fn single_head_computation(
        a_partial_softmax: &mut Array2<i32>,
        vp_requant: &mut Array3<i8>,
        o_softmax: &mut Array3<i32>,
    ) {
        debug!("===================== Single Head Computation =====================");

        // Loop over the number of heads
        for i in 0..o_softmax.shape()[0] {
            // Loop over the number of queries
            for j in 0..o_softmax.shape()[1] {
                // Loop over the number of keys
                for k in 0..o_softmax.shape()[2] {
                    o_softmax[[i, j, k]] = 0;
                    // Loop over the number of features
                    for l in 0..o_softmax.shape()[1] {
                        o_softmax[[i, j, k]] +=
                            a_partial_softmax[[j, l]] as i32 * vp_requant[[i, l, k]] as i32;
                    }
                }
            }
        }

        debug!("o_softmax: {:?}", o_softmax);
    }

    fn multi_head_computation(
        o_softmax_requant: &mut Array3<i8>,
        out: &mut Array3<i32>,
        w_o: &mut Array3<i8>,
        b_o: &mut Array3<i8>,
        bias: u8,
    ) {
        debug!("===================== Multi Head Computation =====================");

        if bias == 1 {
            for i in 0..out.shape()[0] {
                for j in 0..out.shape()[1] {
                    for k in 0..out.shape()[2] {
                        out[[i, j, k]] = b_o[[i, j, k]] as i32;
                        for l in 0..out.shape()[1] {
                            out[[i, j, k]] +=
                                o_softmax_requant[[i, j, l]] as i32 * w_o[[i, l, k]] as i32;
                        }
                    }
                }
            }
        } else {
            for i in 0..out.shape()[0] {
                for j in 0..out.shape()[1] {
                    for k in 0..out.shape()[2] {
                        out[[i, j, k]] = 0;
                        for l in 0..out.shape()[1] {
                            out[[i, j, k]] +=
                                o_softmax_requant[[i, j, l]] as i32 * w_o[[i, l, k]] as i32;
                        }
                    }
                }
            }
        }

        debug!("out: {:?}", out);
    }
}
