// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Paul Scheffler <paulsc@iis.ee.ethz.ch>

`include "tcdm_interface/typedef.svh"
`include "tcdm_interface/assign.svh"

module fixture_ssr;

  // Timing parameters
  localparam time TCK = 10ns;
  localparam time TA  = 2ns;
  localparam time TT  = 8ns;
  localparam int unsigned RstCycles = 10;

  // TCDM parameters
  parameter int unsigned AddrWidth    = 64;
  parameter int unsigned DataWidth    = 32;
  parameter int unsigned SSRNrCredits = 4;

  // TCDM types
  typedef logic [AddrWidth-1:0]   addr_t;
  typedef logic [DataWidth-1:0]   data_t;
  typedef logic [DataWidth/8-1:0] strb_t;
  typedef logic                   user_t;
  `TCDM_TYPEDEF_ALL(tcdm, addr_t, data_t, strb_t, user_t);

  logic         clk_i;
  logic         rst_ni;
  logic [4:0]   cfg_word_i;
  logic         cfg_write_i;
  logic [31:0]  cfg_rdata_o;
  logic [31:0]  cfg_wdata_i;
  logic         lane_valid_o;
  logic         lane_ready_i;
  tcdm_req_t    mem_req_o;
  tcdm_rsp_t    mem_rsp_i;

  logic [DataWidth-1:0] lane_rdata_o;
  logic [DataWidth-1:0] lane_wdata_i;
  logic [AddrWidth-1:0] tcdm_start_address_i;

  clk_rst_gen #(
    .ClkPeriod    ( TCK       ),
    .RstClkCycles ( RstCycles )
  ) i_clk_rst_gen (
    .clk_o  ( clk_i  ),
    .rst_no ( rst_ni )
  );

  snitch_ssr #(
    .AddrWidth    ( AddrWidth    ),
    .DataWidth    ( DataWidth    ),
    .SSRNrCredits ( SSRNrCredits ),
    .tcdm_req_t   ( tcdm_req_t   ),
    .tcdm_rsp_t   ( tcdm_rsp_t   )
  ) i_snitch_ssr (
    .clk_i,
    .rst_ni,
    .cfg_word_i,
    .cfg_write_i,
    .cfg_rdata_o,
    .cfg_wdata_i,
    .lane_rdata_o,
    .lane_wdata_i,
    .lane_valid_o,
    .lane_ready_i,
    .mem_req_o,
    .mem_rsp_i,
    .tcdm_start_address_i
  );

endmodule
