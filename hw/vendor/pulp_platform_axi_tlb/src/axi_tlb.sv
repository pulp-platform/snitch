// Copyright 2018-2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Andreas Kurth <akurth@iis.ee.ethz.ch>
// Author: Paul Scheffler <paulsc@iis.ee.ethz.ch>

`include "axi_tlb/typedef.svh"

/// AXI4+ATOP Translation Lookaside Buffer (TLB) *with* integrated regfile.
/// Use this as a top level if you are happy with the included regfile.
module axi_tlb #(
  /// Address width of main AXI4+ATOP slave port
  parameter int unsigned AxiSlvPortAddrWidth = 0,
  /// Address width of main AXI4+ATOP master port
  parameter int unsigned AxiMstPortAddrWidth = 0,
  /// Data width of main AXI4+ATOP slave and master port
  parameter int unsigned AxiDataWidth = 0,
  /// ID width of main AXI4+ATOP slave and master port
  parameter int unsigned AxiIdWidth = 0,
  /// Width of user signal of main AXI4+ATOP slave and master port
  parameter int unsigned AxiUserWidth = 0,
  /// Maximum number of in-flight transactions on main AXI4+ATOP slave port
  parameter int unsigned AxiSlvPortMaxTxns = 0,
  /// Pipeline AW and AR channel after L1 TLB
  parameter bit L1CutAx = 1'b1,
  /// Request type of main AXI4+ATOP slave port
  parameter type slv_req_t = logic,
  /// Request type of main AXI4+ATOP master port
  parameter type mst_req_t = logic,
  /// Response type of main AXI4+ATOP slave and master ports
  parameter type axi_resp_t = logic,
  /// Request type for configuration register interface
  parameter type cfg_req_t = logic,
  /// Response type for configuration register interface
  parameter type cfg_rsp_t = logic
) (
  /// Rising-edge clock of all ports
  input  logic        clk_i,
  /// Asynchronous reset, active low
  input  logic        rst_ni,
  /// Test mode enable
  input  logic        test_en_i,
  /// Main slave port request
  input  slv_req_t    slv_req_i,
  /// Main slave port response
  output axi_resp_t   slv_resp_o,
  /// Main master port request
  output mst_req_t    mst_req_o,
  /// Main master port response
  input  axi_resp_t   mst_resp_i,
  /// Configuration port request
  input  cfg_req_t    cfg_req_i,
  /// Configuration port response
  output cfg_rsp_t    cfg_rsp_o
);

  typedef logic [$bits(mst_req_o.aw.addr)-12-1:0] oup_page_t;
  typedef logic [$bits(slv_req_i.aw.addr)-12-1:0] inp_page_t;

  `AXI_TLB_TYPEDEF_ALL(tlb, oup_page_t, inp_page_t)


 // Control registers
  axi_tlb_reg_pkg::axi_tlb_reg2hw_t reg2hw;

  axi_tlb_reg_top #(
    .reg_req_t  ( cfg_req_t ),
    .reg_rsp_t  ( cfg_rsp_t )
  ) i_axi_tlb_reg_top (
    .clk_i,
    .rst_ni,
    .reg_req_i  ( cfg_req_i ),
    .reg_rsp_o  ( cfg_rsp_o ),
    .reg2hw,
    .devmode_i  ( 1'b1 )
  );

  // Map to configuration inputs
  tlb_entry_t [7:0] entries;

  assign entries[0] = '{
    first:    {reg2hw.tlb_entry_0_pagein_first_high.q,  reg2hw.tlb_entry_0_pagein_first_low.q},
    last:     {reg2hw.tlb_entry_0_pagein_last_high.q,   reg2hw.tlb_entry_0_pagein_last_low.q},
    base:     {reg2hw.tlb_entry_0_pageout_high.q,       reg2hw.tlb_entry_0_pageout_low.q},
    valid:    reg2hw.tlb_entry_0_flags.valid.q,
    read_only: reg2hw.tlb_entry_0_flags.read_only.q
  };
  assign entries[1] = '{
    first:    {reg2hw.tlb_entry_1_pagein_first_high.q,  reg2hw.tlb_entry_1_pagein_first_low.q},
    last:     {reg2hw.tlb_entry_1_pagein_last_high.q,   reg2hw.tlb_entry_1_pagein_last_low.q},
    base:     {reg2hw.tlb_entry_1_pageout_high.q,       reg2hw.tlb_entry_1_pageout_low.q},
    valid:    reg2hw.tlb_entry_1_flags.valid.q,
    read_only: reg2hw.tlb_entry_1_flags.read_only.q
  };
  assign entries[2] = '{
    first:    {reg2hw.tlb_entry_2_pagein_first_high.q,  reg2hw.tlb_entry_2_pagein_first_low.q},
    last:     {reg2hw.tlb_entry_2_pagein_last_high.q,   reg2hw.tlb_entry_2_pagein_last_low.q},
    base:     {reg2hw.tlb_entry_2_pageout_high.q,       reg2hw.tlb_entry_2_pageout_low.q},
    valid:    reg2hw.tlb_entry_2_flags.valid.q,
    read_only: reg2hw.tlb_entry_2_flags.read_only.q
  };
  assign entries[3] = '{
    first:    {reg2hw.tlb_entry_3_pagein_first_high.q,  reg2hw.tlb_entry_3_pagein_first_low.q},
    last:     {reg2hw.tlb_entry_3_pagein_last_high.q,   reg2hw.tlb_entry_3_pagein_last_low.q},
    base:     {reg2hw.tlb_entry_3_pageout_high.q,       reg2hw.tlb_entry_3_pageout_low.q},
    valid:    reg2hw.tlb_entry_3_flags.valid.q,
    read_only: reg2hw.tlb_entry_3_flags.read_only.q
  };
  assign entries[4] = '{
    first:    {reg2hw.tlb_entry_4_pagein_first_high.q,  reg2hw.tlb_entry_4_pagein_first_low.q},
    last:     {reg2hw.tlb_entry_4_pagein_last_high.q,   reg2hw.tlb_entry_4_pagein_last_low.q},
    base:     {reg2hw.tlb_entry_4_pageout_high.q,       reg2hw.tlb_entry_4_pageout_low.q},
    valid:    reg2hw.tlb_entry_4_flags.valid.q,
    read_only: reg2hw.tlb_entry_4_flags.read_only.q
  };
  assign entries[5] = '{
    first:    {reg2hw.tlb_entry_5_pagein_first_high.q,  reg2hw.tlb_entry_5_pagein_first_low.q},
    last:     {reg2hw.tlb_entry_5_pagein_last_high.q,   reg2hw.tlb_entry_5_pagein_last_low.q},
    base:     {reg2hw.tlb_entry_5_pageout_high.q,       reg2hw.tlb_entry_5_pageout_low.q},
    valid:    reg2hw.tlb_entry_5_flags.valid.q,
    read_only: reg2hw.tlb_entry_5_flags.read_only.q
  };
  assign entries[6] = '{
    first:    {reg2hw.tlb_entry_6_pagein_first_high.q,  reg2hw.tlb_entry_6_pagein_first_low.q},
    last:     {reg2hw.tlb_entry_6_pagein_last_high.q,   reg2hw.tlb_entry_6_pagein_last_low.q},
    base:     {reg2hw.tlb_entry_6_pageout_high.q,       reg2hw.tlb_entry_6_pageout_low.q},
    valid:    reg2hw.tlb_entry_6_flags.valid.q,
    read_only: reg2hw.tlb_entry_6_flags.read_only.q
  };
  assign entries[7] = '{
    first:    {reg2hw.tlb_entry_7_pagein_first_high.q,  reg2hw.tlb_entry_7_pagein_first_low.q},
    last:     {reg2hw.tlb_entry_7_pagein_last_high.q,   reg2hw.tlb_entry_7_pagein_last_low.q},
    base:     {reg2hw.tlb_entry_7_pageout_high.q,       reg2hw.tlb_entry_7_pageout_low.q},
    valid:    reg2hw.tlb_entry_7_flags.valid.q,
    read_only: reg2hw.tlb_entry_7_flags.read_only.q
  };

  // Underlying TLB
  axi_tlb_noreg #(
    .AxiSlvPortAddrWidth  ( AxiSlvPortAddrWidth ),
    .AxiMstPortAddrWidth  ( AxiMstPortAddrWidth ),
    .AxiDataWidth         ( AxiDataWidth        ),
    .AxiIdWidth           ( AxiIdWidth          ),
    .AxiUserWidth         ( AxiUserWidth        ),
    .AxiSlvPortMaxTxns    ( AxiSlvPortMaxTxns   ),
    .L1NumEntries         ( 8      ),
    .L1CutAx              ( L1CutAx             ),
    .slv_req_t            ( slv_req_t           ),
    .mst_req_t            ( mst_req_t           ),
    .axi_resp_t           ( axi_resp_t          ),
    .entry_t              ( tlb_entry_t         )
  ) i_axi_tlb_noreg (
    .clk_i,
    .rst_ni,
    .test_en_i,
    .slv_req_i,
    .slv_resp_o,
    .mst_req_o,
    .mst_resp_i,
    .entries_i    ( entries ),
    .bypass_i     ( ~reg2hw.tlb_enable.q )
  );

endmodule

