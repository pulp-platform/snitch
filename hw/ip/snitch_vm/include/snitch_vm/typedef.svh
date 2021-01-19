// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>

`ifndef SNITCH_VM_TYPEDEF_SVH_
`define SNITCH_VM_TYPEDEF_SVH_

  `define SNITCH_VM_TYPEDEF(__plen)                                                       \
    typedef struct packed {                                                               \
      logic [``__plen``-1:snitch_pkg::PAGE_SHIFT+snitch_pkg::VPN_SIZE] ppn1;              \
      logic [snitch_pkg::PAGE_SHIFT+snitch_pkg::VPN_SIZE-1:snitch_pkg::PAGE_SHIFT] ppn0;  \
    } pa_t;                                                                               \
                                                                                          \
    typedef struct packed {                                                               \
      pa_t                     pa;                                                        \
      snitch_pkg::pte_flags_t  flags;                                                     \
    } l0_pte_t;                                                                           \
                                                                                          \
    typedef struct packed {                                                               \
      pa_t        pa;                                                                     \
      logic [9:8] rsw;                                                                    \
      logic       d;                                                                      \
      logic       a;                                                                      \
      logic       g;                                                                      \
      logic       u;                                                                      \
      logic       x;                                                                      \
      logic       w;                                                                      \
      logic       r;                                                                      \
      logic       v;                                                                      \
    } pte_sv32_t;

`endif
