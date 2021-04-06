// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

#include "Vtestharness.h"
#include "sim.hh"
#include "tb_lib.hh"
#include "verilated.h"
#include "verilated_vcd_c.h"

namespace sim {

// Number of cycles between HTIF checks.
const int HTIFTimeInterval = 200;
void sim_thread_main(void *arg) { ((Sim *)arg)->main(); }

// Sim time.
int TIME = 0;

Sim::Sim(int argc, char **argv) : htif_t(argc, argv) {
    Verilated::commandArgs(argc, argv);
}

void Sim::idle() { target.switch_to(); }

/// Execute the simulation.
int Sim::run() {
    host = context_t::current();
    target.init(sim_thread_main, this);
    return htif_t::run();
}

void Sim::main() {
    // Initialize verilator environment.
    Verilated::traceEverOn(true);
    // Allocate the simulation state and VCD trace.
    auto top = std::make_unique<Vtestharness>();
    auto vcd = std::make_unique<VerilatedVcdC>();

    bool clk_i = 0, rst_ni = 0;

    // Trace 8 levels of hierarchy.
    top->trace(vcd.get(), 8);
    vcd->open("sim.vcd");
    vcd->dump(TIME);
    TIME += 2;

    while (!Verilated::gotFinish()) {
        clk_i = !clk_i;
        rst_ni = TIME >= 8;
        top->clk_i = clk_i;
        top->rst_ni = rst_ni;
        // Evaluate the DUT.
        top->eval();
        vcd->dump(TIME);
        // Increase global time.
        TIME++;
        // Switch to the HTIF interface in regular intervals.
        if (TIME % HTIFTimeInterval == 0) {
            host->switch_to();
        }
    }

    // Clean up.
    vcd->close();
}
}  // namespace sim

// Verilator callback to get the current time.
double sc_time_stamp() { return sim::TIME * 1e-9; }

// DPI calls.
void tb_memory_read(long long addr, int len, const svOpenArrayHandle data) {
    // std::cout << "[TB] Read " << std::hex << addr << std::dec << " (" << len
    //           << " bytes)\n";
    void *data_ptr = svGetArrayPtr(data);
    assert(data_ptr);
    sim::MEM.read(addr, len, (uint8_t *)data_ptr);
}

void tb_memory_write(long long addr, int len, const svOpenArrayHandle data,
                     const svOpenArrayHandle strb) {
    // std::cout << "[TB] Write " << std::hex << addr << std::dec << " (" << len
    //           << " bytes)\n";
    const void *data_ptr = svGetArrayPtr(data);
    const void *strb_ptr = svGetArrayPtr(strb);
    assert(data_ptr);
    assert(strb_ptr);
    sim::MEM.write(addr, len, (const uint8_t *)data_ptr,
                   (const uint8_t *)strb_ptr);
}
