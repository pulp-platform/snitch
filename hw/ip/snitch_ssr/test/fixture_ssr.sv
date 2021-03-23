// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Paul Scheffler <paulsc@iis.ee.ethz.ch>

`include "tcdm_interface/typedef.svh"
`include "tcdm_interface/assign.svh"

module fixture_ssr;

  // ------------
  //  Parameters
  // ------------

  // Testbench parameters
  localparam bit DebugLog = 0;

  // Timing parameters
  localparam time TCK = 10ns;
  localparam time TA  = 2ns;
  localparam time TT  = 8ns;
  localparam int unsigned RstCycles = 10;

  // TCDM parameters
  parameter int unsigned AddrWidth    = 64;
  parameter int unsigned DataWidth    = 32;
  parameter int unsigned SSRNrCredits = 4;

  // TCDM derived parameters
  localparam int unsigned MemWordBytes      = DataWidth/8;
  localparam int unsigned MemWordAddrBits   = $clog2(MemWordBytes);
  localparam int unsigned MemWordAddrWidth  = AddrWidth - MemWordAddrBits;

  // TCDM types
  typedef logic [AddrWidth-1:0]   addr_t;
  typedef logic [DataWidth-1:0]   data_t;
  typedef logic [DataWidth/8-1:0] strb_t;
  typedef logic                   user_t;
  `TCDM_TYPEDEF_ALL(tcdm, addr_t, data_t, strb_t, user_t);

  // -----------------
  //  Clock and reset
  // -----------------

  logic clk;
  logic rst_n;

  // Clock and reset generator
  clk_rst_gen #(
    .ClkPeriod    ( TCK       ),
    .RstClkCycles ( RstCycles )
  ) i_clk_rst_gen (
    .clk_o  ( clk   ),
    .rst_no ( rst_n )
  );

  // Wait for reset to start
  task automatic wait_for_reset_start;
    @(negedge rst_n);
  endtask

  // Wait for reset to end
  task automatic wait_for_reset_end;
    @(posedge rst_n);
    @(posedge clk);
  endtask

  // -----
  //  DUT
  // -----

  // DUT signals
  logic [4:0]   cfg_word_i;
  logic         cfg_write_i;
  logic [31:0]  cfg_rdata_o;
  logic [31:0]  cfg_wdata_i;
  logic         lane_valid_o;
  logic         lane_ready_i;
  tcdm_req_t    mem_req_o;
  tcdm_rsp_t    mem_rsp_i;
  logic [DataWidth-1:0] lane_rdata_o;
  logic [DataWidth-1:0] lane_wdata_i;
  logic [AddrWidth-1:0] tcdm_start_address_i = '0;

  // Device Under Test (DUT)
  snitch_ssr #(
    .AddrWidth    ( AddrWidth    ),
    .DataWidth    ( DataWidth    ),
    .SSRNrCredits ( SSRNrCredits ),
    .tcdm_req_t   ( tcdm_req_t   ),
    .tcdm_rsp_t   ( tcdm_rsp_t   )
  ) i_snitch_ssr (
    .clk_i          ( clk       ),
    .rst_ni         ( rst_n     ),
    .cfg_word_i,
    .cfg_write_i,
    .cfg_rdata_o,
    .cfg_wdata_i,
    .lane_rdata_o,
    .lane_wdata_i,
    .lane_valid_o,
    .lane_ready_i,
    .mem_req_o,
    .mem_rsp_i,
    .tcdm_start_address_i
  );

  // Dynamically change TCDM base address
  task automatic set_tcdm_start_address(addr_t val);
    tcdm_start_address_i = val;
  endtask

  // ----------------
  //  TCDM interface
  // ----------------

  // Associative (maximum-size) TCDM: models full memory space
  data_t memory [bit [MemWordAddrWidth-1:0]];

  // TCDM (memory) bus interface
  TCDM_BUS_DV #(
    .ADDR_WIDTH ( AddrWidth ),
    .DATA_WIDTH ( DataWidth ),
    .user_t     ( user_t    )
  ) tcdm_bus (clk);

  // Connect DUT to TCDM bus
  `TCDM_ASSIGN_FROM_REQ(tcdm_bus, mem_req_o)
  `TCDM_ASSIGN_TO_RESP(mem_rsp_i, tcdm_bus)

  // TCDM driver
  tcdm_test_extra::tcdm_driver_nonrand #(
    .AW     ( AddrWidth ),
    .DW     ( DataWidth ),
    .user_t ( user_t    ),
    .TA     ( TA        ),
    .TT     ( TT        ),
    .req_chan_t ( tcdm_req_chan_t ),
    .rsp_chan_t ( tcdm_rsp_chan_t )
  ) tcdm_drv = new(tcdm_bus);

  // Receive and process TCDM requests
  initial begin
    // Reset driver
    @(negedge rst_n);
    tcdm_drv.reset_slave();
    @(posedge rst_n);
    // Serve TCDM until testbench ends
    forever begin
      automatic tcdm_req_t req;
      automatic tcdm_rsp_t rsp;
      // Receive request
      tcdm_drv.recv_req(req.q);
      // Process Write
      if (req.q.write) begin
        if (DebugLog) $write("Write to 0x%x: 0x%x, strobe 0b%b ... ",
            req.q.addr, req.q.data, req.q.strb);
        for (int i = 0; i < DataWidth/8; i++) begin
          if (req.q.strb[i])
            memory[req.q.addr >> MemWordAddrBits][i*8 +: 8] = req.q.data[i*8 +: 8];
        end
      // Process Read
      end else begin
        rsp.p.data = memory[req.q.addr >> MemWordAddrBits];
        if (DebugLog) $write("Read from 0x%x: data 0x%x ... ", req.q.addr, rsp.p.data);
        tcdm_drv.send_rsp(rsp.p);
        if (DebugLog) $display("OK");
      end
    end
  end

  // ------------------
  //  Config interface
  // ------------------

  // Register bus interface for configuration
  REG_BUS #(
    .ADDR_WIDTH ( 5   ),
    .DATA_WIDTH ( 32  )
  ) cfg_bus (clk);

  // Connect DUT to config bus
  assign cfg_word_i     = cfg_bus.addr;
  assign cfg_write_i    = cfg_bus.write;
  assign cfg_wdata_i    = cfg_bus.wdata;
  assign cfg_bus.rdata  = cfg_rdata_o;
  assign cfg_bus.ready  = 1'b1;   // SSR always ready for config write

  // Register bus driver
  reg_test::reg_driver #(
    .AW ( 5  ),
    .DW ( 32 ),
    .TA ( TA ),
    .TT ( TT )
  ) cfg_drv = new(cfg_bus);

  // Reset driver
  initial begin
    @(negedge rst_n);
    cfg_drv.reset_master();
    @(posedge rst_n);
  end

  // --------------------
  //  Register interface
  // --------------------

  // Register bus interface for hypothetical regfile
  // TODO: this is a bit hacky. Provide a proper SSR interface?
  REG_BUS #(
    .ADDR_WIDTH ( 1         ),  // unused
    .DATA_WIDTH ( DataWidth )
  ) ssr_bus (clk);

  // Register bus driver
  reg_test::reg_driver #(
    .AW ( 1         ),
    .DW ( DataWidth ),
    .TA ( TA        ),
    .TT ( TT        )
  ) ssr_drv = new(ssr_bus);

  // Swap valid and ready to emulate 3-way handshake
  assign lane_wdata_i   = ssr_bus.wdata;
  assign lane_ready_i   = ssr_bus.valid;
  assign ssr_bus.rdata  = lane_rdata_o;
  assign ssr_bus.ready  = lane_valid_o;

  // Reset driver
  initial begin
    @(negedge rst_n);
    ssr_drv.reset_master();
    @(posedge rst_n);
  end

endmodule
