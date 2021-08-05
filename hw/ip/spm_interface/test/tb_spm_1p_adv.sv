// Copyright 2021 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Authors:
// - Florian Zaruba <zarubaf@iis.ee.ethz.ch>

`include "spm_interface/assign.svh"

module tb_spm_1p_adv #(
  parameter int unsigned  AddrWidth = 4,
  parameter int unsigned  DataWidth = 64,
  parameter int unsigned  StrbWidth = DataWidth / 8,
  parameter  bit EnableInputPipeline  = 0,
  parameter  bit EnableOutputPipeline = 0,
  parameter  bit EnableECC            = 0
);

  localparam time ClkPeriod = 10ns;
  localparam time ApplTime =  0ns;
  localparam time TestTime =  10ns;

  localparam int unsigned NumWords = 2**AddrWidth;

  logic clk, rst_n;

  SPM_BUS #(
    .ADDR_WIDTH ( AddrWidth ),
    .DATA_WIDTH ( DataWidth )
  ) spm_bus_master ();

  SPM_BUS_DV #(
    .ADDR_WIDTH ( AddrWidth ),
    .DATA_WIDTH ( DataWidth )
  ) spm_bus_master_dv (clk);

  `SPM_ASSIGN(spm_bus_master, spm_bus_master_dv)

  // ------
  // Driver
  // ------
  spm_test::rand_spm_master #(
    .AW ( AddrWidth ),
    .DW ( DataWidth ),
    .TA ( ApplTime ),
    .TT ( TestTime )
  ) spm_rand_master = new(spm_bus_master_dv);

  initial begin
    spm_rand_master.reset();
    repeat(20) @(posedge clk);
    spm_rand_master.run(500);
    $finish;
  end

  // -------
  // Monitor
  // -------
  typedef spm_test::spm_monitor #(
    // spm bus interface paramaters;
    .AW ( AddrWidth ),
    .DW ( DataWidth ),
    // Stimuli application and test time
    .TA ( ApplTime ),
    .TT ( TestTime )
  ) spm_monitor_t;

  spm_monitor_t spm_master_monitor = new (spm_bus_master_dv);
  // spm Monitor.
  initial begin
    @(posedge rst_n);
    spm_master_monitor.monitor();
  end

  // ----------
  // Scoreboard
  // ----------
  logic [DataWidth-1:0] mem [2**AddrWidth];

  initial begin
    for (int i = 0; i < 2**AddrWidth; i++) mem[i] = 0;
    forever begin
      automatic spm_monitor_t::req_t req;
      automatic spm_monitor_t::rsp_t rsp;
      spm_master_monitor.req_mbx.get(req);
      spm_master_monitor.rsp_mbx.get(rsp);
      if (req.we) begin
        for (int i = 0; i < DataWidth/8; i++) begin
          if (req.strb[i]) begin
            mem[req.addr][i*8+:8] = req.wdata[i*8+:8];
          end
        end
      end else begin
        $info("Checking %x == %x", mem[req.addr], rsp.rdata);
        assert(rsp.rdata == mem[req.addr])
          else $error("Expected %x, got %x", mem[req.addr], rsp.rdata);
      end
    end
  end
  // ----
  // DUT
  // ----
  spm_1p_adv #(
    .NumWords (NumWords),
    .DataWidth (DataWidth),
    .ByteWidth (8),
    .SimInit ("zeros"),
    .EnableInputPipeline (EnableInputPipeline),
    .EnableOutputPipeline (EnableOutputPipeline),
    .EnableECC (EnableECC)
  ) dut (
    .clk_i (clk),
    .rst_ni (rst_n),
    .valid_i (spm_bus_master.valid),
    .ready_o (spm_bus_master.ready),
    .addr_i (spm_bus_master.addr),
    .wdata_i (spm_bus_master.wdata),
    .be_i (spm_bus_master.strb),
    .we_i (spm_bus_master.we),
    .rvalid_o (spm_bus_master.rvalid),
    .rdata_o (spm_bus_master.rdata),
    .rerror_o ()
  );

  // ----------------
  // Clock generation
  // ----------------
  initial begin
    rst_n = 0;
    repeat (5) begin
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
