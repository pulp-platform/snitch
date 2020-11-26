// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Snitch DMA address decoder
// groups a number of banks in the TCDM to superbanks. One superbank can be served by the DMA
// in one cycle.

/// Author: Thomas Benz <tbenz@ethz.ch>

module snitch_dma_addr_decoder #(
  parameter int unsigned TCDMAddrWidth     = -1,
  parameter int unsigned DMAAddrWidth      = -1,
  parameter int unsigned BanksPerSuperbank = -1,
  parameter int unsigned NrSuperBanks      = -1,
  parameter int unsigned DMADataWidth      = -1,
  parameter int unsigned MemoryLatency     = -1
) (

  input   logic                                           clk_i,
  input   logic                                           rst_i,

  // single port towards dma
  /// Bank request
  input   logic                                           dma_req_i,
  /// Bank grant
  output  logic                                           dma_gnt_o,
  /// Address
  input   logic                   [DMAAddrWidth-1:0   ]   dma_add_i,
  /// Atomic Memory Operation
  input   snitch_pkg::amo_op_t                            dma_amo_i,
  /// 1: Store, 0: Load
  input   logic                                           dma_wen_i,
  /// Write data
  input   logic                   [DMADataWidth-1:0   ]   dma_wdata_i,
  /// Byte enable
  input   logic                   [DMADataWidth/8-1:0 ]   dma_be_i,
  /// Read data
  output  logic                   [DMADataWidth-1:0   ]   dma_rdata_o,
  // dma side
  /// Bank request
  output  logic [NrSuperBanks-1:0]                        super_bank_req_o,
  /// Bank grant
  input   logic [NrSuperBanks-1:0]                        super_bank_gnt_i,
  /// Address
  output  logic [NrSuperBanks-1:0][TCDMAddrWidth-1:0  ]   super_bank_add_o,
  /// Atomic Memory Operation
  output  snitch_pkg::amo_op_t [NrSuperBanks-1:0]         super_bank_amo_o,
  /// 1: Store, 0: Load
  output  logic [NrSuperBanks-1:0]                        super_bank_wen_o,
  /// Write data
  output  logic [NrSuperBanks-1:0][DMADataWidth-1:0   ]   super_bank_wdata_o,
  /// Byte enable
  output  logic [NrSuperBanks-1:0][DMADataWidth/8-1:0 ]   super_bank_be_o,
  /// Read data
  input   logic [NrSuperBanks-1:0][DMADataWidth-1:0   ]   super_bank_rdata_i
);

  localparam int unsigned SBWidth           = $clog2(NrSuperBanks);
  localparam int unsigned DMADataWidthBytes = DMADataWidth / 8;
  localparam int unsigned NumBitsDMATrans   = $clog2(DMADataWidthBytes); // example case: 6

  // case for 512 bits, 32 banks, 4 superbanks, 1024 words per bank, 256kiB, 64bit system
  // 31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00
  // 00000000000000000000000000000000000000000|-----------------------------|-----|--------|--------|
  // zero or ignored                            tcdm line address            superbank      byte in bank
  //                                                                               subbank

  localparam int unsigned TCDMUpper = SBWidth + NumBitsDMATrans + TCDMAddrWidth;

  // super bank address
  logic [SBWidth-1:0]                    super_bank;
  logic [TCDMAddrWidth-1:0]              tcdm_line_address;
  // have to keep the last choosen bank to correctly route response (rdata back)
  // the memory can have a parametrizable amount of delay.
  logic [MemoryLatency-1:0][SBWidth-1:0] super_bank_q;

  // divide the address
  assign super_bank        = SBWidth > 0 ? (dma_add_i >> NumBitsDMATrans) : '0;
  assign tcdm_line_address = (dma_add_i >> (TCDMUpper-TCDMAddrWidth));


  // create the mux inthe forward and backwords direction
  always_comb begin : proc_dma_addr_decoder

    // unused ports are set to 0
    super_bank_req_o   = '0;
    super_bank_add_o   = '0;
    super_bank_amo_o   = snitch_pkg::AMONone;
    super_bank_wen_o   = '0;
    super_bank_wdata_o = '0;
    super_bank_be_o    = '0;

    // mux
    super_bank_req_o   [super_bank] = dma_req_i;
    super_bank_add_o   [super_bank] = tcdm_line_address;
    super_bank_amo_o   [super_bank] = dma_amo_i;
    super_bank_wen_o   [super_bank] = dma_wen_i;
    super_bank_wdata_o [super_bank] = dma_wdata_i;
    super_bank_be_o    [super_bank] = dma_be_i;

    dma_gnt_o                       = super_bank_gnt_i   [super_bank];

    // backwards path has be delayed by one, as memory has one cycle latency
    dma_rdata_o                     = super_bank_rdata_i [super_bank_q[MemoryLatency-1]];

  end

  always_ff @(posedge clk_i or posedge rst_i) begin : proc_delay_bank_choice
    if (rst_i) begin
       super_bank_q<= 0;
    end else begin
      super_bank_q[0] <= super_bank;
      // implement the shift for the delay
      for (int i = 1; i < MemoryLatency; i++) begin
        super_bank_q[i] <= super_bank_q[i-1];
      end
    end
  end

endmodule : snitch_dma_addr_decoder
