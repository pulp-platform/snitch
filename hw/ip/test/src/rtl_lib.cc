// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

#include <svdpi.h>
#include <vpi_user.h>

#include <iostream>
#include <memory>

#include "sim.hh"
#include "tb_lib.hh"

/// DPI Functions.
extern "C" {
/// Tick and check whether `fesvr` communication is necessary.
int fesvr_tick();
void tb_memory_read(long long addr, int len, const svOpenArrayHandle data);
void tb_memory_write(long long addr, int len, const svOpenArrayHandle data,
                     const svOpenArrayHandle strb);
}

namespace sim {
void sim_thread_main(void *arg) { ((Sim *)arg)->main(); }

Sim::Sim(int argc, char **argv) : htif_t(argc, argv) {
    host = context_t::current();
    target.init(sim_thread_main, this);
    target.switch_to();
}

void Sim::idle() { host->switch_to(); }

// A single tick.
int Sim::run() {
    host = context_t::current();
    target.switch_to();
    return (exit_code() << 1 | done());
}

// Host thread.
void Sim::main() {
    htif_t::run();
    // HTIF has finished, just idle now.
    while (true) {
        idle();
    }
}

}  // namespace sim

std::unique_ptr<sim::Sim> s;

int fesvr_tick() {
    // Initialize on first tick.
    if (s == nullptr) {
        bool permissive_on = false;

        s_vpi_vlog_info info;
        if (!vpi_get_vlog_info(&info)) abort();

        std::vector<std::string> htif_args;

        // sanitize arguments
        for (int i = 1; i < info.argc; i++) {
            if (strcmp(info.argv[i], "+permissive") == 0) {
                permissive_on = true;
            }

            // remove any two double pluses at the beginning (those are target
            // arguments)
            if (info.argv[i][0] == '+' && info.argv[i][1] == '+' &&
                strlen(info.argv[i]) > 3) {
                for (int j = 0; j < strlen(info.argv[i]) - 1; j++) {
                    info.argv[i][j] = info.argv[i][j + 2];
                }
            }

            if (!permissive_on) {
                htif_args.push_back(info.argv[i]);
            }

            if (strcmp(info.argv[i], "+permissive-off") == 0) {
                permissive_on = false;
            }
        }

        // convert vector to argc and argv
        int argc = htif_args.size() + 1;
        char *argv[argc];
        argv[0] = (char *)"htif";

        for (unsigned int i = 0; i < htif_args.size(); i++) {
            argv[i + 1] = (char *)htif_args[i].c_str();
        }

        s = std::make_unique<sim::Sim>(argc, (char **)argv);
    }
    return s->run();
}

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
