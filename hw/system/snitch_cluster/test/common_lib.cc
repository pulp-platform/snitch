// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

#include <iostream>

#include "sim.hh"
#include "tb_lib.hh"

namespace sim {

// Bootloader
extern "C" {
    extern const char tb_bootrom_start;
    extern const char tb_bootrom_end;
}

asm(".global tb_bootrom_start \n"
    ".global tb_bootrom_end \n"
    "tb_bootrom_start: .incbin \"test/bootrom.bin\" \n"
    "tb_bootrom_end: \n");

// The global memory all memory ports write into.
GlobalMemory MEM;

// Override HTIF to populate bootloader with system specification and entry
// symbol.
void Sim::start() {
    htif_t::start();
    auto f = std::cerr.flags();
    std::cerr << std::hex;
    std::cerr << "Entry point of binary is at " << get_entry_point() << "\n";
    std::cerr << "Bootrom start at " << (const void *)&tb_bootrom_start << "\n";
    std::cerr << "Bootrom end at " << (const void *)&tb_bootrom_end << "\n";
    std::cerr.flags(f);
}

void Sim::read_chunk(addr_t taddr, size_t len, void *dst) {
    MEM.read(taddr, len, reinterpret_cast<uint8_t *>(dst));
}

void Sim::write_chunk(addr_t taddr, size_t len, const void *src) {
    uint8_t strb[8] = {1, 1, 1, 1, 1, 1, 1, 1};
    MEM.write(taddr, len, reinterpret_cast<const uint8_t *>(src), strb);
}

}  // namespace sim
