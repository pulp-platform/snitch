// Copyright 2021 ETH Zurich and University of Bologna.
// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Single-Port SRAM Wrapper with additional latency configuration options.
// Based on `lowRISC's prim_ram_1p_adv`
//

module cc_ram_1p_adv #(
  parameter  int NumWords             = 512,
  parameter  int DataWidth            = 32,
  /// Number of data bits per bit of write mask
  parameter  int ByteWidth            = 1,
  /// Simulation initialization
  parameter      SimInit              = "none",
  /// Print configuration
  parameter bit  PrintSimCfg          = 1'b0,
  /// Adds an input register (read latency +1)
  parameter  bit EnableInputPipeline  = 0,
  /// Adds an output register (read latency +1)
  parameter  bit EnableOutputPipeline = 0,
  // DEPENDENT PARAMETERS, DO NOT OVERWRITE!
  parameter int unsigned AddrWidth = cf_math_pkg::idx_width(NumWords),
  parameter int unsigned BeWidth   = (DataWidth + ByteWidth - 32'd1) / ByteWidth, // ceil_div
  parameter type         addr_t    = logic [AddrWidth-1:0],
  parameter type         data_t    = logic [DataWidth-1:0],
  parameter type         be_t      = logic [BeWidth-1:0]
) (
  input logic        clk_i,
  input logic        rst_ni,
  // input ports
  input  logic       req_i,      // request
  input  logic       we_i,       // write enable
  input  addr_t      addr_i,     // request address
  input  data_t      wdata_i,    // write data
  input  be_t        be_i,       // write byte enable
  // output ports
  output data_t      rdata_o,    // read data
  /// Read- or write transaction is valid.
  output logic       rvalid_o,
  output logic [1:0] rerror_o    // Bit1: Uncorrectable, Bit0: Correctable
);

  ////////////////////////////
  // RAM Primitive Instance //
  ////////////////////////////

  logic       req_q,    req_d;
  logic       we_q,     we_d;
  addr_t      addr_q,   addr_d;
  data_t      wdata_q,  wdata_d;
  be_t        be_q,     be_d;
  logic       rvalid_q, rvalid_d, rvalid_sram_q;
  data_t      rdata_q,  rdata_d;
  data_t      rdata_sram;
  logic [1:0] rerror_q, rerror_d;

  tc_sram #(
    .NumWords (NumWords),
    .DataWidth(DataWidth),
    .ByteWidth(ByteWidth),
    .NumPorts (1),
    .SimInit (SimInit),
    .PrintSimCfg (PrintSimCfg),
    .Latency  (1)
  ) i_mem (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
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

  assign req_d    = req_i;
  assign we_d     = we_i;
  assign addr_d   = addr_i;
  assign rvalid_o = rvalid_q;
  assign rdata_o  = rdata_q;
  assign rerror_o = rerror_q;

  // We do not generate a parity yet.
  assign be_d = be_i;
  assign wdata_d = wdata_i;

  assign rdata_d  = rdata_sram[0+:DataWidth];
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
        we_q <= '0;
        addr_q  <= '0;
        wdata_q <= '0;
        be_q <= '0;
      end else begin
        req_q   <= req_d;
        we_q <= we_d;
        addr_q  <= addr_d;
        wdata_q <= wdata_d;
        be_q <= be_d;
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
