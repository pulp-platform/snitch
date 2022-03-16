# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

proc target_01 {} {
  global noc_hw_server
  global noc_target_serial
  global noc_hw_device
  set noc_hw_server bordcomputer:3231
  set noc_target_serial 091847100576A
  set noc_hw_device xcvu37p_0
}

proc noc_connect { } {
    global noc_hw_server
    global noc_target_serial
    global noc_hw_device
    open_hw_manager
    connect_hw_server -url ${noc_hw_server} -allow_non_jtag
    current_hw_target [get_hw_targets */xilinx_tcf/Xilinx/${noc_target_serial}]
    set_property PARAM.FREQUENCY 15000000 [get_hw_targets */xilinx_tcf/Xilinx/${noc_target_serial}]
    open_hw_target
    current_hw_device [get_hw_devices ${noc_hw_device}]
    refresh_hw_device -update_hw_probes false [lindex [get_hw_devices ${noc_hw_device}] 0]
}

proc noc_program_bit {bit ltx} {
    global noc_hw_device
    global bit_stem_ap
    set_property PROBES.FILE "${ltx}" [get_hw_devices ${noc_hw_device}]
    set_property FULL_PROBES.FILE "${ltx}" [get_hw_devices ${noc_hw_device}]
    set_property PROGRAM.FILE "${bit}" [get_hw_devices ${noc_hw_device}]
    program_hw_devices [get_hw_devices ${noc_hw_device}]
    refresh_hw_device [lindex [get_hw_devices ${noc_hw_device}] 0]
}
