// Copyright 2018-2021 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Florian Zaruba, ETH Zurich

`include "register_interface/assign.svh"
`include "register_interface/typedef.svh"

module clint_tb;

  localparam time ClkPeriod = 10ns;
  localparam time RTCClkPeriod = 30ns;

  `REG_BUS_TYPEDEF_ALL(dut, logic [31:0], logic [31:0], logic [3:0])

  logic clk, rst_n, rtc;
  logic [1:0] timer_irq, ipi;

  // ----------------
  // Clock generation
  // ----------------
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

  initial begin
    rtc = 1'b0;
    forever begin
      #(RTCClkPeriod/2) rtc = 0;
      #(RTCClkPeriod/2) rtc = 1;
    end
  end

  REG_BUS #(.ADDR_WIDTH(32), .DATA_WIDTH(32)) reg_dut(clk);
  dut_req_t dut_req;
  dut_rsp_t dut_rsp;

  `REG_BUS_ASSIGN_TO_REQ(dut_req, reg_dut)
  `REG_BUS_ASSIGN_FROM_RSP(reg_dut, dut_rsp)

  typedef reg_test::reg_driver #(
    .AW (32), .DW (32), .TA (ClkPeriod*0.2), .TT (ClkPeriod*0.8)
  ) reg_driver_t;

  reg_driver_t driver = new (reg_dut);

  clint #(
    .reg_req_t (dut_req_t),
    .reg_rsp_t (dut_rsp_t)
  ) dut (
    .clk_i (clk),
    .rst_ni (rst_n),
    .testmode_i (1'b0),
    .reg_req_i (dut_req),
    .reg_rsp_o (dut_rsp),
    .rtc_i (rtc),
    .timer_irq_o (timer_irq),
    .ipi_o (ipi)
  );

  localparam logic [31:0] MSIPBase = 32'h0;
  localparam logic [31:0] MTIMECMPBase = 32'h4000;
  localparam logic [31:0] MTIMEBase = 32'hbff8;

  initial begin
    automatic logic error;
    driver.reset_master();
    @(posedge rst_n);
    driver.send_write(MSIPBase, 1, 1, error);
    @(posedge clk);
    assert(ipi[0] == 1);
    driver.send_write(MTIMECMPBase, 32'hffff, 4'hf, error);
    @(posedge clk);
    assert(timer_irq[0] == 0);
    assert(timer_irq[1] == 1);
    driver.send_write(MTIMEBase, 32'hffff_ffff, 4'hf, error);
    @(posedge clk);
    assert(timer_irq[0] == 1);
    assert(timer_irq[1] == 1);
    #3000ns;
    $finish();
  end

endmodule
