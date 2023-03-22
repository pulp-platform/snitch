/* Copyright 2020 ETH Zurich and University of Bologna. */
/* Solderpad Hardware License, Version 0.51, see LICENSE for details. */
/* SPDX-License-Identifier: SHL-0.51 */
ENTRY(_start)

MEMORY
{
  bootrom (rx)  : ORIGIN = 0x01000000, LENGTH = 16K
  spm (rwx)     : ORIGIN = 0x70000000, LENGTH = 128K
  hbm (rwx)     : ORIGIN = 0x80000000, LENGTH = 2048M
}

SECTIONS
{
  .text : { *(.text._start) *(.text) *(.text.*) } > bootrom
  .misc ALIGN(16): { *(.data) *(.sdata) *(.*) } > bootrom
  /* common_lib.cc expects entry address and device tree placeholders at end of binary */
  .end ALIGN(16): { *(end) } > bootrom

  /DISCARD/ : { *(.riscv.attributes) *(.comment) }
  /* Global and stack pointer */
  __global_pointer$ = ADDR(.misc) + SIZEOF(.misc) / 2;
  __stack_pointer$  = ORIGIN(spm) + LENGTH(spm) - 8;
  /* Quadrant Parameters */
  __quad_stride     = 0x10000;
  __quad_int_base   = 0x0b000000;
  /* Further addresses */
  __soc_ctrl_scratch0 = 0x02000014;
  __soc_ctrl_scratch1 = 0x02000018;
  __soc_ctrl_bootmode = 0x02000024;
  __soc_ctrl_nr_quads = 0x02000028;
  __clint_mtime       = 0x0400bff8;
  __base_uart_sym     = 0x02002000;
  __base_i2c_sym      = 0x02004000;
  __base_spi_sym      = 0x03000000;
  __base_spm_sym      = ORIGIN(spm);
  __base_hbm_sym      = ORIGIN(hbm);
}
