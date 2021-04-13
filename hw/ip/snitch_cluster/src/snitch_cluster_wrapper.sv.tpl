// Copyright 2021 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

${disclaimer}

<%def name="icache_cfg(prop)">
  % for lw in cfg['hives']:
    ${lw['icache'][prop]}${',' if not loop.last else ''}
  % endfor
</%def>

<%def name="core_cfg(prop)">\
  % for c in cfg['cores']:
${c[prop]}${', ' if not loop.last else ''}\
  % endfor
</%def>\

<%def name="core_cfg_flat(prop)">\
${cfg['nr_cores']}'b\
  % for c in reversed(cfg['cores']):
${int(c[prop])}\
  % endfor
</%def>\

<%def name="core_isa(isa)">\
${cfg['nr_cores']}'b\
  % for c in cfg['cores']:
${int(getattr(c['isa_parsed'], isa))}\
  % endfor
</%def>\

`include "axi/typedef.svh"

// verilog_lint: waive-start package-filename
package ${cfg['pkg_name']};

  localparam int unsigned NrCores = ${cfg['nr_cores']};
  localparam int unsigned NrHives = ${cfg['nr_hives']};

  localparam int unsigned AddrWidth = ${cfg['addr_width']};
  localparam int unsigned NarrowDataWidth = ${cfg['data_width']};
  localparam int unsigned WideDataWidth = ${cfg['dma_data_width']};

  localparam int unsigned NarrowIdWidthIn = ${cfg['id_width_in']};
  localparam int unsigned NrMasters = 3 + ${cfg['nr_hives']};
  localparam int unsigned NarrowIdWidthOut = $clog2(NrMasters) + NarrowIdWidthIn;

  localparam int unsigned NrDmaMasters = 2;
  localparam int unsigned WideIdWidthIn = ${cfg['dma_id_width_in']};
  localparam int unsigned WideIdWidthOut = $clog2(NrDmaMasters) + WideIdWidthIn;

  localparam int unsigned UserWidth = 1;

  localparam int unsigned ICacheLineWidth [NrHives] = '{${icache_cfg('cacheline')}};
  localparam int unsigned ICacheLineCount [NrHives] = '{${icache_cfg('depth')}};
  localparam int unsigned ICacheSets [NrHives] = '{${icache_cfg('sets')}};

  localparam int unsigned Hive [NrCores] = '{${core_cfg('hive')}};

  typedef logic [AddrWidth-1:0]         addr_t;
  typedef logic [NarrowDataWidth-1:0]   data_t;
  typedef logic [NarrowDataWidth/8-1:0] strb_t;
  typedef logic [WideDataWidth-1:0]     data_dma_t;
  typedef logic [WideDataWidth/8-1:0]   strb_dma_t;
  typedef logic [NarrowIdWidthIn-1:0]   narrow_in_id_t;
  typedef logic [NarrowIdWidthOut-1:0]  narrow_out_id_t;
  typedef logic [WideIdWidthIn-1:0]     wide_in_id_t;
  typedef logic [WideIdWidthOut-1:0]    wide_out_id_t;
  typedef logic [UserWidth-1:0]         user_t;

  `AXI_TYPEDEF_ALL(narrow_in, addr_t, narrow_in_id_t, data_t, strb_t, user_t)
  `AXI_TYPEDEF_ALL(narrow_out, addr_t, narrow_out_id_t, data_t, strb_t, user_t)
  `AXI_TYPEDEF_ALL(wide_in, addr_t, wide_in_id_t, data_dma_t, strb_dma_t, user_t)
  `AXI_TYPEDEF_ALL(wide_out, addr_t, wide_out_id_t, data_dma_t, strb_dma_t, user_t)

  localparam snitch_pma_pkg::snitch_pma_t SnitchPMACfg = '{
      NrCachedRegionRules: ${len(cfg['pmas']['cached'])},
      CachedRegion: '{
% for cp in cfg['pmas']['cached']:
          '{base: ${to_sv_hex(cp[0], cfg['addr_width'])}, mask: ${to_sv_hex(cp[1], cfg['addr_width'])}}${', ' if not loop.last else ''}
% endfor
      },
      default: 0
  };

  localparam fpnew_pkg::fpu_implementation_t FPUImplementation = '{
        PipeRegs: // FMA Block
                  '{
                    '{  ${cfg['timing']['lat_comp_fp32']}, // FP32
                        ${cfg['timing']['lat_comp_fp64']}, // FP64
                        ${cfg['timing']['lat_comp_fp16']}, // FP16
                        ${cfg['timing']['lat_comp_fp8']}, // FP8
                        ${cfg['timing']['lat_comp_fp16_alt']}  // FP16alt
                      },
                    '{default: 1},   // DIVSQRT
                    '{default: ${cfg['timing']['lat_noncomp']}},   // NONCOMP
                    '{default: ${cfg['timing']['lat_conv']}}},   // CONV
        UnitTypes: '{'{default: fpnew_pkg::MERGED},
                    '{default: fpnew_pkg::DISABLED}, // DIVSQRT
                    '{default: fpnew_pkg::PARALLEL}, // NONCOMP
                    '{default: fpnew_pkg::MERGED}},  // CONV
        PipeConfig: fpnew_pkg::${cfg['timing']['fpu_pipe_config']}
    };

endpackage
// verilog_lint: waive-stop package-filename

module ${cfg['name']}_wrapper (
  input  logic                                   clk_i,
  input  logic                                   rst_ni,
  input  logic [${cfg['pkg_name']}::NrCores-1:0] debug_req_i,
  input  logic [${cfg['pkg_name']}::NrCores-1:0] meip_i,
  input  logic [${cfg['pkg_name']}::NrCores-1:0] mtip_i,
  input  logic [${cfg['pkg_name']}::NrCores-1:0] msip_i,
% if not cfg['tie_ports']:
  input  logic [9:0]                             hart_base_id_i,
  input  logic [${cfg['addr_width']-1}:0]                            cluster_base_addr_i,
  input  logic                                   clk_d2_bypass_i,
% endif
  input  ${cfg['pkg_name']}::narrow_in_req_t     narrow_in_req_i,
  output ${cfg['pkg_name']}::narrow_in_resp_t    narrow_in_resp_o,
  output ${cfg['pkg_name']}::narrow_out_req_t    narrow_out_req_o,
  input  ${cfg['pkg_name']}::narrow_out_resp_t   narrow_out_resp_i,
  output ${cfg['pkg_name']}::wide_out_req_t      wide_out_req_o,
  input  ${cfg['pkg_name']}::wide_out_resp_t     wide_out_resp_i,
  input  ${cfg['pkg_name']}::wide_in_req_t       wide_in_req_i,
  output ${cfg['pkg_name']}::wide_in_resp_t      wide_in_resp_o
);

  localparam int unsigned NumIntOutstandingLoads [${cfg['nr_cores']}] = '{${core_cfg('num_int_outstanding_loads')}};
  localparam int unsigned NumIntOutstandingMem [${cfg['nr_cores']}] = '{${core_cfg('num_int_outstanding_mem')}};
  localparam int unsigned NumFPOutstandingLoads [${cfg['nr_cores']}] = '{${core_cfg('num_fp_outstanding_loads')}};
  localparam int unsigned NumFPOutstandingMem [${cfg['nr_cores']}] = '{${core_cfg('num_fp_outstanding_mem')}};
  localparam int unsigned NumDTLBEntries [${cfg['nr_cores']}] = '{${core_cfg('num_dtlb_entries')}};
  localparam int unsigned NumITLBEntries [${cfg['nr_cores']}] = '{${core_cfg('num_itlb_entries')}};
  localparam int unsigned SSRNrCredits [${cfg['nr_cores']}] = '{${core_cfg('ssr_nr_credits')}};
  localparam int unsigned NumSequencerInstr [${cfg['nr_cores']}] = '{${core_cfg('num_sequencer_instructions')}};

  // Snitch cluster under test.
  snitch_cluster #(
    .PhysicalAddrWidth (${cfg['addr_width']}),
    .NarrowDataWidth (${cfg['data_width']}),
    .WideDataWidth (${cfg['dma_data_width']}),
    .NarrowIdWidthIn (${cfg['pkg_name']}::NarrowIdWidthIn),
    .WideIdWidthIn (${cfg['pkg_name']}::WideIdWidthIn),
    .UserWidth (${cfg['pkg_name']}::UserWidth),
    .BootAddr (${to_sv_hex(cfg['boot_addr'], 32)}),
    .narrow_in_req_t (${cfg['pkg_name']}::narrow_in_req_t),
    .narrow_in_resp_t (${cfg['pkg_name']}::narrow_in_resp_t),
    .narrow_out_req_t (${cfg['pkg_name']}::narrow_out_req_t),
    .narrow_out_resp_t (${cfg['pkg_name']}::narrow_out_resp_t),
    .wide_out_req_t (${cfg['pkg_name']}::wide_out_req_t),
    .wide_out_resp_t (${cfg['pkg_name']}::wide_out_resp_t),
    .wide_in_req_t (${cfg['pkg_name']}::wide_in_req_t),
    .wide_in_resp_t (${cfg['pkg_name']}::wide_in_resp_t),
    .NrHives (${cfg['nr_hives']}),
    .NrCores (${cfg['nr_cores']}),
    .TCDMDepth (${cfg['tcdm']['depth']}),
    .NrBanks (${cfg['tcdm']['banks']}),
    .DMAAxiReqFifoDepth (${cfg['dma_axi_req_fifo_depth']}),
    .DMAReqFifoDepth (${cfg['dma_req_fifo_depth']}),
    .ICacheLineWidth (${cfg['pkg_name']}::ICacheLineWidth),
    .ICacheLineCount (${cfg['pkg_name']}::ICacheLineCount),
    .ICacheSets (${cfg['pkg_name']}::ICacheSets),
    .RVE (${core_isa('e')}),
    .RVF (${core_isa('f')}),
    .RVD (${core_isa('d')}),
    .XF16 (${core_cfg_flat('xf16')}),
    .XF16ALT (${core_cfg_flat('xf16alt')}),
    .XF8 (${core_cfg_flat('xf8')}),
    .XFVEC (${core_cfg_flat('xfvec')}),
    .Xdma (${core_cfg_flat('xdma')}),
    .Xssr (${core_cfg_flat('xssr')}),
    .Xfrep (${core_cfg_flat('xfrep')}),
    .FPUImplementation (${cfg['pkg_name']}::FPUImplementation),
    .SnitchPMACfg (${cfg['pkg_name']}::SnitchPMACfg),
    .NumIntOutstandingLoads (NumIntOutstandingLoads),
    .NumIntOutstandingMem (NumIntOutstandingMem),
    .NumFPOutstandingLoads (NumFPOutstandingLoads),
    .NumFPOutstandingMem (NumFPOutstandingMem),
    .NumDTLBEntries (NumDTLBEntries),
    .NumITLBEntries (NumITLBEntries),
    .SSRNrCredits (SSRNrCredits),
    .NumSequencerInstr (NumSequencerInstr),
    .Hive (${cfg['pkg_name']}::Hive),
    .Topology (snitch_pkg::LogarithmicInterconnect),
    .Radix (2),
    .RegisterOffloadReq (${int(cfg['timing']['register_offload_req'])}),
    .RegisterOffloadRsp (${int(cfg['timing']['register_offload_rsp'])}),
    .RegisterCoreReq (${int(cfg['timing']['register_core_req'])}),
    .RegisterCoreRsp (${int(cfg['timing']['register_core_rsp'])}),
    .RegisterTCDMCuts (${int(cfg['timing']['register_tcdm_cuts'])}),
    .RegisterExtWide (${int(cfg['timing']['register_ext_wide'])}),
    .RegisterExtNarrow (${int(cfg['timing']['register_ext_narrow'])}),
    .RegisterFPUReq (${int(cfg['timing']['register_fpu_req'])}),
    .RegisterSequencer (${int(cfg['timing']['register_sequencer'])}),
    .IsoCrossing (${int(cfg['timing']['iso_crossings'])}),
    .NarrowXbarLatency (axi_pkg::${cfg['timing']['narrow_xbar_latency']}),
    .WideXbarLatency (axi_pkg::${cfg['timing']['wide_xbar_latency']})
  ) i_cluster (
    .clk_i,
    .rst_ni,
    .debug_req_i,
    .meip_i,
    .mtip_i,
    .msip_i,
% if cfg['tie_ports']:
    .hart_base_id_i (${to_sv_hex(cfg['hart_base_id'], 10)}),
    .cluster_base_addr_i (${to_sv_hex(cfg['cluster_base_addr'], cfg['addr_width'])}),
    .clk_d2_bypass_i (1'b0),
% else:
    .hart_base_id_i,
    .cluster_base_addr_i,
    .clk_d2_bypass_i,
% endif
    .narrow_in_req_i,
    .narrow_in_resp_o,
    .narrow_out_req_o,
    .narrow_out_resp_i,
    .wide_out_req_o,
    .wide_out_resp_i,
    .wide_in_req_i,
    .wide_in_resp_o
  );
endmodule
