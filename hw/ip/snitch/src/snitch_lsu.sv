// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>
// Description: Load Store Unit (can handle `NumOutstandingLoads` outstanding loads) and
//              optionally NaNBox if used in a floating-point setting.
//              It expects its memory sub-system to keep order (as if issued with a single ID).
module snitch_lsu import snitch_pkg::*; #(
  parameter type tag_t                       = logic [4:0],
  parameter int unsigned NumOutstandingLoads = 1,
  parameter bit NaNBox                       = 0
) (
  input  logic       clk_i,
  input  logic       rst_i,
  // request channel
  input  tag_t       lsu_qtag_i,
  input  logic       lsu_qwrite,
  input  logic       lsu_qsigned,
  input  addr_t      lsu_qaddr_i,
  input  data_t      lsu_qdata_i,
  input  logic [1:0] lsu_qsize_i,
  input  amo_op_t    lsu_qamo_i,
  input  logic       lsu_qvalid_i,
  output logic       lsu_qready_o,
  // response channel
  output data_t      lsu_pdata_o,
  output tag_t       lsu_ptag_o,
  output logic       lsu_perror_o,
  output logic       lsu_pvalid_o,
  input  logic       lsu_pready_i,
  // Memory Interface Channel
  output addr_t      data_qaddr_o,
  output logic       data_qwrite_o,
  output amo_op_t    data_qamo_o,
  output data_t      data_qdata_o,
  output logic [1:0] data_qsize_o,
  output strb_t      data_qstrb_o,
  output logic       data_qvalid_o,
  input  logic       data_qready_i,
  input  data_t      data_pdata_i,
  input  logic       data_perror_i,
  input  logic       data_pvalid_i,
  output logic       data_pready_o
);

  logic [63:0] ld_result;
  logic [63:0] lsu_qdata, data_qdata;

  typedef struct packed {
    tag_t                  tag;
    logic                  sign_ext;
    logic [DATA_ALIGN-1:0] offset;
    logic [1:0]            size;
  } laq_t;

  // load adress queue (LAQ)
  laq_t laq_in, laq_out;
  logic laq_full;
  logic laq_push;

  fifo_v3 #(
    .FALL_THROUGH ( 1'b0                ),
    .DEPTH        ( NumOutstandingLoads ),
    .dtype        ( laq_t               )
  ) i_fifo_laq (
    .clk_i,
    .rst_ni    ( ~rst_i                        ),
    .flush_i   ( 1'b0                          ),
    .testmode_i( 1'b0                          ),
    .full_o    ( laq_full                      ),
    .empty_o   ( /* open */                    ),
    .usage_o   ( /* open */                    ),
    .data_i    ( laq_in                        ),
    .push_i    ( laq_push                      ),
    .data_o    ( laq_out                       ),
    .pop_i     ( data_pvalid_i & data_pready_o )
  );

  assign laq_in = '{
    tag:      lsu_qtag_i,
    sign_ext: lsu_qsigned,
    offset:   lsu_qaddr_i[DATA_ALIGN-1:0],
    size:     lsu_qsize_i
  };

  // only make a request when we got a valid request and if it is a load
  // also check that we can actuall store the necessary information to process
  // it in the upcoming cycle(s).
  assign data_qvalid_o = (lsu_qvalid_i) & (lsu_qwrite | ~laq_full);
  assign data_qwrite_o = lsu_qwrite;
  assign data_qaddr_o = lsu_qaddr_i;
  assign data_qamo_o  = lsu_qamo_i;
  assign data_qsize_o = lsu_qsize_i;
  // generate byte enable mask
  always_comb begin
    unique case (lsu_qsize_i)
      2'b00: data_qstrb_o = ('b1 << lsu_qaddr_i[DATA_ALIGN-1:0]);
      2'b01: data_qstrb_o = ('b11 << lsu_qaddr_i[DATA_ALIGN-1:0]);
      2'b10: data_qstrb_o = ('b1111 << lsu_qaddr_i[DATA_ALIGN-1:0]);
      2'b11: data_qstrb_o = '1;
      default: data_qstrb_o = '0;
    endcase
  end

  // re-align write data
  /* verilator lint_off WIDTH */
  assign lsu_qdata = $unsigned(lsu_qdata_i);
  always_comb begin
    unique case (lsu_qaddr_i[DATA_ALIGN-1:0])
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
  assign data_qdata_o = data_qdata[DLEN-1:0];
  /* verilator lint_on WIDTH */

  // the interface didn't accept our request yet
  assign lsu_qready_o = ~(data_qvalid_o & ~data_qready_i) & ~laq_full;
  assign laq_push = ~lsu_qwrite & data_qready_i & data_qvalid_o & ~laq_full;

  // Return Path
  // shift the load data back
  logic [63:0] shifted_data;
  assign shifted_data = data_pdata_i >> {laq_out.offset, 3'b000};
  always_comb begin
    unique case (laq_out.size)
      2'b00: ld_result = {{56{shifted_data[7] & laq_out.sign_ext}}, shifted_data[7:0]};
      2'b01: ld_result = {{48{shifted_data[15] & laq_out.sign_ext}}, shifted_data[15:0]};
      2'b10: ld_result = {{32{(shifted_data[31] | NaNBox) & laq_out.sign_ext}}, shifted_data[31:0]};
      2'b11: ld_result = shifted_data;
      default: ld_result = shifted_data;
    endcase
  end

  assign lsu_perror_o = data_perror_i;
  assign lsu_pdata_o = ld_result[DLEN-1:0];
  assign lsu_ptag_o = laq_out.tag;
  assign lsu_pvalid_o = data_pvalid_i;
  assign data_pready_o = lsu_pready_i;
endmodule
