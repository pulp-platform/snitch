// Copyright 2021 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

#include <tb_lib.hh>

namespace sim {

// TODO(zarubaf): Auto-generate
const BootData BOOTDATA = {
    .boot_addr = 0x1000000,
    .core_count = 9,
    .hartid_base = 0,
    .tcdm_start = 0x100000,
    .tcdm_end = 0x120000,
};

}  // namespace sim
