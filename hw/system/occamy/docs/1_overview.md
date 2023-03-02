# Occamy Overview

Occamy is the chiplet of a 2.5D integrated dual-chiplet system with 8GB private high-bandwidth memory (HBM) per chiplet.
The scalable architecture, designed to operate at 1GHz, is organized around an extremely efficient integer RISC-V core coupled with a powerful FPU with SIMD, Minifloat (8-bit, 16-bit) and fused sum-dot-product capabilities.
Thanks to two custom ISA extensions the RISC-V core can keep FPU utilization above 90% for ultra-efficient computation of data-parallel floating-point workloads.
Each chiplet contains more than 200 such cores organized in groups of four compute clusters.
Each cluster shares a tightly-coupled memory among eight compute cores and a dedicated DMA core orchestrating the flow of data.
All clusters and system peripherals are managed by a linux-capable RISC-V core.

The main architecture is developed in the open and is available on Github: https://github.com/pulp-platform/snitch/tree/occamy-tapeout

The following tag was used for the tapeout: https://github.com/pulp-platform/snitch/tree/occamy-tapeout


## Features

- GF12LP+ technology
- 73 :math:`mm^2` die area
- 6 Groups: 216 32-bit RISC-V Snitch cores
  - 4 cluster per group
  - 8 compute cores per cluster
  - 1 DMA core per cluster
- Linux-capable 64-bit manager core CVA6
- two AXI interconnet subsytems: 64-bit and 512-bit
- 6x2 FLLs
  - GF's Digital Frequency Generator (DFG)
  - ETH FL
- Peripherals:
  - JTAG
  - SPI
  - I2C
  - UART
  - Serial Link
  - Timer
- 8GB HBM2e memory
- Custom Die-to-Die IP:
  - source synchronous
  - Bunch-of-Wires (BoW)
  - DDR
  - Low speed: <125 MHz
  - Low bandwidth: <128 Gb/s Dubplex
