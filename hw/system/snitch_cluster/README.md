# Snitch Cluster

This system provides the minimum necessary logic which is needed around a Snitch
cluster to be executing binaries.

## Usage

Compile the Verilator model:

    make bin/snitch_cluster.vlt

This generates the following files:

- `bin/snitch_cluster.vlt`: An executable that runs a RISC-V binary on a Snitch cluster.
- `bin/libsnitch_cluster.a`: A library version that allows other programs to run binaries on the system and interact with the memory.

## Running

You can run a binary on the simulator by passing it as a command line argument to `bin/snitch_cluster`, for example:

    bin/snitch_cluster.vlt sw/alive

## Additional Simulator Support

We also support Questasim and VCS. For VCS execute.

    make bin/snitch_cluster.vcs

or for Questasim:

    make bin/snitch_cluster.vsim


Use the corresponding generated model in the `bin` folder to execute the binary.
For VCS:

    bin/snitch_cluster.vcs path/to/riscv/binary

or for Questasim:

    bin/snitch_cluster.vsim path/to/riscv/binary