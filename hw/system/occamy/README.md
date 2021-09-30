# Occamy Manycore System

Based on the Manticore architecture.

## Configuration

The configuration of the current system is described and can be modified in `src/occamy_cfg.hjson`.
For example for prototyping and faster simulation times `nr_clusters` and/or `nr_quadrants` can be lowered.

If you make any changes to `src/occamy_cfg.hjson` run `make all` again to re-generate all the sources.

## Usage

To do elaboration using VCS:

```
make bin/occamy_top.vcs
```

Or Questasim:

```
make bin/occamy_top.vsim
```

## Running
You can run a Snitch binary on the simulator by passing it as a command-line argument
to `bin/occamy_top`, for example:

    bin/occamy_top.vsim sw/build/snRuntime/test-snRuntime-simple

## Traces

Each simulation will generate a unique tracefile for each hart in the system.
The tracefile can be disassembled to instruction mnemonics by using the `traces`
target.

    make traces

A source-code annotated trace can be generated using the `annotate` target

    make annotate

## Software

The runtime and tests can be compiled as follows:

    mkdir sw/build
    cd sw/build
    cmake ..
    make

To have some example binaries to run you can enable tests as follows:

    cmake -DBUILD_TESTS=ON ..

## Notes

All Snitch cores are initially isolated and are not able to fetch instructions from the `bootrom`.
The `cva6` manager core de-isolates the Snitch cores during booting. After that the manager core is trapped in an exception loop.
