// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>

/// TCDM Interface.
interface TCDM_BUS #(
  /// The width of the address.
  parameter int  ADDR_WIDTH = -1,
  /// The width of the data.
  parameter int  DATA_WIDTH = -1,
  /// Additional user payload on the `q` channel.
  parameter type user_t  = logic
);

  import reqrsp_pkg::*;

  localparam int unsigned StrbWidth = DATA_WIDTH / 8;

  typedef logic [ADDR_WIDTH-1:0] addr_t;
  typedef logic [DATA_WIDTH-1:0] data_t;
  typedef logic [StrbWidth-1:0] strb_t;
  /// The request channel (Q).
  addr_t   q_addr;
  /// 0 = read, 1 = write, 1 = amo fetch-and-op
  logic    q_write;
  amo_op_e q_amo;
  data_t   q_data;
  /// Byte-wise strobe
  strb_t   q_strb;
  user_t   q_user;
  logic    q_valid;
  logic    q_ready;

  /// The response channel (P).
  data_t   p_data;
  logic    p_valid;

  modport in  (
    input  q_addr, q_write, q_amo, q_user, q_data, q_strb, q_valid,
    output q_ready, p_data, p_valid
  );
  modport out (
    output q_addr, q_write, q_amo, q_user, q_data, q_strb, q_valid,
    input  q_ready, p_data, p_valid
  );
  modport monitor (
    input q_addr, q_write, q_amo, q_user, q_data, q_strb, q_valid,
          q_ready, p_data, p_valid
  );

endinterface

/// TCDM Interface for verficiation purposes.
interface TCDM_BUS_DV #(
  /// The width of the address.
  parameter int  ADDR_WIDTH = -1,
  /// The width of the data.
  parameter int  DATA_WIDTH = -1,
  /// Additional user payload on the `q` channel.
  parameter type user_t  = logic
) (
  input logic clk_i
);

  import reqrsp_pkg::*;

  localparam int unsigned StrbWidth = DATA_WIDTH / 8;

  typedef logic [ADDR_WIDTH-1:0] addr_t;
  typedef logic [DATA_WIDTH-1:0] data_t;
  typedef logic [StrbWidth-1:0] strb_t;
  /// The request channel (Q).
  addr_t   q_addr;
  /// 0 = read, 1 = write, 1 = amo fetch-and-op
  logic    q_write;
  amo_op_e q_amo;
  data_t   q_data;
  /// Byte-wise strobe
  strb_t   q_strb;
  user_t   q_user;
  logic    q_valid;
  logic    q_ready;

  /// The response channel (P).
  data_t   p_data;
  logic    p_valid;

  modport in  (
    input  q_addr, q_write, q_amo, q_user, q_data, q_strb, q_valid,
    output q_ready, p_data, p_valid
  );
  modport out (
    output q_addr, q_write, q_amo, q_user, q_data, q_strb, q_valid,
    input  q_ready, p_data, p_valid
  );
  modport monitor (
    input q_addr, q_write, q_amo, q_user, q_data, q_strb, q_valid,
          q_ready, p_data, p_valid
  );

  // pragma translate_off
  `ifndef VERILATOR
  assert property (@(posedge clk_i) (q_valid && !q_ready |=> $stable(q_addr)));
  assert property (@(posedge clk_i) (q_valid && !q_ready |=> $stable(q_write)));
  assert property (@(posedge clk_i) (q_valid && !q_ready |=> $stable(q_amo)));
  assert property (@(posedge clk_i) (q_valid && !q_ready && q_write |=> $stable(q_data)));
  assert property (@(posedge clk_i) (q_valid && !q_ready && q_write |=> $stable(q_strb)));
  assert property (@(posedge clk_i) (q_valid && !q_ready |=> $stable(q_user)));
  assert property (@(posedge clk_i) (q_valid && !q_ready |=> q_valid));
  `endif
  // pragma translate_on

endinterface
