// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

#include "sim.hh"

int main(int argc, char **argv, char **env) {
    auto sim = std::make_unique<sim::Sim>(argc, argv);
    return sim->run();
}
