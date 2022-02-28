// Copyright 2021 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

#include <tb_lib.hh>

namespace sim {

const BootData BOOTDATA = {.boot_addr = 0x1000000,
                           .core_count = 9,
                           .hartid_base = 1,
                           .tcdm_start = 0x10000000,
                           .tcdm_size = 0x20000,
                           .tcdm_offset = 0x40000,
                           .global_mem_start = 0x80000000,
                           .global_mem_end = 0x100000000,
                           .cluster_count = 4,
                           .s1_quadrant_count = 6,
                           .clint_base = 0x4000000};

}  // namespace sim
