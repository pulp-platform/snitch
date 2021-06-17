// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>

`include "common_cells/assertions.svh"
`include "common_cells/registers.svh"
`include "snitch_vm/typedef.svh"

/// Snitch Core Complex (CC)
/// Contains the Snitch Integer Core + FPU + Private Accelerators
module snitch_cc #(
  /// Address width of the buses
  parameter int unsigned AddrWidth          = 0,
  /// Data width of the buses.
  parameter int unsigned DataWidth          = 0,
  /// Data width of the AXI DMA buses.
  parameter int unsigned DMADataWidth       = 0,
  /// Id width of the AXI DMA bus.
  parameter int unsigned DMAIdWidth         = 0,
  parameter int unsigned DMAAxiReqFifoDepth = 0,
  parameter int unsigned DMAReqFifoDepth    = 0,
  /// Data port request type.
  parameter type         dreq_t             = logic,
  /// Data port response type.
  parameter type         drsp_t             = logic,
  /// Data port request type.
  parameter type         tcdm_req_t         = logic,
  /// Data port response type.
  parameter type         tcdm_rsp_t         = logic,
  /// TCDM User Payload
  parameter type         tcdm_user_t        = logic,
  parameter type         axi_req_t          = logic,
  parameter type         axi_rsp_t          = logic,
  parameter type         hive_req_t         = logic,
  parameter type         hive_rsp_t         = logic,
  parameter type         acc_req_t          = logic,
  parameter type         acc_resp_t         = logic,
  parameter fpnew_pkg::fpu_implementation_t FPUImplementation = '0,
  /// Boot address of core.
  parameter logic [31:0] BootAddr           = 32'h0000_1000,
  /// Reduced-register extension
  parameter bit          RVE                = 0,
  /// Enable F and D Extension
  parameter bit          RVF                = 1,
  parameter bit          RVD                = 1,
  parameter bit          XF8                = 0,
  parameter bit          XF16               = 0,
  parameter bit          XF16ALT            = 0,
  parameter bit          XFVEC              = 0,
  /// Enable Snitch DMA
  parameter bit          Xdma               = 0,
  /// Has `frep` support.
  parameter bit          Xfrep              = 1,
  /// Has `SSR` support.
  parameter bit          Xssr               = 1,
  /// Has `IPU` support.
  parameter bit          Xipu               = 1,
  parameter int unsigned NumIntOutstandingLoads = 0,
  parameter int unsigned NumIntOutstandingMem = 0,
  parameter int unsigned NumFPOutstandingLoads = 0,
  parameter int unsigned NumFPOutstandingMem = 0,
  parameter int unsigned NumDTLBEntries = 0,
  parameter int unsigned NumITLBEntries = 0,
  parameter int unsigned NumSequencerInstr = 0,
  parameter int unsigned NumSsrs = 0,
  parameter int unsigned SsrMuxRespDepth = 0,
  parameter snitch_ssr_pkg::ssr_cfg_t [NumSsrs-1:0] SsrCfgs = '0,
  parameter logic [NumSsrs-1:0][4:0] SsrRegs = '0,
  /// Add isochronous clock-domain crossings e.g., make it possible to operate
  /// the core in a slower clock domain.
  parameter bit          IsoCrossing        = 0,
  /// Timing Parameters
  /// Insert Pipeline registers into off-loading path (request)
  parameter bit          RegisterOffloadReq = 0,
  /// Insert Pipeline registers into off-loading path (response)
  parameter bit          RegisterOffloadRsp = 0,
  /// Insert Pipeline registers into data memory path (request)
  parameter bit          RegisterCoreReq    = 0,
  /// Insert Pipeline registers into data memory path (response)
  parameter bit          RegisterCoreRsp    = 0,
  /// Insert Pipeline register into the FPU data path (request)
  parameter bit          RegisterFPUReq     = 0,
  /// Insert Pipeline registers after sequencer
  parameter bit          RegisterSequencer  = 0,
  snitch_pma_pkg::snitch_pma_t SnitchPMACfg = '{default: 0},
  /// Derived parameter *Do not override*
  parameter int unsigned TCDMPorts = (NumSsrs > 1 ? NumSsrs : 1),
  parameter type addr_t = logic [AddrWidth-1:0],
  parameter type data_t = logic [DataWidth-1:0]
) (
  input  logic                       clk_i,
  input  logic                       clk_d2_i,
  input  logic                       rst_ni,
  input  logic                       rst_int_ss_ni,
  input  logic                       rst_fp_ss_ni,
  input  logic [31:0]                hart_id_i,
  input  snitch_pkg::interrupts_t    irq_i,
  output hive_req_t                  hive_req_o,
  input  hive_rsp_t                  hive_rsp_i,
  // Core data ports
  output dreq_t                      data_req_o,
  input  drsp_t                      data_rsp_i,
  // TCDM Streamer Ports
  output tcdm_req_t [TCDMPorts-1:0]  tcdm_req_o,
  input  tcdm_rsp_t [TCDMPorts-1:0]  tcdm_rsp_i,
  input  logic                       wake_up_sync_i,
  // Accelerator Offload port
  // DMA ports
  output axi_req_t                   axi_dma_req_o,
  input  axi_rsp_t                   axi_dma_res_i,
  output logic                       axi_dma_busy_o,
  output axi_dma_pkg::dma_perf_t     axi_dma_perf_o,
  // Core event strobes
  output snitch_pkg::core_events_t   core_events_o,
  input  addr_t                      tcdm_addr_base_i,
  input  addr_t                      tcdm_addr_mask_i
);

  localparam bit FPEn = RVF | RVD | XF16 | XF16ALT | XF8 | XFVEC | XF16 | XF16ALT | XF8;
  localparam int unsigned FLEN = RVD     ? 64 : // D ext.
                          RVF     ? 32 : // F ext.
                          XF16    ? 16 : // Xf16 ext.
                          XF16ALT ? 16 : // Xf16alt ext.
                          XF8     ? 8 :  // Xf8 ext.
                          0;             // Unused in case of no FP

  typedef struct packed {
    logic [4:0]  id;
    logic [11:0] word;
    logic [31:0] data;
    logic        write;
  } ssr_cfg_req_t;

  typedef struct packed {
    logic [4:0]  id;
    logic [31:0] data;
  } ssr_cfg_rsp_t;

  acc_req_t acc_snitch_req;
  acc_req_t acc_snitch_demux;
  acc_req_t acc_snitch_demux_q;
  acc_resp_t acc_seq;
  acc_resp_t acc_demux_snitch;
  acc_resp_t acc_demux_snitch_q;
  acc_resp_t dma_resp;
  acc_resp_t ipu_resp;

  acc_resp_t ssr_resp;

  logic acc_snitch_demux_qvalid, acc_snitch_demux_qready;
  logic acc_snitch_demux_qvalid_q, acc_snitch_demux_qready_q;
  logic acc_qvalid, acc_qready;
  logic dma_qvalid, dma_qready;
  logic ipu_qvalid, ipu_qready;
  logic ssr_qvalid, ssr_qready;

  logic acc_pvalid, acc_pready;
  logic dma_pvalid, dma_pready;
  logic ipu_pvalid, ipu_pready;
  logic ssr_pvalid, ssr_pready;
  logic acc_demux_snitch_valid, acc_demux_snitch_ready;
  logic acc_demux_snitch_valid_q, acc_demux_snitch_ready_q;

  fpnew_pkg::roundmode_e fpu_rnd_mode;
  fpnew_pkg::status_t    fpu_status;

  // Snitch Integer Core
  dreq_t snitch_dreq_d, snitch_dreq_q, merged_dreq;
  drsp_t snitch_drsp_d, snitch_drsp_q, merged_drsp;

  logic wake_up;

  `SNITCH_VM_TYPEDEF(AddrWidth)

  snitch #(
    .AddrWidth (AddrWidth),
    .DataWidth (DataWidth),
    .acc_req_t (acc_req_t),
    .acc_resp_t (acc_resp_t),
    .dreq_t (dreq_t),
    .drsp_t (drsp_t),
    .pa_t (pa_t),
    .l0_pte_t (l0_pte_t),
    .BootAddr (BootAddr),
    .SnitchPMACfg (SnitchPMACfg),
    .NumIntOutstandingLoads (NumIntOutstandingLoads),
    .NumIntOutstandingMem (NumIntOutstandingMem),
    .NumDTLBEntries (NumDTLBEntries),
    .NumITLBEntries (NumITLBEntries),
    .RVE (RVE),
    .FP_EN (FPEn),
    .Xdma (Xdma),
    .Xssr (Xssr),
    .RVF (RVF),
    .RVD (RVD),
    .XF16 (XF16),
    .XF16ALT (XF16ALT),
    .XF8 (XF8),
    .XFVEC (XFVEC),
    .FLEN (FLEN)
  ) i_snitch (
    .clk_i ( clk_d2_i ), // if necessary operate on half the frequency
    .rst_i ( ~rst_ni ),
    .hart_id_i,
    .irq_i,
    .flush_i_valid_o (hive_req_o.flush_i_valid),
    .flush_i_ready_i (hive_rsp_i.flush_i_ready),
    .inst_addr_o (hive_req_o.inst_addr),
    .inst_cacheable_o (hive_req_o.inst_cacheable),
    .inst_data_i (hive_rsp_i.inst_data),
    .inst_valid_o (hive_req_o.inst_valid),
    .inst_ready_i (hive_rsp_i.inst_ready),
    .acc_qreq_o ( acc_snitch_demux ),
    .acc_qvalid_o ( acc_snitch_demux_qvalid ),
    .acc_qready_i ( acc_snitch_demux_qready ),
    .acc_prsp_i ( acc_demux_snitch ),
    .acc_pvalid_i ( acc_demux_snitch_valid ),
    .acc_pready_o ( acc_demux_snitch_ready ),
    .data_req_o ( snitch_dreq_d ),
    .data_rsp_i ( snitch_drsp_d ),
    .ptw_valid_o (hive_req_o.ptw_valid),
    .ptw_ready_i (hive_rsp_i.ptw_ready),
    .ptw_va_o (hive_req_o.ptw_va),
    .ptw_ppn_o (hive_req_o.ptw_ppn),
    .ptw_pte_i (hive_rsp_i.ptw_pte),
    .ptw_is_4mega_i (hive_rsp_i.ptw_is_4mega),
    .wake_up_sync_i,
    .fpu_rnd_mode_o ( fpu_rnd_mode ),
    .fpu_status_i ( fpu_status )
  );

  reqrsp_iso #(
    .AddrWidth (AddrWidth),
    .DataWidth (DataWidth),
    .req_t (dreq_t),
    .rsp_t (drsp_t),
    .BypassReq (!RegisterCoreReq),
    .BypassRsp (!IsoCrossing && !RegisterCoreRsp)
  ) i_reqrsp_iso (
    .src_clk_i (clk_d2_i),
    .src_rst_ni (rst_ni),
    .src_req_i (snitch_dreq_d),
    .src_rsp_o (snitch_drsp_d),
    .dst_clk_i (clk_i),
    .dst_rst_ni (rst_ni),
    .dst_req_o (snitch_dreq_q),
    .dst_rsp_i (snitch_drsp_q)
  );

  // Cut off-loading request path
  isochronous_spill_register #(
    .T      (acc_req_t),
    .Bypass (!IsoCrossing && !RegisterOffloadReq)
  ) i_spill_register_acc_demux_req (
    .src_clk_i   ( clk_d2_i                  ),
    .src_rst_ni  ( rst_ni                    ),
    .src_valid_i ( acc_snitch_demux_qvalid   ),
    .src_ready_o ( acc_snitch_demux_qready   ),
    .src_data_i  ( acc_snitch_demux          ),
    .dst_clk_i   ( clk_i                     ),
    .dst_rst_ni  ( rst_ni                    ),
    .dst_valid_o ( acc_snitch_demux_qvalid_q ),
    .dst_ready_i ( acc_snitch_demux_qready_q ),
    .dst_data_o  ( acc_snitch_demux_q        )
  );

  // Cut off-loading response path
  isochronous_spill_register #(
    .T (acc_resp_t),
    .Bypass (!IsoCrossing && !RegisterOffloadRsp)
  ) i_spill_register_acc_demux_resp (
    .src_clk_i   ( clk_i                    ),
    .src_rst_ni  ( rst_ni                   ),
    .src_valid_i ( acc_demux_snitch_valid_q ),
    .src_ready_o ( acc_demux_snitch_ready_q ),
    .src_data_i  ( acc_demux_snitch_q       ),
    .dst_clk_i   ( clk_d2_i                 ),
    .dst_rst_ni  ( rst_ni                   ),
    .dst_valid_o ( acc_demux_snitch_valid   ),
    .dst_ready_i ( acc_demux_snitch_ready   ),
    .dst_data_o  ( acc_demux_snitch         )
  );

  // Accelerator Demux Port
  stream_demux #(
    .N_OUP ( 5 )
  ) i_stream_demux_offload (
    .inp_valid_i  ( acc_snitch_demux_qvalid_q  ),
    .inp_ready_o  ( acc_snitch_demux_qready_q  ),
    .oup_sel_i    ( acc_snitch_demux_q.addr[$clog2(5)-1:0]             ),
    .oup_valid_o  ( {ssr_qvalid, ipu_qvalid, dma_qvalid, hive_req_o.acc_qvalid, acc_qvalid} ),
    .oup_ready_i  ( {ssr_qready, ipu_qready, dma_qready, hive_rsp_i.acc_qready, acc_qready} )
  );

  // To shared muldiv
  assign hive_req_o.acc_req = acc_snitch_demux_q;
  assign acc_snitch_req = acc_snitch_demux_q;

  stream_arbiter #(
    .DATA_T      ( acc_resp_t ),
    .N_INP       ( 5          )
  ) i_stream_arbiter_offload (
    .clk_i       ( clk_i                                   ),
    .rst_ni      ( rst_ni                                  ),
    .inp_data_i  ( {ssr_resp,   ipu_resp,   dma_resp,   hive_rsp_i.acc_resp,   acc_seq    } ),
    .inp_valid_i ( {ssr_pvalid, ipu_pvalid, dma_pvalid, hive_rsp_i.acc_pvalid, acc_pvalid } ),
    .inp_ready_o ( {ssr_pready, ipu_pready, dma_pready, hive_req_o.acc_pready, acc_pready } ),
    .oup_data_o  ( acc_demux_snitch_q                      ),
    .oup_valid_o ( acc_demux_snitch_valid_q                ),
    .oup_ready_i ( acc_demux_snitch_ready_q                )
  );

  if (Xdma) begin : gen_dma
    axi_dma_tc_snitch_fe #(
      .AddrWidth (AddrWidth),
      .DataWidth (DataWidth),
      .DMADataWidth (DMADataWidth),
      .IdWidth (DMAIdWidth),
      .DMAAxiReqFifoDepth (DMAAxiReqFifoDepth),
      .DMAReqFifoDepth (DMAReqFifoDepth),
      .axi_req_t (axi_req_t),
      .axi_res_t (axi_rsp_t),
      .acc_resp_t (acc_resp_t)
    ) i_axi_dma_tc_snitch_fe (
      .clk_i            ( clk_i                     ),
      .rst_ni           ( rst_ni                    ),
      .axi_dma_req_o    ( axi_dma_req_o             ),
      .axi_dma_res_i    ( axi_dma_res_i             ),
      .dma_busy_o       ( axi_dma_busy_o            ),
      .acc_qaddr_i      ( acc_snitch_req.addr       ),
      .acc_qid_i        ( acc_snitch_req.id         ),
      .acc_qdata_op_i   ( acc_snitch_req.data_op    ),
      .acc_qdata_arga_i ( acc_snitch_req.data_arga  ),
      .acc_qdata_argb_i ( acc_snitch_req.data_argb  ),
      .acc_qdata_argc_i ( acc_snitch_req.data_argc  ),
      .acc_qvalid_i     ( dma_qvalid                ),
      .acc_qready_o     ( dma_qready                ),
      .acc_pdata_o      ( dma_resp.data             ),
      .acc_pid_o        ( dma_resp.id               ),
      .acc_perror_o     ( dma_resp.error            ),
      .acc_pvalid_o     ( dma_pvalid                ),
      .acc_pready_i     ( dma_pready                ),
      .hart_id_i        ( hart_id_i                 ),
      .dma_perf_o       ( axi_dma_perf_o            )
    );

  // no DMA instanciated
  end else begin : gen_no_dma
    // tie-off unused signals
    assign axi_dma_req_o   =  '0;
    assign axi_dma_busy_o  = 1'b0;

    assign dma_qready      =  '0;
    assign dma_pvalid      =  '0;

    assign dma_resp        =  '0;
    assign axi_dma_perf_o  = '0;
  end

  if (Xipu) begin : gen_ipu
    snitch_int_ss # (
      .AddrWidth (AddrWidth),
      .DataWidth (DataWidth),
      .NumIPUSequencerInstr (NumSequencerInstr),
      .acc_req_t (acc_req_t),
      .acc_resp_t (acc_resp_t)
    ) i_snitch_int_ss (
      .clk_i            ( clk_i                    ),
      .rst_i            ( (~rst_ni) | (~rst_int_ss_ni) ),
      .acc_req_i        ( acc_snitch_req           ),
      .acc_req_valid_i  ( ipu_qvalid               ),
      .acc_req_ready_o  ( ipu_qready               ),
      .acc_resp_o       ( ipu_resp                 ),
      .acc_resp_valid_o ( ipu_pvalid               ),
      .acc_resp_ready_i ( ipu_pready               ),
      .ssr_raddr_o      ( /* TODO */               ),
      .ssr_rdata_i      ('0                        ),
      .ssr_rvalid_o     ( /* TODO */               ),
      .ssr_rready_i     ('0                        ),
      .ssr_rdone_o      ( /* TODO */               ),
      .ssr_waddr_o      ( /* TODO */               ),
      .ssr_wdata_o      ( /* TODO */               ),
      .ssr_wvalid_o     ( /* TODO */               ),
      .ssr_wready_i     ('0                        ),
      .ssr_wdone_o      ( /* TODO */               )
    );
  end else begin : gen_no_ipu
    assign ipu_resp = '0;
    assign ipu_qready = 1'b0;
    assign ipu_pvalid = '0;
  end

  // pragma translate_off
  snitch_pkg::fpu_trace_port_t fpu_trace;
  snitch_pkg::fpu_sequencer_trace_port_t fpu_sequencer_trace;
  // pragma translate_on

  logic  [2:0][4:0] ssr_raddr;
  data_t [2:0]      ssr_rdata;
  logic  [2:0]      ssr_rvalid;
  logic  [2:0]      ssr_rready;
  logic  [2:0]      ssr_rdone;
  logic  [0:0][4:0] ssr_waddr;
  data_t [0:0]      ssr_wdata;
  logic  [0:0]      ssr_wvalid;
  logic  [0:0]      ssr_wready;
  logic  [0:0]      ssr_wdone;

  if (FPEn) begin : gen_fpu
    snitch_pkg::core_events_t fp_ss_core_events;

    dreq_t fpu_dreq;
    drsp_t fpu_drsp;

    snitch_fp_ss #(
      .AddrWidth (AddrWidth),
      .DataWidth (DataWidth),
      .NumFPOutstandingLoads (NumFPOutstandingLoads),
      .NumFPOutstandingMem (NumFPOutstandingMem),
      .NumFPUSequencerInstr (NumSequencerInstr),
      .FPUImplementation (FPUImplementation),
      .NumSsrs (NumSsrs),
      .SsrRegs (SsrRegs),
      .dreq_t (dreq_t),
      .drsp_t (drsp_t),
      .acc_req_t (acc_req_t),
      .acc_resp_t (acc_resp_t),
      .RegisterSequencer ( RegisterSequencer ),
      .Xfrep (Xfrep),
      .Xssr (Xssr),
      .RVF (RVF),
      .RVD (RVD),
      .XF16 (XF16),
      .XF16ALT (XF16ALT),
      .XF8 (XF8),
      .XFVEC (XFVEC),
      .FLEN (FLEN)
    ) i_snitch_fp_ss (
      .clk_i,
      .rst_i            ( ~rst_ni | (~rst_fp_ss_ni)   ),
      // pragma translate_off
      .trace_port_o            ( fpu_trace           ),
      .sequencer_tracer_port_o ( fpu_sequencer_trace ),
      // pragma translate_on
      .acc_req_i        ( acc_snitch_req ),
      .acc_req_valid_i  ( acc_qvalid     ),
      .acc_req_ready_o  ( acc_qready     ),
      .acc_resp_o       ( acc_seq        ),
      .acc_resp_valid_o ( acc_pvalid     ),
      .acc_resp_ready_i ( acc_pready     ),
      .data_req_o       ( fpu_dreq       ),
      .data_rsp_i       ( fpu_drsp       ),
      .fpu_rnd_mode_i   ( fpu_rnd_mode   ),
      .fpu_status_o     ( fpu_status     ),
      .ssr_raddr_o      ( ssr_raddr      ),
      .ssr_rdata_i      ( ssr_rdata      ),
      .ssr_rvalid_o     ( ssr_rvalid     ),
      .ssr_rready_i     ( ssr_rready     ),
      .ssr_rdone_o      ( ssr_rdone      ),
      .ssr_waddr_o      ( ssr_waddr      ),
      .ssr_wdata_o      ( ssr_wdata      ),
      .ssr_wvalid_o     ( ssr_wvalid     ),
      .ssr_wready_i     ( ssr_wready     ),
      .ssr_wdone_o      ( ssr_wdone      ),
      .core_events_o
    );

    reqrsp_mux #(
      .NrPorts (2),
      .AddrWidth (AddrWidth),
      .DataWidth (DataWidth),
      .req_t (dreq_t),
      .rsp_t (drsp_t),
      // TODO(zarubaf): Wire-up to top-level.
      .RespDepth (8),
      .RegisterReq ({RegisterFPUReq, 1'b0})
    ) i_reqrsp_mux (
      .clk_i,
      .rst_ni,
      .slv_req_i ({fpu_dreq, snitch_dreq_q}),
      .slv_rsp_o ({fpu_drsp, snitch_drsp_q}),
      .mst_req_o (merged_dreq),
      .mst_rsp_i (merged_drsp)
    );

  end else begin : gen_no_fpu
    assign fpu_status = '0;

    assign ssr_raddr = '0;
    assign ssr_rvalid = '0;
    assign ssr_rdone = '0;
    assign ssr_waddr = '0;
    assign ssr_wdata = '0;
    assign ssr_wvalid = '0;
    assign ssr_wdone = '0;

    assign acc_qready    = '0;
    assign acc_seq.data  = '0;
    assign acc_seq.id    = '0;
    assign acc_seq.error = '0;
    assign acc_pvalid    = '0;

    assign merged_dreq = snitch_dreq_q;
    assign snitch_drsp_q = merged_drsp;

    assign core_events_o = '0;
  end

  // Decide whether to go to SoC or TCDM
  dreq_t data_tcdm_req;
  drsp_t data_tcdm_rsp;
  localparam int unsigned SelectWidth = cf_math_pkg::idx_width(2);
  typedef logic [SelectWidth-1:0] select_t;
  select_t slave_select;
  reqrsp_demux #(
    .NrPorts (2),
    .req_t (dreq_t),
    .rsp_t (drsp_t),
    // TODO(zarubaf): Make a parameter.
    .RespDepth (4)
  ) i_reqrsp_demux (
    .clk_i,
    .rst_ni,
    .slv_select_i (slave_select),
    .slv_req_i (merged_dreq),
    .slv_rsp_o (merged_drsp),
    .mst_req_o ({data_tcdm_req, data_req_o}),
    .mst_rsp_i ({data_tcdm_rsp, data_rsp_i})
  );

  typedef struct packed {
    int unsigned idx;
    logic [AddrWidth-1:0] base;
    logic [AddrWidth-1:0] mask;
  } reqrsp_rule_t;

  reqrsp_rule_t addr_map;
  assign addr_map = '{
    idx: 1,
    base: tcdm_addr_base_i,
    mask: tcdm_addr_mask_i
  };

  addr_decode_napot #(
    .NoIndices (2),
    .NoRules (1),
    .addr_t (logic [AddrWidth-1:0]),
    .rule_t (reqrsp_rule_t)
  ) i_addr_decode_napot (
    .addr_i (merged_dreq.q.addr),
    .addr_map_i (addr_map),
    .idx_o (slave_select),
    .dec_valid_o (),
    .dec_error_o (),
    .en_default_idx_i (1'b1),
    .default_idx_i ('0)
  );

  tcdm_req_t core_tcdm_req;
  tcdm_rsp_t core_tcdm_rsp;

  reqrsp_to_tcdm #(
    .AddrWidth (AddrWidth),
    .DataWidth (DataWidth),
    // TODO(zarubaf): Make a parameter.
    .BufDepth (4),
    .reqrsp_req_t (dreq_t),
    .reqrsp_rsp_t (drsp_t),
    .tcdm_req_t (tcdm_req_t),
    .tcdm_rsp_t (tcdm_rsp_t)
  ) i_reqrsp_to_tcdm (
    .clk_i,
    .rst_ni,
    .reqrsp_req_i (data_tcdm_req),
    .reqrsp_rsp_o (data_tcdm_rsp),
    .tcdm_req_o (core_tcdm_req),
    .tcdm_rsp_i (core_tcdm_rsp)
  );

  // ----
  // SSRs
  // ----
  if (Xssr) begin : gen_ssrs
    tcdm_req_t [NumSsrs-1:0] ssr_req;
    tcdm_rsp_t [NumSsrs-1:0] ssr_rsp;
    tcdm_req_t tcdm_req;
    tcdm_rsp_t tcdm_rsp;

    ssr_cfg_req_t ssr_cfg_req, cfg_req;
    ssr_cfg_rsp_t ssr_cfg_rsp, cfg_rsp;

    logic cfg_req_valid, cfg_req_valid_q;
    logic [31:0] cfg_rsp_data;
    `FF(cfg_req_valid_q, cfg_req_valid, 0)
    `FF(cfg_rsp.id, ssr_cfg_req.id, 0)
    `FF(cfg_rsp.data, cfg_rsp_data, 0)

    always_comb begin
      import riscv_instr::*;
      automatic logic [11:0] addr;
      automatic logic [4:0] addr_dm;
      automatic logic [6:0] addr_reg;

      ssr_cfg_req.id = acc_snitch_demux_q.id;
      ssr_cfg_req.data = acc_snitch_demux_q.data_arga[31:0];
      ssr_cfg_req.word = '0;
      ssr_cfg_req.write = '0;

      unique casez (acc_snitch_demux_q.data_op)
        SCFGRI,
        SCFGWI: begin
          addr = acc_snitch_demux_q.data_op[31:20];
        end
        SCFGR,
        SCFGW: begin
          addr = acc_snitch_demux_q.data_argb[31:0];
        end
        default: ;
      endcase

      addr_reg = addr[11:5];
      addr_dm = addr[4:0];
      ssr_cfg_req.word = {addr_dm, addr_reg};

      unique casez (acc_snitch_demux_q.data_op)
        SCFGRI,
        SCFGR:
          ssr_cfg_req.write = '0;
        SCFGWI,
        SCFGW: begin
          ssr_cfg_req.write = '1;
          ssr_cfg_req.id = '0; // prevent write-back of result
        end
        default: ;
      endcase
    end

    assign ssr_resp.id = ssr_cfg_rsp.id;
    assign ssr_resp.error = 1'b0;
    assign ssr_resp.data = ssr_cfg_rsp.data;

    stream_to_mem #(
      .mem_req_t (ssr_cfg_req_t),
      .mem_resp_t (ssr_cfg_rsp_t),
      .BufDepth (1)
    ) i_stream_to_mem (
      .clk_i,
      .rst_ni,
      .req_i (ssr_cfg_req),
      .req_valid_i (ssr_qvalid),
      .req_ready_o (ssr_qready),
      .resp_o (ssr_cfg_rsp),
      .resp_valid_o (ssr_pvalid),
      .resp_ready_i (ssr_pready),
      .mem_req_o (cfg_req),
      .mem_req_valid_o (cfg_req_valid),
      .mem_req_ready_i (1'b1),
      .mem_resp_i (cfg_rsp),
      .mem_resp_valid_i (cfg_req_valid_q)
    );

    // TODO: Assert that NumSsrs is at least 1 in any case

    snitch_ssr_streamer #(
      .NumSsrs (NumSsrs),
      .RPorts (3),
      .WPorts (1),
      .SsrCfgs (SsrCfgs),
      .SsrRegs (SsrRegs),
      .AddrWidth (AddrWidth),
      .DataWidth (DataWidth),
      .tcdm_req_t (tcdm_req_t),
      .tcdm_rsp_t (tcdm_rsp_t),
      .tcdm_user_t (tcdm_user_t)
    ) i_snitch_ssr_streamer (
      .clk_i,
      .rst_ni         ( rst_ni    ),
      .cfg_word_i     ( cfg_req.word  ),
      .cfg_write_i    ( cfg_req.write & cfg_req_valid ),
      .cfg_rdata_o    ( cfg_rsp_data ),
      .cfg_wdata_i    ( cfg_req.data ),

      .ssr_raddr_i    ( ssr_raddr  ),
      .ssr_rdata_o    ( ssr_rdata  ),
      .ssr_rvalid_i   ( ssr_rvalid ),
      .ssr_rready_o   ( ssr_rready ),
      .ssr_rdone_i    ( ssr_rdone  ),
      .ssr_waddr_i    ( ssr_waddr  ),
      .ssr_wdata_i    ( ssr_wdata  ),
      .ssr_wvalid_i   ( ssr_wvalid ),
      .ssr_wready_o   ( ssr_wready ),
      .ssr_wdone_i    ( ssr_wdone  ),
      .mem_req_o      ( ssr_req    ),
      .mem_rsp_i      ( ssr_rsp    ),
      .tcdm_start_address_i (tcdm_addr_base_i)
    );

  if (NumSsrs > 1) begin : gen_multi_ssr
    assign ssr_rsp = {tcdm_rsp_i[NumSsrs-1:1], tcdm_rsp};
    assign {tcdm_req_o[NumSsrs-1:1], tcdm_req} = ssr_req;
  end else begin : gen_one_ssr
    assign ssr_rsp = tcdm_rsp;
    assign tcdm_req = ssr_req;
  end

  tcdm_mux #(
    .NrPorts (2),
    .AddrWidth (AddrWidth),
    .DataWidth (DataWidth),
    .RespDepth (SsrMuxRespDepth),
    // TODO(zarubaf): USer type
    .tcdm_req_t (tcdm_req_t),
    .tcdm_rsp_t (tcdm_rsp_t),
    .user_t (tcdm_user_t)
  ) i_tcdm_mux (
    .clk_i,
    .rst_ni,
    .slv_req_i({core_tcdm_req, tcdm_req}),
    .slv_rsp_o({core_tcdm_rsp, tcdm_rsp}),
    .mst_req_o(tcdm_req_o[0]),
    .mst_rsp_i(tcdm_rsp_i[0])
  );

  end else begin : gen_no_ssrs
    // Connect single TCDM port
    assign tcdm_req_o[0] = core_tcdm_req;
    assign core_tcdm_rsp = tcdm_rsp_i[0];
    // Tie off SSR insruction stream
    assign ssr_qready     = '0;
    assign ssr_cfg_rsp    = '0;
    assign ssr_pvalid     = '0;
    assign cfg_req        = '0;
    assign cfg_req_valid  = '0;
    // Tie off SSR data stream
    assign ssr_rdata      = '0;
    assign ssr_rready     = '0;
    assign ssr_wready     = '0;
  end

  // --------------------------
  // Tracer
  // --------------------------
  // pragma translate_off
  int f;
  string fn;
  logic [63:0] cycle = 0;
  initial begin
    // We need to schedule the assignment into a safe region, otherwise
    // `hart_id_i` won't have a value assigned at the beginning of the first
    // delta cycle.
    /* verilator lint_off STMTDLY */
    #0;
    /* verilator lint_on STMTDLY */
    $system("mkdir logs -p");
    $sformat(fn, "logs/trace_hart_%05x.dasm", hart_id_i);
    f = $fopen(fn, "w");
    $display("[Tracer] Logging Hart %d to %s", hart_id_i, fn);
  end

  // verilog_lint: waive-start always-ff-non-blocking
  always_ff @(posedge clk_i) begin
      automatic string trace_entry;
      automatic string extras_str;
      automatic snitch_pkg::snitch_trace_port_t extras_snitch;
      automatic snitch_pkg::fpu_trace_port_t extras_fpu;
      automatic snitch_pkg::fpu_sequencer_trace_port_t extras_fpu_seq_out;

      if (rst_ni) begin
        extras_snitch = '{
          // State
          source:       snitch_pkg::SrcSnitch,
          stall:        i_snitch.stall,
          // Decoding
          rs1:          i_snitch.rs1,
          rs2:          i_snitch.rs2,
          rd:           i_snitch.rd,
          is_load:      i_snitch.is_load,
          is_store:     i_snitch.is_store,
          is_branch:    i_snitch.is_branch,
          pc_d:         i_snitch.pc_d,
          // Operands
          opa:          i_snitch.opa,
          opb:          i_snitch.opb,
          opa_select:   i_snitch.opa_select,
          opb_select:   i_snitch.opb_select,
          write_rd:     i_snitch.write_rd,
          csr_addr:     i_snitch.inst_data_i[31:20],
          // Pipeline writeback
          writeback:    i_snitch.alu_writeback,
          // Load/Store
          gpr_rdata_1:  i_snitch.gpr_rdata[1],
          ls_size:      i_snitch.ls_size,
          ld_result_32: i_snitch.ld_result[31:0],
          lsu_rd:       i_snitch.lsu_rd,
          retire_load:  i_snitch.retire_load,
          alu_result:   i_snitch.alu_result,
          // Atomics
          ls_amo:       i_snitch.ls_amo,
          // Accumulator
          retire_acc:   i_snitch.retire_acc,
          acc_pid:      i_snitch.acc_qreq_o.id,
          acc_pdata_32: i_snitch.acc_qreq_o.data_op[31:0],
          // FPU offload
          fpu_offload:
            (i_snitch.acc_qready_i && i_snitch.acc_qvalid_o && i_snitch.acc_qreq_o.addr == 0),
          is_seq_insn:  (i_snitch.inst_data_i inside {riscv_instr::FREP_I, riscv_instr::FREP_O})
        };

        if (FPEn) begin
          extras_fpu = fpu_trace;
          if (Xfrep) begin
            // Addenda to FPU extras iff popping sequencer
            extras_fpu_seq_out = fpu_sequencer_trace;
        end

        cycle++;
        // Trace snitch iff:
        // we are not stalled <==> we have issued and processed an instruction (including offloads)
        // OR we are retiring (issuing a writeback from) a load or accelerator instruction
        if (
            !i_snitch.stall || i_snitch.retire_load || i_snitch.retire_acc
        ) begin
          $sformat(trace_entry, "%t %1d %8d 0x%h DASM(%h) #; %s\n",
              $time, cycle, i_snitch.priv_lvl_q, i_snitch.pc_q, i_snitch.inst_data_i,
              snitch_pkg::print_snitch_trace(extras_snitch));
          $fwrite(f, trace_entry);
        end
        if (FPEn) begin
          // Trace FPU iff:
          // an incoming handshake on the accelerator bus occurs <==> an instruction was issued
          // OR an FPU result is ready to be written back to an FPR register or the bus
          // OR an LSU result is ready to be written back to an FPR register or the bus
          // OR an FPU result, LSU result or bus value is ready to be written back to an FPR register
          if (extras_fpu.acc_q_hs || extras_fpu.fpu_out_hs
          || extras_fpu.lsu_q_hs || extras_fpu.fpr_we) begin
            $sformat(trace_entry, "%t %1d %8d 0x%h DASM(%h) #; %s\n",
                $time, cycle, i_snitch.priv_lvl_q, 32'hz, extras_fpu.op_in,
                snitch_pkg::print_fpu_trace(extras_fpu));
            $fwrite(f, trace_entry);
          end
          // sequencer instructions
          if (Xfrep) begin
            if (extras_fpu_seq_out.cbuf_push) begin
              $sformat(trace_entry, "%t %1d %8d 0x%h DASM(%h) #; %s\n",
                  $time, cycle, i_snitch.priv_lvl_q, 32'hz, 64'hz,
                  snitch_pkg::print_fpu_sequencer_trace(extras_fpu_seq_out));
              $fwrite(f, trace_entry);
            end
          end
        end
      end else begin
        cycle = '0;
      end
    end
  end

  final begin
    $fclose(f);
  end
  // verilog_lint: waive-stop always-ff-non-blocking
  // pragma translate_on

  `ASSERT_INIT(BootAddrAligned, BootAddr[1:0] == 2'b00)

endmodule
