# Copyright 2021 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

# Testbench
add wave -group "snitch_read_only_cache_tb" snitch_read_only_cache_tb/*
# DUT
add wave -group "dut" -group "parameter" -radix decimal snitch_read_only_cache_tb/dut/LineWidth \
                                                        snitch_read_only_cache_tb/dut/LineCount \
                                                        snitch_read_only_cache_tb/dut/SetCount \
                                                        snitch_read_only_cache_tb/dut/AxiAddrWidth \
                                                        snitch_read_only_cache_tb/dut/AxiDataWidth \
                                                        snitch_read_only_cache_tb/dut/AxiIdWidth \
                                                        snitch_read_only_cache_tb/dut/AxiUserWidth \
                                                        snitch_read_only_cache_tb/dut/MaxTrans \
                                                        snitch_read_only_cache_tb/dut/NrAddrRules \
                                                        snitch_read_only_cache_tb/dut/PendingCount \
                                                        snitch_read_only_cache_tb/dut/CFG

add wave -group "dut" -ports -color "Yellow Green" snitch_read_only_cache_tb/dut/*
add wave -group "dut" -divider -height 8 internal
add wave -group "dut" -internal snitch_read_only_cache_tb/dut/*



# Cache modules: axi_to_cache
add wave -group "axi2cache" -ports -color "Yellow Green" snitch_read_only_cache_tb/dut/i_axi_to_cache/clk* \
                                                         snitch_read_only_cache_tb/dut/i_axi_to_cache/rst*
add wave -group "axi2cache" -divider -height 8 axi
add wave -group "axi2cache" -ports                       snitch_read_only_cache_tb/dut/i_axi_to_cache/slv_*
add wave -group "axi2cache" -divider -height 8 req
add wave -group "axi2cache" -ports                       snitch_read_only_cache_tb/dut/i_axi_to_cache/req_*
add wave -group "axi2cache" -divider -height 8 rsp
add wave -group "axi2cache" -ports                       snitch_read_only_cache_tb/dut/i_axi_to_cache/rsp_*
add wave -group "axi2cache" -divider -height 8 internal
add wave -group "axi2cache" -internal                    snitch_read_only_cache_tb/dut/i_axi_to_cache/*

# Cache modules: axi_burst_splitter_table
add wave -group "table" -ports -color "Yellow Green" snitch_read_only_cache_tb/dut/i_axi_to_cache/i_axi_burst_splitter_table/clk* \
                                                     snitch_read_only_cache_tb/dut/i_axi_to_cache/i_axi_burst_splitter_table/rst*
add wave -group "table" -divider -height 8 alloc
add wave -group "table" -ports                       snitch_read_only_cache_tb/dut/i_axi_to_cache/i_axi_burst_splitter_table/alloc_*
add wave -group "table" -divider -height 8 cnt
add wave -group "table" -ports                       snitch_read_only_cache_tb/dut/i_axi_to_cache/i_axi_burst_splitter_table/cnt_*
add wave -group "table" -divider -height 8 internal
add wave -group "table" -internal                    snitch_read_only_cache_tb/dut/i_axi_to_cache/i_axi_burst_splitter_table/*

# Cache modules: Lookup
add wave -group "lookup" -ports -color "Yellow Green" snitch_read_only_cache_tb/dut/i_lookup/clk* \
                                                      snitch_read_only_cache_tb/dut/i_lookup/rst* \
                                                      snitch_read_only_cache_tb/dut/i_lookup/flush*
add wave -group "lookup" -divider -height 8 in
add wave -group "lookup" -ports                       snitch_read_only_cache_tb/dut/i_lookup/in_*
add wave -group "lookup" -divider -height 8 out
add wave -group "lookup" -ports                       snitch_read_only_cache_tb/dut/i_lookup/out_*
add wave -group "lookup" -divider -height 8 write
add wave -group "lookup" -ports                       snitch_read_only_cache_tb/dut/i_lookup/write_*
add wave -group "lookup" -divider -height 8 internal
add wave -group "lookup" -internal                    snitch_read_only_cache_tb/dut/i_lookup/*

# Cache modules: Handler
add wave -group "handler" -ports -color "Yellow Green" snitch_read_only_cache_tb/dut/i_handler/clk* \
                                                       snitch_read_only_cache_tb/dut/i_handler/rst*
add wave -group "handler" -divider -height 8 in
add wave -group "handler" -ports                       snitch_read_only_cache_tb/dut/i_handler/in_*
add wave -group "handler" -divider -height 8 out
add wave -group "handler" -ports                       snitch_read_only_cache_tb/dut/i_handler/out_*
add wave -group "handler" -divider -height 8 write
add wave -group "handler" -ports                       snitch_read_only_cache_tb/dut/i_handler/write_*
add wave -group "handler" -divider -height 8 internal
add wave -group "handler" -internal                    snitch_read_only_cache_tb/dut/i_handler/*
add wave -group "handler" -internal                    snitch_read_only_cache_tb/dut/i_handler/pending_q

