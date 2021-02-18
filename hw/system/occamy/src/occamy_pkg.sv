// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

`include "axi/typedef.svh"

package occamy_pkg;

  // Re-exports
  localparam AddrWidth = occamy_cluster_pkg::AddrWidth;
  localparam NarrowDataWidth = occamy_cluster_pkg::NarrowDataWidth;
  localparam NarrowIdWidth = occamy_cluster_pkg::NarrowIdWidthOut;
  localparam WideDataWidth = occamy_cluster_pkg::WideDataWidth;
  localparam WideIdWidth = occamy_cluster_pkg::WideIdWidthOut;
  localparam UserWidth = occamy_cluster_pkg::UserWidth;

  localparam NrClustersS1Quadrant = 4;
  localparam NrCoresCluster = occamy_cluster_pkg::NrCores;
  localparam NrCoresS1Quadrant = NrClustersS1Quadrant * NrCoresCluster;

  localparam NrS1Quadrants = 8;

  typedef logic [5:0] tile_id_t;

  typedef logic [AddrWidth-1:0]         addr_t;
  typedef logic [NarrowDataWidth-1:0]   narrow_data_t;
  typedef logic [NarrowDataWidth/8-1:0] narrow_strb_t;
  typedef logic [NarrowIdWidth-1:0]     narrow_id_t;
  typedef logic [WideDataWidth-1:0]     wide_data_t;
  typedef logic [WideDataWidth/8-1:0]   wide_strb_t;
  typedef logic [WideIdWidth-1:0]       wide_id_t;
  typedef logic [UserWidth-1:0]         user_t;

  typedef struct packed {
    int unsigned idx;
    addr_t start_addr;
    addr_t end_addr;
  } xbar_rule_t;

  `AXI_TYPEDEF_ALL(axi_narrow, addr_t, narrow_id_t, narrow_data_t, narrow_strb_t, user_t)
  `AXI_TYPEDEF_ALL(axi_narrow_wide_id, addr_t, wide_id_t, narrow_data_t, narrow_strb_t, user_t)
  `AXI_TYPEDEF_ALL(axi_wide, addr_t, wide_id_t, wide_data_t, wide_strb_t, user_t)

  typedef struct packed {
    axi_narrow_req_t narrow_in_req;
    axi_narrow_resp_t narrow_out_rsp;
    axi_wide_req_t wide_in_req;
    axi_wide_resp_t wide_out_rsp;
  } quadrant_in_t;

  typedef struct packed {
    axi_narrow_resp_t narrow_in_rsp;
    axi_narrow_req_t narrow_out_req;
    axi_wide_resp_t wide_in_rsp;
    axi_wide_req_t wide_out_req;
  } quadrant_out_t;

  // PCIe
  typedef struct packed {
    axi_wide_req_t pcie_in_req;
    axi_wide_resp_t pcie_out_rsp;
  } pice_in_t;

  typedef struct packed {
    axi_wide_req_t pcie_out_req;
    axi_wide_resp_t pcie_in_rsp;
  } pice_out_t;

  /// The base offset for each cluster.
  localparam addr_t ClusterBaseOffset = 'h1000_0000;
  /// The address space set aside for each slave.
  localparam addr_t ClusterAddressSpace = 'h10_0000;
  /// The address space of a single S1 quadrant.
  localparam addr_t S1QuadrantAddressSpace = ClusterAddressSpace * NrClustersS1Quadrant;
endpackage
