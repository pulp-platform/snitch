// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

#include <iostream>

#include "sim.hh"
#include "tb_lib.hh"

namespace sim {

// Bootloader
extern "C" {
extern const uint8_t tb_bootrom_start;
extern const uint8_t tb_bootrom_end;
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

    // Write the bootloader into memory.
    size_t bllen = (&tb_bootrom_end - &tb_bootrom_start);
    MEM.write(BOOTDATA.boot_addr, bllen, &tb_bootrom_start, nullptr);
    std::cerr << "Wrote " << bllen << " bytes of bootrom to "
              << BOOTDATA.boot_addr << "\n";

    // Write the entry point of the binary to the last word in the bootloader
    // (which is a placeholder for this data).
    uint32_t e = get_entry_point();
    size_t ep = BOOTDATA.boot_addr + bllen - 4;
    MEM.write(ep, 4, reinterpret_cast<const uint8_t *>(&e), nullptr);
    std::cerr << "Wrote entry point " << e << " to bootloader slot " << ep
              << "\n";

    // Write the boot data to the end of the bootloader. This address will be
    // passed to the binary in register a1.
    size_t bdlen = sizeof(BootData);
    size_t bdp = BOOTDATA.boot_addr + bllen;
    MEM.write(bdp, bdlen, reinterpret_cast<const uint8_t *>(&BOOTDATA),
              nullptr);
    std::cerr << "Wrote " << bdlen << " bytes of bootdata to " << bdp << "\n";
}

void Sim::read_chunk(addr_t taddr, size_t len, void *dst) {
    MEM.read(taddr, len, reinterpret_cast<uint8_t *>(dst));
}

void Sim::write_chunk(addr_t taddr, size_t len, const void *src) {
    uint8_t strb[8] = {1, 1, 1, 1, 1, 1, 1, 1};
    MEM.write(taddr, len, reinterpret_cast<const uint8_t *>(src), strb);
}

}  // namespace sim
