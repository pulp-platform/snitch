# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Nils Wistoff <nwistoff@iis.ee.ethz.ch>

# Not used anymore
set_property PACKAGE_PIN BJ51 [get_ports clk_100MHz_n]
set_property IOSTANDARD DIFF_SSTL12 [get_ports clk_100MHz_n]
set_property PACKAGE_PIN BH51 [get_ports clk_100MHz_p]
set_property IOSTANDARD DIFF_SSTL12 [get_ports clk_100MHz_p]

set_property PACKAGE_PIN BP26 [get_ports uart_rx_i_0]
set_property IOSTANDARD LVCMOS18 [get_ports uart_rx_i_0]
set_property PACKAGE_PIN BN26 [get_ports uart_tx_o_0]
set_property IOSTANDARD LVCMOS18 [get_ports uart_tx_o_0]

# CPU_RESET pushbutton switch
set_false_path -from [get_port reset] -to [all_registers]
set_property PACKAGE_PIN BM29      [get_ports reset]
set_property IOSTANDARD  LVCMOS12  [get_ports reset]

# Set RTC as false path
set_false_path -to [get_pins occamy_vcu128_i/occamy/inst/i_occamy/i_clint/i_sync_edge/i_sync/reg_q_reg[0]/D]

################################################################################
# JTAG
################################################################################

# CDC 2phase clearable of DM: i_cdc_resp/i_cdc_req
# CONSTRAINT: Requires max_delay of min_period(src_clk_i, dst_clk_i) through the paths async_req, async_ack, async_data.
set_max_delay -through [get_nets -hier -filter {NAME =~ "*i_cdc_resp/async_req*"}] 10
set_max_delay -through [get_nets -hier -filter {NAME =~ "*i_cdc_resp/async_ack*"}] 10
set_max_delay -through [get_nets -hier -filter {NAME =~ "*i_cdc_resp/async_data*"}] 10
set_max_delay -through [get_nets -hier -filter {NAME =~ "*i_cdc_req/async_req*"}] 10
set_max_delay -through [get_nets -hier -filter {NAME =~ "*i_cdc_req/async_ack*"}] 10
set_max_delay -through [get_nets -hier -filter {NAME =~ "*i_cdc_req/async_data*"}] 10

################################################################################
# TIMING GROUPS
################################################################################

# Create timing groups through the FPU to help meet timing

# ingress and egress same for all pipe configs
set _xlnx_shared_i0 [get_pins -of [get_cells -hierarchical -filter {ORIG_REF_NAME == fpnew_sdotp_multi || REF_NAME == fpnew_sdotp_multi}] -filter { DIRECTION == "IN" && NAME !~ *out_ready_i && NAME !~ *rst_ni && NAME !~ *clk_i}]
group_path -default -through $_xlnx_shared_i0
group_path -name {sdotp_ingress} -through $_xlnx_shared_i0
set _xlnx_shared_i1 [get_pins -of [get_cells -hierarchical -filter {ORIG_REF_NAME == fpnew_fma_multi || REF_NAME == fpnew_fma_multi}] -filter { DIRECTION == "IN" && NAME !~ *out_ready_i && NAME !~ *rst_ni && NAME !~ *clk_i}]
group_path -default -through $_xlnx_shared_i1
group_path -name {fma_ingress} -through $_xlnx_shared_i1
set _xlnx_shared_i2 [get_pins -of [get_cells -hierarchical -filter {ORIG_REF_NAME == fpnew_sdotp_multi || REF_NAME == fpnew_sdotp_multi}] -filter { DIRECTION == "OUT" && NAME !~ *in_ready_o}]
group_path -default -through $_xlnx_shared_i2
group_path -name {sdotp_egress} -through $_xlnx_shared_i2
set _xlnx_shared_i3 [get_pins -of [get_cells -hierarchical -filter {ORIG_REF_NAME == fpnew_fma_multi || REF_NAME == fpnew_fma_multi}] -filter { DIRECTION == "OUT" && NAME !~ *in_ready_o}]
group_path -default -through $_xlnx_shared_i3
group_path -name {fma_egress} -through $_xlnx_shared_i3

# For 2 DISTRIBUTED pipe registers, registers are placed on input and mid
# The inside path therefore goes through the registers created in `gen_inside_pipeline[0]`

# The inside path groups
set _xlnx_shared_i4 [get_pins -filter {NAME =~ "*/D"} -of [get_cells -hier -filter { NAME =~  "*gen_inside_pipeline[0]*" && PARENT =~  "*fpnew_sdotp_multi*" }]]
group_path -default -through $_xlnx_shared_i4
group_path -name {sdotp_fu0} -through $_xlnx_shared_i4
set _xlnx_shared_i5 [get_pins -filter {NAME =~ "*/D"} -of [get_cells -hier -filter { NAME =~  "*gen_inside_pipeline[0]*" && PARENT =~  "*fpnew_fma_multi*" }]]
group_path -default -through $_xlnx_shared_i5
group_path -name {fma_fu0} -through $_xlnx_shared_i5

