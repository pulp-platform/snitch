// Copyright 2021 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

module occamy_cva6 (
  input  logic              clk_i,
  input  logic              rst_ni,
  input  logic [63:0]       boot_addr_i,
  input  logic [63:0]       hart_id_i,
  input  logic [1:0]        irq_i,
  input  logic              ipi_i,
  input  logic              time_irq_i,
  input  logic              debug_req_i,
  output ariane_axi::req_t  axi_req_o,
  input  ariane_axi::resp_t axi_resp_i
);

  localparam ariane_pkg::ariane_cfg_t CVA6OccamyConfig = '{
    RASDepth: 2,
    BTBEntries: 32,
    BHTEntries: 128,
    // idempotent region
    NrNonIdempotentRules: 2,
    NonIdempotentAddrBase: {64'b0, 64'b0},
    NonIdempotentLength:   {64'b0, 64'b0},
    NrExecuteRegionRules: 3,
    //                      DRAM,          Boot ROM,   Debug Module
    ExecuteRegionAddrBase: {64'h8000_0000, 64'h1_0000, 64'h0},
    ExecuteRegionLength:   {64'h40000000,  64'h10000,  64'h1000},
    // cached region
    NrCachedRegionRules:    1,
    CachedRegionAddrBase:  {64'h8000_0000},
    CachedRegionLength:    {64'h40000000},
    //  cache config
    Axi64BitCompliant:      1'b1,
    SwapEndianess:          1'b0,
    // debug
    DmBaseAddress:          64'h0,
    NrPMPEntries:           8
  };

  ariane #(
    .ArianeCfg (CVA6OccamyConfig)
  ) i_cva6 (
    .clk_i,
    .rst_ni,
    .boot_addr_i,
    .hart_id_i,
    .irq_i,
    .ipi_i,
    .time_irq_i,
    .debug_req_i,
    .axi_req_o,
    .axi_resp_i
  );

endmodule
