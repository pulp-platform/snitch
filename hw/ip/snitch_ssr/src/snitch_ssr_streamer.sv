// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Fabian Schuiki <fschuiki@iis.ee.ethz.ch>
// Author: Paul Scheffler <paulsc@iis.ee.ethz.ch>

module snitch_ssr_streamer import snitch_ssr_pkg::*; #(
  parameter int unsigned NumSsrs    = 0,
  parameter int unsigned RPorts     = 0,
  parameter int unsigned WPorts     = 0,
  parameter int unsigned AddrWidth  = 0,
  parameter int unsigned DataWidth  = 0,
  parameter ssr_cfg_t [NumSsrs-1:0] SsrCfgs = '0,
  parameter logic [NumSsrs:0][4:0]  SsrRegs = '0,
  parameter type tcdm_user_t  = logic,
  parameter type tcdm_req_t   = logic,
  parameter type tcdm_rsp_t   = logic,
  /// Derived parameter *Do not override*
  parameter type addr_t = logic [AddrWidth-1:0],
  parameter type data_t = logic [DataWidth-1:0]
) (
  input  logic             clk_i,
  input  logic             rst_ni,
  // Access to configuration registers (REG_BUS).
  input  logic [11:0]      cfg_word_i,
  input  logic             cfg_write_i, // 0 = read, 1 = write
  output logic [31:0]      cfg_rdata_o,
  input  logic [31:0]      cfg_wdata_i,
  // Read and write streams coming from the processor.
  input  logic  [RPorts-1:0][4:0] ssr_raddr_i,
  output data_t [RPorts-1:0]      ssr_rdata_o,
  input  logic  [RPorts-1:0]      ssr_rvalid_i,
  output logic  [RPorts-1:0]      ssr_rready_o,
  input  logic  [RPorts-1:0]      ssr_rdone_i,

  input  logic  [WPorts-1:0][4:0] ssr_waddr_i,
  input  data_t [WPorts-1:0]      ssr_wdata_i,
  input  logic  [WPorts-1:0]      ssr_wvalid_i,
  output logic  [WPorts-1:0]      ssr_wready_o,
  input  logic  [WPorts-1:0]      ssr_wdone_i,
  // Ports into memory.
  output tcdm_req_t [NumSsrs-1:0] mem_req_o,
  input  tcdm_rsp_t [NumSsrs-1:0] mem_rsp_i,

  input  addr_t            tcdm_start_address_i
);

  data_t [NumSsrs-1:0] lane_rdata;
  data_t [NumSsrs-1:0] lane_wdata;
  logic  [NumSsrs-1:0] lane_write;
  logic  [NumSsrs-1:0] lane_valid;
  logic  [NumSsrs-1:0] lane_ready;

  logic [4:0]       dmcfg_word;
  logic [7:0]       dmcfg_upper_addr;
  logic [2:0][31:0] dmcfg_rdata;
  logic [2:0]       dmcfg_strobe; // which data mover is currently addressed

  snitch_ssr_switch #(
    .DataWidth ( DataWidth  ),
    .NumSsrs   ( NumSsrs    ),
    .RPorts    ( RPorts     ),
    .WPorts    ( WPorts     ),
    .SsrRegs   ( SsrRegs    )
  ) i_switch (
    .clk_i,
    .rst_ni,
    .ssr_raddr_i,
    .ssr_rdata_o,
    .ssr_rvalid_i,
    .ssr_rready_o,
    .ssr_rdone_i,
    .ssr_waddr_i,
    .ssr_wdata_i,
    .ssr_wvalid_i,
    .ssr_wready_o,
    .ssr_wdone_i,
    .lane_rdata_i ( lane_rdata ),
    .lane_wdata_o ( lane_wdata ),
    .lane_write_o ( lane_write ),
    .lane_valid_i ( lane_valid ),
    .lane_ready_o ( lane_ready )
  );

  for (genvar i = 0; i < NumSsrs; i++) begin : gen_ssrs
    snitch_ssr #(
      .Cfg          ( SsrCfgs [i] ),
      .AddrWidth    ( AddrWidth   ),
      .DataWidth    ( DataWidth   ),
      .tcdm_user_t  ( tcdm_user_t ),
      .tcdm_req_t   ( tcdm_req_t  ),
      .tcdm_rsp_t   ( tcdm_rsp_t  )
    ) i_ssr (
      .clk_i,
      .rst_ni,
      .cfg_wdata_i,
      .cfg_word_i     ( dmcfg_word        ),
      .cfg_write_i    ( cfg_write_i & dmcfg_strobe[i] ),
      .cfg_rdata_o    ( dmcfg_rdata  [i]  ),
      .lane_rdata_o   ( lane_rdata   [i]  ),
      .lane_wdata_i   ( lane_wdata   [i]  ),
      .lane_valid_o   ( lane_valid   [i]  ),
      .lane_ready_i   ( lane_ready   [i]  ),
      .mem_req_o      ( mem_req_o    [i]  ),
      .mem_rsp_i      ( mem_rsp_i    [i]  ),
      .tcdm_start_address_i
    );
  end

  // Determine which data movers are addressed via the config interface. We
  // use the upper address bits to select one of the data movers, or select
  // all if the bits are all 1.
  always_comb begin
    dmcfg_word = cfg_word_i[4:0];
    dmcfg_upper_addr = cfg_word_i[11:7];
    dmcfg_strobe = (dmcfg_upper_addr == '1 ? '1 : (1 << dmcfg_upper_addr));
    cfg_rdata_o = dmcfg_rdata[dmcfg_upper_addr];
  end

endmodule
