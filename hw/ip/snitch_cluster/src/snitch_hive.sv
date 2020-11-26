// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

/// Batches up couple of Snitch cores which share an instruction frontend
/// Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>
module snitch_hive #(
  /// Number of cores which share an instruction frontend
  parameter int unsigned CoreCount          = 4,
  parameter int unsigned MaxNumCompCores    = 65536,
  /// Width of a single icache line.
  parameter int unsigned ICacheLineWidth    = CoreCount > 2 ? CoreCount * 32 : 64,
  /// Number of icache lines per set.
  parameter int unsigned ICacheLineCount    = 128,
  /// Number of icache sets.
  parameter int unsigned ICacheSets         = 4,
  /// Address at which execution starts.
  parameter logic [31:0] BootAddr           = 32'h0,
  /// Per-core enabling of the standard `E` ISA reduced-register extension.
  parameter bit [CoreCount-1:0] RVE = '0,
  /// Per-core enabling of the standard `F` and `D` ISA extensions.
  parameter bit [CoreCount-1:0] RVFD = '1,
  /// Per-core enabling of the custom `Xdma` ISA extensions.
  parameter bit [CoreCount-1:0] Xdma = '0,
  /// Per-core enabling of the custom `Xssr` ISA extensions.
  parameter bit [CoreCount-1:0] Xssr = RVFD,
  /// Insert Pipeline registers into off-loading path (request)
  parameter bit          RegisterOffload    = 1,
  /// Insert Pipeline registers into off-loading path (response)
  parameter bit          RegisterOffloadRsp = 0,
  /// Insert Pipeline registers into data memory request path
  parameter bit          RegisterTCDMReq    = 1,
  /// Insert Pipeline registers after sequencer
  parameter bit          RegisterSequencer  = 0,
  parameter bit          IsoCrossing        = 1,
  parameter type         axi_dma_req_t      = logic,
  parameter type         axi_dma_res_t      = logic
) (
  input  logic                       clk_i,
  input  logic                       clk_d2_i, // divide-by-two clock
  input  logic                       rst_i,
  input  logic [31:0]                hart_base_id_i,
  input  logic [CoreCount-1:0]       debug_req_i,
  input  logic [CoreCount-1:0]       meip_i,
  input  logic [CoreCount-1:0]       mtip_i,
  input  logic [CoreCount-1:0]       msip_i,
  // TCDM Ports
  output snitch_pkg::addr_t   [CoreCount-1:0][2:0] data_qaddr_o,
  output logic                [CoreCount-1:0][2:0] data_qwrite_o,
  output snitch_pkg::amo_op_t [CoreCount-1:0][2:0] data_qamo_o,
  output snitch_pkg::data_t   [CoreCount-1:0][2:0] data_qdata_o,
  output snitch_pkg::size_t   [CoreCount-1:0][2:0] data_qsize_o,
  output snitch_pkg::strb_t   [CoreCount-1:0][2:0] data_qstrb_o,
  output logic                [CoreCount-1:0][2:0] data_qvalid_o,
  input  logic                [CoreCount-1:0][2:0] data_qready_i,
  input  snitch_pkg::data_t   [CoreCount-1:0][2:0] data_pdata_i,
  input  logic                [CoreCount-1:0][2:0] data_perror_i,
  input  logic                [CoreCount-1:0][2:0] data_pvalid_i,
  output logic                [CoreCount-1:0][2:0] data_pready_o,
  input  logic                [CoreCount-1:0]      wake_up_sync_i,

  output snitch_pkg::addr_t          ptw_data_qaddr_o,
  output logic                       ptw_data_qvalid_o,
  input  logic                       ptw_data_qready_i,
  input  snitch_pkg::dresp_t         ptw_data_prsp_i,
  input  logic                       ptw_data_pvalid_i,
  output logic                       ptw_data_pready_o,
  // I-Cache refill interface
  output snitch_pkg::addr_t          refill_qaddr_o,
  output logic [7:0]                 refill_qlen_o,
  output logic                       refill_qvalid_o,
  input  logic                       refill_qready_i,
  input  snitch_pkg::data_t          refill_pdata_i,
  input  logic                       refill_perror_i,
  input  logic                       refill_pvalid_i,
  input  logic                       refill_plast_i,
  output logic                       refill_pready_o,

  // DMA ports
  output snitch_axi_pkg::req_dma_t   axi_dma_req_o,
  input  snitch_axi_pkg::resp_dma_t  axi_dma_res_i,
  output logic                       axi_dma_busy_o,
  output axi_dma_pkg::dma_perf_t     axi_dma_perf_o,

  output snitch_pkg::core_events_t [CoreCount-1:0] core_events_o
);
  // Extend the ID to route back results to the appropriate core.
  localparam int unsigned IdWidth = 5;
  localparam int unsigned LogCoreCount = CoreCount > 1 ? $clog2(CoreCount) : 1;
  localparam int unsigned ExtendedIdWidth = IdWidth + LogCoreCount;

  snitch_pkg::addr_t [CoreCount-1:0] inst_addr;
  logic [CoreCount-1:0]              inst_cacheable;
  logic [CoreCount-1:0][31:0]        inst_data;
  logic [CoreCount-1:0]              inst_valid;
  logic [CoreCount-1:0]              inst_ready;
  logic [CoreCount-1:0]              inst_error;

  logic [CoreCount-1:0]       flush_valid;
  logic [CoreCount-1:0]       flush_ready;
  logic flush_ready_ic;

  typedef struct packed {
    logic [31:0]                addr;
    logic [ExtendedIdWidth-1:0] id;
    logic [31:0]                data_op;
    snitch_pkg::data_t          data_arga;
    snitch_pkg::data_t          data_argb;
    snitch_pkg::data_t          data_argc;
  } acc_req_t;

  typedef struct packed {
    logic [ExtendedIdWidth-1:0] id;
    logic                       error;
    snitch_pkg::data_t          data;
  } acc_resp_t;

  snitch_pkg::acc_req_t  [CoreCount-1:0] acc_req;
  acc_req_t              [CoreCount-1:0] acc_req_ext; // extended version
  logic                  [CoreCount-1:0] acc_qvalid;
  logic                  [CoreCount-1:0] acc_qready;
  snitch_pkg::acc_resp_t [CoreCount-1:0] acc_resp;
  logic                  [CoreCount-1:0] acc_pvalid;
  logic                  [CoreCount-1:0] acc_pready;

  logic            [CoreCount-1:0][1:0] ptw_valid;
  logic            [CoreCount-1:0][1:0] ptw_ready;
  snitch_pkg::pa_t [CoreCount-1:0][1:0] ptw_ppn;
  snitch_pkg::va_t [CoreCount-1:0][1:0] ptw_va;
  snitch_pkg::l0_pte_t ptw_pte;
  logic                ptw_is_4mega;

  acc_req_t              acc_req_sfu, acc_req_sfu_q; // to shared functional unit
  logic                  acc_req_sfu_valid, acc_req_sfu_valid_q;
  logic                  acc_req_sfu_ready, acc_req_sfu_ready_q;

  acc_resp_t             acc_resp_sfu; // to shared functional unit
  logic                  acc_resp_sfu_valid;
  logic                  acc_resp_sfu_ready;

  snitch_icache #(
    .NR_FETCH_PORTS    ( CoreCount        ),
    .L0_LINE_COUNT     ( 4                ),
    .LINE_WIDTH        ( ICacheLineWidth  ),
    .LINE_COUNT        ( ICacheLineCount  ),
    .SET_COUNT         ( ICacheSets       ),
    .FETCH_AW          ( snitch_pkg::PLEN ),
    .FETCH_DW          ( 32               ),
    .FILL_AW           ( snitch_pkg::PLEN ),
    .FILL_DW           ( snitch_pkg::DLEN ),
    .EARLY_LATCH        ( 0               ),
    .L0_EARLY_TAG_WIDTH ( snitch_pkg::PAGE_SHIFT - $clog2(ICacheLineWidth/8) ),
    .ISO_CROSSING       ( IsoCrossing     )
  ) i_snitch_icache (
    .clk_i                             ,
    .clk_d2_i                          ,
    .rst_ni          ( ~rst_i         ),
    // TODO: Wire to socregs or similar
    .enable_prefetching_i ( 1'b1 ),
    .icache_events_o      (      ),
    .flush_valid_i   ( |flush_valid   ),
    .flush_ready_o   ( flush_ready_ic ),

    .inst_addr_i      ( inst_addr      ),
    .inst_cacheable_i ( inst_cacheable ),
    .inst_data_o      ( inst_data      ),
    .inst_valid_i     ( inst_valid     ),
    .inst_ready_o     ( inst_ready     ),
    .inst_error_o     ( inst_error     ),

    .refill_qaddr_o,
    .refill_qlen_o,
    .refill_qvalid_o,
    .refill_qready_i,

    .refill_pdata_i,
    .refill_perror_i,
    .refill_pvalid_i,
    .refill_plast_i,
    .refill_pready_o
  );

  assign flush_ready = {{CoreCount}{flush_ready_ic}};

  for (genvar i = 0; i < CoreCount; i++) begin : gen_core
      snitch_axi_pkg::req_dma_t   axi_dma_req;
      snitch_axi_pkg::resp_dma_t  axi_dma_res;
      logic                       axi_dma_busy;
      axi_dma_pkg::dma_perf_t     axi_dma_perf;

      snitch_cc #(
        .BootAddr           ( BootAddr            ),
        .RVE                ( RVE[i]              ),
        .RVFD               ( RVFD[i]             ),
        .SDMA               ( Xdma[i]             ),
        .Xssr               ( Xssr[i]             ),
        .IsoCrossing        ( IsoCrossing         ),
        .RegisterOffload    ( RegisterOffload     ),
        .RegisterOffloadRsp ( RegisterOffloadRsp  ),
        .RegisterTCDMReq    ( RegisterTCDMReq     ),
        .RegisterSequencer  ( RegisterSequencer   )
      ) i_snitch_cc (
        .clk_i                                  ,
        .clk_d2_i                               ,
        .rst_i                                  ,
        // Reset Int subsystems separately, connected via UPF.
        .rst_int_ss_ni    ( 1'b1               ),
        // Reset FP subsystems separately, connected via UPF.
        .rst_fp_ss_ni     ( 1'b1               ),
        .hart_id_i        ( hart_base_id_i + i ),
        .debug_req_i      ( debug_req_i    [i] ),
        .meip_i           ( meip_i         [i] ),
        .mtip_i           ( mtip_i         [i] ),
        .msip_i           ( msip_i         [i] ),
        .flush_i_valid_o  ( flush_valid    [i] ),
        .flush_i_ready_i  ( flush_ready    [i] ),
        .inst_addr_o      ( inst_addr      [i] ),
        .inst_cacheable_o ( inst_cacheable [i] ),
        .inst_data_i      ( inst_data      [i] ),
        .inst_valid_o     ( inst_valid     [i] ),
        .inst_ready_i     ( inst_ready     [i] ),
        .data_qaddr_o     ( data_qaddr_o   [i] ),
        .data_qwrite_o    ( data_qwrite_o  [i] ),
        .data_qamo_o      ( data_qamo_o    [i] ),
        .data_qdata_o     ( data_qdata_o   [i] ),
        .data_qsize_o     ( data_qsize_o   [i] ),
        .data_qstrb_o     ( data_qstrb_o   [i] ),
        .data_qvalid_o    ( data_qvalid_o  [i] ),
        .data_qready_i    ( data_qready_i  [i] ),
        .data_pdata_i     ( data_pdata_i   [i] ),
        .data_perror_i    ( data_perror_i  [i] ),
        .data_pvalid_i    ( data_pvalid_i  [i] ),
        .data_pready_o    ( data_pready_o  [i] ),
        .wake_up_sync_i   ( wake_up_sync_i [i] ),
        .acc_req_o        ( acc_req        [i] ),
        .acc_qvalid_o     ( acc_qvalid     [i] ),
        .acc_qready_i     ( acc_qready     [i] ),
        .acc_resp_i       ( acc_resp       [i] ),
        .acc_pvalid_i     ( acc_pvalid     [i] ),
        .acc_pready_o     ( acc_pready     [i] ),
        .ptw_valid_o      ( ptw_valid      [i] ),
        .ptw_ready_i      ( ptw_ready      [i] ),
        .ptw_va_o         ( ptw_va         [i] ),
        .ptw_ppn_o        ( ptw_ppn        [i] ),
        .ptw_pte_i        ( {ptw_pte, ptw_pte}           ),
        .ptw_is_4mega_i   ( {ptw_is_4mega, ptw_is_4mega} ),
        .core_events_o    ( core_events_o  [i] ),
        .axi_dma_req_o    ( axi_dma_req        ),
        .axi_dma_res_i    ( axi_dma_res        ),
        .axi_dma_busy_o   ( axi_dma_busy       ),
        .axi_dma_perf_o   ( axi_dma_perf       )
      );

    if (Xdma[i]) begin : gen_dma_connection
      assign axi_dma_req_o = axi_dma_req;
      assign axi_dma_res = axi_dma_res_i;
      assign axi_dma_busy_o = axi_dma_busy;
      assign axi_dma_perf_o = axi_dma_perf;
    end else begin : gen_no_dma_connection
      assign axi_dma_res = '0;
    end

    assign acc_req_ext[i].id = {i[LogCoreCount-1:0], acc_req[i].id};
    assign acc_req_ext[i].addr = acc_req[i].addr;
    assign acc_req_ext[i].data_op = acc_req[i].data_op;
    assign acc_req_ext[i].data_arga = acc_req[i].data_arga;
    assign acc_req_ext[i].data_argb = acc_req[i].data_argb;
    assign acc_req_ext[i].data_argc = acc_req[i].data_argc;
  end

  // -------------------
  // Shared VM Subsystem
  // -------------------
  typedef struct packed {
    snitch_pkg::va_t va;
    snitch_pkg::pa_t ppn;
  } va_arb_t;

  va_arb_t [2*CoreCount-1:0] ptw_req_in;
  va_arb_t ptw_req_out;

  // We've two request ports per core for the PTW:
  // instructions and data.
  for (genvar i = 0; i < CoreCount; i++) begin : gen_connect_ptw_core
    for (genvar j = 0; j < 2; j++) begin : gen_connect_ptw_port
      assign ptw_req_in[2*i+j].va = ptw_va[j];
      assign ptw_req_in[2*i+j].ppn = ptw_ppn[j];
    end
  end

  logic ptw_valid_out, ptw_ready_out;

  snitch_pkg::addr_t ptw_req;
  logic ptw_req_valid, ptw_req_ready;
  snitch_pkg::dresp_t ptw_rsp;
  logic ptw_rsp_valid, ptw_rsp_ready;

  /// Multiplex translation requests
  stream_arbiter #(
    .DATA_T ( va_arb_t ),
    .N_INP  ( 2*CoreCount )
  ) i_stream_arbiter (
    .clk_i       ( clk_d2_i      ),
    .rst_ni      ( ~rst_i        ),
    .inp_data_i  ( ptw_req_in    ),
    .inp_valid_i ( ptw_valid     ),
    .inp_ready_o ( ptw_ready     ),
    .oup_data_o  ( ptw_req_out   ),
    .oup_valid_o ( ptw_valid_out ),
    .oup_ready_i ( ptw_ready_out )
  );

  snitch_ptw #(
    .DW (snitch_pkg::DLEN)
  ) i_snitch_ptw (
    .clk_i         ( clk_d2_i        ),
    .rst_i,
    .ppn_i         ( ptw_req_out.ppn ),
    .valid_i       ( ptw_valid_out   ),
    .ready_o       ( ptw_ready_out   ),
    .va_i          ( ptw_req_out.va  ),
    .pte_o         ( ptw_pte         ),
    .is_4mega_o    ( ptw_is_4mega    ),
    .data_qaddr_o  ( ptw_req         ),
    .data_qvalid_o ( ptw_req_valid   ),
    .data_qready_i ( ptw_req_ready   ),
    .data_pdata_i  ( ptw_rsp.data    ),
    .data_perror_i ( ptw_rsp.error   ),
    .data_pvalid_i ( ptw_rsp_valid   ),
    .data_pready_o ( ptw_rsp_ready   )
  );

  isochronous_spill_register  #(
      .T      ( snitch_pkg::addr_t ),
      .Bypass ( 1'b0     )
  ) i_spill_register_ptw_req (
      .src_clk_i   ( clk_d2_i          ),
      .src_rst_ni  ( ~rst_i            ),
      .src_valid_i ( ptw_req_valid     ),
      .src_ready_o ( ptw_req_ready     ),
      .src_data_i  ( ptw_req           ),
      .dst_clk_i   ( clk_i             ),
      .dst_rst_ni  ( ~rst_i            ),
      .dst_valid_o ( ptw_data_qvalid_o ),
      .dst_ready_i ( ptw_data_qready_i ),
      .dst_data_o  ( ptw_data_qaddr_o  )
  );

  isochronous_spill_register  #(
      .T      ( snitch_pkg::dresp_t  ),
      .Bypass ( 1'b0                 )
  ) i_spill_register_ptw_rsp (
      .src_clk_i   ( clk_i             ),
      .src_rst_ni  ( ~rst_i            ),
      .src_valid_i ( ptw_data_pvalid_i ),
      .src_ready_o ( ptw_data_pready_o ),
      .src_data_i  ( ptw_data_prsp_i   ),
      .dst_clk_i   ( clk_d2_i          ),
      .dst_rst_ni  ( ~rst_i            ),
      .dst_valid_o ( ptw_rsp_valid     ),
      .dst_ready_i ( ptw_rsp_ready     ),
      .dst_data_o  ( ptw_rsp           )
  );

  // TODO(zarubaf): Maybe instantiate PTW cache.

  // ----------------------------------
  // Shared Accelerator Interconnect
  // ----------------------------------
  if (CoreCount > 1) begin : gen_shared_interconnect
    stream_arbiter #(
      .DATA_T  ( acc_req_t ),
      .N_INP   ( CoreCount ),
      .ARBITER ( "rr" )
    ) i_stream_arbiter (
      .clk_i       ( clk_i             ),
      .rst_ni      ( ~rst_i            ),
      .inp_data_i  ( acc_req_ext       ),
      .inp_valid_i ( acc_qvalid        ),
      .inp_ready_o ( acc_qready        ),
      .oup_data_o  ( acc_req_sfu       ),
      .oup_valid_o ( acc_req_sfu_valid ),
      .oup_ready_i ( acc_req_sfu_ready )
    );

  end else begin : gen_no_shared_interconnect
    assign acc_req_sfu = acc_req_ext;
    assign acc_req_sfu_valid = acc_qvalid;
    assign acc_qready = acc_req_sfu_ready;
  end

  logic [LogCoreCount-1:0] resp_sel;
  assign resp_sel = acc_resp_sfu.id[ExtendedIdWidth-1:IdWidth];

  stream_demux #(
    .N_OUP ( CoreCount )
  ) i_stream_demux (
    .inp_valid_i ( acc_resp_sfu_valid ),
    .inp_ready_o ( acc_resp_sfu_ready ),
    .oup_sel_i   ( resp_sel           ),
    .oup_valid_o ( acc_pvalid         ),
    .oup_ready_i ( acc_pready         )
  );

  for (genvar i = 0; i < CoreCount; i++) begin : gen_id_extension
    // reduce IP width again
    assign acc_resp[i].id    = acc_resp_sfu.id[IdWidth-1:0];
    assign acc_resp[i].error = acc_resp_sfu.error;
    assign acc_resp[i].data  = acc_resp_sfu.data;
  end

  spill_register  #(
    .T      ( acc_req_t  ),
    .Bypass ( 1'b1       )
  ) i_spill_register_muldiv (
    .clk_i   ,
    .rst_ni  ( ~rst_i              ),
    .valid_i ( acc_req_sfu_valid   ),
    .ready_o ( acc_req_sfu_ready   ),
    .data_i  ( acc_req_sfu         ),
    .valid_o ( acc_req_sfu_valid_q ),
    .ready_i ( acc_req_sfu_ready_q ),
    .data_o  ( acc_req_sfu_q       )
  );

  snitch_shared_muldiv #(
    .IdWidth ( ExtendedIdWidth )
  ) i_snitch_shared_muldiv (
    .clk_i            ( clk_i                   ),
    .rst_i            ( rst_i                   ),
    .acc_qaddr_i      ( acc_req_sfu_q.addr      ),
    .acc_qid_i        ( acc_req_sfu_q.id        ),
    .acc_qdata_op_i   ( acc_req_sfu_q.data_op   ),
    .acc_qdata_arga_i ( acc_req_sfu_q.data_arga ),
    .acc_qdata_argb_i ( acc_req_sfu_q.data_argb ),
    .acc_qdata_argc_i ( acc_req_sfu_q.data_argc ),
    .acc_qvalid_i     ( acc_req_sfu_valid_q     ),
    .acc_qready_o     ( acc_req_sfu_ready_q     ),
    .acc_pdata_o      ( acc_resp_sfu.data       ),
    .acc_pid_o        ( acc_resp_sfu.id         ),
    .acc_perror_o     ( acc_resp_sfu.error      ),
    .acc_pvalid_o     ( acc_resp_sfu_valid      ),
    .acc_pready_i     ( acc_resp_sfu_ready      )
  );

  // pragma translate_off
  `ifndef VERILATOR
  // Check invariants.
  initial begin
      assert(BootAddr[1:0] == 2'b00) else $error("Boot address must be aligned to 4 bytes");
      // NOTE(fschuiki): Commented this out due to added bitmasks.
      // if (SDMA == 0) assert(2**LogCoreCount     == CoreCount     || CoreCount == 1) else $error("Core count must be a power of two");
      // if (SDMA == 1) assert(2**(LogCoreCount-1) == (CoreCount-1) || CoreCount == 1) else $error("Core count must be a power of two + 1");
  end
  `endif
  // pragma translate_on
endmodule
