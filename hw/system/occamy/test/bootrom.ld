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
  . = ALIGN(16);
  /DISCARD/ : { *(.riscv.attributes) *(.comment) }
  /* Quadrant Parameters */
  __quad_count      = 8;
  __quad_stride     = 0x80000;
  __quad_int_base   = 0x10040000;
  /* Further addresses */
  __soc_ctrl_scratch0 = 0x02000014;
  __soc_ctrl_bootmode = 0x02000024;
  __soc_ctrl_isolate  = 0x020000a4;
  __clint_mtime       = 0x0400bff8;
  __base_uart_sym     = 0x02002000;
  __base_i2c_sym      = 0x02004000;
  __base_spi_sym      = 0x03000000;
  __base_spm_sym      = ORIGIN(spm);
  __base_hbm_sym      = ORIGIN(hbm);
}
