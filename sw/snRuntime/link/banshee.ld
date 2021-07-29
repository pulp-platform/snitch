/* Copyright 2020 ETH Zurich and University of Bologna. */
/* Solderpad Hardware License, Version 0.51, see LICENSE for details. */
/* SPDX-License-Identifier: SHL-0.51 */

MEMORY
{
    L1 (rw)          : ORIGIN = 0x00000000, LENGTH = 128K
    DRAM (rwxa)      : ORIGIN = 0x80000000, LENGTH = 256M
}

/* The default mapping to memory */
SECTIONS
{
  .text           : { } >DRAM
  .rodata         : { } >DRAM
  .data           : { } >L1 AT> DRAM
  .sdata          : { } >L1 AT> DRAM
  .sbss           : { } >L1
  .bss            : { } >L1
}
