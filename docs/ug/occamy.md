# Occamy System

## Adapting the FPGA Block Design for the VCU128

With `occamy_vcu128.xpr` open in the Vivado GUI, the block design can be
accessed on the left (`Open Block Design`).

Then, the block design can be viewed and modified. The tcl script for the block
design can then by generated via `File->Export->Export Block Design`. There are
some manual adjustments to this file.

Usually I diff the exported with the original version of `occamy_vcu128_bd.tcl`.
