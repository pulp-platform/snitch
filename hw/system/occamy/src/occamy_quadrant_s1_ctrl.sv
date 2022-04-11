// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// This controller acts as a gatekeeper to a quadrant. It can isolate all its
// (downstream) AXI ports, gate its clock, and assert its reset through a
// register file mapped on the narrow AXI port.

// Author: Paul Scheffler <paulsc@iis.ee.ethz.ch>

// AUTOMATICALLY GENERATED by occamygen.py; edit the script instead.


module occamy_quadrant_s1_ctrl
  import occamy_pkg::*;
  import occamy_quadrant_s1_reg_pkg::*;
(
  input  logic clk_i,
  input  logic rst_ni,
  input  logic test_mode_i,

  input  tile_id_t tile_id_i,

  // Quadrant clock and reset
  output logic clk_quadrant_o,
  output logic rst_quadrant_no,

  // Quadrant control signals
  output occamy_quadrant_s1_reg2hw_isolate_reg_t isolate_o,
  input  occamy_quadrant_s1_hw2reg_isolated_reg_t isolated_i,
  output logic ro_enable_o,
  output logic ro_flush_valid_o,
  input  logic ro_flush_ready_i,
  output logic [3:0][47:0] ro_start_addr_o,
  output logic [3:0][47:0] ro_end_addr_o,

  // Upward (SoC) narrow ports
  output axi_a48_d64_i4_u0_req_t soc_out_req_o,
  input  axi_a48_d64_i4_u0_resp_t soc_out_rsp_i,
  input  axi_a48_d64_i8_u0_req_t soc_in_req_i,
  output axi_a48_d64_i8_u0_resp_t soc_in_rsp_o,

  // TLB narrow and wide configuration ports

  // Quadrant narrow ports
  output axi_a48_d64_i8_u0_req_t quadrant_out_req_o,
  input  axi_a48_d64_i8_u0_resp_t quadrant_out_rsp_i,
  input  axi_a48_d64_i4_u0_req_t quadrant_in_req_i,
  output axi_a48_d64_i4_u0_resp_t quadrant_in_rsp_o
);

  // Upper half of quadrant space reserved for internal use (same size as for all clusters)
  addr_t [0:0] internal_xbar_base_addr;
  assign internal_xbar_base_addr = '{S1QuadrantCfgBaseOffset + tile_id_i * S1QuadrantCfgAddressSpace};

    addr_t [0:0] lite_xbar_base_addrs;
    assign lite_xbar_base_addrs[0] = internal_xbar_base_addr[0];

  // TODO: Pipeline appropriately (possibly only outwards)
  // Controller crossbar: shims off for access to internal space

/// Address map of the `quadrant_s1_ctrl_soc_to_quad_xbar` crossbar.
xbar_rule_48_t [0:0] QuadrantS1CtrlSocToQuadXbarAddrmap;
assign QuadrantS1CtrlSocToQuadXbarAddrmap = '{
  '{ idx: 1, start_addr: internal_xbar_base_addr[0], end_addr: internal_xbar_base_addr[0] + S1QuadrantCfgAddressSpace }
};

quadrant_s1_ctrl_soc_to_quad_xbar_in_req_t [0:0] quadrant_s1_ctrl_soc_to_quad_xbar_in_req;
quadrant_s1_ctrl_soc_to_quad_xbar_in_resp_t [0:0] quadrant_s1_ctrl_soc_to_quad_xbar_in_rsp;
quadrant_s1_ctrl_soc_to_quad_xbar_out_req_t [1:0] quadrant_s1_ctrl_soc_to_quad_xbar_out_req;
quadrant_s1_ctrl_soc_to_quad_xbar_out_resp_t [1:0] quadrant_s1_ctrl_soc_to_quad_xbar_out_rsp;

axi_xbar #(
  .Cfg           ( QuadrantS1CtrlSocToQuadXbarCfg ),
  .Connectivity  ( 2'b11 ),
  .AtopSupport   ( 1 ),
  .slv_aw_chan_t ( axi_a48_d64_i8_u0_aw_chan_t ),
  .mst_aw_chan_t ( axi_a48_d64_i8_u0_aw_chan_t ),
  .w_chan_t      ( axi_a48_d64_i8_u0_w_chan_t ),
  .slv_b_chan_t  ( axi_a48_d64_i8_u0_b_chan_t ),
  .mst_b_chan_t  ( axi_a48_d64_i8_u0_b_chan_t ),
  .slv_ar_chan_t ( axi_a48_d64_i8_u0_ar_chan_t ),
  .mst_ar_chan_t ( axi_a48_d64_i8_u0_ar_chan_t ),
  .slv_r_chan_t  ( axi_a48_d64_i8_u0_r_chan_t ),
  .mst_r_chan_t  ( axi_a48_d64_i8_u0_r_chan_t ),
  .slv_req_t     ( axi_a48_d64_i8_u0_req_t ),
  .slv_resp_t    ( axi_a48_d64_i8_u0_resp_t ),
  .mst_req_t     ( axi_a48_d64_i8_u0_req_t ),
  .mst_resp_t    ( axi_a48_d64_i8_u0_resp_t ),
  .rule_t        ( xbar_rule_48_t )
) i_quadrant_s1_ctrl_soc_to_quad_xbar (
  .clk_i  ( clk_i ),
  .rst_ni ( rst_ni ),
  .test_i ( test_mode_i ),
  .slv_ports_req_i  ( quadrant_s1_ctrl_soc_to_quad_xbar_in_req  ),
  .slv_ports_resp_o ( quadrant_s1_ctrl_soc_to_quad_xbar_in_rsp  ),
  .mst_ports_req_o  ( quadrant_s1_ctrl_soc_to_quad_xbar_out_req ),
  .mst_ports_resp_i ( quadrant_s1_ctrl_soc_to_quad_xbar_out_rsp ),
  .addr_map_i       ( QuadrantS1CtrlSocToQuadXbarAddrmap ),
  .en_default_mst_port_i ( '1 ),
  .default_mst_port_i    ( '0 )
);

/// Address map of the `quadrant_s1_ctrl_quad_to_soc_xbar` crossbar.
xbar_rule_48_t [0:0] QuadrantS1CtrlQuadToSocXbarAddrmap;
assign QuadrantS1CtrlQuadToSocXbarAddrmap = '{
  '{ idx: 1, start_addr: internal_xbar_base_addr[0], end_addr: internal_xbar_base_addr[0] + S1QuadrantCfgAddressSpace }
};

quadrant_s1_ctrl_quad_to_soc_xbar_in_req_t [0:0] quadrant_s1_ctrl_quad_to_soc_xbar_in_req;
quadrant_s1_ctrl_quad_to_soc_xbar_in_resp_t [0:0] quadrant_s1_ctrl_quad_to_soc_xbar_in_rsp;
quadrant_s1_ctrl_quad_to_soc_xbar_out_req_t [1:0] quadrant_s1_ctrl_quad_to_soc_xbar_out_req;
quadrant_s1_ctrl_quad_to_soc_xbar_out_resp_t [1:0] quadrant_s1_ctrl_quad_to_soc_xbar_out_rsp;

axi_xbar #(
  .Cfg           ( QuadrantS1CtrlQuadToSocXbarCfg ),
  .Connectivity  ( 2'b11 ),
  .AtopSupport   ( 1 ),
  .slv_aw_chan_t ( axi_a48_d64_i4_u0_aw_chan_t ),
  .mst_aw_chan_t ( axi_a48_d64_i4_u0_aw_chan_t ),
  .w_chan_t      ( axi_a48_d64_i4_u0_w_chan_t ),
  .slv_b_chan_t  ( axi_a48_d64_i4_u0_b_chan_t ),
  .mst_b_chan_t  ( axi_a48_d64_i4_u0_b_chan_t ),
  .slv_ar_chan_t ( axi_a48_d64_i4_u0_ar_chan_t ),
  .mst_ar_chan_t ( axi_a48_d64_i4_u0_ar_chan_t ),
  .slv_r_chan_t  ( axi_a48_d64_i4_u0_r_chan_t ),
  .mst_r_chan_t  ( axi_a48_d64_i4_u0_r_chan_t ),
  .slv_req_t     ( axi_a48_d64_i4_u0_req_t ),
  .slv_resp_t    ( axi_a48_d64_i4_u0_resp_t ),
  .mst_req_t     ( axi_a48_d64_i4_u0_req_t ),
  .mst_resp_t    ( axi_a48_d64_i4_u0_resp_t ),
  .rule_t        ( xbar_rule_48_t )
) i_quadrant_s1_ctrl_quad_to_soc_xbar (
  .clk_i  ( clk_i ),
  .rst_ni ( rst_ni ),
  .test_i ( test_mode_i ),
  .slv_ports_req_i  ( quadrant_s1_ctrl_quad_to_soc_xbar_in_req  ),
  .slv_ports_resp_o ( quadrant_s1_ctrl_quad_to_soc_xbar_in_rsp  ),
  .mst_ports_req_o  ( quadrant_s1_ctrl_quad_to_soc_xbar_out_req ),
  .mst_ports_resp_i ( quadrant_s1_ctrl_quad_to_soc_xbar_out_rsp ),
  .addr_map_i       ( QuadrantS1CtrlQuadToSocXbarAddrmap ),
  .en_default_mst_port_i ( '1 ),
  .default_mst_port_i    ( '0 )
);

/// Address map of the `quadrant_s1_ctrl_mux` crossbar.
xbar_rule_48_t [0:0] QuadrantS1CtrlMuxAddrmap;
assign QuadrantS1CtrlMuxAddrmap = '{
  '{ idx: 0, start_addr: lite_xbar_base_addrs[0], end_addr: lite_xbar_base_addrs[0] + (S1QuadrantCfgAddressSpace >> 1) }
};

axi_lite_a48_d32_req_t [1:0] quadrant_s1_ctrl_mux_in_req;
axi_lite_a48_d32_rsp_t [1:0] quadrant_s1_ctrl_mux_in_rsp;
axi_lite_a48_d32_req_t [0:0] quadrant_s1_ctrl_mux_out_req;
axi_lite_a48_d32_rsp_t [0:0] quadrant_s1_ctrl_mux_out_rsp;

// The `quadrant_s1_ctrl_mux` crossbar.
axi_lite_xbar #(
  .Cfg       ( QuadrantS1CtrlMuxCfg ),
  .aw_chan_t ( axi_lite_a48_d32_aw_chan_t ),
  .w_chan_t  ( axi_lite_a48_d32_w_chan_t ),
  .b_chan_t  ( axi_lite_a48_d32_b_chan_t ),
  .ar_chan_t ( axi_lite_a48_d32_ar_chan_t ),
  .r_chan_t  ( axi_lite_a48_d32_r_chan_t ),
  .req_t     ( axi_lite_a48_d32_req_t ),
  .resp_t    ( axi_lite_a48_d32_rsp_t ),
  .rule_t    ( xbar_rule_48_t )
) i_quadrant_s1_ctrl_mux (
  .clk_i  ( clk_i ),
  .rst_ni ( rst_ni ),
  .test_i ( test_mode_i ),
  .slv_ports_req_i  ( quadrant_s1_ctrl_mux_in_req  ),
  .slv_ports_resp_o ( quadrant_s1_ctrl_mux_in_rsp  ),
  .mst_ports_req_o  ( quadrant_s1_ctrl_mux_out_req ),
  .mst_ports_resp_i ( quadrant_s1_ctrl_mux_out_rsp ),
  .addr_map_i       ( QuadrantS1CtrlMuxAddrmap ),
  .en_default_mst_port_i ( '1 ),
  .default_mst_port_i    ( '0 )
);


  // Connect upward (SoC) narrow ports
  assign soc_out_req_o = quadrant_s1_ctrl_quad_to_soc_xbar_out_req[QUADRANT_S1_CTRL_QUAD_TO_SOC_XBAR_OUT_OUT];
  assign quadrant_s1_ctrl_quad_to_soc_xbar_out_rsp[QUADRANT_S1_CTRL_QUAD_TO_SOC_XBAR_OUT_OUT] = soc_out_rsp_i;
  assign quadrant_s1_ctrl_soc_to_quad_xbar_in_req[QUADRANT_S1_CTRL_SOC_TO_QUAD_XBAR_IN_IN] = soc_in_req_i;
  assign soc_in_rsp_o = quadrant_s1_ctrl_soc_to_quad_xbar_in_rsp[QUADRANT_S1_CTRL_SOC_TO_QUAD_XBAR_IN_IN];

  // Connect quadrant narrow ports
  assign quadrant_out_req_o = quadrant_s1_ctrl_soc_to_quad_xbar_out_req[QUADRANT_S1_CTRL_SOC_TO_QUAD_XBAR_OUT_OUT];
  assign quadrant_s1_ctrl_soc_to_quad_xbar_out_rsp[QUADRANT_S1_CTRL_SOC_TO_QUAD_XBAR_OUT_OUT] = quadrant_out_rsp_i;
  assign quadrant_s1_ctrl_quad_to_soc_xbar_in_req[QUADRANT_S1_CTRL_QUAD_TO_SOC_XBAR_IN_IN] = quadrant_in_req_i;
  assign quadrant_in_rsp_o = quadrant_s1_ctrl_quad_to_soc_xbar_in_rsp[QUADRANT_S1_CTRL_QUAD_TO_SOC_XBAR_IN_IN];


  // Convert both internal ports to AXI lite, since only registers for now
    axi_a48_d64_i1_u0_req_t soc_to_quad_internal_ser_req;
  axi_a48_d64_i1_u0_resp_t soc_to_quad_internal_ser_rsp;

  axi_id_serialize #(
    .AtopSupport (1),
    .AxiSlvPortIdWidth (8),
    .AxiSlvPortMaxTxns (4),
    .AxiMstPortIdWidth (1),
    .AxiMstPortMaxUniqIds (2),
    .AxiMstPortMaxTxnsPerId (2),
    .AxiAddrWidth (48),
    .AxiDataWidth (64),
    .AxiUserWidth (1),
    .slv_req_t (axi_a48_d64_i8_u0_req_t),
    .slv_resp_t (axi_a48_d64_i8_u0_resp_t),
    .mst_req_t (axi_a48_d64_i1_u0_req_t),
    .mst_resp_t (axi_a48_d64_i1_u0_resp_t)
  ) i_soc_to_quad_internal_ser (
    .clk_i ( clk_i ),
    .rst_ni ( rst_ni ),
    .slv_req_i ( quadrant_s1_ctrl_soc_to_quad_xbar_out_req[QUADRANT_S1_CTRL_SOC_TO_QUAD_XBAR_OUT_INTERNAL] ),
    .slv_resp_o ( quadrant_s1_ctrl_soc_to_quad_xbar_out_rsp[QUADRANT_S1_CTRL_SOC_TO_QUAD_XBAR_OUT_INTERNAL] ),
    .mst_req_o ( soc_to_quad_internal_ser_req ),
    .mst_resp_i ( soc_to_quad_internal_ser_rsp )
  );
  axi_a48_d32_i1_u0_req_t axi_to_axi_lite_dw_req;
  axi_a48_d32_i1_u0_resp_t axi_to_axi_lite_dw_rsp;

  axi_dw_converter #(
    .AxiSlvPortDataWidth ( 64 ),
    .AxiMstPortDataWidth ( 32 ),
    .AxiAddrWidth ( 48 ),
    .AxiIdWidth ( 1 ),
    .aw_chan_t ( axi_a48_d32_i1_u0_aw_chan_t ),
    .mst_w_chan_t ( axi_a48_d32_i1_u0_w_chan_t ),
    .slv_w_chan_t ( axi_a48_d64_i1_u0_w_chan_t ),
    .b_chan_t ( axi_a48_d32_i1_u0_b_chan_t ),
    .ar_chan_t ( axi_a48_d32_i1_u0_ar_chan_t ),
    .mst_r_chan_t ( axi_a48_d32_i1_u0_r_chan_t ),
    .slv_r_chan_t ( axi_a48_d64_i1_u0_r_chan_t ),
    .axi_mst_req_t ( axi_a48_d32_i1_u0_req_t ),
    .axi_mst_resp_t ( axi_a48_d32_i1_u0_resp_t ),
    .axi_slv_req_t ( axi_a48_d64_i1_u0_req_t ),
    .axi_slv_resp_t ( axi_a48_d64_i1_u0_resp_t )
  ) i_axi_to_axi_lite_dw (
    .clk_i ( clk_i ),
    .rst_ni ( rst_ni ),
    .slv_req_i ( soc_to_quad_internal_ser_req ),
    .slv_resp_o ( soc_to_quad_internal_ser_rsp ),
    .mst_req_o ( axi_to_axi_lite_dw_req ),
    .mst_resp_i ( axi_to_axi_lite_dw_rsp )
  );

  axi_to_axi_lite #(
    .AxiAddrWidth ( 48 ),
    .AxiDataWidth ( 32 ),
    .AxiIdWidth ( 1 ),
    .AxiUserWidth ( 1 ),
    .AxiMaxWriteTxns ( 4  ),
    .AxiMaxReadTxns ( 4  ),
    .FallThrough ( 0  ),
    .full_req_t ( axi_a48_d32_i1_u0_req_t ),
    .full_resp_t ( axi_a48_d32_i1_u0_resp_t ),
    .lite_req_t ( axi_lite_a48_d32_req_t ),
    .lite_resp_t ( axi_lite_a48_d32_rsp_t )
  ) i_quad_to_soc_internal_ser_pc (
    .clk_i (clk_i),
    .rst_ni (rst_ni),
    .test_i (test_mode_i),
    .slv_req_i (axi_to_axi_lite_dw_req),
    .slv_resp_o (axi_to_axi_lite_dw_rsp),
    .mst_req_o (quadrant_s1_ctrl_mux_in_req[QUADRANT_S1_CTRL_MUX_IN_SOC]),
    .mst_resp_i (quadrant_s1_ctrl_mux_in_rsp[QUADRANT_S1_CTRL_MUX_IN_SOC])
  );

  axi_a48_d64_i1_u0_req_t soc_internal_serialize_req;
  axi_a48_d64_i1_u0_resp_t soc_internal_serialize_rsp;

  axi_id_serialize #(
    .AtopSupport (1),
    .AxiSlvPortIdWidth (4),
    .AxiSlvPortMaxTxns (4),
    .AxiMstPortIdWidth (1),
    .AxiMstPortMaxUniqIds (2),
    .AxiMstPortMaxTxnsPerId (2),
    .AxiAddrWidth (48),
    .AxiDataWidth (64),
    .AxiUserWidth (1),
    .slv_req_t (axi_a48_d64_i4_u0_req_t),
    .slv_resp_t (axi_a48_d64_i4_u0_resp_t),
    .mst_req_t (axi_a48_d64_i1_u0_req_t),
    .mst_resp_t (axi_a48_d64_i1_u0_resp_t)
  ) i_soc_internal_serialize (
    .clk_i ( clk_i ),
    .rst_ni ( rst_ni ),
    .slv_req_i ( quadrant_s1_ctrl_quad_to_soc_xbar_out_req[QUADRANT_S1_CTRL_QUAD_TO_SOC_XBAR_OUT_INTERNAL] ),
    .slv_resp_o ( quadrant_s1_ctrl_quad_to_soc_xbar_out_rsp[QUADRANT_S1_CTRL_QUAD_TO_SOC_XBAR_OUT_INTERNAL] ),
    .mst_req_o ( soc_internal_serialize_req ),
    .mst_resp_i ( soc_internal_serialize_rsp )
  );
  axi_a48_d32_i1_u0_req_t soc_internal_change_dw_req;
  axi_a48_d32_i1_u0_resp_t soc_internal_change_dw_rsp;

  axi_dw_converter #(
    .AxiSlvPortDataWidth ( 64 ),
    .AxiMstPortDataWidth ( 32 ),
    .AxiAddrWidth ( 48 ),
    .AxiIdWidth ( 1 ),
    .aw_chan_t ( axi_a48_d32_i1_u0_aw_chan_t ),
    .mst_w_chan_t ( axi_a48_d32_i1_u0_w_chan_t ),
    .slv_w_chan_t ( axi_a48_d64_i1_u0_w_chan_t ),
    .b_chan_t ( axi_a48_d32_i1_u0_b_chan_t ),
    .ar_chan_t ( axi_a48_d32_i1_u0_ar_chan_t ),
    .mst_r_chan_t ( axi_a48_d32_i1_u0_r_chan_t ),
    .slv_r_chan_t ( axi_a48_d64_i1_u0_r_chan_t ),
    .axi_mst_req_t ( axi_a48_d32_i1_u0_req_t ),
    .axi_mst_resp_t ( axi_a48_d32_i1_u0_resp_t ),
    .axi_slv_req_t ( axi_a48_d64_i1_u0_req_t ),
    .axi_slv_resp_t ( axi_a48_d64_i1_u0_resp_t )
  ) i_soc_internal_change_dw (
    .clk_i ( clk_i ),
    .rst_ni ( rst_ni ),
    .slv_req_i ( soc_internal_serialize_req ),
    .slv_resp_o ( soc_internal_serialize_rsp ),
    .mst_req_o ( soc_internal_change_dw_req ),
    .mst_resp_i ( soc_internal_change_dw_rsp )
  );

  axi_to_axi_lite #(
    .AxiAddrWidth ( 48 ),
    .AxiDataWidth ( 32 ),
    .AxiIdWidth ( 1 ),
    .AxiUserWidth ( 1 ),
    .AxiMaxWriteTxns ( 4  ),
    .AxiMaxReadTxns ( 4  ),
    .FallThrough ( 0  ),
    .full_req_t ( axi_a48_d32_i1_u0_req_t ),
    .full_resp_t ( axi_a48_d32_i1_u0_resp_t ),
    .lite_req_t ( axi_lite_a48_d32_req_t ),
    .lite_resp_t ( axi_lite_a48_d32_rsp_t )
  ) i_soc_internal_to_axi_lite_pc (
    .clk_i (clk_i),
    .rst_ni (rst_ni),
    .test_i (test_mode_i),
    .slv_req_i (soc_internal_change_dw_req),
    .slv_resp_o (soc_internal_change_dw_rsp),
    .mst_req_o (quadrant_s1_ctrl_mux_in_req[QUADRANT_S1_CTRL_MUX_IN_QUAD]),
    .mst_resp_i (quadrant_s1_ctrl_mux_in_rsp[QUADRANT_S1_CTRL_MUX_IN_QUAD])
  );

  reg_a48_d32_req_t axi_lite_to_regbus_regs_req;
  reg_a48_d32_rsp_t axi_lite_to_regbus_regs_rsp;

  axi_lite_to_reg #(
    .ADDR_WIDTH     ( 48 ),
    .DATA_WIDTH     ( 32 ),
    .axi_lite_req_t ( axi_lite_a48_d32_req_t ),
    .axi_lite_rsp_t ( axi_lite_a48_d32_rsp_t ),
    .reg_req_t      ( reg_a48_d32_req_t ),
    .reg_rsp_t      ( reg_a48_d32_rsp_t )
  ) i_axi_lite_to_regbus_regs_pc (
    .clk_i          ( clk_i ),
    .rst_ni         ( rst_ni ),
    .axi_lite_req_i ( quadrant_s1_ctrl_mux_out_req[QUADRANT_S1_CTRL_MUX_OUT_QUADRANT_CTRL] ),
    .axi_lite_rsp_o ( quadrant_s1_ctrl_mux_out_rsp[QUADRANT_S1_CTRL_MUX_OUT_QUADRANT_CTRL] ),
    .reg_req_o      ( axi_lite_to_regbus_regs_req ),
    .reg_rsp_i      ( axi_lite_to_regbus_regs_rsp )
  );


  // Control registers
  occamy_quadrant_s1_reg2hw_t reg2hw;
  occamy_quadrant_s1_hw2reg_t hw2reg;

  occamy_quadrant_s1_reg_top #(
    .reg_req_t (reg_a48_d32_req_t),
    .reg_rsp_t (reg_a48_d32_rsp_t)
  ) i_occamy_quadrant_s1_reg_top (
    .clk_i,
    .rst_ni,
    .reg_req_i (axi_lite_to_regbus_regs_req),
    .reg_rsp_o (axi_lite_to_regbus_regs_rsp),
    .reg2hw,
    .hw2reg,
    .devmode_i (1'b1)
  );

  // Control quadrant control signals
  assign isolate_o = reg2hw.isolate;
  assign hw2reg.isolated = isolated_i;
  assign ro_enable_o = reg2hw.ro_cache_enable.q;

  // RO cache flush handshake
  assign ro_flush_valid_o = reg2hw.ro_cache_flush.q;
  assign hw2reg.ro_cache_flush.d = ro_flush_ready_i;
  assign hw2reg.ro_cache_flush.de = reg2hw.ro_cache_flush.q & hw2reg.ro_cache_flush.d;

  // Assemble RO cache start and end addresses from registers
  assign ro_start_addr_o[0] = {reg2hw.ro_start_addr_high_0.q, reg2hw.ro_start_addr_low_0.q};
  assign ro_end_addr_o  [0] = {reg2hw.ro_end_addr_high_0.q,   reg2hw.ro_end_addr_low_0.q};
  assign ro_start_addr_o[1] = {reg2hw.ro_start_addr_high_1.q, reg2hw.ro_start_addr_low_1.q};
  assign ro_end_addr_o  [1] = {reg2hw.ro_end_addr_high_1.q,   reg2hw.ro_end_addr_low_1.q};
  assign ro_start_addr_o[2] = {reg2hw.ro_start_addr_high_2.q, reg2hw.ro_start_addr_low_2.q};
  assign ro_end_addr_o  [2] = {reg2hw.ro_end_addr_high_2.q,   reg2hw.ro_end_addr_low_2.q};
  assign ro_start_addr_o[3] = {reg2hw.ro_start_addr_high_3.q, reg2hw.ro_start_addr_low_3.q};
  assign ro_end_addr_o  [3] = {reg2hw.ro_end_addr_high_3.q,   reg2hw.ro_end_addr_low_3.q};

  // Quadrant clock gate controlled by register
  tc_clk_gating i_tc_clk_gating_quadrant (
    .clk_i,
    .en_i (reg2hw.clk_ena.q),
    .test_en_i (test_mode_i),
    .clk_o (clk_quadrant_o)
  );

  // Reset directly from register (i.e. (de)assertion inherently synchronized)
  // Multiplex with glitchless multiplexor, top reset for testing purposes
  tc_clk_mux2 i_tc_reset_mux (
    .clk0_i (reg2hw.reset_n.q),
    .clk1_i (rst_ni),
    .clk_sel_i (test_mode_i),
    .clk_o (rst_quadrant_no)
  );

endmodule
