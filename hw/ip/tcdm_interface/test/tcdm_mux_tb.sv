// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

`include "tcdm_interface/assign.svh"

/// Testbench for the `tcdm_mux`. Based on the `reqrsp_mux_tb`, see that
/// testbench for a more indepth and commented version. This one just
/// instantiates the right tcdm drivers.
module tcdm_mux_tb import reqrsp_pkg::*; #(
  parameter int unsigned AW = 32,
  parameter int unsigned DW = 32,
  parameter int unsigned NrPorts = 4,
  parameter int unsigned RespDepth = 2,
  parameter int unsigned RegisterReq = 1,
  parameter int unsigned NrRandomTransactions = 1000
);
  localparam time ClkPeriod = 10ns;
  localparam time ApplTime =  2ns;
  localparam time TestTime =  8ns;

  logic  clk, rst_n;

  TCDM_BUS #(
    .ADDR_WIDTH ( AW ),
    .DATA_WIDTH ( DW ),
    .user_t (logic)
  ) master [NrPorts] ();

  TCDM_BUS_DV #(
    .ADDR_WIDTH ( AW ),
    .DATA_WIDTH ( DW ),
    .user_t (logic)
  ) master_dv [NrPorts] (clk);

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

  tcdm_mux_intf #(
    .NrPorts (NrPorts),
    .AddrWidth (AW),
    .DataWidth (DW),
    .user_t (logic),
    .RespDepth (RespDepth)
  ) dut (
    .clk_i (clk),
    .rst_ni (rst_n),
    .slv (master),
    .mst (slave)
  );

  `TCDM_ASSIGN(slave_dv, slave)
  for (genvar i = 0; i < NrPorts; i++) begin : gen_if_assignment
    `TCDM_ASSIGN(master[i], master_dv[i])
  end

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

  // -------
  // Monitor
  // -------
  typedef tcdm_test::tcdm_monitor #(
    // tcdm bus interface paramaters;
    .AW ( AW ),
    .DW ( DW ),
    // Stimuli application and test time
    .TA ( ApplTime ),
    .TT ( TestTime )
  ) tcdm_monitor_t;

  tcdm_monitor_t tcdm_slv_monitor = new (slave_dv);
  // tcdm Monitor.
  initial begin
    @(posedge rst_n);
    tcdm_slv_monitor.monitor();
  end

  tcdm_monitor_t tcdm_mst_monitor [NrPorts];
  for (genvar i = 0; i < NrPorts; i++) begin : gen_mst_mon
    initial begin
      tcdm_mst_monitor[i] = new (master_dv[i]);
      @(posedge rst_n);
      tcdm_mst_monitor[i].monitor();
    end
  end

  // ------
  // Driver
  // ------
  typedef tcdm_test::rand_tcdm_master #(
    // tcdm bus interface paramaters;
    .AW ( AW ),
    .DW ( DW ),
    // Stimuli application and test time
    .TA ( ApplTime ),
    .TT ( TestTime )
  ) tcdm_rand_master_t;

  tcdm_rand_master_t rand_tcdm_master [NrPorts];
  for (genvar i = 0; i < NrPorts; i++) begin : gen_mst_driver
    initial begin
      rand_tcdm_master[i] = new (master_dv[i]);
      rand_tcdm_master[i].reset();
      @(posedge rst_n);
      rand_tcdm_master[i].run(NrRandomTransactions);
    end
  end

  typedef tcdm_test::rand_tcdm_slave #(
    // tcdm bus interface paramaters;
    .AW ( AW ),
    .DW ( DW ),
    // Stimuli application and test time
    .TA ( ApplTime ),
    .TT ( TestTime )
  ) tcdm_rand_slave_t;

  tcdm_rand_slave_t rand_tcdm_slave = new (slave_dv);

  // tcdm Slave.
  initial begin
    rand_tcdm_slave.reset();
    @(posedge rst_n);
    rand_tcdm_slave.run();
  end

  // ----------
  // Scoreboard
  // ----------
  int unsigned nr_transactions = 0;
  initial begin
    forever begin
      automatic tcdm_test::req_t req;
      automatic tcdm_test::rsp_t rsp;
      automatic bit arb_found = 0;
      tcdm_slv_monitor.req_mbx.get(req);
      tcdm_slv_monitor.rsp_mbx.get(rsp);
      nr_transactions++;
      // Check that this transaction has been valid at one of the request
      // ports.
      for (int i = 0; i < NrPorts; i++) begin
        // Check that the request mailbox contains at least one value, otherwise
        // one early finishing port can stall the rest. Also, if the request is
        // observeable on the output the input must have handshaked, so this is
        // a safe operation.
        if (tcdm_mst_monitor[i].req_mbx.num() != 0) begin
          automatic tcdm_test::req_t req_inp;
          automatic tcdm_test::rsp_t rsp_inp;
          tcdm_mst_monitor[i].req_mbx.peek(req_inp);
          tcdm_mst_monitor[i].rsp_mbx.peek(rsp_inp);
          if (req_inp.do_compare(req) && rsp_inp.do_compare(rsp)) begin
            tcdm_mst_monitor[i].req_mbx.get(req_inp);
            tcdm_mst_monitor[i].rsp_mbx.get(rsp_inp);
            arb_found |= 1;
            break;
          end
        end
      end

      assert(arb_found) else $error("No arbitration found.");
      if (nr_transactions == NrPorts * NrRandomTransactions) $finish;
    end
  end

  // Check that we have associated all transactions.
  final begin
    assert(tcdm_slv_monitor.req_mbx.num() == 0);
    assert(tcdm_slv_monitor.rsp_mbx.num() == 0);
    for (int i = 0; i < NrPorts; i++) begin
      assert(tcdm_mst_monitor[i].req_mbx.num() == 0);
      assert(tcdm_mst_monitor[i].rsp_mbx.num() == 0);
    end
    $display("Checked for non-empty mailboxes.");
    $display("Checked %0d transactions.", nr_transactions);
  end

endmodule
