// Copyright 2018-2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Andreas Kurth <akurth@iis.ee.ethz.ch>
// Author: Paul Scheffler <paulsc@iis.ee.ethz.ch>

/// Internal module of [`axi_tlb`](module.axi_tlb): L1 translation table.
module axi_tlb_l1 #(
  /// Width of addresses in input address space
  parameter int unsigned InpAddrWidth = 0,
  /// Width of addresses in output address space
  parameter int unsigned OupAddrWidth = 0,
  /// Number of entries in translation table
  parameter int unsigned NumEntries = 0,
  /// Type of translation result.  Must have a single-bit field `hit` and an `addr` field as wide as
  /// the output address.
  parameter type res_t = logic,
  /// Type of page table entry
  parameter type entry_t = logic,
  /// Derived (=do not override) type of input addresses
  parameter type inp_addr_t = logic [InpAddrWidth-1:0],
  /// Derived (=do not override) type of output addresses
  parameter type oup_addr_t = logic [OupAddrWidth-1:0]
) (
  /// Rising-edge clock of all ports
  input  logic        clk_i,
  /// Asynchronous reset, active low
  input  logic        rst_ni,
  /// Test mode enable
  input  logic        test_en_i,
  /// Write request input address
  input  inp_addr_t   wr_req_addr_i,
  /// Write request valid
  input  logic        wr_req_valid_i,
  /// Write request ready
  output logic        wr_req_ready_o,
  /// Write translation result
  output res_t        wr_res_o,
  /// Write translation result valid
  output logic        wr_res_valid_o,
  /// Write translation result ready
  input  logic        wr_res_ready_i,
  /// Read request input address
  input  inp_addr_t   rd_req_addr_i,
  /// Read request valid
  input  logic        rd_req_valid_i,
  /// Read request ready
  output logic        rd_req_ready_o,
  /// Read translation result
  output res_t        rd_res_o,
  /// Read translation result valid
  output logic        rd_res_valid_o,
  /// Read translation result ready
  input  logic        rd_res_ready_i,
  /// Configured translation entries
  input  entry_t [NumEntries-1:0] entries_i,
  /// Whether TLB is bypassed (no translation)
  input logic         bypass_i
);

  // Write channel
  axi_tlb_l1_chan #(
    .NumEntries     ( NumEntries  ),
    .IsWriteChannel ( 1'b1        ),
    .req_addr_t     ( inp_addr_t  ),
    .entry_t        ( entry_t     ),
    .res_t          ( res_t       )
  ) i_wr_chan (
    .clk_i,
    .rst_ni,
    .test_en_i,
    .entries_i,
    .bypass_i,
    .req_addr_i   ( wr_req_addr_i   ),
    .req_valid_i  ( wr_req_valid_i  ),
    .req_ready_o  ( wr_req_ready_o  ),
    .res_o        ( wr_res_o        ),
    .res_valid_o  ( wr_res_valid_o  ),
    .res_ready_i  ( wr_res_ready_i  )
  );

  // Read channel
  axi_tlb_l1_chan #(
    .NumEntries     ( NumEntries  ),
    .IsWriteChannel ( 1'b0        ),
    .req_addr_t     ( inp_addr_t  ),
    .entry_t        ( entry_t     ),
    .res_t          ( res_t       )
  ) i_rd_chan (
    .clk_i,
    .rst_ni,
    .test_en_i,
    .entries_i,
    .bypass_i,
    .req_addr_i   ( rd_req_addr_i   ),
    .req_valid_i  ( rd_req_valid_i  ),
    .req_ready_o  ( rd_req_ready_o  ),
    .res_o        ( rd_res_o        ),
    .res_valid_o  ( rd_res_valid_o  ),
    .res_ready_i  ( rd_res_ready_i  )
  );

  `ifndef VERILATOR
  // pragma translate_off
  initial begin
    assert (InpAddrWidth > 12)
      else $fatal(1, "Input address space must be larger than one 4 KiB page!");
    assert (OupAddrWidth > 12)
      else $fatal(1, "Output address space must be larger than one 4 KiB page!");
  end
  // pragma translate_on
  `endif

endmodule
