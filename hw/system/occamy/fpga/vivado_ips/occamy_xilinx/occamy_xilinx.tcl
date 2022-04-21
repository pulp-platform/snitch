# Copyright 2022 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

set top "occamy_xilinx"

set ip_properties [ list \
    vendor "ethz.ch" \
    library "user" \
    name ${ip_name} \
    version "1.0" \
    taxonomy "/UserIP" \
    display_name "Occamy System" \
    description "Occamy System" \
    vendor_display_name "PULP Platform" \
    company_url "https://pulp-platform.org/" \
    ]

set family_lifecycle { \
  aartix7:ALL:Production \
  akintex7:ALL:Production \
  artix7:ALL:Production \
  artix7l:ALL:Production \
  aspartan7:ALL:Production \
  azynq:ALL:Production \
  kintex7:ALL:Production \
  kintex7l:ALL:Production \
  kintexu:ALL:Production \
  kintexuplus:ALL:Production \
  qartix7:ALL:Production \
  qkintex7:ALL:Production \
  qkintex7l:ALL:Production \
  qvirtex7:ALL:Production \
  qzynq:ALL:Production \
  spartan7:ALL:Production \
  versal:ALL:Pre-Production virtex7:ALL:Production \
  virtexu:ALL:Production \
  virtexuplus58g:ALL:Production \
  virtexuplus:ALL:Production \
  virtexuplusHBM:ALL:Production \
  zynq:ALL:Production \
  zynquplus:ALL:Pre-Production \
  zynquplus:ALL:Production \
}


proc modify_ip { } {
    # clock & reset interface
    ipx::infer_bus_interface clk_i xilinx.com:signal:clock_rtl:1.0 [ipx::current_core]
    ipx::infer_bus_interface rst_ni xilinx.com:signal:reset_rtl:1.0 [ipx::current_core]
    set_property value ACTIVE_LOW [ipx::add_bus_parameter POLARITY [ipx::get_bus_interfaces rst_ni]]

    # Associate AXI/AXIS interfaces and reset with clock
    for {set i 0} {$i < 8} {incr i} {ipx::associate_bus_interfaces -busif m_axi_hbm_$i -clock clk_i [ipx::current_core]}

    for {set i 0} {$i < 1} {incr i} {ipx::associate_bus_interfaces -busif m_axi_rmq_${i}_ds -clock clk_i [ipx::current_core]}
    for {set i 0} {$i < 1} {incr i} {ipx::associate_bus_interfaces -busif s_axi_rmq_${i}_us -clock clk_i [ipx::current_core]}

    ipx::associate_bus_interfaces -busif m_axi_pcie -clock clk_i [ipx::current_core]
    ipx::associate_bus_interfaces -busif s_axi_pcie -clock clk_i [ipx::current_core]
}
