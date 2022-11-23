# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Nils Wistoff <nwistoff@iis.ee.ethz.ch>

# Parse arguments (Vivado's boolean properties are not compatible with all tcl boolean variables)
set DEBUG false
set EXT_JTAG false

if {$argc > 0 && [lindex $argv 0]} { set DEBUG true }
if {$argc > 1 && [lindex $argv 1]} { set EXT_JTAG true }

# Create project
set project occamy_xilinx

create_project $project ./occamy_xilinx -force -part xcvu37p-fsvh2892-2L-e
set_property XPM_LIBRARIES XPM_MEMORY [current_project]

# Define sources
source define-sources.tcl

# Add constraints
set ooc_constraint_file ooc_synth_constraints.xdc
if {[file exists ${ooc_constraint_file}]} {
    add_files -fileset constrs_1 -norecurse ${ooc_constraint_file}
    set_property USED_IN {synthesis out_of_context} [get_files ${ooc_constraint_file}]
}

# Buggy Vivado doesn't like these files. That's ok, we don't need them anyways.
set_property IS_ENABLED 0 [get_files -regex .*/axi_intf.sv]
set_property IS_ENABLED 0 [get_files -regex .*/reg_intf.sv]

# Package IP
set_property top occamy_xilinx [current_fileset]

update_compile_order -fileset sources_1
synth_design -rtl -name rtl_1

ipx::package_project -root_dir . -vendor ethz.ch -library user -taxonomy /UserIP -set_current true

# Clock interface
ipx::infer_bus_interface clk_i xilinx.com:signal:clock_rtl:1.0 [ipx::current_core]

# Reset interface
ipx::infer_bus_interface rst_ni xilinx.com:signal:reset_rtl:1.0 [ipx::current_core]

# Associate clock to AXI interfaces
for {set i 0} {$i < 8} {incr i} {ipx::associate_bus_interfaces -busif m_axi_hbm_$i -clock clk_i [ipx::current_core]}
ipx::associate_bus_interfaces -busif m_axi_pcie -clock clk_i [ipx::current_core]
ipx::associate_bus_interfaces -busif s_axi_pcie -clock clk_i [ipx::current_core]

# Export
set_property core_revision 1 [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]
ipx::check_integrity [ipx::current_core]
ipx::save_core [ipx::current_core]