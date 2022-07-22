// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

#include <printf.h>

#include "ipc.hh"
#include "sim.hh"

int main(int argc, char **argv, char **env) {
    // Write binary path to logs/binary for the `make annotate` target
    FILE *fd;
    fd = fopen("logs/.rtlbinary", "w");
    if (fd != NULL && argc >= 2) {
        fprintf(fd, "%s\n", argv[1]);
        fclose(fd);
    } else {
        fprintf(stderr,
                "Warning: Failed to write binary name to logs/.rtlbinary\n");
    }

    // Initialize IPC bridge if specified
    IpcIface ipc_iface(argc, argv);

    auto sim = std::make_unique<sim::Sim>(argc, argv);
    return sim->run();
}
