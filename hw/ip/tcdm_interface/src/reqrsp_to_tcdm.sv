// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>

`include "reqrsp_interface/typedef.svh"

/// Convert from reqrsp to tcdm.
module reqrsp_to_tcdm #(
  parameter int unsigned AddrWidth  = 0,
  parameter int unsigned DataWidth  = 0,
  parameter int unsigned BufDepth = 2,
  parameter type reqrsp_req_t = logic,
  parameter type reqrsp_rsp_t = logic,
  parameter type tcdm_req_t = logic,
  parameter type tcdm_rsp_t = logic
) (
  input  logic        clk_i,
  input  logic        rst_ni,
  input  reqrsp_req_t reqrsp_req_i,
  output reqrsp_rsp_t reqrsp_rsp_o,
  output tcdm_req_t   tcdm_req_o,
  input  tcdm_rsp_t   tcdm_rsp_i
);

  typedef logic [AddrWidth-1:0] addr_t;
  typedef logic [DataWidth-1:0] data_t;
  typedef logic [DataWidth/8-1:0] strb_t;

  `REQRSP_TYPEDEF_ALL(rr, addr_t, data_t, strb_t)
  rr_req_chan_t req;
  rr_rsp_chan_t rsp;

  stream_to_mem #(
    .mem_req_t (rr_req_chan_t),
    .mem_resp_t (rr_rsp_chan_t),
    .BufDepth (BufDepth)
  ) i_stream_to_mem (
    .clk_i,
    .rst_ni,
    .req_i (reqrsp_req_i.q),
    .req_valid_i (reqrsp_req_i.q_valid),
    .req_ready_o (reqrsp_rsp_o.q_ready),
    .resp_o (reqrsp_rsp_o.p),
    .resp_valid_o (reqrsp_rsp_o.p_valid),
    .resp_ready_i (reqrsp_req_i.p_ready),
    .mem_req_o (req),
    .mem_req_valid_o (tcdm_req_o.q_valid),
    .mem_req_ready_i (tcdm_rsp_i.q_ready),
    .mem_resp_i (rsp),
    .mem_resp_valid_i (tcdm_rsp_i.p_valid)
  );

  assign tcdm_req_o.q = '{
    addr: req.addr,
    write: req.write,
    amo: req.amo,
    data: req.data,
    strb: req.strb,
    user: '0
  };

  assign rsp = '{
    data: tcdm_rsp_i.p.data,
    error: 1'b0
  };

endmodule

`include "reqrsp_interface/typedef.svh"
`include "reqrsp_interface/assign.svh"
`include "tcdm_interface/typedef.svh"
`include "tcdm_interface/assign.svh"

/// Interface wrapper.
module reqrsp_to_tcdm_intf #(
  parameter int unsigned AddrWidth  = 0,
  parameter int unsigned DataWidth  = 0,
  parameter type user_t             = logic,
  parameter int unsigned BufDepth = 2
) (
  input  logic        clk_i,
  input  logic        rst_ni,
  REQRSP_BUS          reqrsp,
  TCDM_BUS            tcdm
);

  typedef logic [AddrWidth-1:0] addr_t;
  typedef logic [DataWidth-1:0] data_t;
  typedef logic [DataWidth/8-1:0] strb_t;

  `REQRSP_TYPEDEF_ALL(reqrsp, addr_t, data_t, strb_t)
  `TCDM_TYPEDEF_ALL(tcdm, addr_t, data_t, strb_t, user_t)

  reqrsp_req_t reqrsp_req;
  reqrsp_rsp_t reqrsp_rsp;

  tcdm_req_t tcdm_req;
  tcdm_rsp_t tcdm_rsp;

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
    .tcdm_req_o (tcdm_req),
    .tcdm_rsp_i (tcdm_rsp)
  );

  `REQRSP_ASSIGN_TO_REQ(reqrsp_req, reqrsp)
  `REQRSP_ASSIGN_FROM_RESP(reqrsp, reqrsp_rsp)

  `TCDM_ASSIGN_FROM_REQ(tcdm, tcdm_req)
  `TCDM_ASSIGN_TO_RESP(tcdm_rsp, tcdm)

endmodule
