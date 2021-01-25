/* Copyright 2020 ETH Zurich and University of Bologna. */
/* Licensed under the Apache License, Version 2.0, see LICENSE for details. */
/* SPDX-License-Identifier: Apache-2.0 */

OUTPUT_ARCH( "riscv" )
ENTRY(_start)

SECTIONS
{
  ROM_BASE = 0x80000000; /* ... but actually position independent */
  . = 0x0;
  .l1 : { *(.l1) }
  l1_alloc_base = ALIGN(0x10);
  tcdm_start_address_reg = 0x40000000;
  tcdm_end_address_reg = 0x40000008;
  nr_cores_address_reg = 0x40000010;
  fetch_enable_reg = 0x40000018;
  scratch_reg = 0x40000020;
  wake_up_reg = 0x40000028;
  cycle_count_reg = 0x40000030;
  barrier_reg = 0x40000038;
  cluster_base_hart_id_reg = 0x40000040;
  ssr_config_reg = 0x204800;
  fake_uart = 0xC0000000;
  . = 0xD0000000;
  .eoc_address (NOLOAD): { *(.eoc_address) }
  . = 0x80010000;
  .text : {
    *(.text.init)
    *(.text)
  }
  . = ALIGN(0x10);
  .data : { *(.data)}
  .rodata         : { *(.rodata .rodata.* .gnu.linkonce.r.*) }
  .rodata1        : { *(.rodata1) }
  .sdata2         :
  {
    *(.sdata2 .sdata2.* .gnu.linkonce.s2.*)
  }
  .sdata          :
  {
    __global_pointer$ = . + 0x800;
    *(.srodata.cst16) *(.srodata.cst8) *(.srodata.cst4) *(.srodata.cst2) *(.srodata .srodata.*)
    *(.sdata .sdata.* .gnu.linkonce.s.*)
  }
  . = .;
  __bss_start = .;
  .sbss2          : { *(.sbss2 .sbss2.* .gnu.linkonce.sb2.*) }
  .bss : { *(.bss) }
  __bss_end = .;
}
