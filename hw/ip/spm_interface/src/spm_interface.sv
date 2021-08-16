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
  logic    we;
  data_t   wdata;
  strb_t   strb;
  logic    valid;

  /// The response channel.
  logic    ready;
  logic    rvalid;
  data_t   rdata;

  modport in  (
    input  addr, we, wdata, strb, valid,
    output ready, rvalid, rdata
  );

  modport out  (
    output  addr, we, wdata, strb, valid,
    input ready, rvalid, rdata
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
  logic                          we;
  data_t   wdata;
  strb_t   strb;
  logic                          valid;

  /// The response channel.
  logic                          ready;
  logic                          rvalid;
  data_t   rdata;

  modport in  (
               input  addr, we, wdata, strb, valid,
               output ready, rvalid, rdata
               );

  modport out  (
                output addr, we, wdata, strb, valid,
                input  ready, rvalid, rdata
                );

  // pragma translate_off
`ifndef VERILATOR
  assert property (@(posedge clk_i) (valid && !ready |=> $stable(addr)));
  assert property (@(posedge clk_i) (valid && !ready |=> $stable(we)));
  assert property (@(posedge clk_i) (valid && !ready && we |=> $stable(wdata)));
  assert property (@(posedge clk_i) (valid && !ready |=> $stable(strb)));
  assert property (@(posedge clk_i) (valid && !ready |=> valid));
`endif
  // pragma translate_on

endinterface
