// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>

`include "snitch_vm/typedef.svh"

/// Shared subsystems for `CoreCount` cores.
module snitch_hive #(
  /// Number of cores which share an instruction frontend
  parameter int unsigned CoreCount          = 4,
  /// Width of a single icache line.
  parameter int unsigned ICacheLineWidth    = CoreCount > 2 ? CoreCount * 32 : 64,
  /// Number of icache lines per set.
  parameter int unsigned ICacheLineCount    = 128,
  /// Number of icache sets.
  parameter int unsigned ICacheSets         = 4,
  parameter bit          IsoCrossing        = 1,
  /// Address width of the buses
  parameter int unsigned AddrWidth          = 0,
  /// Data width of the Narrow bus.
  parameter int unsigned NarrowDataWidth    = 0,
  parameter int unsigned WideDataWidth      = 0,
  /// Enable virtual memory support.
  parameter bit          VMSupport          = 1,
  parameter type         dreq_t             = logic,
  parameter type         drsp_t             = logic,
  parameter type         axi_req_t          = logic,
  parameter type         axi_rsp_t          = logic,
  parameter type         hive_req_t         = logic,
  parameter type         hive_rsp_t         = logic,
  /// Configuration input types for memory cuts used in implementation.
  parameter type         sram_cfg_t         = logic,
  parameter type         sram_cfgs_t        = logic,
  /// Derived parameter *Do not override*
  parameter type addr_t = logic [AddrWidth-1:0],
  parameter type data_t = logic [NarrowDataWidth-1:0]
) (
  input  logic     clk_i,
  input  logic     clk_d2_i, // divide-by-two clock
  input  logic     rst_ni,

  input  hive_req_t [CoreCount-1:0] hive_req_i,
  output hive_rsp_t [CoreCount-1:0] hive_rsp_o,

  output dreq_t    ptw_data_req_o,
  input  drsp_t    ptw_data_rsp_i,
  output axi_req_t axi_req_o,
  input  axi_rsp_t axi_rsp_i,

  input logic      icache_prefetch_enable_i,

  input sram_cfgs_t sram_cfgs_i,

  output snitch_icache_pkg::icache_events_t [CoreCount-1:0] icache_events_o
);
  // Extend the ID to route back results to the appropriate core.
  localparam int unsigned IdWidth = 5;
  localparam int unsigned LogCoreCount = cf_math_pkg::idx_width(CoreCount);
  localparam int unsigned ExtendedIdWidth = IdWidth + LogCoreCount;

  addr_t [CoreCount-1:0] inst_addr;
  logic [CoreCount-1:0] inst_cacheable;
  logic [CoreCount-1:0][31:0] inst_data;
  logic [CoreCount-1:0] inst_valid;
  logic [CoreCount-1:0] inst_ready;
  logic [CoreCount-1:0] inst_error;
  logic [CoreCount-1:0] flush_valid;
  logic [CoreCount-1:0] flush_ready;



  for (genvar i = 0; i < CoreCount; i++) begin : gen_unpack_icache
    assign inst_addr[i] = hive_req_i[i].inst_addr;
    assign inst_cacheable[i] = hive_req_i[i].inst_cacheable;
    assign inst_valid[i] = hive_req_i[i].inst_valid;
    assign flush_valid[i] = hive_req_i[i].flush_i_valid;
    assign hive_rsp_o[i].inst_data = inst_data[i];
    assign hive_rsp_o[i].inst_ready = inst_ready[i];
    assign hive_rsp_o[i].inst_error = inst_error[i];
    assign hive_rsp_o[i].flush_i_ready = flush_ready[i];
  end

  snitch_icache #(
    .NR_FETCH_PORTS     ( CoreCount        ),
    .L0_LINE_COUNT      ( 8                ),
    .LINE_WIDTH         ( ICacheLineWidth  ),
    .LINE_COUNT         ( ICacheLineCount  ),
    .SET_COUNT          ( ICacheSets       ),
    .FETCH_AW           ( AddrWidth        ),
    .FETCH_DW           ( 32               ),
    .FILL_AW            ( AddrWidth        ),
    .FILL_DW            ( WideDataWidth    ),
    .EARLY_LATCH        ( 0               ),
    .L0_EARLY_TAG_WIDTH ( snitch_pkg::PAGE_SHIFT - $clog2(ICacheLineWidth/8) ),
    .ISO_CROSSING       ( IsoCrossing     ),
    .sram_cfg_tag_t     ( sram_cfg_t ),
    .sram_cfg_data_t    ( sram_cfg_t ),
    .axi_req_t          ( axi_req_t ),
    .axi_rsp_t          ( axi_rsp_t )
  ) i_snitch_icache (
    .clk_i (clk_i),
    .clk_d2_i (clk_d2_i),
    .rst_ni (rst_ni),
    .enable_prefetching_i ( icache_prefetch_enable_i ),
    .icache_events_o  ( icache_events_o),
    .flush_valid_i    ( flush_valid    ),
    .flush_ready_o    ( flush_ready    ),

    .inst_addr_i      ( inst_addr      ),
    .inst_cacheable_i ( inst_cacheable ),
    .inst_data_o      ( inst_data      ),
    .inst_valid_i     ( inst_valid     ),
    .inst_ready_o     ( inst_ready     ),
    .inst_error_o     ( inst_error     ),

    .sram_cfg_tag_i   ( sram_cfgs_i.icache_tag  ),
    .sram_cfg_data_i  ( sram_cfgs_i.icache_data ),

    .axi_req_o (axi_req_o),
    .axi_rsp_i (axi_rsp_i)
  );

  // -------------------
  // Shared VM Subsystem
  // -------------------

  // Typedef outside of the generate block
  // for VCS compatibility reasons

  `SNITCH_VM_TYPEDEF(AddrWidth)

  typedef struct packed {
    snitch_pkg::va_t va;
    pa_t ppn;
  } va_arb_t;

  if (VMSupport) begin : gen_ptw

    logic [2*CoreCount-1:0] ptw_valid, ptw_ready;
    va_arb_t [2*CoreCount-1:0] ptw_req_in;
    va_arb_t ptw_req_out;

    // We've two request ports per core for the PTW:
    // instructions and data.
    l0_pte_t ptw_pte;
    logic    ptw_is_4mega;

    for (genvar i = 0; i < CoreCount; i++) begin : gen_connect_ptw_core
      for (genvar j = 0; j < 2; j++) begin : gen_connect_ptw_port
        assign ptw_req_in[2*i+j].va = hive_req_i[i].ptw_va;
        assign ptw_req_in[2*i+j].ppn = hive_req_i[i].ptw_ppn;
        assign ptw_valid[2*i+j] = hive_req_i[i].ptw_valid;
      end
      assign hive_rsp_o[i].ptw_ready = ptw_ready[2*i+:2];
      assign hive_rsp_o[i].ptw_pte = ptw_pte;
      assign hive_rsp_o[i].ptw_is_4mega = ptw_is_4mega;
    end

    logic ptw_valid_out, ptw_ready_out;

    /// Multiplex translation requests
    stream_arbiter #(
      .DATA_T ( va_arb_t ),
      .N_INP  ( 2*CoreCount )
    ) i_stream_arbiter (
      .clk_i       ( clk_d2_i      ),
      .rst_ni      ( rst_ni        ),
      .inp_data_i  ( ptw_req_in    ),
      .inp_valid_i ( ptw_valid     ),
      .inp_ready_o ( ptw_ready     ),
      .oup_data_o  ( ptw_req_out   ),
      .oup_valid_o ( ptw_valid_out ),
      .oup_ready_i ( ptw_ready_out )
    );

    dreq_t ptw_req;
    drsp_t ptw_rsp;

    snitch_ptw #(
      .AddrWidth (AddrWidth),
      .DataWidth (NarrowDataWidth),
      .pa_t (pa_t),
      .l0_pte_t (l0_pte_t),
      .pte_sv32_t (pte_sv32_t),
      .dreq_t (dreq_t),
      .drsp_t (drsp_t)
    ) i_snitch_ptw (
      .clk_i         ( clk_d2_i        ),
      .rst_ni        ( rst_ni          ),
      .ppn_i         ( ptw_req_out.ppn ),
      .valid_i       ( ptw_valid_out   ),
      .ready_o       ( ptw_ready_out   ),
      .va_i          ( ptw_req_out.va  ),
      .pte_o         ( ptw_pte         ),
      .is_4mega_o    ( ptw_is_4mega    ),
      .data_req_o    ( ptw_req ),
      .data_rsp_i    ( ptw_rsp )
    );

    reqrsp_iso #(
      .AddrWidth (AddrWidth),
      .DataWidth (NarrowDataWidth),
      .req_t (dreq_t),
      .rsp_t (drsp_t),
      .BypassReq (1'b0),
      .BypassRsp (1'b0)
    ) i_reqrsp_iso (
      .src_clk_i (clk_d2_i),
      .src_rst_ni (rst_ni),
      .src_req_i (ptw_req),
      .src_rsp_o (ptw_rsp),
      .dst_clk_i (clk_i),
      .dst_rst_ni (rst_ni),
      .dst_req_o (ptw_data_req_o),
      .dst_rsp_i (ptw_data_rsp_i)
    );

    // TODO(zarubaf): Maybe instantiate PTW cache.

  end else begin : gen_no_ptw

    assign ptw_data_req_o = '0;

    for (genvar i = 0; i < CoreCount; i++) begin : gen_tie_ptw_core
      assign hive_rsp_o[i].ptw_ready = '0;
      assign hive_rsp_o[i].ptw_pte = '0;
      assign hive_rsp_o[i].ptw_is_4mega = 1'b0;
    end

  end

  // ----------------------------------
  // Shared Accelerator Interconnect
  // ----------------------------------
  typedef struct packed {
    logic [31:0]                addr;
    logic [ExtendedIdWidth-1:0] id;
    logic [31:0]                data_op;
    data_t          data_arga;
    data_t          data_argb;
    data_t          data_argc;
  } acc_req_t;

  typedef struct packed {
    logic [ExtendedIdWidth-1:0] id;
    logic                       error;
    data_t          data;
  } acc_resp_t;

  acc_req_t              acc_req_sfu, acc_req_sfu_q; // to shared functional unit
  logic                  acc_req_sfu_valid, acc_req_sfu_valid_q;
  logic                  acc_req_sfu_ready, acc_req_sfu_ready_q;

  acc_resp_t             acc_resp_sfu; // to shared functional unit
  logic                  acc_resp_sfu_valid;
  logic                  acc_resp_sfu_ready;


  acc_req_t              [CoreCount-1:0] acc_req_ext; // extended version
  logic                  [CoreCount-1:0] acc_qvalid;
  logic                  [CoreCount-1:0] acc_qready;
  logic                  [CoreCount-1:0] acc_pvalid;
  logic                  [CoreCount-1:0] acc_pready;

  for (genvar i = 0; i < CoreCount; i++) begin : gen_core
    assign acc_qvalid[i] = hive_req_i[i].acc_qvalid;
    assign acc_pready[i] = hive_req_i[i].acc_pready;
    assign hive_rsp_o[i].acc_qready = acc_qready[i];
    assign hive_rsp_o[i].acc_pvalid = acc_pvalid[i];
    assign acc_req_ext[i].id = {i[LogCoreCount-1:0], hive_req_i[i].acc_req.id};
    assign acc_req_ext[i].addr = hive_req_i[i].acc_req.addr;
    assign acc_req_ext[i].data_op = hive_req_i[i].acc_req.data_op;
    assign acc_req_ext[i].data_arga = hive_req_i[i].acc_req.data_arga;
    assign acc_req_ext[i].data_argb = hive_req_i[i].acc_req.data_argb;
    assign acc_req_ext[i].data_argc = hive_req_i[i].acc_req.data_argc;
  end

  if (CoreCount > 1) begin : gen_shared_interconnect
    stream_arbiter #(
      .DATA_T  ( acc_req_t ),
      .N_INP   ( CoreCount ),
      .ARBITER ( "rr" )
    ) i_stream_arbiter (
      .clk_i       ( clk_i             ),
      .rst_ni      ( rst_ni            ),
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
    assign hive_rsp_o[i].acc_resp.id    = acc_resp_sfu.id[IdWidth-1:0];
    assign hive_rsp_o[i].acc_resp.error = acc_resp_sfu.error;
    assign hive_rsp_o[i].acc_resp.data  = acc_resp_sfu.data;
  end

  spill_register  #(
    .T      ( acc_req_t  ),
    .Bypass ( 1'b1       )
  ) i_spill_register_muldiv (
    .clk_i   ,
    .rst_ni  ( rst_ni              ),
    .valid_i ( acc_req_sfu_valid   ),
    .ready_o ( acc_req_sfu_ready   ),
    .data_i  ( acc_req_sfu         ),
    .valid_o ( acc_req_sfu_valid_q ),
    .ready_i ( acc_req_sfu_ready_q ),
    .data_o  ( acc_req_sfu_q       )
  );

  snitch_shared_muldiv #(
    .DataWidth (NarrowDataWidth),
    .IdWidth ( ExtendedIdWidth )
  ) i_snitch_shared_muldiv (
    .clk_i            ( clk_i                   ),
    .rst_ni           ( rst_ni                  ),
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

endmodule
