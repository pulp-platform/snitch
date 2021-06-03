// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>

/// Load Store Unit (can handle `NumOutstandingLoads` outstanding loads and
/// `NumOutstandingMem` requests in total) and optionally NaNBox if used in a
/// floating-point setting. It expects its memory sub-system to keep order (as if
/// issued with a single ID).
module snitch_lsu #(
  parameter int unsigned AddrWidth           = 32,
  parameter int unsigned DataWidth           = 32,
  /// Tag passed from input to output. All transactions are in-order.
  parameter type tag_t                       = logic [4:0],
  /// Number of outstanding memory transactions.
  parameter int unsigned NumOutstandingMem   = 1,
  /// Number of outstanding loads.
  parameter int unsigned NumOutstandingLoads = 1,
  /// Whether to NaN Box values. Used for floating-point load/stores.
  parameter bit          NaNBox              = 0,
  parameter type         dreq_t              = logic,
  parameter type         drsp_t              = logic,
  /// Derived parameter *Do not override*
  parameter type addr_t = logic [AddrWidth-1:0],
  parameter type data_t = logic [DataWidth-1:0]
) (
  input  logic                 clk_i,
  input  logic                 rst_i,
  // request channel
  input  tag_t                 lsu_qtag_i,
  input  logic                 lsu_qwrite_i,
  input  logic                 lsu_qsigned_i,
  input  addr_t                lsu_qaddr_i,
  input  data_t                lsu_qdata_i,
  input  logic [1:0]           lsu_qsize_i,
  input  reqrsp_pkg::amo_op_e  lsu_qamo_i,
  input  logic                 lsu_qvalid_i,
  output logic                 lsu_qready_o,
  // response channel
  output data_t                lsu_pdata_o,
  output tag_t                 lsu_ptag_o,
  output logic                 lsu_perror_o,
  output logic                 lsu_pvalid_o,
  input  logic                 lsu_pready_i,
  /// High if there is currently no transaction pending.
  output logic                 lsu_empty_o,
  // Memory Interface Channel
  output dreq_t                data_req_o,
  input  drsp_t                data_rsp_i
);

  localparam int unsigned DataAlign = $clog2(DataWidth/8);
  logic [63:0] ld_result;
  logic [63:0] lsu_qdata, data_qdata;

  typedef struct packed {
    tag_t                  tag;
    logic                  sign_ext;
    logic [DataAlign-1:0] offset;
    logic [1:0]            size;
  } laq_t;

  // Load Address Queue (LAQ)
  laq_t laq_in, laq_out;
  logic mem_out;
  logic laq_full, mem_full;
  logic laq_push;

  fifo_v3 #(
    .FALL_THROUGH ( 1'b0                ),
    .DEPTH        ( NumOutstandingLoads ),
    .dtype        ( laq_t               )
  ) i_fifo_laq (
    .clk_i,
    .rst_ni (~rst_i),
    .flush_i (1'b0),
    .testmode_i(1'b0),
    .full_o (laq_full),
    .empty_o (/* open */),
    .usage_o (/* open */),
    .data_i (laq_in),
    .push_i (laq_push),
    .data_o (laq_out),
    .pop_i (data_rsp_i.p_valid & data_req_o.p_ready & ~mem_out)
  );

  // For each memory transaction save whether this was a load or a store. We
  // need this information to suppress stores.
  fifo_v3 #(
    .FALL_THROUGH (1'b0),
    .DEPTH (NumOutstandingMem),
    .DATA_WIDTH (1)
  ) i_fifo_mem (
    .clk_i,
    .rst_ni (~rst_i),
    .flush_i (1'b0),
    .testmode_i (1'b0),
    .full_o (mem_full),
    .empty_o (lsu_empty_o),
    .usage_o ( /* open */ ),
    .data_i (lsu_qwrite_i),
    .push_i (data_req_o.q_valid & data_rsp_i.q_ready),
    .data_o (mem_out),
    .pop_i (data_rsp_i.p_valid & data_req_o.p_ready)
  );

  assign laq_in = '{
    tag:      lsu_qtag_i,
    sign_ext: lsu_qsigned_i,
    offset:   lsu_qaddr_i[DataAlign-1:0],
    size:     lsu_qsize_i
  };

  // Only make a request when we got a valid request and if it is a load also
  // check that we can actually store the necessary information to process it in
  // the upcoming cycle(s).
  assign data_req_o.q_valid = lsu_qvalid_i & (lsu_qwrite_i | ~laq_full) & ~mem_full;
  assign data_req_o.q.write = lsu_qwrite_i;
  assign data_req_o.q.addr = lsu_qaddr_i;
  assign data_req_o.q.amo  = lsu_qamo_i;
  assign data_req_o.q.size = lsu_qsize_i;

  // Generate byte enable mask.
  always_comb begin
    unique case (lsu_qsize_i)
      2'b00: data_req_o.q.strb = ('b1 << lsu_qaddr_i[DataAlign-1:0]);
      2'b01: data_req_o.q.strb = ('b11 << lsu_qaddr_i[DataAlign-1:0]);
      2'b10: data_req_o.q.strb = ('b1111 << lsu_qaddr_i[DataAlign-1:0]);
      2'b11: data_req_o.q.strb = '1;
      default: data_req_o.q.strb = '0;
    endcase
  end

  // Re-align write data.
  /* verilator lint_off WIDTH */
  assign lsu_qdata = $unsigned(lsu_qdata_i);
  always_comb begin
    unique case (lsu_qaddr_i[DataAlign-1:0])
      3'b000: data_qdata = lsu_qdata;
      3'b001: data_qdata = {lsu_qdata[55:0], lsu_qdata[63:56]};
      3'b010: data_qdata = {lsu_qdata[47:0], lsu_qdata[63:48]};
      3'b011: data_qdata = {lsu_qdata[39:0], lsu_qdata[63:40]};
      3'b100: data_qdata = {lsu_qdata[31:0], lsu_qdata[63:32]};
      3'b101: data_qdata = {lsu_qdata[23:0], lsu_qdata[63:24]};
      3'b110: data_qdata = {lsu_qdata[15:0], lsu_qdata[63:16]};
      3'b111: data_qdata = {lsu_qdata[7:0],  lsu_qdata[63:8]};
      default: data_qdata = lsu_qdata;
    endcase
  end
  assign data_req_o.q.data = data_qdata[DataWidth-1:0];
  /* verilator lint_on WIDTH */

  // The interface didn't accept our request yet
  assign lsu_qready_o = ~(data_req_o.q_valid & ~data_rsp_i.q_ready)
                      & (lsu_qwrite_i | ~laq_full) & ~mem_full;
  assign laq_push = ~lsu_qwrite_i & data_rsp_i.q_ready & data_req_o.q_valid & ~laq_full;

  // Return Path
  // shift the load data back
  logic [63:0] shifted_data;
  assign shifted_data = data_rsp_i.p.data >> {laq_out.offset, 3'b000};
  always_comb begin
    unique case (laq_out.size)
      2'b00: ld_result = {{56{shifted_data[7] & laq_out.sign_ext}}, shifted_data[7:0]};
      2'b01: ld_result = {{48{shifted_data[15] & laq_out.sign_ext}}, shifted_data[15:0]};
      2'b10: ld_result = {{32{(shifted_data[31] | NaNBox) & laq_out.sign_ext}}, shifted_data[31:0]};
      2'b11: ld_result = shifted_data;
      default: ld_result = shifted_data;
    endcase
  end

  assign lsu_perror_o = data_rsp_i.p.error;
  assign lsu_pdata_o = ld_result[DataWidth-1:0];
  assign lsu_ptag_o = laq_out.tag;
  // In case of a write, don't signal a valid transaction. Stores are always
  // without ans answer to the core.
  assign lsu_pvalid_o = data_rsp_i.p_valid & ~mem_out;
  assign data_req_o.p_ready = lsu_pready_i | mem_out;

endmodule
