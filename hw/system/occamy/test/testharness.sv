// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

`include "axi/typedef.svh"

module testharness import occamy_pkg::*; (
  input  logic        clk_i,
  input  logic        rst_ni
);

  // verilog_lint: waive explicit-parameter-storage-type
  localparam RTCTCK = 30.518us; // 32.768 kHz

  logic rtc_i;

  // Generate reset and clock.
  initial begin
    forever begin
      rtc_i = 1;
      #(RTCTCK/2);
      rtc_i = 0;
      #(RTCTCK/2);
    end
  end

  logic clk_periph_i, rst_periph_ni;
  assign clk_periph_i = clk_i;
  assign rst_periph_ni = rst_ni;






  axi_a48_d512_i7_u0_req_t hbm_channel_0_req;
  axi_a48_d512_i7_u0_resp_t hbm_channel_0_rsp;

  tb_memory_axi #(
    .AxiAddrWidth (48),
    .AxiDataWidth (512),
    .AxiIdWidth (7),
    .AxiUserWidth (1),
    .ATOPSupport (0),
    .req_t (axi_a48_d512_i7_u0_req_t),
    .rsp_t (axi_a48_d512_i7_u0_resp_t)
  ) i_hbm_channel_0_channel (
    .clk_i,
    .rst_ni,
    .req_i (hbm_channel_0_req),
    .rsp_o (hbm_channel_0_rsp)
  );


  axi_a48_d512_i7_u0_req_t hbm_channel_1_req;
  axi_a48_d512_i7_u0_resp_t hbm_channel_1_rsp;

  tb_memory_axi #(
    .AxiAddrWidth (48),
    .AxiDataWidth (512),
    .AxiIdWidth (7),
    .AxiUserWidth (1),
    .ATOPSupport (0),
    .req_t (axi_a48_d512_i7_u0_req_t),
    .rsp_t (axi_a48_d512_i7_u0_resp_t)
  ) i_hbm_channel_1_channel (
    .clk_i,
    .rst_ni,
    .req_i (hbm_channel_1_req),
    .rsp_o (hbm_channel_1_rsp)
  );


  axi_a48_d512_i7_u0_req_t hbm_channel_2_req;
  axi_a48_d512_i7_u0_resp_t hbm_channel_2_rsp;

  tb_memory_axi #(
    .AxiAddrWidth (48),
    .AxiDataWidth (512),
    .AxiIdWidth (7),
    .AxiUserWidth (1),
    .ATOPSupport (0),
    .req_t (axi_a48_d512_i7_u0_req_t),
    .rsp_t (axi_a48_d512_i7_u0_resp_t)
  ) i_hbm_channel_2_channel (
    .clk_i,
    .rst_ni,
    .req_i (hbm_channel_2_req),
    .rsp_o (hbm_channel_2_rsp)
  );


  axi_a48_d512_i7_u0_req_t hbm_channel_3_req;
  axi_a48_d512_i7_u0_resp_t hbm_channel_3_rsp;

  tb_memory_axi #(
    .AxiAddrWidth (48),
    .AxiDataWidth (512),
    .AxiIdWidth (7),
    .AxiUserWidth (1),
    .ATOPSupport (0),
    .req_t (axi_a48_d512_i7_u0_req_t),
    .rsp_t (axi_a48_d512_i7_u0_resp_t)
  ) i_hbm_channel_3_channel (
    .clk_i,
    .rst_ni,
    .req_i (hbm_channel_3_req),
    .rsp_o (hbm_channel_3_rsp)
  );


  axi_a48_d512_i7_u0_req_t hbm_channel_4_req;
  axi_a48_d512_i7_u0_resp_t hbm_channel_4_rsp;

  tb_memory_axi #(
    .AxiAddrWidth (48),
    .AxiDataWidth (512),
    .AxiIdWidth (7),
    .AxiUserWidth (1),
    .ATOPSupport (0),
    .req_t (axi_a48_d512_i7_u0_req_t),
    .rsp_t (axi_a48_d512_i7_u0_resp_t)
  ) i_hbm_channel_4_channel (
    .clk_i,
    .rst_ni,
    .req_i (hbm_channel_4_req),
    .rsp_o (hbm_channel_4_rsp)
  );


  axi_a48_d512_i7_u0_req_t hbm_channel_5_req;
  axi_a48_d512_i7_u0_resp_t hbm_channel_5_rsp;

  tb_memory_axi #(
    .AxiAddrWidth (48),
    .AxiDataWidth (512),
    .AxiIdWidth (7),
    .AxiUserWidth (1),
    .ATOPSupport (0),
    .req_t (axi_a48_d512_i7_u0_req_t),
    .rsp_t (axi_a48_d512_i7_u0_resp_t)
  ) i_hbm_channel_5_channel (
    .clk_i,
    .rst_ni,
    .req_i (hbm_channel_5_req),
    .rsp_o (hbm_channel_5_rsp)
  );


  axi_a48_d512_i7_u0_req_t hbm_channel_6_req;
  axi_a48_d512_i7_u0_resp_t hbm_channel_6_rsp;

  tb_memory_axi #(
    .AxiAddrWidth (48),
    .AxiDataWidth (512),
    .AxiIdWidth (7),
    .AxiUserWidth (1),
    .ATOPSupport (0),
    .req_t (axi_a48_d512_i7_u0_req_t),
    .rsp_t (axi_a48_d512_i7_u0_resp_t)
  ) i_hbm_channel_6_channel (
    .clk_i,
    .rst_ni,
    .req_i (hbm_channel_6_req),
    .rsp_o (hbm_channel_6_rsp)
  );


  axi_a48_d512_i7_u0_req_t hbm_channel_7_req;
  axi_a48_d512_i7_u0_resp_t hbm_channel_7_rsp;

  tb_memory_axi #(
    .AxiAddrWidth (48),
    .AxiDataWidth (512),
    .AxiIdWidth (7),
    .AxiUserWidth (1),
    .ATOPSupport (0),
    .req_t (axi_a48_d512_i7_u0_req_t),
    .rsp_t (axi_a48_d512_i7_u0_resp_t)
  ) i_hbm_channel_7_channel (
    .clk_i,
    .rst_ni,
    .req_i (hbm_channel_7_req),
    .rsp_o (hbm_channel_7_rsp)
  );


  logic tx, rx;
  axi_lite_a48_d32_req_t axi_lite_bootrom_req;
  axi_lite_a48_d32_req_t axi_lite_fll_system_req;
  axi_lite_a48_d32_req_t axi_lite_fll_periph_req;
  axi_lite_a48_d32_req_t axi_lite_fll_hbm2e_req;

  axi_lite_a48_d32_rsp_t axi_lite_bootrom_rsp;
  axi_lite_a48_d32_rsp_t axi_lite_fll_system_rsp;
  axi_lite_a48_d32_rsp_t axi_lite_fll_periph_rsp;
  axi_lite_a48_d32_rsp_t axi_lite_fll_hbm2e_rsp;
  reg_a48_d32_req_t bootrom_regbus_req;
  reg_a48_d32_rsp_t bootrom_regbus_rsp;

  axi_lite_to_reg #(
    .ADDR_WIDTH     ( 48 ),
    .DATA_WIDTH     ( 32 ),
    .axi_lite_req_t ( axi_lite_a48_d32_req_t ),
    .axi_lite_rsp_t ( axi_lite_a48_d32_rsp_t ),
    .reg_req_t      ( reg_a48_d32_req_t ),
    .reg_rsp_t      ( reg_a48_d32_rsp_t )
  ) i_bootrom_regbus_pc (
    .clk_i          ( clk_periph_i ),
    .rst_ni         ( rst_periph_ni ),
    .axi_lite_req_i ( axi_lite_bootrom_req ),
    .axi_lite_rsp_o ( axi_lite_bootrom_rsp ),
    .reg_req_o      ( bootrom_regbus_req ),
    .reg_rsp_i      ( bootrom_regbus_rsp )
  );


  reg_a48_d32_req_t fll_system_req;
  reg_a48_d32_rsp_t fll_system_rsp;

  axi_lite_to_reg #(
    .ADDR_WIDTH     ( 48 ),
    .DATA_WIDTH     ( 32 ),
    .axi_lite_req_t ( axi_lite_a48_d32_req_t ),
    .axi_lite_rsp_t ( axi_lite_a48_d32_rsp_t ),
    .reg_req_t      ( reg_a48_d32_req_t ),
    .reg_rsp_t      ( reg_a48_d32_rsp_t )
  ) i_fll_system_pc (
    .clk_i          ( clk_periph_i ),
    .rst_ni         ( rst_periph_ni ),
    .axi_lite_req_i ( axi_lite_fll_system_req ),
    .axi_lite_rsp_o ( axi_lite_fll_system_rsp ),
    .reg_req_o      ( fll_system_req ),
    .reg_rsp_i      ( fll_system_rsp )
  );


  reg_a48_d32_req_t fll_periph_req;
  reg_a48_d32_rsp_t fll_periph_rsp;

  axi_lite_to_reg #(
    .ADDR_WIDTH     ( 48 ),
    .DATA_WIDTH     ( 32 ),
    .axi_lite_req_t ( axi_lite_a48_d32_req_t ),
    .axi_lite_rsp_t ( axi_lite_a48_d32_rsp_t ),
    .reg_req_t      ( reg_a48_d32_req_t ),
    .reg_rsp_t      ( reg_a48_d32_rsp_t )
  ) i_fll_periph_pc (
    .clk_i          ( clk_periph_i ),
    .rst_ni         ( rst_periph_ni ),
    .axi_lite_req_i ( axi_lite_fll_periph_req ),
    .axi_lite_rsp_o ( axi_lite_fll_periph_rsp ),
    .reg_req_o      ( fll_periph_req ),
    .reg_rsp_i      ( fll_periph_rsp )
  );


  reg_a48_d32_req_t fll_hbm2e_req;
  reg_a48_d32_rsp_t fll_hbm2e_rsp;

  axi_lite_to_reg #(
    .ADDR_WIDTH     ( 48 ),
    .DATA_WIDTH     ( 32 ),
    .axi_lite_req_t ( axi_lite_a48_d32_req_t ),
    .axi_lite_rsp_t ( axi_lite_a48_d32_rsp_t ),
    .reg_req_t      ( reg_a48_d32_req_t ),
    .reg_rsp_t      ( reg_a48_d32_rsp_t )
  ) i_fll_hbm2e_pc (
    .clk_i          ( clk_periph_i ),
    .rst_ni         ( rst_periph_ni ),
    .axi_lite_req_i ( axi_lite_fll_hbm2e_req ),
    .axi_lite_rsp_o ( axi_lite_fll_hbm2e_rsp ),
    .reg_req_o      ( fll_hbm2e_req ),
    .reg_rsp_i      ( fll_hbm2e_rsp )
  );




  axi_a48_d64_i8_u5_req_t pcie_axi_req;
  axi_a48_d64_i8_u5_resp_t pcie_axi_rsp;

  tb_memory_axi #(
    .AxiAddrWidth (48),
    .AxiDataWidth (64),
    .AxiIdWidth (8),
    .AxiUserWidth (6),
    .ATOPSupport (0),
    .req_t (axi_a48_d64_i8_u5_req_t),
    .rsp_t (axi_a48_d64_i8_u5_resp_t)
  ) i_pcie_axi_channel (
    .clk_i,
    .rst_ni,
    .req_i (pcie_axi_req),
    .rsp_o (pcie_axi_rsp)
  );


  tb_memory_regbus #(
    .AddrWidth (48),
    .DataWidth (32),
    .req_t (reg_a48_d32_req_t),
    .rsp_t (reg_a48_d32_rsp_t)
  ) i_bootrom_regbus_channel (
    .clk_i,
    .rst_ni,
    .req_i (bootrom_regbus_req),
    .rsp_o (bootrom_regbus_rsp)
  );


  tb_memory_regbus #(
    .AddrWidth (48),
    .DataWidth (32),
    .req_t (reg_a48_d32_req_t),
    .rsp_t (reg_a48_d32_rsp_t)
  ) i_fll_system_channel (
    .clk_i,
    .rst_ni,
    .req_i (fll_system_req),
    .rsp_o (fll_system_rsp)
  );


  tb_memory_regbus #(
    .AddrWidth (48),
    .DataWidth (32),
    .req_t (reg_a48_d32_req_t),
    .rsp_t (reg_a48_d32_rsp_t)
  ) i_fll_periph_channel (
    .clk_i,
    .rst_ni,
    .req_i (fll_periph_req),
    .rsp_o (fll_periph_rsp)
  );


  tb_memory_regbus #(
    .AddrWidth (48),
    .DataWidth (32),
    .req_t (reg_a48_d32_req_t),
    .rsp_t (reg_a48_d32_rsp_t)
  ) i_fll_hbm2e_channel (
    .clk_i,
    .rst_ni,
    .req_i (fll_hbm2e_req),
    .rsp_o (fll_hbm2e_rsp)
  );

  occamy_top i_occamy (
    .clk_i,
    .rst_ni,
    .sram_cfgs_i ('0),
    .clk_periph_i,
    .rst_periph_ni,
    .rtc_i,
    .test_mode_i (1'b0),
    .chip_id_i ('0),
    .boot_mode_i ('0),
    .uart_tx_o (tx),
    .uart_rx_i (rx),
    .gpio_d_i ('0),
    .gpio_d_o (),
    .gpio_oe_o (),
    .jtag_trst_ni ('0),
    .jtag_tck_i ('0),
    .jtag_tms_i ('0),
    .jtag_tdi_i ('0),
    .jtag_tdo_o (),
    .i2c_sda_o (),
    .i2c_sda_i ('0),
    .i2c_sda_en_o (),
    .i2c_scl_o (),
    .i2c_scl_i ('0),
    .i2c_scl_en_o (),
    .spim_sck_o (),
    .spim_sck_en_o (),
    .spim_csb_o (),
    .spim_csb_en_o (),
    .spim_sd_o (),
    .spim_sd_en_o (),
    .spim_sd_i ('0),
    .bootrom_req_o (axi_lite_bootrom_req),
    .bootrom_rsp_i (axi_lite_bootrom_rsp),
    .fll_system_req_o (axi_lite_fll_system_req),
    .fll_system_rsp_i (axi_lite_fll_system_rsp),
    .fll_periph_req_o (axi_lite_fll_periph_req),
    .fll_periph_rsp_i (axi_lite_fll_periph_rsp),
    .fll_hbm2e_req_o (axi_lite_fll_hbm2e_req),
    .fll_hbm2e_rsp_i (axi_lite_fll_hbm2e_rsp),
    .hbi_wide_cfg_req_o (),
    .hbi_wide_cfg_rsp_i ('0),
    .hbi_narrow_cfg_req_o (),
    .hbi_narrow_cfg_rsp_i ('0),
    .hbm_cfg_req_o (),
    .hbm_cfg_rsp_i ('0),
    .pcie_cfg_req_o (),
    .pcie_cfg_rsp_i ('0),
    .chip_ctrl_req_o (),
    .chip_ctrl_rsp_i ('0),
    .ext_irq_i ('0),
    .hbm_0_req_o (hbm_channel_0_req),
    .hbm_0_rsp_i (hbm_channel_0_rsp),
    .hbm_1_req_o (hbm_channel_1_req),
    .hbm_1_rsp_i (hbm_channel_1_rsp),
    .hbm_2_req_o (hbm_channel_2_req),
    .hbm_2_rsp_i (hbm_channel_2_rsp),
    .hbm_3_req_o (hbm_channel_3_req),
    .hbm_3_rsp_i (hbm_channel_3_rsp),
    .hbm_4_req_o (hbm_channel_4_req),
    .hbm_4_rsp_i (hbm_channel_4_rsp),
    .hbm_5_req_o (hbm_channel_5_req),
    .hbm_5_rsp_i (hbm_channel_5_rsp),
    .hbm_6_req_o (hbm_channel_6_req),
    .hbm_6_rsp_i (hbm_channel_6_rsp),
    .hbm_7_req_o (hbm_channel_7_req),
    .hbm_7_rsp_i (hbm_channel_7_rsp),
    .hbi_wide_req_i ('0),
    .hbi_wide_rsp_o (),
    .hbi_wide_req_o (),
    .hbi_wide_rsp_i ('0),
    .hbi_narrow_req_i ('0),
    .hbi_narrow_rsp_o (),
    .hbi_narrow_req_o (),
    .hbi_narrow_rsp_i ('0),
    .pcie_axi_req_o (pcie_axi_req),
    .pcie_axi_rsp_i (pcie_axi_rsp),
    .pcie_axi_req_i ('0),
    .pcie_axi_rsp_o ()
  );

  uartdpi #(
    .BAUD ('d115_200),
    // Frequency shouldn't matter since we are sending with the same clock.
    .FREQ ('d500_000),
    .NAME("uart0")
  ) i_uart0 (
    .clk_i (clk_i),
    .rst_ni (rst_ni),
    .tx_o (rx),
    .rx_i (tx)
  );

endmodule
