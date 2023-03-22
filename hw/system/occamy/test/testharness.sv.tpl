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

<%def name="tb_memory(bus, name)">
  ${bus.req_type()} ${name}_req;
  ${bus.rsp_type()} ${name}_rsp;

  % if isinstance(bus, solder.AxiBus):
  tb_memory_axi #(
    .AxiAddrWidth (${bus.aw}),
    .AxiDataWidth (${bus.dw}),
    .AxiIdWidth (${bus.iw}),
    .AxiUserWidth (${bus.uw + 1}),
    .ATOPSupport (0),
  % else:
  tb_memory_regbus #(
    .AddrWidth (${bus.aw}),
    .DataWidth (${bus.dw}),
  % endif
    .req_t (${bus.req_type()}),
    .rsp_t (${bus.rsp_type()})
  ) i_${name}_channel (
    .clk_i,
    .rst_ni,
    .req_i (${name}_req),
    .rsp_o (${name}_rsp)
  );
</%def>

<%def name="tb_memory_no_def(bus, name)">
  % if isinstance(bus, solder.AxiBus):
  tb_memory_axi #(
    .AxiAddrWidth (${bus.aw}),
    .AxiDataWidth (${bus.dw}),
    .AxiIdWidth (${bus.iw}),
    .AxiUserWidth (${bus.uw + 1}),
    .ATOPSupport (0),
  % else:
  tb_memory_regbus #(
    .AddrWidth (${bus.aw}),
    .DataWidth (${bus.dw}),
  % endif
    .req_t (${bus.req_type()}),
    .rsp_t (${bus.rsp_type()})
  ) i_${name}_channel (
    .clk_i,
    .rst_ni,
    .req_i (${name}_req),
    .rsp_o (${name}_rsp)
  );
</%def>

% for i in range(nr_hbm_channels):
  ${tb_memory(hbm_xbar.__dict__["out_hbm_{}".format(i)], "hbm_channel_{}".format(i))}
% endfor

  logic tx, rx;
  axi_lite_a48_d32_req_t axi_lite_bootrom_req;
  axi_lite_a48_d32_req_t axi_lite_fll_system_req;
  axi_lite_a48_d32_req_t axi_lite_fll_periph_req;
  axi_lite_a48_d32_req_t axi_lite_fll_hbm2e_req;

  axi_lite_a48_d32_rsp_t axi_lite_bootrom_rsp;
  axi_lite_a48_d32_rsp_t axi_lite_fll_system_rsp;
  axi_lite_a48_d32_rsp_t axi_lite_fll_periph_rsp;
  axi_lite_a48_d32_rsp_t axi_lite_fll_hbm2e_rsp;
<% regbus_bootrom = soc_axi_lite_narrow_periph_xbar.out_bootrom.to_reg(context, "bootrom_regbus", fr="axi_lite_bootrom") %>
<% regbus_fll_system = soc_axi_lite_narrow_periph_xbar.out_fll_system.to_reg(context, "fll_system", fr="axi_lite_fll_system") %>
<% regbus_fll_periph = soc_axi_lite_narrow_periph_xbar.out_fll_periph.to_reg(context, "fll_periph", fr="axi_lite_fll_periph") %>
<% regbus_fll_hbm2e = soc_axi_lite_narrow_periph_xbar.out_fll_hbm2e.to_reg(context, "fll_hbm2e", fr="axi_lite_fll_hbm2e") %>

  ${tb_memory(soc_narrow_xbar.out_pcie, "pcie_axi")}
  ${tb_memory_no_def(regbus_bootrom, "bootrom_regbus")}
  ${tb_memory_no_def(regbus_fll_system, "fll_system")}
  ${tb_memory_no_def(regbus_fll_periph, "fll_periph")}
  ${tb_memory_no_def(regbus_fll_hbm2e, "fll_hbm2e")}
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
% for i in range(nr_hbm_channels):
    .hbm_${i}_req_o (hbm_channel_${i}_req),
    .hbm_${i}_rsp_i (hbm_channel_${i}_rsp),
% endfor
% for s in ("wide", "narrow"):
    .hbi_${s}_req_i ('0),
    .hbi_${s}_rsp_o (),
    .hbi_${s}_req_o (),
    .hbi_${s}_rsp_i ('0),
% endfor
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
