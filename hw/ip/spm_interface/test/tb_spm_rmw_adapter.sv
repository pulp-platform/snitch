// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Authors:
// - Tim Fischer <fischeti@iis.ee.ethz.ch>

`include "spm_interface/assign.svh"

module tb_spm_rmw_adapter
  #(
    parameter int unsigned AddrWidth = 32,
    parameter int unsigned DataWidth = 32,
    parameter int unsigned StrbWidth = AddrWidth / 8,

    localparam type addr_t = logic [AddrWidth-1:0],
    localparam type data_t = logic [DataWidth-1:0],
    localparam type strb_t = logic [StrbWidth-1:0]
    );


  localparam time          ClkPeriod = 10ns;
  localparam time          ApplTime =  0ns;
  localparam time          TestTime =  10ns;

  logic                  clk, rst_n;

  SPM_BUS #(
            .ADDR_WIDTH ( AddrWidth ),
            .DATA_WIDTH ( DataWidth )
            ) spm_bus_master ();

  SPM_BUS_DV #(
               .ADDR_WIDTH ( AddrWidth ),
               .DATA_WIDTH ( DataWidth )
               ) spm_bus_master_dv (clk);

  SPM_BUS #(
            .ADDR_WIDTH ( AddrWidth ),
            .DATA_WIDTH ( DataWidth )
            ) spm_bus_slave ();

  SPM_BUS_DV #(
               .ADDR_WIDTH ( AddrWidth ),
               .DATA_WIDTH ( DataWidth )
               ) spm_bus_slave_dv ( clk );

  assign spm_bus_slave.strb = '1;

  `SPM_ASSIGN(spm_bus_master, spm_bus_master_dv)
  `SPM_ASSIGN(spm_bus_slave_dv, spm_bus_slave)

  // ------
  // Driver
  // ------
  spm_test::rand_spm_master
    #(
      .AW ( AddrWidth ),
      .DW ( DataWidth ),
      .TA ( ApplTime ),
      .TT ( TestTime )
      ) spm_rand_master = new(spm_bus_master_dv);

  spm_test::rand_spm_slave
    #(
      .AW ( AddrWidth ),
      .DW ( DataWidth ),
      // Right now this module needs an immediate valid response.
      .TA ( ApplTime ),
      .TT ( TestTime )
      ) spm_rand_slave = new(spm_bus_slave_dv);

  initial begin

    spm_rand_master.reset();
    repeat(20) @(posedge clk);
    spm_rand_master.run(5);


  end // initial begin

  initial begin

    spm_rand_slave.reset();
    repeat(20) @(posedge clk);
    spm_rand_slave.run();

  end // initial begin

  // ----------
  // DUT
  // ----------

  spm_rmw_adapter
    #(
      .AddrWidth(AddrWidth),
      .DataWidth(DataWidth),
      .StrbWidth(StrbWidth)
      ) dut_i
      (
       .clk_i(clk),
       .rst_ni(rst_n),

       .mem_valid_i(spm_bus_master.valid),
       .mem_ready_o(spm_bus_master.ready),
       .mem_addr_i(spm_bus_master.addr),
       .mem_wdata_i(spm_bus_master.wdata),
       .mem_strb_i(spm_bus_master.strb),
       .mem_we_i(spm_bus_master.we),
       .mem_rvalid_o(spm_bus_master.rvalid),
       .mem_rdata_o(spm_bus_master.rdata),

       .mem_valid_o(spm_bus_slave.valid),
       .mem_ready_i(spm_bus_slave.ready),
       .mem_addr_o(spm_bus_slave.addr),
       .mem_wdata_o(spm_bus_slave.wdata),
       .mem_we_o(spm_bus_slave.we),
       .mem_rvalid_i(spm_bus_slave.rvalid),
       .mem_rdata_i(spm_bus_slave.rdata)
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
