// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>
`include "reqrsp_interface/typedef.svh"

/// Convert AXI to TCDM protocol.
module axi_to_tcdm #(
    parameter type axi_req_t = logic,
    parameter type axi_rsp_t = logic,
    parameter type tcdm_req_t = logic,
    parameter type tcdm_rsp_t = logic,
    parameter int unsigned AddrWidth  = 0,
    parameter int unsigned DataWidth  = 0,
    parameter int unsigned IdWidth    = 0,
    parameter int unsigned BufDepth   = 1
) (
    input  logic      clk_i,
    input  logic      rst_ni,
    input  axi_req_t  axi_req_i,
    output axi_rsp_t  axi_rsp_o,
    output tcdm_req_t tcdm_req_o,
    input  tcdm_rsp_t tcdm_rsp_i
);

  typedef logic [AddrWidth-1:0] addr_t;
  typedef logic [DataWidth-1:0] data_t;
  typedef logic [DataWidth/8-1:0] strb_t;

  `REQRSP_TYPEDEF_ALL(reqrsp, addr_t, data_t, strb_t)

  reqrsp_req_t reqrsp_req;
  reqrsp_rsp_t reqrsp_rsp;

  axi_to_reqrsp #(
    .axi_req_t (axi_req_t),
    .axi_rsp_t (axi_rsp_t),
    .AddrWidth (AddrWidth),
    .DataWidth (DataWidth),
    .IdWidth (IdWidth),
    .BufDepth (BufDepth),
    .reqrsp_req_t (reqrsp_req_t),
    .reqrsp_rsp_t (reqrsp_rsp_t)
  ) i_axi_to_reqrsp (
    .clk_i (clk_i),
    .rst_ni (rst_ni),
    .busy_o (/* open */),
    .axi_req_i (axi_req_i),
    .axi_rsp_o (axi_rsp_o),
    .reqrsp_req_o (reqrsp_req),
    .reqrsp_rsp_i (reqrsp_rsp)
  );

  reqrsp_to_tcdm #(
    .AddrWidth (AddrWidth),
    .DataWidth (DataWidth),
    .BufDepth (BufDepth),
    .reqrsp_req_t (reqrsp_req_t),
    .reqrsp_rsp_t (reqrsp_rsp_t),
    .tcdm_req_t (tcdm_req_t),
    .tcdm_rsp_t (tcdm_rsp_t)
  ) i_reqrsp_to_tcdm (
    .clk_i (clk_i),
    .rst_ni (rst_ni),
    .reqrsp_req_i (reqrsp_req),
    .reqrsp_rsp_o (reqrsp_rsp),
    .tcdm_req_o (tcdm_req_o),
    .tcdm_rsp_i (tcdm_rsp_i)
  );

endmodule
