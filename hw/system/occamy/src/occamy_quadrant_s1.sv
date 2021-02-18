// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>
// Author: Fabian Schuiki <fschuiki@iis.ee.ethz.ch>

/// Occamy Stage 1 Quadrant
module occamy_quadrant_s1
  import occamy_pkg::*;
(
  input  logic                         clk_i,
  input  logic                         rst_ni,
  input  tile_id_t                     tile_id_i,
  input  logic [NrCoresS1Quadrant-1:0] debug_req_i,
  input  logic [NrCoresS1Quadrant-1:0] meip_i,
  input  logic [NrCoresS1Quadrant-1:0] mtip_i,
  input  logic [NrCoresS1Quadrant-1:0] msip_i,
  input  quadrant_in_t                 quadrant_i,
  output quadrant_out_t                quadrant_o
);

  /// Disable the loopback.
  function bit [NrClustersS1Quadrant:0][NrClustersS1Quadrant:0] disable_loopback(int unsigned n);
    bit [NrClustersS1Quadrant:0][NrClustersS1Quadrant:0] Connectivity;
    // Disable loop-back.
    for (int i = 0; i < NrClustersS1Quadrant+1; i++) begin
      for (int j = 0; j < NrClustersS1Quadrant+1; j++) begin
        if (i == j) Connectivity[i][j] = 1'b0;
        else Connectivity[i][j] = 1'b1;
      end
    end
    return Connectivity;
  endfunction

  localparam bit [NrClustersS1Quadrant:0][NrClustersS1Quadrant:0] Connectivity = disable_loopback(NrClustersS1Quadrant+1);

  axi_wide_req_t [NrClustersS1Quadrant-1:0] wide_in_req;
  axi_wide_resp_t [NrClustersS1Quadrant-1:0] wide_in_resp;
  axi_wide_req_t [NrClustersS1Quadrant-1:0] wide_out_req;
  axi_wide_resp_t [NrClustersS1Quadrant-1:0] wide_out_resp;

  axi_narrow_req_t [NrClustersS1Quadrant-1:0] narrow_in_req;
  axi_narrow_resp_t [NrClustersS1Quadrant-1:0] narrow_in_resp;
  axi_narrow_req_t [NrClustersS1Quadrant-1:0] narrow_out_req;
  axi_narrow_resp_t [NrClustersS1Quadrant-1:0] narrow_out_resp;

  // Calculate cluster base address based on `tile id`.
  addr_t [NrClustersS1Quadrant-1:0] cluster_base_addr;
  for (genvar i = 0; i < NrClustersS1Quadrant; i++) begin : gen_cluster_base_addr
    assign cluster_base_addr[i] = ClusterBaseOffset +
              tile_id_i * NrClustersS1Quadrant * ClusterAddressSpace + i * ClusterAddressSpace;
  end

  xbar_rule_t [NrClustersS1Quadrant-1:0] addr_map;

  // Generate address map based on `tile_id`.
  for (genvar i = 0; i < NrClustersS1Quadrant; i++) begin : gen_addr_map
    assign addr_map[i] = '{
      idx: i,
      start_addr: cluster_base_addr[i],
      end_addr: cluster_base_addr[i] + ClusterAddressSpace
    };
  end

  localparam int unsigned NumPorts = NrClustersS1Quadrant+1;
  /// Wide crossbar.
  axi_xp #(
    .NumSlvPorts (NumPorts),
    .NumMstPorts (NumPorts),
    .Connectivity (Connectivity),
    .AxiAddrWidth (AddrWidth),
    .AxiDataWidth (WideDataWidth),
    .AxiIdWidth (WideIdWidth),
    .AxiUserWidth (UserWidth),
    // Check with specification of upstream modules.
    .AxiSlvPortMaxUniqIds (4),
    .AxiSlvPortMaxWriteTxns (16),
    .AxiMaxTxnsPerId (16),
    .NumAddrRules (NrClustersS1Quadrant),
    .slv_req_t (axi_wide_req_t),
    .slv_resp_t (axi_wide_resp_t),
    .mst_req_t (axi_wide_req_t),
    .mst_resp_t (axi_wide_resp_t),
    .rule_t (xbar_rule_t)
  ) i_axi_xp_wide_quadrant_s1 (
    .clk_i (clk_i),
    .rst_ni (rst_ni),
    .test_en_i (1'b0),
    .slv_req_i ({quadrant_i.wide_in_req, wide_out_req}),
    .slv_resp_o ({quadrant_o.wide_in_rsp, wide_out_resp}),
    .mst_req_o ({quadrant_o.wide_out_req, wide_in_req}),
    .mst_resp_i ({quadrant_i.wide_out_rsp, wide_in_resp}),
    .addr_map_i (addr_map),
    .en_default_mst_port_i ({NumPorts{1'b1}}),
    .default_mst_port_i ({NumPorts{NrClustersS1Quadrant[$clog2(NumPorts)-1:0]}})
  );

  /// Narrow crossbar.
  axi_xp #(
    .NumSlvPorts (NumPorts),
    .NumMstPorts (NumPorts),
    .Connectivity (Connectivity),
    .AxiAddrWidth (AddrWidth),
    .AxiDataWidth (NarrowDataWidth),
    .AxiIdWidth (NarrowIdWidth),
    .AxiUserWidth (UserWidth),
    // Check with specification of upstream modules.
    .AxiSlvPortMaxUniqIds (4),
    .AxiSlvPortMaxWriteTxns (16),
    .AxiMaxTxnsPerId (16),
    .NumAddrRules (NrClustersS1Quadrant),
    .slv_req_t (axi_narrow_req_t),
    .slv_resp_t (axi_narrow_resp_t),
    .mst_req_t (axi_narrow_req_t),
    .mst_resp_t (axi_narrow_resp_t),
    .rule_t (xbar_rule_t)
  ) i_axi_xp_narrow_quadrant_s1 (
    .clk_i (clk_i),
    .rst_ni (rst_ni),
    .test_en_i (1'b0),
    .slv_req_i ({quadrant_i.narrow_in_req, narrow_out_req}),
    .slv_resp_o ({quadrant_o.narrow_in_rsp, narrow_out_resp}),
    .mst_req_o ({quadrant_o.narrow_out_req, narrow_in_req}),
    .mst_resp_i ({quadrant_i.narrow_out_rsp, narrow_in_resp}),
    .addr_map_i (addr_map),
    .en_default_mst_port_i ({NumPorts{1'b1}}),
    .default_mst_port_i ({NumPorts{NrClustersS1Quadrant[$clog2(NumPorts)-1:0]}})
  );

  /// Snitch cluster.
  for (genvar i = 0; i < NrClustersS1Quadrant; i++) begin : gen_cluster
    logic [9:0] hart_base_id;
    assign hart_base_id = tile_id_i * NrCoresS1Quadrant + i * NrCoresCluster;

    occamy_cluster_pkg::narrow_in_req_t cluster_narrow_in_req;
    occamy_cluster_pkg::narrow_in_resp_t cluster_narrow_in_rsp;
    occamy_cluster_pkg::wide_in_req_t cluster_wide_in_req;
    occamy_cluster_pkg::wide_in_resp_t cluster_wide_in_rsp;

    // TODO(zarubaf): Think about exact parameters. This likely has an
    // performance impact.
    axi_iw_converter #(
      .AxiSlvPortIdWidth (NarrowIdWidth),
      .AxiMstPortIdWidth (occamy_cluster_pkg::NarrowIdWidthIn),
      .AxiSlvPortMaxUniqIds (1),
      .AxiSlvPortMaxTxnsPerId (8),
      .AxiSlvPortMaxTxns (1),
      .AxiMstPortMaxUniqIds (8),
      .AxiMstPortMaxTxnsPerId (8),
      .AxiAddrWidth (AddrWidth),
      .AxiDataWidth (NarrowDataWidth),
      .AxiUserWidth (UserWidth),
      .slv_req_t (axi_narrow_req_t),
      .slv_resp_t (axi_narrow_resp_t),
      .mst_req_t (occamy_cluster_pkg::narrow_in_req_t),
      .mst_resp_t (occamy_cluster_pkg::narrow_in_resp_t)
    ) i_axi_iw_converter_narrow (
      .clk_i (clk_i),
      .rst_ni (rst_ni),
      .slv_req_i (narrow_in_req[i]),
      .slv_resp_o (narrow_in_resp[i]),
      .mst_req_o (cluster_narrow_in_req),
      .mst_resp_i (cluster_narrow_in_rsp)
    );

    axi_iw_converter #(
      .AxiSlvPortIdWidth (WideIdWidth),
      .AxiMstPortIdWidth (occamy_cluster_pkg::WideIdWidthIn),
      .AxiSlvPortMaxUniqIds (1),
      .AxiSlvPortMaxTxnsPerId (8),
      .AxiSlvPortMaxTxns (8),
      .AxiMstPortMaxUniqIds (1),
      .AxiMstPortMaxTxnsPerId (8),
      .AxiAddrWidth (AddrWidth),
      .AxiDataWidth (WideDataWidth),
      .AxiUserWidth (UserWidth),
      .slv_req_t (axi_wide_req_t),
      .slv_resp_t (axi_wide_resp_t),
      .mst_req_t (occamy_cluster_pkg::wide_in_req_t),
      .mst_resp_t (occamy_cluster_pkg::wide_in_resp_t)
    ) i_axi_iw_converter_wide (
      .clk_i (clk_i),
      .rst_ni (rst_ni),
      .slv_req_i (wide_in_req[i]),
      .slv_resp_o (wide_in_resp[i]),
      .mst_req_o (cluster_wide_in_req),
      .mst_resp_i (cluster_wide_in_rsp)
    );

    occamy_cluster_wrapper i_occamy_cluster (
      .clk_i (clk_i),
      .rst_ni (rst_ni),
      .debug_req_i (debug_req_i[i*NrCoresCluster+:NrCoresCluster]),
      .meip_i (meip_i[i*NrCoresCluster+:NrCoresCluster]),
      .mtip_i (mtip_i[i*NrCoresCluster+:NrCoresCluster]),
      .msip_i (msip_i[i*NrCoresCluster+:NrCoresCluster]),
      .hart_base_id_i (hart_base_id),
      .cluster_base_addr_i (cluster_base_addr[i]),
      .clk_d2_bypass_i (1'b0),
      .narrow_in_req_i (cluster_narrow_in_req),
      .narrow_in_resp_o (cluster_narrow_in_rsp),
      .narrow_out_req_o (narrow_out_req[i]),
      .narrow_out_resp_i (narrow_out_resp[i]),
      .wide_out_req_o (wide_out_req[i]),
      .wide_out_resp_i (wide_out_resp[i]),
      .wide_in_req_i (cluster_wide_in_req),
      .wide_in_resp_o (cluster_wide_in_rsp)
    );
  end

endmodule
