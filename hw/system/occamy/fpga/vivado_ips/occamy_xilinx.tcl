# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Nils Wistoff <nwistoff@iis.ee.ethz.ch>

# Create project
set project occamy_xilinx

create_project $project ./occamy_xilinx -force -part xcvu37p-fsvh2892-2L-e
set_property XPM_LIBRARIES XPM_MEMORY [current_project]

# Define sources
source define-sources.tcl

# Buggy Vivado doesn't like these files. That's ok, we don't need them anyways.
set_property IS_ENABLED 0 [get_files $ROOT/../../vendor/pulp_platform_axi/src/axi_intf.sv]
set_property IS_ENABLED 0 [get_files $ROOT/../../vendor/pulp_platform_register_interface/src/reg_intf.sv]

# Package IP
set_property top occamy_xilinx [current_fileset]

update_compile_order -fileset sources_1
synth_design -rtl -name rtl_1

ipx::package_project -root_dir . -vendor ethz.ch -library user -taxonomy /UserIP -set_current true

set_property core_revision 1 [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]
