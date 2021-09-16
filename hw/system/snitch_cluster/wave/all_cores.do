# Copyright 2020 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group {All Cores} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[0]/i_snitch_cc/i_snitch/wfi_q}
add wave -noupdate -expand -group {All Cores} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[1]/i_snitch_cc/i_snitch/wfi_q}
add wave -noupdate -expand -group {All Cores} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[2]/i_snitch_cc/i_snitch/wfi_q}
add wave -noupdate -expand -group {All Cores} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[3]/i_snitch_cc/i_snitch/wfi_q}
add wave -noupdate -expand -group {All Cores} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[4]/i_snitch_cc/i_snitch/wfi_q}
add wave -noupdate -expand -group {All Cores} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[5]/i_snitch_cc/i_snitch/wfi_q}
add wave -noupdate -expand -group {All Cores} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[6]/i_snitch_cc/i_snitch/wfi_q}
add wave -noupdate -expand -group {All Cores} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[7]/i_snitch_cc/i_snitch/wfi_q}
add wave -noupdate -expand -group {All Cores} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[8]/i_snitch_cc/i_snitch/wfi_q}
add wave -noupdate -expand -group {All Cores} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[0]/i_snitch_cc/i_snitch/pc_q}
add wave -noupdate -expand -group {All Cores} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[1]/i_snitch_cc/i_snitch/pc_q}
add wave -noupdate -expand -group {All Cores} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[2]/i_snitch_cc/i_snitch/pc_q}
add wave -noupdate -expand -group {All Cores} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[3]/i_snitch_cc/i_snitch/pc_q}
add wave -noupdate -expand -group {All Cores} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[4]/i_snitch_cc/i_snitch/pc_q}
add wave -noupdate -expand -group {All Cores} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[5]/i_snitch_cc/i_snitch/pc_q}
add wave -noupdate -expand -group {All Cores} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[6]/i_snitch_cc/i_snitch/pc_q}
add wave -noupdate -expand -group {All Cores} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[7]/i_snitch_cc/i_snitch/pc_q}
add wave -noupdate -expand -group {All Cores} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[8]/i_snitch_cc/i_snitch/pc_q}
add wave -noupdate -divider {FPU subsystem}
add wave -noupdate -expand -group FPU0 {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[0]/i_snitch_cc/gen_fpu/i_snitch_fp_ss/trace_port_o}
add wave -noupdate -expand -group FPU0 {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[0]/i_snitch_cc/gen_fpu/i_snitch_fp_ss/i_fpu/op_i}
add wave -noupdate -expand -group FPU0 {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[0]/i_snitch_cc/gen_fpu/i_snitch_fp_ss/i_fpu/out_valid_o}
add wave -noupdate -expand -group FPU0 {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[0]/i_snitch_cc/gen_fpu/i_snitch_fp_ss/i_fpu/out_ready_i}
add wave -noupdate -expand -group {SSR 0.0} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[0]/i_snitch_cc/gen_ssrs/i_snitch_ssr_streamer/gen_ssrs[0]/i_ssr/i_addr_gen/mem_addr_o}
add wave -noupdate -expand -group {SSR 0.0} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[0]/i_snitch_cc/gen_ssrs/i_snitch_ssr_streamer/gen_ssrs[0]/i_ssr/i_addr_gen/mem_write_o}
add wave -noupdate -expand -group {SSR 0.0} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[0]/i_snitch_cc/gen_ssrs/i_snitch_ssr_streamer/gen_ssrs[0]/i_ssr/i_addr_gen/mem_valid_o}
add wave -noupdate -expand -group {SSR 0.0} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[0]/i_snitch_cc/gen_ssrs/i_snitch_ssr_streamer/gen_ssrs[0]/i_ssr/i_addr_gen/mem_ready_i}
add wave -noupdate -expand -group {SSR 0.0} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[0]/i_snitch_cc/gen_ssrs/i_snitch_ssr_streamer/gen_ssrs[0]/i_ssr/i_addr_gen/enable}
add wave -noupdate -expand -group {SSR 0.0} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[0]/i_snitch_cc/gen_ssrs/i_snitch_ssr_streamer/gen_ssrs[0]/i_ssr/i_addr_gen/done}
add wave -noupdate -expand -group {SSR 0.0} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[0]/i_snitch_cc/gen_ssrs/i_snitch_ssr_streamer/gen_ssrs[0]/i_ssr/lane_rdata_o}
add wave -noupdate -expand -group {SSR 0.0} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[0]/i_snitch_cc/gen_ssrs/i_snitch_ssr_streamer/gen_ssrs[0]/i_ssr/lane_valid_o}
add wave -noupdate -expand -group {SSR 0.0} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[0]/i_snitch_cc/gen_ssrs/i_snitch_ssr_streamer/gen_ssrs[0]/i_ssr/lane_ready_i}
add wave -noupdate -expand -group {SSR 0.0} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[0]/i_snitch_cc/gen_ssrs/i_snitch_ssr_streamer/gen_ssrs[0]/i_ssr/i_addr_gen/bound_sq}
add wave -noupdate -group FPU1 {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[1]/i_snitch_cc/gen_fpu/i_snitch_fp_ss/trace_port_o}
add wave -noupdate -group FPU1 {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[1]/i_snitch_cc/gen_fpu/i_snitch_fp_ss/i_fpu/op_i}
add wave -noupdate -group FPU1 {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[1]/i_snitch_cc/gen_fpu/i_snitch_fp_ss/i_fpu/out_valid_o}
add wave -noupdate -group FPU1 {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[1]/i_snitch_cc/gen_fpu/i_snitch_fp_ss/i_fpu/out_ready_i}
add wave -noupdate -group {SSR 1.0} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[1]/i_snitch_cc/gen_ssrs/i_snitch_ssr_streamer/gen_ssrs[0]/i_ssr/i_addr_gen/mem_addr_o}
add wave -noupdate -group {SSR 1.0} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[1]/i_snitch_cc/gen_ssrs/i_snitch_ssr_streamer/gen_ssrs[0]/i_ssr/i_addr_gen/mem_write_o}
add wave -noupdate -group {SSR 1.0} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[1]/i_snitch_cc/gen_ssrs/i_snitch_ssr_streamer/gen_ssrs[0]/i_ssr/i_addr_gen/mem_valid_o}
add wave -noupdate -group {SSR 1.0} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[1]/i_snitch_cc/gen_ssrs/i_snitch_ssr_streamer/gen_ssrs[0]/i_ssr/i_addr_gen/mem_ready_i}
add wave -noupdate -group {SSR 1.0} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[1]/i_snitch_cc/gen_ssrs/i_snitch_ssr_streamer/gen_ssrs[0]/i_ssr/i_addr_gen/enable}
add wave -noupdate -group {SSR 1.0} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[1]/i_snitch_cc/gen_ssrs/i_snitch_ssr_streamer/gen_ssrs[0]/i_ssr/i_addr_gen/done}
add wave -noupdate -group {SSR 1.0} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[1]/i_snitch_cc/gen_ssrs/i_snitch_ssr_streamer/gen_ssrs[0]/i_ssr/lane_rdata_o}
add wave -noupdate -group {SSR 1.0} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[1]/i_snitch_cc/gen_ssrs/i_snitch_ssr_streamer/gen_ssrs[0]/i_ssr/lane_valid_o}
add wave -noupdate -group {SSR 1.0} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[1]/i_snitch_cc/gen_ssrs/i_snitch_ssr_streamer/gen_ssrs[0]/i_ssr/lane_ready_i}
add wave -noupdate -group {SSR 1.0} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[1]/i_snitch_cc/gen_ssrs/i_snitch_ssr_streamer/gen_ssrs[0]/i_ssr/i_addr_gen/bound_sq}
add wave -noupdate -group FPU2 {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[2]/i_snitch_cc/gen_fpu/i_snitch_fp_ss/trace_port_o}
add wave -noupdate -group FPU2 {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[2]/i_snitch_cc/gen_fpu/i_snitch_fp_ss/i_fpu/op_i}
add wave -noupdate -group FPU2 {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[2]/i_snitch_cc/gen_fpu/i_snitch_fp_ss/i_fpu/out_valid_o}
add wave -noupdate -group FPU2 {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[2]/i_snitch_cc/gen_fpu/i_snitch_fp_ss/i_fpu/out_ready_i}
add wave -noupdate -group FPU3 {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[3]/i_snitch_cc/gen_fpu/i_snitch_fp_ss/trace_port_o}
add wave -noupdate -group FPU3 {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[3]/i_snitch_cc/gen_fpu/i_snitch_fp_ss/i_fpu/op_i}
add wave -noupdate -group FPU3 {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[3]/i_snitch_cc/gen_fpu/i_snitch_fp_ss/i_fpu/out_valid_o}
add wave -noupdate -group FPU3 {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[3]/i_snitch_cc/gen_fpu/i_snitch_fp_ss/i_fpu/out_ready_i}
add wave -noupdate -group FPU4 {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[4]/i_snitch_cc/gen_fpu/i_snitch_fp_ss/trace_port_o}
add wave -noupdate -group FPU4 {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[4]/i_snitch_cc/gen_fpu/i_snitch_fp_ss/i_fpu/op_i}
add wave -noupdate -group FPU4 {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[4]/i_snitch_cc/gen_fpu/i_snitch_fp_ss/i_fpu/out_valid_o}
add wave -noupdate -group FPU4 {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[4]/i_snitch_cc/gen_fpu/i_snitch_fp_ss/i_fpu/out_ready_i}
add wave -noupdate -group FPU5 {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[5]/i_snitch_cc/gen_fpu/i_snitch_fp_ss/trace_port_o}
add wave -noupdate -group FPU5 {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[5]/i_snitch_cc/gen_fpu/i_snitch_fp_ss/i_fpu/op_i}
add wave -noupdate -group FPU5 {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[5]/i_snitch_cc/gen_fpu/i_snitch_fp_ss/i_fpu/out_valid_o}
add wave -noupdate -group FPU5 {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[5]/i_snitch_cc/gen_fpu/i_snitch_fp_ss/i_fpu/out_ready_i}
add wave -noupdate -group FPU6 {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[6]/i_snitch_cc/gen_fpu/i_snitch_fp_ss/trace_port_o}
add wave -noupdate -group FPU6 {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[6]/i_snitch_cc/gen_fpu/i_snitch_fp_ss/i_fpu/op_i}
add wave -noupdate -group FPU6 {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[6]/i_snitch_cc/gen_fpu/i_snitch_fp_ss/i_fpu/out_valid_o}
add wave -noupdate -group FPU6 {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[6]/i_snitch_cc/gen_fpu/i_snitch_fp_ss/i_fpu/out_ready_i}
add wave -noupdate -group FPU7 {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[7]/i_snitch_cc/gen_fpu/i_snitch_fp_ss/trace_port_o}
add wave -noupdate -group FPU7 {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[7]/i_snitch_cc/gen_fpu/i_snitch_fp_ss/i_fpu/op_i}
add wave -noupdate -group FPU7 {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[7]/i_snitch_cc/gen_fpu/i_snitch_fp_ss/i_fpu/out_valid_o}
add wave -noupdate -group FPU7 {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[7]/i_snitch_cc/gen_fpu/i_snitch_fp_ss/i_fpu/out_ready_i}
add wave -noupdate -group {FPU0 LSU} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[0]/i_snitch_cc/gen_fpu/i_snitch_fp_ss/i_snitch_lsu/lsu_qready_o}
add wave -noupdate -group {FPU0 LSU} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[0]/i_snitch_cc/gen_fpu/i_snitch_fp_ss/i_snitch_lsu/lsu_qvalid_i}
add wave -noupdate -group {FPU0 LSU} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[0]/i_snitch_cc/gen_fpu/i_snitch_fp_ss/i_snitch_lsu/lsu_pready_i}
add wave -noupdate -group {FPU0 LSU} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[0]/i_snitch_cc/gen_fpu/i_snitch_fp_ss/i_snitch_lsu/lsu_pvalid_o}
add wave -noupdate -divider DMA
add wave -noupdate -childformat {{{/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[8]/i_snitch_cc/gen_dma/i_axi_dma_tc_snitch_fe/dma_perf_o.aw_stall_cnt} -radix decimal} {{/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[8]/i_snitch_cc/gen_dma/i_axi_dma_tc_snitch_fe/dma_perf_o.ar_stall_cnt} -radix decimal} {{/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[8]/i_snitch_cc/gen_dma/i_axi_dma_tc_snitch_fe/dma_perf_o.r_stall_cnt} -radix decimal} {{/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[8]/i_snitch_cc/gen_dma/i_axi_dma_tc_snitch_fe/dma_perf_o.w_stall_cnt} -radix decimal} {{/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[8]/i_snitch_cc/gen_dma/i_axi_dma_tc_snitch_fe/dma_perf_o.buf_w_stall_cnt} -radix decimal} {{/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[8]/i_snitch_cc/gen_dma/i_axi_dma_tc_snitch_fe/dma_perf_o.buf_r_stall_cnt} -radix decimal} {{/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[8]/i_snitch_cc/gen_dma/i_axi_dma_tc_snitch_fe/dma_perf_o.aw_valid_cnt} -radix decimal} {{/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[8]/i_snitch_cc/gen_dma/i_axi_dma_tc_snitch_fe/dma_perf_o.aw_ready_cnt} -radix decimal} {{/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[8]/i_snitch_cc/gen_dma/i_axi_dma_tc_snitch_fe/dma_perf_o.aw_done_cnt} -radix decimal} {{/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[8]/i_snitch_cc/gen_dma/i_axi_dma_tc_snitch_fe/dma_perf_o.ar_valid_cnt} -radix decimal} {{/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[8]/i_snitch_cc/gen_dma/i_axi_dma_tc_snitch_fe/dma_perf_o.ar_ready_cnt} -radix decimal} {{/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[8]/i_snitch_cc/gen_dma/i_axi_dma_tc_snitch_fe/dma_perf_o.ar_done_cnt} -radix decimal} {{/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[8]/i_snitch_cc/gen_dma/i_axi_dma_tc_snitch_fe/dma_perf_o.r_valid_cnt} -radix decimal} {{/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[8]/i_snitch_cc/gen_dma/i_axi_dma_tc_snitch_fe/dma_perf_o.r_ready_cnt} -radix decimal} {{/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[8]/i_snitch_cc/gen_dma/i_axi_dma_tc_snitch_fe/dma_perf_o.r_done_cnt} -radix decimal} {{/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[8]/i_snitch_cc/gen_dma/i_axi_dma_tc_snitch_fe/dma_perf_o.w_valid_cnt} -radix decimal} {{/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[8]/i_snitch_cc/gen_dma/i_axi_dma_tc_snitch_fe/dma_perf_o.w_ready_cnt} -radix decimal} {{/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[8]/i_snitch_cc/gen_dma/i_axi_dma_tc_snitch_fe/dma_perf_o.w_done_cnt} -radix decimal} {{/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[8]/i_snitch_cc/gen_dma/i_axi_dma_tc_snitch_fe/dma_perf_o.b_valid_cnt} -radix decimal} {{/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[8]/i_snitch_cc/gen_dma/i_axi_dma_tc_snitch_fe/dma_perf_o.b_ready_cnt} -radix decimal} {{/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[8]/i_snitch_cc/gen_dma/i_axi_dma_tc_snitch_fe/dma_perf_o.b_done_cnt} -radix decimal} {{/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[8]/i_snitch_cc/gen_dma/i_axi_dma_tc_snitch_fe/dma_perf_o.dma_busy_cnt} -radix decimal}} -subitemconfig {{/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[8]/i_snitch_cc/gen_dma/i_axi_dma_tc_snitch_fe/dma_perf_o.aw_stall_cnt} {-height 16 -radix decimal} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[8]/i_snitch_cc/gen_dma/i_axi_dma_tc_snitch_fe/dma_perf_o.ar_stall_cnt} {-height 16 -radix decimal} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[8]/i_snitch_cc/gen_dma/i_axi_dma_tc_snitch_fe/dma_perf_o.r_stall_cnt} {-height 16 -radix decimal} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[8]/i_snitch_cc/gen_dma/i_axi_dma_tc_snitch_fe/dma_perf_o.w_stall_cnt} {-height 16 -radix decimal} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[8]/i_snitch_cc/gen_dma/i_axi_dma_tc_snitch_fe/dma_perf_o.buf_w_stall_cnt} {-height 16 -radix decimal} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[8]/i_snitch_cc/gen_dma/i_axi_dma_tc_snitch_fe/dma_perf_o.buf_r_stall_cnt} {-height 16 -radix decimal} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[8]/i_snitch_cc/gen_dma/i_axi_dma_tc_snitch_fe/dma_perf_o.aw_valid_cnt} {-height 16 -radix decimal} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[8]/i_snitch_cc/gen_dma/i_axi_dma_tc_snitch_fe/dma_perf_o.aw_ready_cnt} {-height 16 -radix decimal} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[8]/i_snitch_cc/gen_dma/i_axi_dma_tc_snitch_fe/dma_perf_o.aw_done_cnt} {-height 16 -radix decimal} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[8]/i_snitch_cc/gen_dma/i_axi_dma_tc_snitch_fe/dma_perf_o.ar_valid_cnt} {-height 16 -radix decimal} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[8]/i_snitch_cc/gen_dma/i_axi_dma_tc_snitch_fe/dma_perf_o.ar_ready_cnt} {-height 16 -radix decimal} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[8]/i_snitch_cc/gen_dma/i_axi_dma_tc_snitch_fe/dma_perf_o.ar_done_cnt} {-height 16 -radix decimal} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[8]/i_snitch_cc/gen_dma/i_axi_dma_tc_snitch_fe/dma_perf_o.r_valid_cnt} {-height 16 -radix decimal} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[8]/i_snitch_cc/gen_dma/i_axi_dma_tc_snitch_fe/dma_perf_o.r_ready_cnt} {-height 16 -radix decimal} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[8]/i_snitch_cc/gen_dma/i_axi_dma_tc_snitch_fe/dma_perf_o.r_done_cnt} {-height 16 -radix decimal} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[8]/i_snitch_cc/gen_dma/i_axi_dma_tc_snitch_fe/dma_perf_o.w_valid_cnt} {-height 16 -radix decimal} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[8]/i_snitch_cc/gen_dma/i_axi_dma_tc_snitch_fe/dma_perf_o.w_ready_cnt} {-height 16 -radix decimal} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[8]/i_snitch_cc/gen_dma/i_axi_dma_tc_snitch_fe/dma_perf_o.w_done_cnt} {-height 16 -radix decimal} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[8]/i_snitch_cc/gen_dma/i_axi_dma_tc_snitch_fe/dma_perf_o.b_valid_cnt} {-height 16 -radix decimal} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[8]/i_snitch_cc/gen_dma/i_axi_dma_tc_snitch_fe/dma_perf_o.b_ready_cnt} {-height 16 -radix decimal} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[8]/i_snitch_cc/gen_dma/i_axi_dma_tc_snitch_fe/dma_perf_o.b_done_cnt} {-height 16 -radix decimal} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[8]/i_snitch_cc/gen_dma/i_axi_dma_tc_snitch_fe/dma_perf_o.dma_busy_cnt} {-height 16 -radix decimal}} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[8]/i_snitch_cc/gen_dma/i_axi_dma_tc_snitch_fe/dma_perf_o}
add wave -noupdate {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[8]/i_snitch_cc/gen_dma/i_axi_dma_tc_snitch_fe/i_axi_dma_backend/backend_idle_o}
add wave -noupdate {/tb_bin/i_dut/i_snitch_cluster/i_cluster/gen_core[8]/i_snitch_cc/gen_dma/i_axi_dma_tc_snitch_fe/i_axi_dma_backend/trans_complete_o}
add wave -noupdate -divider AXI
add wave -noupdate -group {Wide Out} /tb_bin/i_dut/wide_out_resp.r
add wave -noupdate -group {Wide Out} /tb_bin/i_dut/wide_out_resp.r_valid
add wave -noupdate -group {Wide Out} /tb_bin/i_dut/wide_out_req.r_ready
add wave -noupdate -group {Wide Out} /tb_bin/i_dut/wide_out_req.ar
add wave -noupdate -group {Wide Out} /tb_bin/i_dut/wide_out_req.ar_valid
add wave -noupdate -group {Wide Out} /tb_bin/i_dut/wide_out_resp.ar_ready
add wave -noupdate -group {Wide Out} /tb_bin/i_dut/wide_out_req.aw
add wave -noupdate -group {Wide Out} /tb_bin/i_dut/wide_out_req.aw_valid
add wave -noupdate -group {Wide Out} /tb_bin/i_dut/wide_out_resp.aw_ready
add wave -noupdate -group {Wide Out} /tb_bin/i_dut/wide_out_req.w
add wave -noupdate -group {Wide Out} /tb_bin/i_dut/wide_out_req.w_valid
add wave -noupdate -group {Wide Out} /tb_bin/i_dut/wide_out_resp.w_ready
add wave -noupdate -group {Wide Out} /tb_bin/i_dut/wide_out_req.w.last
add wave -noupdate -group {DMA Xbar DMA port} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/i_axi_dma_xbar/slv_ports_req_i[0].aw_valid}
add wave -noupdate -group {DMA Xbar DMA port} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/i_axi_dma_xbar/slv_ports_resp_o[0].aw_ready}
add wave -noupdate -group {DMA Xbar DMA port} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/i_axi_dma_xbar/slv_ports_req_i[0].aw.addr}
add wave -noupdate -group {DMA Xbar DMA port} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/i_axi_dma_xbar/slv_ports_req_i[0].ar_valid}
add wave -noupdate -group {DMA Xbar DMA port} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/i_axi_dma_xbar/slv_ports_resp_o[0].ar_ready}
add wave -noupdate -group {DMA Xbar DMA port} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/i_axi_dma_xbar/slv_ports_req_i[0].ar.addr}
add wave -noupdate -group {DMA Xbar DMA port} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/i_axi_dma_xbar/slv_ports_req_i[0].w_valid}
add wave -noupdate -group {DMA Xbar DMA port} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/i_axi_dma_xbar/slv_ports_resp_o[0].w_ready}
add wave -noupdate -group {DMA Xbar DMA port} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/i_axi_dma_xbar/slv_ports_resp_o[0].r_valid}
add wave -noupdate -group {DMA Xbar DMA port} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/i_axi_dma_xbar/slv_ports_req_i[0].r_ready}
add wave -noupdate -group {DMA Xbar TCDM port} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/i_axi_dma_xbar/mst_ports_req_o[0].aw_valid}
add wave -noupdate -group {DMA Xbar TCDM port} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/i_axi_dma_xbar/mst_ports_resp_i[0].aw_ready}
add wave -noupdate -group {DMA Xbar TCDM port} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/i_axi_dma_xbar/mst_ports_req_o[0].aw.addr}
add wave -noupdate -group {DMA Xbar TCDM port} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/i_axi_dma_xbar/mst_ports_req_o[0].ar_valid}
add wave -noupdate -group {DMA Xbar TCDM port} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/i_axi_dma_xbar/mst_ports_resp_i[0].ar_ready}
add wave -noupdate -group {DMA Xbar TCDM port} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/i_axi_dma_xbar/mst_ports_req_o[0].ar.addr}
add wave -noupdate -group {DMA Xbar TCDM port} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/i_axi_dma_xbar/mst_ports_req_o[0].w_valid}
add wave -noupdate -group {DMA Xbar TCDM port} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/i_axi_dma_xbar/mst_ports_resp_i[0].w_ready}
add wave -noupdate -group {DMA Xbar TCDM port} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/i_axi_dma_xbar/mst_ports_resp_i[0].r_valid}
add wave -noupdate -group {DMA Xbar TCDM port} {/tb_bin/i_dut/i_snitch_cluster/i_cluster/i_axi_dma_xbar/mst_ports_req_o[0].r_ready}
add wave -noupdate -group {Narrow Out} /tb_bin/i_dut/i_snitch_cluster/i_cluster/narrow_out_resp_i.r
add wave -noupdate -group {Narrow Out} /tb_bin/i_dut/i_snitch_cluster/i_cluster/narrow_out_resp_i.r_valid
add wave -noupdate -group {Narrow Out} /tb_bin/i_dut/i_snitch_cluster/i_cluster/narrow_out_req_o.r_ready
add wave -noupdate -group {Narrow Out} /tb_bin/i_dut/i_snitch_cluster/i_cluster/narrow_out_req_o.ar
add wave -noupdate -group {Narrow Out} /tb_bin/i_dut/i_snitch_cluster/i_cluster/narrow_out_req_o.ar_valid
add wave -noupdate -group {Narrow Out} /tb_bin/i_dut/i_snitch_cluster/i_cluster/narrow_out_resp_i.ar_ready
add wave -noupdate -group {Narrow Out} /tb_bin/i_dut/i_snitch_cluster/i_cluster/narrow_out_req_o.w
add wave -noupdate -group {Narrow Out} /tb_bin/i_dut/i_snitch_cluster/i_cluster/narrow_out_req_o.w_valid
add wave -noupdate -group {Narrow Out} /tb_bin/i_dut/i_snitch_cluster/i_cluster/narrow_out_resp_i.w_ready
add wave -noupdate -group {Narrow Out} /tb_bin/i_dut/i_snitch_cluster/i_cluster/narrow_out_req_o.aw
add wave -noupdate -group {Narrow Out} /tb_bin/i_dut/i_snitch_cluster/i_cluster/narrow_out_req_o.aw_valid
add wave -noupdate -group {Narrow Out} /tb_bin/i_dut/i_snitch_cluster/i_cluster/narrow_out_resp_i.aw_ready
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {15540 ns}
