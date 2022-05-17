riscv-opcodes
===========================================================================

This repo enumerates standard RISC-V instruction opcodes and control and
status registers, as well as some custom modifications.  It also contains a
script to convert them into several formats (C, Python, Go, SystemVerilog, Scala, LaTeX),
starting from their high-level, human-readable description.

## Practical info
- Every output of the parser is generated inside this folder; tools which
  need such automatically generated files must use soft link to point to them.
  For example, supposing `RISCV_ISA_SIM_TOOL` is set to the source code directory of
  the Spike simulator:

  ```bash
  ln -sfr encoding_out.h $RISCV_ISA_SIM_TOOL/encoding.h
  ```

  For example the outputs of `parse-opcodes` can be used in other parts of a project like
  assembler, ISA simulator, riscv-tests, apps runtime or RTL decoder.

- opcodes description files organization matches the same of the official
  repository upstream [riscv-opcodes](https://github.com/riscv/riscv-opcodes),
  with the addition of several custom instruction set extensions: you can
  add your own custom extensions as text file in the root, then create a configuration in
  `config.mk` and subsequently add that variable to the variable `MY_OPCODES` of the `Makefile`
- in the `Makefile`, you can select which opcodes files not to take into account
  for the parsing script execution, basing on the target architecture, by
  listing them in the variable `DISCARDED_OPCODES`;
- opcodes files from the official 128-bit extension have not been introduced
  due to the other changes which they imply to other opcodes specifications;
- some of the instructions originally declared in the vectorial extension
  (`opcodes-rvv` file) have been set as pseudo-instruction due to the overlapping
  of their opcodes space with the opcodes space of the SIMD instructions from
  Xpulpv2, defined in `opcodes-xpulpvect_CUSTOM` and `opcodes-xpulpvectshufflepack_CUSTOM`.


## Smallfloat notice

The Snitch cores use `opcodes-flt-occamy` to decode smallfloat instructions.
`opcodes-sflt` is not used but describes how ariane (CVA6) decodes
instructions. This file is not used but kept in this repository for reference.
Ariane and Snitch do not use the same FPU configuration.


## Overlap notices
There might be some overlap in opcodes between extensions. These are noted as far as known
in the corresponding files. In some cases these overlaps can be avoided by making one of the
opcodes a pseudo-opcodes using `@` in front.
