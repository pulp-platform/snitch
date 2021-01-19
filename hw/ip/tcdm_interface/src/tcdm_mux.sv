// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

`include "tcdm_interface/typedef.svh"

/// Multiplex `NrPorts` TCDM interfaces onto one.
module tcdm_mux #(
  parameter int unsigned NrPorts = 2,
  parameter int unsigned AddrWidth = 0,
  parameter int unsigned DataWidth = 0,
  parameter type user_t = logic,
  parameter int unsigned RespDepth = 8,
  parameter type tcdm_req_t = logic,
  parameter type tcdm_rsp_t = logic
) (
  input  logic                    clk_i,
  input  logic                    rst_ni,
  input  tcdm_req_t [NrPorts-1:0] slv_req_i,
  output tcdm_rsp_t [NrPorts-1:0] slv_rsp_o,
  output tcdm_req_t               mst_req_o,
  input  tcdm_rsp_t               mst_rsp_i
);

  localparam int unsigned SelectWidth = cf_math_pkg::idx_width(NrPorts);
  typedef logic [SelectWidth-1:0] select_t;

  typedef logic [AddrWidth-1:0] addr_t;
  typedef logic [DataWidth-1:0] data_t;
  typedef logic [DataWidth/8-1:0] strb_t;

  `TCDM_TYPEDEF_REQ_CHAN_T(tcdm_req_chan_t, addr_t, data_t, strb_t, user_t)

  if (NrPorts > 1) begin : gen_mux
    logic [NrPorts-1:0] slv_req_valid, slv_req_ready;
    tcdm_req_chan_t [NrPorts-1:0] slv_req;
    logic rr_valid, rr_ready;
    logic fifo_valid, fifo_ready;
    select_t fifo_in_select, fifo_out_select;

    for (genvar i = 0; i < NrPorts; i++) begin : gen_flat_valid_ready
      assign slv_req_valid[i] = slv_req_i[i].q_valid;
      assign slv_req[i] = slv_req_i[i].q;
      // Response
      assign slv_rsp_o[i].q_ready = slv_req_ready[i];
      assign slv_rsp_o[i].p.data = mst_rsp_i.p.data;
      assign slv_rsp_o[i].p_valid = (i == fifo_out_select) & mst_rsp_i.p_valid;
    end

    /// Arbitrate on instruction request port
    rr_arb_tree #(
      .NumIn (NrPorts),
      .DataType (tcdm_req_chan_t),
      .AxiVldRdy (1'b1),
      .LockIn (1'b1)
    ) i_q_mux (
      .clk_i (clk_i),
      .rst_ni (rst_ni),
      .flush_i (1'b0),
      .rr_i  ('0),
      .req_i (slv_req_valid),
      .gnt_o (slv_req_ready),
      .data_i (slv_req),
      .req_o (rr_valid),
      .gnt_i (rr_ready),
      .data_o (mst_req_o.q),
      .idx_o (fifo_in_select)
    );

    stream_fork #(
      .N_OUP (2)
    ) i_stream_fork (
      .clk_i (clk_i),
      .rst_ni (rst_ni),
      .valid_i (rr_valid),
      .ready_o (rr_ready),
      .valid_o ({fifo_valid, mst_req_o.q_valid}),
      .ready_i ({fifo_ready, mst_rsp_i.q_ready})
    );

    stream_fifo #(
      .FALL_THROUGH (1'b0),
      .DEPTH (RespDepth),
      .T (select_t)
    ) i_stream_fifo (
      .clk_i,
      .rst_ni,
      .flush_i (1'b0),
      .testmode_i (1'b0),
      .usage_o (),
      .data_i (fifo_in_select),
      .valid_i (fifo_valid),
      .ready_o (fifo_ready),
      .data_o (fifo_out_select),
      .valid_o (),
      .ready_i (mst_rsp_i.p_valid)
    );
  end else begin : gen_no_mux
    assign mst_req_o = slv_req_i;
    assign slv_rsp_o = mst_rsp_i;
  end

endmodule

`include "tcdm_interface/typedef.svh"
`include "tcdm_interface/assign.svh"

/// Interface wrapper.
module tcdm_mux_intf #(
  parameter int unsigned NrPorts = 2,
  parameter int unsigned AddrWidth = 0,
  parameter int unsigned DataWidth = 0,
  parameter type         user_t    = logic,
  parameter int unsigned RespDepth = 8
) (
  input  logic                    clk_i,
  input  logic                    rst_ni,
  TCDM_BUS                        slv [NrPorts],
  TCDM_BUS                        mst
);

  typedef logic [AddrWidth-1:0] addr_t;
  typedef logic [DataWidth-1:0] data_t;
  typedef logic [DataWidth/8-1:0] strb_t;

  `TCDM_TYPEDEF_ALL(tcdm, addr_t, data_t, strb_t, user_t)

  tcdm_req_t [NrPorts-1:0] tcdm_slv_req;
  tcdm_rsp_t [NrPorts-1:0] tcdm_slv_rsp;

  tcdm_req_t tcdm_mst_req;
  tcdm_rsp_t tcdm_mst_rsp;

  tcdm_mux #(
    .NrPorts (NrPorts),
    .AddrWidth (AddrWidth),
    .DataWidth (DataWidth),
    .user_t (user_t),
    // TODO(zarubaf): Make parameter
    .RespDepth (RespDepth),
    .tcdm_req_t (tcdm_req_t),
    .tcdm_rsp_t (tcdm_rsp_t)
  ) i_tcdm_mux (
    .clk_i,
    .rst_ni,
    .slv_req_i (tcdm_slv_req),
    .slv_rsp_o (tcdm_slv_rsp),
    .mst_req_o (tcdm_mst_req),
    .mst_rsp_i (tcdm_mst_rsp)
  );

  for (genvar i = 0; i < NrPorts; i++) begin : gen_interface_assignment
    `TCDM_ASSIGN_TO_REQ(tcdm_slv_req[i], slv[i])
    `TCDM_ASSIGN_FROM_RESP(slv[i], tcdm_slv_rsp[i])
  end

  `TCDM_ASSIGN_FROM_REQ(mst, tcdm_mst_req)
  `TCDM_ASSIGN_TO_RESP(tcdm_mst_rsp, mst)

endmodule
