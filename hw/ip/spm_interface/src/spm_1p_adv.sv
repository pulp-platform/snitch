// Copyright 2021 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Single-Port SRAM Wrapper with additional latency configuration options.
// Based on `lowRISC's prim_ram_1p_adv`
//
// Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>
`include "common_cells/assertions.svh"

module spm_1p_adv #(
  parameter  int NumWords             = 512,
  parameter  int DataWidth            = 32,
  /// Number of data bits per bit of write mask
  parameter  int ByteWidth            = 1,
  /// Simulation initialization
  // verilog_lint: waive explicit-parameter-storage-type
  parameter      SimInit              = "none",
  /// Print configuration
  parameter bit  PrintSimCfg          = 1'b0,
  /// Adds an input register (read latency +1)
  parameter  bit EnableInputPipeline  = 0,
  /// Adds an output register (read latency +1)
  parameter  bit EnableOutputPipeline = 0,
  /// Enables per-word ECC
  parameter  bit EnableECC            = 0,
  // DEPENDENT PARAMETERS, DO NOT OVERWRITE!
  parameter int unsigned AddrWidth = cf_math_pkg::idx_width(NumWords),
  parameter int unsigned BeWidth   = (DataWidth + ByteWidth - 32'd1) / ByteWidth, // ceil_div
  parameter type         parity_t  = logic [ecc_pkg::get_parity_width(DataWidth)-1:0],
  parameter type         addr_t    = logic [AddrWidth-1:0],
  parameter type         data_t    = logic [DataWidth-1:0],
  parameter type         be_t      = logic [BeWidth-1:0],
  /// Configuration input types for SRAMs used in implementation.
  parameter type sram_cfg_t = logic
) (
  input logic        clk_i,
  input logic        rst_ni,
  // input ports
  input  logic       valid_i,      // request
  output logic       ready_o,      // request granted
  input  logic       we_i,       // write enable
  input  addr_t      addr_i,     // request address
  input  data_t      wdata_i,    // write data
  input  be_t        be_i,       // write byte enable
  // output ports
  output data_t      rdata_o,    // read data
  /// Read- or write transaction is valid.
  output logic       rvalid_o,
  output logic [1:0] rerror_o,    // Bit1: Uncorrectable, Bit0: Correctable
  // SRAM configuration
  input  sram_cfg_t  sram_cfg_i
);

  // Calculate the true SPM data width (i.e., DW with optional ECC).
  localparam int unsigned SPMDataWidth = EnableECC ?
                                         (ecc_pkg::get_cw_width(DataWidth) + 1) : DataWidth;
  localparam int unsigned SPMBeWidth   = (SPMDataWidth + ByteWidth - 32'd1) / ByteWidth;

  typedef logic [SPMDataWidth-1:0] spm_data_t;
  typedef logic [SPMBeWidth-1:0] spm_be_t;

  logic       req_q,    req_d;
  logic       we_q,     we_d;
  addr_t      addr_q,   addr_d;
  spm_data_t  wdata_q,  wdata_d;
  spm_be_t    be_q,     be_d;
  logic       rvalid_q, rvalid_d, rvalid_sram_q;
  spm_data_t  rdata_q,  rdata_d;
  spm_data_t  rdata_sram;
  logic [1:0] rerror_q, rerror_d;

  ////////////////////
  // (Optional) ECC //
  ////////////////////

  typedef logic [ecc_pkg::get_cw_width(DataWidth)-1:0] code_word_t;
  typedef struct packed {
    logic parity;
    code_word_t code_word;
  } encoded_data_t;

  if (EnableECC) begin : gen_ecc
    logic single_error, parity_error, double_error;

    // Data without parity.
    data_t wdata_rmw, rdata_rmw;

    spm_rmw_adapter #(
      .AddrWidth (AddrWidth),
      .DataWidth (DataWidth),
      .StrbWidth (BeWidth),
      .MaxTxns (EnableInputPipeline + EnableOutputPipeline + 2)
    ) i_spm_rmw_adapter (
      .clk_i (clk_i),
      .rst_ni (rst_ni),
      .mem_valid_i (valid_i),
      .mem_ready_o (ready_o),
      .mem_addr_i (addr_i),
      .mem_wdata_i (wdata_i),
      .mem_strb_i (be_i),
      .mem_we_i (we_i),
      .mem_rvalid_o (rvalid_o),
      .mem_rdata_o (rdata_o),
      // Mem-side
      .mem_valid_o (req_d),
      .mem_ready_i (req_d),
      .mem_addr_o (addr_d),
      .mem_wdata_o (wdata_rmw),
      .mem_we_o (we_d),

      .mem_rvalid_i (rvalid_q),
      .mem_rdata_i (rdata_rmw)
    );

    assign be_d = '1;
    assign rerror_o = rerror_q | {double_error & rvalid_q, (single_error | parity_error) & rvalid_q};

    // Read-path, decode
    ecc_decode #(
      .DataWidth (DataWidth)
    ) i_ecc_decode (
      .data_i (rdata_q),
      .data_o (rdata_rmw),
      .syndrome_o (),
      .single_error_o (single_error),
      .parity_error_o (parity_error),
      .double_error_o (double_error)
    );

    // Write-path, encode
    ecc_encode #(
      .DataWidth (DataWidth)
    ) i_ecc_encode (
      .data_i (wdata_rmw),
      .data_o (wdata_d)
    );

    // Because of limitations in the RMW adapter the `ByteWidth` must be 8 bits.
    `ASSERT_INIT(BytWdith, ByteWidth == 8)

  end else begin : gen_no_ecc

    assign req_d    = valid_i;
    assign we_d     = we_i;
    assign be_d     = be_i;
    assign wdata_d  = wdata_i;
    assign addr_d   = addr_i;

    assign ready_o = valid_i;
    assign rvalid_o = rvalid_q;
    assign rdata_o  = rdata_q;
    assign rerror_o = rerror_q;
  end



  ////////////////////////////
  // RAM Primitive Instance //
  ////////////////////////////

  tc_sram #(
    .NumWords (NumWords),
    .DataWidth(SPMDataWidth),
    .ByteWidth(ByteWidth),
    .NumPorts (1),
    .SimInit (SimInit),
    .PrintSimCfg (PrintSimCfg),
    .Latency  (1),
    .impl_in_t (sram_cfg_t)
  ) i_mem (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .impl_i (sram_cfg_i),
    .impl_o (  ),
    .req_i(req_q),
    .we_i(we_q),
    .addr_i(addr_q),
    .wdata_i(wdata_q),
    .be_i(be_q),
    .rdata_o(rdata_sram)
  );

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      rvalid_sram_q <= 1'b0;
    end else begin
      rvalid_sram_q <= req_q;
    end
  end

  assign rdata_d  = rdata_sram[0+:SPMDataWidth];
  assign rerror_d = '0;

  assign rvalid_d = rvalid_sram_q;

  /////////////////////////////////////
  // Input/Output Pipeline Registers //
  /////////////////////////////////////

  if (EnableInputPipeline) begin : gen_regslice_input
    // Put the register slices between ECC encoding to SRAM port
    always_ff @(posedge clk_i or negedge rst_ni) begin
      if (!rst_ni) begin
        req_q   <= '0;
        we_q    <= '0;
        addr_q  <= '0;
        wdata_q <= '0;
        be_q    <= '0;
      end else begin
        req_q   <= req_d;
        we_q    <= we_d;
        addr_q  <= addr_d;
        wdata_q <= wdata_d;
        be_q    <= be_d;
      end
    end
  end else begin : gen_dirconnect_input
    assign req_q   = req_d;
    assign we_q = we_d;
    assign addr_q  = addr_d;
    assign wdata_q = wdata_d;
    assign be_q = be_d;
  end

  if (EnableOutputPipeline) begin : gen_regslice_output
    // Put the register slices between ECC decoding to output
    always_ff @(posedge clk_i or negedge rst_ni) begin
      if (!rst_ni) begin
        rvalid_q <= '0;
        rdata_q  <= '0;
        rerror_q <= '0;
      end else begin
        rvalid_q <= rvalid_d;
        rdata_q  <= rdata_d;
        // tie to zero if the read data is not valid
        rerror_q <= rerror_d & {2{rvalid_d}};
      end
    end
  end else begin : gen_dirconnect_output
    assign rvalid_q = rvalid_d;
    assign rdata_q  = rdata_d;
    // tie to zero if the read data is not valid
    assign rerror_q = rerror_d & {2{rvalid_d}};
  end

endmodule
