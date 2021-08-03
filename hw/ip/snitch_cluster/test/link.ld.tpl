/* Copyright 2020 ETH Zurich and University of Bologna. */
/* Solderpad Hardware License, Version 0.51, see LICENSE for details. */
/* SPDX-License-Identifier: SHL-0.51 */

OUTPUT_ARCH( "riscv" )
ENTRY(_start)
<% dram_address = cfg['dram']['address']; %>
MEMORY
{
    DRAM (rwxai)  : ORIGIN = ${dram_address}, LENGTH = ${cfg['dram']['length']}
    L1 (rw) : ORIGIN = ${l1_region[0]}, LENGTH = ${l1_region[1]}K
}

SECTIONS
{
  . = ${dram_address};
  .text.init : { *(.text.init) }
  . = ALIGN(0x1000);
  .tohost : { *(.tohost) }
  . = ALIGN(0x1000);
  .text : { *(.text) }
  . = ALIGN(0x1000);
  .data : { *(.data) }
  .bss : { *(.bss) }
  _end = .;
}
