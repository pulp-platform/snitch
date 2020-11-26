// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>


`include "reqrsp_interface/assign.svh"
`include "axi/assign.svh"

/// Testbench for the request/response TB
module reqrsp_to_axi_tb #(
  parameter int unsigned AW = 32,
  parameter int unsigned DW = 32,
  parameter int unsigned IW = 2,
  parameter int unsigned UW = 2
);

  localparam time ClkPeriod = 10ns;
  logic  clk, rst_n;

  typedef logic [AW-1:0] addr_t;
  typedef logic [DW-1:0] data_t;
  typedef logic [DW/8-1:0] strb_t;
  typedef logic [IW-1:0] id_t;
  typedef logic [UW-1:0] user_t;

  // interfaces
  REQRSP_BUS #(
    .ADDR_WIDTH ( AW ),
    .DATA_WIDTH ( DW )
  ) master ();

  REQRSP_BUS_DV #(
    .ADDR_WIDTH ( AW ),
    .DATA_WIDTH ( DW )
  ) master_dv (clk);

  AXI_BUS #(
    .AXI_ADDR_WIDTH ( AW ),
    .AXI_DATA_WIDTH ( DW ),
    .AXI_ID_WIDTH   ( IW  ),
    .AXI_USER_WIDTH ( UW )
  ) slave ();

  AXI_BUS_DV #(
    .AXI_ADDR_WIDTH ( AW ),
    .AXI_DATA_WIDTH ( DW ),
    .AXI_ID_WIDTH   ( IW  ),
    .AXI_USER_WIDTH ( UW )
  ) slave_dv (clk);

  reqrsp_to_axi_intf #(
    .AXI_ID_WIDTH (IW),
    .ADDR_WIDTH (AW),
    .DATA_WIDTH (DW),
    .AXI_USER_WIDTH (UW)
  ) i_reqrsp_to_axi (
    .clk_i (clk),
    .rst_ni (rst_n),
    .reqrsp (master),
    .axi (slave)
  );

  `REQRSP_ASSIGN(master, master_dv)
  `AXI_ASSIGN(slave_dv, slave)

  // Clock generation.
  initial begin
    rst_n = 0;
    repeat (3) begin
      #(ClkPeriod/2) clk = 0;
      #(ClkPeriod/2) clk = 1;
    end
    rst_n = 1;
    forever begin
      #(ClkPeriod/2) clk = 0;
      #(ClkPeriod/2) clk = 1;
    end
  end

endmodule
