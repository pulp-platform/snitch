// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Nils Wistoff <nwistoff@iis.ee.ethz.ch>

module reg_to_apb #(
  /// Regbus request struct type.
  parameter type reg_req_t = logic,
  /// Regbus response struct type.
  parameter type reg_rsp_t = logic,
  /// APB request struct type.
  parameter type apb_req_t = logic,
  /// APB response type.
  parameter type apb_rsp_t = logic
)
(
  input  logic     clk_i,
  input  logic     rst_ni,

  // Register interface
  input  reg_req_t reg_req_i,
  output reg_rsp_t reg_rsp_o,

  // APB interface
  output apb_req_t apb_req_o,
  input  apb_rsp_t apb_rsp_i
);

  assign apb_req_o.paddr   = reg_req_i.addr;
  assign apb_req_o.pwrite  = reg_req_i.write;
  assign apb_req_o.pwdata  = reg_req_i.wdata;
  assign apb_req_o.psel    = reg_req_i.valid;
  assign apb_req_o.penable = reg_req_i.valid;
  assign apb_req_o.pstrb   = reg_req_i.wstrb;
  assign apb_req_o.pprot   = 3'b010;            // 0: unprivileged, 1: non-secure, 0: data

  assign reg_rsp_o.ready   = apb_rsp_i.pready;
  assign reg_rsp_o.error   = apb_rsp_i.pslverr;
  assign reg_rsp_o.rdata   = apb_rsp_i.prdata;

endmodule
