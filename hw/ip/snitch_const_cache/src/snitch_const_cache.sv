// Copyright 2021 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>
//         Samuel Riedel <sriedel@iis.ee.ethz.ch>

/// Serve read memory requests from a constant cache.
/// The cacheable region can be runtime configured. All writes and read
/// requests outside the configured regions will be forwarded.
module snitch_const_cache #(
  /// Cache Line Width
  parameter int unsigned LineWidth    = -1,
  /// The number of cache lines per set. Power of two; >= 2.
  parameter int unsigned LineCount    = -1,
  /// The set associativity of the cache. Power of two; >= 1.
  parameter int unsigned SetCount     = 1,
  /// AXI address width
  parameter int unsigned AxiAddrWidth = 0,
  /// AXI data width
  parameter int unsigned AxiDataWidth = 0,
  /// AXI id width
  parameter int unsigned AxiIdWidth   = 0,
  /// AXI user width
  parameter int unsigned AxiUserWidth = 0,
  parameter int unsigned MaxTrans     = 0,
  parameter int unsigned NrAddrRules  = 1,
  parameter type slv_req_t = logic,
  parameter type slv_rsp_t = logic,
  parameter type mst_req_t = logic,
  parameter type mst_rsp_t = logic
) (
  input  logic clk_i,
  input  logic rst_ni,
  input  logic enable_i,
  input  logic flush_valid_i,
  output logic flush_ready_o,
  input  logic [AxiAddrWidth-1:0] start_addr_i [NrAddrRules],
  input  logic [AxiAddrWidth-1:0] end_addr_i [NrAddrRules],
  input  slv_req_t axi_slv_req_i,
  output slv_rsp_t axi_slv_rsp_o,
  output mst_req_t axi_mst_req_o,
  input  mst_rsp_t axi_mst_rsp_i
);

  `include "axi/typedef.svh"
  `include "common_cells/registers.svh"
  import cf_math_pkg::idx_width;

  // Check for supported parameters
  if (AxiDataWidth < 32)
    $error("snitch_const_cache: AxiDataWidth must be larger than 32.");
  if (AxiDataWidth > LineWidth)
    $error("snitch_const_cache: LineWidth must be larger than/equal to AxiDataWidth.");
  if (NrAddrRules < 1)
    $error("snitch_const_cache: NrAddrRules must be larger than/equal to 1.");
  if (MaxTrans < 1)
    $error("snitch_const_cache: MaxTrans must be larger than/equal to 1.");

  // --------------------------------------------------
  // AXI Demux
  // --------------------------------------------------
  localparam int unsigned NoMstPorts = 2;

  typedef logic [idx_width(NoMstPorts)-1:0] index_t;
  typedef enum index_t {
    Cache  = 1,
    Bypass = 0
  } index_e;

  typedef logic [AxiIdWidth-1:0] id_t;
  typedef logic [AxiIdWidth:0] mst_id_t;
  typedef logic [AxiAddrWidth-1:0] addr_t;
  typedef logic [AxiDataWidth-1:0] data_t;
  typedef logic [AxiDataWidth/8-1:0] strb_t;
  typedef logic [AxiUserWidth-1:0] user_t;

  `AXI_TYPEDEF_ALL(axi, addr_t, id_t, data_t, strb_t, user_t)
  `AXI_TYPEDEF_ALL(axi_mst, addr_t, mst_id_t, data_t, strb_t, user_t)

  axi_req_t [1:0] demux_req;
  axi_resp_t [1:0] demux_rsp;

  axi_req_t refill_req;
  axi_resp_t refill_rsp;

  index_t slv_aw_select;
  index_t slv_ar_select;
  index_t dec_ar;

  axi_demux #(
    .AxiIdWidth  ( AxiIdWidth    ),
    .aw_chan_t   ( axi_aw_chan_t ),
    .w_chan_t    ( axi_w_chan_t  ),
    .b_chan_t    ( axi_b_chan_t  ),
    .ar_chan_t   ( axi_ar_chan_t ),
    .r_chan_t    ( axi_r_chan_t  ),
    .req_t       ( axi_req_t     ),
    .resp_t      ( axi_resp_t    ),
    .NoMstPorts  ( NoMstPorts    ),
    .MaxTrans    ( MaxTrans      ),
    .AxiLookBits ( AxiIdWidth    ),
    .FallThrough ( 1'b1          ),
    .SpillAw     ( 1'b0          ),
    .SpillW      ( 1'b0          ),
    .SpillB      ( 1'b0          ),
    .SpillAr     ( 1'b0          ),
    .SpillR      ( 1'b0          )
  ) i_axi_demux (
    .clk_i,
    .rst_ni,
    .test_i          ( 1'b0          ),
    .slv_req_i       ( axi_slv_req_i ),
    .slv_aw_select_i ( slv_aw_select ),
    .slv_ar_select_i ( slv_ar_select ),
    .slv_resp_o      ( axi_slv_rsp_o ),
    .mst_reqs_o      ( demux_req     ),
    .mst_resps_i     ( demux_rsp     )
  );

  typedef struct packed {
    int unsigned idx;
    addr_t       start_addr;
    addr_t       end_addr;
  } rule_t;

  rule_t [NrAddrRules-1:0] addr_map;

  for (genvar i = 0; i < NrAddrRules; i++) begin : gen_addr_map
    assign addr_map[i] = '{
      idx: Cache,
      start_addr: start_addr_i[i],
      end_addr: end_addr_i[i]
    };
  end

  addr_decode #(
    .NoIndices ( NoMstPorts  ),
    .NoRules   ( NrAddrRules ),
    .addr_t    ( addr_t      ),
    .rule_t    ( rule_t      )
  ) i_axi_aw_decode (
    .addr_i           ( axi_slv_req_i.ar.addr ),
    .addr_map_i       ( addr_map              ),
    .idx_o            ( dec_ar                ),
    .dec_valid_o      (                       ),
    .dec_error_o      (                       ),
    .en_default_idx_i ( 1'b1                  ),
    .default_idx_i    ( Bypass                )
  );

  // `AW` always bypass
  assign slv_aw_select = Bypass;

  // `AR` select logic
  always_comb begin
    // Select cache based on address region
    slv_ar_select = dec_ar;
    // Bypass all atomic requests
    if (axi_slv_req_i.ar.lock) begin
      slv_ar_select = Bypass;
    end
    // Wrapping bursts are currently not supported
    if (axi_slv_req_i.ar.burst == axi_pkg::BURST_WRAP) begin
      slv_ar_select = Bypass;
    end
    // Only accept bursts that use full AXI width
    if (axi_slv_req_i.ar.len && (axi_slv_req_i.ar.size < $clog2(AxiDataWidth/8))) begin
      slv_ar_select = Bypass;
    end
    // Bypass cache if disabled
    if (enable_i == 1'b0) begin
      slv_ar_select = Bypass;
    end
  end

  // --------------------------------------------------
  // Cache Logic
  // --------------------------------------------------
  localparam int unsigned PendingCount = MaxTrans;
  localparam snitch_icache_pkg::config_t CFG = '{
    LINE_WIDTH:    LineWidth,
    LINE_COUNT:    LineCount,
    SET_COUNT:     SetCount,
    PENDING_COUNT: PendingCount,
    FETCH_AW:      AxiAddrWidth,
    FETCH_DW:      AxiDataWidth,
    FILL_AW:       AxiAddrWidth,
    FILL_DW:       AxiDataWidth,

    FETCH_ALIGN:   $clog2(AxiDataWidth/8),
    FILL_ALIGN:    $clog2(AxiDataWidth/8),
    LINE_ALIGN:    $clog2(LineWidth/8),
    COUNT_ALIGN:   cf_math_pkg::idx_width(LineCount),
    SET_ALIGN:     cf_math_pkg::idx_width(SetCount),
    TAG_WIDTH:     AxiAddrWidth - $clog2(LineWidth/8) - $clog2(LineCount) + 1,
    ID_WIDTH_REQ:  AxiIdWidth,
    ID_WIDTH_RESP: 2**AxiIdWidth,
    PENDING_IW:    $clog2(PendingCount),
    default:       0
  };

  logic [CFG.FETCH_AW-1:0]      in_addr;
  logic [CFG.ID_WIDTH_REQ-1:0]  in_id;
  logic                         in_valid;
  logic                         in_ready;

  logic [CFG.LINE_WIDTH-1:0]    in_rsp_data;
  logic                         in_rsp_error;
  logic [CFG.ID_WIDTH_RESP-1:0] in_rsp_id;
  logic                         in_rsp_valid;
  logic                         in_rsp_ready;

  logic [CFG.FETCH_AW-1:0]      lookup_addr;
  logic [CFG.ID_WIDTH_REQ-1:0]  lookup_id;
  logic [CFG.SET_ALIGN-1:0]     lookup_set;
  logic                         lookup_hit;
  logic [CFG.LINE_WIDTH-1:0]    lookup_data;
  logic                         lookup_error;
  logic                         lookup_valid;
  logic                         lookup_ready;

  logic                         handler_req_valid;
  logic                         handler_req_ready;
  logic [CFG.FETCH_AW-1:0]      handler_req_addr;
  logic [CFG.PENDING_IW-1:0]    handler_req_id;

  logic [CFG.LINE_WIDTH-1:0]    handler_rsp_data;
  logic                         handler_rsp_error;
  logic [CFG.PENDING_IW-1:0]    handler_rsp_id;
  logic                         handler_rsp_valid;
  logic                         handler_rsp_ready;

  logic [CFG.COUNT_ALIGN-1:0]   write_addr;
  logic [CFG.SET_ALIGN-1:0]     write_set;
  logic [CFG.LINE_WIDTH-1:0]    write_data;
  logic [CFG.TAG_WIDTH-1:0]     write_tag;
  logic                         write_error;
  logic                         write_valid;
  logic                         write_ready;

  // The axi_to_cache module converts AXI requests to cache requests and
  // reconstructs AXI responses from the cache's responses
  axi_to_cache #(
    .MaxTrans ( MaxTrans   ),
    .req_t    ( axi_req_t  ),
    .resp_t   ( axi_resp_t ),
    .CFG      ( CFG        )
  ) i_axi_to_cache (
    .clk_i,
    .rst_ni,
    // Cache request
    .req_addr_o  ( in_addr          ),
    .req_id_o    ( in_id            ),
    .req_valid_o ( in_valid         ),
    .req_ready_i ( in_ready         ),
    // Cache response
    .rsp_data_i  ( in_rsp_data      ),
    .rsp_error_i ( in_rsp_error     ),
    .rsp_id_i    ( in_rsp_id        ),
    .rsp_valid_i ( in_rsp_valid     ),
    .rsp_ready_o ( in_rsp_ready     ),
    // AXI
    .slv_req_i   ( demux_req[Cache] ),
    .slv_rsp_o   ( demux_rsp[Cache] )
  );

  // The lookup module contains the actual cache RAMs and performs lookups.
  snitch_icache_lookup #(CFG) i_lookup (
    .clk_i,
    .rst_ni,

    .flush_valid_i ( flush_valid_i ),
    .flush_ready_o ( flush_ready_o ),

    .in_addr_i     ( in_addr       ),
    .in_id_i       ( in_id         ),
    .in_valid_i    ( in_valid      ),
    .in_ready_o    ( in_ready      ),

    .out_addr_o    ( lookup_addr   ),
    .out_id_o      ( lookup_id     ),
    .out_set_o     ( lookup_set    ),
    .out_hit_o     ( lookup_hit    ),
    .out_data_o    ( lookup_data   ),
    .out_error_o   ( lookup_error  ),
    .out_valid_o   ( lookup_valid  ),
    .out_ready_i   ( lookup_ready  ),

    .write_addr_i  ( write_addr    ),
    .write_set_i   ( write_set     ),
    .write_data_i  ( write_data    ),
    .write_tag_i   ( write_tag     ),
    .write_error_i ( write_error   ),
    .write_valid_i ( write_valid   ),
    .write_ready_o ( write_ready   )
  );

  // The handler module deals with the result of the lookup. It also
  // keeps track of the pending refills and ensures that no redundant memory
  // requests are made. Upon refill completion, it sends a new tag/data item
  // to the lookup module and sends the final cache response.
  snitch_icache_handler #(CFG) i_handler (
    .clk_i,
    .rst_ni,

    .in_req_addr_i   ( lookup_addr       ),
    .in_req_id_i     ( lookup_id         ),
    .in_req_set_i    ( lookup_set        ),
    .in_req_hit_i    ( lookup_hit        ),
    .in_req_data_i   ( lookup_data       ),
    .in_req_error_i  ( lookup_error      ),
    .in_req_valid_i  ( lookup_valid      ),
    .in_req_ready_o  ( lookup_ready      ),

    .in_rsp_data_o   ( in_rsp_data       ),
    .in_rsp_error_o  ( in_rsp_error      ),
    .in_rsp_id_o     ( in_rsp_id         ),
    .in_rsp_valid_o  ( in_rsp_valid      ),
    .in_rsp_ready_i  ( in_rsp_ready      ),

    .write_addr_o    ( write_addr        ),
    .write_set_o     ( write_set         ),
    .write_data_o    ( write_data        ),
    .write_tag_o     ( write_tag         ),
    .write_error_o   ( write_error       ),
    .write_valid_o   ( write_valid       ),
    .write_ready_i   ( write_ready       ),

    .out_req_addr_o  ( handler_req_addr  ),
    .out_req_id_o    ( handler_req_id    ),
    .out_req_valid_o ( handler_req_valid ),
    .out_req_ready_i ( handler_req_ready ),

    .out_rsp_data_i  ( handler_rsp_data  ),
    .out_rsp_error_i ( handler_rsp_error ),
    .out_rsp_id_i    ( handler_rsp_id    ),
    .out_rsp_valid_i ( handler_rsp_valid ),
    .out_rsp_ready_o ( handler_rsp_ready )
  );

  // The cache refill module emits AXI transactions.
  snitch_icache_refill #(
    .CFG       ( CFG        ),
    .axi_req_t ( axi_req_t  ),
    .axi_rsp_t ( axi_resp_t )
  ) i_refill (
    .clk_i,
    .rst_ni,

    .in_req_addr_i   ( handler_req_addr  ),
    .in_req_id_i     ( handler_req_id    ),
    .in_req_bypass_i ( 1'b0              ),
    .in_req_valid_i  ( handler_req_valid ),
    .in_req_ready_o  ( handler_req_ready ),

    .in_rsp_data_o   ( handler_rsp_data  ),
    .in_rsp_error_o  ( handler_rsp_error ),
    .in_rsp_id_o     ( handler_rsp_id    ),
    .in_rsp_bypass_o ( /* left open */   ),
    .in_rsp_valid_o  ( handler_rsp_valid ),
    .in_rsp_ready_i  ( handler_rsp_ready ),

    .axi_req_o       ( refill_req        ),
    .axi_rsp_i       ( refill_rsp        )
  );

  // --------------------------------------------------
  // AXI Mux
  // --------------------------------------------------
  axi_mux #(
    .SlvAxiIDWidth ( AxiIdWidth        ),
    .slv_aw_chan_t ( axi_aw_chan_t     ),
    .mst_aw_chan_t ( axi_mst_aw_chan_t ),
    .w_chan_t      ( axi_w_chan_t      ),
    .slv_b_chan_t  ( axi_b_chan_t      ),
    .mst_b_chan_t  ( axi_mst_b_chan_t  ),
    .slv_ar_chan_t ( axi_ar_chan_t     ),
    .mst_ar_chan_t ( axi_mst_ar_chan_t ),
    .slv_r_chan_t  ( axi_r_chan_t      ),
    .mst_r_chan_t  ( axi_mst_r_chan_t  ),
    .slv_req_t     ( axi_req_t         ),
    .slv_resp_t    ( axi_resp_t        ),
    .mst_req_t     ( axi_mst_req_t     ),
    .mst_resp_t    ( axi_mst_resp_t    ),
    .NoSlvPorts    ( NoMstPorts        ),
    .MaxWTrans     ( MaxTrans          ),
    .FallThrough   ( 1'b1              ),
    .SpillAw       ( 1'b0              ),
    .SpillW        ( 1'b0              ),
    .SpillB        ( 1'b0              ),
    .SpillAr       ( 1'b0              ),
    .SpillR        ( 1'b0              )
  ) i_axi_mux (
    .clk_i,
    .rst_ni,
    .test_i      ( 1'b0                            ),
    .slv_reqs_i  ( {refill_req, demux_req[Bypass]} ),
    .slv_resps_o ( {refill_rsp, demux_rsp[Bypass]} ),
    .mst_req_o   ( axi_mst_req_o                   ),
    .mst_resp_i  ( axi_mst_rsp_i                   )
  );

endmodule


/// Convert from AXI to Cache requests and reconstruct response beats on the way back
/// Adapted from axi_burst_splitter
module axi_to_cache #(
  // Maximum number of AXI read bursts outstanding at the same time
  parameter int unsigned MaxTrans           = 32'd0,
  // AXI Bus Types
  parameter type         req_t              = logic,
  parameter type         resp_t             = logic,
  parameter snitch_icache_pkg::config_t CFG = '0
)(
  input  logic                         clk_i,
  input  logic                         rst_ni,
  // Cache request
  output logic [CFG.FETCH_AW-1:0]      req_addr_o,
  output logic [CFG.ID_WIDTH_REQ-1:0]  req_id_o,
  output logic                         req_valid_o,
  input  logic                         req_ready_i,
  // Cache response
  input  logic [CFG.LINE_WIDTH-1:0]    rsp_data_i,
  input  logic                         rsp_error_i,
  input  logic [CFG.ID_WIDTH_RESP-1:0] rsp_id_i,
  input  logic                         rsp_valid_i,
  output logic                         rsp_ready_o,
  // AXI
  input  req_t                         slv_req_i,
  output resp_t                        slv_rsp_o
);

  import cf_math_pkg::idx_width;

  // AXI-word offset within cache line
  localparam int unsigned WordOffset = idx_width(CFG.LINE_WIDTH/CFG.FETCH_DW);

  typedef logic [WordOffset-1:0]       offset_t;
  typedef logic [CFG.ID_WIDTH_REQ-1:0] id_t;
  typedef struct packed {
    logic [CFG.FETCH_AW-1:0]     addr;
    logic [CFG.ID_WIDTH_REQ-1:0] id;
    axi_pkg::len_t               len;
    axi_pkg::burst_t             burst;
  } chan_t;

  // AR Channel
  chan_t         ax_d, ax_q, ax_o;
  offset_t       ar_offset;
  axi_pkg::len_t ar_len;
  logic          cnt_alloc_req, cnt_alloc_gnt;

  // R Channel
  id_t           rsp_id;
  logic          r_cnt_req, r_cnt_gnt;
  logic          r_cnt_len_dec, r_cnt_offset_inc;
  offset_t       r_cnt_offset, r_offset, r_offset_d, r_offset_q;
  axi_pkg::len_t r_cnt_len;

  // --------------------------------------------------
  // Write Channels
  // --------------------------------------------------
  // AW, W, B channel --> Never used tie off
  assign slv_rsp_o.aw_ready = 1'b0;
  assign slv_rsp_o.w_ready = 1'b0;
  assign slv_rsp_o.b_valid = 1'b0;
  assign slv_rsp_o.b = '0;

  // --------------------------------------------------
  // AR Channel
  // --------------------------------------------------
  // Store the offset if the cache is wider than AXI
  assign ar_offset = slv_req_i.ar.addr[$clog2(CFG.FETCH_DW/8)+:WordOffset];
  // Issue less requests if the cache is wider than AXI
  always_comb begin
    if (CFG.LINE_WIDTH > CFG.FETCH_DW) begin
      ar_len = (slv_req_i.ar.len + ar_offset) >> $clog2(CFG.LINE_WIDTH/CFG.FETCH_DW);
    end else begin
      ar_len = slv_req_i.ar.len;
    end
  end

  // Store counters
  axi_burst_splitter_table #(
    .MaxTrans ( MaxTrans         ),
    .IdWidth  ( CFG.ID_WIDTH_REQ ),
    .offset_t ( offset_t         )
  ) i_axi_burst_splitter_table (
    .clk_i,
    .rst_ni,
    .alloc_id_i       ( slv_req_i.ar.id  ),
    .alloc_len_i      ( slv_req_i.ar.len ),
    .alloc_offset_i   ( ar_offset        ),
    .alloc_req_i      ( cnt_alloc_req    ),
    .alloc_gnt_o      ( cnt_alloc_gnt    ),
    .cnt_id_i         ( rsp_id           ),
    .cnt_len_o        ( r_cnt_len        ),
    .cnt_offset_o     ( r_cnt_offset     ),
    .cnt_set_err_i    ( 1'b0             ),
    .cnt_err_o        ( /* unused */     ),
    .cnt_len_dec_i    ( r_cnt_len_dec    ),
    .cnt_offset_inc_i ( r_cnt_offset_inc ),
    .cnt_req_i        ( r_cnt_req        ),
    .cnt_gnt_o        ( r_cnt_gnt        )
  );

  assign req_addr_o = ax_o.addr;
  assign req_id_o = ax_o.id;

  typedef enum logic {Idle, Busy} ar_state_e;
  ar_state_e ar_state_d, ar_state_q;
  always_comb begin
    cnt_alloc_req      = 1'b0;
    ax_d               = ax_q;
    ar_state_d         = ar_state_q;
    ax_o               = '0;
    req_valid_o        = 1'b0;
    slv_rsp_o.ar_ready = 1'b0;
    unique case (ar_state_q)
      Idle: begin
        if (slv_req_i.ar_valid && cnt_alloc_gnt) begin
          if (ar_len == '0) begin // No splitting required -> feed through.
            ax_o.addr  = slv_req_i.ar.addr >> CFG.LINE_ALIGN << CFG.LINE_ALIGN;
            ax_o.id    = slv_req_i.ar.id;
            ax_o.len   = ar_len;
            req_valid_o = 1'b1;
            // As soon as downstream is ready, allocate a counter and acknowledge upstream.
            if (req_ready_i) begin
              cnt_alloc_req      = 1'b1;
              slv_rsp_o.ar_ready = 1'b1;
            end
          end else begin // Splitting required.
            // Store Ax, allocate a counter, and acknowledge upstream.
            ax_d.addr          = slv_req_i.ar.addr >> CFG.LINE_ALIGN << CFG.LINE_ALIGN;
            ax_d.id            = slv_req_i.ar.id;
            ax_d.len           = ar_len;
            ax_d.burst         = slv_req_i.ar.burst;
            cnt_alloc_req      = 1'b1;
            slv_rsp_o.ar_ready = 1'b1;
            // Try to feed first burst through.
            ax_o     = ax_d;
            ax_o.len = '0;
            req_valid_o = 1'b1;
            if (req_ready_i) begin
              // Reduce number of bursts still to be sent by one and increment address.
              ax_d.len--;
              if (ax_d.burst == axi_pkg::BURST_INCR) begin
                ax_d.addr += CFG.LINE_WIDTH/8;
              end
            end
            ar_state_d = Busy;
          end
        end
      end
      Busy: begin
        // Sent next burst from split.
        ax_o        = ax_q;
        ax_o.len    = '0;
        req_valid_o = 1'b1;
        if (req_ready_i) begin
          if (ax_q.len == '0) begin
            // If this was the last burst, go back to idle.
            ar_state_d = Idle;
          end else begin
            // Otherwise, continue with the next burst.
            ax_d.len--;
            if (ax_q.burst == axi_pkg::BURST_INCR) begin
              ax_d.addr += CFG.LINE_WIDTH/8;
            end
          end
        end
      end
      default: /*do nothing*/;
    endcase
  end

  // registers
  `FFARN(ax_q, ax_d, '0, clk_i, rst_ni)
  `FFARN(ar_state_q, ar_state_d, Idle, clk_i, rst_ni)

  // --------------------------------------------------
  // R Channel
  // --------------------------------------------------
  // Cut path
  typedef struct packed {
    logic [CFG.LINE_WIDTH-1:0]    data;
    logic                         error;
    logic [CFG.ID_WIDTH_RESP-1:0] id;
  } rsp_in_t;

  logic rsp_valid_q, rsp_ready_q;
  rsp_in_t rsp_in_d, rsp_in_q;

  assign rsp_in_d.data  = rsp_data_i;
  assign rsp_in_d.error = rsp_error_i;
  assign rsp_in_d.id    = rsp_id_i;

  spill_register #(
    .T      ( rsp_in_t),
    .Bypass ( 1'b0    )
  ) i_cut_rsp_in (
    .clk_i   ( clk_i       ),
    .rst_ni  ( rst_ni      ),
    .valid_i ( rsp_valid_i ),
    .ready_o ( rsp_ready_o ),
    .data_i  ( rsp_in_d    ),
    .valid_o ( rsp_valid_q ),
    .ready_i ( rsp_ready_q ),
    .data_o  ( rsp_in_q    )
  );

  // Reconstruct `id` by splitting cache's ID vector into multiple responses
  // rsp_valid_i --> [forward]                                             --> rsp_valid
  // rsp_ready_o <-- [ready if downstream is ready and input ID is onehot] <-- rsp_ready
  // rsp_id_i    --> [from vector to single ID with lzc]                   --> rsp_id
  // rsp_data_i  --> [forward]                                             --> rsp_in_q.data
  // rsp_error_i --> [forward]                                             --> rsp_in_q.error
  logic rsp_valid, rsp_ready;
  logic rsp_id_onehot, rsp_id_empty;
  logic [CFG.ID_WIDTH_RESP-1:0] rsp_id_mask, rsp_id_masked;

  assign rsp_ready_q   = (rsp_id_onehot | rsp_id_empty) & rsp_ready;
  assign rsp_valid     = rsp_valid_q; // And not empty?
  assign rsp_id_masked = rsp_in_q.id & ~rsp_id_mask;

  lzc #(
    .WIDTH ( CFG.ID_WIDTH_RESP ),
    .MODE  ( 0                 )
  ) i_lzc (
    .in_i    ( rsp_id_masked ),
    .cnt_o   ( rsp_id        ),
    .empty_o ( rsp_id_empty  )
  );

  onehot #(
    .Width ( CFG.ID_WIDTH_RESP )
  ) i_onehot (
    .d_i         ( rsp_id_masked ),
    .is_onehot_o ( rsp_id_onehot )
  );

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if(~rst_ni) begin
      rsp_id_mask <= '0;
    end else begin
      if (rsp_valid && rsp_ready) begin
        // Downstream handshake --> Go to next ID
        rsp_id_mask <= rsp_id_mask | (1 << rsp_id);
      end
      if (rsp_valid_q && rsp_ready_q) begin // Or empty, should be redundant
        // Upstream handshake --> Clear mask
        rsp_id_mask <= '0;
      end
    end
  end

  // Reconstruct `last`, feed rest through.
  logic r_last_d, r_last_q;
  logic [CFG.FETCH_DW-1:0] r_data, r_data_d, r_data_q;
  typedef enum logic {RFeedthrough, RWait} r_state_e;
  r_state_e r_state_d, r_state_q;

  // Tie the offset down if cache and AXI width are the same
  assign r_offset  = (CFG.LINE_WIDTH > CFG.FETCH_DW) ? r_cnt_offset : '1;
  // Do not realign data if cache and AXI width are the same
  assign r_data = (CFG.LINE_WIDTH > CFG.FETCH_DW) ?
      rsp_in_q.data >> (r_offset * CFG.FETCH_DW) : rsp_in_q.data;

  always_comb begin
    r_cnt_len_dec     = 1'b0;
    r_cnt_offset_inc  = 1'b0;
    r_cnt_req         = 1'b0;
    r_last_d          = r_last_q;
    r_state_d         = r_state_q;
    r_data_d          = r_data_q;
    r_offset_d        = r_offset_q;
    rsp_ready         = 1'b0;
    slv_rsp_o.r.id    = rsp_id;
    slv_rsp_o.r.data  = r_data;
    slv_rsp_o.r.resp  = rsp_in_q.error; // This response is already an AXI response.
    slv_rsp_o.r.user  = '0;
    slv_rsp_o.r.last  = 1'b0;
    slv_rsp_o.r_valid = 1'b0;

    unique case (r_state_q)
      RFeedthrough: begin
        // If downstream has an R beat and the R counters can give us the remaining length of
        // that burst, ...
        if (rsp_valid) begin
          r_cnt_req = 1'b1;
          if (r_cnt_gnt) begin
            r_last_d = (r_cnt_len == 8'd0);
            slv_rsp_o.r.last   = r_last_d;
            // Decrement the counter
            r_cnt_len_dec      = 1'b1;
            // Increment the offset counter
            r_cnt_offset_inc   = 1'b1;
            // Try to forward the beat upstream
            slv_rsp_o.r_valid  = 1'b1;
            if (slv_req_i.r_ready) begin
              // Is this the last chunk of this cache line
              if (r_offset == '1 || r_last_d) begin
                // Acknowledge downstream
                rsp_ready      = 1'b1;
              end
            end else begin
              // Keep output constant
              r_data_d   = r_data;
              r_offset_d = r_offset;
              // Wait for upstream to become ready
              r_state_d = RWait;
            end
          end
        end
      end
      RWait: begin
        slv_rsp_o.r.last   = r_last_q;
        slv_rsp_o.r_valid  = rsp_valid;
        slv_rsp_o.r.data   = r_data_q;
        if (rsp_valid && slv_req_i.r_ready) begin
          // Is this the last chunk of this cache line
          if (r_offset_q == '1 || r_last_q) begin
            // Acknowledge downstream
            rsp_ready      = 1'b1;
          end
          r_state_d         = RFeedthrough;
        end
      end
      default: /*do nothing*/;
    endcase
  end

  // --------------------------------------------------
  // Flip-Flops
  // --------------------------------------------------
  `FFARN(r_last_q, r_last_d, 1'b0, clk_i, rst_ni)
  `FFARN(r_state_q, r_state_d, RFeedthrough, clk_i, rst_ni)
  `FFARN(r_data_q, r_data_d, '0, clk_i, rst_ni)
  `FFARN(r_offset_q, r_offset_d, '0, clk_i, rst_ni)

endmodule


/// Stores the burst length and the corresponding address offset for the axi_to_cache module.
/// Adapted from axi_burst_splitter_counters
module axi_burst_splitter_table #(
  parameter int unsigned MaxTrans = 0,
  parameter int unsigned IdWidth  = 0,
  parameter type         offset_t = logic,
  parameter type         id_t     = logic [IdWidth-1:0]
) (
  input  logic          clk_i,
  input  logic          rst_ni,

  input  id_t           alloc_id_i,
  input  axi_pkg::len_t alloc_len_i,
  input  offset_t       alloc_offset_i,
  input  logic          alloc_req_i,
  output logic          alloc_gnt_o,

  input  id_t           cnt_id_i,
  output axi_pkg::len_t cnt_len_o,
  output offset_t       cnt_offset_o,
  input  logic          cnt_set_err_i,
  output logic          cnt_err_o,
  input  logic          cnt_len_dec_i,
  input  logic          cnt_offset_inc_i,
  input  logic          cnt_req_i,
  output logic          cnt_gnt_o
);
  localparam int unsigned CntIdxWidth = (MaxTrans > 1) ? $clog2(MaxTrans) : 32'd1;

  typedef logic [CntIdxWidth-1:0]         cnt_idx_t;
  typedef logic [$bits(axi_pkg::len_t):0] cnt_t;

  cnt_idx_t            cnt_free_idx, cnt_r_idx;
  logic [MaxTrans-1:0] cnt_len_dec, cnt_offset_inc, cnt_free, cnt_set, err_d, err_q;
  cnt_t                cnt_len_inp;
  cnt_t [MaxTrans-1:0] cnt_len_oup;
  offset_t                cnt_offset_inp;
  offset_t [MaxTrans-1:0] cnt_offset_oup;
  for (genvar i = 0; i < MaxTrans; i++) begin : gen_cnt
    counter #(
      .WIDTH ( $bits(cnt_t) )
    ) i_cnt_len (
      .clk_i,
      .rst_ni,
      .clear_i    ( 1'b0           ),
      .en_i       ( cnt_len_dec[i] ),
      .load_i     ( cnt_set[i]     ),
      .down_i     ( 1'b1           ),
      .d_i        ( cnt_len_inp    ),
      .q_o        ( cnt_len_oup[i] ),
      .overflow_o (                )  // not used
    );
    counter #(
      .WIDTH ( $bits(offset_t) )
    ) i_cnt_offset (
      .clk_i,
      .rst_ni,
      .clear_i    ( 1'b0              ),
      .en_i       ( cnt_offset_inc[i] ),
      .load_i     ( cnt_set[i]        ),
      .down_i     ( 1'b0              ),
      .d_i        ( cnt_offset_inp    ),
      .q_o        ( cnt_offset_oup[i] ),
      .overflow_o (                   )  // not used
    );
    assign cnt_free[i] = (cnt_len_oup[i] == '0);
  end
  assign cnt_len_inp    = {1'b0, alloc_len_i} + 1;
  assign cnt_offset_inp = alloc_offset_i;

  lzc #(
    .WIDTH ( MaxTrans ),
    .MODE  ( 1'b0     )
  ) i_lzc (
    .in_i    ( cnt_free     ),
    .cnt_o   ( cnt_free_idx ),
    .empty_o (              )
  );

  logic idq_inp_req, idq_inp_gnt;
  logic idq_oup_gnt, idq_oup_valid, idq_oup_pop;
  id_queue #(
    .ID_WIDTH ( $bits(id_t) ),
    .CAPACITY ( MaxTrans    ),
    .data_t   ( cnt_idx_t   )
  ) i_idq (
    .clk_i,
    .rst_ni,
    .inp_id_i         ( alloc_id_i    ),
    .inp_data_i       ( cnt_free_idx  ),
    .inp_req_i        ( idq_inp_req   ),
    .inp_gnt_o        ( idq_inp_gnt   ),
    .exists_data_i    ( '0            ),
    .exists_mask_i    ( '0            ),
    .exists_req_i     ( 1'b0          ),
    .exists_o         ( /* unused */  ),
    .exists_gnt_o     ( /* unused */  ),
    .oup_id_i         ( cnt_id_i      ),
    .oup_pop_i        ( idq_oup_pop   ),
    .oup_req_i        ( cnt_req_i     ),
    .oup_data_o       ( cnt_r_idx     ),
    .oup_data_valid_o ( idq_oup_valid ),
    .oup_gnt_o        ( idq_oup_gnt   )
  );
  logic [8:0] read_len;
  assign idq_inp_req  = alloc_req_i & alloc_gnt_o;
  assign alloc_gnt_o  = idq_inp_gnt & |(cnt_free);
  assign cnt_gnt_o    = idq_oup_gnt & idq_oup_valid;
  assign read_len     = cnt_len_oup[cnt_r_idx] - 1;
  assign cnt_len_o    = read_len[7:0];
  assign cnt_offset_o = cnt_offset_oup[cnt_r_idx];
  assign idq_oup_pop  = cnt_req_i & cnt_gnt_o & cnt_len_dec_i & (cnt_len_o == 8'd0);

  always_comb begin
    cnt_len_dec            = '0;
    cnt_len_dec[cnt_r_idx] = cnt_req_i & cnt_gnt_o & cnt_len_dec_i;
  end
  always_comb begin
    cnt_offset_inc            = '0;
    cnt_offset_inc[cnt_r_idx] = cnt_req_i & cnt_gnt_o & cnt_offset_inc_i;
  end
  always_comb begin
    cnt_set               = '0;
    cnt_set[cnt_free_idx] = alloc_req_i & alloc_gnt_o;
  end
  always_comb begin
    err_d     = err_q;
    cnt_err_o = err_q[cnt_r_idx];
    if (cnt_req_i && cnt_gnt_o && cnt_set_err_i) begin
      err_d[cnt_r_idx] = 1'b1;
      cnt_err_o        = 1'b1;
    end
    if (alloc_req_i && alloc_gnt_o) begin
      err_d[cnt_free_idx] = 1'b0;
    end
  end

  // registers
  `FFARN(err_q, err_d, '0, clk_i, rst_ni)

  `ifndef VERILATOR
  // pragma translate_off
  assume property (@(posedge clk_i) idq_oup_gnt |-> idq_oup_valid)
    else begin $warning("Invalid output at ID queue, read not granted!"); $finish(); end
  // pragma translate_on
  `endif

endmodule
