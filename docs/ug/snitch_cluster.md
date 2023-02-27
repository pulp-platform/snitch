# Snitch Cluster System

The Snitch cluster system (`hw/system/snitch_cluster`) is a fundamental system
around a Snitch core. The cluster can be configured using a config file.

The configuration parameters are documented using JSON schema, and documentation
is generated for the schema. The configuration options can be found [here](../../../schema-doc/snitch_cluster/).

The cluster testbench simulates an infinite memory. The RISC-V ELF file is
preloaded using RISC-V's Front-end Server (`fesvr`).

## Getting Started

In `hw/system/snicht_cluster`:

- Build the software:
    ```
    mkdir sw/build
    cd sw/build
    cmake ..
    make
    ```
- Compile the model for your simulator:

    === "Verilator"

        ```
        make bin/snitch_cluster.vlt
        ```

    === "Questasim"

        ```
        make bin/snitch_cluster.vsim
        ```

    === "VCS"

        ```
        make bin/snitch_cluster.vcs
        ```

- Run a binary on the simulator:

    === "Verilator"

        ```
        bin/snitch_cluster.vlt path/to/riscv/binary
        ```

    === "Questasim"

        ```
        # Headless
        bin/snitch_cluster.vsim path/to/riscv/binary
        # GUI
        bin/snitch_cluster.vsim.gui path/to/riscv/binary
        ```

    === "VCS"

        ```
        bin/snitch_cluster.vcs path/to/riscv/binary
        ```

- Build the traces in .logs/trace_hart_<hart_id>.txt with the help of spike-dasm:
    ```
    make traces
    ```

- Annotate the traces in .logs/trace_hart_<hart_id>.s with the source code related with the retired instructions:
    ```
    make annotate
    ```

- Get an overview of all Makefile targets:
    ```
    make help
    ```

## Configure the Cluster

To configure the cluster with a different configuration, either edit the
configuration files in the `cfg` folder or create a new configuration file and
pass it to the Makefile:

```
make bin/snitch_cluster.vlt CFG=cfg/single-core.hjson
```

The default config is in `cfg/cluster.default.hjson`. Alternatively, you can also
set your `CFG` environment variable, the Makefile will pick it up and override
the standard config.


## Using Verilator with LLVM

LLVM+clang can be used to build the Verilator model. Optionally specify a path
to the LLVM toolchain in `CLANG_PATH` and set `VLT_USE_LLVM=ON`.
For the verilated model itself to be complied with LLVM, verilator must be built
with LLVM (`CC=clang CXX=clang++ ./configure`). The `VLT` environment variable
can then be used to point to the verilator binary.

```bash
# Optional: Specify which llvm to use
export CLANG_PATH=/path/to/llvm-12.0.1
# Optional: Point to a verilator binary compiled with LLVM
export VLT=/path/to/verilator-llvm/bin/verilator
make VLT_USE_LLVM=ON bin/snitch_cluster.vlt
```
