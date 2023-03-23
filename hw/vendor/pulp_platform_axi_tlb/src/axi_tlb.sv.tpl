// Copyright 2018-2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Andreas Kurth <akurth@iis.ee.ethz.ch>
// Author: Paul Scheffler <paulsc@iis.ee.ethz.ch>

`include "axi_tlb/typedef.svh"

/// AXI4+ATOP Translation Lookaside Buffer (TLB) *with* integrated regfile.
/// Use this as a top level if you are happy with the included regfile.
module axi_${tlb_name} #(
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
  axi_${tlb_name}_reg_pkg::axi_${tlb_name}_reg2hw_t reg2hw;

  axi_${tlb_name}_reg_top #(
    .reg_req_t  ( cfg_req_t ),
    .reg_rsp_t  ( cfg_rsp_t )
  ) i_axi_${tlb_name}_reg_top (
    .clk_i,
    .rst_ni,
    .reg_req_i  ( cfg_req_i ),
    .reg_rsp_o  ( cfg_rsp_o ),
    .reg2hw,
    .devmode_i  ( 1'b1 )
  );

  // Map to configuration inputs
  tlb_entry_t [7:0] entries;

  % for j in range(num_entries):
  assign entries[${j}] = '{
    first:    {reg2hw.${tlb_name}_entry_${j}_pagein_first_high.q,  reg2hw.${tlb_name}_entry_${j}_pagein_first_low.q},
    last:     {reg2hw.${tlb_name}_entry_${j}_pagein_last_high.q,   reg2hw.${tlb_name}_entry_${j}_pagein_last_low.q},
    base:     {reg2hw.${tlb_name}_entry_${j}_pageout_high.q,       reg2hw.${tlb_name}_entry_${j}_pageout_low.q},
    valid:    reg2hw.${tlb_name}_entry_${j}_flags.valid.q,
    read_only: reg2hw.${tlb_name}_entry_${j}_flags.read_only.q
  };
  % endfor

  // Underlying TLB
  axi_tlb_noreg #(
    .AxiSlvPortAddrWidth  ( AxiSlvPortAddrWidth ),
    .AxiMstPortAddrWidth  ( AxiMstPortAddrWidth ),
    .AxiDataWidth         ( AxiDataWidth        ),
    .AxiIdWidth           ( AxiIdWidth          ),
    .AxiUserWidth         ( AxiUserWidth        ),
    .AxiSlvPortMaxTxns    ( AxiSlvPortMaxTxns   ),
    .L1NumEntries         ( ${num_entries}      ),
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
    .bypass_i     ( ~reg2hw.${tlb_name}_enable.q )
  );

endmodule
