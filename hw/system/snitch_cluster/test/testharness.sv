// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

`include "axi/typedef.svh"

module testharness import snitch_cluster_pkg::*; (
  input  logic        clk_i,
  input  logic        rst_ni
);

  narrow_in_req_t narrow_in_req;
  narrow_in_resp_t narrow_in_resp;
  narrow_out_req_t narrow_out_req;
  narrow_out_resp_t narrow_out_resp;
  wide_out_req_t wide_out_req;
  wide_out_resp_t wide_out_resp;
  wide_in_req_t wide_in_req;
  wide_in_resp_t wide_in_resp;

  snitch_cluster_wrapper i_snitch_cluster (
    .clk_i,
    .rst_ni,
    .debug_req_i ('0),
    .meip_i ('0),
    .mtip_i ('0),
    .msip_i ('0),
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
    .AxiUserWidth (UserWidth),
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
    .AxiUserWidth (UserWidth),
    .req_t (wide_out_req_t),
    .rsp_t (wide_out_resp_t)
  ) i_dma (
    .clk_i,
    .rst_ni,
    .req_i (wide_out_req),
    .rsp_o (wide_out_resp)
  );

endmodule
