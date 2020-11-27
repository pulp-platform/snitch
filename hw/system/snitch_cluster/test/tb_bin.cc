// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

#include "snitch_cluster.hh"

int main(int argc, char **argv, char **env) {
    auto sim = std::make_unique<snitch_cluster::Sim>(argc, argv);
    return sim->run();
}
