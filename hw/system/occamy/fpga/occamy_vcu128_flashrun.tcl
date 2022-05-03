# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Nils Wistoff <nwistoff@iis.ee.ethz.ch>
# Noah Huetter <huettern@iis.ee.ethz.ch>
# 
# Programs the SPI Flash of the VCU128 board with with two partitions and 
# Afterwards programs the real bitstream and runs the bootrom
# 
# HW_SERVER  host:port URL to the server where the FPGA board is connected to 
# FPGA_ID    Serial of the FPGA to target
# MCS        Output flash configuration file
# OFFSET0    Address offset of partition 0
# FILE0      File to program to partition 0

source occamy_vcu128_procs.tcl

# Parse arguments
if {$argc < 5} {
    error "usage: occamy_vcu_138_flash.tcl HW_SERVER FPGA_ID MCS OFFSET0 FILE0"
}
set HW_SERVER [lindex $argv 0]
set FPGA_ID   [lindex $argv 1]
set MCS       [lindex $argv 2]
set OFFSET0   [lindex $argv 3]
set FILE0     [lindex $argv 4]

set mcs_file $MCS

# Create flash configuration file
write_cfgmem -force -format mcs -size 256 -interface SPIx4 \
  -loaddata "up $OFFSET0 $FILE0" \
  -checksum \
  -file $mcs_file

# Open and connect HW manager
open_hw_manager
connect_hw_server -url ${HW_SERVER} -allow_non_jtag
current_hw_target [get_hw_targets */xilinx_tcf/Xilinx/${FPGA_ID}]
set_property PARAM.FREQUENCY 15000000 [get_hw_targets */xilinx_tcf/Xilinx/${FPGA_ID}]
open_hw_target
current_hw_device [get_hw_devices xcvu37p_0]

# Add the SPI flash as configuration memory
set hw_device [get_hw_devices xcvu37p_0]
create_hw_cfgmem -hw_device $hw_device [lindex [get_cfgmem_parts {mt25qu02g-spi-x1_x2_x4}] 0]
set hw_cfgmem [get_property PROGRAM.HW_CFGMEM $hw_device]
set_property PROGRAM.ADDRESS_RANGE  {use_file} $hw_cfgmem
set_property PROGRAM.FILES [list $mcs_file ] $hw_cfgmem
set_property PROGRAM.PRM_FILE {} $hw_cfgmem
set_property PROGRAM.UNUSED_PIN_TERMINATION {pull-none} $hw_cfgmem
set_property PROGRAM.BLANK_CHECK  0 $hw_cfgmem
set_property PROGRAM.ERASE  1 $hw_cfgmem
set_property PROGRAM.CFG_PROGRAM  1 $hw_cfgmem
set_property PROGRAM.VERIFY  1 $hw_cfgmem
set_property PROGRAM.CHECKSUM  0 $hw_cfgmem

# Create bitstream to access SPI flash
create_hw_bitstream -hw_device $hw_device [get_property PROGRAM.HW_CFGMEM_BITFILE $hw_device]; 
program_hw_devices $hw_device; 
refresh_hw_device $hw_device;

# Program SPI flash
program_hw_cfgmem -hw_cfgmem $hw_cfgmem

# Program BIT
global occ_hw_server
global occ_target_serial
global occ_hw_device
global occ_bit_stem
set occ_hw_server $HW_SERVER
set occ_target_serial $FPGA_ID
set occ_hw_device xcvu37p_0
set occ_bit_stem occamy_vcu128/occamy_vcu128.runs/impl_1/occamy_vcu128_wrapper

occ_program_bit

# Write bootrom
if [file exists bootrom/bootrom-spl.tcl] {
  occ_flash_bootrom_spl
} else {
  puts "Not writing bootrom. File does not exist."
}

# Close connection
close_hw_manager
