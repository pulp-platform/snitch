# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Nils Wistoff <nwistoff@iis.ee.ethz.ch>

set_property PACKAGE_PIN BJ51 [get_ports clk_100MHz_n]
set_property IOSTANDARD DIFF_SSTL12 [get_ports clk_100MHz_n]
set_property PACKAGE_PIN BH51 [get_ports clk_100MHz_p]
set_property IOSTANDARD DIFF_SSTL12 [get_ports clk_100MHz_p]

set_property PACKAGE_PIN BK28 [get_ports uart_rx_i_0]
set_property IOSTANDARD LVCMOS18 [get_ports uart_rx_i_0]
set_property PACKAGE_PIN BJ28 [get_ports uart_tx_o_0]
set_property IOSTANDARD LVCMOS18 [get_ports uart_tx_o_0]
