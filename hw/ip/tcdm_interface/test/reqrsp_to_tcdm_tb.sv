// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

`include "reqrsp_interface/assign.svh"
`include "tcdm_interface/assign.svh"

/// Testbench for `reqrsp_to_tcdm` module.
module reqrsp_to_tcdm_tb import reqrsp_pkg::*; #(
  parameter int unsigned AW = 32,
  parameter int unsigned DW = 32,
  parameter int unsigned BufDepth = 4,
  parameter int unsigned NrRandomTransactions = 1000
);

  localparam time ClkPeriod = 10ns;
  localparam time ApplTime =  2ns;
  localparam time TestTime =  8ns;

  logic  clk, rst_n;

  typedef logic [AW-1:0] addr_t;
  typedef logic [DW-1:0] data_t;
  typedef logic [DW/8-1:0] strb_t;

  // interfaces
  REQRSP_BUS #(
    .ADDR_WIDTH ( AW ),
    .DATA_WIDTH ( DW )
  ) master ();

  REQRSP_BUS_DV #(
    .ADDR_WIDTH ( AW ),
    .DATA_WIDTH ( DW )
  ) master_dv (clk);

  TCDM_BUS #(
    .ADDR_WIDTH ( AW ),
    .DATA_WIDTH ( DW ),
    .user_t (logic)
  ) slave ();

  TCDM_BUS_DV #(
    .ADDR_WIDTH ( AW ),
    .DATA_WIDTH ( DW ),
    .user_t (logic)
  ) slave_dv (clk);


  reqrsp_to_tcdm_intf #(
    .AddrWidth (AW),
    .DataWidth (DW),
    .BufDepth (BufDepth),
    .user_t (logic)
  ) i_dut (
    .clk_i (clk),
    .rst_ni (rst_n),
    .reqrsp (master),
    .tcdm (slave)
  );

  `REQRSP_ASSIGN(master, master_dv)
  `TCDM_ASSIGN(slave_dv, slave)

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

  // ------
  // Driver
  // ------
  // TCDM Driver
  typedef tcdm_test::rand_tcdm_slave #(
    // tcdm interface parameters
    .AW ( AW ),
    .DW ( DW ),
    .user_t (logic),
    // Stimuli application and test time
    .TA ( ApplTime ),
    .TT ( TestTime )
  ) rand_tcdm_slave_t;

  rand_tcdm_slave_t rand_tcdm_slave = new (slave_dv);

  typedef reqrsp_test::rand_reqrsp_master #(
    // Reqrsp bus interface paramaters;
    .AW ( AW ),
    .DW ( DW ),
    // Stimuli application and test time
    .TA ( ApplTime ),
    .TT ( TestTime )
  ) reqrsp_driver_t;

  reqrsp_driver_t rand_reqrsp_master = new (master_dv);

  // tcdm side.
  initial begin
    rand_tcdm_slave.reset();
    @(posedge rst_n);
    rand_tcdm_slave.run();
  end

  // tcdm side.
  initial begin
    rand_reqrsp_master.reset();
    @(posedge rst_n);
    rand_reqrsp_master.run(NrRandomTransactions);
    repeat (100) @(posedge clk);
    $finish;
  end

  // -------
  // Monitor
  // -------
  typedef reqrsp_test::reqrsp_monitor #(
    // Reqrsp bus interface paramaters;
    .AW ( AW ),
    .DW ( DW ),
    // Stimuli application and test time
    .TA ( ApplTime ),
    .TT ( TestTime )
  ) reqrsp_monitor_t;

  reqrsp_monitor_t reqrsp_monitor = new (master_dv);
  // Reqrsp Monitor.
  initial begin
    @(posedge rst_n);
    reqrsp_monitor.monitor();
  end

  // TCDM Monitor
  typedef tcdm_test::tcdm_monitor #(
    // tcdm interface parameters
    .AW ( AW ),
    .DW ( DW ),
    .user_t (logic),
    // Stimuli application and test time
    .TA ( ApplTime ),
    .TT ( TestTime )
  ) tcdm_monitor_t;

  tcdm_monitor_t tcdm_monitor = new (slave_dv);
  initial begin
    @(posedge rst_n);
    tcdm_monitor.monitor();
  end

  // ----------
  // Scoreboard
  // ----------
  int unsigned nr_transactions;
  /// Make sure that each transaction on the input side is observeable on the
  /// output.
  initial begin
    forever begin
      automatic reqrsp_test::req_t req;
      automatic reqrsp_test::rsp_t rsp;
      automatic tcdm_test::req_t tcdm_req;
      automatic tcdm_test::rsp_t tcdm_rsp;
      reqrsp_monitor.req_mbx.get(req);
      reqrsp_monitor.rsp_mbx.get(rsp);
      tcdm_monitor.req_mbx.get(tcdm_req);
      tcdm_monitor.rsp_mbx.get(tcdm_rsp);
      nr_transactions++;
      assert(tcdm_req.addr == req.addr)
        else $error("Expected `%h` got `%h`", req.addr, tcdm_req.addr);
      assert(tcdm_req.write == req.write);
      assert(tcdm_req.amo == req.amo);
      assert(tcdm_req.data == req.data);
      assert(tcdm_req.strb == req.strb);
      assert(tcdm_rsp.data == rsp.data) else $error("Responses didn't match.");

    end
  end

  final begin
    assert(reqrsp_monitor.req_mbx.num() == 0);
    assert(reqrsp_monitor.req_mbx.num() == 0);
    assert(tcdm_monitor.req_mbx.num() == 0);
    assert(tcdm_monitor.rsp_mbx.num() == 0);
    $info("Finished with %d transactions.", nr_transactions);
  end
endmodule
