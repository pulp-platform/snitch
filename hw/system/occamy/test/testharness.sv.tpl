// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

`include "axi/typedef.svh"

module testharness import occamy_pkg::*; (
  input  logic        clk_i,
  input  logic        rst_ni
);

<%def name="tb_memory(hbm_channel, name)">
  ${hbm_channel.req_type()} ${name}_req;
  ${hbm_channel.rsp_type()} ${name}_rsp;

  tb_memory #(
    .AxiAddrWidth (${hbm_channel.aw}),
    .AxiDataWidth (${hbm_channel.dw}),
    .AxiIdWidth (${hbm_channel.iw}),
    .AxiUserWidth (${hbm_channel.uw + 1}),
    .req_t (${hbm_channel.req_type()}),
    .rsp_t (${hbm_channel.rsp_type()})
  ) i_${name}_channel (
    .clk_i,
    .rst_ni,
    .req_i (${name}_req),
    .rsp_o (${name}_rsp)
  );
</%def>

% for i in range(8):
${tb_memory(soc_wide_xbar.__dict__["out_hbm_{}".format(i)], "hbm_channel_{}".format(i))}
% endfor

  ${tb_memory(soc_wide_xbar.out_pcie, "pcie_axi")}

  occamy_top i_occamy (
    .clk_i,
    .rst_ni,
    .clk_periph_i (clk_i),
    .rst_periph_ni (rst_ni),
    .rtc_i (),
    .test_mode_i (1'b0),
    .chip_id_i ('0),
    .boot_mode_i ('0),
    .pad_slw_o (),
    .pad_smt_o (),
    .pad_drv_o (),
    .uart_tx_o (),
    .uart_rx_i ('0),
    .gpio_d_i (),
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
    .bootrom_req_o (),
    .bootrom_rsp_i (),
    .clk_mgr_req_o (),
    .clk_mgr_rsp_i (),
% for i in range(8):
    .hbm_${i}_req_o (hbm_channel_${i}_req),
    .hbm_${i}_rsp_i (hbm_channel_${i}_rsp),
% endfor
% for i in range(nr_s1_quadrants):
    .hbi_${i}_req_i ('0),
    .hbi_${i}_rsp_o (),
% endfor
    .pcie_axi_req_o (pcie_axi_req),
    .pcie_axi_rsp_i (pcie_axi_rsp),
    .pcie_axi_req_i ('0),
    .pcie_axi_rsp_o ()
  );

endmodule
