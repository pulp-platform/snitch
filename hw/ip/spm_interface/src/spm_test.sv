// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

/// A set of testbench utlities for the SPM interface.
package spm_test;

  class req_t #(
    parameter int AW = 32,
    parameter int DW = 32
  );
    rand logic [AW-1:0]       addr;
    rand logic                we;
    rand logic [DW-1:0]       wdata;
    rand logic [DW/8-1:0]     strb;

    /// Compare objects of same type.
    function do_compare(req_t rhs);
      return addr == rhs.addr &
             we == rhs.we &
             wdata == rhs.wdata &
             strb == rhs.strb;
    endfunction

  endclass

  class rsp_t #(
    parameter int DW = 32
  );
    rand logic [DW-1:0]   rdata;

    /// Compare objects of same type.
    function do_compare(rsp_t rhs);
      return rdata == rhs.rdata;
    endfunction

  endclass

  class spm_driver #(
    parameter int  AW = -1,
    parameter int  DW = -1,
    /// Stimuli application time
    parameter time TA = 0,
    /// Stimuli test time
    parameter time TT = 0
  );

    typedef req_t #(.AW(AW), .DW(DW)) req_t;
    typedef rsp_t #(.DW(DW)) rsp_t;

    virtual SPM_BUS_DV #(
      .ADDR_WIDTH(AW),
      .DATA_WIDTH(DW)
    ) bus;

    function new(
      virtual SPM_BUS_DV #(
        .ADDR_WIDTH(AW),
        .DATA_WIDTH(DW)
      ) bus
    );
      this.bus = bus;
    endfunction

    task reset_master;
      bus.addr    <= '0;
      bus.we      <= '0;
      bus.wdata   <= '0;
      bus.strb    <= '0;
      bus.valid   <= '0;
    endtask

    task reset_slave;
      bus.ready   <= '0;
      bus.rvalid  <= '0;
      bus.rdata   <= '0;
    endtask

    task cycle_start;
      #TT;
    endtask

    task cycle_end;
      @(posedge bus.clk_i);
    endtask

    /// Send a request.
    task send_req (input req_t req);
      bus.addr    <= #TA req.addr;
      bus.we      <= #TA req.we;
      bus.wdata   <= #TA req.wdata;
      bus.strb    <= #TA req.strb;
      bus.req     <= #TA 1;
      cycle_start();
      while (bus.gnt != 1) begin cycle_end(); cycle_start(); end
      cycle_end();
      bus.addr    <= #TA '0;
      bus.we      <= #TA '0;
      bus.wdata   <= #TA '0;
      bus.strb    <= #TA '0;
      bus.req     <= #TA 0;
    endtask

    /// Send a response.
    task send_rsp (input rsp_t rsp);
      bus.rdata   <= #TA rsp.rdata;
      bus.rvalid  <= #TA 1;
      cycle_start();
      cycle_end();
      bus.rdata   <= #TA '0;
      bus.rvalid  <= #TA 0;
    endtask

    /// Receive a request.
    task recv_req (output req_t req);
      bus.ready   <= #TA 1'b1;
      cycle_start();
      while (bus.req != 1) begin cycle_end(); cycle_start(); end
      cycle_end();
      req = new;
      req.addr   = bus.addr;
      req.we     = bus.we;
      req.wdata  = bus.wdata;
      req.strb   = bus.strb;
      bus.gnt    <= #TA 1'b1;
      cycle_end();
    endtask

    /// Receive a response.
    task recv_rsp (output rsp_t rsp);
      cycle_start();
      rsp = new;
      rsp.rdata  = bus.rdata;
      cycle_end();
    endtask

    // /// Monitor request.
    // task mon_req (output req_t req);
    //   cycle_start();
    //   while (!(bus.q_valid && bus.q_ready)) begin cycle_end(); cycle_start(); end
    //   req = new;
    //   req.addr  = bus.q_addr;
    //   req.write = bus.q_write;
    //   req.amo   = bus.q_amo;
    //   req.data  = bus.q_data;
    //   req.strb  = bus.q_strb;
    //   req.user  = bus.q_user;
    //   cycle_end();
    // endtask

    // /// Monitor response.
    // task mon_rsp (output rsp_t rsp);
    //   cycle_start();
    //   rsp = new;
    //   rsp.data  = bus.p_data;
    //   cycle_end();
    // endtask

  endclass

// Super classs for random spm drivers.
  virtual class rand_spm #(
    // spm interface parameters
    parameter int   AW = 32,
    parameter int   DW = 32,
    // Stimuli application and test time
    parameter time  TA = 0ps,
    parameter time  TT = 0ps
  );

    typedef spm_test::spm_driver #(
      // spm bus interface paramaters;
      .AW ( AW ),
      .DW ( DW ),
      // Stimuli application and test time
      .TA ( TA ),
      .TT ( TT )
    ) spm_driver_t;

    spm_driver_t drv;

    typedef spm_driver_t::req_t req_t;
    typedef spm_driver_t::rsp_t rsp_t;

    function new(virtual SPM_BUS_DV #(
      .ADDR_WIDTH (AW),
      .DATA_WIDTH (DW)
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
        cycles dist {min := 10, [min:max] := 1};
      };
      assert (rand_success) else $error("Failed to randomize wait cycles!");
      repeat (cycles) @(posedge this.drv.bus.clk_i);
    endtask

  endclass

  /// Generate random requests as a master device.
  class rand_spm_master #(
    // spm interface parameters
    parameter int   AW = 32,
    parameter int   DW = 32,
    // Stimuli application and test time
    parameter time  TA = 0ps,
    parameter time  TT = 0ps,
    parameter int unsigned REQ_MIN_WAIT_CYCLES = 1,
    parameter int unsigned REQ_MAX_WAIT_CYCLES = 20
  ) extends rand_spm #(.AW(AW), .DW(DW), .TA(TA), .TT(TT));

    /// Reset the driver.
    task reset();
      drv.reset_master();
    endtask

    /// Constructor.
    function new(virtual SPM_BUS_DV #(
      .ADDR_WIDTH (AW),
      .DATA_WIDTH (DW)
    ) bus);
      super.new(bus);
    endfunction

    task run(input int n);
      repeat (n) begin
        automatic spm_driver_t::req_t r = new;
        assert(r.randomize());
        rand_wait(REQ_MIN_WAIT_CYCLES, REQ_MAX_WAIT_CYCLES);
        this.drv.send_req(r);
      end
    endtask
  endclass

  class rand_spm_slave #(
    // spm interface parameters
    parameter int   AW = 32,
    parameter int   DW = 32,
    parameter int unsigned RespLatency = 1,
    // Stimuli application and test time
    parameter time  TA = 0ps,
    parameter time  TT = 0ps,
    parameter int unsigned REQ_MIN_WAIT_CYCLES = 0,
    parameter int unsigned REQ_MAX_WAIT_CYCLES = 10
  ) extends rand_spm #(.AW(AW), .DW(DW), .TA(TA), .TT(TT));

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
    function new(virtual SPM_BUS_DV #(
      .ADDR_WIDTH (AW),
      .DATA_WIDTH (DW)
    ) bus);
      super.new(bus);
    endfunction

    task recv_requests();
      forever begin
        automatic spm_driver_t::req_t req;
        rand_wait(REQ_MIN_WAIT_CYCLES, REQ_MAX_WAIT_CYCLES);
        this.drv.recv_req(req);
        req_mbx.put(req);
      end
    endtask

    task send_responses();
      automatic spm_driver_t::rsp_t rsp = new;
      automatic spm_driver_t::req_t req;
      forever begin
        req_mbx.get(req);
        assert(rsp.randomize());
        repeat (RespLatency-1) @(posedge this.drv.bus.clk_i);
        this.drv.send_rsp(rsp);
      end
    endtask
  endclass

  // class spm_monitor #(
  //   // spm interface parameters
  //   parameter int   AW = 32,
  //   parameter int   DW = 32,
  //   parameter type  user_t = logic,
  //   parameter int unsigned RespLatency = 1,
  //   // Stimuli application and test time
  //   parameter time  TA = 0ps,
  //   parameter time  TT = 0ps
  // ) extends rand_mem #(.AW(AW), .DW(DW), .user_t (user_t), .TA(TA), .TT(TT));

  //   mailbox req_mbx = new, rsp_mbx = new;
  //   typedef mem_driver_t::req_t req_t;
  //   typedef mem_driver_t::rsp_t rsp_t;

  //   /// Constructor.
  //   function new(virtual MEM_BUS_DV #(
  //     .ADDR_WIDTH (AW),
  //     .DATA_WIDTH (DW),
  //     .user_t (user_t)
  //   ) bus);
  //     super.new(bus);
  //   endfunction

  //   // mem Monitor.
  //   task monitor;
  //     forever begin
  //       automatic mem_driver_t::req_t req;
  //       this.drv.mon_req(req);
  //       req_mbx.put(req);
  //       fork
  //         begin
  //           automatic mem_driver_t::rsp_t rsp;
  //           repeat (RespLatency-1) @(posedge this.drv.bus.clk_i);
  //           this.drv.mon_rsp(rsp);
  //           rsp_mbx.put(rsp);
  //         end
  //       join_none
  //     end
  //   endtask
  // endclass
endpackage
