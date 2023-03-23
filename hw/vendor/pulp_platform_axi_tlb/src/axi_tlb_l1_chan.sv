// Copyright 2018-2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Andreas Kurth <akurth@iis.ee.ethz.ch>
// Author: Paul Scheffler <paulsc@iis.ee.ethz.ch>

/// Internal module of [`axi_tlb_l1`](module.axi_tlb_l1): Channel handler.
module axi_tlb_l1_chan #(
  /// Number of entries in translation table
  parameter int unsigned NumEntries = 0,
  /// Is this channel is used for writes?
  parameter logic IsWriteChannel = 1'b0,
  /// Type of request address
  parameter type req_addr_t = logic,
  /// Type of a translation table entry
  parameter type entry_t = logic,
  /// Type of translation result
  parameter type res_t = logic
) (
  /// Rising-edge clock
  input  logic                    clk_i,
  /// Asynchronous reset, active low
  input  logic                    rst_ni,
  /// Test mode enable
  input  logic                    test_en_i,
  /// Translation table entries
  input  entry_t [NumEntries-1:0] entries_i,
  /// Whether TLB is bypassed (no translation)
  input logic                     bypass_i,
  /// Request address
  input  req_addr_t               req_addr_i,
  /// Request valid
  input  logic                    req_valid_i,
  /// Request ready
  output logic                    req_ready_o,
  /// Translation result
  output res_t                    res_o,
  /// Translation result valid
  output logic                    res_valid_o,
  /// Translation result ready
  input  logic                    res_ready_i
);

  localparam int unsigned EntryIdxWidth = NumEntries > 1 ? $clog2(NumEntries) : 1;

  typedef logic [EntryIdxWidth-1:0] entry_idx_t;

  // Determine all entries matching a request.
  logic [NumEntries-1:0] entry_matches;
  for (genvar i = 0; i < NumEntries; i++) begin : gen_matches
    assign entry_matches[i] = entries_i[i].valid & req_valid_i
        & ((req_addr_i >> 12) >= entries_i[i].first)
        & ((req_addr_i >> 12) <= entries_i[i].last)
        & (~IsWriteChannel | ~entries_i[i].read_only);
  end

  // Determine entry with lowest index that matches the request.
  entry_idx_t match_idx;
  logic       no_match;
  lzc #(
    .WIDTH  ( NumEntries  ),
    .MODE   ( 1'b0        )   // trailing zeros -> lowest match
  ) i_lzc (
    .in_i     ( entry_matches ),
    .cnt_o    ( match_idx     ),
    .empty_o  ( no_match      )
  );

  // Handle request and translate address.
  logic res_valid, res_ready;
  res_t res;
  always_comb begin
    res_valid = 1'b0;
    req_ready_o = 1'b0;
    res = '{default: '0};
    if (bypass_i) begin
      // In bypass mode, we always "hit" with the original address
      res = '{hit: 1'b1, addr: req_addr_i};
      res_valid = req_valid_i;
      req_ready_o = res_ready;
    end else if (req_valid_i) begin
      if (no_match) begin
        res = '{default: '0};
      end else begin
        res.hit = 1'b1;
        res.addr = {(
          ((req_addr_i >> 12) - entries_i[match_idx].first) + entries_i[match_idx].base
        ), req_addr_i[11:0]};
      end
      res_valid = 1'b1;
      req_ready_o = res_ready;
    end
  end
  // Store translation in fall-through register.  This prevents changes in the translated address
  // due to changes in `entries_i` while downstream handshake is outstanding.
  fall_through_register #(
    .T  ( res_t )
  ) i_res_ft_reg (
    .clk_i,
    .rst_ni,
    .clr_i      ( 1'b0        ),
    .testmode_i ( test_en_i   ),
    .valid_i    ( res_valid   ),
    .ready_o    ( res_ready   ),
    .data_i     ( res         ),
    .valid_o    ( res_valid_o ),
    .ready_i    ( res_ready_i ),
    .data_o     ( res_o       )
  );

endmodule
