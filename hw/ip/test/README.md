# Testbench

This directory contains generic testbench components. The base abstraction of
this testbench is multiple AXI interfaces and an infinite simulation memory.

Furthermore it allows to link a system specific `bootrom`.

The testbench mimics the behavior of an infinite memory. The `tb_memory_*`
module turn read and write transactions into DPI calls into the simulation
memory (`GlobalMemory` in `tb_lib.hh`).

The testbench can interface directly with the global memory or the RISC-V
front-end server (`fesvr`) can interact with the DUT through memory map
operations. This allows the software on the DUT to make proxied system calls.
