// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>

`include "mem_interface/assign.svh"

/// Testbench for `wide_narrow_mux`.
module mem_wide_narrow_mux_tb #(
  parameter int unsigned AW = 32,
  parameter int unsigned DW_NARROW = 64,
  parameter int unsigned DW_WIDE = 512,
  parameter int unsigned MemoryLatency = 1,
  parameter int unsigned NrRandomTransactions = 1000
);

  localparam int unsigned NrPorts = DW_WIDE / DW_NARROW;
  localparam time ClkPeriod = 10ns;
  localparam time ApplTime =  2ns;
  localparam time TestTime =  8ns;

  logic  clk, rst_n;

  MEM_BUS #(
    .ADDR_WIDTH ( AW ),
    .DATA_WIDTH ( DW_NARROW ),
    .user_t (logic)
  ) master_narrow [NrPorts] ();

  MEM_BUS_DV #(
    .ADDR_WIDTH ( AW ),
    .DATA_WIDTH ( DW_NARROW ),
    .user_t (logic)
  ) master_narrow_dv [NrPorts] (clk);

  MEM_BUS #(
    .ADDR_WIDTH ( AW ),
    .DATA_WIDTH ( DW_WIDE ),
    .user_t (logic)
  ) master_wide ();

  MEM_BUS_DV #(
    .ADDR_WIDTH ( AW ),
    .DATA_WIDTH ( DW_WIDE ),
    .user_t (logic)
  ) master_wide_dv (clk);

  MEM_BUS #(
    .ADDR_WIDTH ( AW ),
    .DATA_WIDTH ( DW_NARROW ),
    .user_t (logic)
  ) slave [NrPorts] ();

  MEM_BUS_DV #(
    .ADDR_WIDTH ( AW ),
    .DATA_WIDTH ( DW_NARROW ),
    .user_t (logic)
  ) slave_dv [NrPorts] (clk);

  mem_wide_narrow_mux_intf #(
    .AddrWidth (AW),
    .NarrowDataWidth (DW_NARROW),
    .WideDataWidth (DW_WIDE),
    .user_t (logic),
    .MemoryLatency (MemoryLatency)
  ) dut (
    .clk_i (clk),
    .rst_ni (rst_n),
    .in_narrow (master_narrow),
    .in_wide (master_wide),
    .out (slave),
    .sel_wide_i (master_wide.q_valid)
  );


  for (genvar i = 0; i < NrPorts; i++) begin : gen_if_assignment
    `MEM_ASSIGN(slave_dv[i], slave[i])
    `MEM_ASSIGN(master_narrow[i], master_narrow_dv[i])
  end
  `MEM_ASSIGN(master_wide, master_wide_dv)

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
  typedef mem_test::rand_mem_master #(
    .AW ( AW ),
    .DW ( DW_NARROW ),
    .TA ( ApplTime ),
    .TT ( TestTime )
  ) mem_rand_master_narrow_t;

  mem_rand_master_narrow_t rand_mem_master_narrow [NrPorts];
  for (genvar i = 0; i < NrPorts; i++) begin : gen_mst_driver
    initial begin
      rand_mem_master_narrow[i] = new (master_narrow_dv[i]);
      rand_mem_master_narrow[i].reset();
      @(posedge rst_n);
      rand_mem_master_narrow[i].run(NrRandomTransactions);
    end
  end

  typedef mem_test::rand_mem_master #(
    .AW ( AW ),
    .DW ( DW_WIDE ),
    .TA ( ApplTime ),
    .TT ( TestTime )
  ) mem_rand_master_wide_t;

  mem_rand_master_wide_t rand_mem_master_wide  = new (master_wide_dv);
  initial begin
    rand_mem_master_wide.reset();
    @(posedge rst_n);
    rand_mem_master_wide.run(NrRandomTransactions);
    repeat(1000) @(posedge clk);
    $finish;
  end

  typedef mem_test::rand_mem_slave #(
    .AW ( AW ),
    .DW ( DW_NARROW ),
    // Right now this module needs an immediate valid response.
    .REQ_MIN_WAIT_CYCLES (0),
    .REQ_MAX_WAIT_CYCLES (0),
    .TA ( ApplTime ),
    .TT ( TestTime )
  ) mem_rand_slave_t;

  mem_rand_slave_t rand_mem_slave [NrPorts];
  for (genvar i = 0; i < NrPorts; i++) begin : gen_slv_driver
    initial begin
      rand_mem_slave[i] = new (slave_dv[i]);
      rand_mem_slave[i].reset();
      @(posedge rst_n);
      rand_mem_slave[i].run();
    end
  end

  // -------
  // Monitor
  // -------
  typedef mem_test::mem_monitor #(
    .AW ( AW ),
    .DW ( DW_NARROW ),
    .RespLatency (MemoryLatency),
    .TA ( ApplTime ),
    .TT ( TestTime )
  ) mem_monitor_narrow_t;

  typedef mem_test::mem_monitor #(
    .AW ( AW ),
    .DW ( DW_WIDE ),
    .RespLatency (MemoryLatency),
    .TA ( ApplTime ),
    .TT ( TestTime )
  ) mem_monitor_wide_t;

  mem_monitor_narrow_t mem_monitor_narrow [NrPorts];
  for (genvar i = 0; i < NrPorts; i++) begin : gen_monitor_narrow
    initial begin
      mem_monitor_narrow[i] = new (master_narrow_dv[i]);
      @(posedge rst_n);
      mem_monitor_narrow[i].monitor();
    end
  end

  mem_monitor_wide_t mem_monitor_wide  = new (master_wide_dv);
  initial begin
    @(posedge rst_n);
    mem_monitor_wide.monitor();
  end


  mem_monitor_narrow_t mem_monitor_out [NrPorts];
  for (genvar i = 0; i < NrPorts; i++) begin : gen_monitor_out
    initial begin
      mem_monitor_out[i] = new (slave_dv[i]);
      @(posedge rst_n);
      mem_monitor_out[i].monitor();
    end
  end

  // ----------
  // Scoreboard
  // ----------
  // For now we are "testing" the module with the DUT's internal assertions. The
  // testbench just drives a random pattern. This is mainly because the module
  // violates the protocol by requiring instant response of the wide data port.
  // Once the module moves to a more standardized and protocol compliant version
  // we can use the monitor circuit to implement a proper scoreboard.

  // initial begin
  //   forever begin
  //     automatic mem_monitor_wide_t::req_t wide_req;
  //     automatic mem_monitor_wide_t::rsp_t wide_rsp;
  //     automatic mem_monitor_narrow_t::req_t out_req [NrPorts];
  //     automatic mem_monitor_narrow_t::rsp_t out_rsp [NrPorts];

  //     for (int i = 0; i < NrPorts; i++) begin
  //       mem_monitor_out[i].req_mbx.get(out_req[i]);
  //       mem_monitor_out[i].rsp_mbx.get(out_rsp[i]);
  //       // $display("Got %h, rsp %h", out_req[i].addr, out_rsp[i].data);
  //     end
  //   end
  // end

endmodule
