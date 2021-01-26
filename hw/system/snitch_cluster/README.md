# Snitch Cluster

This system provides the minimum necessary logic which is needed around a Snitch
cluster to be executing binaries.

## Usage

Compile the Verilator model:

    make bin/snitch_cluster.vlt

This generates the following files:

- `bin/snitch_cluster.vlt`: An executable that runs a RISC-V binary on a Snitch
  cluster.
- `bin/libsnitch_cluster.a`: A library version that allows other programs to run
  binaries on the system and interact with the memory.

## Running

You can run a binary on the simulator by passing it as a command line argument
to `bin/snitch_cluster`, for example:

    bin/snitch_cluster.vlt sw/alive

## Configure the Cluster

To configure the cluster with a different configuration either edit the the
configuration files in the `cfg` folder or create a new configuration file and
pass it to the Makefile:

```
    make bin/snitch_cluster.vlt CFG=cfg/single-core.hjson
```

The default config is in `cfg/cluster.default.hjson`. Alternatively you can also
set your `CFG` environnement variable, the Makefile will pick it up and override
the standard config.


## Traces

Each simulation will generate a unique tracefile for each hart in the system.
The tracefile can be disassembled to instruction mnemonics by using the `traces`
target.

```
    make traces
```

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

## Software

The runtime and additional software libraries for the cluster configuration can be compiled as follows:

    mkdir sw/build
    cd sw/build
    cmake ..
    make
