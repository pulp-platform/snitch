// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>
// Author: Fabian Schuiki <fschuiki@iis.ee.ethz.ch>

// AUTOMATICALLY GENERATED by occamygen.py; edit the script instead.
<%
  #// Note: controller introduces *one* cut stage on both narrow bus directions
  cuts_narrx_with_cluster = 0
  cuts_widex_with_cluster = 0
  cuts_narrx_with_ctrl = 1
  cuts_widexroc_with_wideout = 1
  nr_clusters = int(cfg["s1_quadrant"]["nr_clusters"])
  wide_trans = int(cfg["s1_quadrant"]["wide_trans"])
  narrow_trans = int(cfg["s1_quadrant"]["narrow_trans"])
  ro_cache_cfg = cfg["s1_quadrant"].get("ro_cache_cfg", {})
  ro_cache_regions = ro_cache_cfg.get("address_regions", 1)
  narrow_tlb_cfg = cfg["s1_quadrant"].get("narrow_tlb_cfg", {})
  narrow_tlb_entries = narrow_tlb_cfg.get("l1_num_entries", 1)
  wide_tlb_cfg = cfg["s1_quadrant"].get("wide_tlb_cfg", {})
  wide_tlb_entries = wide_tlb_cfg.get("l1_num_entries", 1)
%>

`include "axi/typedef.svh"

/// Occamy Stage 1 Quadrant
module ${name}_quadrant_s1
  import ${name}_pkg::*;
(
  input  logic                         clk_i,
  input  logic                         rst_ni,
  input  logic                         test_mode_i,
  input  tile_id_t                     tile_id_i,
  input  logic [NrCoresS1Quadrant-1:0] meip_i,
  input  logic [NrCoresS1Quadrant-1:0] mtip_i,
  input  logic [NrCoresS1Quadrant-1:0] msip_i,
  // Next-Level
  output ${soc_narrow_xbar.in_s1_quadrant_0.req_type()} quadrant_narrow_out_req_o,
  input  ${soc_narrow_xbar.in_s1_quadrant_0.rsp_type()} quadrant_narrow_out_rsp_i,
  input  ${soc_narrow_xbar.out_s1_quadrant_0.req_type()} quadrant_narrow_in_req_i,
  output ${soc_narrow_xbar.out_s1_quadrant_0.rsp_type()} quadrant_narrow_in_rsp_o,
  output ${quadrant_pre_xbars[0].in_quadrant.req_type()} quadrant_wide_out_req_o,
  input  ${quadrant_pre_xbars[0].in_quadrant.rsp_type()} quadrant_wide_out_rsp_i,
  input  ${quadrant_inter_xbar.out_quadrant_0.req_type()} quadrant_wide_in_req_i,
  output ${quadrant_inter_xbar.out_quadrant_0.rsp_type()} quadrant_wide_in_rsp_o,
  // SRAM configuration
  input  sram_cfg_quadrant_t sram_cfg_i
);

 // Calculate cluster base address based on `tile id`.
  addr_t [${nr_clusters-1}:0] cluster_base_addr;
  % for i in range(nr_clusters):
  assign cluster_base_addr[${i}] = ClusterBaseOffset + tile_id_i * NrClustersS1Quadrant * ClusterAddressSpace + ${i} * ClusterAddressSpace;
  %endfor

  // Define types for IOTLBs
  `AXI_TLB_TYPEDEF_ALL(tlb, logic [AddrWidth-1:0], logic [AddrWidth-1:0])

  // Signals from Controller
  logic clk_quadrant, rst_quadrant_n;
  logic [3:0] isolate, isolated;
  logic ro_enable, ro_flush_valid, ro_flush_ready;
  logic [${ro_cache_regions-1}:0][${quadrant_pre_xbars[0].in_quadrant.aw-1}:0] ro_start_addr, ro_end_addr;
  %if narrow_tlb_cfg:
  logic narrow_tlb_enable;
  tlb_entry_t [${narrow_tlb_entries-1}:0] narrow_tlb_entries;
  % endif
  %if wide_tlb_cfg:
  logic wide_tlb_enable;
  tlb_entry_t [${wide_tlb_entries-1}:0] wide_tlb_entries;
  % endif

  ///////////////////
  //   CROSSBARS   //
  ///////////////////
  ${module}

  ///////////////////////////////
  // Narrow In + IW Converter //
  ///////////////////////////////
  <%
    narrow_cluster_in_ctrl = soc_narrow_xbar.out_s1_quadrant_0 \
      .copy(name="narrow_cluster_in_ctrl") \
      .declare(context)
    narrow_cluster_in_ctrl \
      .cut(context, cuts_narrx_with_ctrl) \
      .isolate(context, "isolate[0]", "narrow_cluster_in_isolate", isolated="isolated[0]", terminated=True, to_clk="clk_quadrant", to_rst="rst_quadrant_n", num_pending=narrow_trans) \
      .change_iw(context, narrow_xbar_quadrant_s1.in_top.iw, "narrow_cluster_in_iwc", to=narrow_xbar_quadrant_s1.in_top)
  %>

  /////////////////////////////////////
  // Narrow Out + TLB + IW Converter //
  /////////////////////////////////////
  <%
  #// Add TLB behind crossbar if enabled
  if narrow_tlb_cfg:
    narrow_cluster_out_tlb = narrow_xbar_quadrant_s1.out_top \
    .add_tlb(context, "narrow_cluster_out_tlb", \
      cfg=narrow_tlb_cfg, \
      entry_t="tlb_entry_t", \
      entries="narrow_tlb_entries", \
      bypass="~narrow_tlb_enable")
  else:
    narrow_cluster_out_tlb = narrow_xbar_quadrant_s1.out_top
  #// Change ID width, isolate, and cut
  narrow_cluster_out_ctrl = narrow_cluster_out_tlb \
    .change_iw(context, soc_narrow_xbar.in_s1_quadrant_0.iw, "narrow_cluster_out_iwc") \
    .isolate(context, "isolate[1]", "narrow_cluster_out_isolate", isolated="isolated[1]", to_clk="clk_i", to_rst="rst_ni", use_to_clk_rst=True, num_pending=narrow_trans) \
    .cut(context, cuts_narrx_with_ctrl, "narrow_cluster_out_ctrl")
   %>

  /////////////////////////////////////////
  // Wide Out + RO Cache + IW Converter  //
  /////////////////////////////////////////
  <%
    wide_target_iw = 3
    #// Add TLB behind crossbar if enabled
    if wide_tlb_cfg:
      wide_cluster_out_tlb = wide_xbar_quadrant_s1.out_top \
      .add_tlb(context, "wide_cluster_out_tlb", \
        cfg=wide_tlb_cfg, \
      entry_t="tlb_entry_t", \
      entries="wide_tlb_entries", \
      bypass="~wide_tlb_enable")
    else:
      wide_cluster_out_tlb = wide_xbar_quadrant_s1.out_top
    #// Add RO cache behind TLB if enabled
    if ro_cache_cfg:
      wide_target_iw += 1
      wide_cluster_out_ro_cache = wide_cluster_out_tlb \
      .add_ro_cache(context, "snitch_ro_cache", \
        ro_cache_cfg, \
        enable="ro_enable", \
        flush_valid="ro_flush_valid", \
        flush_ready="ro_flush_ready", \
        start_addr="ro_start_addr", \
        end_addr="ro_end_addr", \
        sram_cfg_data_t="sram_cfg_t", \
        sram_cfg_tag_t="sram_cfg_t", \
        sram_cfg_data_i="sram_cfg_i.rocache_data", \
        sram_cfg_tag_i="sram_cfg_i.rocache_tag")
    else:
      wide_cluster_out_ro_cache = wide_cluster_out_tlb
    #// Change ID width, isolate, and cut
    wide_cluster_out_cut = wide_cluster_out_ro_cache \
      .change_iw(context, wide_target_iw, "wide_cluster_out_iwc", max_txns_per_id=wide_trans) \
      .isolate(context, "isolate[3]", "wide_cluster_out_isolate", isolated="isolated[3]", atop_support=False, to_clk="clk_i", to_rst="rst_ni", use_to_clk_rst=True, num_pending=wide_trans) \
      .cut(context, cuts_widexroc_with_wideout)
    #// Assert correct outgoing ID widths
    assert quadrant_pre_xbars[0].in_quadrant.iw == wide_cluster_out_cut.iw, "S1 Quadrant and SoC IW mismatches."
  %>

  assign quadrant_wide_out_req_o = ${wide_cluster_out_cut.req_name()};
  assign ${wide_cluster_out_cut.rsp_name()} = quadrant_wide_out_rsp_i;

  ////////////////////////////
  // Wide In + IW Converter //
  ////////////////////////////
  <%
    quadrant_inter_xbar.out_quadrant_0 \
      .copy(name="wide_cluster_in_iwc") \
      .declare(context) \
      .cut(context, cuts_widexroc_with_wideout) \
      .isolate(context, "isolate[2]", "wide_cluster_in_isolate", isolated="isolated[2]", terminated=True, atop_support=False, to_clk="clk_quadrant", to_rst="rst_quadrant_n", num_pending=wide_trans) \
      .change_iw(context, wide_xbar_quadrant_s1.in_top.iw, "wide_cluster_in_iwc", to=wide_xbar_quadrant_s1.in_top)
  %>
  assign wide_cluster_in_iwc_req = quadrant_wide_in_req_i;
  assign quadrant_wide_in_rsp_o = wide_cluster_in_iwc_rsp;

  /////////////////////////
  // Quadrant Controller //
  /////////////////////////

  ${name}_quadrant_s1_ctrl #(
    .tlb_entry_t (tlb_entry_t)
  ) i_${name}_quadrant_s1_ctrl (
    .clk_i,
    .rst_ni,
    .test_mode_i,
    .tile_id_i,
    .clk_quadrant_o (clk_quadrant),
    .rst_quadrant_no (rst_quadrant_n),
    .isolate_o (isolate),
    .isolated_i (isolated),
    .ro_enable_o (ro_enable),
    .ro_flush_valid_o (ro_flush_valid),
    .ro_flush_ready_i  (ro_flush_ready),
    .ro_start_addr_o (ro_start_addr),
    .ro_end_addr_o (ro_end_addr),
    .soc_out_req_o (quadrant_narrow_out_req_o),
    .soc_out_rsp_i (quadrant_narrow_out_rsp_i),
    .soc_in_req_i (quadrant_narrow_in_req_i),
    .soc_in_rsp_o (quadrant_narrow_in_rsp_o),
    %if narrow_tlb_cfg:
    .narrow_tlb_entries_o (narrow_tlb_entries),
    .narrow_tlb_enable_o (narrow_tlb_enable),
    %endif
    %if wide_tlb_cfg:
    .wide_tlb_entries_o (wide_tlb_entries),
    .wide_tlb_enable_o (wide_tlb_enable),
    %endif
    .quadrant_out_req_o (${narrow_cluster_in_ctrl.req_name()}),
    .quadrant_out_rsp_i (${narrow_cluster_in_ctrl.rsp_name()}),
    .quadrant_in_req_i (${narrow_cluster_out_ctrl.req_name()}),
    .quadrant_in_rsp_o (${narrow_cluster_out_ctrl.rsp_name()})
  );

% for i in range(nr_clusters):
  ///////////////
  // Cluster ${i} //
  ///////////////
  <%
    narrow_cluster_in = narrow_xbar_quadrant_s1.__dict__["out_cluster_{}".format(i)].change_iw(context, cfg["cluster"]["id_width_in"], "narrow_in_iwc_{}".format(i)).cut(context, cuts_narrx_with_cluster)
    narrow_cluster_out = narrow_xbar_quadrant_s1.__dict__["in_cluster_{}".format(i)].copy(name="narrow_out_{}".format(i)).declare(context)
    narrow_cluster_out.cut(context, cuts_narrx_with_cluster, to=narrow_xbar_quadrant_s1.__dict__["in_cluster_{}".format(i)])
    wide_cluster_in = wide_xbar_quadrant_s1.__dict__["out_cluster_{}".format(i)].change_iw(context, cfg["cluster"]["dma_id_width_in"], "wide_in_iwc_{}".format(i), max_txns_per_id=wide_trans).cut(context, cuts_widex_with_cluster)
    wide_cluster_out = wide_xbar_quadrant_s1.__dict__["in_cluster_{}".format(i)].copy(name="wide_out_{}".format(i)).declare(context)
    wide_cluster_out.cut(context, cuts_widex_with_cluster, to=wide_xbar_quadrant_s1.__dict__["in_cluster_{}".format(i)])
  %>

  logic [9:0] hart_base_id_${i};
  assign hart_base_id_${i} = HartIdOffset + tile_id_i * NrCoresS1Quadrant + ${i} * NrCoresCluster;

  ${name}_cluster_wrapper i_${name}_cluster_${i} (
    .clk_i (clk_quadrant),
    .rst_ni (rst_quadrant_n),
    .meip_i (meip_i[${i}*NrCoresCluster+:NrCoresCluster]),
    .mtip_i (mtip_i[${i}*NrCoresCluster+:NrCoresCluster]),
    .msip_i (msip_i[${i}*NrCoresCluster+:NrCoresCluster]),
    .hart_base_id_i (hart_base_id_${i}),
    .cluster_base_addr_i (cluster_base_addr[${i}]),
    .narrow_in_req_i (${narrow_cluster_in.req_name()}),
    .narrow_in_resp_o (${narrow_cluster_in.rsp_name()}),
    .narrow_out_req_o  (${narrow_cluster_out.req_name()}),
    .narrow_out_resp_i (${narrow_cluster_out.rsp_name()}),
    .wide_out_req_o  (${wide_cluster_out.req_name()}),
    .wide_out_resp_i (${wide_cluster_out.rsp_name()}),
    .wide_in_req_i (${wide_cluster_in.req_name()}),
    .wide_in_resp_o (${wide_cluster_in.rsp_name()}),
    .sram_cfgs_i (sram_cfg_i.cluster)
  );

% endfor
endmodule
