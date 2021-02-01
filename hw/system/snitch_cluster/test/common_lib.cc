// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

#include <iostream>

#include "sim.hh"
#include "tb_lib.hh"

namespace sim {

// The global memory all memory ports write into.
GlobalMemory MEM;

// Override HTIF to populate bootloader with system specification and entry
// symbol.
void Sim::start() {
    htif_t::start();
    std::cerr << "Entry point of binary is at " << get_entry_point() << "\n";
}

void Sim::read_chunk(addr_t taddr, size_t len, void *dst) {
    MEM.read(taddr, len, reinterpret_cast<uint8_t *>(dst));
}

void Sim::write_chunk(addr_t taddr, size_t len, const void *src) {
    uint8_t strb[8] = {1, 1, 1, 1, 1, 1, 1, 1};
    MEM.write(taddr, len, reinterpret_cast<const uint8_t *>(src), strb);
}

}  // namespace sim
