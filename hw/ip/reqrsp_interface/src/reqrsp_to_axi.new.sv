// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// AUthor: Florian Zaruba <zarubaf@iis.ee.ethz.ch>

`include "common_cells/registers.svh"
`include "common_cells/assertions.svh"

/// Convert reqrsp to AXI.
///
/// Two things make this module a bit more special:
/// 1. We need to be carfule with the memory model: AXI does not imply any
///    ordering between the read and the write channel. On the other hand the
///    reqrsp protocol does (implicitely because everything is in issue order).
/// 2. Atomic memory operations are supported and they are a bit quirky in the
///    AXI5 standard. In particular the kid of break the assumption that every
///    `AW` implies excactly one `B` because the read data is also returned on
///    the `R` channel.
///
/// ## Memory Ordering
///
/// 1. Atomics need to block and wait until the ID becomes available again.
/// 2. Reads can go after reads, AXI will maintain the ordering.
/// 3. Similarly, writes can go after writes, AXI will also maintain the
///    ordering there.
///
/// This has the drawback that we are overly conservative when only
/// point-to-point ordering is needed. In the future one can implement two
/// regions: (i) one where the ordering between reads and writs is point to
/// point (ii) one where the ordering is strong as it is currently the case.
/// That would also mean that we would need to keep a FIFO width the arbitration
/// decisions so that we can route the response from the correct channel.
///
/// ## Complexity
///
/// The module just needs to save the amount of transactions which are currently
/// in-flight. This parameter is bound by `MAX_TRANS` and O(log2(MAX_TRANS)))
/// storage complexity is needed.
///
/// This module does not emit any bursts, but AXI5 capability is needed because
/// of the atomic memory operations.
module reqrsp_to_axi import reqrsp_pkg::*; #(
  /// Number of same transactions which can be in-flight
  /// simulatnously.
  parameter int unsigned MAX_TRANS = 4,
  /// ID with which to send the transactions.
  parameter int unsigned ID = 0,
  /// Data width of bus, must be 32 or 64.
  parameter int unsigned DATA_WIDTH = 32'b0,
  parameter type reqrsp_req_t = logic,
  parameter type reqrsp_rsp_t = logic,
  parameter type axi_req_t = logic,
  parameter type axi_rsp_t = logic
) (
  input  logic clk_i,
  input  logic rst_ni,
  input  reqrsp_req_t reqrsp_req_i,
  output reqrsp_rsp_t reqrsp_rsp_o,
  output axi_req_t axi_req_o,
  input  axi_rsp_t axi_rsp_i
);

  localparam int unsigned CounterWidth = cf_math_pkg::idx_width(MAX_TRANS);
  typedef logic [CounterWidth-1:0] cnt_t;
  logic atomic_in_flight_d, atomic_in_flight_q;
  cnt_t read_cnt_d, read_cnt_q;
  cnt_t write_cnt_d, write_cnt_q;
  logic [DATA_WIDTH-1:0] write_data;

  logic q_valid, q_ready;
  logic q_valid_read, q_ready_read;
  logic q_valid_write, q_ready_write;

  // Globally no new transactions can be accepted if there is an unresolved
  // atomic transactions and per channel we can not accept new transaction iff:
  // - The other channel has in-flight transactions (we can't garuantee the ordering).
  // - The counter would overflow.
  always_comb begin
    q_valid = reqrsp_req_i.q_valid;
    reqrsp_rsp_o.q_ready = q_ready;

    if (atomic_in_flight_q
      || (reqrsp_req_i.q.write && (write_cnt_q == MAX_TRANS-1 || read_cnt_d != 0))
      || (!reqrsp_req_i.q.write && (read_cnt_q == MAX_TRANS-1 || write_cnt_d != 0))) begin
      q_valid = 1'b0;
      reqrsp_rsp_o.q_ready = 1'b0;
    end
  end

  assign q_valid_read = q_valid & ~reqrsp_req_i.q.write;
  assign q_valid_write = q_valid & reqrsp_req_i.q.write;
  assign q_ready = (q_valid_read & q_ready_read) | (q_valid_write & q_ready_write);

  // Count the number of in-fligh reads.
  `FF(read_cnt_q, read_cnt_d, '0)
  // Count the number of in-fligh writes.
  `FF(write_cnt_q, write_cnt_d, '0)
  `FF(atomic_in_flight_q, atomic_in_flight_d, '0)

  always_comb begin
    atomic_in_flight_d = atomic_in_flight_q;
    read_cnt_d = read_cnt_q;
    write_cnt_d = write_cnt_q;

    if (reqrsp_req_i.q_valid && reqrsp_rsp_o.q_ready) begin
        // Set atomic in-flight flag if we sent an atomic.
        if (reqrsp_req_i.q.amo inside
          {AMOSwap, AMOAdd, AMOAnd, AMOOr,
           AMOXor, AMOMax, AMOMaxu, AMOMin, AMOMinu}) begin
          atomic_in_flight_d = 1'b1;
          read_cnt_d++;
        end

        if (!reqrsp_req_i.q.write) read_cnt_d++;
        else write_cnt_d++;
    end
    // Reset atomic in-flight flag.
    if (read_cnt_d == 0 && write_cnt_d == 0) begin
      atomic_in_flight_d = 1'b0;
    end
    // Decrement the write counter again when the signals arrived.
    if (axi_rsp_i.r_valid && axi_req_o.r_ready) read_cnt_d--;
    if (axi_rsp_i.b_valid && axi_req_o.b_ready) write_cnt_d--;
  end

  // -------------
  // Read Channel
  // -------------

  // AXI read bus assignment.
  assign axi_req_o.ar.addr   = reqrsp_req_i.q.addr;
  assign axi_req_o.ar.size   = {1'b0, reqrsp_req_i.q.size};
  assign axi_req_o.ar.burst  = axi_pkg::BURST_INCR;
  assign axi_req_o.ar.lock   = (reqrsp_req_i.q.amo == AMOLR);
  assign axi_req_o.ar.cache  = axi_pkg::CACHE_MODIFIABLE;
  assign axi_req_o.ar.id     = $unsigned(ID);
  assign axi_req_o.ar_valid  = q_valid_read;
  assign q_ready_read        = axi_rsp_i.ar_ready;

  // -------------
  // Write Channel
  // -------------

  // AXI write bus assignment.
  assign axi_req_o.aw.addr   = reqrsp_req_i.q.addr;
  assign axi_req_o.aw.size   = {1'b0, reqrsp_req_i.q.size};
  assign axi_req_o.aw.burst  = axi_pkg::BURST_INCR;
  assign axi_req_o.aw.lock   = (reqrsp_req_i.q.amo == AMOSC);
  assign axi_req_o.aw.cache  = axi_pkg::CACHE_MODIFIABLE;
  assign axi_req_o.aw.id     = $unsigned(ID);
  assign axi_req_o.w.data    = write_data;
  assign axi_req_o.w.strb    = reqrsp_req_i.q.strb;
  assign axi_req_o.w.last    = 1'b1;

  // Both channels need to handshake (independently).
  stream_fork #(
    .N_OUP (2)
  ) i_stream_fork (
    .clk_i,
    .rst_ni,
    .valid_i (q_valid_write),
    .ready_o (q_write_read),
    .valid_o ({axi_req_o.aw_valid, axi_req_o.w_valid}),
    .ready_i ({axi_rsp_i.aw_ready, axi_rsp_i.w_ready})
  );

  always_comb begin
    write_data = reqrsp_req_i.q.data;
    axi_req_o.aw.atop = '0;
    unique case (reqrsp_req_i.q.amo)
      // RISC-V atops have a load semantic
      AMOSwap: axi_req_o.aw.atop  = axi_pkg::ATOP_ATOMICSWAP;
      AMOAdd: axi_req_o.aw.atop = {
          axi_pkg::ATOP_ATOMICLOAD, axi_pkg::ATOP_LITTLE_END, axi_pkg::ATOP_ADD
        };
      AMOAnd: begin
        // in this case we need to invert the data to get a "CLR"
        write_data = ~reqrsp_req_i.q.data;
        axi_req_o.aw.atop = {
            axi_pkg::ATOP_ATOMICLOAD, axi_pkg::ATOP_LITTLE_END, axi_pkg::ATOP_CLR
          };
      end
      AMOOr:  axi_req_o.aw.atop = {
                axi_pkg::ATOP_ATOMICLOAD, axi_pkg::ATOP_LITTLE_END, axi_pkg::ATOP_SET
              };
      AMOXor: axi_req_o.aw.atop = {
                axi_pkg::ATOP_ATOMICLOAD, axi_pkg::ATOP_LITTLE_END, axi_pkg::ATOP_EOR
              };
      AMOMax: axi_req_o.aw.atop = {
                axi_pkg::ATOP_ATOMICLOAD, axi_pkg::ATOP_LITTLE_END, axi_pkg::ATOP_SMAX
              };
      AMOMaxu:axi_req_o.aw.atop = {
                axi_pkg::ATOP_ATOMICLOAD, axi_pkg::ATOP_LITTLE_END, axi_pkg::ATOP_UMAX
              };
      AMOMin: axi_req_o.aw.atop = {
                axi_pkg::ATOP_ATOMICLOAD, axi_pkg::ATOP_LITTLE_END, axi_pkg::ATOP_SMIN
              };
      AMOMinu:  axi_req_o.aw.atop = {
                  axi_pkg::ATOP_ATOMICLOAD, axi_pkg::ATOP_LITTLE_END, axi_pkg::ATOP_UMIN
                };
      default:;
    endcase
  end

  // -----------
  // Return Path
  // -----------

  // As we can never have two read and write transactions in-flight (except for
  // atomics) simultanously return path arbitration becomes quite an simply an
  // `or` between `r` and `b` channel.
  assign reqrsp_rsp_o.p.error = (axi_rsp_i.r_valid & axi_rsp_i.r.resp[1])
                              | (axi_rsp_i.b_valid & axi_rsp_i.b.resp[1]);

  // In case we have an atomic instruction in-flight we don't pass on the
  // b channel as we are just interested in the read data. The logic in this
  // module will make sure that we only issue new instructions if the atomic has
  // been fully resolved.
  assign reqrsp_rsp_o.p_valid = axi_rsp_i.r_valid | (~atomic_in_flight_q & axi_rsp_i.b_valid);
  assign axi_req_o.r_ready = reqrsp_req_i.p_ready & axi_rsp_i.r_valid;
  assign axi_req_o.b_ready = (reqrsp_req_i.p_ready | atomic_in_flight_q) & axi_rsp_i.b_valid;

  always begin
    reqrsp_rsp_o.p.data = '0;
    if (axi_rsp_i.r_valid) reqrsp_rsp_o.p.data = axi_rsp_i.r.data;
    // In case we got a B response and this wasn't an atomic, let's check
    // if we need to signal an `exclusive error`
    if (axi_rsp_i.b_valid && ~atomic_in_flight_q && axi_rsp_i.b.resp != axi_pkg::RESP_EXOKAY) begin
      reqrsp_rsp_o.p.data = 1;
    end
  end

  // AXI auxiliary signal
  assign axi_req_o.aw.len = '0;
  assign axi_req_o.aw.user = '0;
  assign axi_req_o.aw.qos = 4'b0;
  assign axi_req_o.aw.prot = 3'b0;
  assign axi_req_o.aw.region = 4'b0;
  assign axi_req_o.ar.len    = '0;
  assign axi_req_o.ar.user = '0;
  assign axi_req_o.ar.qos = 4'b0;
  assign axi_req_o.ar.prot = 3'b0;
  assign axi_req_o.ar.region = 4'b0;
  assign axi_req_o.w.user = '0;

  // Assertions:
  // Check that the data width is in the range of 32 or 64 bit. We didn't define
  // any other bus widths so far.
  `ASSERT_INIT(check_data_width, DATA_WIDTH inside {32, 64})
  // 1. Assert that the in-flight counters are never both 2+ == 2+, that would
  //    imply an illegal state.

endmodule

`include "reqrsp_interface/typedef.svh"
`include "reqrsp_interface/assign.svh"
`include "axi/typedef.svh"
`include "axi/assign.svh"

module reqrsp_to_axi_intf #(
  /// ID width which to send the transactions.
  parameter int unsigned ID = 0,
  /// AXI ID width.
  parameter int unsigned AXI_ID_WIDTH = 32'd0,
  /// AXI and REQRSP address width.
  parameter int unsigned ADDR_WIDTH = 32'd0,
  /// AXI and REQRSP data width.
  parameter int unsigned DATA_WIDTH = 32'd0,
  /// AXI user width.
  parameter int unsigned AXI_USER_WIDTH = 32'd0
) (
  input logic clk_i,
  input logic rst_ni,
  REQRSP_BUS  reqrsp,
  AXI_BUS     axi
);

  typedef logic [ADDR_WIDTH-1:0] addr_t;
  typedef logic [DATA_WIDTH-1:0] data_t;
  typedef logic [DATA_WIDTH/8-1:0] strb_t;
  typedef logic [AXI_ID_WIDTH-1:0] id_t;
  typedef logic [AXI_USER_WIDTH-1:0] user_t;

  `REQRSP_BUS_TYPEDEF_ALL(reqrsp, addr_t, data_t, strb_t)

  `AXI_TYPEDEF_AW_CHAN_T(aw_chan_t, addr_t, id_t, user_t)
  `AXI_TYPEDEF_W_CHAN_T(w_chan_t, data_t, strb_t, user_t)
  `AXI_TYPEDEF_B_CHAN_T(b_chan_t, id_t, user_t)
  `AXI_TYPEDEF_AR_CHAN_T(ar_chan_t, addr_t, id_t, user_t)
  `AXI_TYPEDEF_R_CHAN_T(r_chan_t, data_t, id_t, user_t)

  `AXI_TYPEDEF_REQ_T(axi_req_t, aw_chan_t, w_chan_t, ar_chan_t)
  `AXI_TYPEDEF_RESP_T(axi_rsp_t, b_chan_t, r_chan_t)

  reqrsp_req_t reqrsp_req;
  reqrsp_rsp_t reqrsp_rsp;

  axi_req_t axi_req;
  axi_rsp_t axi_rsp;

  reqrsp_to_axi #(
    .DATA_WIDTH ( DATA_WIDTH ),
    .reqrsp_req_t (reqrsp_req_t),
    .reqrsp_rsp_t (reqrsp_rsp_t),
    .axi_req_t (axi_req_t),
    .axi_rsp_t (axi_rsp_t)
  ) i_reqrsp_to_axi (
    .clk_i,
    .rst_ni,
    .reqrsp_req_i (reqrsp_req),
    .reqrsp_rsp_o (reqrsp_rsp),
    .axi_req_o (axi_req),
    .axi_rsp_i (axi_rsp)
  );

  // assign q.
  // assign q_valid
  // assign p_ready
  `REQRSP_ASSIGN_TO_REQ(reqrsp_req, reqrsp)

  // assign p.
  // assign p_valid
  // assign q_ready
  `REQRSP_ASSIGN_FROM_RESP(reqrsp, reqrsp_rsp)

  `AXI_ASSIGN_FROM_REQ(axi, axi_req)
  `AXI_ASSIGN_TO_RESP(axi_rsp, axi)

endmodule
