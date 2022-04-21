# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Noah Huetter <huettern@iis.ee.ethz.ch>

# Fix verilog includes: For all IPs in the design look for the generated file "inc_def.tcl"
# which is packed into the IP by `package_ip.tcl`. If it exists, change the fileset to the
# instantiated IP and source the script

if { ! [info exists project]} {
    set project [current_project]
}
if { ! [info exists design_name]} {
    set design_name [current_bd_design]
}
if { ! [info exists build]} {
    set build .
}

set ips [get_ips]
puts "Fixing includes in PROJ $build/$project BD $design_name IPS $ips"

foreach ip [get_ips] {
    set incdef [glob -nocomplain $build/$project.gen/sources_1/bd/$design_name/ip/$ip/inc_def.tcl]
    if {[llength $incdef] == 1} {
        puts "Fixing includes for IP $ip with file [lindex $incdef 0]"
        set fileset $ip
        source [lindex $incdef 0]
    }
}
