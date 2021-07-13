# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Nils Wistoff <nwistoff@iis.ee.ethz.ch>

# Parse arguments
if {$argc < 3} {
    error "usage: occamy_vcu_138_flash.tcl FPGA_ID FILE OFFSET"
}
set FPGA_ID [lindex $argv 0]
set FILE   [lindex $argv 1]
set OFFSET [lindex $argv 2]

# Create memory configuration file
write_cfgmem -force -format mcs -size 256 -interface SPIx4 -loaddata "up ${OFFSET} ${FILE}" -file "data.mcs"

# Program memory
open_hw_manager
connect_hw_server -url bordcomputer:3231 -allow_non_jtag

current_hw_target [get_hw_targets */xilinx_tcf/Xilinx/${FPGA_ID}]
set_property PARAM.FREQUENCY 15000000 [get_hw_targets */xilinx_tcf/Xilinx/${FPGA_ID}]
open_hw_target

current_hw_device [get_hw_devices xcvu37p_0]
create_hw_cfgmem -hw_device [get_hw_devices xcvu37p_0] -mem_dev [lindex [get_cfgmem_parts {mt25qu02g-spi-x1_x2_x4}] 0]

set_property PROGRAM.ADDRESS_RANGE  {use_file} [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xcvu37p_0] 0]]
set_property PROGRAM.FILES [list "data.mcs" ] [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xcvu37p_0] 0]]
set_property PROGRAM.PRM_FILE {} [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xcvu37p_0] 0]]
set_property PROGRAM.UNUSED_PIN_TERMINATION {pull-none} [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xcvu37p_0] 0]]
set_property PROGRAM.BLANK_CHECK  0 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xcvu37p_0] 0]]
set_property PROGRAM.ERASE  1 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xcvu37p_0] 0]]
set_property PROGRAM.CFG_PROGRAM  1 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xcvu37p_0] 0]]
set_property PROGRAM.VERIFY  1 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xcvu37p_0] 0]]
set_property PROGRAM.CHECKSUM  0 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xcvu37p_0] 0]]

startgroup
create_hw_bitstream -hw_device [lindex [get_hw_devices xcvu37p_0] 0] [get_property PROGRAM.HW_CFGMEM_BITFILE [ lindex [get_hw_devices xcvu37p_0] 0]]; program_hw_devices [lindex [get_hw_devices xcvu37p_0] 0]; refresh_hw_device [lindex [get_hw_devices xcvu37p_0] 0];
program_hw_cfgmem -hw_cfgmem [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xcvu37p_0] 0]]
endgroup

close_hw_manager
