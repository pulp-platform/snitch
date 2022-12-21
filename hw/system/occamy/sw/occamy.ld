/* Copyright 2020 ETH Zurich and University of Bologna. */
/* Solderpad Hardware License, Version 0.51, see LICENSE for details. */
/* SPDX-License-Identifier: SHL-0.51 */

ENTRY(_start)

MEMORY
{
    DRAM (rwxa) : ORIGIN = 0x80000000, LENGTH = 0x80000000
}

SECTIONS
{
  /* Scratch 0 register used for return code */
  __soc_ctrl_scratch0 = 0x02000014;

  /* The program code and data goes into DRAM */
  .appl : {
    __stack_pointer$  = . + 0x70000;
    *(.text.startup)
    *(.text)
    __SDATA_BEGIN__ = .;
    __global_pointer$ = . + 0x7f0;
    *(.sdata)
    *(.srodata.cst16) *(.srodata.cst8) *(.srodata.cst4) *(.srodata.cst2) *(.srodata .srodata.*)
    *(.sdata .sdata.* .gnu.linkonce.s.*)
    *(.data)
    *(.rodata .rodata.*)
  } > DRAM

  .bss (NOLOAD) :
  {
    . = ALIGN(8);
    __bss_start = . ;
    *(.bss .bss.*)
    *(COMMON)
    . = ALIGN(8);
    __bss_end = . ;
  } > DRAM

  /* Discard sections */
  /DISCARD/ : { *(.riscv.attributes) *(.comment) }
}
