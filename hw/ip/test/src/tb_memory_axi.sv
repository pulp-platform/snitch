// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Fabian Schuiki <fschuiki@iis.ee.ethz.ch>
// Florian Zaruba <zarubaf@iis.ee.ethz.ch>

module tb_memory_axi #(
  /// AXI4+ATOP address width.
  parameter int unsigned AxiAddrWidth  = 0,
  /// AXI4+ATOP data width.
  parameter int unsigned AxiDataWidth  = 0,
  /// AXI4+ATOP ID width.
  parameter int unsigned AxiIdWidth  = 0,
  /// AXI4+ATOP User width.
  parameter int unsigned AxiUserWidth  = 0,
  /// Atomic memory support.
  parameter bit unsigned ATOPSupport = 1,
  parameter type req_t = logic,
  parameter type rsp_t = logic
)(
  input  logic clk_i,
  input  logic rst_ni,
  input  req_t req_i,
  output rsp_t rsp_o
);

  `include "axi/assign.svh"
  `include "axi/typedef.svh"

  `include "register_interface/typedef.svh"
  `include "register_interface/assign.svh"

  `include "common_cells/assertions.svh"

  localparam int NumBytes = AxiDataWidth/8;
  localparam int BusAlign = $clog2(NumBytes);

  REG_BUS #(
    .ADDR_WIDTH ( AxiAddrWidth ),
    .DATA_WIDTH ( AxiDataWidth )
  ) regb(clk_i);

  AXI_BUS #(
    .AXI_ADDR_WIDTH ( AxiAddrWidth ),
    .AXI_DATA_WIDTH ( AxiDataWidth ),
    .AXI_ID_WIDTH   ( AxiIdWidth   ),
    .AXI_USER_WIDTH ( AxiUserWidth )
  ) axi(),
    axi_wo_atomics(),
    axi_wo_atomics_cut();

  `AXI_ASSIGN_FROM_REQ(axi, req_i)
  `AXI_ASSIGN_TO_RESP(rsp_o, axi)

  // Filter atomic operations.
  if (ATOPSupport) begin : gen_atop_support
    axi_riscv_atomics_wrap #(
      .AXI_ADDR_WIDTH (AxiAddrWidth),
      .AXI_DATA_WIDTH (AxiDataWidth),
      .AXI_ID_WIDTH (AxiIdWidth),
      .AXI_USER_WIDTH (AxiUserWidth),
      .AXI_MAX_READ_TXNS (2),
      .AXI_MAX_WRITE_TXNS (2),
      .RISCV_WORD_WIDTH (32)
    ) i_axi_riscv_atomics_wrap (
      .clk_i (clk_i),
      .rst_ni (rst_ni),
      .slv (axi),
      .mst (axi_wo_atomics)
    );
  end else begin : gen_no_atop_support
    `AXI_ASSIGN(axi_wo_atomics, axi)
    `ASSERT(NoAtomicOperation, axi.aw_valid & axi.aw_ready |-> (axi.aw_atop == axi_pkg::ATOP_NONE))
  end

  // Ensure the AXI interface has not feedthrough signals.
  axi_cut_intf #(
    .BYPASS     (1'b0),
    .ADDR_WIDTH (AxiAddrWidth),
    .DATA_WIDTH (AxiDataWidth),
    .ID_WIDTH   (AxiIdWidth),
    .USER_WIDTH (AxiUserWidth)
  ) i_cut (
    .clk_i (clk_i),
    .rst_ni (rst_ni),
    .in (axi_wo_atomics),
    .out (axi_wo_atomics_cut)
  );

  // Convert AXI to a trivial register interface.
  axi_to_reg_intf #(
    .ADDR_WIDTH ( AxiAddrWidth ),
    .DATA_WIDTH ( AxiDataWidth ),
    .ID_WIDTH   ( AxiIdWidth   ),
    .USER_WIDTH ( AxiUserWidth ),
    .DECOUPLE_W ( 1            ),
    .AXI_MAX_WRITE_TXNS ( 32'd128 ),
    .AXI_MAX_READ_TXNS  ( 32'd128 )
  ) i_axi_to_reg (
    .clk_i,
    .rst_ni,
    .testmode_i ( 1'b0 ),
    .in         ( axi_wo_atomics_cut ),
    .reg_o      ( regb )
  );

  `REG_BUS_TYPEDEF_ALL(regbus,
    logic [AxiAddrWidth-1:0], logic [AxiDataWidth-1:0], logic [NumBytes-1:0])

  regbus_req_t regbus_req;
  regbus_rsp_t regbus_rsp;

  `REG_BUS_ASSIGN_TO_REQ(regbus_req, regb)
  `REG_BUS_ASSIGN_FROM_RSP(regb, regbus_rsp)

  tb_memory_regbus #(
    .AddrWidth (AxiAddrWidth),
    .DataWidth (AxiDataWidth),
    .req_t (regbus_req_t),
    .rsp_t (regbus_rsp_t)
  ) i_tb_memory_regbus (
    .clk_i,
    .rst_ni,
    .req_i (regbus_req),
    .rsp_o (regbus_rsp)
  );

endmodule
