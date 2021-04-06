// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

#pragma once
#include <fesvr/context.h>
#include <fesvr/htif.h>

#include <chrono>
#include <iomanip>
#include <iostream>
#include <memory>
#include <set>
#include <unordered_map>
#include <vector>

namespace sim {
using namespace std::chrono_literals;

// Simulation object with `fesvr` support.
struct Sim : htif_t {
    Sim(int argc, char **argv);

    virtual void start();

    int run();
    void main();

    // HTIF overrides. Calls into the global memory.
    void read_chunk(addr_t taddr, size_t len, void *dst);
    void write_chunk(addr_t taddr, size_t len, const void *src);

    void idle();

    // Force alignment to 8 byte.
    size_t chunk_align() { return 8; }
    // Force chunk size to 8 byte.
    size_t chunk_max_size() { return 8; }

    void reset() {}

   private:
    context_t *host;
    context_t target;
};

void sim_thread_main(void *arg);

}  // namespace sim
