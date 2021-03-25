// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

/// A set of testbench utlities for the TCDM interface.
package tcdm_test;

  class req_t #(
    parameter int AW = 32,
    parameter int DW = 32,
    parameter type user_t = logic
  );
    rand logic [AW-1:0]       addr;
    rand logic                write;
    rand reqrsp_pkg::amo_op_e amo;
    rand logic [DW-1:0]       data;
    rand logic [DW/8-1:0]     strb;
    rand user_t               user;

    rand bit is_amo;

    constraint legal_amo_op_c {
      amo inside {
        reqrsp_pkg::AMOSwap,
        reqrsp_pkg::AMOAdd,
        reqrsp_pkg::AMOAnd,
        reqrsp_pkg::AMOOr,
        reqrsp_pkg::AMOXor,
        reqrsp_pkg::AMOMax,
        reqrsp_pkg::AMOMaxu,
        reqrsp_pkg::AMOMin,
        reqrsp_pkg::AMOMinu,
        reqrsp_pkg::AMOSC} -> write == 1;
    }

    // Reduce the amount of atomics.
    constraint amo_reduce_c {
      is_amo dist { 1:= 1, 0:= 10};
      is_amo -> amo inside {
        reqrsp_pkg::AMOSwap,
        reqrsp_pkg::AMOAdd,
        reqrsp_pkg::AMOAnd,
        reqrsp_pkg::AMOOr,
        reqrsp_pkg::AMOXor,
        reqrsp_pkg::AMOMax,
        reqrsp_pkg::AMOMaxu,
        reqrsp_pkg::AMOMin,
        reqrsp_pkg::AMOMinu
      };
    }

    /// Compare objects of same type.
    function do_compare(req_t #(.AW(AW), .DW(DW), .user_t(user_t)) rhs);
      return addr == rhs.addr &
             write == rhs.write &
             amo == rhs.amo &
             data == rhs.data &
             strb == rhs.strb;
    endfunction

  endclass

  class rsp_t #(
    parameter int DW = 32
  );
    rand logic [DW-1:0]   data;

    /// Compare objects of same type.
    function do_compare(rsp_t #(.DW(DW)) rhs);
      return data == rhs.data;
    endfunction

  endclass

  class tcdm_driver #(
    parameter int  AW = -1,
    parameter int  DW = -1,
    parameter type user_t = logic,
    /// Stimuli application time
    parameter time TA = 0,
    /// Stimuli test time
    parameter time TT = 0
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
    task send_req (input req_t #(.AW(AW), .DW(DW), .user_t(user_t)) req);
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
    task send_rsp (input rsp_t #(.DW(DW)) rsp);
      bus.p_data  <= #TA rsp.data;
      bus.p_valid <= #TA 1;
      cycle_start();
      cycle_end();
      bus.p_data  <= #TA '0;
      bus.p_valid <= #TA 0;
    endtask

    /// Receive a request.
    task recv_req (output req_t #(.AW(AW), .DW(DW), .user_t(user_t)) req);
      bus.q_ready <= #TA 1;
      cycle_start();
      while (bus.q_valid != 1) begin cycle_end(); cycle_start(); end
      req = new;
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
    task recv_rsp (output rsp_t #(.DW(DW)) rsp);
      cycle_start();
      while (bus.p_valid != 1) begin cycle_end(); cycle_start(); end
      rsp = new;
      rsp.data  = bus.p_data;
      cycle_end();
    endtask

    /// Monitor request.
    task mon_req (output req_t #(.AW(AW), .DW(DW), .user_t(user_t)) req);
      cycle_start();
      while (!(bus.q_valid && bus.q_ready)) begin cycle_end(); cycle_start(); end
      req = new;
      req.addr  = bus.q_addr;
      req.write = bus.q_write;
      req.amo   = bus.q_amo;
      req.data  = bus.q_data;
      req.strb  = bus.q_strb;
      req.user  = bus.q_user;
      cycle_end();
    endtask

    /// Monitor response.
    task mon_rsp (output rsp_t #(.DW(DW)) rsp);
      cycle_start();
      while (!(bus.p_valid)) begin cycle_end(); cycle_start(); end
      rsp = new;
      rsp.data  = bus.p_data;
      cycle_end();
    endtask

  endclass

// Super classs for random tcdm drivers.
  virtual class rand_tcdm #(
    // tcdm interface parameters
    parameter int   AW = 32,
    parameter int   DW = 32,
    parameter type  user_t = logic,
    // Stimuli application and test time
    parameter time  TA = 0ps,
    parameter time  TT = 0ps
  );

    typedef tcdm_test::tcdm_driver #(
      // tcdm bus interface paramaters;
      .AW ( AW ),
      .DW ( DW ),
      .user_t ( user_t ),
      // Stimuli application and test time
      .TA ( TA ),
      .TT ( TT )
    ) tcdm_driver_t;

    tcdm_driver_t drv;

    function new(virtual TCDM_BUS_DV #(
      .ADDR_WIDTH (AW),
      .DATA_WIDTH (DW),
      .user_t (user_t)
    ) bus);
      this.drv = new (bus);
    endfunction

    task automatic rand_wait(input int unsigned min, input int unsigned max);
      int unsigned rand_success, cycles;
      rand_success = std::randomize(cycles) with {
        cycles >= min;
        cycles <= max;
        // Weigh the distribution so that the minimum cycle time is the common
        // case.
        cycles dist {min := 10, [min+1:max] := 1};
      };
      assert (rand_success) else $error("Failed to randomize wait cycles!");
      repeat (cycles) @(posedge this.drv.bus.clk_i);
    endtask

  endclass

  /// Generate random requests as a master device.
  class rand_tcdm_master #(
    // tcdm interface parameters
    parameter int   AW = 32,
    parameter int   DW = 32,
    parameter type  user_t = logic,
    // Stimuli application and test time
    parameter time  TA = 0ps,
    parameter time  TT = 0ps,
    parameter int unsigned REQ_MIN_WAIT_CYCLES = 1,
    parameter int unsigned REQ_MAX_WAIT_CYCLES = 20
  ) extends rand_tcdm #(.AW(AW), .DW(DW), .user_t (user_t), .TA(TA), .TT(TT));

    int unsigned cnt = 0;
    bit req_done = 0;

    /// Reset the driver.
    task reset();
      drv.reset_master();
    endtask

    /// Constructor.
    function new(virtual TCDM_BUS_DV #(
      .ADDR_WIDTH (AW),
      .DATA_WIDTH (DW),
      .user_t (user_t)
    ) bus);
      super.new(bus);
    endfunction

    task run(input int n);
      fork
        send_requests(n);
        recv_response();
      join
    endtask

    /// Send random requests.
    task send_requests (input int n);
      automatic req_t #(.AW(AW), .DW(DW), .user_t(user_t)) r = new;

      repeat (n) begin
        this.cnt++;
        assert(r.randomize());
        rand_wait(REQ_MIN_WAIT_CYCLES, REQ_MAX_WAIT_CYCLES);
        this.drv.send_req(r);
      end
      this.req_done = 1;
    endtask

    /// Receive random responses.
    task recv_response;
      while (!this.req_done || this.cnt > 0) begin
        automatic rsp_t #(.DW(DW)) rsp;
        this.cnt--;
        this.drv.recv_rsp(rsp);
      end
    endtask
  endclass

  class rand_tcdm_slave #(
    // tcdm interface parameters
    parameter int   AW = 32,
    parameter int   DW = 32,
    parameter type  user_t  = logic,
    // Stimuli application and test time
    parameter time  TA = 0ps,
    parameter time  TT = 0ps,
    parameter int unsigned REQ_MIN_WAIT_CYCLES = 0,
    parameter int unsigned REQ_MAX_WAIT_CYCLES = 10,
    parameter int unsigned RSP_MIN_WAIT_CYCLES = 0,
    parameter int unsigned RSP_MAX_WAIT_CYCLES = 10
  ) extends rand_tcdm #(.AW(AW), .DW(DW), .user_t (user_t), .TA(TA), .TT(TT));

    mailbox req_mbx = new();

    /// Reset the driver.
    task reset();
      drv.reset_slave();
    endtask

    task run();
      fork
        recv_requests();
        send_responses();
      join
    endtask

    /// Constructor.
    function new(virtual TCDM_BUS_DV #(
      .ADDR_WIDTH (AW),
      .DATA_WIDTH (DW),
      .user_t (user_t)
    ) bus);
      super.new(bus);
    endfunction

    task recv_requests();
      forever begin
        automatic req_t #(.AW(AW), .DW(DW), .user_t(user_t)) req;
        rand_wait(REQ_MIN_WAIT_CYCLES, REQ_MAX_WAIT_CYCLES);
        this.drv.recv_req(req);
        req_mbx.put(req);
      end
    endtask

    task send_responses();
      automatic rsp_t #(.DW(DW)) rsp = new;
      automatic req_t #(.AW(AW), .DW(DW), .user_t(user_t)) req;
      forever begin
        req_mbx.get(req);
        assert(rsp.randomize());
        @(posedge this.drv.bus.clk_i);
        rand_wait(RSP_MIN_WAIT_CYCLES, RSP_MAX_WAIT_CYCLES);
        this.drv.send_rsp(rsp);
      end
    endtask
  endclass

  class tcdm_monitor #(
    // tcdm interface parameters
    parameter int   AW = 32,
    parameter int   DW = 32,
    parameter type  user_t = logic,
    // Stimuli application and test time
    parameter time  TA = 0ps,
    parameter time  TT = 0ps
  ) extends rand_tcdm #(.AW(AW), .DW(DW), .user_t (user_t), .TA(TA), .TT(TT));

    mailbox req_mbx = new, rsp_mbx = new;

    /// Constructor.
    function new(virtual TCDM_BUS_DV #(
      .ADDR_WIDTH (AW),
      .DATA_WIDTH (DW),
      .user_t (user_t)
    ) bus);
      super.new(bus);
    endfunction

    // tcdm Monitor.
    task monitor;
      fork
        forever begin
          automatic tcdm_test::req_t #(.AW(AW), .DW(DW), .user_t(user_t)) req;
          this.drv.mon_req(req);
          req_mbx.put(req);
        end
        forever begin
          automatic tcdm_test::rsp_t #(.DW(DW)) rsp;
          this.drv.mon_rsp(rsp);
          rsp_mbx.put(rsp);
        end
      join
    endtask
  endclass
endpackage
