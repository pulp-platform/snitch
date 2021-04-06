// Copyright 2021 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

#include <tb_lib.hh>

namespace sim {

const BootData BOOTDATA = {
    .boot_addr = ${hex(cfg['cluster']['boot_addr'])},
    .core_count = ${cfg['cluster']['nr_cores']},
    .hartid_base = ${cfg['cluster']['hart_base_id']},
    .tcdm_start = ${hex(cfg['cluster']['cluster_base_addr'])},
    .tcdm_end = ${hex(cfg['cluster']['cluster_base_addr'] +
                      cfg['cluster']['tcdm']['size'] * 1024)},
};

}  // namespace sim
