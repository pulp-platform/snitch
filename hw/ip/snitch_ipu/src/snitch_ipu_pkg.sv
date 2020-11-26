// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

package snitch_ipu_pkg;

  // IPU
  typedef enum integer {
    RV32BNone,
    RV32BBalanced,
    RV32BFull
  } rv32b_e;

  typedef enum logic [5:0] {
    // Arithmetics
    ALU_ADD,
    ALU_SUB,

    // Logics
    ALU_XOR,
    ALU_OR,
    ALU_AND,
    // RV32B
    ALU_XNOR,
    ALU_ORN,
    ALU_ANDN,

    // Shifts
    ALU_SRA,
    ALU_SRL,
    ALU_SLL,
    // RV32B
    ALU_SRO,
    ALU_SLO,
    ALU_ROR,
    ALU_ROL,
    ALU_GREV,
    ALU_GORC,
    ALU_SHFL,
    ALU_UNSHFL,

    // Comparisons
    ALU_LT,
    ALU_LTU,
    ALU_GE,
    ALU_GEU,
    ALU_EQ,
    ALU_NE,
    // RV32B
    ALU_MIN,
    ALU_MINU,
    ALU_MAX,
    ALU_MAXU,

    // Pack
    // RV32B
    ALU_PACK,
    ALU_PACKU,
    ALU_PACKH,

    // Sign-Extend
    // RV32B
    ALU_SEXTB,
    ALU_SEXTH,

    // Bitcounting
    // RV32B
    ALU_CLZ,
    ALU_CTZ,
    ALU_PCNT,

    // Set lower than
    ALU_SLT,
    ALU_SLTU,

    // Ternary Bitmanip Operations
    // RV32B
    ALU_CMOV,
    ALU_CMIX,
    ALU_FSL,
    ALU_FSR,

    // Single-Bit Operations
    // RV32B
    ALU_SBSET,
    ALU_SBCLR,
    ALU_SBINV,
    ALU_SBEXT,

    // Bit Extract / Deposit
    // RV32B
    ALU_BEXT,
    ALU_BDEP,

    // Bit Field Place
    // RV32B
    ALU_BFP,

    // Carry-less Multiply
    // RV32B
    ALU_CLMUL,
    ALU_CLMULR,
    ALU_CLMULH,

    // Cyclic Redundancy Check
    ALU_CRC32_B,
    ALU_CRC32C_B,
    ALU_CRC32_H,
    ALU_CRC32C_H,
    ALU_CRC32_W,
    ALU_CRC32C_W
  } alu_op_e;

endpackage
