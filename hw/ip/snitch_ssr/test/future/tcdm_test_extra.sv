// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

/// A set of testbench utlities for the TCDM interface.
/// This package proposes an additional driver class using non-random structs as arguments.
/// TODO: Integrate this functionality properly in tcdm_test.

package tcdm_test_extra;

  class tcdm_driver_nonrand #(
    parameter int  AW = -1,
    parameter int  DW = -1,
    parameter type user_t = logic,
    /// Stimuli application time
    parameter time TA = 0,
    /// Stimuli test time
    parameter time TT = 0,
    /// Request channel (payload) type
    parameter type req_chan_t = logic,
    /// Response channel (payload) type
    parameter type rsp_chan_t = logic
  );
    virtual TCDM_BUS_DV #(
      .ADDR_WIDTH(AW),
      .DATA_WIDTH(DW),
      .user_t (user_t)
    ) bus;

    function new(
      virtual TCDM_BUS_DV #(
        .ADDR_WIDTH(AW),
        .DATA_WIDTH(DW),
        .user_t (user_t)
      ) bus
    );
      this.bus = bus;
    endfunction

    task reset_master;
      bus.q_addr  <= '0;
      bus.q_write <= '0;
      bus.q_amo   <= reqrsp_pkg::AMONone;
      bus.q_data  <= '0;
      bus.q_strb  <= '0;
      bus.q_user  <= '0;
      bus.q_valid <= '0;
    endtask

    task reset_slave;
      bus.q_ready <= '0;
      bus.p_data  <= '0;
      bus.p_valid <= '0;
    endtask

    task cycle_start;
      #TT;
    endtask

    task cycle_end;
      @(posedge bus.clk_i);
    endtask

    /// Send a request.
    task send_req (input req_chan_t req);
      bus.q_addr  <= #TA req.addr;
      bus.q_write <= #TA req.write;
      bus.q_amo   <= #TA req.amo;
      bus.q_data  <= #TA req.data;
      bus.q_strb  <= #TA req.strb;
      bus.q_user  <= #TA req.user;
      bus.q_valid <= #TA 1;
      cycle_start();
      while (bus.q_ready != 1) begin cycle_end(); cycle_start(); end
      cycle_end();
      bus.q_addr  <= #TA '0;
      bus.q_write <= #TA '0;
      bus.q_data  <= #TA '0;
      bus.q_strb  <= #TA '0;
      bus.q_user  <= #TA '0;
      bus.q_valid <= #TA 0;
    endtask

    /// Send a response.
    task send_rsp (input rsp_chan_t rsp);
      bus.p_data  <= #TA rsp.data;
      bus.p_valid <= #TA 1;
      cycle_start();
      cycle_end();
      bus.p_data  <= #TA '0;
      bus.p_valid <= #TA 0;
    endtask

    /// Receive a request.
    task recv_req (output req_chan_t req);
      bus.q_ready <= #TA 1;
      cycle_start();
      while (bus.q_valid != 1) begin cycle_end(); cycle_start(); end
      req.addr  = bus.q_addr;
      req.write = bus.q_write;
      req.amo   = bus.q_amo;
      req.data  = bus.q_data;
      req.strb  = bus.q_strb;
      req.user  = bus.q_user;
      cycle_end();
      bus.q_ready <= #TA 0;
    endtask

    /// Receive a response.
    task recv_rsp (output rsp_chan_t rsp);
      cycle_start();
      while (bus.p_valid != 1) begin cycle_end(); cycle_start(); end
      rsp.data  = bus.p_data;
      cycle_end();
    endtask

    /// Monitor request.
    task mon_req (output req_chan_t req);
      cycle_start();
      while (!(bus.q_valid && bus.q_ready)) begin cycle_end(); cycle_start(); end
      req.addr  = bus.q_addr;
      req.write = bus.q_write;
      req.amo   = bus.q_amo;
      req.data  = bus.q_data;
      req.strb  = bus.q_strb;
      req.user  = bus.q_user;
      cycle_end();
    endtask

    /// Monitor response.
    task mon_rsp (output rsp_chan_t rsp);
      cycle_start();
      while (!(bus.p_valid)) begin cycle_end(); cycle_start(); end
      rsp.data  = bus.p_data;
      cycle_end();
    endtask

  endclass

endpackage
