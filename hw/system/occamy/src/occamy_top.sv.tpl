// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>
// Author: Fabian Schuiki <fschuiki@iis.ee.ethz.ch>
//
// AUTOMATICALLY GENERATED by genoccamy.py; edit the script instead.

`include "common_cells/registers.svh"

module ${name}_top
  import ${name}_pkg::*;
(
  input  logic        clk_i,
  input  logic        rst_ni,
  /// Peripheral clock
  input  logic        clk_periph_i,
  input  logic        rst_periph_ni,
  /// Real-time clock (for time keeping)
  input  logic        rtc_i,
  input  logic        test_mode_i,
  input  logic [1:0]  chip_id_i,
  input  logic [1:0]  boot_mode_i,
  // pad cfg
  output logic [31:0]      pad_slw_o,
  output logic [31:0]      pad_smt_o,
  output logic [31:0][1:0] pad_drv_o,
  // `uart` Interface
  output logic        uart_tx_o,
  input  logic        uart_rx_i,
  // `gpio` Interface
  input  logic [31:0] gpio_d_i,
  output logic [31:0] gpio_d_o,
  output logic [31:0] gpio_oe_o,
  output logic [31:0] gpio_puen_o,
  output logic [31:0] gpio_pden_o,
  // `jtag` Interface
  input  logic        jtag_trst_ni,
  input  logic        jtag_tck_i,
  input  logic        jtag_tms_i,
  input  logic        jtag_tdi_i,
  output logic        jtag_tdo_o,
  // `i2c` Interface
  output logic        i2c_sda_o,
  input  logic        i2c_sda_i,
  output logic        i2c_sda_en_o,
  output logic        i2c_scl_o,
  input  logic        i2c_scl_i,
  output logic        i2c_scl_en_o,
  // `SPI Host` Interface
  output logic        spim_sck_o,
  output logic        spim_sck_en_o,
  output logic [1:0]  spim_csb_o,
  output logic [1:0]  spim_csb_en_o,
  output logic [3:0]  spim_sd_o,
  output logic [3:0]  spim_sd_en_o,
  input        [3:0]  spim_sd_i,

  /// Boot ROM
  output ${soc_regbus_periph_xbar.out_bootrom.req_type()} bootrom_req_o,
  input  ${soc_regbus_periph_xbar.out_bootrom.rsp_type()} bootrom_rsp_i,

  /// Clk manager
  output ${soc_regbus_periph_xbar.out_clk_mgr.req_type()} clk_mgr_req_o,
  input  ${soc_regbus_periph_xbar.out_clk_mgr.rsp_type()} clk_mgr_rsp_i,

  /// HBI Config and APB Control
  output ${soc_regbus_periph_xbar.out_hbi_cfg.req_type()} hbi_cfg_req_o,
  input  ${soc_regbus_periph_xbar.out_hbi_cfg.rsp_type()} hbi_cfg_rsp_i,
  output ${apb_hbi_ctl.req_type()} apb_hbi_ctl_req_o,
  input  ${apb_hbi_ctl.rsp_type()} apb_hbi_ctl_rsp_i,
  /// HBM Config
  output ${apb_hbm_cfg.req_type()} apb_hbm_cfg_req_o,
  input  ${apb_hbm_cfg.rsp_type()} apb_hbm_cfg_rsp_i,
  output ${soc_regbus_periph_xbar.out_hbm_phy_cfg.req_type()} hbm_phy_cfg_req_o,
  input  ${soc_regbus_periph_xbar.out_hbm_phy_cfg.rsp_type()} hbm_phy_cfg_rsp_i,
  output ${soc_regbus_periph_xbar.out_hbm_seq.req_type()} hbm_seq_req_o,
  input  ${soc_regbus_periph_xbar.out_hbm_seq.rsp_type()} hbm_seq_rsp_i,
  /// PCIe/DDR Config
  output ${soc_regbus_periph_xbar.out_pcie_cfg.req_type()} pcie_cfg_req_o,
  input  ${soc_regbus_periph_xbar.out_pcie_cfg.rsp_type()} pcie_cfg_rsp_i,
  /// Chip specific control registers
  output ${soc_regbus_periph_xbar.out_chip_ctrl.req_type()} chip_ctrl_req_o,
  input  ${soc_regbus_periph_xbar.out_chip_ctrl.rsp_type()} chip_ctrl_rsp_i,
  // "external interrupts from uncore - "programmable"
  input logic [11:0] ext_irq_i,

  /// HBM2e Ports
% for i in range(nr_hbm_channels):
  output  ${hbm_xbar.__dict__["out_hbm_{}".format(i)].req_type()} hbm_${i}_req_o,
  input   ${hbm_xbar.__dict__["out_hbm_{}".format(i)].rsp_type()} hbm_${i}_rsp_i,
% endfor

  /// HBI Ports
  input   ${soc_wide_xbar.in_hbi.req_type()} hbi_wide_req_i,
  output  ${soc_wide_xbar.in_hbi.rsp_type()} hbi_wide_rsp_o,
  output  ${soc_wide_xbar.out_hbi.req_type()} hbi_wide_req_o,
  input   ${soc_wide_xbar.out_hbi.rsp_type()} hbi_wide_rsp_i,

  input   ${soc_narrow_xbar.in_hbi.req_type()} hbi_narrow_req_i,
  output  ${soc_narrow_xbar.in_hbi.rsp_type()} hbi_narrow_rsp_o,
  output  ${soc_narrow_xbar.out_hbi.req_type()} hbi_narrow_req_o,
  input   ${soc_narrow_xbar.out_hbi.rsp_type()} hbi_narrow_rsp_i,

  /// PCIe Ports
  output  ${soc_narrow_xbar.out_pcie.req_type()} pcie_axi_req_o,
  input   ${soc_narrow_xbar.out_pcie.rsp_type()} pcie_axi_rsp_i,

  input  ${soc_narrow_xbar.in_pcie.req_type()} pcie_axi_req_i,
  output ${soc_narrow_xbar.in_pcie.rsp_type()} pcie_axi_rsp_o,

  /// RMQ: Remote Quadrant Ports: AXI master/slave and GPIO
% for i in range(nr_remote_quadrants):
  output   ${soc_wide_xbar.__dict__["out_rmq_{}".format(i)].req_type()} rmq_${i}_wide_req_o,
  input  ${soc_wide_xbar.__dict__["out_rmq_{}".format(i)].rsp_type()} rmq_${i}_wide_rsp_i,
  input   ${soc_wide_xbar.__dict__["in_rmq_{}".format(i)].req_type()} rmq_${i}_wide_req_i,
  output  ${soc_wide_xbar.__dict__["in_rmq_{}".format(i)].rsp_type()} rmq_${i}_wide_rsp_o,
  output   ${soc_narrow_xbar.__dict__["out_rmq_{}".format(i)].req_type()} rmq_${i}_narrow_req_o,
  input  ${soc_narrow_xbar.__dict__["out_rmq_{}".format(i)].rsp_type()} rmq_${i}_narrow_rsp_i,
  input   ${soc_narrow_xbar.__dict__["in_rmq_{}".format(i)].req_type()} rmq_${i}_narrow_req_i,
  output  ${soc_narrow_xbar.__dict__["in_rmq_{}".format(i)].rsp_type()} rmq_${i}_narrow_rsp_o,
  output rmq_${i}_mst_out_t rmq_${i}_mst_o,
% endfor

  /// SRAM configuration
  input sram_cfgs_t sram_cfgs_i
);

  ${name}_soc_reg_pkg::${name}_soc_reg2hw_t soc_ctrl_out;
  ${name}_soc_reg_pkg::${name}_soc_hw2reg_t soc_ctrl_in, soc_ctrl_soc_in;
  logic [1:0] spm_rerror;

  always_comb begin
    soc_ctrl_in = soc_ctrl_soc_in;
    // External SoC register inputs
    soc_ctrl_in.boot_mode.d = boot_mode_i;
    soc_ctrl_in.chip_id.d = chip_id_i;
  end

  // Machine timer and machine software interrupt pending.
  logic [${cores-1}:0] mtip, msip;
  // Supervisor and machine-mode external interrupt pending.
  logic [1:0] eip;
  logic [0:0] debug_req;
  ${name}_interrupt_t irq;

  assign irq.ext_irq = ext_irq_i;

  //////////////////////////
  //   Peripheral Xbars   //
  //////////////////////////

  ${module}

  ///////////////////////////////
  //   Synchronous top level   //
  ///////////////////////////////

  // Peripheral Xbar connections
<%
  periph_axi_lite_soc2per = soc_narrow_xbar.out_periph.copy(name="periph_axi_lite_soc2per").declare(context)
  periph_axi_lite_per2soc = soc_narrow_xbar.in_periph.copy(name="periph_axi_lite_per2soc").declare(context)
  periph_regbus_soc2per = soc_narrow_xbar.out_regbus_periph.copy(name="periph_regbus_soc2per").declare(context)
%> \
  ${name}_soc i_${name}_soc (
    .clk_i,
    .rst_ni,
    .test_mode_i,
% for i in range(8):
    .hbm_${i}_req_o,
    .hbm_${i}_rsp_i,
% endfor
% for s in ("wide", "narrow"):
    .hbi_${s}_req_i,
    .hbi_${s}_rsp_o,
    .hbi_${s}_req_o,
    .hbi_${s}_rsp_i,
% endfor
    .pcie_axi_req_o,
    .pcie_axi_rsp_i,
    .pcie_axi_req_i,
    .pcie_axi_rsp_o,
    .periph_axi_lite_req_o ( periph_axi_lite_soc2per_req ),
    .periph_axi_lite_rsp_i ( periph_axi_lite_soc2per_rsp ),
    .periph_axi_lite_req_i ( periph_axi_lite_per2soc_req ),
    .periph_axi_lite_rsp_o ( periph_axi_lite_per2soc_rsp ),
    .periph_regbus_req_o ( periph_regbus_soc2per_req ),
    .periph_regbus_rsp_i ( periph_regbus_soc2per_rsp ),
    .soc_ctrl_out_i ( soc_ctrl_out ),
    .soc_ctrl_in_o ( soc_ctrl_soc_in ),
    .spm_rerror_o (spm_rerror),
    .mtip_i ( mtip ),
    .msip_i ( msip ),
    .eip_i ( eip ),
    .debug_req_i ( debug_req ),
    .sram_cfgs_i
  );

  // Connect AXI-lite master
  <% periph_axi_lite_soc2per \
      .cdc(context, "clk_periph_i", "rst_periph_ni", "axi_lite_from_soc_cdc") \
      .to_axi_lite(context, "axi_to_axi_lite_periph", to=soc_periph_xbar.in_soc) %> \
  // Connect AXI-lite slave
  <% soc_periph_xbar.out_soc \
      .cdc(context, "clk_i", "rst_ni", "axi_lite_to_soc_cdc") \
      .to_axi(context, "axi_lite_to_axi_periph", to=periph_axi_lite_per2soc) %> \
  // Connect Regbus master
  <% periph_regbus_soc2per \
      .cdc(context, "clk_periph_i", "rst_periph_ni", "periph_cdc") \
      .change_dw(context, 32, "axi_to_axi_lite_dw") \
      .to_axi_lite(context, "axi_to_axi_lite_regbus_periph") \
      .to_reg(context, "axi_lite_to_regbus_periph", to=soc_regbus_periph_xbar.in_soc) %> \


  //////////////////////
  // Remote Quadrants //
  //////////////////////

  /// Remote Quadrant Ports
% for i in range(nr_remote_quadrants):
  assign rmq_${i}_wide_req_o = ${soc_wide_xbar.__dict__["out_rmq_{}".format(i)].req_name()};
  assign ${soc_wide_xbar.__dict__["out_rmq_{}".format(i)].rsp_name()} = rmq_${i}_wide_rsp_i;
  assign rmq_${i}_narrow_req_o = ${soc_narrow_xbar.__dict__["out_rmq_{}".format(i)].req_name()};
  assign ${soc_narrow_xbar.__dict__["out_rmq_{}".format(i)].rsp_name()} = rmq_${i}_narrow_rsp_i;
  assign ${soc_wide_xbar.__dict__["in_rmq_{}".format(i)].req_name()} = rmq_${i}_wide_req_i;
  assign rmq_${i}_wide_rsp_o = ${soc_wide_xbar.__dict__["in_rmq_{}".format(i)].rsp_name()};
  assign ${soc_narrow_xbar.__dict__["in_rmq_{}".format(i)].req_name()} = rmq_${i}_narrow_req_i;
  assign rmq_${i}_narrow_rsp_o = ${soc_narrow_xbar.__dict__["in_rmq_{}".format(i)].rsp_name()};
% endfor

  /// GPIO signals
% for i, rq in enumerate(remote_quadrants):
  <% rm_cores = rq["nr_clusters"]*rq["nr_cluster_cores"] %>
  <% rm_core_off = lcl_cores + i*rm_cores %>
  assign rmq_${i}_mst_o.mtip = mtip[${rm_core_off+rm_cores-1}:${rm_core_off}];
  assign rmq_${i}_mst_o.msip = msip[${rm_core_off+rm_cores-1}:${rm_core_off}];
% endfor

  //////////////////////
  // HBI & HBM Config //
  //////////////////////

  // APB port for HBI
  <% soc_regbus_periph_xbar.out_hbi_ctl.to_apb(context, "apb_hbi_ctl", to=apb_hbi_ctl) %>
  assign apb_hbi_ctl_req_o = ${apb_hbi_ctl.req_name()};
  assign ${apb_hbi_ctl.rsp_name()} = apb_hbi_ctl_rsp_i;

  // APB port for HBM
  <% soc_regbus_periph_xbar.out_hbm_cfg.to_apb(context, "apb_hbm_cfg", to=apb_hbm_cfg) %>
  assign apb_hbm_cfg_req_o = ${apb_hbm_cfg.req_name()};
  assign ${apb_hbm_cfg.rsp_name()} = apb_hbm_cfg_rsp_i;
  assign hbm_phy_cfg_req_o = ${soc_regbus_periph_xbar.out_hbm_phy_cfg.req_name()};
  assign ${soc_regbus_periph_xbar.out_hbm_phy_cfg.rsp_name()} = hbm_phy_cfg_rsp_i;
  assign hbm_seq_req_o = ${soc_regbus_periph_xbar.out_hbm_seq.req_name()};
  assign ${soc_regbus_periph_xbar.out_hbm_seq.rsp_name()} = hbm_seq_rsp_i;

  ///////////
  // Debug //
  ///////////
  <% regbus_debug = soc_periph_xbar.out_debug.to_reg(context, "axi_lite_to_reg_debug") %>
  dm::hartinfo_t [0:0] hartinfo;
  assign hartinfo[0] = ariane_pkg::DebugHartInfo;

  logic          dmi_rst_n;
  dm::dmi_req_t  dmi_req;
  logic          dmi_req_valid;
  logic          dmi_req_ready;
  dm::dmi_resp_t dmi_resp;
  logic          dmi_resp_ready;
  logic          dmi_resp_valid;

  logic dbg_req;
  logic dbg_we;
  logic [${regbus_debug.aw-1}:0] dbg_addr;
  logic [${regbus_debug.dw-1}:0] dbg_wdata;
  logic [${regbus_debug.dw//8-1}:0] dbg_wstrb;
  logic [${regbus_debug.dw-1}:0] dbg_rdata;
  logic dbg_rvalid;

  reg_to_mem #(
    .AW(${regbus_debug.aw}),
    .DW(${regbus_debug.dw}),
    .req_t (${regbus_debug.req_type()}),
    .rsp_t (${regbus_debug.rsp_type()})
  ) i_reg_to_mem_dbg (
    .clk_i (${regbus_debug.clk}),
    .rst_ni (${regbus_debug.rst}),
    .reg_req_i (${regbus_debug.req_name()}),
    .reg_rsp_o (${regbus_debug.rsp_name()}),
    .req_o (dbg_req),
    .gnt_i (dbg_req),
    .we_o (dbg_we),
    .addr_o (dbg_addr),
    .wdata_o (dbg_wdata),
    .wstrb_o (dbg_wstrb),
    .rdata_i (dbg_rdata),
    .rvalid_i (dbg_rvalid),
    .rerror_i (1'b0)
  );

  `FFARN(dbg_rvalid, dbg_req, 1'b0, ${regbus_debug.clk}, ${regbus_debug.rst})

  logic        sba_req;
  logic [${regbus_debug.aw-1}:0] sba_addr;
  logic        sba_we;
  logic [${regbus_debug.dw-1}:0] sba_wdata;
  logic [${regbus_debug.dw//8-1}:0]  sba_strb;
  logic        sba_gnt;

  logic [${regbus_debug.dw-1}:0] sba_rdata;
  logic        sba_rvalid;

  logic [${regbus_debug.dw-1}:0] sba_addr_long;

  dm_top #(
    // .NrHarts (${cores}),
    .NrHarts (1),
    .BusWidth (${regbus_debug.dw}),
    .DmBaseAddress ('h0)
  ) i_dm_top (
    .clk_i (${regbus_debug.clk}),
    .rst_ni (${regbus_debug.rst}),
    .testmode_i (1'b0),
    .ndmreset_o (),
    .dmactive_o (),
    .debug_req_o (debug_req),
    .unavailable_i ('0),
    .hartinfo_i (hartinfo),
    .slave_req_i (dbg_req),
    .slave_we_i (dbg_we),
    .slave_addr_i ({${regbus_debug.dw-regbus_debug.aw}'b0, dbg_addr}),
    .slave_be_i (dbg_wstrb),
    .slave_wdata_i (dbg_wdata),
    .slave_rdata_o (dbg_rdata),
    .master_req_o (sba_req),
    .master_add_o (sba_addr_long),
    .master_we_o (sba_we),
    .master_wdata_o (sba_wdata),
    .master_be_o (sba_strb),
    .master_gnt_i (sba_gnt),
    .master_r_valid_i (sba_rvalid),
    .master_r_rdata_i (sba_rdata),
    .dmi_rst_ni (dmi_rst_n),
    .dmi_req_valid_i (dmi_req_valid),
    .dmi_req_ready_o (dmi_req_ready),
    .dmi_req_i (dmi_req),
    .dmi_resp_valid_o (dmi_resp_valid),
    .dmi_resp_ready_i (dmi_resp_ready),
    .dmi_resp_o (dmi_resp)
  );

  assign sba_addr = sba_addr_long[${regbus_debug.aw-1}:0];

  mem_to_axi_lite #(
    .MemAddrWidth (${regbus_debug.aw}),
    .AxiAddrWidth (${regbus_debug.aw}),
    .DataWidth (${regbus_debug.dw}),
    .MaxRequests (2),
    .AxiProt ('0),
    .axi_req_t (${soc_periph_xbar.in_debug.req_type()}),
    .axi_rsp_t (${soc_periph_xbar.in_debug.rsp_type()})
  ) i_mem_to_axi_lite (
    .clk_i (${regbus_debug.clk}),
    .rst_ni (${regbus_debug.rst}),
    .mem_req_i (sba_req),
    .mem_addr_i (sba_addr),
    .mem_we_i (sba_we),
    .mem_wdata_i (sba_wdata),
    .mem_be_i (sba_strb),
    .mem_gnt_o (sba_gnt),
    .mem_rsp_valid_o (sba_rvalid),
    .mem_rsp_rdata_o (sba_rdata),
    .mem_rsp_error_o (/* left open */),
    .axi_req_o (${soc_periph_xbar.in_debug.req_name()}),
    .axi_rsp_i (${soc_periph_xbar.in_debug.rsp_name()})

  );

  dmi_jtag #(
    .IdcodeValue (${name}_pkg::IDCode)
  ) i_dmi_jtag (
    .clk_i (${regbus_debug.clk}),
    .rst_ni (${regbus_debug.rst}),
    .testmode_i (1'b0),
    .dmi_rst_no (dmi_rst_n),
    .dmi_req_o (dmi_req),
    .dmi_req_valid_o (dmi_req_valid),
    .dmi_req_ready_i (dmi_req_ready),
    .dmi_resp_i (dmi_resp),
    .dmi_resp_ready_o (dmi_resp_ready),
    .dmi_resp_valid_i (dmi_resp_valid),
    .tck_i (jtag_tck_i),
    .tms_i (jtag_tms_i),
    .trst_ni (jtag_trst_ni),
    .td_i (jtag_tdi_i),
    .td_o (jtag_tdo_o),
    .tdo_oe_o ()
  );


  ///////////////
  //   CLINT   //
  ///////////////
  clint #(
    .reg_req_t ( ${soc_regbus_periph_xbar.out_clint.req_type()} ),
    .reg_rsp_t ( ${soc_regbus_periph_xbar.out_clint.rsp_type()} )
  ) i_clint (
    .clk_i (${soc_regbus_periph_xbar.out_clint.clk}),
    .rst_ni (${soc_regbus_periph_xbar.out_clint.rst}),
    .testmode_i (1'b0),
    .reg_req_i (${soc_regbus_periph_xbar.out_clint.req_name()}),
    .reg_rsp_o (${soc_regbus_periph_xbar.out_clint.rsp_name()}),
    .rtc_i (rtc_i),
    .timer_irq_o (mtip),
    .ipi_o (msip)
  );

  /////////////////////
  //   SOC CONTROL   //
  /////////////////////
  ${name}_soc_ctrl #(
    .reg_req_t ( ${soc_regbus_periph_xbar.out_soc_ctrl.req_type()} ),
    .reg_rsp_t ( ${soc_regbus_periph_xbar.out_soc_ctrl.rsp_type()} )
  ) i_soc_ctrl (
    .clk_i     ( clk_i  ),
    .rst_ni    ( rst_ni ),
    .reg_req_i ( ${soc_regbus_periph_xbar.out_soc_ctrl.req_name()} ),
    .reg_rsp_o ( ${soc_regbus_periph_xbar.out_soc_ctrl.rsp_name()} ),
    .reg2hw_o  ( soc_ctrl_out ),
    .hw2reg_i  ( soc_ctrl_in ),
    .event_ecc_rerror_i (spm_rerror),
    .intr_ecc_uncorrectable_o (irq.ecc_uncorrectable),
    .intr_ecc_correctable_o (irq.ecc_correctable)
  );

  //////////////////////
  //   CHIP CONTROL   //
  //////////////////////
  // Contains NDA and chip specific information.
  assign chip_ctrl_req_o = ${soc_regbus_periph_xbar.out_chip_ctrl.req_name()};
  assign ${soc_regbus_periph_xbar.out_chip_ctrl.rsp_name()} = chip_ctrl_rsp_i;

  //////////////
  //   UART   //
  //////////////

  <% uart_apb = soc_regbus_periph_xbar.out_uart.to_apb(context, "uart_apb") %>
  apb_uart_wrap #(
    .apb_req_t (${uart_apb.req_type()} ),
    .apb_rsp_t (${uart_apb.rsp_type()} )
  ) i_uart (
    .clk_i (${uart_apb.clk}),
    .rst_ni (${uart_apb.rst}),
    .apb_req_i (${uart_apb.req_name()}),
    .apb_rsp_o (${uart_apb.rsp_name()}),
    .intr_o (irq.uart),
    .out1_no (  ),  // keep open
    .out2_no (  ),  // keep open
    .rts_no (  ),   // no flow control
    .dtr_no (  ),   // no flow control
    .cts_ni (1'b0), // no flow control
    .dsr_ni (1'b0), // no flow control
    .dcd_ni (1'b0), // no flow control
    .rin_ni (1'b0),
    .sin_i (uart_rx_i),
    .sout_o (uart_tx_o)
  );

  /////////////
  //   ROM   //
  /////////////

  // This is very system specific, so we might be better off
  // placing it outside the top-level.
  assign bootrom_req_o = ${soc_regbus_periph_xbar.out_bootrom.req_name()};
  assign ${soc_regbus_periph_xbar.out_bootrom.rsp_name()} = bootrom_rsp_i;

  /////////////////
  //   Clk Mgr   //
  /////////////////

  assign clk_mgr_req_o = ${soc_regbus_periph_xbar.out_clk_mgr.req_name()};
  assign ${soc_regbus_periph_xbar.out_clk_mgr.rsp_name()} = clk_mgr_rsp_i;

  //////////////
  //   PLIC   //
  //////////////
  rv_plic #(
    .reg_req_t (${soc_regbus_periph_xbar.out_plic.req_type()}),
    .reg_rsp_t (${soc_regbus_periph_xbar.out_plic.rsp_type()})
  ) i_rv_plic (
    .clk_i (${soc_regbus_periph_xbar.out_plic.clk}),
    .rst_ni (${soc_regbus_periph_xbar.out_plic.rst}),
    .reg_req_i (${soc_regbus_periph_xbar.out_plic.req_name()}),
    .reg_rsp_o (${soc_regbus_periph_xbar.out_plic.rsp_name()}),
    .intr_src_i (irq),
    .irq_o (eip),
    .irq_id_o (),
    .msip_o ()
  );

  assign irq.zero = 1'b0;

  //////////////////
  //   SPI Host   //
  //////////////////
  spi_host #(
    .reg_req_t (${soc_regbus_periph_xbar.out_spim.req_type()}),
    .reg_rsp_t (${soc_regbus_periph_xbar.out_spim.rsp_type()})
  ) i_spi_host (
    // TODO(zarubaf): Fix clock assignment
    .clk_i  (${soc_regbus_periph_xbar.out_spim.clk}),
    .rst_ni (${soc_regbus_periph_xbar.out_spim.rst}),
    .clk_core_i (${soc_regbus_periph_xbar.out_spim.clk}),
    .rst_core_ni (${soc_regbus_periph_xbar.out_spim.rst}),
    .reg_req_i (${soc_regbus_periph_xbar.out_spim.req_name()}),
    .reg_rsp_o (${soc_regbus_periph_xbar.out_spim.rsp_name()}),
    .cio_sck_o (spim_sck_o),
    .cio_sck_en_o (spim_sck_en_o),
    .cio_csb_o (spim_csb_o),
    .cio_csb_en_o (spim_csb_en_o),
    .cio_sd_o (spim_sd_o),
    .cio_sd_en_o (spim_sd_en_o),
    .cio_sd_i (spim_sd_i),
    .intr_error_o (irq.spim_error),
    .intr_spi_event_o (irq.spim_spi_event)
  );

  //////////////
  //   GPIO   //
  //////////////
  gpio #(
    .reg_req_t (${soc_regbus_periph_xbar.out_gpio.req_type()}),
    .reg_rsp_t (${soc_regbus_periph_xbar.out_gpio.rsp_type()})
  ) i_gpio (
    .clk_i (${soc_regbus_periph_xbar.out_gpio.clk}),
    .rst_ni (${soc_regbus_periph_xbar.out_gpio.rst}),
    .reg_req_i (${soc_regbus_periph_xbar.out_gpio.req_name()}),
    .reg_rsp_o (${soc_regbus_periph_xbar.out_gpio.rsp_name()}),
    .cio_gpio_i (gpio_d_i),
    .cio_gpio_o (gpio_d_o),
    .cio_gpio_en_o (gpio_oe_o),
    .intr_gpio_o (irq.gpio)
  );

  /////////////
  //   I2C   //
  /////////////
  i2c #(
    .reg_req_t (${soc_regbus_periph_xbar.out_i2c.req_type()}),
    .reg_rsp_t (${soc_regbus_periph_xbar.out_i2c.rsp_type()})
  ) i_i2c (
    .clk_i (${soc_regbus_periph_xbar.out_i2c.clk}),
    .rst_ni (${soc_regbus_periph_xbar.out_i2c.rst}),
    .reg_req_i (${soc_regbus_periph_xbar.out_i2c.req_name()}),
    .reg_rsp_o (${soc_regbus_periph_xbar.out_i2c.rsp_name()}),
    .cio_scl_i (i2c_scl_i),
    .cio_scl_o (i2c_scl_o),
    .cio_scl_en_o (i2c_scl_en_o),
    .cio_sda_i (i2c_sda_i),
    .cio_sda_o (i2c_sda_o),
    .cio_sda_en_o (i2c_sda_en_o),
    .intr_fmt_watermark_o (irq.i2c_fmt_watermark),
    .intr_rx_watermark_o (irq.i2c_rx_watermark),
    .intr_fmt_overflow_o (irq.i2c_fmt_overflow),
    .intr_rx_overflow_o (irq.i2c_rx_overflow),
    .intr_nak_o (irq.i2c_nak),
    .intr_scl_interference_o (irq.i2c_scl_interference),
    .intr_sda_interference_o (irq.i2c_sda_interference),
    .intr_stretch_timeout_o (irq.i2c_stretch_timeout),
    .intr_sda_unstable_o (irq.i2c_sda_unstable),
    .intr_trans_complete_o (irq.i2c_trans_complete),
    .intr_tx_empty_o (irq.i2c_tx_empty),
    .intr_tx_nonempty_o (irq.i2c_tx_nonempty),
    .intr_tx_overflow_o (irq.i2c_tx_overflow),
    .intr_acq_overflow_o (irq.i2c_acq_overflow),
    .intr_ack_stop_o (irq.i2c_ack_stop),
    .intr_host_timeout_o (irq.i2c_host_timeout)
  );

  /////////////
  //  Timer  //
  /////////////
  <% apb_timer_bus = soc_regbus_periph_xbar.out_timer.to_apb(context, "apb_timer") %>
  apb_timer #(
    .APB_ADDR_WIDTH (${apb_timer_bus.aw}),
    .TIMER_CNT (2)
  ) i_apb_timer (
    .HCLK (${soc_regbus_periph_xbar.out_timer.clk}),
    .HRESETn (${soc_regbus_periph_xbar.out_timer.rst}),
    .PADDR (apb_timer_req.paddr),
    .PWDATA (apb_timer_req.pwdata),
    .PWRITE (apb_timer_req.pwrite),
    .PSEL (apb_timer_req.psel),
    .PENABLE (apb_timer_req.penable),
    .PRDATA (apb_timer_rsp.prdata),
    .PREADY (apb_timer_rsp.pready),
    .PSLVERR (apb_timer_rsp.pslverr),
    .irq_o (irq.timer)
  );

endmodule
