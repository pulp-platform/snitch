/* Copyright 2020 ETH Zurich and University of Bologna. */
/* Solderpad Hardware License, Version 0.51, see LICENSE for details. */
/* SPDX-License-Identifier: SHL-0.51 */
ENTRY(_start)
SECTIONS
{
  /* TODO(zarubaf): Auto-generate from description */
  . = 0x1000000;
  .text : { 
    *(.entry)
    *(.rodata)
    
    . = ALIGN(4);
    __spl_start = .;
    *(.spl)
    __spl_end = .;
  }
  __soc_ctrl_scratch0 = 0x02000014;
  __soc_ctrl_scratch1 = 0x02000018;
}
