/* Copyright 2020 ETH Zurich and University of Bologna. */
/* Licensed under the Apache License, Version 2.0, see LICENSE for details. */
/* SPDX-License-Identifier: Apache-2.0 */

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
    ssr_config_reg = 0x204800;
    fake_uart = 0xC0000000;
    . = 0xD0000000;
    .eoc_address (NOLOAD): { *(.eoc_address) }
}
