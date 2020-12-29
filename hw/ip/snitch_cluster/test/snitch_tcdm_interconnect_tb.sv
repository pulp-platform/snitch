// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

`include "tcdm_interface/typedef.svh"
`include "tcdm_interface/assign.svh"
`include "mem_interface/typedef.svh"
`include "mem_interface/assign.svh"

module snitch_tcdm_interconnect_tb #(
  parameter int unsigned NrInput = 4,
  parameter int unsigned NrOutput = 8,
  parameter int unsigned NrRandomTransactions = 1000
);

  localparam time ClkPeriod = 10ns;
  localparam time ApplTime =  2ns;
  localparam time TestTime =  8ns;

  localparam int unsigned AddrWidth = 32;
  localparam int unsigned MemAddrWidth = 15;
  localparam int unsigned DataWidth = 32;
  localparam int unsigned RespLatency = 1;

  localparam int unsigned ByteOffset = $clog2(DataWidth/8);
  localparam int unsigned SelWidth = cf_math_pkg::idx_width(NrOutput);

  typedef logic [AddrWidth-1:0] addr_t;
  typedef logic [MemAddrWidth-1:0] tcdm_addr_t;
  typedef logic [DataWidth-1:0] data_t;
  typedef logic [DataWidth/8-1:0] strb_t;
  typedef logic user_t;

  logic  clk, rst_n;

  `TCDM_TYPEDEF_ALL(tcdm, addr_t, data_t, strb_t, user_t)
  `MEM_TYPEDEF_ALL(mem, tcdm_addr_t, data_t, strb_t, user_t)

  tcdm_req_t [NrInput-1:0] tcdm_req;
  tcdm_rsp_t [NrInput-1:0] tcdm_rsp;
  mem_req_t [NrOutput-1:0] mem_req;
  mem_rsp_t [NrOutput-1:0] mem_rsp;

  snitch_tcdm_interconnect #(
    .NumInp (NrInput),
    .NumOut (NrOutput),
    .tcdm_req_t (tcdm_req_t),
    .tcdm_rsp_t (tcdm_rsp_t),
    .mem_req_t (mem_req_t),
    .mem_rsp_t (mem_rsp_t),
    .MemAddrWidth (MemAddrWidth),
    .DataWidth (DataWidth),
    .MemoryResponseLatency (RespLatency)
  ) dut (
    .clk_i (clk),
    .rst_ni (rst_n),
    .req_i (tcdm_req),
    .rsp_o (tcdm_rsp),
    .mem_req_o (mem_req),
    .mem_rsp_i (mem_rsp)
  );

  TCDM_BUS_DV #(
    .ADDR_WIDTH ( AddrWidth ),
    .DATA_WIDTH ( DataWidth ),
    .user_t (logic)
  ) master_dv [NrInput-1:0](clk);


  MEM_BUS_DV #(
    .ADDR_WIDTH ( MemAddrWidth ),
    .DATA_WIDTH ( DataWidth ),
    .user_t (logic)
  ) slave_dv [NrOutput-1:0](clk);

  for (genvar i = 0; i < NrInput; i++) begin : gen_input_assign
    `TCDM_ASSIGN_TO_REQ(tcdm_req[i], master_dv[i]);
    `TCDM_ASSIGN_FROM_RESP(master_dv[i], tcdm_rsp[i]);
  end

  for (genvar i = 0; i < NrOutput; i++) begin : gen_output_assign
    `MEM_ASSIGN_FROM_REQ(slave_dv[i], mem_req[i]);
    `MEM_ASSIGN_TO_RESP(mem_rsp[i], slave_dv[i]);
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

  // ------
  // Driver
  // ------
  typedef tcdm_test::rand_tcdm_master #(
    // tcdm bus interface paramaters;
    .AW ( AddrWidth ),
    .DW ( DataWidth ),
    // Stimuli application and test time
    .TA ( ApplTime ),
    .TT ( TestTime )
  ) tcdm_driver_t;

  tcdm_driver_t rand_tcdm_master [NrInput];

  for (genvar i = 0; i < NrInput; i++) begin : gen_mst_driver
    initial begin
      rand_tcdm_master[i] = new (master_dv[i]);
      rand_tcdm_master[i].reset();
      @(posedge rst_n);
      rand_tcdm_master[i].run(NrRandomTransactions);
      repeat (100) @(posedge clk);
      $finish;
    end
  end

  typedef mem_test::rand_mem_slave #(
    .AW ( MemAddrWidth ),
    .DW ( DataWidth ),
    .TA ( ApplTime ),
    .TT ( TestTime )
  ) mem_rand_slave_t;

  mem_rand_slave_t rand_mem_slave [NrOutput];
  for (genvar i = 0; i < NrOutput; i++) begin : gen_slv_driver
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
    .AW ( MemAddrWidth ),
    .DW ( DataWidth ),
    .RespLatency ( RespLatency ),
    .TA ( ApplTime ),
    .TT ( TestTime )
  ) mem_monitor_t;

  mem_monitor_t mem_monitor [NrOutput];
  for (genvar i = 0; i < NrOutput; i++) begin : gen_monitor_narrow
    initial begin
      mem_monitor[i] = new (slave_dv[i]);
      @(posedge rst_n);
      mem_monitor[i].monitor();
    end
  end

  typedef tcdm_test::tcdm_monitor #(
    // tcdm bus interface paramaters;
    .AW ( AddrWidth ),
    .DW ( DataWidth ),
    // Stimuli application and test time
    .TA ( ApplTime ),
    .TT ( TestTime )
  ) tcdm_monitor_t;

  tcdm_monitor_t tcdm_mst_monitor [NrInput];
  for (genvar i = 0; i < NrInput; i++) begin : gen_mst_mon
    initial begin
      tcdm_mst_monitor[i] = new (master_dv[i]);
      @(posedge rst_n);
      tcdm_mst_monitor[i].monitor();
    end
  end

  // ----------
  // Scoreboard
  // ----------
  for (genvar i = 0; i < NrInput; i++) begin : gen_sb
    initial begin
      forever begin
        automatic tcdm_test::req_t req;
        automatic tcdm_test::rsp_t rsp;
        automatic mem_monitor_t::req_t mem_req;
        automatic mem_monitor_t::rsp_t mem_rsp;
        tcdm_mst_monitor[i].req_mbx.get(req);
        tcdm_mst_monitor[i].rsp_mbx.get(rsp);
        // Figure out which slave should have the right slot.
        mem_monitor[req.addr[ByteOffset+:SelWidth]].req_mbx.get(mem_req);
        mem_monitor[req.addr[ByteOffset+:SelWidth]].rsp_mbx.get(mem_rsp);
        assert(req.addr[ByteOffset+SelWidth+:MemAddrWidth] == mem_req.addr)
          else $error("Expected `%h` got `%h`",
                      req.addr[ByteOffset+SelWidth+:MemAddrWidth], mem_req.addr);
        assert(req.amo == mem_req.amo);
        assert(req.write == mem_req.write);
        assert(req.data == mem_req.data);
        assert(req.strb == mem_req.strb);
        assert(req.user == mem_req.user);
        assert(mem_rsp.data == rsp.data);
      end
    end
  end

endmodule
