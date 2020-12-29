// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Fabian Schuiki <fschuiki@iis.ee.ethz.ch>

module snitch_ssr_streamer import snitch_pkg::*; #(
  parameter int unsigned AddrWidth = 0,
  parameter int unsigned DataWidth = 0,
  parameter int unsigned SSRNrCredits = 0,
  parameter type tcdm_req_t = logic,
  parameter type tcdm_rsp_t = logic,
  /// Derived parameter *Do not override*
  parameter type addr_t = logic [AddrWidth-1:0],
  parameter type data_t = logic [DataWidth-1:0]
) (
  input  logic             clk_i,
  input  logic             rst_ni,
  // Access to configuration registers (REG_BUS).
  input  logic [11:0]      cfg_word_i,
  input  logic             cfg_write_i, // 0 = read, 1 = write
  output logic [31:0]      cfg_rdata_o,
  input  logic [31:0]      cfg_wdata_i,
  // Read and write streams coming from the processor.
  input  logic  [2:0][4:0] ssr_raddr_i,
  output data_t [2:0]      ssr_rdata_o,
  input  logic  [2:0]      ssr_rvalid_i,
  output logic  [2:0]      ssr_rready_o,
  input  logic  [2:0]      ssr_rdone_i,

  input  logic  [0:0][4:0] ssr_waddr_i,
  input  data_t [0:0]      ssr_wdata_i,
  input  logic  [0:0]      ssr_wvalid_i,
  output logic  [0:0]      ssr_wready_o,
  input  logic  [0:0]      ssr_wdone_i,
  // Ports into memory.
  output tcdm_req_t [2:0]  mem_req_o,
  input  tcdm_rsp_t [2:0]  mem_rsp_i,

  input  addr_t            tcdm_start_address_i
);

  data_t [2:0] lane_rdata;
  data_t [2:0] lane_wdata;
  logic  [2:0] lane_write;
  logic  [2:0] lane_valid;
  logic  [2:0] lane_ready;

  logic [4:0]       dmcfg_word;
  logic [2:0][31:0] dmcfg_rdata;
  logic [2:0]       dmcfg_strobe; // which data mover is currently addressed

  snitch_ssr_switch #(
    .DataWidth (DataWidth)
  ) i_switch (
    .clk_i,
    .rst_ni,
    .ssr_raddr_i,
    .ssr_rdata_o,
    .ssr_rvalid_i,
    .ssr_rready_o,
    .ssr_rdone_i,
    .ssr_waddr_i,
    .ssr_wdata_i,
    .ssr_wvalid_i,
    .ssr_wready_o,
    .ssr_wdone_i,
    .lane_rdata_i ( lane_rdata ),
    .lane_wdata_o ( lane_wdata ),
    .lane_write_o ( lane_write ),
    .lane_valid_i ( lane_valid ),
    .lane_ready_o ( lane_ready )
  );

  for (genvar i = 0; i < 3; i++) begin : gen_lane
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

    snitch_ssr_addr_gen #(
      .AddrWidth (AddrWidth)
    ) i_addr_gen (
      .clk_i,
      .rst_ni,
      .cfg_word_i     ( dmcfg_word                        ),
      .cfg_rdata_o    ( dmcfg_rdata[i]                    ),
      .cfg_wdata_i    ( cfg_wdata_i                       ),
      .cfg_write_i    ( cfg_write_i & dmcfg_strobe[i]     ),
      .reg_rep_o      ( rep_max                           ),
      .mem_addr_o     ( mem_req_o[i].q.addr               ),
      .mem_write_o    ( mem_req_o[i].q.write              ),
      .mem_valid_o    ( mover_valid                       ),
      .mem_ready_i    ( mem_req_qvalid & mem_rsp_i[i].q_ready ),
      .tcdm_start_address_i
    );

    assign mem_req_o[i].q_valid = mem_req_qvalid;
    assign mem_req_o[i].q.amo = reqrsp_pkg::AMONone;

    assign lane_rdata[i]  = fifo_out;
    assign mem_req_o[i].q.data = fifo_out;
    assign mem_req_o[i].q.strb = '1;

    always_comb begin
      if (mem_req_o[i].q.write) begin
        lane_valid[i] = ~fifo_full;
        mem_req_qvalid = mover_valid & ~fifo_empty;
        fifo_push = lane_ready[i] & ~fifo_full;
        fifo_in = lane_wdata[i];
        rep_enable = 0;
        fifo_pop = mem_req_qvalid & mem_rsp_i[i].q_ready;
        credit_take = fifo_push;
        credit_give = mem_rsp_i[i].p_valid;
      end else begin
        lane_valid[i] = ~fifo_empty;
        mem_req_qvalid = mover_valid & ~fifo_full & has_credit;
        fifo_push = mem_rsp_i[i].p_valid;
        fifo_in = mem_rsp_i[i].p.data;
        rep_enable = lane_ready[i] & ~fifo_empty;
        fifo_pop = rep_enable & rep_done;
        credit_take = mem_req_qvalid & mem_rsp_i[i].q_ready;
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
  end

  // Determine which data movers are addressed via the config interface. We
  // use the upper address bits to select one of the data movers, or select
  // all if the bits are all 1.
  always_comb begin
    logic [11:4] upper_addr;
    {upper_addr, dmcfg_word} = cfg_word_i;
    dmcfg_strobe = (upper_addr == '1 ? '1 : (1 << upper_addr));
    cfg_rdata_o = dmcfg_rdata[upper_addr];
  end

endmodule
