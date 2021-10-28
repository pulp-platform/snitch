// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Fabian Schuiki <fschuiki@iis.ee.ethz.ch>
// Author: Paul Scheffler <paulsc@iis.ee.ethz.ch>

`include "common_cells/registers.svh"

module snitch_ssr_addr_gen import snitch_ssr_pkg::*; #(
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
  parameter type pointer_t  = logic [Cfg.PointerWidth-1:0],
  parameter type index_t    = logic [Cfg.IndexWidth-1:0],
  parameter type bytecnt_t  = logic [BytecntWidth-1:0],
  parameter type idx_size_t = logic [$clog2($clog2(DataWidth/8)+1)-1:0]
) (
  input  logic        clk_i,
  input  logic        rst_ni,

  // Index fetch ports
  output tcdm_req_t   idx_req_o,
  input  tcdm_rsp_t   idx_rsp_i,

  // Interface with intersector
  output isect_slv_req_t isect_slv_req_o,
  input  isect_slv_rsp_t isect_slv_rsp_i,
  output isect_mst_req_t isect_mst_req_o,
  input  isect_mst_rsp_t isect_mst_rsp_i,

  input  logic [4:0]  cfg_word_i,
  output logic [31:0] cfg_rdata_o,
  input  logic [31:0] cfg_wdata_i,
  input  logic        cfg_write_i,

  output logic [Cfg.RptWidth-1:0] reg_rep_o,

  output addr_t       mem_addr_o,
  output logic        mem_zero_o,
  output logic        mem_write_o,
  output logic        mem_valid_o,
  input  logic        mem_ready_i,

  input  addr_t       tcdm_start_address_i
);

  // Mask for word-aligned address fields
  localparam logic [31:0] WordAddrMask = {{(32-BytecntWidth){1'b1}}, {(BytecntWidth){1'b0}}};

  pointer_t [Cfg.NumLoops-1:0] stride_q, stride_sd, stride_sq;
  pointer_t pointer_q, pointer_qn, pointer_sd, pointer_sq, pointer_sqn, selected_stride;
  index_t [Cfg.NumLoops-1:0] index_q, index_d, bound_q, bound_sd, bound_sq;
  logic [Cfg.RptWidth-1:0] rep_q, rep_sd, rep_sq;
  logic [Cfg.NumLoops-1:0] loop_enabled;
  logic [Cfg.NumLoops-1:0] loop_last;
  logic enable, done;

  typedef struct packed {
    logic idx_base;
    logic idx_cfg;
    logic [3:0] stride;
    logic [3:0] bound;
    logic rep;
    logic status;
  } write_strobe_t;
  write_strobe_t write_strobe;

  logic alias_strobe;

  cfg_status_upper_t config_q, config_qn, config_sd, config_sq, config_sqn;

  cfg_alias_fields_t alias_fields;

  // Read map for added indirection registers
  typedef struct packed {
    logic [31:0]  idx_isect;
    logic [31:0]  idx_base;
    logic [31:0]  idx_cfg;
  } indir_read_map_t;

  // Signals interfacing with indirection datapath
  indir_read_map_t indir_read_map;
  pointer_t mem_pointer;
  logic mem_last, mem_kill, mem_ptr_hs;
  logic cfg_indir_next;

  // Type for output spill register
  typedef struct packed {
    pointer_t pointer;
    logic     last;
    logic     zero;
    logic     kill;
  } out_spill_t;

  if (Cfg.Indirection) begin : gen_indirection

    // Interface between natural iterator 0 and indirector
    logic natit_base_last_d, natit_base_last_q;
    logic natit_ready;
    logic natit_extraword;
    logic natit_last_word_inflight_q;
    logic natit_done;
    bytecnt_t natit_boundoffs;
    index_t natit_base_bound;
    logic cfg_indir_swap, cfg_isect_consec;

    // Address generation output of indirector
    logic indir_valid;
    pointer_t indir_pointer;
    logic indir_last, indir_zero, indir_kill;

    // Indirector configuration registers
    logic [Cfg.ShiftWidth-1:0]    idx_shift_q, idx_shift_sd, idx_shift_sq;
    logic [Cfg.PointerWidth-1:0]  idx_base_q, idx_base_sd, idx_base_sq;
    idx_size_t                    idx_size_q, idx_size_sd, idx_size_sq;
    idx_flags_t                   idx_flags_q, idx_flags_sd, idx_flags_sq;
    index_t                       idx_isect_sd, idx_isect_sq;

    // Output spill register, if it exists
    out_spill_t spill_in_data;
    logic spill_in_valid, spill_in_ready;
    logic spill_out_valid, spill_out_ready;

    // Config register write
    cfg_idx_ctl_t cfg_wdata_idx_ctl, cfg_rdata_idx_ctl;
    assign cfg_wdata_idx_ctl = cfg_wdata_i;
    always_comb begin
      idx_shift_sd  = idx_shift_sq;
      idx_base_sd   = idx_base_sq;
      idx_size_sd   = idx_size_sq;
      idx_flags_sd  = idx_flags_sq;
      if (write_strobe.idx_cfg) begin
        idx_flags_sd = cfg_wdata_idx_ctl.flags;
        idx_shift_sd = cfg_wdata_idx_ctl.shift;
        idx_size_sd  = cfg_wdata_idx_ctl.size;
      end
      if (write_strobe.idx_base)  idx_base_sd  = cfg_wdata_i & WordAddrMask;
    end

    // Config register read
    assign cfg_rdata_idx_ctl = '{flags: idx_flags_q, shift: idx_shift_q, size: idx_size_q};
    assign indir_read_map = '{
      idx_base:   idx_base_q,
      idx_cfg:    cfg_rdata_idx_ctl,
      idx_isect:  idx_isect_sq
    };

    // Config registers
    `FFARN(idx_shift_sq, idx_shift_sd, '0, clk_i, rst_ni)
    `FFLARN(idx_shift_q, idx_shift_sd, cfg_indir_swap, '0, clk_i, rst_ni)
    `FFARN(idx_base_sq, idx_base_sd, '0, clk_i, rst_ni)
    `FFLARN(idx_base_q, idx_base_sd, cfg_indir_swap, '0, clk_i, rst_ni)
    `FFARN(idx_size_sq, idx_size_sd, '0, clk_i, rst_ni)
    `FFLARN(idx_size_q, idx_size_sd, cfg_indir_swap, '0, clk_i, rst_ni)
    `FFARN(idx_flags_sq, idx_flags_sd, '0, clk_i, rst_ni)
    `FFLARN(idx_flags_q, idx_flags_sd, cfg_indir_swap, '0, clk_i, rst_ni)

    // Intersection index count shadow register (read-only, slave-only)
    if (Cfg.IsectSlave) begin : gen_idx_isect_reg
      logic done_qq, done_rising;
      assign done_rising = config_q.done & ~done_qq;
      `FFARN(done_qq, config_q.done, 1'b0, clk_i, rst_ni)
      `FFLARN(idx_isect_sq, idx_isect_sd, done_rising, '0, clk_i, rst_ni)
    end else begin : gen_no_idx_isect_reg
      assign idx_isect_sq = '0;
    end

    // Delay register for last iteration of base loop, in case additional iteration needed.
    `FFLARNC(natit_base_last_q, natit_base_last_d, enable, natit_done, 1'b0, clk_i, rst_ni)

    // Indicate last iteration (loop 0)
    assign natit_base_bound   = bound_q[0] >> (config_q.indir ? idx_size_t'('1) - idx_size_q : '0);
    assign natit_base_last_d  = (index_q[0] == natit_base_bound);
    assign loop_last[0]       = (natit_extraword ? natit_base_last_q : natit_base_last_d);

    // Track last index word to set downstream last signal and handle word misalignment at end.
    logic config_load;
    assign config_load = enable & done;
    `FFLARNC(natit_last_word_inflight_q, 1'b1, config_load, config_q.done, 1'b0, clk_i, rst_ni)

    // Natural iteration loop 0 is done when last word inflight or address gen done.
    assign natit_done = natit_last_word_inflight_q | config_q.done;

    // Determine word offset incurred by indirect loop bound on loop 0.
    assign natit_boundoffs = bytecnt_t'(bound_q[0]) << idx_size_q;

    // TODO: check when consectuive indirection jobs have similar enough configs to be chained
    assign cfg_isect_consec = 
      (config_sq.dims == config_q.dims) &
      (config_sq.write == config_q.write) &
      (config_sq.indir == config_q.indir);

    // Encapsulated indirection datapath
    snitch_ssr_indirector #(
      .Cfg          ( Cfg         ),
      .AddrWidth    ( AddrWidth   ),
      .DataWidth    ( DataWidth   ),
      .tcdm_req_t   ( tcdm_req_t  ),
      .tcdm_rsp_t   ( tcdm_rsp_t  ),
      .tcdm_user_t  ( tcdm_user_t ),
      .isect_slv_req_t ( isect_slv_req_t ),
      .isect_slv_rsp_t ( isect_slv_rsp_t ),
      .isect_mst_req_t ( isect_mst_req_t ),
      .isect_mst_rsp_t ( isect_mst_rsp_t )
    ) i_snitch_ssr_indirector (
      .clk_i,
      .rst_ni,
      .idx_req_o,
      .idx_rsp_i,
      .isect_slv_req_o,
      .isect_slv_rsp_i,
      .isect_mst_req_o,
      .isect_mst_rsp_i,
      .cfg_done_i          ( config_q.done    ),
      .cfg_offs_next_i     ( pointer_sd[BytecntWidth-1:0] ),
      .cfg_indir_i         ( config_q.indir   ),
      .cfg_isect_slv_i     ( config_q.indir & (config_q.dims == 2'b01)  ),
      .cfg_isect_mst_i     ( config_q.indir & config_q.dims[1]          ),
      .cfg_isect_slv_ena_i ( config_q.indir & (config_q.dims == 2'b11)  ),
      .cfg_size_i          ( idx_size_q       ),
      .cfg_base_i          ( idx_base_q       ),
      .cfg_shift_i         ( idx_shift_q      ),
      .cfg_flags_i         ( idx_flags_q      ),
      .cfg_idx_isect_o     ( idx_isect_sd     ),
      .cfg_indir_swap_o    ( cfg_indir_swap   ),
      .cfg_indir_next_o    ( cfg_indir_next   ),
      .cfg_isect_consec_i  ( cfg_isect_consec ),
      .natit_pointer_i     ( pointer_q        ),
      .natit_ready_o       ( natit_ready      ),
      .natit_done_i        ( natit_done       ),
      .natit_boundoffs_i   ( natit_boundoffs  ),
      .natit_extraword_o   ( natit_extraword  ),
      .mem_pointer_o       ( indir_pointer    ),
      .mem_zero_o          ( indir_zero       ),
      .mem_done_o          ( indir_kill       ),
      .mem_last_o          ( indir_last       ),
      .mem_valid_o         ( indir_valid      ),
      .mem_ready_i         ( spill_in_ready   ),
      .tcdm_start_address_i
    );

    // Multiplex natural and indirection datapaths into spill register (if
    // generated) or directly to address output port.
    always_comb begin
      if (config_q.indir) begin
        spill_in_valid  = indir_valid;
        spill_in_data   = {indir_pointer, indir_last, indir_zero, indir_kill};
        enable          = ~natit_done & natit_ready;
      end else begin
        spill_in_valid  = ~natit_done;
        spill_in_data   = {pointer_q, done, 1'b0, 1'b0};
        enable          = ~natit_done & spill_in_ready;
      end
    end

    // Generate spill register at output to cut timing paths if desired.
    spill_register #(
      .T      ( out_spill_t         ),
      .Bypass ( !Cfg.IndirOutSpill  )
    ) i_out_spill (
      .clk_i,
      .rst_ni,
      .valid_i ( spill_in_valid ),
      .ready_o ( spill_in_ready ),
      .data_i  ( spill_in_data  ),
      .valid_o ( spill_out_valid ),
      .ready_i ( spill_out_ready ),
      .data_o  ( {mem_pointer, mem_last, mem_zero_o, mem_kill} )
    );

    // Do not forward kill signals to data mover
    assign mem_valid_o      = spill_out_valid & ~mem_kill;
    assign spill_out_ready  = mem_ready_i | mem_kill;
    assign mem_ptr_hs       = spill_out_valid & spill_out_ready;

  end else begin : gen_no_indirection

    // Enable the overall count operation if we're not done and the memory
    // interface can make progress.
    assign enable = ~config_q.done & mem_valid_o & mem_ready_i;
    assign mem_valid_o = ~config_q.done;
    assign mem_pointer = pointer_q;
    assign mem_last    = done;
    assign mem_kill    = 1'b0;
    assign mem_ptr_hs  = mem_valid_o & mem_ready_i;
    assign mem_zero_o  = 1'b0;
    assign cfg_indir_next = 1'b0;

    // Tie off the index request port as no indirection
    assign idx_req_o = '0;

    // Loop 0 behaves like all other levels
    assign loop_last[0] = (index_q[0] == bound_q[0]);

  end

  assign mem_write_o  = config_q.write;
  assign mem_addr_o   = {tcdm_start_address_i[AddrWidth-1:Cfg.PointerWidth], mem_pointer};

  // Unpack the configuration address and write signal into a write strobe for
  // the individual registers. Also assign the alias strobe if the address is
  // targeting one of the status register aliases.
  assign write_strobe = (cfg_write_i << cfg_word_i);
  assign alias_strobe = cfg_write_i & (cfg_word_i[$bits(cfg_word_i)-1:$bits(alias_fields)] == '1);
  assign alias_fields = cfg_word_i[0+:$bits(alias_fields)];

  // Generate the loop counters.
  for (genvar i = 0; i < Cfg.NumLoops; i++) begin : gen_loop_counter
    logic index_ena;
    logic index_clear;

    always_comb begin
      stride_sd[i] = stride_sq[i];
      bound_sd[i] = bound_sq[i];
      if (write_strobe.stride[i])
        stride_sd[i] = cfg_wdata_i & WordAddrMask;
      if (write_strobe.bound[i])
        bound_sd[i] = cfg_wdata_i;
    end

    `FFARN(stride_sq[i], stride_sd[i], '0, clk_i, rst_ni)
    `FFLARN(stride_q[i], stride_sd[i], config_q.done, '0, clk_i, rst_ni)
    `FFARN(bound_sq[i], bound_sd[i], '0, clk_i, rst_ni)
    `FFLARN(bound_q[i], bound_sd[i], config_q.done, '0, clk_i, rst_ni)

    assign index_ena = enable & loop_enabled[i];

    assign index_d[i] = index_q[i] + 1;
    assign index_clear = index_ena & loop_last[i];
    `FFLARNC(index_q[i], index_d[i], index_ena, index_clear, '0, clk_i, rst_ni)

    // Indicate last iteration (loops > 0); base loop handled differently in indirection
    if (i > 0) begin : gen_loop_last_upper
      assign loop_last[i] = config_q.indir ? 1'b1: (index_q[i] == bound_q[i] || config_q.dims < i);
    end
  end

  // Remaining registers.
  always_comb begin
    rep_sd = rep_sq;
    if (write_strobe.rep)
      rep_sd = cfg_wdata_i;
  end

  `FFARN(rep_sq, rep_sd, '0, clk_i, rst_ni)
  `FFLARN(rep_q, rep_sd, config_q.done, '0, clk_i, rst_ni)

  assign reg_rep_o = rep_q;

  // Enable a loop if they are enabled globally, and the next inner loop is at
  // its maximum.
  always_comb begin
    logic e;
    e = 1;
    for (int i = 0; i < Cfg.NumLoops; i++) begin
      loop_enabled[i] = e;
      e &= loop_last[i];
    end
    done = e;
  end

  // Pick the stride of the highest enabled loop.
  always_comb begin
    logic [Cfg.NumLoops-1:0] outermost;
    outermost = loop_enabled & ~(loop_enabled >> 1);
    selected_stride = '0;
    if (Cfg.Indirection && config_q.indir)
      selected_stride = DataWidth/8;
    else for (int i = 0; i < Cfg.NumLoops; i++)
      selected_stride |= outermost[i] ? stride_q[i] : '0;
  end

  // Advance the pointer by the selected stride if enabled.
  always_comb begin
    pointer_sd = pointer_sq;
    config_sd = config_sq;
    if (write_strobe.status) begin
      pointer_sd = cfg_wdata_i;
      config_sd = cfg_wdata_i[31-:$bits(config_sq)];
    end else if (alias_strobe) begin
      pointer_sd = cfg_wdata_i;
      config_sd.done = 0;
      config_sd.write = alias_fields.write;
      config_sd.dims = alias_fields.dims;
      config_sd.indir = ~alias_fields.no_indir;
    end
  end

  `FFARN(pointer_q, pointer_qn, '0, clk_i, rst_ni)
  `FFARN(pointer_sq, pointer_sqn, '0, clk_i, rst_ni)
  `FFARN(config_q, config_qn, '{done: 1, default: '0}, clk_i, rst_ni)
  `FFARN(config_sq, config_sqn, '{done: 1, default: '0}, clk_i, rst_ni)

  always_comb begin
    pointer_qn  = pointer_q;
    config_qn   = config_q;
    pointer_sqn = pointer_sd;
    config_sqn  = config_sd;
    if (config_q.done) begin
      pointer_qn  = pointer_sd;
      config_qn   = config_sd;
      config_sqn.done = 1;
    end else begin
      if (enable)
        pointer_qn = pointer_q + selected_stride;
      if (mem_ptr_hs)
        config_qn.done = mem_last | mem_kill;
      if (cfg_indir_next)
        config_qn.done = 1;
    end
  end

  typedef struct packed {
    indir_read_map_t indir_read_map;
    logic [3:0][31:0] stride;
    logic [3:0][31:0] bound;
    logic [31:0] rep;
    logic [31:0] status;
  } read_map_t;

  // Configuration read access.
  always_comb begin
    read_map_t read_map;

    read_map.indir_read_map = Cfg.Indirection ? indir_read_map : '0;
    read_map.status = pointer_q;
    read_map.status[31-:$bits(config_q)] = config_q;
    read_map.rep = rep_q;
    read_map.bound = '0;
    read_map.stride = '0;
    for (int i = 0; i < Cfg.NumLoops; i++) begin
      read_map.bound[i] = bound_q[i];
      read_map.stride[i] = stride_q[i];
    end

    cfg_rdata_o = read_map[(cfg_word_i*32)+:32];
  end

endmodule
