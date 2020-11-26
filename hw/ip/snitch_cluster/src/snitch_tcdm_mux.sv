// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

/// Description: Mux between the DMA and the interconnect. 1 DMA access
/// occupies N banks.

/// Author: Thomas Benz <tbenz@ethz.ch>

module snitch_tcdm_mux #(
    parameter int unsigned AddrMemWidth      = -1,
    parameter int unsigned BanksPerSuperbank = -1,
    parameter int unsigned DataWidth         = -1,
    parameter int unsigned DMADataWidth      = -1
) (

    input logic clk_i,
    input logic rst_i,

    // interconnect side
    /// Bank request
    input  logic                [BanksPerSuperbank-1:0]                   ic_req_i,
    /// Bank grant
    output logic                [BanksPerSuperbank-1:0]                   ic_gnt_o,
    /// Address
    input  logic                [BanksPerSuperbank-1:0][AddrMemWidth-1:0] ic_add_i,
    /// Atomic Memory Operation
    input  snitch_pkg::amo_op_t [BanksPerSuperbank-1:0]                   ic_amo_i,
    /// 1: Store, 0: Load
    input  logic                [BanksPerSuperbank-1:0]                   ic_wen_i,
    /// Write data
    input  logic                [BanksPerSuperbank-1:0][   DataWidth-1:0] ic_wdata_i,
    /// Byte enable
    input  logic                [BanksPerSuperbank-1:0][ DataWidth/8-1:0] ic_be_i,
    /// Read data
    output logic                [BanksPerSuperbank-1:0][   DataWidth-1:0] ic_rdata_o,
    // dma side
    /// Bank request
    input  logic                                                          dma_req_i,
    /// Bank grant
    output logic                                                          dma_gnt_o,
    /// Address
    input  logic                [     AddrMemWidth-1:0]                   dma_add_i,
    /// Atomic Memory Operation
    input  snitch_pkg::amo_op_t                                           dma_amo_i,
    /// 1: Store, 0: Load
    input  logic                                                          dma_wen_i,
    /// Write data
    input  logic                [     DMADataWidth-1:0]                   dma_wdata_i,
    /// Byte enable
    input  logic                [   DMADataWidth/8-1:0]                   dma_be_i,
    /// Read data
    output logic                [     DMADataWidth-1:0]                   dma_rdata_o,

    // to memory/amo ports
    output logic [BanksPerSuperbank-1:0] amo_req_o,  // Bank request
    input logic [BanksPerSuperbank-1:0] amo_gnt_i,  // Bank grant
    output logic [BanksPerSuperbank-1:0][AddrMemWidth-1:0] amo_add_o,  // Address
    output snitch_pkg::amo_op_t [BanksPerSuperbank-1:0] amo_amo_o,  // Atomic Memory Operation
    output logic [BanksPerSuperbank-1:0] amo_wen_o,  // 1: Store, 0: Load
    output logic [BanksPerSuperbank-1:0][DataWidth-1:0] amo_wdata_o,  // Write data
    output logic [BanksPerSuperbank-1:0][DataWidth/8-1:0] amo_be_o,  // Byte enable
    input logic [BanksPerSuperbank-1:0][DataWidth-1:0] amo_rdata_i,  // Read data

    // general inputs
    input logic sel_dma_i  // 0: use ic port, 1: use dma port
);

  // response is always delayed:
  logic sel_dma_q;

  // forwards channel DMA to memory.
  always_comb begin : proc_tcdm_mux
    // default -> feed trough ic requests
    ic_gnt_o    = amo_gnt_i;
    amo_req_o   = ic_req_i;
    amo_add_o   = ic_add_i;
    amo_amo_o   = ic_amo_i;
    amo_wen_o   = ic_wen_i;
    amo_wdata_o = ic_wdata_i;
    amo_be_o    = ic_be_i;

    // tie dma gnt port to 0
    dma_gnt_o   = 'b0;

    if (sel_dma_i) begin
      // block access from tcdm
      ic_gnt_o    = 'b0;
      amo_req_o   = {{BanksPerSuperbank} {dma_req_i}};
      amo_add_o   = {{BanksPerSuperbank} {dma_add_i}};
      amo_amo_o   = {{BanksPerSuperbank} {dma_amo_i}};
      amo_wen_o   = {{BanksPerSuperbank} {dma_wen_i}};
      amo_wdata_o = dma_wdata_i;
      amo_be_o    = dma_be_i;

      // we need permission from all banks
      dma_gnt_o   = 1'b1;
      for (int i = 0; i < BanksPerSuperbank; i++) begin
        dma_gnt_o = dma_gnt_o & amo_gnt_i;
      end
    end
  end

  // backwards channel memory to DMA, this will be one cycle delayed.
  always_comb begin : proc_tcdm_mux_backwards_channel
    // default: get response from DMA
    ic_rdata_o  = amo_rdata_i;
    dma_rdata_o = 'b0;

    // dma did last request -> get now the response
    if (sel_dma_q) begin
      ic_rdata_o  = 'b0;
      dma_rdata_o = amo_rdata_i;
    end
  end

  // delay dma accesses by one for the response channel
  always_ff @(posedge clk_i) begin : proc_delay_dma_sel
    if (rst_i) begin
      sel_dma_q <= 1'b0;
    end else begin
      sel_dma_q <= sel_dma_i;
    end
  end

endmodule : snitch_tcdm_mux
