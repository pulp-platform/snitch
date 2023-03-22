/* Copyright 2020 ETH Zurich and University of Bologna. */
/* Solderpad Hardware License, Version 0.51, see LICENSE for details. */
/* SPDX-License-Identifier: SHL-0.51 */

/* Defines the L3_ORIGIN variable */
INCLUDE origin.ld
L3_LENGTH = 0x100000000 - L3_ORIGIN;

MEMORY
{
    L3 (rwxa) : ORIGIN = L3_ORIGIN, LENGTH = L3_LENGTH
}
