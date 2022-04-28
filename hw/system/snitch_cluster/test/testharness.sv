// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

`include "axi/typedef.svh"

module testharness import snitch_cluster_pkg::*; (
  input  logic        clk_i,
  input  logic        rst_ni
);
  import "DPI-C" function void clint_tick(
    output byte msip[]
  );

  narrow_in_req_t narrow_in_req;
  narrow_in_resp_t narrow_in_resp;
  narrow_out_req_t narrow_out_req;
  narrow_out_resp_t narrow_out_resp;
  wide_out_req_t wide_out_req;
  wide_out_resp_t wide_out_resp;
  wide_in_req_t wide_in_req;
  wide_in_resp_t wide_in_resp;
  logic [snitch_cluster_pkg::NrCores-1:0] msip;

  snitch_cluster_wrapper i_snitch_cluster (
    .clk_i,
    .rst_ni,
    .debug_req_i ('0),
    .meip_i ('0),
    .mtip_i ('0),
    .msip_i (msip),
    .narrow_in_req_i (narrow_in_req),
    .narrow_in_resp_o (narrow_in_resp),
    .narrow_out_req_o (narrow_out_req),
    .narrow_out_resp_i (narrow_out_resp),
    .wide_out_req_o (wide_out_req),
    .wide_out_resp_i (wide_out_resp),
    .wide_in_req_i (wide_in_req),
    .wide_in_resp_o (wide_in_resp)
  );

  // Tie-off unused input ports.
  assign narrow_in_req = '0;
  assign wide_in_req = '0;

  // Narrow port into simulation memory.
  tb_memory_axi #(
    .AxiAddrWidth (AddrWidth),
    .AxiDataWidth (NarrowDataWidth),
    .AxiIdWidth (NarrowIdWidthOut),
    .AxiUserWidth (NarrowUserWidth),
    .req_t (narrow_out_req_t),
    .rsp_t (narrow_out_resp_t)
  ) i_mem (
    .clk_i,
    .rst_ni,
    .req_i (narrow_out_req),
    .rsp_o (narrow_out_resp)
  );

  // Wide port into simulation memory.
  tb_memory_axi #(
    .AxiAddrWidth (AddrWidth),
    .AxiDataWidth (WideDataWidth),
    .AxiIdWidth (WideIdWidthOut),
    .AxiUserWidth (WideUserWidth),
    .req_t (wide_out_req_t),
    .rsp_t (wide_out_resp_t)
  ) i_dma (
    .clk_i,
    .rst_ni,
    .req_i (wide_out_req),
    .rsp_o (wide_out_resp)
  );

  // CLINT
  // verilog_lint: waive-start always-ff-non-blocking
  localparam int NumCores = snitch_cluster_pkg::NrCores;
  always_ff @(posedge clk_i) begin
    automatic byte msip_ret[NumCores];
    if (rst_ni) begin
      clint_tick(msip_ret);
      for (int i = 0; i < NumCores; i++) begin
        msip[i] = msip_ret[i];
      end
    end
  end
  // verilog_lint: waive-stop always-ff-non-blocking

endmodule
