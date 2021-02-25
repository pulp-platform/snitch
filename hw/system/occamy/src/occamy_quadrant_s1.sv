// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>
// Author: Fabian Schuiki <fschuiki@iis.ee.ethz.ch>

// AUTOMATICALLY GENERATED by occamygen.py; edit the script instead.
// verilog_lint: waive-start line-length

/// Occamy Stage 1 Quadrant
module occamy_quadrant_s1
  import occamy_pkg::*;
(
    input  logic                                             clk_i,
    input  logic                                             rst_ni,
    input  logic                                             test_mode_i,
    input  tile_id_t                                         tile_id_i,
    input  logic                     [NrCoresS1Quadrant-1:0] debug_req_i,
    input  logic                     [NrCoresS1Quadrant-1:0] meip_i,
    input  logic                     [NrCoresS1Quadrant-1:0] mtip_i,
    input  logic                     [NrCoresS1Quadrant-1:0] msip_i,
    output axi_a48_d64_i4_u0_req_t                           quadrant_narrow_out_req_o,
    input  axi_a48_d64_i4_u0_resp_t                          quadrant_narrow_out_rsp_i,
    input  axi_a48_d64_i7_u0_req_t                           quadrant_narrow_in_req_i,
    output axi_a48_d64_i7_u0_resp_t                          quadrant_narrow_in_rsp_o,
    output axi_a48_d512_i3_u0_req_t                          quadrant_wide_out_req_o,
    input  axi_a48_d512_i3_u0_resp_t                         quadrant_wide_out_rsp_i,
    input  axi_a48_d512_i7_u0_req_t                          quadrant_wide_in_req_i,
    output axi_a48_d512_i7_u0_resp_t                         quadrant_wide_in_rsp_o
);

  // Calculate cluster base address based on `tile id`.
  addr_t [3:0] cluster_base_addr;
  assign cluster_base_addr[0] = ClusterBaseOffset + tile_id_i * NrClustersS1Quadrant * ClusterAddressSpace + 0 * ClusterAddressSpace;
  assign cluster_base_addr[1] = ClusterBaseOffset + tile_id_i * NrClustersS1Quadrant * ClusterAddressSpace + 1 * ClusterAddressSpace;
  assign cluster_base_addr[2] = ClusterBaseOffset + tile_id_i * NrClustersS1Quadrant * ClusterAddressSpace + 2 * ClusterAddressSpace;
  assign cluster_base_addr[3] = ClusterBaseOffset + tile_id_i * NrClustersS1Quadrant * ClusterAddressSpace + 3 * ClusterAddressSpace;

  ///////////////////
  //   CROSSBARS   //
  ///////////////////

  /// Address map of the `wide_xbar_quadrant_s1` crossbar.
  xbar_rule_48_t [3:0] WideXbarQuadrantS1Addrmap;
  assign WideXbarQuadrantS1Addrmap = '{
    '{ idx: 1, start_addr: cluster_base_addr[0], end_addr: cluster_base_addr[0] + ClusterAddressSpace },
    '{ idx: 2, start_addr: cluster_base_addr[1], end_addr: cluster_base_addr[1] + ClusterAddressSpace },
    '{ idx: 3, start_addr: cluster_base_addr[2], end_addr: cluster_base_addr[2] + ClusterAddressSpace },
    '{ idx: 4, start_addr: cluster_base_addr[3], end_addr: cluster_base_addr[3] + ClusterAddressSpace }
  };

  wide_xbar_quadrant_s1_in_req_t   [4:0] wide_xbar_quadrant_s1_in_req;
  wide_xbar_quadrant_s1_in_resp_t  [4:0] wide_xbar_quadrant_s1_in_rsp;
  wide_xbar_quadrant_s1_out_req_t  [4:0] wide_xbar_quadrant_s1_out_req;
  wide_xbar_quadrant_s1_out_resp_t [4:0] wide_xbar_quadrant_s1_out_rsp;

  axi_xbar #(
      .Cfg          (WideXbarQuadrantS1Cfg),
      .Connectivity (25'b0111110111110111110111110),
      .slv_aw_chan_t(axi_a48_d512_i3_u0_aw_chan_t),
      .mst_aw_chan_t(axi_a48_d512_i6_u0_aw_chan_t),
      .w_chan_t     (axi_a48_d512_i3_u0_w_chan_t),
      .slv_b_chan_t (axi_a48_d512_i3_u0_b_chan_t),
      .mst_b_chan_t (axi_a48_d512_i6_u0_b_chan_t),
      .slv_ar_chan_t(axi_a48_d512_i3_u0_ar_chan_t),
      .mst_ar_chan_t(axi_a48_d512_i6_u0_ar_chan_t),
      .slv_r_chan_t (axi_a48_d512_i3_u0_r_chan_t),
      .mst_r_chan_t (axi_a48_d512_i6_u0_r_chan_t),
      .slv_req_t    (axi_a48_d512_i3_u0_req_t),
      .slv_resp_t   (axi_a48_d512_i3_u0_resp_t),
      .mst_req_t    (axi_a48_d512_i6_u0_req_t),
      .mst_resp_t   (axi_a48_d512_i6_u0_resp_t),
      .rule_t       (xbar_rule_48_t)
  ) i_wide_xbar_quadrant_s1 (
      .clk_i                (clk_i),
      .rst_ni               (rst_ni),
      .test_i               (test_mode_i),
      .slv_ports_req_i      (wide_xbar_quadrant_s1_in_req),
      .slv_ports_resp_o     (wide_xbar_quadrant_s1_in_rsp),
      .mst_ports_req_o      (wide_xbar_quadrant_s1_out_req),
      .mst_ports_resp_i     (wide_xbar_quadrant_s1_out_rsp),
      .addr_map_i           (WideXbarQuadrantS1Addrmap),
      .en_default_mst_port_i('1),
      .default_mst_port_i   ('0)
  );

  /// Address map of the `narrow_xbar_quadrant_s1` crossbar.
  xbar_rule_48_t [3:0] NarrowXbarQuadrantS1Addrmap;
  assign NarrowXbarQuadrantS1Addrmap = '{
    '{ idx: 1, start_addr: cluster_base_addr[0], end_addr: cluster_base_addr[0] + ClusterAddressSpace },
    '{ idx: 2, start_addr: cluster_base_addr[1], end_addr: cluster_base_addr[1] + ClusterAddressSpace },
    '{ idx: 3, start_addr: cluster_base_addr[2], end_addr: cluster_base_addr[2] + ClusterAddressSpace },
    '{ idx: 4, start_addr: cluster_base_addr[3], end_addr: cluster_base_addr[3] + ClusterAddressSpace }
  };

  narrow_xbar_quadrant_s1_in_req_t   [4:0] narrow_xbar_quadrant_s1_in_req;
  narrow_xbar_quadrant_s1_in_resp_t  [4:0] narrow_xbar_quadrant_s1_in_rsp;
  narrow_xbar_quadrant_s1_out_req_t  [4:0] narrow_xbar_quadrant_s1_out_req;
  narrow_xbar_quadrant_s1_out_resp_t [4:0] narrow_xbar_quadrant_s1_out_rsp;

  axi_xbar #(
      .Cfg          (NarrowXbarQuadrantS1Cfg),
      .Connectivity (25'b0111110111110111110111110),
      .slv_aw_chan_t(axi_a48_d64_i4_u0_aw_chan_t),
      .mst_aw_chan_t(axi_a48_d64_i7_u0_aw_chan_t),
      .w_chan_t     (axi_a48_d64_i4_u0_w_chan_t),
      .slv_b_chan_t (axi_a48_d64_i4_u0_b_chan_t),
      .mst_b_chan_t (axi_a48_d64_i7_u0_b_chan_t),
      .slv_ar_chan_t(axi_a48_d64_i4_u0_ar_chan_t),
      .mst_ar_chan_t(axi_a48_d64_i7_u0_ar_chan_t),
      .slv_r_chan_t (axi_a48_d64_i4_u0_r_chan_t),
      .mst_r_chan_t (axi_a48_d64_i7_u0_r_chan_t),
      .slv_req_t    (axi_a48_d64_i4_u0_req_t),
      .slv_resp_t   (axi_a48_d64_i4_u0_resp_t),
      .mst_req_t    (axi_a48_d64_i7_u0_req_t),
      .mst_resp_t   (axi_a48_d64_i7_u0_resp_t),
      .rule_t       (xbar_rule_48_t)
  ) i_narrow_xbar_quadrant_s1 (
      .clk_i                (clk_i),
      .rst_ni               (rst_ni),
      .test_i               (test_mode_i),
      .slv_ports_req_i      (narrow_xbar_quadrant_s1_in_req),
      .slv_ports_resp_o     (narrow_xbar_quadrant_s1_in_rsp),
      .mst_ports_req_o      (narrow_xbar_quadrant_s1_out_req),
      .mst_ports_resp_i     (narrow_xbar_quadrant_s1_out_rsp),
      .addr_map_i           (NarrowXbarQuadrantS1Addrmap),
      .en_default_mst_port_i('1),
      .default_mst_port_i   ('0)
  );


  ///////////////////////////////
  // Narrow In + IW Converter //
  ///////////////////////////////
  axi_a48_d64_i7_u0_req_t  narrow_cluster_in_iwc_req;
  axi_a48_d64_i7_u0_resp_t narrow_cluster_in_iwc_rsp;

  axi_id_remap #(
      .AxiSlvPortIdWidth(7),
      .AxiSlvPortMaxUniqIds(4),
      .AxiMaxTxnsPerId(4),
      .AxiMstPortIdWidth(4),
      .slv_req_t(axi_a48_d64_i7_u0_req_t),
      .slv_resp_t(axi_a48_d64_i7_u0_resp_t),
      .mst_req_t(axi_a48_d64_i4_u0_req_t),
      .mst_resp_t(axi_a48_d64_i4_u0_resp_t)
  ) i_narrow_cluster_in_iwc (
      .clk_i(clk_i),
      .rst_ni(rst_ni),
      .slv_req_i(narrow_cluster_in_iwc_req),
      .slv_resp_o(narrow_cluster_in_iwc_rsp),
      .mst_req_o(narrow_xbar_quadrant_s1_in_req[NARROW_XBAR_QUADRANT_S1_IN_TOP]),
      .mst_resp_i(narrow_xbar_quadrant_s1_in_rsp[NARROW_XBAR_QUADRANT_S1_IN_TOP])
  );

  assign narrow_cluster_in_iwc_req = quadrant_narrow_in_req_i;
  assign quadrant_narrow_in_rsp_o  = narrow_cluster_in_iwc_rsp;

  ///////////////////////////////
  // Narrow Out + IW Converter //
  ///////////////////////////////
  axi_a48_d64_i4_u0_req_t  narrow_cluster_out_iwc_req;
  axi_a48_d64_i4_u0_resp_t narrow_cluster_out_iwc_rsp;

  axi_id_remap #(
      .AxiSlvPortIdWidth(7),
      .AxiSlvPortMaxUniqIds(4),
      .AxiMaxTxnsPerId(4),
      .AxiMstPortIdWidth(4),
      .slv_req_t(axi_a48_d64_i7_u0_req_t),
      .slv_resp_t(axi_a48_d64_i7_u0_resp_t),
      .mst_req_t(axi_a48_d64_i4_u0_req_t),
      .mst_resp_t(axi_a48_d64_i4_u0_resp_t)
  ) i_narrow_cluster_out_iwc (
      .clk_i(clk_i),
      .rst_ni(rst_ni),
      .slv_req_i(narrow_xbar_quadrant_s1_out_req[NARROW_XBAR_QUADRANT_S1_OUT_TOP]),
      .slv_resp_o(narrow_xbar_quadrant_s1_out_rsp[NARROW_XBAR_QUADRANT_S1_OUT_TOP]),
      .mst_req_o(narrow_cluster_out_iwc_req),
      .mst_resp_i(narrow_cluster_out_iwc_rsp)
  );


  assign quadrant_narrow_out_req_o  = narrow_cluster_out_iwc_req;
  assign narrow_cluster_out_iwc_rsp = quadrant_narrow_out_rsp_i;

  ////////////////////////////////////////////
  // Wide Out + Const Cache + IW Converter  //
  ////////////////////////////////////////////
  addr_t const_cache_start_addr, const_cache_end_addr;
  assign const_cache_start_addr = '0;
  assign const_cache_end_addr   = '1;
  axi_a48_d512_i3_u0_req_t  wide_cluster_out_iwc_req;
  axi_a48_d512_i3_u0_resp_t wide_cluster_out_iwc_rsp;

  axi_id_remap #(
      .AxiSlvPortIdWidth(6),
      .AxiSlvPortMaxUniqIds(4),
      .AxiMaxTxnsPerId(4),
      .AxiMstPortIdWidth(3),
      .slv_req_t(axi_a48_d512_i6_u0_req_t),
      .slv_resp_t(axi_a48_d512_i6_u0_resp_t),
      .mst_req_t(axi_a48_d512_i3_u0_req_t),
      .mst_resp_t(axi_a48_d512_i3_u0_resp_t)
  ) i_wide_cluster_out_iwc (
      .clk_i(clk_i),
      .rst_ni(rst_ni),
      .slv_req_i(wide_xbar_quadrant_s1_out_req[WIDE_XBAR_QUADRANT_S1_OUT_TOP]),
      .slv_resp_o(wide_xbar_quadrant_s1_out_rsp[WIDE_XBAR_QUADRANT_S1_OUT_TOP]),
      .mst_req_o(wide_cluster_out_iwc_req),
      .mst_resp_i(wide_cluster_out_iwc_rsp)
  );


  assign quadrant_wide_out_req_o  = wide_cluster_out_iwc_req;
  assign wide_cluster_out_iwc_rsp = quadrant_wide_out_rsp_i;

  ////////////////////////////
  // Wide In + IW Converter //
  ////////////////////////////
  axi_a48_d512_i7_u0_req_t  wide_cluster_in_iwc_req;
  axi_a48_d512_i7_u0_resp_t wide_cluster_in_iwc_rsp;

  axi_id_remap #(
      .AxiSlvPortIdWidth(7),
      .AxiSlvPortMaxUniqIds(4),
      .AxiMaxTxnsPerId(4),
      .AxiMstPortIdWidth(3),
      .slv_req_t(axi_a48_d512_i7_u0_req_t),
      .slv_resp_t(axi_a48_d512_i7_u0_resp_t),
      .mst_req_t(axi_a48_d512_i3_u0_req_t),
      .mst_resp_t(axi_a48_d512_i3_u0_resp_t)
  ) i_wide_cluster_in_iwc (
      .clk_i(clk_i),
      .rst_ni(rst_ni),
      .slv_req_i(wide_cluster_in_iwc_req),
      .slv_resp_o(wide_cluster_in_iwc_rsp),
      .mst_req_o(wide_xbar_quadrant_s1_in_req[WIDE_XBAR_QUADRANT_S1_IN_TOP]),
      .mst_resp_i(wide_xbar_quadrant_s1_in_rsp[WIDE_XBAR_QUADRANT_S1_IN_TOP])
  );

  assign wide_cluster_in_iwc_req = quadrant_wide_in_req_i;
  assign quadrant_wide_in_rsp_o  = wide_cluster_in_iwc_rsp;

  ///////////////
  // Cluster 0 //
  ///////////////
  axi_a48_d64_i2_u0_req_t  narrow_out_iwc_0_req;
  axi_a48_d64_i2_u0_resp_t narrow_out_iwc_0_rsp;

  axi_id_remap #(
      .AxiSlvPortIdWidth(7),
      .AxiSlvPortMaxUniqIds(4),
      .AxiMaxTxnsPerId(4),
      .AxiMstPortIdWidth(2),
      .slv_req_t(axi_a48_d64_i7_u0_req_t),
      .slv_resp_t(axi_a48_d64_i7_u0_resp_t),
      .mst_req_t(axi_a48_d64_i2_u0_req_t),
      .mst_resp_t(axi_a48_d64_i2_u0_resp_t)
  ) i_narrow_out_iwc_0 (
      .clk_i(clk_i),
      .rst_ni(rst_ni),
      .slv_req_i(narrow_xbar_quadrant_s1_out_req[NARROW_XBAR_QUADRANT_S1_OUT_CLUSTER_0]),
      .slv_resp_o(narrow_xbar_quadrant_s1_out_rsp[NARROW_XBAR_QUADRANT_S1_OUT_CLUSTER_0]),
      .mst_req_o(narrow_out_iwc_0_req),
      .mst_resp_i(narrow_out_iwc_0_rsp)
  );

  axi_a48_d512_i2_u0_req_t  wide_out_iwc_0_req;
  axi_a48_d512_i2_u0_resp_t wide_out_iwc_0_rsp;

  axi_id_remap #(
      .AxiSlvPortIdWidth(6),
      .AxiSlvPortMaxUniqIds(4),
      .AxiMaxTxnsPerId(4),
      .AxiMstPortIdWidth(2),
      .slv_req_t(axi_a48_d512_i6_u0_req_t),
      .slv_resp_t(axi_a48_d512_i6_u0_resp_t),
      .mst_req_t(axi_a48_d512_i2_u0_req_t),
      .mst_resp_t(axi_a48_d512_i2_u0_resp_t)
  ) i_wide_out_iwc_0 (
      .clk_i(clk_i),
      .rst_ni(rst_ni),
      .slv_req_i(wide_xbar_quadrant_s1_out_req[WIDE_XBAR_QUADRANT_S1_OUT_CLUSTER_0]),
      .slv_resp_o(wide_xbar_quadrant_s1_out_rsp[WIDE_XBAR_QUADRANT_S1_OUT_CLUSTER_0]),
      .mst_req_o(wide_out_iwc_0_req),
      .mst_resp_i(wide_out_iwc_0_rsp)
  );


  logic [9:0] hart_base_id_0;
  assign hart_base_id_0 = tile_id_i * NrCoresS1Quadrant + 0 * NrCoresCluster;

  occamy_cluster_wrapper i_occamy_cluster_0 (
      .clk_i(clk_i),
      .rst_ni(rst_ni),
      .debug_req_i(debug_req_i[0*NrCoresCluster+:NrCoresCluster]),
      .meip_i(meip_i[0*NrCoresCluster+:NrCoresCluster]),
      .mtip_i(mtip_i[0*NrCoresCluster+:NrCoresCluster]),
      .msip_i(msip_i[0*NrCoresCluster+:NrCoresCluster]),
      .hart_base_id_i(hart_base_id_0),
      .cluster_base_addr_i(cluster_base_addr[0]),
      .clk_d2_bypass_i(1'b0),
      .narrow_in_req_i(narrow_out_iwc_0_req),
      .narrow_in_resp_o(narrow_out_iwc_0_rsp),
      .narrow_out_req_o(narrow_xbar_quadrant_s1_in_req[NARROW_XBAR_QUADRANT_S1_IN_CLUSTER_0]),
      .narrow_out_resp_i(narrow_xbar_quadrant_s1_in_rsp[NARROW_XBAR_QUADRANT_S1_IN_CLUSTER_0]),
      .wide_out_req_o(wide_xbar_quadrant_s1_in_req[WIDE_XBAR_QUADRANT_S1_IN_CLUSTER_0]),
      .wide_out_resp_i(wide_xbar_quadrant_s1_in_rsp[WIDE_XBAR_QUADRANT_S1_IN_CLUSTER_0]),
      .wide_in_req_i(wide_out_iwc_0_req),
      .wide_in_resp_o(wide_out_iwc_0_rsp)
  );

  ///////////////
  // Cluster 1 //
  ///////////////
  axi_a48_d64_i2_u0_req_t  narrow_out_iwc_1_req;
  axi_a48_d64_i2_u0_resp_t narrow_out_iwc_1_rsp;

  axi_id_remap #(
      .AxiSlvPortIdWidth(7),
      .AxiSlvPortMaxUniqIds(4),
      .AxiMaxTxnsPerId(4),
      .AxiMstPortIdWidth(2),
      .slv_req_t(axi_a48_d64_i7_u0_req_t),
      .slv_resp_t(axi_a48_d64_i7_u0_resp_t),
      .mst_req_t(axi_a48_d64_i2_u0_req_t),
      .mst_resp_t(axi_a48_d64_i2_u0_resp_t)
  ) i_narrow_out_iwc_1 (
      .clk_i(clk_i),
      .rst_ni(rst_ni),
      .slv_req_i(narrow_xbar_quadrant_s1_out_req[NARROW_XBAR_QUADRANT_S1_OUT_CLUSTER_1]),
      .slv_resp_o(narrow_xbar_quadrant_s1_out_rsp[NARROW_XBAR_QUADRANT_S1_OUT_CLUSTER_1]),
      .mst_req_o(narrow_out_iwc_1_req),
      .mst_resp_i(narrow_out_iwc_1_rsp)
  );

  axi_a48_d512_i2_u0_req_t  wide_out_iwc_1_req;
  axi_a48_d512_i2_u0_resp_t wide_out_iwc_1_rsp;

  axi_id_remap #(
      .AxiSlvPortIdWidth(6),
      .AxiSlvPortMaxUniqIds(4),
      .AxiMaxTxnsPerId(4),
      .AxiMstPortIdWidth(2),
      .slv_req_t(axi_a48_d512_i6_u0_req_t),
      .slv_resp_t(axi_a48_d512_i6_u0_resp_t),
      .mst_req_t(axi_a48_d512_i2_u0_req_t),
      .mst_resp_t(axi_a48_d512_i2_u0_resp_t)
  ) i_wide_out_iwc_1 (
      .clk_i(clk_i),
      .rst_ni(rst_ni),
      .slv_req_i(wide_xbar_quadrant_s1_out_req[WIDE_XBAR_QUADRANT_S1_OUT_CLUSTER_1]),
      .slv_resp_o(wide_xbar_quadrant_s1_out_rsp[WIDE_XBAR_QUADRANT_S1_OUT_CLUSTER_1]),
      .mst_req_o(wide_out_iwc_1_req),
      .mst_resp_i(wide_out_iwc_1_rsp)
  );


  logic [9:0] hart_base_id_1;
  assign hart_base_id_1 = tile_id_i * NrCoresS1Quadrant + 1 * NrCoresCluster;

  occamy_cluster_wrapper i_occamy_cluster_1 (
      .clk_i(clk_i),
      .rst_ni(rst_ni),
      .debug_req_i(debug_req_i[1*NrCoresCluster+:NrCoresCluster]),
      .meip_i(meip_i[1*NrCoresCluster+:NrCoresCluster]),
      .mtip_i(mtip_i[1*NrCoresCluster+:NrCoresCluster]),
      .msip_i(msip_i[1*NrCoresCluster+:NrCoresCluster]),
      .hart_base_id_i(hart_base_id_1),
      .cluster_base_addr_i(cluster_base_addr[1]),
      .clk_d2_bypass_i(1'b0),
      .narrow_in_req_i(narrow_out_iwc_1_req),
      .narrow_in_resp_o(narrow_out_iwc_1_rsp),
      .narrow_out_req_o(narrow_xbar_quadrant_s1_in_req[NARROW_XBAR_QUADRANT_S1_IN_CLUSTER_1]),
      .narrow_out_resp_i(narrow_xbar_quadrant_s1_in_rsp[NARROW_XBAR_QUADRANT_S1_IN_CLUSTER_1]),
      .wide_out_req_o(wide_xbar_quadrant_s1_in_req[WIDE_XBAR_QUADRANT_S1_IN_CLUSTER_1]),
      .wide_out_resp_i(wide_xbar_quadrant_s1_in_rsp[WIDE_XBAR_QUADRANT_S1_IN_CLUSTER_1]),
      .wide_in_req_i(wide_out_iwc_1_req),
      .wide_in_resp_o(wide_out_iwc_1_rsp)
  );

  ///////////////
  // Cluster 2 //
  ///////////////
  axi_a48_d64_i2_u0_req_t  narrow_out_iwc_2_req;
  axi_a48_d64_i2_u0_resp_t narrow_out_iwc_2_rsp;

  axi_id_remap #(
      .AxiSlvPortIdWidth(7),
      .AxiSlvPortMaxUniqIds(4),
      .AxiMaxTxnsPerId(4),
      .AxiMstPortIdWidth(2),
      .slv_req_t(axi_a48_d64_i7_u0_req_t),
      .slv_resp_t(axi_a48_d64_i7_u0_resp_t),
      .mst_req_t(axi_a48_d64_i2_u0_req_t),
      .mst_resp_t(axi_a48_d64_i2_u0_resp_t)
  ) i_narrow_out_iwc_2 (
      .clk_i(clk_i),
      .rst_ni(rst_ni),
      .slv_req_i(narrow_xbar_quadrant_s1_out_req[NARROW_XBAR_QUADRANT_S1_OUT_CLUSTER_2]),
      .slv_resp_o(narrow_xbar_quadrant_s1_out_rsp[NARROW_XBAR_QUADRANT_S1_OUT_CLUSTER_2]),
      .mst_req_o(narrow_out_iwc_2_req),
      .mst_resp_i(narrow_out_iwc_2_rsp)
  );

  axi_a48_d512_i2_u0_req_t  wide_out_iwc_2_req;
  axi_a48_d512_i2_u0_resp_t wide_out_iwc_2_rsp;

  axi_id_remap #(
      .AxiSlvPortIdWidth(6),
      .AxiSlvPortMaxUniqIds(4),
      .AxiMaxTxnsPerId(4),
      .AxiMstPortIdWidth(2),
      .slv_req_t(axi_a48_d512_i6_u0_req_t),
      .slv_resp_t(axi_a48_d512_i6_u0_resp_t),
      .mst_req_t(axi_a48_d512_i2_u0_req_t),
      .mst_resp_t(axi_a48_d512_i2_u0_resp_t)
  ) i_wide_out_iwc_2 (
      .clk_i(clk_i),
      .rst_ni(rst_ni),
      .slv_req_i(wide_xbar_quadrant_s1_out_req[WIDE_XBAR_QUADRANT_S1_OUT_CLUSTER_2]),
      .slv_resp_o(wide_xbar_quadrant_s1_out_rsp[WIDE_XBAR_QUADRANT_S1_OUT_CLUSTER_2]),
      .mst_req_o(wide_out_iwc_2_req),
      .mst_resp_i(wide_out_iwc_2_rsp)
  );


  logic [9:0] hart_base_id_2;
  assign hart_base_id_2 = tile_id_i * NrCoresS1Quadrant + 2 * NrCoresCluster;

  occamy_cluster_wrapper i_occamy_cluster_2 (
      .clk_i(clk_i),
      .rst_ni(rst_ni),
      .debug_req_i(debug_req_i[2*NrCoresCluster+:NrCoresCluster]),
      .meip_i(meip_i[2*NrCoresCluster+:NrCoresCluster]),
      .mtip_i(mtip_i[2*NrCoresCluster+:NrCoresCluster]),
      .msip_i(msip_i[2*NrCoresCluster+:NrCoresCluster]),
      .hart_base_id_i(hart_base_id_2),
      .cluster_base_addr_i(cluster_base_addr[2]),
      .clk_d2_bypass_i(1'b0),
      .narrow_in_req_i(narrow_out_iwc_2_req),
      .narrow_in_resp_o(narrow_out_iwc_2_rsp),
      .narrow_out_req_o(narrow_xbar_quadrant_s1_in_req[NARROW_XBAR_QUADRANT_S1_IN_CLUSTER_2]),
      .narrow_out_resp_i(narrow_xbar_quadrant_s1_in_rsp[NARROW_XBAR_QUADRANT_S1_IN_CLUSTER_2]),
      .wide_out_req_o(wide_xbar_quadrant_s1_in_req[WIDE_XBAR_QUADRANT_S1_IN_CLUSTER_2]),
      .wide_out_resp_i(wide_xbar_quadrant_s1_in_rsp[WIDE_XBAR_QUADRANT_S1_IN_CLUSTER_2]),
      .wide_in_req_i(wide_out_iwc_2_req),
      .wide_in_resp_o(wide_out_iwc_2_rsp)
  );

  ///////////////
  // Cluster 3 //
  ///////////////
  axi_a48_d64_i2_u0_req_t  narrow_out_iwc_3_req;
  axi_a48_d64_i2_u0_resp_t narrow_out_iwc_3_rsp;

  axi_id_remap #(
      .AxiSlvPortIdWidth(7),
      .AxiSlvPortMaxUniqIds(4),
      .AxiMaxTxnsPerId(4),
      .AxiMstPortIdWidth(2),
      .slv_req_t(axi_a48_d64_i7_u0_req_t),
      .slv_resp_t(axi_a48_d64_i7_u0_resp_t),
      .mst_req_t(axi_a48_d64_i2_u0_req_t),
      .mst_resp_t(axi_a48_d64_i2_u0_resp_t)
  ) i_narrow_out_iwc_3 (
      .clk_i(clk_i),
      .rst_ni(rst_ni),
      .slv_req_i(narrow_xbar_quadrant_s1_out_req[NARROW_XBAR_QUADRANT_S1_OUT_CLUSTER_3]),
      .slv_resp_o(narrow_xbar_quadrant_s1_out_rsp[NARROW_XBAR_QUADRANT_S1_OUT_CLUSTER_3]),
      .mst_req_o(narrow_out_iwc_3_req),
      .mst_resp_i(narrow_out_iwc_3_rsp)
  );

  axi_a48_d512_i2_u0_req_t  wide_out_iwc_3_req;
  axi_a48_d512_i2_u0_resp_t wide_out_iwc_3_rsp;

  axi_id_remap #(
      .AxiSlvPortIdWidth(6),
      .AxiSlvPortMaxUniqIds(4),
      .AxiMaxTxnsPerId(4),
      .AxiMstPortIdWidth(2),
      .slv_req_t(axi_a48_d512_i6_u0_req_t),
      .slv_resp_t(axi_a48_d512_i6_u0_resp_t),
      .mst_req_t(axi_a48_d512_i2_u0_req_t),
      .mst_resp_t(axi_a48_d512_i2_u0_resp_t)
  ) i_wide_out_iwc_3 (
      .clk_i(clk_i),
      .rst_ni(rst_ni),
      .slv_req_i(wide_xbar_quadrant_s1_out_req[WIDE_XBAR_QUADRANT_S1_OUT_CLUSTER_3]),
      .slv_resp_o(wide_xbar_quadrant_s1_out_rsp[WIDE_XBAR_QUADRANT_S1_OUT_CLUSTER_3]),
      .mst_req_o(wide_out_iwc_3_req),
      .mst_resp_i(wide_out_iwc_3_rsp)
  );


  logic [9:0] hart_base_id_3;
  assign hart_base_id_3 = tile_id_i * NrCoresS1Quadrant + 3 * NrCoresCluster;

  occamy_cluster_wrapper i_occamy_cluster_3 (
      .clk_i(clk_i),
      .rst_ni(rst_ni),
      .debug_req_i(debug_req_i[3*NrCoresCluster+:NrCoresCluster]),
      .meip_i(meip_i[3*NrCoresCluster+:NrCoresCluster]),
      .mtip_i(mtip_i[3*NrCoresCluster+:NrCoresCluster]),
      .msip_i(msip_i[3*NrCoresCluster+:NrCoresCluster]),
      .hart_base_id_i(hart_base_id_3),
      .cluster_base_addr_i(cluster_base_addr[3]),
      .clk_d2_bypass_i(1'b0),
      .narrow_in_req_i(narrow_out_iwc_3_req),
      .narrow_in_resp_o(narrow_out_iwc_3_rsp),
      .narrow_out_req_o(narrow_xbar_quadrant_s1_in_req[NARROW_XBAR_QUADRANT_S1_IN_CLUSTER_3]),
      .narrow_out_resp_i(narrow_xbar_quadrant_s1_in_rsp[NARROW_XBAR_QUADRANT_S1_IN_CLUSTER_3]),
      .wide_out_req_o(wide_xbar_quadrant_s1_in_req[WIDE_XBAR_QUADRANT_S1_IN_CLUSTER_3]),
      .wide_out_resp_i(wide_xbar_quadrant_s1_in_rsp[WIDE_XBAR_QUADRANT_S1_IN_CLUSTER_3]),
      .wide_in_req_i(wide_out_iwc_3_req),
      .wide_in_resp_o(wide_out_iwc_3_rsp)
  );

endmodule
// verilog_lint: waive-off line-length
