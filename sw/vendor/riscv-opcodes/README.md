riscv-opcodes
===========================================================================

## Smallfloat notice

The Snitch cores use `opcodes-flt-occamy` to decode smallfloat instructions.
`opcodes-sflt` is not used but describes how ariane (CVA6) decodes 
instructions. This file is not used but kept in this repository for reference.
Ariane and Snitch do not use the same FPU configuration.

---

This repo enumerates standard RISC-V instruction opcodes, control and status
registers and PULP specific instruction opcodes. It also contains a script to
convert them into several formats (C, Python, Go, Scala, SystemVerilog LaTeX).
Functions will be instantiated to decode those instructions.
