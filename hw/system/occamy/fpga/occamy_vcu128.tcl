# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Nils Wistoff <nwistoff@iis.ee.ethz.ch>

# Parse arguments
set DEBUG false
if {$argc > 0} {
    # Vivado's boolean properties are not compatible with all tcl boolean variables.
    if {[lindex $argv 0]} {
        set DEBUG true
    }
}

# Create project
set project occamy_vcu128

create_project $project ./$project -force -part xcvu37p-fsvh2892-2L-e
set_property board_part xilinx.com:vcu128:part0:1.0 [current_project]
set_property XPM_LIBRARIES XPM_MEMORY [current_project]

set_property ip_repo_paths ./vivado_ips [current_project]
update_ip_catalog

# Create block design
source occamy_vcu128_bd.tcl

# Add constraint files
add_files -fileset constrs_1 -norecurse occamy_vcu128_impl.xdc
import_files -fileset constrs_1 occamy_vcu128_impl.xdc
set_property used_in_synthesis false [get_files occamy_vcu128/occamy_vcu128.srcs/constrs_1/imports/fpga/occamy_vcu128_impl.xdc]

# Generate wrapper
make_wrapper -files [get_files ./occamy_vcu128/occamy_vcu128.srcs/sources_1/bd/occamy_vcu128/occamy_vcu128.bd] -top
add_files -norecurse ./occamy_vcu128/occamy_vcu128.gen/sources_1/bd/occamy_vcu128/hdl/occamy_vcu128_wrapper.v
update_compile_order -fileset sources_1

# Create runs
generate_target all [get_files ./occamy_vcu128/occamy_vcu128.srcs/sources_1/bd/occamy_vcu128/occamy_vcu128.bd]
export_ip_user_files -of_objects [get_files ./occamy_vcu128/occamy_vcu128.srcs/sources_1/bd/occamy_vcu128/occamy_vcu128.bd] -no_script -sync -force -quiet
create_ip_run [get_files -of_objects [get_fileset sources_1] ./occamy_vcu128/occamy_vcu128.srcs/sources_1/bd/occamy_vcu128/occamy_vcu128.bd]

# Re-add occamy includes
export_ip_user_files -of_objects [get_ips occamy_vcu128_occamy_xilinx_0_0] -no_script -sync -force -quiet
eval [exec sed {s/current_fileset/get_filesets occamy_vcu128_occamy_xilinx_0_0/} define_defines_includes_no_simset.tcl]

# Debug settings
if {$DEBUG} {
    add_files -fileset constrs_1 occamy_vcu128_debug.xdc
    set_property target_constrs_file occamy_vcu128_debug.xdc [current_fileset -constrset]
}

# Do NOT insert BUFGs on high-fanout nets (e.g. reset). This will backfire during placement.
set_param logicopt.enableBUFGinsertHFN no

# Synthesize
foreach run [list synth_1 occamy_vcu128_occamy_xilinx_0_0_synth_1] {
 set_property strategy Flow_AlternateRoutability [get_runs $run]
 set_property STEPS.SYNTH_DESIGN.ARGS.RETIMING true [get_runs $run]
}
launch_runs synth_1 -jobs 12
wait_on_run synth_1

# Implement
set_property strategy Congestion_SpreadLogic_low [get_runs impl_1]
launch_runs impl_1 -jobs 12
wait_on_run impl_1

# Generate Bitstream
launch_runs impl_1 -to_step write_bitstream -jobs 12
wait_on_run impl_1
