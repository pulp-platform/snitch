// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Snitch Core Complex (CC)
// Contains the Snitch Integer Core + floating point unit

/// Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>
module snitch_cc #(
  parameter logic [31:0] BootAddr           = 32'h0000_1000,
  parameter bit          RVE                = 0,       // Reduced-register extension
  parameter bit          RVFD               = 1,       // Enable F and D Extension
  parameter bit          SDMA               = 0,       // Enable Snitch DMA
  /// Add isochronous clock-domain crossings e.g., make it possible to operate the core in a slower clock domain.
  parameter bit          IsoCrossing        = 1,
  parameter bit          FPUSequencer       = 1,
  parameter bit          Xssr               = 1,
  parameter bit          Xipu               = 1,
  /// Insert Pipeline registers into off-loading path (request)
  parameter bit          RegisterOffload    = 1,
  /// Insert Pipeline registers into off-loading path (response)
  parameter bit          RegisterOffloadRsp = 0,
  /// Insert Pipeline registers into data memory request path
  parameter bit          RegisterTCDMReq    = 1,
  /// Insert Pipeline registers after sequencer
  parameter bit          RegisterSequencer  = 0
) (
  input  logic               clk_i,
  input  logic               clk_d2_i,
  input  logic               rst_i,
  input  logic               rst_int_ss_ni,
  input  logic               rst_fp_ss_ni,
  input  logic [31:0]        hart_id_i,
  input  logic               debug_req_i,
  output logic               flush_i_valid_o,
  input  logic               flush_i_ready_i,
  input  logic               meip_i,
  input  logic               mtip_i,
  input  logic               msip_i,
  // Instruction Port (Potentially in slower clock-domain)
  output snitch_pkg::addr_t  inst_addr_o,
  output logic               inst_cacheable_o,
  input  logic [31:0]        inst_data_i,
  output logic               inst_valid_o,
  input  logic               inst_ready_i,
  // TCDM Ports
  output snitch_pkg::addr_t   [2:0] data_qaddr_o,
  output logic                [2:0] data_qwrite_o,
  output snitch_pkg::amo_op_t [2:0] data_qamo_o,
  output snitch_pkg::data_t   [2:0] data_qdata_o,
  output snitch_pkg::size_t   [2:0] data_qsize_o,
  output snitch_pkg::strb_t   [2:0] data_qstrb_o,
  output logic                [2:0] data_qvalid_o,
  input  logic                [2:0] data_qready_i,
  input  snitch_pkg::data_t   [2:0] data_pdata_i,
  input  logic                [2:0] data_perror_i,
  input  logic                [2:0] data_pvalid_i,
  output logic                [2:0] data_pready_o,
  input  logic                      wake_up_sync_i,
  // Accelerator Off-load port
  output snitch_pkg::acc_req_t  acc_req_o,
  output logic                  acc_qvalid_o,
  input  logic                  acc_qready_i,
  input  snitch_pkg::acc_resp_t acc_resp_i,
  input  logic                  acc_pvalid_i,
  output logic                  acc_pready_o,
  // Address Translation Interface.
  output logic                [1:0] ptw_valid_o,
  input  logic                [1:0] ptw_ready_i,
  output snitch_pkg::va_t     [1:0] ptw_va_o,
  output snitch_pkg::pa_t     [1:0] ptw_ppn_o,
  input  snitch_pkg::l0_pte_t [1:0] ptw_pte_i,
  input  logic                [1:0] ptw_is_4mega_i,
  // DMA ports
  output snitch_axi_pkg::req_dma_t   axi_dma_req_o,
  input  snitch_axi_pkg::resp_dma_t  axi_dma_res_i,
  output logic                       axi_dma_busy_o,
  output axi_dma_pkg::dma_perf_t     axi_dma_perf_o,
  // Core event strobes
  output snitch_pkg::core_events_t core_events_o
);

  snitch_pkg::acc_req_t acc_snitch_req;
  snitch_pkg::acc_req_t acc_snitch_demux;
  snitch_pkg::acc_req_t acc_snitch_demux_q;
  snitch_pkg::acc_resp_t acc_seq;
  snitch_pkg::acc_resp_t acc_demux_snitch;
  snitch_pkg::acc_resp_t acc_demux_snitch_q;
  snitch_pkg::acc_resp_t dma_resp;
  snitch_pkg::acc_resp_t ipu_resp;

  logic acc_snitch_demux_qvalid, acc_snitch_demux_qready;
  logic acc_snitch_demux_qvalid_q, acc_snitch_demux_qready_q;
  logic acc_qvalid, acc_qready;
  logic dma_qvalid, dma_qready;
  logic ipu_qvalid, ipu_qready;

  logic acc_pvalid, acc_pready;
  logic dma_pvalid, dma_pready;
  logic ipu_pvalid, ipu_pready;
  logic acc_demux_snitch_valid, acc_demux_snitch_ready;
  logic acc_demux_snitch_valid_q, acc_demux_snitch_ready_q;

  fpnew_pkg::roundmode_e fpu_rnd_mode;
  fpnew_pkg::status_t    fpu_status;

  snitch_pkg::dreq_t data_req [3];
  logic     data_req_valid    [3];
  logic     data_req_ready    [3];

  snitch_pkg::dreq_t data_req_q [3];
  logic     data_req_valid_q    [3];
  logic     data_req_ready_q    [3];

  snitch_pkg::dresp_t [2:0] data_pdata_q;
  logic [2:0] data_pvalid_q;
  logic [2:0] data_pready_q;
  // Internal signals
  snitch_pkg::dreq_t  snitch_data_req, snitch_data_req_mux, snitch_data_req_mux_q;
  snitch_pkg::dresp_t snitch_data_resp, snitch_data_resp_mux, snitch_data_resp_mux_q;
  logic snitch_data_req_valid, snitch_data_req_ready;
  logic snitch_data_resp_valid, snitch_data_resp_ready;
  logic snitch_data_req_mux_valid, snitch_data_req_mux_ready;
  logic snitch_data_req_mux_valid_q, snitch_data_req_mux_ready_q;
  logic snitch_data_resp_mux_valid, snitch_data_resp_mux_ready;
  logic snitch_data_resp_mux_valid_q, snitch_data_resp_mux_ready_q;
  // SSRs
  snitch_pkg::dreq_t  ssr_data_req;
  snitch_pkg::dresp_t ssr_data_resp;
  logic ssr_data_req_valid, ssr_data_req_ready;
  logic ssr_data_resp_valid, ssr_data_resp_ready;

  snitch_pkg::dreq_t fp_data_req [3];
  logic     fp_data_req_valid [3];
  logic     fp_data_req_ready [3];

  snitch_pkg::dresp_t fp_data_resp [3];
  logic      fp_data_resp_valid [3];
  logic      fp_data_resp_ready [3];

  for (genvar i = 0; i < 3; i++) begin : gen_spill_register
    spill_register  #(
      .T      ( snitch_pkg::dreq_t    ),
      .Bypass ( !RegisterTCDMReq  || i == 0 ) // Bypass path 0
    ) i_spill_register_tcdm_req (
      .clk_i                           ,
      .rst_ni  ( ~rst_i               ),
      .valid_i ( data_req_valid   [i] ),
      .ready_o ( data_req_ready   [i] ),
      .data_i  ( data_req         [i] ),
      .valid_o ( data_req_valid_q [i] ),
      .ready_i ( data_req_ready_q [i] ),
      .data_o  ( data_req_q       [i] )
    );
  end

  for (genvar i = 0; i < 3; i++) begin : gen_explode_struct
    assign data_qaddr_o     [i] = data_req_q[i].addr;
    assign data_qwrite_o    [i] = data_req_q[i].write;
    assign data_qamo_o      [i] = data_req_q[i].amo;
    assign data_qdata_o     [i] = data_req_q[i].data;
    assign data_qsize_o     [i] = data_req_q[i].size;
    assign data_qstrb_o     [i] = data_req_q[i].strb;
    assign data_qvalid_o    [i] = data_req_valid_q[i];
    assign data_req_ready_q [i] = data_qready_i[i];
  end

  // Snitch Integer Core
  snitch #(
    .BootAddr ( BootAddr ),
    .RVE      ( RVE      ),
    .SDMA     ( SDMA     ),
    .RVFD     ( RVFD     )
  ) i_snitch (
    .clk_i            ( clk_d2_i                   ), // if necessary operate on half the frequency
    .rst_i                                          ,
    .hart_id_i                                      ,
    .debug_req_i                                    ,
    .flush_i_valid_o                                ,
    .flush_i_ready_i                                ,
    .meip_i                                         ,
    .mtip_i                                         ,
    .msip_i                                         ,
    .inst_addr_o                                    ,
    .inst_cacheable_o                               ,
    .inst_data_i                                    ,
    .inst_valid_o                                   ,
    .inst_ready_i                                   ,
    .acc_qaddr_o      ( acc_snitch_demux.addr      ),
    .acc_qid_o        ( acc_snitch_demux.id        ),
    .acc_qdata_op_o   ( acc_snitch_demux.data_op   ),
    .acc_qdata_arga_o ( acc_snitch_demux.data_arga ),
    .acc_qdata_argb_o ( acc_snitch_demux.data_argb ),
    .acc_qdata_argc_o ( acc_snitch_demux.data_argc ),
    .acc_qvalid_o     ( acc_snitch_demux_qvalid    ),
    .acc_qready_i     ( acc_snitch_demux_qready    ),
    .acc_pdata_i      ( acc_demux_snitch.data      ),
    .acc_pid_i        ( acc_demux_snitch.id        ),
    .acc_perror_i     ( acc_demux_snitch.error     ),
    .acc_pvalid_i     ( acc_demux_snitch_valid     ),
    .acc_pready_o     ( acc_demux_snitch_ready     ),
    .data_qaddr_o     ( snitch_data_req_mux.addr   ),
    .data_qwrite_o    ( snitch_data_req_mux.write  ),
    .data_qamo_o      ( snitch_data_req_mux.amo    ),
    .data_qdata_o     ( snitch_data_req_mux.data   ),
    .data_qstrb_o     ( snitch_data_req_mux.strb   ),
    .data_qsize_o     ( snitch_data_req_mux.size   ),
    .data_qvalid_o    ( snitch_data_req_mux_valid  ),
    .data_qready_i    ( snitch_data_req_mux_ready  ),
    .data_pdata_i     ( snitch_data_resp_mux_q.data  ),
    .data_perror_i    ( snitch_data_resp_mux_q.error ),
    .data_pvalid_i    ( snitch_data_resp_mux_valid_q ),
    .data_pready_o    ( snitch_data_resp_mux_ready_q ),
    .ptw_valid_o,
    .ptw_ready_i,
    .ptw_va_o,
    .ptw_ppn_o,
    .ptw_pte_i,
    .ptw_is_4mega_i,
    .wake_up_sync_i,
    .fpu_rnd_mode_o   ( fpu_rnd_mode               ),
    .fpu_status_i     ( fpu_status                 )
  );

  // Cut data request path
  isochronous_spill_register  #(
    .T      ( snitch_pkg::dreq_t  ),
    .Bypass ( 1'b0                )
  ) i_spill_register_snitch_lsu_req (
    .src_clk_i   ( clk_d2_i                  ),
    .src_rst_ni  ( ~rst_i                    ),
    .src_valid_i ( snitch_data_req_mux_valid   ),
    .src_ready_o ( snitch_data_req_mux_ready   ),
    .src_data_i  ( snitch_data_req_mux         ),
    .dst_clk_i   ( clk_i                     ),
    .dst_rst_ni  ( ~rst_i                    ),
    .dst_valid_o ( snitch_data_req_mux_valid_q ),
    .dst_ready_i ( snitch_data_req_mux_ready_q ),
    .dst_data_o  ( snitch_data_req_mux_q       )
  );

  // Cut data response path
  isochronous_spill_register #(
    .T      ( snitch_pkg::dresp_t ),
    .Bypass ( !IsoCrossing        )
  ) i_spill_register_snitch_lsu_resp (
    .src_clk_i   ( clk_i                        ),
    .src_rst_ni  ( ~rst_i                       ),
    .src_valid_i ( snitch_data_resp_mux_valid   ),
    .src_ready_o ( snitch_data_resp_mux_ready   ),
    .src_data_i  ( snitch_data_resp_mux         ),
    .dst_clk_i   ( clk_d2_i                     ),
    .dst_rst_ni  ( ~rst_i                       ),
    .dst_valid_o ( snitch_data_resp_mux_valid_q ),
    .dst_ready_i ( snitch_data_resp_mux_ready_q ),
    .dst_data_o  ( snitch_data_resp_mux_q       )
  );

  // Cut off-loading request path
  isochronous_spill_register #(
    .T      ( snitch_pkg::acc_req_t ),
    .Bypass ( 1'b0                  )
  ) i_spill_register_acc_demux_req (
    .src_clk_i   ( clk_d2_i                  ),
    .src_rst_ni  ( ~rst_i                    ),
    .src_valid_i ( acc_snitch_demux_qvalid   ),
    .src_ready_o ( acc_snitch_demux_qready   ),
    .src_data_i  ( acc_snitch_demux          ),
    .dst_clk_i   ( clk_i                     ),
    .dst_rst_ni  ( ~rst_i                    ),
    .dst_valid_o ( acc_snitch_demux_qvalid_q ),
    .dst_ready_i ( acc_snitch_demux_qready_q ),
    .dst_data_o  ( acc_snitch_demux_q        )
  );

  // Cut off-loading response path
  isochronous_spill_register #(
    .T      ( snitch_pkg::acc_resp_t              ),
    .Bypass ( !RegisterOffloadRsp && !IsoCrossing )
  ) i_spill_register_acc_demux_resp (
    .src_clk_i   ( clk_i                    ),
    .src_rst_ni  ( ~rst_i                   ),
    .src_valid_i ( acc_demux_snitch_valid_q ),
    .src_ready_o ( acc_demux_snitch_ready_q ),
    .src_data_i  ( acc_demux_snitch_q       ),
    .dst_clk_i   ( clk_d2_i                 ),
    .dst_rst_ni  ( ~rst_i                   ),
    .dst_valid_o ( acc_demux_snitch_valid   ),
    .dst_ready_i ( acc_demux_snitch_ready   ),
    .dst_data_o  ( acc_demux_snitch         )
  );

  // Accelerator Demux Port
  stream_demux #(
    .N_OUP ( 4 )
  ) i_stream_demux_offload (
    .inp_valid_i  ( acc_snitch_demux_qvalid_q  ),
    .inp_ready_o  ( acc_snitch_demux_qready_q  ),
    .oup_sel_i    ( acc_snitch_demux_q.addr[$clog2(4)-1:0]             ),
    .oup_valid_o  ( {ipu_qvalid, dma_qvalid, acc_qvalid_o, acc_qvalid} ),
    .oup_ready_i  ( {ipu_qready, dma_qready, acc_qready_i, acc_qready} )
  );

  // To shared muldiv
  assign acc_req_o = acc_snitch_demux_q;
  assign acc_snitch_req = acc_snitch_demux_q;

  stream_arbiter #(
    .DATA_T      ( snitch_pkg::acc_resp_t      ),
    .N_INP       ( 4                           ),
    .ARBITER     ( "rr"                        )
  ) i_stream_arbiter_offload (
    .clk_i       ( clk_i                                   ),
    .rst_ni      ( ~rst_i                                  ),
    .inp_data_i  ( {ipu_resp,   dma_resp,   acc_resp_i,   acc_seq    } ),
    .inp_valid_i ( {ipu_pvalid, dma_pvalid, acc_pvalid_i, acc_pvalid } ),
    .inp_ready_o ( {ipu_pready, dma_pready, acc_pready_o, acc_pready } ),
    .oup_data_o  ( acc_demux_snitch_q                      ),
    .oup_valid_o ( acc_demux_snitch_valid_q                ),
    .oup_ready_i ( acc_demux_snitch_ready_q                )
  );

  if (SDMA) begin : gen_dma
    axi_dma_tc_snitch_fe #(
      .axi_req_t    ( snitch_axi_pkg::req_dma_t     ),
      .axi_res_t    ( snitch_axi_pkg::resp_dma_t     )
    ) i_axi_dma_tc_snitch_fe (
      .clk_i            ( clk_i                     ),
      .rst_ni           ( ~rst_i                    ),
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
    snitch_int_ss i_snitch_int_ss (
      .clk_i            ( clk_i                    ),
      .rst_i            ( rst_i | (~rst_int_ss_ni) ),
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

  end

  // pragma translate_off
  snitch_pkg::fpu_trace_port_t fpu_trace;
  snitch_pkg::fpu_sequencer_trace_port_t fpu_sequencer_trace;
  // pragma translate_on

  logic              [2:0][4:0] ssr_raddr;
  snitch_pkg::data_t [2:0]      ssr_rdata;
  logic              [2:0]      ssr_rvalid;
  logic              [2:0]      ssr_rready;
  logic              [2:0]      ssr_rdone;
  logic              [0:0][4:0] ssr_waddr;
  snitch_pkg::data_t [0:0]      ssr_wdata;
  logic              [0:0]      ssr_wvalid;
  logic              [0:0]      ssr_wready;
  logic              [0:0]      ssr_wdone;

  logic [6:0]  cfg_word;
  logic        cfg_write;
  logic [31:0] cfg_wdata;
  logic [31:0] cfg_rdata;

  if (RVFD) begin : gen_fpu
    snitch_pkg::core_events_t fp_ss_core_events;

    snitch_addr_demux #(
      .NrOutput            ( 2                   ),
      .AddressWidth        ( snitch_pkg::PLEN    ),
      .DefaultSlave        ( 0                   ),
      .NrRules             ( 1                   ),
      .MaxOutStandingReads ( 4                   ),
      .req_t               ( snitch_pkg::dreq_t  ),
      .resp_t              ( snitch_pkg::dresp_t )
    ) i_snitch_addr_demux (
      .clk_i,
      .rst_ni         ( ~rst_i                      ),
      .req_addr_i     ( snitch_data_req_mux_q.addr  ),
      .req_write_i    ( snitch_data_req_mux_q.write ),
      .req_payload_i  ( snitch_data_req_mux_q       ),
      .req_valid_i    ( snitch_data_req_mux_valid_q ),
      .req_ready_o    ( snitch_data_req_mux_ready_q ),
      .resp_payload_o ( snitch_data_resp_mux        ),
      .resp_valid_o   ( snitch_data_resp_mux_valid  ),
      .resp_ready_i   ( snitch_data_resp_mux_ready  ),
      .req_payload_o  ( {ssr_data_req,        snitch_data_req}        ),
      .req_valid_o    ( {ssr_data_req_valid,  snitch_data_req_valid}  ),
      .req_ready_i    ( {ssr_data_req_ready,  snitch_data_req_ready}  ),
      .resp_payload_i ( {ssr_data_resp,       snitch_data_resp}       ),
      .resp_valid_i   ( {ssr_data_resp_valid, snitch_data_resp_valid} ),
      .resp_ready_o   ( {ssr_data_resp_ready, snitch_data_resp_ready} ),
      .addr_base_i    ( { snitch_pkg::SSR_ADDR_BASE } ),
      .addr_mask_i    ( { snitch_pkg::SSR_ADDR_MASK } ),
      .addr_slave_i   ( { 1'b1                      } )
    );

    // protocol conversion
    logic ssr_full, ssr_empty;
    logic [31:0] ssr_cfg_rdata;

    assign ssr_data_req_ready = ~ssr_full;

    assign ssr_data_resp.error = 1'b0;
    assign ssr_data_resp.data = ssr_cfg_rdata[31:0]; // shift down
    assign ssr_data_resp_valid = ~ssr_empty;

    assign cfg_word = ssr_data_req.addr >> 3; // convert to 8 byte word addresses
    assign cfg_wdata = ssr_data_req.data;
    assign cfg_write = ssr_data_req.write & ssr_data_req_valid;

    fifo_v3 #(
      .DATA_WIDTH ( 32 ),
      .DEPTH      ( 1  )
    ) i_fifo_ssr (
      .clk_i,
      .rst_ni     ( ~rst_i                                                        ),
      .flush_i    ( 1'b0                                                          ),
      .testmode_i ( 1'b0                                                          ),
      .full_o     ( ssr_full                                                      ),
      .empty_o    ( ssr_empty                                                     ),
      .usage_o    (                                                               ),
      .data_i     ( cfg_rdata                                                     ),
      .push_i     ( ssr_data_req_valid & ssr_data_req_ready & ~ssr_data_req.write ),
      .data_o     ( ssr_cfg_rdata                                                 ),
      .pop_i      ( ssr_data_resp_valid & ssr_data_resp_ready                     )
    );

    snitch_fp_ss #(
      .RegisterSequencer ( RegisterSequencer ),
      .FPUSequencer      ( FPUSequencer      ),
      .Xssr              ( Xssr              )
    ) i_snitch_fp_ss (
      .clk_i,
      .rst_i            ( rst_i | (~rst_fp_ss_ni)   ),
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
      .data_qaddr_o     ( fp_data_req[0].addr   ),
      .data_qwrite_o    ( fp_data_req[0].write  ),
      .data_qdata_o     ( fp_data_req[0].data   ),
      .data_qsize_o     ( fp_data_req[0].size   ),
      .data_qstrb_o     ( fp_data_req[0].strb   ),
      .data_qvalid_o    ( fp_data_req_valid[0]  ),
      .data_qready_i    ( fp_data_req_ready[0]  ),
      .data_pdata_i     ( fp_data_resp[0].data  ),
      .data_perror_i    ( fp_data_resp[0].error ),
      .data_pvalid_i    ( fp_data_resp_valid[0] ),
      .data_pready_o    ( fp_data_resp_ready[0] ),
      .fpu_rnd_mode_i   ( fpu_rnd_mode          ),
      .fpu_status_o     ( fpu_status            ),
      .ssr_raddr_o      ( ssr_raddr             ),
      .ssr_rdata_i      ( ssr_rdata             ),
      .ssr_rvalid_o     ( ssr_rvalid            ),
      .ssr_rready_i     ( ssr_rready            ),
      .ssr_rdone_o      ( ssr_rdone             ),
      .ssr_waddr_o      ( ssr_waddr             ),
      .ssr_wdata_o      ( ssr_wdata             ),
      .ssr_wvalid_o     ( ssr_wvalid            ),
      .ssr_wready_i     ( ssr_wready            ),
      .ssr_wdone_o      ( ssr_wdone             ),
      .core_events_o
    );
    // the floating point unit can't issue atomics
    assign fp_data_req[0].amo = snitch_pkg::AMONone;

  end else begin : gen_no_fpu
    assign fpu_status = '0;

    assign ssr_raddr = '0;
    assign ssr_rvalid = '0;
    assign ssr_rdone = '0;
    assign ssr_waddr = '0;
    assign ssr_wdata = '0;
    assign ssr_wvalid = '0;
    assign ssr_wdone = '0;

    assign cfg_word = '0;
    assign cfg_wdata = '0;
    assign cfg_write = '0;

    assign fp_data_req[0] = '0;
    assign fp_data_req_valid[0] = '0;
    assign fp_data_resp_ready[0] = '0;

    assign acc_qready    = '0;
    assign acc_seq.data  = '0;
    assign acc_seq.id    = '0;
    assign acc_seq.error = '0;
    assign acc_pvalid    = '0;

    assign snitch_data_req = snitch_data_req_mux_q;
    assign snitch_data_req_valid = snitch_data_req_mux_valid_q;
    assign snitch_data_req_mux_ready_q = snitch_data_req_ready;

    assign snitch_data_resp_mux = snitch_data_resp;
    assign snitch_data_resp_mux_valid = snitch_data_resp_valid;
    assign snitch_data_resp_ready = snitch_data_resp_mux_ready;

    assign core_events_o = '0;
  end

  snitch_pkg::dreq_t ssr_req;
  snitch_pkg::dresp_t ssr_resp;
  logic ssr_req_valid, ssr_req_ready;
  logic ssr_resp_valid, ssr_resp_ready;

  // ----
  // SSRs
  // ----
  if (Xssr) begin : gen_ssrs
    snitch_ssr_streamer i_snitch_ssr_streamer (
      .clk_i,
      .rst_ni         ( ~rst_i     ),
      .cfg_word_i     ( cfg_word   ),
      .cfg_write_i    ( cfg_write  ),
      .cfg_rdata_o    ( cfg_rdata  ),
      .cfg_wdata_i    ( cfg_wdata  ),

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

      .mem_qaddr_o    ( {fp_data_req[2].addr,   fp_data_req[1].addr,   ssr_req.addr}   ),
      .mem_qwrite_o   ( {fp_data_req[2].write,  fp_data_req[1].write,  ssr_req.write}  ),
      .mem_qstrb_o    ( {fp_data_req[2].strb,   fp_data_req[1].strb,   ssr_req.strb}   ),
      .mem_qdata_o    ( {fp_data_req[2].data,   fp_data_req[1].data,   ssr_req.data}   ),
      .mem_qvalid_o   ( {fp_data_req_valid[2],  fp_data_req_valid[1],  ssr_req_valid}  ),
      .mem_qready_i   ( {fp_data_req_ready[2],  fp_data_req_ready[1],  ssr_req_ready}  ),
      .mem_pvalid_i   ( {fp_data_resp_valid[2], fp_data_resp_valid[1], ssr_resp_valid} ),
      .mem_pready_o   ( {fp_data_resp_ready[2], fp_data_resp_ready[1], ssr_resp_ready} ),
      .mem_pdata_i    ( {fp_data_resp[2].data,  fp_data_resp[1].data,  ssr_resp.data}  ),
      .mem_perror_i   ( {fp_data_resp[2].error, fp_data_resp[1].error, ssr_resp.error} )
    );
    assign fp_data_req[1].size = snitch_pkg::DATA_ALIGN[1:0];
    assign fp_data_req[2].size = snitch_pkg::DATA_ALIGN[1:0];
    assign fp_data_req[1].amo = snitch_pkg::AMONone;
    assign fp_data_req[2].amo = snitch_pkg::AMONone;
    assign ssr_req.amo = snitch_pkg::AMONone;
    assign ssr_req.size = snitch_pkg::DATA_ALIGN[1:0];
  end else begin : gen_no_ssrs
    assign ssr_req = '0;
    assign fp_data_req[1] = '0;
    assign fp_data_req[2] = '0;
    assign fp_data_req_valid[1] = '0;
    assign fp_data_req_valid[2] = '0;
    assign ssr_req_valid = '0;
    assign fp_data_resp_ready[1] = '0;
    assign fp_data_resp_ready[2] = '0;
    assign ssr_resp_ready = '0;
  end


  // -----------------------------------
  // Priority Arbitrate Request Port O
  // -----------------------------------
  snitch_pkg::dresp_t demux_in;
  assign demux_in = data_pdata_q[0];

  // Arbitrate between SSRs, FP data and integer data.
  snitch_demux #(
    .NrPorts        ( 3                    ),
    .req_t          ( snitch_pkg::dreq_t   ),
    .resp_t         ( snitch_pkg::dresp_t  ),
    .RespDepth      ( 4                    ),
    .Arbiter        ( "rr"                 ), // TODO(zarubaf): Set to prio
    .RegisterReq    ( 3'b010               )
  ) i_snitch_demux (
    .clk_i,
    .rst_ni         ( ~rst_i                                          ),
    .req_payload_i  ( {ssr_req,       fp_data_req[0],       snitch_data_req}         ),
    .req_valid_i    ( {ssr_req_valid, fp_data_req_valid[0], snitch_data_req_valid}   ),
    .req_ready_o    ( {ssr_req_ready, fp_data_req_ready[0], snitch_data_req_ready}   ),

    .resp_payload_o ( {ssr_resp,       fp_data_resp[0],       snitch_data_resp}       ),
    .resp_valid_o   ( {ssr_resp_valid, fp_data_resp_valid[0], snitch_data_resp_valid} ),
    .resp_ready_i   ( {ssr_resp_ready, fp_data_resp_ready[0], snitch_data_resp_ready} ),
    .resp_last_o    ( /* not used */                                                  ),

    .req_payload_o  ( data_req[0]                                     ),
    .req_valid_o    ( data_req_valid[0]                               ),
    .req_ready_i    ( data_req_ready[0]                               ),

    .resp_payload_i ( demux_in                                        ),
    .resp_last_i    ( 1'b1                                            ),
    .resp_valid_i   ( data_pvalid_q[0]                                ),
    .resp_ready_o   ( data_pready_q[0]                                )
  );

  // Port 1/2: Dedicated to SSR
  for (genvar i = 1; i < 3; i++) begin : gen_port_connections
    assign data_req[i]           = fp_data_req[i];
    assign data_req_valid[i]     = fp_data_req_valid[i];
    assign fp_data_req_ready[i]  = data_req_ready[i];

    assign data_pready_q[i]      = fp_data_resp_ready[i];
    assign fp_data_resp[i]       = data_pdata_q[i];
    assign fp_data_resp_valid[i] = data_pvalid_q[i];
  end

  // Spill-register on data response port
  for (genvar i = 0; i < 3; i++) begin : gen_resp_spill_reg
    // assignment pattern in port not supported by Synopsys
    snitch_pkg::dresp_t tmp_data_pdata;
    assign tmp_data_pdata = '{error: data_perror_i[i], data: data_pdata_i[i]};

    spill_register #(
      .T (snitch_pkg::dresp_t),
      .Bypass (1'b0)
    ) i_spill_register_data_resp (
      .clk_i                           ,
      .rst_ni  ( ~rst_i               ),
      .valid_i ( data_pvalid_i    [i] ),
      .ready_o ( data_pready_o    [i] ),
      .data_i  ( tmp_data_pdata       ),
      .valid_o ( data_pvalid_q [i]    ),
      .ready_i ( data_pready_q [i]    ),
      .data_o  ( data_pdata_q  [i]    )
    );
  end

  // --------------------------
  // Tracer
  // --------------------------
  // pragma translate_off
  // verilog_lint: waive-start always-ff-non-blocking
  `ifndef VERILATOR
  int f;
  string fn;
  logic [63:0] cycle;

  always_ff @(posedge rst_i) begin
    if (rst_i) begin
      $sformat(fn, "trace_hart_%05x.dasm", hart_id_i);
      f = $fopen(fn, "w");
      $display("[Tracer] Logging Hart %d to %s", hart_id_i, fn);
    end
  end

  typedef enum logic [1:0] {SrcSnitch =  0, SrcFpu = 1, SrcFpuSeq = 2} trace_src_e;

  function static void fmt_extras (
    input longint extras [string],
    output string extras_str
  );
    extras_str = "{";
    foreach(extras[key]) extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, key, extras[key]);
    extras_str = $sformatf("%s}", extras_str);
  endfunction

  always_ff @(posedge clk_i) begin
      automatic string trace_entry;
      automatic string extras_str;
      automatic longint extras_snitch       [string];
      automatic longint extras_fpu          [string];
      automatic longint extras_fpu_seq_in   [string];
      automatic longint extras_fpu_seq_out  [string];

      if (!rst_i) begin
        extras_snitch = '{
          // State
          "source":       SrcSnitch,
          "stall":        i_snitch.stall,
          // Decoding
          "rs1":          i_snitch.rs1,
          "rs2":          i_snitch.rs2,
          "rd":           i_snitch.rd,
          "is_load":      i_snitch.is_load,
          "is_store":     i_snitch.is_store,
          "is_branch":    i_snitch.is_branch,
          "pc_d":         i_snitch.pc_d,
          // Operands
          "opa":          i_snitch.opa,
          "opb":          i_snitch.opb,
          "opa_select":   i_snitch.opa_select,
          "opb_select":   i_snitch.opb_select,
          "write_rd":     i_snitch.write_rd,
          "csr_addr":     i_snitch.inst_data_i[31:20],
          // Pipeline writeback
          "writeback":    i_snitch.alu_writeback,
          // Load/Store
          "gpr_rdata_1":  i_snitch.gpr_rdata[1],
          "ls_size":      i_snitch.ls_size,
          "ld_result_32": i_snitch.ld_result[31:0],
          "lsu_rd":       i_snitch.lsu_rd,
          "retire_load":  i_snitch.retire_load,
          "alu_result":   i_snitch.alu_result,
          // Atomics
          "ls_amo":       i_snitch.ls_amo,
          // Accumulator
          "retire_acc":   i_snitch.retire_acc,
          "acc_pid":      i_snitch.acc_pid_i,
          "acc_pdata_32": i_snitch.acc_pdata_i[31:0],
          // FPU offload
          "fpu_offload":
            (i_snitch.acc_qready_i && i_snitch.acc_qvalid_o && i_snitch.acc_qaddr_o == 0),
          "is_seq_insn":  (i_snitch.inst_data_i ==? riscv_instr::FREP)
        };

        if (RVFD) begin
          extras_fpu = '{
            // State and handshakes
            "source":       SrcFpu,
            "acc_q_hs":     fpu_trace.acc_q_hs,
            "fpu_out_hs":   fpu_trace.fpu_out_hs,
            "lsu_q_hs":     fpu_trace.lsu_q_hs,
            "op_in":        fpu_trace.op_in,
            // Operand addressing
            "rs1":          fpu_trace.rs1,
            "rs2":          fpu_trace.rs2,
            "rs3":          fpu_trace.rs3,
            "rd":           fpu_trace.rd,
            "op_sel_0":     fpu_trace.op_sel_0,
            "op_sel_1":     fpu_trace.op_sel_1,
            "op_sel_2":     fpu_trace.op_sel_2,
            // Operand format
            "src_fmt":      fpu_trace.src_fmt,
            "dst_fmt":      fpu_trace.dst_fmt,
            "int_fmt":      fpu_trace.int_fmt,
            // Operand values
            "acc_qdata_0":  fpu_trace.acc_qdata_0,
            "acc_qdata_1":  fpu_trace.acc_qdata_1,
            "acc_qdata_2":  fpu_trace.acc_qdata_2,
            "op_0":         fpu_trace.op_0,
            "op_1":         fpu_trace.op_1,
            "op_2":         fpu_trace.op_2,
            // FPU
            "use_fpu":      fpu_trace.use_fpu,
            "fpu_in_rd":    fpu_trace.fpu_in_rd,
            "fpu_in_acc":   fpu_trace.fpu_in_acc,
            // Load/Store
            "ls_size":      fpu_trace.ls_size,
            "is_load":      fpu_trace.is_load,
            "is_store":     fpu_trace.is_store,
            "lsu_qaddr":    fpu_trace.lsu_qaddr,
            "lsu_rd":       fpu_trace.lsu_rd,
            // Writeback
            "acc_wb_ready": fpu_trace.acc_wb_ready,
            "fpu_out_acc":  fpu_trace.fpu_out_acc,
            "fpr_waddr":    fpu_trace.fpr_waddr,
            "fpr_wdata":    fpu_trace.fpr_wdata,
            "fpr_we":       fpu_trace.fpr_we
          };

          if (FPUSequencer) begin
            // Addenda to FPU extras iff popping sequencer
            extras_fpu_seq_out = '{
              "source":     SrcFpuSeq,
              "cbuf_push":  fpu_sequencer_trace.cbuf_push,
              "is_outer":   fpu_sequencer_trace.is_outer,
              "max_inst":   fpu_sequencer_trace.max_inst,
              "max_rpt":    fpu_sequencer_trace.max_rpt,
              "stg_max":    fpu_sequencer_trace.stg_max,
              "stg_mask":   fpu_sequencer_trace.stg_mask
            };
          end
        end

        cycle++;
        // Trace snitch iff:
        // we are not stalled <==> we have issued and processed an instruction (including offloads)
        // OR we are retiring (issuing a writeback from) a load or accelerator instruction
        if (
            !i_snitch.stall || i_snitch.retire_load || i_snitch.retire_acc
        ) begin
          fmt_extras(extras_snitch, extras_str);
          $sformat(trace_entry, "%t %1d %8d 0x%h DASM(%h) #; %s\n",
              $time, cycle, i_snitch.priv_lvl_q, i_snitch.pc_q, i_snitch.inst_data_i, extras_str);
          $fwrite(f, trace_entry);
        end
        if (RVFD) begin
          // Trace FPU iff:
          // an incoming handshake on the accelerator bus occurs <==> an instruction was issued
          // OR an FPU result is ready to be written back to an FPR register or the bus
          // OR an LSU result is ready to be written back to an FPR register or the bus
          // OR an FPU result, LSU result or bus value is ready to be written back to an FPR register
          if (extras_fpu["acc_q_hs"] || extras_fpu["fpu_out_hs"]
          || extras_fpu["lsu_q_hs"] || extras_fpu["fpr_we"]) begin
            fmt_extras(extras_fpu, extras_str);
            $sformat(trace_entry, "%t %1d %8d 0x%h DASM(%h) #; %s\n",
                $time, cycle, i_snitch.priv_lvl_q, 32'hz, extras_fpu["op_in"], extras_str);
            $fwrite(f, trace_entry);
          end
          // sequencer instructions
          if (FPUSequencer) begin
            if (extras_fpu_seq_out["cbuf_push"]) begin
              fmt_extras(extras_fpu_seq_out, extras_str);
              $sformat(trace_entry, "%t %1d %8d 0x%h SASM(%h) #; %s\n",
                  $time, cycle, i_snitch.priv_lvl_q, 32'hz, 64'hz, extras_str);
              $fwrite(f, trace_entry);
            end
          end
        end
      end else begin
        cycle = '0;
      end
    end

  final begin
    $fclose(f);
  end
  `endif
  // verilog_lint: waive-stop always-ff-non-blocking
  // pragma translate_on

endmodule
