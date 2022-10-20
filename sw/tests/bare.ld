/* Copyright 2020 ETH Zurich and University of Bologna. */
/* Solderpad Hardware License, Version 0.51, see LICENSE for details. */
/* SPDX-License-Identifier: SHL-0.51 */

OUTPUT_ARCH( "riscv" )
ENTRY(_start)

MEMORY
{
    DRAM (rwxa)  : ORIGIN = 0x80000000, LENGTH = 0x80000000
}

SECTIONS
{
  /* The program code and other data goes into DRAM */
  .text :
  {
    . = ALIGN(4);
    _start = .;
    *(.text.init)
    *(.text.startup)
    *(.text)
    *(.text*)
    *(.text)
    . = ALIGN(4);
  } >DRAM

}
