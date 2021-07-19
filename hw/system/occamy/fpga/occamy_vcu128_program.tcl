# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

# Parse arguments
if {$argc < 1} {
    error "usage: occamy_vcu_138_program.tcl FPGA_ID"
}
set FPGA_ID [lindex $argv 0]

open_hw_manager
connect_hw_server -url bordcomputer:3231 -allow_non_jtag

current_hw_target [get_hw_targets */xilinx_tcf/Xilinx/${FPGA_ID}]
set_property PARAM.FREQUENCY 15000000 [get_hw_targets */xilinx_tcf/Xilinx/${FPGA_ID}]
open_hw_target

set_property PROGRAM.FILE {occamy_vcu128/occamy_vcu128.runs/impl_1/occamy_vcu128_wrapper.bit} [get_hw_devices xcvu37p_0]

current_hw_device [get_hw_devices xcvu37p_0]
program_hw_devices [get_hw_devices xcvu37p_0]

close_hw_manager
