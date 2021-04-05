// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Nils Wistoff <nwistoff@iis.ee.ethz.ch>
//
// AUTOMATICALLY GENERATED by genoccamy.py; edit the script instead.

`include "axi_flat.sv"

module occamy_xilinx
  import occamy_pkg::*;
(
    input  logic             clk_i,
    input  logic             rst_ni,
    input  logic             test_mode_i,
    input  logic [ 1:0]      chip_id_i,
    input  logic [ 1:0]      boot_mode_i,
    // pad cfg
    output logic [31:0]      pad_slw_o,
    output logic [31:0]      pad_smt_o,
    output logic [31:0][1:0] pad_drv_o,
    // `uart` Interface
    output logic             uart_tx_o,
    input  logic             uart_rx_i,
    // `gpio` Interface
    input  logic [31:0]      gpio_d_i,
    output logic [31:0]      gpio_d_o,
    output logic [31:0]      gpio_oe_o,
    output logic [31:0]      gpio_puen_o,
    output logic [31:0]      gpio_pden_o,
    // `serial` Interface
    input  logic             serial_clk_i,
    input  logic [ 3:0]      serial_data_i,
    output logic [ 3:0]      serial_data_o,
    // `jtag` Interface
    input  logic             jtag_trst_ni,
    input  logic             jtag_tck_i,
    input  logic             jtag_tms_i,
    input  logic             jtag_tdi_i,
    output logic             jtag_tdo_o,
    // `i2c` Interface
    output logic             i2c_sda_o,
    input  logic             i2c_sda_i,
    output logic             i2c_sda_en_o,
    output logic             i2c_scl_o,
    input  logic             i2c_scl_i,
    output logic             i2c_scl_en_o,


    /// PCIe Ports
    input  logic                     m_axi_pcie_awready,
    output logic                     m_axi_pcie_awvalid,
    output logic             [  7:0] m_axi_pcie_awid,
    output logic             [ 47:0] m_axi_pcie_awaddr,
    output axi_pkg::len_t            m_axi_pcie_awlen,
    output axi_pkg::size_t           m_axi_pcie_awsize,
    output axi_pkg::burst_t          m_axi_pcie_awburst,
    output logic                     m_axi_pcie_awlock,
    output axi_pkg::cache_t          m_axi_pcie_awcache,
    output axi_pkg::prot_t           m_axi_pcie_awprot,
    output axi_pkg::qos_t            m_axi_pcie_awqos,
    output axi_pkg::region_t         m_axi_pcie_awregion,
    //   output axi_pkg::atop_t    m_axi_pcie_awatop,
    output logic             [  0:0] m_axi_pcie_awuser,
    input  logic                     m_axi_pcie_wready,
    output logic                     m_axi_pcie_wvalid,
    output logic             [511:0] m_axi_pcie_wdata,
    output logic             [ 63:0] m_axi_pcie_wstrb,
    output logic                     m_axi_pcie_wlast,
    output logic             [  0:0] m_axi_pcie_wuser,
    input  logic                     m_axi_pcie_arready,
    output logic                     m_axi_pcie_arvalid,
    output logic             [  7:0] m_axi_pcie_arid,
    output logic             [ 47:0] m_axi_pcie_araddr,
    output axi_pkg::len_t            m_axi_pcie_arlen,
    output axi_pkg::size_t           m_axi_pcie_arsize,
    output axi_pkg::burst_t          m_axi_pcie_arburst,
    output logic                     m_axi_pcie_arlock,
    output axi_pkg::cache_t          m_axi_pcie_arcache,
    output axi_pkg::prot_t           m_axi_pcie_arprot,
    output axi_pkg::qos_t            m_axi_pcie_arqos,
    output axi_pkg::region_t         m_axi_pcie_arregion,
    output logic             [  0:0] m_axi_pcie_aruser,
    output logic                     m_axi_pcie_rready,
    input  logic                     m_axi_pcie_rvalid,
    input  logic             [  7:0] m_axi_pcie_rid,
    input  logic             [511:0] m_axi_pcie_rdata,
    input  axi_pkg::resp_t           m_axi_pcie_rresp,
    input  logic                     m_axi_pcie_rlast,
    input  logic             [  0:0] m_axi_pcie_ruser,
    output logic                     m_axi_pcie_bready,
    input  logic                     m_axi_pcie_bvalid,
    input  logic             [  7:0] m_axi_pcie_bid,
    input  axi_pkg::resp_t           m_axi_pcie_bresp,
    input  logic             [  0:0] m_axi_pcie_buser,

    output logic                     s_axi_pcie_awready,
    input  logic                     s_axi_pcie_awvalid,
    input  logic             [  2:0] s_axi_pcie_awid,
    input  logic             [ 47:0] s_axi_pcie_awaddr,
    input  axi_pkg::len_t            s_axi_pcie_awlen,
    input  axi_pkg::size_t           s_axi_pcie_awsize,
    input  axi_pkg::burst_t          s_axi_pcie_awburst,
    input  logic                     s_axi_pcie_awlock,
    input  axi_pkg::cache_t          s_axi_pcie_awcache,
    input  axi_pkg::prot_t           s_axi_pcie_awprot,
    input  axi_pkg::qos_t            s_axi_pcie_awqos,
    input  axi_pkg::region_t         s_axi_pcie_awregion,
    //   input axi_pkg::atop_t    s_axi_pcie_awatop,
    input  logic             [  0:0] s_axi_pcie_awuser,
    output logic                     s_axi_pcie_wready,
    input  logic                     s_axi_pcie_wvalid,
    input  logic             [511:0] s_axi_pcie_wdata,
    input  logic             [ 63:0] s_axi_pcie_wstrb,
    input  logic                     s_axi_pcie_wlast,
    input  logic             [  0:0] s_axi_pcie_wuser,
    output logic                     s_axi_pcie_arready,
    input  logic                     s_axi_pcie_arvalid,
    input  logic             [  2:0] s_axi_pcie_arid,
    input  logic             [ 47:0] s_axi_pcie_araddr,
    input  axi_pkg::len_t            s_axi_pcie_arlen,
    input  axi_pkg::size_t           s_axi_pcie_arsize,
    input  axi_pkg::burst_t          s_axi_pcie_arburst,
    input  logic                     s_axi_pcie_arlock,
    input  axi_pkg::cache_t          s_axi_pcie_arcache,
    input  axi_pkg::prot_t           s_axi_pcie_arprot,
    input  axi_pkg::qos_t            s_axi_pcie_arqos,
    input  axi_pkg::region_t         s_axi_pcie_arregion,
    input  logic             [  0:0] s_axi_pcie_aruser,
    input  logic                     s_axi_pcie_rready,
    output logic                     s_axi_pcie_rvalid,
    output logic             [  2:0] s_axi_pcie_rid,
    output logic             [511:0] s_axi_pcie_rdata,
    output axi_pkg::resp_t           s_axi_pcie_rresp,
    output logic                     s_axi_pcie_rlast,
    output logic             [  0:0] s_axi_pcie_ruser,
    input  logic                     s_axi_pcie_bready,
    output logic                     s_axi_pcie_bvalid,
    output logic             [  2:0] s_axi_pcie_bid,
    output axi_pkg::resp_t           s_axi_pcie_bresp,
    output logic             [  0:0] s_axi_pcie_buser

    /// HBM2e Ports
    /// HBI Ports
);

  // AXI ports of Occamy top-level
  axi_a48_d512_i8_u0_req_t  pcie_axi_req_o;
  axi_a48_d512_i8_u0_resp_t pcie_axi_rsp_i;

  axi_a48_d512_i3_u0_req_t  pcie_axi_req_i;
  axi_a48_d512_i3_u0_resp_t pcie_axi_rsp_o;

  // Assign structs to flattened ports
  `AXI_FLATTEN_MASTER(pcie, pcie_axi_req_o, pcie_axi_rsp_i)
  `AXI_FLATTEN_SLAVE(pcie, pcie_axi_req_i, pcie_axi_rsp_o)

  // Occamy top-level
  occamy_top i_occamy (.*);

endmodule
