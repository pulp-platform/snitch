// This seems to be bug in the compiler.
#![allow(unused_parens, dead_code)]

#[macro_use]
extern crate clap;
#[macro_use]
extern crate log;
extern crate llvm_sys as llvm;

// use std::collections::HashMap;
use anyhow::{bail, Context, Result};
use clap::Arg;
use llvm_sys::{bit_writer::*, core::*, execution_engine::*, initialization::*, target::*};
// use softfloat::{self as sf, Sf32, Sf64};
use std::cell::RefCell;
use std::collections::HashMap;
use std::fmt;
use std::{path::Path, ptr::null_mut};

pub mod engine;
pub mod riscv;
mod softfloat;
pub mod tran;

use engine::*;

/// Architectural state of a Snich Hart.
struct Snitch<'a> {
    // Architectural state of a RiSC-V Hart.
    state: RISCVState<'a>,
    /// Time.
    clock: u64,
    /// Instruction Fetch Port.
    instr: &'a dyn RWMemory,
    /// Supported Ops.
    ops: Vec<RISCVInstr>,
}

// #[derive(Debug)]
struct RISCVState<'a> {
    /// Program Counter.
    pc: u32,
    /// Integer Regsters.
    reg: [u32; 32],
    /// CSRs
    csrs: HashMap<u16, u32>,
    /// Memory Port
    mem: &'a dyn RWMemory,
}

impl<'a> fmt::Display for RISCVState<'a> {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        for i in 0..8 {
            for j in 0..4 {
                let idx = i * 4 + j;
                write!(
                    f,
                    "{:4}: 0x{:08x} ",
                    get_abi_reg_name(idx as u8),
                    self.reg[idx]
                )
                .ok();
            }
            write!(f, "\n").ok();
        }
        write!(f, "")
    }
}

/// Functional description of a RISC-V Instruction.
type RISCVInstrDesc = Box<(dyn FnMut(&mut RISCVState, u32) -> ())>;

/// RISC-V Instruction
struct RISCVInstr {
    /// Instruction Opcode
    opcode: riscv::Opcode,
    /// Functional description. Need to Box this value since the compiler is not aware on how big the
    /// closure is.
    instr_descr: RISCVInstrDesc,
}

impl RISCVInstr {
    fn new(opcode: riscv::Opcode, instr_descr: RISCVInstrDesc) -> RISCVInstr {
        RISCVInstr {
            opcode,
            instr_descr,
        }
    }
}
/// Extract `rd` from instruction.
fn rd(instr: u32) -> usize {
    ((instr & 0xF80) as usize) >> 7
}

/// Extract `rs1` from instruction.
fn rs1(instr: u32) -> usize {
    ((instr & 0xF8000) as usize) >> 15
}

/// Extract `rs2` from instruction.
fn rs2(instr: u32) -> usize {
    ((instr & 0x1F00000) as usize) >> 20
}

/// Extract `i_imm` from instruction.
fn i_imm(instr: u32) -> i32 {
    ((instr & 0xFFF00000) as i32) >> 20
}

/// Extract `s_imm` from instruction.
fn s_imm(instr: u32) -> i32 {
    (((instr & 0b0000_0000_0000_0000_0000_1111_1000_0000) as i32) >> 7)
        | (((instr & 0b1111_1110_0000_0000_0000_0000_0000_0000) as i32) >> 20)
}

/// Extract `b_imm` from instruction.
fn b_imm(instr: u32) -> i32 {
    (((instr & 0b0000_0000_0000_0000_0000_1111_0000_0000) as i32) >> 7)
        | (((instr & 0b0111_1110_0000_0000_0000_0000_0000_0000) as i32) >> 20)
        | (((instr & 0b0000_0000_0000_0000_0000_0000_1000_0000) as i32) << 4)
        | (((instr & 0b1000_0000_0000_0000_0000_0000_0000_0000) as i32) >> 19)
}

/// Extract `u_imm` from instruction.
fn u_imm(instr: u32) -> u32 {
    (instr & 0xFFFFF000) as u32
}

/// Extract `j_imm` from instruction.
fn j_imm(instr: u32) -> i32 {
    (((instr & 0b0111_1111_1110_0000_0000_0000_0000_0000) as i32) >> 20)
        | (((instr & 0b0000_0000_0001_0000_0000_0000_0000_0000) as i32) >> 9)
        | ((instr & 0b0000_0000_0000_1111_1111_0000_0000_0000) as i32)
        | (((instr & 0b1000_0000_0000_0000_0000_0000_0000_0000) as i32) >> 11)
}

/// Extract `z_imm` from instruction.
fn zimm(instr: u32) -> u32 {
    rs1(instr) as u32
}

fn shamt(instr: u32) -> u32 {
    rs2(instr) as u32
}

fn csr(instr: u32) -> u32 {
    (instr & 0b1111_1111_1111_0000_0000_0000_0000_0000) >> 20
}

macro_rules! register_op {
    ($id:ident, $op:path, $desc:tt) => {
        $id.push(RISCVInstr::new($op, Box::new($desc)));
    };
}

fn get_abi_reg_name(reg: u8) -> &'static str {
    return match reg {
        0 => "zero",
        1 => "ra",
        2 => "sp",
        3 => "gp",
        4 => "tp",
        5 => "t0",
        6 => "t1",
        7 => "t2",
        8 => "s0",
        9 => "s1",
        10 => "a0",
        11 => "a1",
        12 => "a2",
        13 => "a3",
        14 => "a4",
        15 => "a5",
        16 => "a6",
        17 => "a7",
        18 => "s2",
        19 => "s3",
        20 => "s4",
        21 => "s5",
        22 => "s6",
        23 => "s7",
        24 => "s8",
        25 => "s9",
        26 => "s10",
        27 => "s1",
        28 => "t3",
        29 => "t4",
        30 => "t5",
        31 => "t6",
        _ => "invalid",
    };
}

impl<'a> Snitch<'a> {
    fn new(
        boot_addr: u32,
        hartid: u32,
        instr: &'a dyn RWMemory,
        mem: &'a dyn RWMemory,
    ) -> Snitch<'a> {
        // Add Opcodes
        let mut ops = Vec::new();
        register_op!(
            ops,
            riscv::Opcode::Auipc,
            (|s, instr| {
                s.pc += 4;
                s.reg[rd(instr)] = s.pc.wrapping_add(u_imm(instr));
            })
        );
        register_op!(
            ops,
            riscv::Opcode::Lui,
            (|s, instr| {
                s.pc += 4;
                s.reg[rd(instr)] = u_imm(instr) as u32;
            })
        );
        // Immediate OPs
        register_op!(
            ops,
            riscv::Opcode::Addi,
            (|s, instr| {
                s.pc += 4;
                s.reg[rd(instr)] = s.reg[rs1(instr)].wrapping_add(i_imm(instr) as u32);
            })
        );
        register_op!(
            ops,
            riscv::Opcode::Slti,
            (|s, instr| {
                s.pc += 4;
                s.reg[rd(instr)] = if ((s.reg[rs1(instr)] as i32) < i_imm(instr)) {
                    1
                } else {
                    0
                };
            })
        );
        register_op!(
            ops,
            riscv::Opcode::Sltiu,
            (|s, instr| {
                s.pc += 4;
                s.reg[rd(instr)] = if (s.reg[rs1(instr)] < (i_imm(instr) as u32)) {
                    1
                } else {
                    0
                };
            })
        );
        register_op!(
            ops,
            riscv::Opcode::Xori,
            (|s, instr| {
                s.pc += 4;
                s.reg[rd(instr)] = s.reg[rs1(instr)] ^ i_imm(instr) as u32;
            })
        );
        register_op!(
            ops,
            riscv::Opcode::Ori,
            (|s, instr| {
                s.pc += 4;
                s.reg[rd(instr)] = s.reg[rs1(instr)] | i_imm(instr) as u32;
            })
        );
        register_op!(
            ops,
            riscv::Opcode::Andi,
            (|s, instr| {
                s.pc += 4;
                s.reg[rd(instr)] = s.reg[rs1(instr)] & i_imm(instr) as u32;
            })
        );
        register_op!(
            ops,
            riscv::Opcode::Slli,
            (|s, instr| {
                s.pc += 4;
                s.reg[rd(instr)] = s.reg[rs1(instr)].wrapping_shl(shamt(instr));
            })
        );
        register_op!(
            ops,
            riscv::Opcode::Srli,
            (|s, instr| {
                s.pc += 4;
                s.reg[rd(instr)] = s.reg[rs1(instr)].wrapping_shr(shamt(instr));
            })
        );
        register_op!(
            ops,
            riscv::Opcode::Srai,
            (|s, instr| {
                s.pc += 4;
                s.reg[rd(instr)] = (s.reg[rs1(instr)] as i32).wrapping_shr(shamt(instr)) as u32;
            })
        );
        // Register-Register Ops
        register_op!(
            ops,
            riscv::Opcode::Add,
            (|s, instr| {
                s.pc += 4;
                s.reg[rd(instr)] = s.reg[rs1(instr)].wrapping_add(s.reg[rs2(instr)]);
            })
        );
        register_op!(
            ops,
            riscv::Opcode::Sll,
            (|s, instr| {
                s.pc += 4;
                s.reg[rd(instr)] = s.reg[rs1(instr)].wrapping_shl(s.reg[rs2(instr)]);
            })
        );
        register_op!(
            ops,
            riscv::Opcode::Slt,
            (|s, instr| {
                s.pc += 4;
                s.reg[rd(instr)] = if ((s.reg[rs1(instr)] as i32) < (s.reg[rs2(instr)] as i32)) {
                    1
                } else {
                    0
                };
            })
        );
        register_op!(
            ops,
            riscv::Opcode::Sltu,
            (|s, instr| {
                s.pc += 4;
                s.reg[rd(instr)] = if (s.reg[rs1(instr)] < s.reg[rs2(instr)]) {
                    1
                } else {
                    0
                };
            })
        );
        register_op!(
            ops,
            riscv::Opcode::Xor,
            (|s, instr| {
                s.pc += 4;
                s.reg[rd(instr)] = s.reg[rs1(instr)] ^ s.reg[rs2(instr)];
            })
        );
        register_op!(
            ops,
            riscv::Opcode::Or,
            (|s, instr| {
                s.pc += 4;
                s.reg[rd(instr)] = s.reg[rs1(instr)] | s.reg[rs2(instr)];
            })
        );
        register_op!(
            ops,
            riscv::Opcode::And,
            (|s, instr| {
                s.pc += 4;
                s.reg[rd(instr)] = s.reg[rs1(instr)] & s.reg[rs2(instr)];
            })
        );
        register_op!(
            ops,
            riscv::Opcode::Srl,
            (|s, instr| {
                s.pc += 4;
                s.reg[rd(instr)] = s.reg[rs1(instr)].wrapping_shr(s.reg[rs2(instr)]);
            })
        );
        register_op!(
            ops,
            riscv::Opcode::Sra,
            (|s, instr| {
                s.pc += 4;
                s.reg[rd(instr)] =
                    (s.reg[rs1(instr)] as i32).wrapping_shr(s.reg[rs2(instr)]) as u32;
            })
        );
        register_op!(
            ops,
            riscv::Opcode::Sub,
            (|s, instr| {
                s.pc += 4;
                s.reg[rd(instr)] = s.reg[rs1(instr)].wrapping_sub(s.reg[rs2(instr)]);
            })
        );
        // Control Transfer Instructions
        register_op!(
            ops,
            riscv::Opcode::Jal,
            (|s, instr| {
                s.reg[rd(instr)] = s.pc.wrapping_add(4);
                s.pc = s.pc.wrapping_add(j_imm(instr) as u32);
            })
        );
        register_op!(
            ops,
            riscv::Opcode::Jalr,
            (|s, instr| {
                s.reg[rd(instr)] = s.pc.wrapping_add(4);
                s.pc = s.reg[rs1(instr)].wrapping_add(i_imm(instr) as u32);
            })
        );
        register_op!(
            ops,
            riscv::Opcode::Beq,
            (|s, instr| {
                if s.reg[rs1(instr)] == s.reg[rs2(instr)] {
                    s.pc = s.pc.wrapping_add(b_imm(instr) as u32);
                } else {
                    s.pc += 4;
                }
            })
        );
        register_op!(
            ops,
            riscv::Opcode::Bne,
            (|s, instr| {
                if s.reg[rs1(instr)] != s.reg[rs2(instr)] {
                    s.pc = s.pc.wrapping_add(b_imm(instr) as u32);
                } else {
                    s.pc += 4;
                }
            })
        );
        register_op!(
            ops,
            riscv::Opcode::Blt,
            (|s, instr| {
                if (s.reg[rs1(instr)] as i32) < (s.reg[rs2(instr)] as i32) {
                    s.pc = s.pc.wrapping_add(b_imm(instr) as u32);
                } else {
                    s.pc += 4;
                }
            })
        );
        register_op!(
            ops,
            riscv::Opcode::Blt,
            (|s, instr| {
                if (s.reg[rs1(instr)] as i32) >= (s.reg[rs2(instr)] as i32) {
                    s.pc = s.pc.wrapping_add(b_imm(instr) as u32);
                } else {
                    s.pc += 4;
                }
            })
        );
        register_op!(
            ops,
            riscv::Opcode::Bltu,
            (|s, instr| {
                if s.reg[rs1(instr)] < s.reg[rs2(instr)] {
                    s.pc = s.pc.wrapping_add(b_imm(instr) as u32);
                } else {
                    s.pc += 4;
                }
            })
        );
        register_op!(
            ops,
            riscv::Opcode::Bgeu,
            (|s, instr| {
                if s.reg[rs1(instr)] >= s.reg[rs2(instr)] {
                    s.pc = s.pc.wrapping_add(b_imm(instr) as u32);
                } else {
                    s.pc += 4;
                }
            })
        );
        // Load and Stores
        register_op!(
            ops,
            riscv::Opcode::Lw,
            (|s, instr| {
                let addr = s.reg[rs1(instr)].wrapping_add(i_imm(instr) as u32);
                // Catach MMU Errors here.
                s.reg[rd(instr)] = s.mem.read(addr, AccessSize::Word).unwrap() as u32;
                s.pc += 4;
            })
        );
        register_op!(
            ops,
            riscv::Opcode::Lh,
            (|s, instr| {
                let addr = s.reg[rs1(instr)].wrapping_add(i_imm(instr) as u32);
                // Catach MMU Errors here.
                s.reg[rd(instr)] = s.mem.read(addr, AccessSize::Word).unwrap() as u32;
                s.pc += 4;
            })
        );
        register_op!(
            ops,
            riscv::Opcode::Lhu,
            (|s, instr| {
                let addr = s.reg[rs1(instr)].wrapping_add(i_imm(instr) as u32);
                // Catach MMU Errors here.
                let value: u16 = s.mem.read(addr, AccessSize::HalfWord).unwrap() as u16;
                s.reg[rd(instr)] = value as u32;
                s.pc += 4;
            })
        );
        register_op!(
            ops,
            riscv::Opcode::Lb,
            (|s, instr| {
                let addr = s.reg[rs1(instr)].wrapping_add(i_imm(instr) as u32);
                // Catach MMU Errors here.
                let value: i8 = s.mem.read(addr, AccessSize::HalfWord).unwrap() as i8;
                s.reg[rd(instr)] = value as u32;
                s.pc += 4;
            })
        );
        register_op!(
            ops,
            riscv::Opcode::Lbu,
            (|s, instr| {
                let addr = s.reg[rs1(instr)].wrapping_add(i_imm(instr) as u32);
                // Catach MMU Errors here.
                let value: u8 = s.mem.read(addr, AccessSize::HalfWord).unwrap() as u8;
                s.reg[rd(instr)] = value as u32;
                s.pc += 4;
            })
        );
        register_op!(
            ops,
            riscv::Opcode::Sw,
            (|s, instr| {
                let addr = s.reg[rs1(instr)].wrapping_add(s_imm(instr) as u32);
                // Catach MMU Errors here.
                s.mem
                    .write(addr, (s.reg[rs2(instr)] as u32).into(), AccessSize::Word)
                    .unwrap() as u32;
                s.pc += 4;
            })
        );
        register_op!(
            ops,
            riscv::Opcode::Sh,
            (|s, instr| {
                let addr = s.reg[rs1(instr)].wrapping_add(s_imm(instr) as u32);
                // Catach MMU Errors here.
                s.mem
                    .write(
                        addr,
                        (s.reg[rs2(instr)] as u32).into(),
                        AccessSize::HalfWord,
                    )
                    .unwrap() as u32;
                s.pc += 4;
            })
        );
        register_op!(
            ops,
            riscv::Opcode::Sb,
            (|s, instr| {
                let addr = s.reg[rs1(instr)].wrapping_add(s_imm(instr) as u32);
                // Catach MMU Errors here.
                s.mem
                    .write(addr, (s.reg[rs2(instr)] as u32).into(), AccessSize::Byte)
                    .unwrap() as u32;
                s.pc += 4;
            })
        );
        // CSR Instructions
        register_op!(
            ops,
            riscv::Opcode::Csrrw,
            (|s, instr| {
                s.pc += 4;
                let csr = s.csrs.get_mut(&(csr(instr) as u16)).unwrap();
                s.reg[rd(instr)] = *csr;
                *csr = s.reg[rs1(instr)];
            })
        );
        register_op!(
            ops,
            riscv::Opcode::Csrrs,
            (|s, instr| {
                s.pc += 4;
                let csr = s.csrs.get_mut(&(csr(instr) as u16)).unwrap();
                s.reg[rd(instr)] = *csr;
                *csr = *csr | s.reg[rs1(instr)];
            })
        );
        register_op!(
            ops,
            riscv::Opcode::Csrrc,
            (|s, instr| {
                s.pc += 4;
                let csr = s.csrs.get_mut(&(csr(instr) as u16)).unwrap();
                s.reg[rd(instr)] = *csr;
                *csr = *csr & !s.reg[rs1(instr)];
            })
        );
        register_op!(
            ops,
            riscv::Opcode::Csrrwi,
            (|s, instr| {
                s.pc += 4;
                let csr = s.csrs.get_mut(&(csr(instr) as u16)).unwrap();
                s.reg[rd(instr)] = *csr;
                *csr = zimm(instr);
            })
        );
        register_op!(
            ops,
            riscv::Opcode::Csrrsi,
            (|s, instr| {
                s.pc += 4;
                let csr = s.csrs.get_mut(&(csr(instr) as u16)).unwrap();
                s.reg[rd(instr)] = *csr;
                *csr = *csr | zimm(instr);
            })
        );
        register_op!(
            ops,
            riscv::Opcode::Csrrci,
            (|s, instr| {
                s.pc += 4;
                let csr = s.csrs.get_mut(&(csr(instr) as u16)).unwrap();
                s.reg[rd(instr)] = *csr;
                *csr = *csr & !zimm(instr);
            })
        );

        let mut csrs = HashMap::new();
        // Add supported CSRs.
        csrs.insert(0xF14, hartid);

        Snitch {
            state: RISCVState {
                pc: boot_addr,
                reg: [0; 32],
                csrs: csrs,
                mem,
            },
            clock: 0,
            instr,
            ops: ops,
        }
    }

    fn step(&mut self) {
        let pc = self.state.pc;
        let instr_bits: u32 = self.instr.read(pc, AccessSize::Word).unwrap() as u32;

        // Decode
        let mut illegal_instr = true;
        for op in &mut self.ops {
            if op.opcode.value().instr_mask & instr_bits == op.opcode.value().instr_match {
                (op.instr_descr)(&mut self.state, instr_bits);
                debug!(
                    "core {}: 0x{:08x} instr: (0x{:08x}) {} \n{}",
                    *self.state.csrs.get(&0xF14).unwrap(),
                    pc,
                    instr_bits,
                    op.opcode,
                    self.state
                );
                illegal_instr = false;
                break;
            }
        }
        if illegal_instr {
            error!(
                "core {}: Illegal Instruction 0x{:08x} at 0x{:08x}",
                *self.state.csrs.get(&0xF14).unwrap(),
                instr_bits,
                pc
            );
        }
        // Make sure zero reg stays zero.
        self.state.reg[0] = 0;
        self.clock += 1;
    }
}

#[derive(Debug, Clone, Copy)]
/// Supported Access Sizes.
enum AccessSize {
    Byte = 1,
    HalfWord = 2,
    Word = 4,
    DoubleWord = 8,
}
/// Specifies a Read/Write Memory interface.
trait RWMemory {
    fn read(&self, addr: u32, size: AccessSize) -> Result<u64, MemoryError>;
    fn write(&self, addr: u32, datum: u64, size: AccessSize) -> Option<MemoryError>;
}

#[derive(Debug)]
struct SRAM {
    base_address: u32,
    len: u32,
    content: RefCell<Vec<u8>>,
}

#[derive(Debug)]
enum MemoryError {
    NotMapped,
}
/// An SRAM can usually be written and read.
impl RWMemory for SRAM {
    fn read(&self, addr: u32, size: AccessSize) -> Result<u64, MemoryError> {
        // Check wether this is a legal access.
        if addr < self.base_address || addr > self.base_address + self.len {
            return Err(MemoryError::NotMapped);
        }

        // Calculate byte offset in memory.
        let idx = addr - self.base_address;
        let mut res: u64 = 0;
        // Iterate over word offset.
        for i in 0..size as u32 {
            res |= (self.content.borrow()[idx as usize + i as usize] as u64) << (i * 8);
        }
        return Ok(res);
    }

    fn write(&self, addr: u32, datum: u64, size: AccessSize) -> Option<MemoryError> {
        if addr < self.base_address || addr > self.base_address + self.len {
            return Some(MemoryError::NotMapped);
        }
        let idx = addr - self.base_address;
        let mut value = datum.to_be_bytes();
        value.reverse();

        for i in 0..size as u32 {
            self.content.borrow_mut()[idx as usize + i as usize] = value[i as usize];
        }
        return None;
    }
}

impl SRAM {
    fn new(base_address: u32, len: u32, content: Vec<u8>) -> SRAM {
        SRAM {
            base_address,
            len,
            content: RefCell::new(content),
        }
    }
}

/// Simple XBar delegates the corresponding access to the appropriate sub-slave.
struct SimpleXBar<'a> {
    slaves: Vec<&'a mut dyn RWMemory>,
}

impl<'a> SimpleXBar<'a> {
    fn new() -> SimpleXBar<'a> {
        SimpleXBar { slaves: Vec::new() }
    }

    fn add_slave(&mut self, slave: &'a mut dyn RWMemory) {
        self.slaves.push(slave)
    }
}

impl<'a> RWMemory for SimpleXBar<'a> {
    fn read(&self, addr: u32, size: AccessSize) -> Result<u64, MemoryError> {
        // Delegate reads, each slave is responsible for rejecting operations it can't handle.
        for slave in &self.slaves {
            if let Ok(res) = slave.read(addr, size) {
                return Ok(res);
            }
        }
        // In case no slave mapped throw an error.
        return Err(MemoryError::NotMapped);
    }

    fn write(&self, addr: u32, datum: u64, size: AccessSize) -> Option<MemoryError> {
        // Delegate writes, each slave is responsible for rejecting operations it can't handle.
        for slave in &self.slaves {
            if let None = slave.write(addr, datum, size) {
                return None;
            }
        }
        // In case there is no slave mapped throw an error.
        return Some(MemoryError::NotMapped);
    }
}

fn main() -> Result<()> {
    // Parse the command line arguments.
    let matches = app_from_crate!()
        .arg(
            Arg::with_name("binary")
                .help("RISC-V ELF binary to execute")
                .required(true),
        )
        .arg(
            Arg::with_name("dump-llvm")
                .long("dump-llvm")
                .short("d")
                .help("Dump the translated LLVM IR module"),
        )
        .arg(
            Arg::with_name("emit-llvm")
                .long("emit-llvm")
                .short("S")
                .takes_value(true)
                .help("Emit the translated LLVM assembly to a file"),
        )
        .arg(
            Arg::with_name("emit-bitcode")
                .long("emit-bitcode")
                .short("c")
                .takes_value(true)
                .help("Emit the translated LLVM bitcode to a file"),
        )
        .arg(
            Arg::with_name("dry-run")
                .long("dry-run")
                .short("n")
                .help("Translate the binary, but do not execute"),
        )
        .arg(
            Arg::with_name("no-opt-llvm")
                .long("no-opt-llvm")
                .help("Do not optimize LLVM IR"),
        )
        .arg(
            Arg::with_name("no-opt-jit")
                .long("no-opt-jit")
                .help("Do not optimize during JIT compilation"),
        )
        .get_matches();

    // Configure the logger.
    pretty_env_logger::init_custom_env("SNITCH_LOG");

    // Initialize the LLVM core.
    let context = unsafe {
        let pass_reg = LLVMGetGlobalPassRegistry();
        LLVMInitializeCore(pass_reg);
        LLVMLinkInMCJIT();
        LLVM_InitializeNativeTarget();
        LLVM_InitializeNativeAsmPrinter();
        engine::add_llvm_symbols();
        LLVMGetGlobalContext()
    };

    // Setup the execution engine.
    let mut engine = Engine::new(context);
    engine.opt_llvm = !matches.is_present("no-opt-llvm");
    engine.opt_jit = !matches.is_present("no-opt-jit");

    // Read the binary.
    let path = Path::new(matches.value_of("binary").unwrap());
    info!("Loading binary {}", path.display());
    let elf = match elf::File::open_path(&path) {
        Ok(f) => f,
        Err(e) => bail!("Failed to open binary {}: {:?}", path.display(), e),
    };

    // Translate the binary.
    engine
        .translate_elf(&elf)
        .context("Failed to translate ELF binary")?;

    // Write the module to disk if requested.
    if let Some(path) = matches.value_of("emit-llvm") {
        unsafe {
            LLVMPrintModuleToFile(
                engine.module,
                format!("{}\0", path).as_ptr() as *const _,
                null_mut(),
            );
        }
    }
    if let Some(path) = matches.value_of("emit-bitcode") {
        unsafe {
            LLVMWriteBitcodeToFile(engine.module, format!("{}\0", path).as_ptr() as *const _);
        }
    }

    // Dump the module if requested.
    if matches.is_present("dump-llvm") {
        unsafe {
            LLVMDumpModule(engine.module);
        }
    }

    // Execute the binary.
    if !matches.is_present("dry-run") {
        engine.execute().context("Failed to execute ELF binary")?;
    }

    // let ddr_size: usize = 1024 * 1024;
    // let mut ddr_vec = vec![];
    // ddr_vec.resize(ddr_size, 0);
    // let mut ddr = SRAM::new(0x80000000, ddr_size as u32, ddr_vec);

    // // Prepare Main Memory. Filter non-relevant sections from ELF.
    // let prog_sections: Vec<elf::Section> = file
    //     .sections
    //     .into_iter()
    //     .filter(|s| s.shdr.shtype == elf::types::SHT_PROGBITS)
    //     .collect();

    // for s in prog_sections {
    //     let mut i = 0;
    //     for data in s.data {
    //         ddr.write(s.shdr.addr as u32 + i, data as u64, AccessSize::Byte);
    //         i += 1;
    //     }
    // }

    // // let bootrom = SRAM::new(0x80000000 as u32, 128, text_scn.data.clone());
    // // TODO(zarubaf): Implement peripherals.
    // let mut peripherals = SRAM::new(0x40000000 as u32, 1024, vec![0; 1024]);
    // let mut l1 = SRAM::new(0x00000000 as u32, 1024, vec![0; 1024]);

    // let mut xbar = SimpleXBar::new();
    // // xbar.add_slave(&bootrom);
    // xbar.add_slave(&mut ddr);
    // xbar.add_slave(&mut l1);
    // xbar.add_slave(&mut peripherals);

    // // Print instruction memory.
    // // 1. construct system
    // // &xbar
    // let mut snitch = Snitch::new(0x80010000, 10, &xbar, &xbar);

    // for _ in 0..20 {
    //     snitch.step();
    // }
    Ok(())
}
