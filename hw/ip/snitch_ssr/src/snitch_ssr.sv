// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Fabian Schuiki <fschuiki@iis.ee.ethz.ch>

module snitch_ssr import snitch_pkg::*; #(
  parameter int unsigned AddrWidth = 0,
  parameter int unsigned DataWidth = 0,
  parameter int unsigned SSRNrCredits = 0,
  parameter type tcdm_req_t = logic,
  parameter type tcdm_rsp_t = logic,
  /// Derived parameter *Do not override*
  parameter type addr_t = logic [AddrWidth-1:0],
  parameter type data_t = logic [DataWidth-1:0]
) (
  input  logic        clk_i,
  input  logic        rst_ni,
  // Access to configuration registers (REG_BUS).
  input  logic  [4:0] cfg_word_i,
  input  logic        cfg_write_i,  // 0 = read, 1 = write
  output logic [31:0] cfg_rdata_o,
  input  logic [31:0] cfg_wdata_i,
  // Register lanes from switch.
  output data_t       lane_rdata_o,
  input  data_t       lane_wdata_i,
  output logic        lane_valid_o,
  input  logic        lane_ready_i,
  // Ports into memory.
  output tcdm_req_t   mem_req_o,
  input  tcdm_rsp_t   mem_rsp_i,

  input  addr_t       tcdm_start_address_i
);

  data_t fifo_out, fifo_in;
  logic fifo_push, fifo_pop, fifo_full, fifo_empty;
  logic mover_valid;
  logic [$clog2(SSRNrCredits):0] credit_q;
  logic has_credit, credit_take, credit_give;
  logic [3:0] rep_max, rep_q, rep_done, rep_enable;

  fifo_v3 #(
    .FALL_THROUGH ( 0           ),
    .DATA_WIDTH   ( DataWidth   ),
    .DEPTH        ( SSRNrCredits )
  ) i_fifo (
    .clk_i,
    .rst_ni,
    .testmode_i ( 1'b0       ),
    .flush_i    ( '0         ),
    .full_o     ( fifo_full  ),
    .empty_o    ( fifo_empty ),
    .usage_o    (            ),
    .data_i     ( fifo_in    ),
    .push_i     ( fifo_push  ),
    .data_o     ( fifo_out   ),
    .pop_i      ( fifo_pop   )
  );

  logic mem_req_qvalid;

  // TODO: indirection integration

  snitch_ssr_addr_gen #(
    .Indirection      ( 0           ),
    .IndirOutSpill    ( 0           ),
    .AddrWidth        ( AddrWidth   ),
    .DataWidth        ( DataWidth   ),
    .NumIndexCredits  ( 4           ),
    .tcdm_req_t       ( tcdm_req_t  ),
    .tcdm_rsp_t       ( tcdm_rsp_t  ),
    .tcdm_user_t      ( logic       )
  ) i_addr_gen (
    .clk_i,
    .rst_ni,
    .idx_req_o      (  ),
    .idx_rsp_i      ( '0 ),
    .cfg_word_i,
    .cfg_rdata_o,
    .cfg_wdata_i,
    .cfg_write_i,
    .reg_rep_o      ( rep_max                     ),
    .mem_addr_o     ( mem_req_o.q.addr            ),
    .mem_write_o    ( mem_req_o.q.write           ),
    .mem_valid_o    ( mover_valid                 ),
    .mem_ready_i    ( mem_req_qvalid & mem_rsp_i.q_ready ),
    .tcdm_start_address_i
  );

  assign mem_req_o.q_valid = mem_req_qvalid;
  assign mem_req_o.q.amo = reqrsp_pkg::AMONone;
  assign mem_req_o.q.user = '0;

  assign lane_rdata_o = fifo_out;
  assign mem_req_o.q.data = fifo_out;
  assign mem_req_o.q.strb = '1;

  always_comb begin
    if (mem_req_o.q.write) begin
      lane_valid_o = ~fifo_full;
      mem_req_qvalid = mover_valid & ~fifo_empty;
      fifo_push = lane_ready_i & ~fifo_full;
      fifo_in = lane_wdata_i;
      rep_enable = 0;
      fifo_pop = mem_req_qvalid & mem_rsp_i.q_ready;
      credit_take = fifo_push;
      credit_give = mem_rsp_i.p_valid;
    end else begin
      lane_valid_o = ~fifo_empty;
      mem_req_qvalid = mover_valid & ~fifo_full & has_credit;
      fifo_push = mem_rsp_i.p_valid;
      fifo_in = mem_rsp_i.p.data;
      rep_enable = lane_ready_i & ~fifo_empty;
      fifo_pop = rep_enable & rep_done;
      credit_take = mem_req_qvalid & mem_rsp_i.q_ready;
      credit_give = fifo_pop;
    end
  end

  // Credit counter that keeps track of the number of memory requests issued
  // to ensure that the FIFO does not overfill.
  always_ff @(posedge clk_i, negedge rst_ni) begin
    if (!rst_ni)
      credit_q <= SSRNrCredits;
    else if (credit_take & ~credit_give)
      credit_q <= credit_q - 1;
    else if (!credit_take & credit_give)
      credit_q <= credit_q + 1;
  end
  assign has_credit = (credit_q != '0);

  // Repetition counter.
  always_ff @(posedge clk_i, negedge rst_ni) begin
    if (!rst_ni)
      rep_q <= '0;
    else if (rep_enable)
      rep_q <= rep_done ? '0 : rep_q + 1;
  end
  assign rep_done = (rep_q == rep_max);

endmodule
