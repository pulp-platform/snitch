# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Nils Wistoff <nwistoff@iis.ee.ethz.ch>

set_property PACKAGE_PIN BJ51 [get_ports clk_100MHz_n]
set_property IOSTANDARD DIFF_SSTL12 [get_ports clk_100MHz_n]
set_property PACKAGE_PIN BH51 [get_ports clk_100MHz_p]
set_property IOSTANDARD DIFF_SSTL12 [get_ports clk_100MHz_p]

set_property PACKAGE_PIN BP26 [get_ports uart_rx_i_0]
set_property IOSTANDARD LVCMOS18 [get_ports uart_rx_i_0]
set_property PACKAGE_PIN BN26 [get_ports uart_tx_o_0]
set_property IOSTANDARD LVCMOS18 [get_ports uart_tx_o_0]

# Set RTC as false path
set_false_path -to occamy_vcu128_i/occamy_xilinx_0/inst/i_occamy/i_clint/i_sync_edge/i_sync/reg_q_reg[0]/D
