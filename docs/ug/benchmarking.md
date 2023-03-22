# Benchmarking

## Choosing the right platform

To start developing and benchmarking applications on Snitch, we advise to start developing on `banshee` and in a later step benchmark them on the RTL for cycle-accurate results. `banshee` is a good starting point to functionaly verify your application and to get a first impression of the performance. `banshee` can generate traces for you which allows to already have a rough estimate of the FPU utilization for instance. However, `banshee` does not model delays for instructions and memory accesses. Therefore, the cycle-accurate results are only possible with RTL simulations or on the FPGA.

## Generating traces

To generate traces, `spike-dasm` must be installed and available in the `PATH`. Using the source from this repository supports disassembly of Snitch-custom instructions. We refer to the [Quick Start](./getting_started.md#Quick-Start) to install `spike-dasm`.

traces are automatically generated if you run the simulation when running the following target for RTL simulations from the `build` folder:

```bash
make run-rtl-my_binary
```

respectively for `banshee`:

```bash
make run-banshee-my_binary
```

Alternatively you can also generate traces for the RTL by running the following target in the `hw/system/my_platform` folder:

```bash
make traces
```

## RTL Traces

The traces will be stored in the `logs` folder. The traces are generated for each core. The trace for core 0 is stored in `trace_hart_00000000.txt`. The trace for core 1 is stored in `trace_hart_00000001.txt` and so on. A trace file contains a summary of few statistics for the specific core that is appended at the end of the trace file. The following example shows such a summary:

```
## Performance metrics

Performance metrics for section 0 @ (11, 3459):
snitch_loads                                    89
snitch_stores                                   89
fpss_loads                                       0
snitch_avg_load_latency                    22.9888
snitch_occupancy                            0.1334
snitch_fseq_rel_offloads                    0.0650
fseq_yield                                     1.0
fseq_fpu_yield                                 1.0
fpss_section_latency                             0
fpss_avg_fpu_latency                           1.0
fpss_avg_load_latency                            0
fpss_occupancy                              0.0093
fpss_fpu_occupancy                          0.0093
fpss_fpu_rel_occupancy                         1.0
cycles                                        3449
total_ipc                                   0.1427
```

The trace script also allows to split the execution into multiple sections. The sections are defined by reading from the `mcycle` CSR register. This register will return the current cycle count, but also serves as a trigger for the trace script, to start a new section. The following example shows how to split the execution into two sections:

```c
#include "sw/vendor/riscv-opcodes/encoding.h"
size_t benchmark_get_cycle() { return read_csr(mcycle); }

// End of section 0, Start of section 1
benchmark_get_cycle();

// Execute kernel to be benchmarked
my_kernel();

// End of section 1, Start of section 2
benchmark_get_cycle();
```
