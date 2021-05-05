// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

`include "axi/typedef.svh"

module testharness import occamy_pkg::*; (
  input  logic        clk_i,
  input  logic        rst_ni
);

  // verilog_lint: waive explicit-parameter-storage-type
  localparam RTCTCK = 305ms; // 32.768 kHz

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




  axi_a48_d512_i8_u0_req_t hbm_channel_0_req;
  axi_a48_d512_i8_u0_resp_t hbm_channel_0_rsp;

  tb_memory_axi #(
    .AxiAddrWidth (48),
    .AxiDataWidth (512),
    .AxiIdWidth (8),
    .AxiUserWidth (1),
    .req_t (axi_a48_d512_i8_u0_req_t),
    .rsp_t (axi_a48_d512_i8_u0_resp_t)
  ) i_hbm_channel_0_channel (
    .clk_i,
    .rst_ni,
    .req_i (hbm_channel_0_req),
    .rsp_o (hbm_channel_0_rsp)
  );


  axi_a48_d512_i8_u0_req_t hbm_channel_1_req;
  axi_a48_d512_i8_u0_resp_t hbm_channel_1_rsp;

  tb_memory_axi #(
    .AxiAddrWidth (48),
    .AxiDataWidth (512),
    .AxiIdWidth (8),
    .AxiUserWidth (1),
    .req_t (axi_a48_d512_i8_u0_req_t),
    .rsp_t (axi_a48_d512_i8_u0_resp_t)
  ) i_hbm_channel_1_channel (
    .clk_i,
    .rst_ni,
    .req_i (hbm_channel_1_req),
    .rsp_o (hbm_channel_1_rsp)
  );


  axi_a48_d512_i8_u0_req_t hbm_channel_2_req;
  axi_a48_d512_i8_u0_resp_t hbm_channel_2_rsp;

  tb_memory_axi #(
    .AxiAddrWidth (48),
    .AxiDataWidth (512),
    .AxiIdWidth (8),
    .AxiUserWidth (1),
    .req_t (axi_a48_d512_i8_u0_req_t),
    .rsp_t (axi_a48_d512_i8_u0_resp_t)
  ) i_hbm_channel_2_channel (
    .clk_i,
    .rst_ni,
    .req_i (hbm_channel_2_req),
    .rsp_o (hbm_channel_2_rsp)
  );


  axi_a48_d512_i8_u0_req_t hbm_channel_3_req;
  axi_a48_d512_i8_u0_resp_t hbm_channel_3_rsp;

  tb_memory_axi #(
    .AxiAddrWidth (48),
    .AxiDataWidth (512),
    .AxiIdWidth (8),
    .AxiUserWidth (1),
    .req_t (axi_a48_d512_i8_u0_req_t),
    .rsp_t (axi_a48_d512_i8_u0_resp_t)
  ) i_hbm_channel_3_channel (
    .clk_i,
    .rst_ni,
    .req_i (hbm_channel_3_req),
    .rsp_o (hbm_channel_3_rsp)
  );


  axi_a48_d512_i8_u0_req_t hbm_channel_4_req;
  axi_a48_d512_i8_u0_resp_t hbm_channel_4_rsp;

  tb_memory_axi #(
    .AxiAddrWidth (48),
    .AxiDataWidth (512),
    .AxiIdWidth (8),
    .AxiUserWidth (1),
    .req_t (axi_a48_d512_i8_u0_req_t),
    .rsp_t (axi_a48_d512_i8_u0_resp_t)
  ) i_hbm_channel_4_channel (
    .clk_i,
    .rst_ni,
    .req_i (hbm_channel_4_req),
    .rsp_o (hbm_channel_4_rsp)
  );


  axi_a48_d512_i8_u0_req_t hbm_channel_5_req;
  axi_a48_d512_i8_u0_resp_t hbm_channel_5_rsp;

  tb_memory_axi #(
    .AxiAddrWidth (48),
    .AxiDataWidth (512),
    .AxiIdWidth (8),
    .AxiUserWidth (1),
    .req_t (axi_a48_d512_i8_u0_req_t),
    .rsp_t (axi_a48_d512_i8_u0_resp_t)
  ) i_hbm_channel_5_channel (
    .clk_i,
    .rst_ni,
    .req_i (hbm_channel_5_req),
    .rsp_o (hbm_channel_5_rsp)
  );


  axi_a48_d512_i8_u0_req_t hbm_channel_6_req;
  axi_a48_d512_i8_u0_resp_t hbm_channel_6_rsp;

  tb_memory_axi #(
    .AxiAddrWidth (48),
    .AxiDataWidth (512),
    .AxiIdWidth (8),
    .AxiUserWidth (1),
    .req_t (axi_a48_d512_i8_u0_req_t),
    .rsp_t (axi_a48_d512_i8_u0_resp_t)
  ) i_hbm_channel_6_channel (
    .clk_i,
    .rst_ni,
    .req_i (hbm_channel_6_req),
    .rsp_o (hbm_channel_6_rsp)
  );


  axi_a48_d512_i8_u0_req_t hbm_channel_7_req;
  axi_a48_d512_i8_u0_resp_t hbm_channel_7_rsp;

  tb_memory_axi #(
    .AxiAddrWidth (48),
    .AxiDataWidth (512),
    .AxiIdWidth (8),
    .AxiUserWidth (1),
    .req_t (axi_a48_d512_i8_u0_req_t),
    .rsp_t (axi_a48_d512_i8_u0_resp_t)
  ) i_hbm_channel_7_channel (
    .clk_i,
    .rst_ni,
    .req_i (hbm_channel_7_req),
    .rsp_o (hbm_channel_7_rsp)
  );


  logic tx, rx;

  axi_a48_d512_i8_u0_req_t pcie_axi_req;
  axi_a48_d512_i8_u0_resp_t pcie_axi_rsp;

  tb_memory_axi #(
    .AxiAddrWidth (48),
    .AxiDataWidth (512),
    .AxiIdWidth (8),
    .AxiUserWidth (1),
    .req_t (axi_a48_d512_i8_u0_req_t),
    .rsp_t (axi_a48_d512_i8_u0_resp_t)
  ) i_pcie_axi_channel (
    .clk_i,
    .rst_ni,
    .req_i (pcie_axi_req),
    .rsp_o (pcie_axi_rsp)
  );


  reg_a48_d32_req_t bootrom_regbus_req;
  reg_a48_d32_rsp_t bootrom_regbus_rsp;

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


  reg_a48_d32_req_t clk_mgr_req;
  reg_a48_d32_rsp_t clk_mgr_rsp;

  tb_memory_regbus #(
    .AddrWidth (48),
    .DataWidth (32),
    .req_t (reg_a48_d32_req_t),
    .rsp_t (reg_a48_d32_rsp_t)
  ) i_clk_mgr_channel (
    .clk_i,
    .rst_ni,
    .req_i (clk_mgr_req),
    .rsp_o (clk_mgr_rsp)
  );

  occamy_top i_occamy (
    .clk_i,
    .rst_ni,
    .clk_periph_i (clk_i),
    .rst_periph_ni (rst_ni),
    .rtc_i,
    .test_mode_i (1'b0),
    .chip_id_i ('0),
    .boot_mode_i ('0),
    .pad_slw_o (),
    .pad_smt_o (),
    .pad_drv_o (),
    .uart_tx_o (tx),
    .uart_rx_i (rx),
    .gpio_d_i ('0),
    .gpio_d_o (),
    .gpio_oe_o (),
    .gpio_puen_o (),
    .gpio_pden_o (),
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
    .bootrom_req_o (bootrom_regbus_req),
    .bootrom_rsp_i (bootrom_regbus_rsp),
    .clk_mgr_req_o (clk_mgr_req),
    .clk_mgr_rsp_i (clk_mgr_rsp),
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
    .hbi_0_req_i ('0),
    .hbi_0_rsp_o (),
    .hbi_1_req_i ('0),
    .hbi_1_rsp_o (),
    .hbi_2_req_i ('0),
    .hbi_2_rsp_o (),
    .hbi_3_req_i ('0),
    .hbi_3_rsp_o (),
    .hbi_4_req_i ('0),
    .hbi_4_rsp_o (),
    .hbi_5_req_i ('0),
    .hbi_5_rsp_o (),
    .hbi_6_req_i ('0),
    .hbi_6_rsp_o (),
    .hbi_7_req_i ('0),
    .hbi_7_rsp_o (),
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
