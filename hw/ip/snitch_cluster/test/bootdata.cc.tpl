// Copyright 2021 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

#include "tb_lib.hh"

namespace sim {

const BootData BOOTDATA = {
    .boot_addr = ${hex(cfg['cluster']['boot_addr'])},
};

}  // namespace sim
