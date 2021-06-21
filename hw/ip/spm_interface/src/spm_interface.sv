// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

/// SPM Interface.
interface SPM_BUS #(
  /// The width of the address.
  parameter int  ADDR_WIDTH = -1,
  /// The width of the data.
  parameter int  DATA_WIDTH = -1
);

  localparam int unsigned StrbWidth = DATA_WIDTH / 8;

  typedef logic [ADDR_WIDTH-1:0] addr_t;
  typedef logic [DATA_WIDTH-1:0] data_t;
  typedef logic [StrbWidth-1:0] strb_t;
  /// The request channel.
  addr_t   addr;
  /// 0 = read, 1 = write, 1 = amo fetch-and-op
  logic    we;
  data_t   wdata;
  /// Byte-wise strobe
  strb_t   strb;
  logic    req;

  /// The response channel.
  logic    gnt;
  logic    rvalid;
  data_t   rdata;

  modport in  (
    input  addr, we, wdata, strb, req,
    output gnt, rvalid, rdata
  );

  modport out  (
    output  addr, we, wdata, strb, req,
    input gnt, rvalid, rdata
  );

endinterface

/// SPM Interface for verficiation purposes.
interface SPM_BUS_DV #(
  /// The width of the address.
  parameter int  ADDR_WIDTH = -1,
  /// The width of the data.
  parameter int  DATA_WIDTH = -1
) (
  input logic clk_i
);

  localparam int unsigned StrbWidth = DATA_WIDTH / 8;

  typedef logic [ADDR_WIDTH-1:0] addr_t;
  typedef logic [DATA_WIDTH-1:0] data_t;
  typedef logic [StrbWidth-1:0]  strb_t;
  /// The request channel.
  addr_t   addr;
  /// 0 = read, 1 = write, 1 = amo fetch-and-op
  logic                          we;
  data_t   wdata;
  /// Byte-wise strobe
  strb_t   strb;
  logic                          req;

  /// The response channel.
  logic                          gnt;
  logic                          rvalid;
  data_t   rdata;

  modport in  (
               input  addr, we, wdata, strb, req,
               output gnt, rvalid, rdata
               );

  modport out  (
                output addr, we, wdata, strb, req,
                input  gnt, rvalid, rdata
                );

endinterface
