/* Copyright 2020 ETH Zurich and University of Bologna. */
/* Solderpad Hardware License, Version 0.51, see LICENSE for details. */
/* SPDX-License-Identifier: SHL-0.51 */
ENTRY(_start)
SECTIONS
{
  /* TODO(zarubaf): Auto-generate from description */
  . = 0x1000000;
  .text : { *(.text) }
  .bootdata : { *(.boot_section) }
}
