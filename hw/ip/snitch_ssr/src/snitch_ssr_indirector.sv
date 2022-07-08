// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Paul Scheffler <paulsc@iis.ee.ethz.ch>

// Indirection datapath for the SSR address generator.

`include "common_cells/registers.svh"
`include "common_cells/assertions.svh"

module snitch_ssr_indirector import snitch_ssr_pkg::*; #(
  parameter ssr_cfg_t Cfg = '0,
  parameter int unsigned AddrWidth = 0,
  parameter int unsigned DataWidth = 0,
  parameter type tcdm_req_t   = logic,
  parameter type tcdm_rsp_t   = logic,
  parameter type tcdm_user_t  = logic,
  parameter type isect_slv_req_t = logic,
  parameter type isect_slv_rsp_t = logic,
  parameter type isect_mst_req_t = logic,
  parameter type isect_mst_rsp_t = logic,
  /// Derived parameters *Do not override*
  parameter int unsigned BytecntWidth = $clog2(DataWidth/8),
  parameter type addr_t     = logic [AddrWidth-1:0],
  parameter type data_t     = logic [DataWidth-1:0],
  parameter type data_bte_t = logic [DataWidth/8-1:0][7:0],
  parameter type strb_t     = logic [DataWidth/8-1:0],
  parameter type bytecnt_t  = logic [BytecntWidth-1:0],
  parameter type index_t    = logic [Cfg.IndexWidth-1:0],
  parameter type pointer_t  = logic [Cfg.PointerWidth-1:0],
  parameter type shift_t    = logic [Cfg.ShiftWidth-1:0],
  parameter type idx_size_t = logic [$clog2($clog2(DataWidth/8)+1)-1:0]
) (
  input  logic      clk_i,
  input  logic      rst_ni,
  // Index fetch ports
  output tcdm_req_t idx_req_o,
  input  tcdm_rsp_t idx_rsp_i,
  // With intersector interfaces
  output isect_slv_req_t isect_slv_req_o,
  input  isect_slv_rsp_t isect_slv_rsp_i,
  output isect_mst_req_t isect_mst_req_o,
  input  isect_mst_rsp_t isect_mst_rsp_i,
  // With config interface
  input  bytecnt_t  cfg_offs_next_i,
  input  logic      cfg_done_i,
  input  logic      cfg_indir_i,
  input  logic      cfg_isect_slv_i,    // Whether to consume indices from intersector
  input  logic      cfg_isect_mst_i,    // Whether to emit indices to intersector
  input  logic      cfg_isect_slv_ena_i,  // Whether to wait for connected slave with emission
  input  idx_size_t cfg_size_i,
  input  pointer_t  cfg_base_i,
  input  shift_t    cfg_shift_i,
  input  idx_flags_t  cfg_flags_i,
  output index_t    cfg_idx_isect_o,
  // With natural iterator level 0 (upstream)
  input  pointer_t  natit_pointer_i,
  output logic      natit_ready_o,
  input  logic      natit_done_i,       // Keep high, deassert with cfg_done_i
  input  bytecnt_t  natit_boundoffs_i,  // Additional byte offset incurred by subword bound
  output logic      natit_extraword_o,  // Emit additional index word address if bounds require it
  // To address generator output (downstream)
  output pointer_t  mem_pointer_o,
  output logic      mem_last_o,         // Whether pointer emitted is last in job (indirection)
  output logic      mem_zero_o,         // Whether to inject a zero value; overrules pointer!
  output logic      mem_done_o,         // Whether to end job without emitting pointer (inters.)
  output logic      mem_valid_o,
  input  logic      mem_ready_i
);

  // Address used for external requests
  addr_t  idx_addr;

  // Index used in shift-and-add and emitted to address generator
  index_t mem_idx;
  logic   mem_skip;

  // Intersection index counter
  logic   idx_isect_ena;
  index_t idx_isect_q;

  // Index byte (serializer/deserializer) counter
  logic     idx_bytecnt_ena;
  bytecnt_t idx_bytecnt_d, idx_bytecnt_q;
  bytecnt_t idx_bytecnt_next;
  logic     idx_bytecnt_rovr, idx_bytecnt_rovr_q;

  // Index port handshakes
  logic idx_q_hs, idx_p_hs;
  assign idx_q_hs = idx_req_o.q_valid & idx_rsp_i.q_ready;
  assign idx_p_hs = idx_rsp_i.p_valid;

  // Output port handshake
  logic mem_hs;
  assign mem_hs = mem_valid_o & mem_ready_i;

  if (Cfg.IsectSlave) begin : gen_isect_slave

    // Write data coalescing
    logic       idx_word_valid_d, idx_word_valid_q, idx_word_clr;
    strb_t      idx_strb_base, idx_strb_incr;
    strb_t      idx_strb_d, idx_strb_q;
    data_bte_t  idx_data_mask, idx_data_shifted;
    data_bte_t  idx_data_d, idx_data_q;

    // Last index handshaked, waiting for new job
    logic done_pending_q;

    // Data from intersector
    index_t isect_slv_idx;
    logic   isect_slv_done;
    logic   isect_slv_valid, isect_slv_ready;
    logic   isect_slv_hs;

    // Handshaking at request egresses
    logic idx_req_stall;

    // Decoupling done FIFO
    logic done_in_ready;
    logic done_out_valid, done_out_ready;
    logic done_out;

    // Index TCDM request (write-only)
    assign idx_req_o.q = '{addr: idx_addr, write: 1'b1,
        strb: idx_strb_q, data: idx_data_q, amo: reqrsp_pkg::AMONone, default: '0};

    // Write index word when it is complete or when done is popped
    assign idx_req_o.q_valid = idx_word_valid_q;

    // Draw new index data address on each write request
    assign natit_ready_o = idx_q_hs;

    // Handshake at intersector interface before timing cut
    logic isect_slv_up_hs, isect_cnt_swap;
    index_t isect_cnt;
    assign isect_slv_up_hs = isect_slv_rsp_i.valid & isect_slv_req_o.ready;
    assign isect_cnt_swap  = isect_slv_up_hs & isect_slv_rsp_i.done;
    `FFLARN(cfg_idx_isect_o, isect_cnt, isect_cnt_swap, '0, clk_i, rst_ni)

    // Counter for number of elements emitted by intersector
    counter #(
      .WIDTH            ( Cfg.IndexWidth ),
      .STICKY_OVERFLOW  ( 1'b0 )
    ) i_isect_counter (
      .clk_i,
      .rst_ni,
      .clear_i    ( isect_cnt_swap  ),
      .en_i       ( isect_slv_up_hs ),
      .load_i     ( '0  ),
      .down_i     ( '0  ),
      .d_i        ( '0  ),
      .q_o        ( isect_cnt ),
      .overflow_o (     )
    );

    // Cut timing paths from intersector slave port
    spill_register #(
      .T        ( logic [Cfg.IndexWidth:0] ),
      .Bypass   ( Cfg.IsectSlaveSpill   )
      ) i_spill_slv_idx (
      .clk_i,
      .rst_ni,
      .valid_i  ( isect_slv_rsp_i.valid ),
      .ready_o  ( isect_slv_req_o.ready ),
      .data_i   ( {isect_slv_rsp_i.idx, isect_slv_rsp_i.done} ),
      .valid_o  ( isect_slv_valid ),
      .ready_i  ( isect_slv_ready ),
      .data_o   ( {isect_slv_idx, isect_slv_done} )
    );

    // Ready to write indices memory not stalled, FIFO ready, and job not done
    assign idx_req_stall    = idx_req_o.q_valid & ~idx_rsp_i.q_ready;
    assign isect_slv_ready  = ~idx_req_stall & done_in_ready & ~done_pending_q;

    // Advance byte counter on index pop unless done
    assign isect_slv_hs     = isect_slv_valid & isect_slv_ready;
    assign idx_bytecnt_ena  = isect_slv_hs & ~isect_slv_done;

    // Advance to next job in upstream address gen once done handshaked;
    // Swap indirection-related shadowed registers at the same time.
    logic cfg_indir_next;
    assign cfg_indir_next = cfg_isect_slv_i & isect_slv_hs & isect_slv_done;

    // Track when the last index word was received and we wait for upstream termination
    `FFLARNC(done_pending_q, 1'b1, cfg_indir_next, cfg_done_i, 1'b0, clk_i, rst_ni)

    // Create coalescing masks
    assign idx_strb_base    = ~({(DataWidth/8){1'b1}} << (1 << cfg_size_i));
    assign idx_strb_incr    = idx_strb_base << idx_bytecnt_q;
    assign idx_data_mask    = ~({(DataWidth){1'b1}} << (8 << cfg_size_i)) << {idx_bytecnt_q, 3'b0};
    assign idx_data_shifted = data_t'(isect_slv_idx) << {idx_bytecnt_q, 3'b0};

    // Coalesce indices to data words to be written to memory
    assign idx_data_d = (idx_data_q & ~idx_data_mask) | (idx_data_shifted & idx_data_mask);
    assign idx_strb_d = idx_bytecnt_rovr_q ? idx_strb_base : (idx_strb_q | idx_strb_incr);

    // Complete word when uppermost index or last index (delayed due to coalescing regs).
    // On every word transmitted: clear validity *unless* new word loaded.
    assign idx_word_valid_d = idx_bytecnt_rovr | (~idx_bytecnt_rovr_q & isect_slv_done);
    assign idx_word_clr     = idx_q_hs & ~isect_slv_hs;

    `FFLARN(idx_data_q, idx_data_d, idx_bytecnt_ena,  1'b0, clk_i, rst_ni)
    `FFLARN(idx_strb_q, idx_strb_d, idx_bytecnt_ena,  1'b0, clk_i, rst_ni)
    `FFLARNC(idx_word_valid_q, idx_word_valid_d, isect_slv_hs, idx_word_clr, 1'b0, clk_i, rst_ni)

    // Track done and decouple address emission from index write
    stream_fifo #(
      .FALL_THROUGH ( 0 ),
      .DATA_WIDTH   ( 1 ),
      .DEPTH        ( Cfg.IsectSlaveCredits )
    ) i_done_fifo (
      .clk_i,
      .rst_ni,
      .flush_i    ( 1'b0 ),
      .testmode_i ( 1'b0 ),
      .usage_o    (  ),
      .data_i     ( isect_slv_done  ),
      .valid_i    ( isect_slv_hs    ),
      .ready_o    ( done_in_ready   ),
      .data_o     ( done_out        ),
      .valid_o    ( done_out_valid  ),
      .ready_i    ( done_out_ready  )
    );

    assign done_out_ready = mem_ready_i;

    // Not an intersection master; termination is externally controlled
    assign isect_mst_req_o    = '0;
    assign natit_extraword_o  = 1'b0;

    // Intersector slave enable signals
    assign isect_slv_req_o.ena  = ~(done_pending_q | cfg_done_i) & cfg_isect_slv_i;
    assign idx_isect_ena        = done_out_valid & done_out_ready & ~done_out;

    // Output to address generator
    assign mem_idx      = idx_isect_q;
    assign mem_skip     = 1'b0;
    assign mem_zero_o   = 1'b0;
    assign mem_last_o   = 1'b0;
    assign mem_done_o   = done_out;
    assign mem_valid_o  = done_out_valid;

  end else begin : gen_no_isect_slave

    // Natural iterator
    logic   natit_ena;

    // Index FIFO signals
    logic   idx_fifo_empty;
    logic   idx_fifo_pop;
    data_t  idx_fifo_out;

    // Index serializer
    data_t  idx_ser_mask;
    index_t idx_ser_out;
    logic   idx_ser_last;
    logic   idx_ser_valid;

    // Last word & index tracking
    logic     last_word;
    bytecnt_t first_idx_byteoffs;
    bytecnt_t last_idx_byteoffs;

    // Intersector master
    logic isect_mst_hs;
    logic isect_mst_dom;
    logic isect_mst_doi_q;
    logic isect_mst_blk_q;
    logic isect_idx_lockin;

    // Index credit counter
    logic idx_cred_left, idx_cred_crit;

    if (Cfg.IsectMaster) begin : gen_isect_master

      logic idx_has_inflight;

      // Count inflight index words
      snitch_ssr_credit_counter #(
        .NumCredits       ( Cfg.IndexCredits ),
        .InitCreditEmpty  ( 1 )
      ) i_mem_inflight_counter (
        .clk_i,
        .rst_ni,
        .credit_o      ( ),
        .credit_give_i ( idx_q_hs ),
        .credit_take_i ( idx_p_hs ),
        .credit_init_i ( 1'b0 ),
        .credit_left_o ( idx_has_inflight ),
        .credit_crit_o ( ),
        .credit_full_o ( )
      );

      // Master interface handshake
      assign isect_mst_hs = isect_mst_req_o.valid & isect_mst_rsp_i.ready;

      // Launch master termination cleanup when handshaking last index out or done in
      logic isect_mst_cln_init;
      assign isect_mst_cln_init = isect_mst_hs &
          (isect_mst_rsp_i.done | (~cfg_flags_i.merge & idx_ser_last));

      // Generate done flag for output to address generator.
      // isect_mst_domp_q denotes the state while waiting for inflight index words; used
      // only during intersection and ignored during merging as no idx words need flushing.
      // Do not advance intersection flush in request lock-in (i.e. idx_req_o.q_valid is high).
      logic isect_mst_dom_set, isect_mst_dom_clr;
      logic isect_mst_domp_q, isect_mst_dom_q;
      assign isect_mst_dom_set = cfg_flags_i.merge ? isect_mst_cln_init :
          (isect_mst_domp_q & ~(idx_req_o.q_valid | idx_has_inflight));
      assign isect_mst_dom_clr = mem_hs & isect_mst_dom_q;
      `FFLARNC(isect_mst_domp_q, 1'b1, isect_mst_cln_init, isect_mst_dom_q, 1'b0, clk_i, rst_ni)
      `FFLARNC(isect_mst_dom_q, 1'b1, isect_mst_dom_set, isect_mst_dom_clr, 1'b0, clk_i, rst_ni)
      assign isect_mst_dom = isect_mst_dom_q;

      // Generate done flag for intersector interface
      logic isect_mst_doi_set, isect_mst_doi_clr;
      assign isect_mst_doi_set = cfg_flags_i.merge ? idx_ser_last : isect_mst_cln_init;
      assign isect_mst_doi_clr = isect_mst_hs & isect_mst_rsp_i.done;
      `FFLARNC(isect_mst_doi_q, 1'b1, isect_mst_doi_set, isect_mst_doi_clr, 1'b0, clk_i, rst_ni)

      // Block index pipeline during cleanup
      `FFLARNC(isect_mst_blk_q, 1'b1, isect_mst_cln_init, cfg_done_i, 1'b0, clk_i, rst_ni)

      // Once locked in, keep any index requests asserted even if starting cleanup
      logic isect_idx_lockin_set;
      assign isect_idx_lockin_set = isect_mst_cln_init & idx_req_o.q_valid;
      `FFLARNC(isect_idx_lockin, 1'b1, isect_idx_lockin_set, idx_q_hs, 1'b0, clk_i, rst_ni)

    end else begin : gen_no_isect_master
      assign isect_mst_hs     = 1'b0;
      assign isect_mst_dom    = 1'b0;
      assign isect_mst_doi_q  = 1'b0;
      assign isect_mst_blk_q  = 1'b0;
      assign isect_idx_lockin = 1'b0;
    end

    // Index TCDM request (read-only)
    assign idx_req_o.q = '{addr: idx_addr, amo: reqrsp_pkg::AMONone, default: '0};

    // Index handshaking
    assign natit_ena          = cfg_indir_i & idx_cred_left & ~isect_mst_blk_q & ~natit_done_i;
    assign idx_req_o.q_valid  = natit_ena | isect_idx_lockin;
    assign natit_ready_o      = natit_ena & idx_rsp_i.q_ready;

    // Index FIFO: stores full unserialized words.
    fifo_v3 #(
      .FALL_THROUGH ( 1'b0              ),
      .DATA_WIDTH   ( DataWidth         ),
      .DEPTH        ( Cfg.IndexCredits  )
    ) i_idx_fifo (
      .clk_i,
      .rst_ni,
      .flush_i    ( isect_mst_blk_q   ),
      .testmode_i ( 1'b0              ),
      .full_o     (  ),                     // Credit counter prevents overflows
      .empty_o    ( idx_fifo_empty    ),
      .usage_o    (  ),
      .data_i     ( idx_rsp_i.p.data  ),
      .push_i     ( idx_p_hs          ),
      .data_o     ( idx_fifo_out      ),
      .pop_i      ( idx_fifo_pop      )
    );

    // Index counter: keeps track of the number of memory requests in flight
    // to ensure that the FIFO does not overfill.
    snitch_ssr_credit_counter #(
      .NumCredits       ( Cfg.IndexCredits ),
      .InitCreditEmpty  ( 0 )
      ) i_credit_counter (
      .clk_i,
      .rst_ni,
      .credit_o      (  ),
      .credit_give_i ( idx_fifo_pop     ),
      .credit_take_i ( idx_q_hs         ),
      .credit_init_i ( isect_mst_blk_q  ),
      .credit_left_o ( idx_cred_left    ),
      .credit_crit_o ( idx_cred_crit    ),
      .credit_full_o ( )
    );

    // The initial byte offset and byte offset of the index array bound determine
    // the final index offset and whether an additional index word is needed.
    assign last_word          = idx_cred_crit & natit_done_i;
    assign first_idx_byteoffs = bytecnt_t'(natit_pointer_i);
    assign {natit_extraword_o, last_idx_byteoffs} = first_idx_byteoffs + natit_boundoffs_i;

    // Move on to next FIFO word if not stalled and at last index in word.
    assign idx_fifo_pop = idx_bytecnt_ena &
        (last_word ? idx_bytecnt_q == last_idx_byteoffs : idx_bytecnt_rovr);

    // Serialize indices: shift left by current byte offset, then mask out index of given size.
    assign idx_ser_mask   = ~({DataWidth{1'b1}} << (8 << cfg_size_i));
    assign idx_ser_out    = (idx_fifo_out >> {idx_bytecnt_q, 3'b0}) & idx_ser_mask;
    assign idx_ser_last   = last_word & idx_fifo_pop & ~isect_mst_blk_q;
    assign idx_ser_valid  = ~idx_fifo_empty;

    // Not an intersection slave: tie off slave requests and count register
    assign isect_slv_req_o = '{ena: '0, ready: '0};
    assign cfg_idx_isect_o = '0;

    // Advance whenever pointer and not flag emitted, or if skipped
    assign idx_bytecnt_ena = (mem_hs & ~mem_zero_o & ~mem_done_o) | mem_skip;

    // Output index, validity, and zero flag depend on whether we intersect
    always_comb begin
      if (Cfg.IsectMaster & cfg_isect_mst_i) begin
        isect_mst_req_o = '{
            merge:    cfg_flags_i.merge,
            slv_ena:  cfg_isect_slv_ena_i,
            idx:      idx_ser_out,
            done:     isect_mst_doi_q,
            valid:    isect_mst_doi_q | (idx_ser_valid & mem_ready_i)
            };
        idx_isect_ena   = idx_bytecnt_ena;
        mem_idx         = idx_isect_q;
        mem_skip        = isect_mst_hs & isect_mst_rsp_i.skip;
        mem_zero_o      = isect_mst_rsp_i.zero;
        mem_done_o      = isect_mst_dom;
        mem_last_o      = 1'b0;
        mem_valid_o     = isect_mst_dom |
            (isect_mst_hs & ~isect_mst_rsp_i.skip & ~isect_mst_rsp_i.done);
      end else begin
        isect_mst_req_o = '0;
        idx_isect_ena   = 1'b0;
        mem_idx         = idx_ser_out;
        mem_skip        = 1'b0;
        mem_zero_o      = 1'b0;
        mem_done_o      = 1'b0;
        mem_last_o      = idx_ser_last;
        mem_valid_o     = idx_ser_valid;
      end
    end

  end

  // Intersection index counter
  if (Cfg.IsectMaster | Cfg.IsectSlave) begin : gen_isect_ctr
    index_t idx_isect_d;
    always_comb begin
      idx_isect_d = idx_isect_q;
      if (cfg_done_i)         idx_isect_d = '0;
      else if (idx_isect_ena) idx_isect_d = idx_isect_q + 1;
    end
    `FFARN(idx_isect_q, idx_isect_d, '0, clk_i, rst_ni)
  end else begin : gen_no_isect_ctr
    assign idx_isect_q = '0;
  end

  // Use external natural iterator; mask lower bits to fetch only entire, aligned words.
  assign idx_addr = {natit_pointer_i[Cfg.PointerWidth-1:BytecntWidth], {BytecntWidth{1'b0}}};

  // Shift and emit indices
  assign mem_pointer_o = cfg_base_i + ((pointer_t'(mem_idx) << BytecntWidth) << cfg_shift_i);

  // Byte counter advancing the byte offset
  always_comb begin
    idx_bytecnt_d = idx_bytecnt_q;
    // Set the initial byte offset (upbeat) before job starts, i.e. while done register set.
    if (cfg_done_i)           idx_bytecnt_d = cfg_offs_next_i;
    else if (idx_bytecnt_ena) idx_bytecnt_d = idx_bytecnt_next;
  end

  `FFARN(idx_bytecnt_q, idx_bytecnt_d, '0, clk_i, rst_ni)

  assign idx_bytecnt_next = idx_bytecnt_q + bytecnt_t'(1 << cfg_size_i);

  // Track byte counter rollover and whether it just happened
  assign idx_bytecnt_rovr   = (idx_bytecnt_next == '0);
  assign idx_bytecnt_rovr_q = (idx_bytecnt_q    == '0);   // TODO: PPA vs FF?

endmodule
