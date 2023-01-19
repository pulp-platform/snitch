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

## Software

The runtime and tests can be compiled as follows:

    make DEBUG=ON update-sw

The `DEBUG` flag is used to include debugging symbols in the binaries, and can be omitted if this is not required.
It is required if you later want to annotate the traces.

## Running

You can run a Snitch binary on the simulator by passing it as a command-line argument
to `bin/occamy_top`, for example:

    bin/occamy_top.vsim sw/build/<some test>

## Traces

Each simulation will generate a unique trace file for each hart in the system.
The trace file can be disassembled to instruction mnemonics by using the `traces`
target.

    make traces

In addition to generating readable traces, the above command also dumps several
performance metrics to file for each hart. These can be collected into a single CSV file
with the following target:

    make perf-csv

Among these performance metrics are start and end times of particular regions marked
in the traces (via mcycle CSR reads). It can sometimes be useful to visualize
these regions in a timeline. You can use the `util/trace/eventvis.py` tool to generate a
JSON file starting from a CSV file (similar to the output of the previous command)
which can be visualized in a Chrome browser at `chrome://tracing`.
A detailed description of the expected CSV file format can be found in the tool's source code.

A source-code annotated trace can be generated using the `annotate` target. The Snitch binary with the debugging
symbols should be passed to the target:

    make BINARY=sw/build/sn_<some test>.elf annotate

## Notes

All Snitch cores are initially isolated and are not able to fetch instructions from the `bootrom`.
The `cva6` manager core de-isolates the Snitch cores during booting. After that the manager core is trapped in an exception loop.
