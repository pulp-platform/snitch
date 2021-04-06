// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Fabian Schuiki <fschuiki@iis.ee.ethz.ch>
// Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>

#pragma once
#include "sim.hh"

namespace sim {

struct GlobalMemory {
    static constexpr size_t ADDR_SHIFT = 12;
    static constexpr size_t PAGE_SIZE = (size_t)1 << ADDR_SHIFT;

    std::unordered_map<uint64_t, std::unique_ptr<uint8_t[]>> pages;
    std::set<uint64_t> touched;

    // A mapping of host memory into Manticore memory.
    struct Mapping {
        uint64_t base;  // manticore memory
        size_t size;
        uint8_t *into;  // host memory
    };
    std::vector<Mapping> mappings;

    uint8_t *find_mapping(uint64_t addr) const {
        for (const auto &m : mappings) {
            if (m.base <= addr && m.base + m.size > addr) {
                return m.into + (addr - m.base);
            }
        }
        return nullptr;
    }

    // Copy a chunk of data into memory.
    void write(size_t addr, size_t len, const uint8_t *data,
               const uint8_t *strb) {
        // std::cout << "[GlobalMemory] Write " << std::hex << addr << std::dec
        //           << " (" << len << " bytes)\n";
        size_t end = addr + len;
        size_t data_idx = 0;
        while (addr < end) {
            size_t byte_start = addr;
            addr >>= ADDR_SHIFT;
            auto &page = pages[addr];
            uint64_t page_idx = addr;
            if (!page) {
                // std::cout << "[TB] Allocate page " << std::hex << (addr <<
                // ADDR_SHIFT) << "\n";
                page = std::make_unique<uint8_t[]>(PAGE_SIZE);
                std::fill(&page[0], &page[PAGE_SIZE], 0);
            }
            // std::cout << "[TB] Write to page " << std::hex << (addr <<
            // ADDR_SHIFT)
            // << "\n";
            addr += 1;
            addr <<= ADDR_SHIFT;
            size_t byte_end = std::min(addr, end);
            bool any_changed = false;
            for (size_t i = byte_start; i < byte_end; i++, data_idx++) {
                if (!strb || strb[data_idx]) {
                    // std::cout << "[TB] Write byte " << std::hex << i << " = "
                    // << (uint32_t)data[data_idx] << "\n";
                    auto host = find_mapping(i);
                    if (host) {
                        *host = data[data_idx];
                    } else {
                        page[i % PAGE_SIZE] = data[data_idx];
                        any_changed = true;
                    }
                }
            }
            if (any_changed) touched.insert(page_idx);
        }
        std::cout << std::dec;
    }

    // Copy a chunk of data out of the memory.
    void read(size_t addr, size_t len, uint8_t *data) {
        // std::cout << "[GlobalMemory] Read " << std::hex << addr << std::dec
        //           << " (" << len << " bytes)\n";
        size_t end = addr + len;
        size_t data_idx = 0;
        while (addr < end) {
            size_t byte_start = addr;
            addr >>= ADDR_SHIFT;
            auto &page = pages[addr];
            // std::cout << "[TB] Read from page " << std::hex << (addr <<
            // ADDR_SHIFT)
            // << "\n";
            addr += 1;
            addr <<= ADDR_SHIFT;
            size_t byte_end = std::min(addr, end);
            for (size_t i = byte_start; i < byte_end; i++, data_idx++) {
                auto host = find_mapping(i);
                if (host) {
                    data[data_idx] = *host;
                } else {
                    if (page) {
                        // std::cout << "[TB] Read byte " << std::hex << i <<
                        // "\n";
                        data[data_idx] = page[i % PAGE_SIZE];
                    } else {
                        data[data_idx] = 0;
                    }
                }
            }
        }
        std::cout << std::dec;
    }
};

// The global memory all memory ports write into.
extern GlobalMemory MEM;

// The boot data generated along with the system RTL.
struct BootData {
    uint32_t boot_addr;
    uint32_t core_count;
    uint32_t hartid_base;
    uint32_t tcdm_start;
    uint32_t tcdm_end;
};
extern const BootData BOOTDATA;

}  // namespace sim
