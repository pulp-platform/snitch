# Snitch Cluster

This system provides the minimum necessary logic which is needed around a Snitch
cluster to be executing binaries. Further documentation can be found
[here](https://pulp-platform.github.io/snitch/ug/snitch_cluster/).

## Usage

Compile the Verilator model:

    make bin/snitch_cluster.vlt

This generates the following files:

- `bin/snitch_cluster.vlt`: An executable that runs a RISC-V binary on a Snitch
  cluster.
- `bin/libsnitch_cluster.a`: A library version that allows other programs to run
  binaries on the system and interact with the memory.

## Running

You can run a binary on the simulator by passing it as a command-line argument
to `bin/snitch_cluster`, for example:

    bin/snitch_cluster.vlt sw/alive

Questasim simulation can be run in GUI mode with Wave-Format scripts in `wave/*.do`

    bin/snitch_cluster.vsim.gui sw/alive
    VSIM> do wave/all_cores.do

## Traces

Each simulation will generate a unique tracefile for each hart in the system.
The tracefile can be disassembled to instruction mnemonics by using the `traces`
target.

    make traces

A source-code annotated trace can be generated using the `annotate` target

    make annotate

## Software

The runtime and additional software libraries for the cluster configuration can be compiled as follows:

    mkdir sw/build
    cd sw/build
    cmake ..
    make

If you have compiled the Verilator model as described above, you can run the unit tests on your system as follows:

    make test
