# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Noah Huetter <huettern@iis.ee.ethz.ch>
#
# Create and package a Vivado IP core to use in a block-design.
# Reads ${ip_name}/${ip_name}.tcl to read metadata and call modify_ip after createion
#
# Argunents: ip_name build_dir

# Arguments
set ip_name [lindex $argv 0]
set build [lindex $argv 1]

# Settings
set proj_dir ${build}/proj_${ip_name}
set ip_dir ${build}/${ip_name}

puts "Build: ${build}"
puts "IP: ${ip_name}"

# Source metadata
source ${ip_name}/${ip_name}.tcl

# Create project
create_project -name ${ip_name} -force -dir ${proj_dir}
set_property XPM_LIBRARIES XPM_MEMORY [current_project]

# Disable automatic top module switching if main module cannot be verified
# set_property source_mgmt_mode None [current_project]

# Read sources
source ${build}/${ip_name}/sources.tcl

# Add constraints
set ooc_constraint_file ${ip_name}/ooc_synth_constraints.xdc
if {[file exists ${ooc_constraint_file}]} {
    add_files -fileset constrs_1 -norecurse ${ooc_constraint_file}
    set_property USED_IN {synthesis out_of_context} [get_files ${ooc_constraint_file}]
}

# disable interface sources
set inf_files [lsearch -all -inline [get_files] *intf.sv]
if { 0 != [llength $inf_files] } {
    set_property IS_ENABLED 0 $inf_files
}

# run elaboration
set_property top ${top} [current_fileset]
update_compile_order -fileset sources_1
synth_design -rtl -name rtl_1

####################
# Package project
####################
# -import_files copies the source files but doesn't work for duplicate file names
ipx::package_project -root_dir ${ip_dir} -set_current true
set ip_core [ipx::current_core]

# Set properties
set_property -dict ${ip_properties} ${ip_core}
set_property SUPPORTED_FAMILIES ${family_lifecycle} ${ip_core}

# Add logo
set logo ${ip_name}/logo.png
if { [file exists $logo] == 1} {
    puts "Adding logo"
    file copy -force $logo ${ip_dir}/logo.png
    ipx::add_file_group -type utility {} [ipx::current_core]
    ipx::add_file logo.png [ipx::get_file_groups xilinx_utilityxitfiles -of_objects [ipx::current_core]]
    set_property type LOGO [ipx::get_files logo.png -of_objects [ipx::get_file_groups xilinx_utilityxitfiles -of_objects [ipx::current_core]]]
}

# Add include file
# ipx::add_file_group -type utility bender_include [ipx::current_core]
# ipx::add_file inc_def.tcl [ipx::get_file_groups xilinx_utilityxitfiles -of_objects [ipx::current_core]]
exec sed -i {s/current_fileset/get_filesets \$fileset/} ${ip_dir}/inc_def.tcl
ipx::add_file_group -type synthesis {} [ipx::current_core]
ipx::add_file inc_def.tcl [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]
set_property type tclSource [ipx::get_files inc_def.tcl -of_objects [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]]

# Associate interfaces etc.
modify_ip

# Save IP and close project
set_property core_revision 1 [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::check_integrity ${ip_core}
ipx::save_core ${ip_core}
close_project
file delete -force ${proj_dir}
