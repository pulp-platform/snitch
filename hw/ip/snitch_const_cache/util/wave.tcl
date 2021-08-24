# Testbench
add wave -group "snitch_const_cache_tb" snitch_const_cache_tb/*
# DUT
add wave -group "dut" -group "parameter" -radix decimal snitch_const_cache_tb/dut/LineWidth \
                                                        snitch_const_cache_tb/dut/LineCount \
                                                        snitch_const_cache_tb/dut/SetCount \
                                                        snitch_const_cache_tb/dut/AxiAddrWidth \
                                                        snitch_const_cache_tb/dut/AxiDataWidth \
                                                        snitch_const_cache_tb/dut/AxiIdWidth \
                                                        snitch_const_cache_tb/dut/AxiUserWidth \
                                                        snitch_const_cache_tb/dut/MaxTrans \
                                                        snitch_const_cache_tb/dut/NrAddrRules \
                                                        snitch_const_cache_tb/dut/PendingCount \
                                                        snitch_const_cache_tb/dut/CFG

add wave -group "dut" -ports -color "Yellow Green" snitch_const_cache_tb/dut/*
add wave -group "lookup" -divider -height 8 internal
add wave -group "dut" -internal snitch_const_cache_tb/dut/*
# Cache modules: Lookup
add wave -group "lookup" -ports -color "Yellow Green" snitch_const_cache_tb/dut/i_lookup/clk* \
                                                      snitch_const_cache_tb/dut/i_lookup/rst* \
                                                      snitch_const_cache_tb/dut/i_lookup/flush*
add wave -group "lookup" -divider -height 8 in
add wave -group "lookup" -ports -color "Yellow Green" snitch_const_cache_tb/dut/i_lookup/in_*
add wave -group "lookup" -divider -height 8 out
add wave -group "lookup" -ports -color "Yellow Green" snitch_const_cache_tb/dut/i_lookup/out_*
add wave -group "lookup" -divider -height 8 write
add wave -group "lookup" -ports -color "Yellow Green" snitch_const_cache_tb/dut/i_lookup/write_*
add wave -group "lookup" -divider -height 8 internal
add wave -group "lookup" -internal snitch_const_cache_tb/dut/i_lookup/*

# Cache modules: Handler
add wave -group "handler" -ports -color "Yellow Green" snitch_const_cache_tb/dut/i_handler/clk* \
                                                       snitch_const_cache_tb/dut/i_handler/rst*
add wave -group "handler" -divider -height 8 in
add wave -group "handler" -ports -color "Yellow Green" snitch_const_cache_tb/dut/i_handler/in_*
add wave -group "handler" -divider -height 8 out
add wave -group "handler" -ports -color "Yellow Green" snitch_const_cache_tb/dut/i_handler/out_*
add wave -group "handler" -divider -height 8 write
add wave -group "handler" -ports -color "Yellow Green" snitch_const_cache_tb/dut/i_handler/write_*
add wave -group "handler" -divider -height 8 internal
add wave -group "handler" -internal snitch_const_cache_tb/dut/i_handler/*

