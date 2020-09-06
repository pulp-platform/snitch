// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Fabian Schuiki <fschuiki@iis.ee.ethz.ch>

/// A simple two channel interface.
///
/// This interface provides two channels, one for requests and one for
/// responses. Both channels have a valid/ready handshake. The sender sets the
/// channel signals and pulls valid high. Once pulled high, valid must remain
/// high and none of the signals may change. The transaction completes when both
/// valid and ready are high. Valid must not depend on ready. The master can
/// request a read or write on the `q` channel. The slave responds on the `p`
/// channel once the action has been completed.
/// Every transaction returns a response. For write transaction the datum
/// on the response channel is invalid. For read and atomic transaction the
/// value corresponds to the un-modified value (the value read before an
/// operation was performed).
interface REQRSP_BUS import reqrsp_pkg::*; #(
  /// The width of the address.
  parameter int ADDR_WIDTH = -1,
  /// The width of the data.
  parameter int DATA_WIDTH = -1,
  /// The width of the ID.
  parameter int ID_WIDTH = -1
);
  typedef logic [AXI_ID_WIDTH-1:0]   id_t;
  typedef logic [AXI_ADDR_WIDTH-1:0] addr_t;
  typedef logic [AXI_DATA_WIDTH-1:0] data_t;
  typedef logic [AXI_STRB_WIDTH-1:0] strb_t;
  // The request channel (Q).
  addr_t   q_addr;
  logic    q_write; // 0=read, 1=write
  amo_op_e q_amo;
  data_t   q_data;
  strb_t   q_strb;  // byte-wise strobe
  size_t   q_size;
  logic    q_valid;
  logic    q_ready;

  // The response channel (P).
  data_t   p_data;
  logic    p_error; // 0=ok, 1=error
  logic    p_valid;
  logic    p_ready;

  modport in  (
    input  q_addr, q_write, q_amo, q_size, q_data, q_strb, q_valid, p_ready,
    output q_ready, p_data, p_error, p_valid);
  modport out (
    output q_addr, q_write, q_amo, q_size, q_data, q_strb, q_valid, p_ready,
    input  q_ready, p_data, p_error, p_valid);

endinterface

// The DV interface additionally caries a clock signal.
interface REQRSP_BUS_DV import reqrsp_pkg::*; #(
  /// The width of the address.
  parameter int ADDR_WIDTH = -1,
  /// The width of the data.
  parameter int DATA_WIDTH = -1,
  /// The width of the ID.
  parameter int ID_WIDTH = -1
)(
  input logic clk_i
);
  typedef logic [AXI_ID_WIDTH-1:0]   id_t;
  typedef logic [AXI_ADDR_WIDTH-1:0] addr_t;
  typedef logic [AXI_DATA_WIDTH-1:0] data_t;
  typedef logic [AXI_STRB_WIDTH-1:0] strb_t;
  // The request channel (Q).
  addr_t   q_addr;
  logic    q_write; // 0=read, 1=write
  amo_op_e q_amo;
  data_t   q_data;
  strb_t   q_strb;  // byte-wise strobe
  size_t   q_size;
  logic    q_valid;
  logic    q_ready;

  // The response channel (P).
  data_t   p_data;
  logic    p_error; // 0=ok, 1=error
  logic    p_valid;
  logic    p_ready;

  modport in  (
    input  q_addr, q_write, q_amo, q_size, q_data, q_strb, q_valid, p_ready,
    output q_ready, p_data, p_error, p_valid);
  modport out (
    output q_addr, q_write, q_amo, q_size, q_data, q_strb, q_valid, p_ready,
    input  q_ready, p_data, p_error, p_valid);

endinterface
