// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Fabian Schuiki <fschuiki@iis.ee.ethz.ch>

/// A set of testbench utilities for REQRSP interfaces.
package reqrsp_test;

  import reqrsp_pkg::*;

  /// A driver for the REQRSP interface.
  class reqrsp_driver #(
    parameter int  AW = -1,
    parameter int  DW = -1,
    parameter int  IW = -1,
    parameter time TA = 0 , // stimuli application time
    parameter time TT = 0   // stimuli test time
  );
    virtual REQRSP_BUS_DV #(
      .ADDR_WIDTH(AW),
      .DATA_WIDTH(DW)
    ) bus;

    function new(
      virtual REQRSP_BUS_DV #(
        .ADDR_WIDTH(AW),
        .DATA_WIDTH(DW)
      ) bus
    );
      this.bus = bus;
    endfunction

    task reset_master;
      bus.q_addr  <= '0;
      bus.q_write <= '0;
      bus.q_amo   <= AMONone;
      bus.q_data  <= '0;
      bus.q_strb  <= '0;
      bus.q_size  <= '0;
      bus.q_valid <= '0;
      bus.p_ready <= '0;
    endtask

    task reset_slave;
      bus.q_ready <= '0;
      bus.p_data  <= '0;
      bus.p_error <= '0;
      bus.p_valid <= '0;
    endtask

    task cycle_start;
      #TT;
    endtask

    task cycle_end;
      @(posedge bus.clk_i);
    endtask

    /// Send a request.
    task send_req (
      input logic [AW-1:0]   addr,
      input logic            write,
      input amo_op_e         amo,
      input logic [DW-1:0]   data,
      input logic [DW/8-1:0] strb,
      input size_t           size
    );
      bus.q_addr  <= #TA addr;
      bus.q_write <= #TA write;
      bus.q_amo   <= #TA AMONone;
      bus.q_data  <= #TA data;
      bus.q_strb  <= #TA strb;
      bus.q_size  <= #TA size;
      bus.q_valid <= #TA 1;
      cycle_start();
      while (bus.q_ready != 1) begin cycle_end(); cycle_start(); end
      cycle_end();
      bus.q_addr  <= #TA '0;
      bus.q_write <= #TA '0;
      bus.q_data  <= #TA '0;
      bus.q_strb  <= #TA '0;
      bus.q_valid <= #TA 0;
    endtask

    /// Send a response.
    task send_rsp (
      input logic [DW-1:0] data,
      input logic          error
    );
      bus.p_data  <= #TA data;
      bus.p_error <= #TA error;
      bus.p_valid <= #TA 1;
      cycle_start();
      while (bus.p_ready != 1) begin cycle_end(); cycle_start(); end
      cycle_end();
      bus.p_data  <= #TA '0;
      bus.p_error <= #TA '0;
      bus.p_valid <= #TA 0;
    endtask

    /// Receive a request.
    task recv_req (
      output logic [AW-1:0]   addr,
      output logic            write,
      output amo_op_e         amo,
      output logic [DW-1:0]   data,
      output logic [DW/8-1:0] strb,
      output size_t           size
    );
      bus.q_ready <= #TA 1;
      cycle_start();
      while (bus.q_valid != 1) begin cycle_end(); cycle_start(); end
      addr  = bus.q_addr;
      write = bus.q_write;
      amo   = bus.q_amo;
      data  = bus.q_data;
      strb  = bus.q_strb;
      size  = bus.q_size;
      cycle_end();
      bus.q_ready <= #TA 0;
    endtask

    /// Receive a response.
    task recv_rsp (
      output logic [DW-1:0] data,
      output logic          error
    );
      bus.p_ready <= #TA 1;
      cycle_start();
      while (bus.p_valid != 1) begin cycle_end(); cycle_start(); end
      data  = bus.p_data;
      error = bus.p_error;
      cycle_end();
      bus.p_ready <= #TA 0;
    endtask

  endclass

endpackage
