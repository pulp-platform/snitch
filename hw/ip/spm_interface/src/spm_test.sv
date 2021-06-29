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
      bus.valid   <= #TA 1;
      cycle_start();
      while (bus.ready != 1) begin cycle_end(); cycle_start(); end
      cycle_end();
      bus.valid   <= #TA 0;
      bus.addr    <= #TA '0;
      bus.we      <= #TA '0;
      bus.wdata   <= #TA '0;
      bus.strb    <= #TA '0;

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
      while (bus.valid != 1) begin cycle_end(); cycle_start(); end
      req = new;
      req.addr   = bus.addr;
      req.we     = bus.we;
      req.wdata  = bus.wdata;
      req.strb   = bus.strb;
      cycle_end();
      bus.ready  <= #TA 1'b0;
    endtask

    /// Receive a response.
    task recv_rsp (output rsp_t rsp);
      cycle_start();
      rsp = new;
      rsp.rdata  = bus.rdata;
      cycle_end();
    endtask

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
        r.we = (r.strb != '1)? 1'b1 : r.we;
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

endpackage
