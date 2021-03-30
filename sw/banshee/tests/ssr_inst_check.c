// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// Requires LLVM toolchain with support for the Xssr extension

int main() {
    unsigned errs = 0;
    asm volatile(
        // ------------------------------------
        // immediate write and read to ssr0 rep
        // ------------------------------------
        "addi   t0, x0, 12\n"
        "scfgwi t0, 1<<5\n"  // write t0 to location in immediate
        "scfgri t1, 1<<5\n"  // read from immediate location to t1
        // compare
        "beq    t0, t1, 1f\n"
        "addi   %[errs], %[errs], 1\n"  // increment error on mismatch
        "1:\n"

        // ------------------------------------
        // immediate write and read to ssr1 rep
        // ------------------------------------
        "addi   t0, x0, 42\n"
        "scfgwi t0, 1<<5 | 1\n"  // write t0 to location in immediate
        "scfgri t1, 1<<5 | 1\n"  // read from immediate location to t1
        // compare
        "beq    t0, t1, 2f\n"
        "addi   %[errs], %[errs], 1\n"  // increment error on mismatch
        "2:\n"

        // ------------------------------------
        // write and read to ssr0 stride3
        // ------------------------------------
        "li     t0, (0x0 | (9<<5))\n"  // address
        "li     t1, 0x98765432\n"      // data
        "scfgw  t1, t0\n"              // val, adr
        "scfgr  t3, t0\n"              // val, adr
        // compare
        "beq    t1, t3, 3f\n"
        "addi   %[errs], %[errs], 1\n"  // increment error on mismatch
        "3:\n"

        // ------------------------------------
        // write and read to ssr1 stride2
        // ------------------------------------
        "li     t0, (0x1 | 8<<5)\n"  // address
        "li     t1, 0x98765432\n"    // data
        "scfgw  t1, t0\n"            // val, adr
        "scfgr  t3, t0\n"            // val, adr
        // compare
        "beq    t1, t3, 4f\n"
        "addi   %[errs], %[errs], 1\n"  // increment error on mismatch
        "4:\n"

        // ------------------------------------
        // write and read to ssr1 stride2 with reg/imm mixed
        // ------------------------------------
        "li     t0, (0x1 | 8<<5)\n"  // address
        "li     t1, 0x23456789\n"    // data
        "scfgw  t1, t0\n"            // val, adr
        "scfgri t3, (0x1 | 8<<5)\n"  // val, adr
        // compare
        "beq    t1, t3, 5f\n"
        "addi   %[errs], %[errs], 1\n"  // increment error on mismatch
        "5:\n"

        // ------------------------------------
        // write and read to ssr1 stride2 with reg/imm mixed
        // ------------------------------------
        "li     t0, (0x1 | 8<<5)\n"  // address
        "li     t1, 0x42424242\n"    // data
        "scfgwi t1, (0x1 | 8<<5)\n"  // val, adr
        "scfgr  t3, t0\n"            // val, adr
        // compare
        "beq    t1, t3, 6f\n"
        "addi   %[errs], %[errs], 1\n"  // increment error on mismatch
        "6:\n"
        : [ errs ] "+r"(errs)::"t0", "t1", "t2", "t3");
    return errs;
}
