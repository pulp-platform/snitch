/* Copyright 2020 ETH Zurich and University of Bologna. */
/* Solderpad Hardware License, Version 0.51, see LICENSE for details. */
/* SPDX-License-Identifier: SHL-0.51 */

OUTPUT_ARCH( "riscv" )
ENTRY(_start)
<% dram_address = cfg['dram']['address']; %>
MEMORY
{
    DRAM (rwxa)  : ORIGIN = ${dram_address}, LENGTH = ${cfg['dram']['length']}
    L1 (rw) : ORIGIN = ${l1_region[0]}, LENGTH = ${l1_region[1]}K
}

SECTIONS
{
  .text           : { } >DRAM
  .rodata         : { } >DRAM
  .data           : { } >L1 AT> DRAM
  .sdata          : { } >L1 AT> DRAM
  .sbss           : { } >L1
  .bss            : { } >L1
}
