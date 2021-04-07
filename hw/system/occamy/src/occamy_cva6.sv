// Copyright 2021 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>

// AUTOMATICALLY GENERATED by genoccamy.py; edit the script instead.

module occamy_cva6
  import occamy_pkg::*;
(
    input  logic                          clk_i,
    input  logic                          rst_ni,
    input  logic                    [1:0] irq_i,
    input  logic                          ipi_i,
    input  logic                          time_irq_i,
    input  logic                          debug_req_i,
    output axi_a48_d64_i4_u0_req_t        axi_req_o,
    input  axi_a48_d64_i4_u0_resp_t       axi_resp_i
);

  axi_a48_d64_i4_u0_req_t  cva6_axi_req;
  axi_a48_d64_i4_u0_resp_t cva6_axi_rsp;

  axi_a48_d64_i4_u0_req_t  cva6_axi_cut_req;
  axi_a48_d64_i4_u0_resp_t cva6_axi_cut_rsp;

  axi_multicut #(
      .NoCuts(1),
      .aw_chan_t(axi_a48_d64_i4_u0_aw_chan_t),
      .w_chan_t(axi_a48_d64_i4_u0_w_chan_t),
      .b_chan_t(axi_a48_d64_i4_u0_b_chan_t),
      .ar_chan_t(axi_a48_d64_i4_u0_ar_chan_t),
      .r_chan_t(axi_a48_d64_i4_u0_r_chan_t),
      .req_t(axi_a48_d64_i4_u0_req_t),
      .resp_t(axi_a48_d64_i4_u0_resp_t)
  ) i_cva6_axi_cut (
      .clk_i(clk_i),
      .rst_ni(rst_ni),
      .slv_req_i(cva6_axi_req),
      .slv_resp_o(cva6_axi_rsp),
      .mst_req_o(cva6_axi_cut_req),
      .mst_resp_i(cva6_axi_cut_rsp)
  );


  assign axi_req_o = cva6_axi_cut_req;
  assign cva6_axi_cut_rsp = axi_resp_i;

  // TODO(zarubaf): Derive from system parameters
  localparam ariane_pkg::ariane_cfg_t CVA6OccamyConfig = '{
    RASDepth: 2,
    BTBEntries: 32,
    BHTEntries: 128,
  // idempotent region
  NrNonIdempotentRules: 1, NonIdempotentAddrBase: {
    64'b0
  }, NonIdempotentLength: {
    64'h8000_0000
  }, NrExecuteRegionRules: 3,
  //                      DRAM,                     Boot ROM,                             Debug Module
  ExecuteRegionAddrBase: {
    64'h8000_0000, 64'd16777216, 64'h0
  }, ExecuteRegionLength: {
    64'hffff_ffff_ffff_ffff, 64'd131072, 64'h1000
  },
  // cached region
  NrCachedRegionRules: 1, CachedRegionAddrBase: {
    64'h8000_0000
  }, CachedRegionLength: {
    64'hffff_ffff_ffff_ffff
  },
  //  cache config
  Axi64BitCompliant: 1'b1, SwapEndianess: 1'b0,
  // debug
  DmBaseAddress: 64'h0, NrPMPEntries: 8};

  logic [1:0] irq;
  logic       ipi;
  logic       time_irq;
  logic       debug_req;

  sync #(
      .STAGES(2)
  ) i_sync_debug (
      .clk_i,
      .rst_ni,
      .serial_i(debug_req_i),
      .serial_o(debug_req)
  );
  sync #(
      .STAGES(2)
  ) i_sync_ipi (
      .clk_i,
      .rst_ni,
      .serial_i(ipi_i),
      .serial_o(ipi)
  );
  sync #(
      .STAGES(2)
  ) i_sync_time_irq (
      .clk_i,
      .rst_ni,
      .serial_i(time_irq_i),
      .serial_o(time_irq)
  );
  sync #(
      .STAGES(2)
  ) i_sync_irq_0 (
      .clk_i,
      .rst_ni,
      .serial_i(irq_i[0]),
      .serial_o(irq[0])
  );
  sync #(
      .STAGES(2)
  ) i_sync_irq_1 (
      .clk_i,
      .rst_ni,
      .serial_i(irq_i[1]),
      .serial_o(irq[1])
  );

  localparam logic [63:0] BootAddr = 'd16777216;


  ariane #(
      .ArianeCfg(CVA6OccamyConfig),
      .AxiAddrWidth(48),
      .AxiDataWidth(64),
      .AxiIdWidth(4),
      .AxiUserWidth(1),
      .axi_req_t(axi_a48_d64_i4_u0_req_t),
      .axi_rsp_t(axi_a48_d64_i4_u0_resp_t)
  ) i_cva6 (
      .clk_i,
      .rst_ni,
      .boot_addr_i(BootAddr),
      .hart_id_i(64'h0),
      .irq_i(irq),
      .ipi_i(ipi),
      .time_irq_i(time_irq),
      .debug_req_i(debug_req),
      .axi_req_o(cva6_axi_req),
      .axi_resp_i(cva6_axi_rsp)
  );

endmodule
