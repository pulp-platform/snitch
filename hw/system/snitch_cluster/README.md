# Snitch Cluster

This system provides the minimum necessary logic which is needed around a Snitch
cluster to be executing binaries.

## Usage

Compile the verilator testbench:

    make verilate
    make build

This generates the following files:

- `bin/snitch_cluster`: An executable that runs a RISC-V binary on a Snitch cluster.
- `bin/libsnitch_cluster.a`: A library version that allows other programs to run binaries on the system and interact with the memory.

## Running

You can run a binary on the simulator by passing it as a command line argument to `bin/snitch_cluster`, for example:

    bin/snitch_cluster test/sw/alive
