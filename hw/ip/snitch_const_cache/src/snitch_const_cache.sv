// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Florian Zaruba <zarubaf@iis.ee.ethz.ch>


/// Serve bufferable read memory requests from a constant cache.
/// In more specific AXI terms:
///   ArCache xy11 (x or y must be 1)
///   - ArCache[3] (OtherAllocate)
///   - ArCache[2] (Allocate)
///   - ArCache[1] (Modifiable): Must be 1
///   - ArCache[0] (Bufferable): Must be 1
///
/// Other reads will be served from backing memory.
/// Write requests must always be non-bufferable and non-cacheable.
/// i.e., AwCache must be 00?0
module snitch_const_cache #(
  /// Cache Line Width
  parameter int unsigned LineWidth = -1,
  /// The number of cache lines per set. Power of two; >= 2.
  parameter int unsigned LineCount = -1,
  /// The set associativity of the cache. Power of two; >= 1.
  parameter int unsigned SetCount = 1,
  /// AXI address width
  parameter int unsigned AxiAddrWidth = 0,
  /// AXI data width
  parameter int unsigned AxiDataWidth = 0,
  /// AXI id width
  parameter int unsigned AxiIdWidth = 0,
  /// AXI user width
  parameter int unsigned AxiUserWidth = 0,
  parameter int unsigned MaxTrans       = 32'd8,
  parameter int unsigned NrAddrRules = 1,
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
    $error("snitch_const_cache: LineWidth must be larger/equal than AxiDataWidth.");

  typedef enum logic [1:0] {
    Error = 0,
    Cache = 1,
    Bypass = 2
  } index_e;

  typedef logic [AxiIdWidth-1:0] id_t;
  typedef logic [AxiIdWidth:0] mst_id_t;
  typedef logic [AxiAddrWidth-1:0] addr_t;
  typedef logic [AxiDataWidth-1:0] data_t;
  typedef logic [AxiDataWidth/8-1:0] strb_t;
  typedef logic [AxiUserWidth-1:0] user_t;

  `AXI_TYPEDEF_ALL(axi, addr_t, id_t, data_t, strb_t, user_t)
  `AXI_TYPEDEF_ALL(axi_mst, addr_t, mst_id_t, data_t, strb_t, user_t)

  axi_req_t [2:0] demux_req;
  axi_resp_t [2:0] demux_rsp;

  axi_req_t refill_req;
  axi_resp_t refill_rsp;

  logic [1:0] slv_aw_select;
  logic [1:0] slv_ar_select;

  axi_demux #(
    .AxiIdWidth     ( AxiIdWidth    ),
    .aw_chan_t      ( axi_aw_chan_t ),
    .w_chan_t       ( axi_w_chan_t  ),
    .b_chan_t       ( axi_b_chan_t  ),
    .ar_chan_t      ( axi_ar_chan_t ),
    .r_chan_t       ( axi_r_chan_t  ),
    .req_t          ( axi_req_t     ),
    .resp_t         ( axi_resp_t    ),
    .NoMstPorts     ( 3             ),
    .MaxTrans       ( MaxTrans      ),
    .AxiLookBits    ( AxiIdWidth    ),
    .FallThrough    ( 1'b1          ),
    .SpillAw        ( 1'b0          ),
    .SpillW         ( 1'b0          ),
    .SpillB         ( 1'b0          ),
    .SpillAr        ( 1'b0          ),
    .SpillR         ( 1'b0          )
  ) i_axi_demux (
    .clk_i,
    .rst_ni,
    .test_i          ( 1'b0                ),
    .slv_req_i       ( axi_slv_req_i       ),
    .slv_aw_select_i ( slv_aw_select       ),
    .slv_ar_select_i ( slv_ar_select       ),
    .slv_resp_o      ( axi_slv_rsp_o       ),
    .mst_reqs_o      ( demux_req           ),
    .mst_resps_i     ( demux_rsp           )
  );

  axi_err_slv #(
    .AxiIdWidth  ( AxiIdWidth ),
    .req_t       ( axi_req_t              ),
    .resp_t      ( axi_resp_t             ),
    .Resp        ( axi_pkg::RESP_DECERR   ),
    .ATOPs       ( 1'b1                   ),
    .MaxTrans    ( 1                      )
  ) i_axi_err_slv (
    .clk_i,
    .rst_ni,
    .test_i (1'b0),
    // slave port
    .slv_req_i  ( demux_req[0] ),
    .slv_resp_o ( demux_rsp[0] )
  );

  logic [1:0] dec_ar;

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
    .NoIndices  ( 3 ),
    .NoRules    ( NrAddrRules ),
    .addr_t     ( addr_t ),
    .rule_t     ( rule_t )
  ) i_axi_aw_decode (
    .addr_i           ( axi_slv_req_i.ar.addr ),
    .addr_map_i       ( addr_map              ),
    .idx_o            ( dec_ar                ),
    .dec_valid_o      (                       ),
    .dec_error_o      (                       ),
    .en_default_idx_i ( 1'b1                  ),
    // Default is bypass.
    .default_idx_i    ( Bypass                )
  );

  // `AW` always bypass
  assign slv_aw_select = Bypass;

  // select logic
  always_comb begin
    // Cache selection logic.
    slv_ar_select = dec_ar;
    // Bypass all atomic requests
    if (axi_slv_req_i.ar.lock) begin
      slv_ar_select = Bypass;
    end
    // Wrapping bursts are currently not supported.
    if (axi_slv_req_i.ar.burst == axi_pkg::BURST_WRAP) begin
      slv_ar_select = Bypass;
    end
    // Bypass cache if disabled
    if (enable_i == 1'b0) begin
      slv_ar_select = Bypass;
    end
  end

  // Store some AXI metadata for the response
  typedef struct packed {
    logic [AxiIdWidth-1:0]          id; // Store the AXI ID of the request
    logic [$clog2(LineWidth/8)-1:0] addr; // Store the offset in the cache line minus the byte offset
    axi_pkg::len_t                  len; // Store the length of the burst
    axi_pkg::size_t                 size; // Store the size of the beats
    logic                           valid; // Metadata is valid --> a transaction is already in flight
  } metadata_t;

  localparam PendingCount = 2**AxiIdWidth; // TODO: Necessary for now to support all IDs requesting the same address in the handler

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
      META_WIDTH:    $bits(metadata_t),
      PENDING_IW:    $clog2(PendingCount),
      default:       0
  };

  // The lookup module contains the actual cache RAMs and performs lookups.
  logic [CFG.FETCH_AW-1:0]     lookup_addr;
  metadata_t                   lookup_meta;
  logic [CFG.SET_ALIGN-1:0]    lookup_set;
  logic                        lookup_hit;
  logic [CFG.LINE_WIDTH-1:0]   lookup_data;
  logic                        lookup_error;
  logic                        lookup_valid;
  logic                        lookup_ready;

  logic [CFG.COUNT_ALIGN-1:0]  write_addr;
  logic [CFG.SET_ALIGN-1:0]    write_set;
  logic [CFG.LINE_WIDTH-1:0]   write_data;
  logic [CFG.TAG_WIDTH-1:0]    write_tag;
  logic                        write_error;
  logic                        write_valid;
  logic                        write_ready;

  logic [CFG.FETCH_AW-1:0]     in_addr;
  metadata_t                   in_meta;
  logic                        in_valid;
  logic                        in_ready;

  logic                         handler_req_valid;
  logic                         handler_req_ready;
  logic [CFG.FETCH_AW-1:0]      handler_req_addr;
  logic [CFG.PENDING_IW-1:0]    handler_req_id;

  logic [CFG.LINE_WIDTH-1:0]    handler_rsp_data;
  logic                         handler_rsp_error;
  logic [CFG.PENDING_IW-1:0]    handler_rsp_id;
  logic                         handler_rsp_valid;
  logic                         handler_rsp_ready;

  logic [CFG.LINE_WIDTH-1:0]    in_rsp_data;
  logic                         in_rsp_error;
  logic [CFG.ID_WIDTH_RESP-1:0] in_rsp_id;
  logic                         in_rsp_valid;
  logic                         in_rsp_ready;

  localparam int unsigned MaxTxns = 8;

  axi_to_cache #(
    .MaxTxns     ( MaxTxns      ),
    .AddrWidth   ( 0            ),
    .DataWidth   ( 0            ),
    .IdWidth     ( AxiIdWidth   ),
    .UserWidth   ( 0            ),
    .metadata_t  ( metadata_t   ),
    .req_t       ( axi_req_t    ),
    .resp_t      ( axi_resp_t   ),
    .CFG         ( CFG          )
  ) i_axi_to_cache (
    .clk_i       ( clk_i        ),
    .rst_ni      ( rst_ni       ),
    // Cache request
    .req_addr_o  ( in_addr      ),
    .req_meta_o  ( in_meta      ),
    .req_valid_o ( in_valid     ),
    .req_ready_i ( in_ready     ),
    // Cache response
    .rsp_data_i  ( in_rsp_data  ),
    .rsp_error_i ( in_rsp_error ),
    .rsp_id_i    ( in_rsp_id    ),
    .rsp_meta_i  ( in_rsp_id    ),
    .rsp_valid_i ( in_rsp_valid ),
    .rsp_ready_o ( in_rsp_ready ),
    // AXI
    .slv_req_i   ( demux_req[Cache] ),
    .slv_rsp_o   ( demux_rsp[Cache] )
  );

  snitch_icache_lookup #(CFG) i_lookup (
    .clk_i,
    .rst_ni,

    .flush_valid_i ( flush_valid_i ),
    .flush_ready_o ( flush_ready_o ),

    .in_addr_i     ( in_addr   ),
    .in_meta_i     ( in_meta   ),
    .in_valid_i    ( in_valid  ),
    .in_ready_o    ( in_ready  ),

    .out_addr_o    ( lookup_addr        ),
    .out_meta_o    ( lookup_meta        ),
    .out_set_o     ( lookup_set         ),
    .out_hit_o     ( lookup_hit         ),
    .out_data_o    ( lookup_data        ),
    .out_error_o   ( lookup_error       ),
    .out_valid_o   ( lookup_valid       ),
    .out_ready_i   ( lookup_ready       ),

    .write_addr_i  ( write_addr         ),
    .write_set_i   ( write_set          ),
    .write_data_i  ( write_data         ),
    .write_tag_i   ( write_tag          ),
    .write_error_i ( write_error        ),
    .write_valid_i ( write_valid        ),
    .write_ready_o ( write_ready        )
  );

  snitch_icache_handler #(CFG) i_handler (
    .clk_i,
    .rst_ni,

    .in_req_addr_i   ( lookup_addr        ),
    .in_req_id_i     ( lookup_meta.id     ),
    .in_req_set_i    ( lookup_set         ),
    .in_req_hit_i    ( lookup_hit         ),
    .in_req_data_i   ( lookup_data        ),
    .in_req_error_i  ( lookup_error       ),
    .in_req_valid_i  ( lookup_valid       ),
    .in_req_ready_o  ( lookup_ready       ),

    .in_rsp_data_o   ( in_rsp_data        ),
    .in_rsp_error_o  ( in_rsp_error       ),
    .in_rsp_id_o     ( in_rsp_id          ),
    .in_rsp_valid_o  ( in_rsp_valid       ),
    .in_rsp_ready_i  ( in_rsp_ready       ),

    .write_addr_o    ( write_addr         ),
    .write_set_o     ( write_set          ),
    .write_data_o    ( write_data         ),
    .write_tag_o     ( write_tag          ),
    .write_error_o   ( write_error        ),
    .write_valid_o   ( write_valid        ),
    .write_ready_i   ( write_ready        ),

    .out_req_addr_o  ( handler_req_addr   ),
    .out_req_id_o    ( handler_req_id     ),
    .out_req_valid_o ( handler_req_valid  ),
    .out_req_ready_i ( handler_req_ready  ),

    .out_rsp_data_i  ( handler_rsp_data   ),
    .out_rsp_error_i ( handler_rsp_error  ),
    .out_rsp_id_i    ( handler_rsp_id     ),
    .out_rsp_valid_i ( handler_rsp_valid  ),
    .out_rsp_ready_o ( handler_rsp_ready  )
  );

  // Instantiate the cache refill module which emits AXI transactions.
  snitch_icache_refill #(
    .CFG(CFG),
    .axi_req_t (axi_req_t),
    .axi_rsp_t (axi_resp_t)
  ) i_refill (
    .clk_i,
    .rst_ni,

    .in_req_addr_i   ( handler_req_addr  ),
    .in_req_id_i     ( handler_req_id    ),
    .in_req_bypass_i ( 1'b0              ),
    .in_req_valid_i  ( handler_req_valid ),
    .in_req_ready_o  ( handler_req_ready ),

    .in_rsp_data_o   ( handler_rsp_data   ),
    .in_rsp_error_o  ( handler_rsp_error  ),
    .in_rsp_id_o     ( handler_rsp_id     ),
    .in_rsp_bypass_o ( /* left open */    ),
    .in_rsp_valid_o  ( handler_rsp_valid  ),
    .in_rsp_ready_i  ( handler_rsp_ready  ),
    .axi_req_o (refill_req),
    .axi_rsp_i (refill_rsp)
  );

  axi_mux #(
    .SlvAxiIDWidth ( AxiIdWidth ),
    .slv_aw_chan_t ( axi_aw_chan_t ),
    .mst_aw_chan_t ( axi_mst_aw_chan_t ),
    .w_chan_t      ( axi_w_chan_t ),
    .slv_b_chan_t  ( axi_b_chan_t ),
    .mst_b_chan_t  ( axi_mst_b_chan_t ),
    .slv_ar_chan_t ( axi_ar_chan_t ),
    .mst_ar_chan_t ( axi_mst_ar_chan_t ),
    .slv_r_chan_t  ( axi_r_chan_t ),
    .mst_r_chan_t  ( axi_mst_r_chan_t ),
    .slv_req_t     ( axi_req_t ),
    .slv_resp_t    ( axi_resp_t ),
    .mst_req_t     ( axi_mst_req_t ),
    .mst_resp_t    ( axi_mst_resp_t ),
    .NoSlvPorts    ( 2 ),
    .MaxWTrans     ( MaxTrans ),
    .FallThrough   ( 1'b1 ),
    .SpillAw       ( 1'b0 ),
    .SpillW        ( 1'b0 ),
    .SpillB        ( 1'b0 ),
    .SpillAr       ( 1'b0 ),
    .SpillR        ( 1'b0 )
  ) i_axi_mux (
    .clk_i,   // Clock
    .rst_ni,  // Asynchronous reset active low
    .test_i (1'b0),  // Test Mode enable
    .slv_reqs_i  ({demux_req[2], refill_req}),
    .slv_resps_o ({demux_rsp[2], refill_rsp}),
    .mst_req_o   (axi_mst_req_o),
    .mst_resp_i  (axi_mst_rsp_i)
  );

endmodule





















/// Convert from AXI to Cache requests and reconstruct response beats on the way back
module axi_to_cache #(
  // Maximum number of AXI read bursts outstanding at the same time
  parameter int unsigned MaxTxns            = 32'd0,
  // AXI Bus Types
  parameter int unsigned AddrWidth          = 32'd0,
  parameter int unsigned DataWidth          = 32'd0,
  parameter int unsigned IdWidth            = 32'd0,
  parameter int unsigned UserWidth          = 32'd0,
  parameter type         metadata_t         = logic,
  parameter type         req_t              = logic,
  parameter type         resp_t             = logic,
  parameter snitch_icache_pkg::config_t CFG = '0
)(
  input  logic                         clk_i,
  input  logic                         rst_ni,
  // Cache request
  output logic [CFG.FETCH_AW-1:0]      req_addr_o,
  output logic [CFG.META_WIDTH-1:0]    req_meta_o,
  output logic                         req_valid_o,
  input  logic                         req_ready_i,
  // Cache response
  input  logic [CFG.LINE_WIDTH-1:0]    rsp_data_i,
  input  logic                         rsp_error_i,
  input  logic [CFG.ID_WIDTH_RESP-1:0] rsp_id_i,
  input  logic [CFG.META_WIDTH-1:0]    rsp_meta_i,
  input  logic                         rsp_valid_i,
  output logic                         rsp_ready_o,
  // AXI
  input  req_t                         slv_req_i,
  output resp_t                        slv_rsp_o
);

  import cf_math_pkg::idx_width;

  localparam WORD_OFFSET = idx_width(CFG.LINE_WIDTH/CFG.FETCH_DW); // AXI-word offset within cache line

  // AW, W, B channel --> Never used tie off
  assign slv_rsp_o.aw_ready = 1'b0;
  assign slv_rsp_o.w_ready = 1'b0;
  assign slv_rsp_o.b_valid = 1'b0;
  assign slv_rsp_o.b = '0;

  // R Channel
  typedef logic [IdWidth-1:0] id_t;
  id_t  rsp_id;

  // --------------------------------------------------
  // AR Channel
  // --------------------------------------------------
  // See description of `ax_chan` module.
  logic           r_cnt_dec, r_cnt_req, r_cnt_gnt;
  axi_pkg::len_t  r_cnt_len;
  logic           cnt_alloc_req, cnt_alloc_gnt;
  metadata_t      r_metadata;

  // Store counters
  axi_burst_splitter_table #(
    .MaxTxns    ( MaxTxns    ),
    .IdWidth    ( IdWidth    ),
    .metadata_t ( metadata_t )
  ) i_axi_burst_splitter_table (
    .clk_i,
    .rst_ni,
    .alloc_id_i     ( slv_req_i.ar.id  ),
    .alloc_len_i    ( slv_req_i.ar.len ),
    .alloc_meta_i   ( req_meta_o       ),
    .alloc_req_i    ( cnt_alloc_req    ),
    .alloc_gnt_o    ( cnt_alloc_gnt    ),
    .cnt_id_i       ( rsp_id             ),
    .cnt_len_o      ( r_cnt_len        ),
    .cnt_meta_o     ( r_metadata       ),
    .cnt_set_err_i  ( 1'b0             ),
    .cnt_err_o      ( /* unused */     ),
    .cnt_dec_i      ( r_cnt_dec        ),
    .cnt_req_i      ( r_cnt_req        ),
    .cnt_gnt_o      ( r_cnt_gnt        )
  );

  typedef struct packed {
    logic [CFG.FETCH_AW-1:0] addr;
    metadata_t               meta;
    axi_pkg::burst_t         burst;
  } chan_t;

  chan_t ax_d, ax_q, ax_o;

  assign req_addr_o = ax_o.addr;
  assign req_meta_o = ax_o.meta;

  enum logic {Idle, Busy} state_d, state_q;
  always_comb begin
    cnt_alloc_req      = 1'b0;
    ax_d               = ax_q;
    state_d            = state_q;
    ax_o               = '0;
    req_valid_o        = 1'b0;
    slv_rsp_o.ar_ready = 1'b0;
    unique case (state_q)
      Idle: begin
        if (slv_req_i.ar_valid && cnt_alloc_gnt) begin
          if (slv_req_i.ar.len == '0) begin // No splitting required -> feed through.
            ax_o.addr       = slv_req_i.ar.addr >> CFG.LINE_ALIGN << CFG.LINE_ALIGN;
            ax_o.meta.id    = slv_req_i.ar.id;
            ax_o.meta.addr  = slv_req_i.ar.addr[0+:CFG.LINE_ALIGN];
            ax_o.meta.len   = slv_req_i.ar.len;
            ax_o.meta.size  = slv_req_i.ar.size;
            ax_o.meta.valid = slv_req_i.ar_valid;
            req_valid_o = 1'b1;
            // As soon as downstream is ready, allocate a counter and acknowledge upstream.
            if (req_ready_i) begin
              cnt_alloc_req      = 1'b1;
              slv_rsp_o.ar_ready = 1'b1;
            end
          end else begin // Splitting required.
            // Store Ax, allocate a counter, and acknowledge upstream.
            ax_d.addr       = slv_req_i.ar.addr >> CFG.LINE_ALIGN << CFG.LINE_ALIGN;
            ax_d.meta.id    = slv_req_i.ar.id;
            ax_d.meta.addr  = slv_req_i.ar.addr[0+:CFG.LINE_ALIGN];
            ax_d.meta.len   = slv_req_i.ar.len;
            ax_d.meta.size  = slv_req_i.ar.size;
            ax_d.meta.valid = slv_req_i.ar_valid;
            ax_d.burst      = slv_req_i.ar.burst;
            cnt_alloc_req = 1'b1;
            slv_rsp_o.ar_ready    = 1'b1;
            // Try to feed first burst through.
            ax_o          = ax_d;
            ax_o.meta.len = '0;
            req_valid_o = 1'b1;
            if (req_ready_i) begin
              // Reduce number of bursts still to be sent by one and increment address.
              ax_d.meta.len--; // TODO multiply by cache line width
              if (ax_d.burst == axi_pkg::BURST_INCR) begin
                ax_d.addr += (1 << ax_d.meta.size); // TODO Will be the cache line width
              end
            end
            state_d = Busy;
          end
        end
      end
      Busy: begin
        // Sent next burst from split.
        ax_o            = ax_q;
        ax_o.meta.len   = '0;
        req_valid_o     = 1'b1;
        if (req_ready_i) begin
          if (ax_q.meta.len == '0) begin
            // If this was the last burst, go back to idle.
            state_d = Idle;
          end else begin
            // Otherwise, continue with the next burst.
            ax_d.meta.len--;
            if (ax_q.burst == axi_pkg::BURST_INCR) begin
              ax_d.addr += (1 << ax_q.meta.size);
            end
          end
        end
      end
      default: /*do nothing*/;
    endcase
  end

  // registers
  `FFARN(ax_q, ax_d, '0, clk_i, rst_ni)
  `FFARN(state_q, state_d, Idle, clk_i, rst_ni)

  // --------------------------------------------------
  // R Channel
  // --------------------------------------------------
  // Cut path
  typedef struct packed {
    logic [CFG.LINE_WIDTH-1:0]    data;
    logic                         error;
    logic [CFG.ID_WIDTH_RESP-1:0] id;
    logic [CFG.META_WIDTH-1:0]    meta;
  } rsp_in_t;

  logic rsp_valid_q, rsp_ready_q;
  rsp_in_t rsp_in_d, rsp_in_q;

  assign rsp_in_d.data  = rsp_data_i;
  assign rsp_in_d.error = rsp_error_i;
  assign rsp_in_d.id    = rsp_id_i;
  assign rsp_in_d.meta  = rsp_meta_i;

  spill_register #(
    .T      ( rsp_in_t),
    .Bypass ( 1'b0    )
  ) i_cut_rsp_in (
    .clk_i   ( clk_i   ),
    .rst_ni  ( rst_ni  ),
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
  // rsp_id_i    --> [from vector to single ID]                            --> rsp_id
  // rsp_data_i  --> [forward]                                             --> rsp_in_q.data
  // rsp_error_i --> [forward]                                             --> rsp_in_q.error
  // rsp_meta_i  --> [forward]                                             --> rsp_in_q.meta
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

  always_ff @(posedge clk_i or negedge rst_ni) begin : proc_metadata
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
  enum logic {RFeedthrough, RWait} r_state_d, r_state_q;

  always_comb begin
    r_cnt_dec         = 1'b0;
    r_cnt_req         = 1'b0;
    r_last_d          = r_last_q;
    r_state_d         = r_state_q;
    rsp_ready         = 1'b0;
    slv_rsp_o.r.id    = rsp_id;
    slv_rsp_o.r.data  = rsp_in_q.data >> (r_metadata.addr[$clog2(CFG.FETCH_DW/8)+:WORD_OFFSET] * CFG.FETCH_DW);
    slv_rsp_o.r.resp  = rsp_in_q.error; // This response is already an AXI response.
    // slv_rsp_o.r.last  = ~(|metadata[rsp_id].len);
    slv_rsp_o.r.user  = '0;
    slv_rsp_o.r.last  = 1'b0;
    slv_rsp_o.r_valid = 1'b0;
    // slv_rsp_o.r_valid = ~in_rsp_empty;

    unique case (r_state_q)
      RFeedthrough: begin
        // If downstream has an R beat and the R counters can give us the remaining length of
        // that burst, ...
        if (rsp_valid) begin
          r_cnt_req = 1'b1;
          if (r_cnt_gnt) begin
            r_last_d = (r_cnt_len == 8'd0);
            slv_rsp_o.r.last   = r_last_d;
            // Decrement the counter.
            r_cnt_dec         = 1'b1;
            // Try to forward the beat upstream.
            slv_rsp_o.r_valid  = 1'b1;
            if (slv_req_i.r_ready) begin
              // Acknowledge downstream.
              rsp_ready       = 1'b1;
            end else begin
              // Wait for upstream to become ready.
              r_state_d = RWait;
            end
          end
        end
      end
      RWait: begin
        slv_rsp_o.r.last   = r_last_q;
        slv_rsp_o.r_valid  = rsp_valid;
        if (rsp_valid && slv_req_i.r_ready) begin
          rsp_ready       = 1'b1;
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

endmodule

































/// Internal module of [`axi_burst_splitter`](module.axi_burst_splitter) to order transactions.
module axi_burst_splitter_table #(
  parameter int unsigned MaxTxns    = 0,
  parameter int unsigned IdWidth    = 0,
  parameter type         metadata_t = logic,
  parameter type         id_t       = logic [IdWidth-1:0]
) (
  input  logic          clk_i,
  input  logic          rst_ni,

  input  id_t           alloc_id_i,
  input  axi_pkg::len_t alloc_len_i,
  input  metadata_t     alloc_meta_i,
  input  logic          alloc_req_i,
  output logic          alloc_gnt_o,

  input  id_t           cnt_id_i,
  output axi_pkg::len_t cnt_len_o,
  output metadata_t     cnt_meta_o,
  input  logic          cnt_set_err_i,
  output logic          cnt_err_o,
  input  logic          cnt_dec_i,
  input  logic          cnt_req_i,
  output logic          cnt_gnt_o
);
  localparam int unsigned CntIdxWidth = (MaxTxns > 1) ? $clog2(MaxTxns) : 32'd1;
  typedef logic [CntIdxWidth-1:0]         cnt_idx_t;
  typedef logic [$bits(axi_pkg::len_t):0] cnt_t;
  logic [MaxTxns-1:0]  cnt_dec, cnt_free, cnt_set, err_d, err_q;
  cnt_t                cnt_inp;
  cnt_t [MaxTxns-1:0]  cnt_oup;
  cnt_idx_t            cnt_free_idx, cnt_r_idx;
  for (genvar i = 0; i < MaxTxns; i++) begin : gen_cnt
    counter #(
      .WIDTH ( $bits(cnt_t) )
    ) i_cnt (
      .clk_i,
      .rst_ni,
      .clear_i    ( 1'b0       ),
      .en_i       ( cnt_dec[i] ),
      .load_i     ( cnt_set[i] ),
      .down_i     ( 1'b1       ),
      .d_i        ( cnt_inp    ),
      .q_o        ( cnt_oup[i] ),
      .overflow_o (            )  // not used
    );
    assign cnt_free[i] = (cnt_oup[i] == '0);
  end
  assign cnt_inp = {1'b0, alloc_len_i} + 1;

  lzc #(
    .WIDTH  ( MaxTxns ),
    .MODE   ( 1'b0    )  // start counting at index 0
  ) i_lzc (
    .in_i    ( cnt_free     ),
    .cnt_o   ( cnt_free_idx ),
    .empty_o (              )
  );

  // Metadata
  metadata_t [MaxTxns-1:0]  metadata;
  always_ff @(posedge clk_i or negedge rst_ni) begin : proc_metadata
    if(~rst_ni) begin
      metadata <= '0;
    end else if (alloc_req_i & alloc_gnt_o) begin
      metadata[cnt_free_idx] <= alloc_meta_i;
    end
  end
  assign cnt_meta_o = metadata[cnt_r_idx];

  logic idq_inp_req, idq_inp_gnt,
        idq_oup_gnt, idq_oup_valid, idq_oup_pop;
  id_queue #(
    .ID_WIDTH ( $bits(id_t) ),
    .CAPACITY ( MaxTxns     ),
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
    .exists_o         (/* keep open */),
    .exists_gnt_o     (/* keep open */),
    .oup_id_i         ( cnt_id_i      ),
    .oup_pop_i        ( idq_oup_pop   ),
    .oup_req_i        ( cnt_req_i     ),
    .oup_data_o       ( cnt_r_idx     ),
    .oup_data_valid_o ( idq_oup_valid ),
    .oup_gnt_o        ( idq_oup_gnt   )
  );
  assign idq_inp_req = alloc_req_i & alloc_gnt_o;
  assign alloc_gnt_o = idq_inp_gnt & |(cnt_free);
  assign cnt_gnt_o   = idq_oup_gnt & idq_oup_valid;
  logic [8:0] read_len;
  assign read_len    = cnt_oup[cnt_r_idx] - 1;
  assign cnt_len_o   = read_len[7:0];

  assign idq_oup_pop = cnt_req_i & cnt_gnt_o & cnt_dec_i & (cnt_len_o == 8'd0);
  always_comb begin
    cnt_dec            = '0;
    cnt_dec[cnt_r_idx] = cnt_req_i & cnt_gnt_o & cnt_dec_i;
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
