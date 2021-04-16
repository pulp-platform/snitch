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
  /// Derived parameters *Do not override*
  parameter int unsigned DimWidth     = $clog2(Cfg.NumLoops),
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

  input  logic [4:0]  cfg_word_i,
  output logic [31:0] cfg_rdata_o,
  input  logic [31:0] cfg_wdata_i,
  input  logic        cfg_write_i,

  output logic [Cfg.RptWidth-1:0] reg_rep_o,

  output addr_t       mem_addr_o,
  output logic        mem_write_o,
  output logic        mem_valid_o,
  input  logic        mem_ready_i,

  input  addr_t       tcdm_start_address_i
);

  // Mask for word-aligned address fields
  localparam logic [31:0] WordAddrMask = {{(32-BytecntWidth){1'b1}}, {(BytecntWidth){1'b0}}};

  pointer_t [Cfg.NumLoops-1:0] stride_q, stride_sd, stride_sq;
  pointer_t pointer_q, pointer_qn, pointer_sd, pointer_sq, pointer_sqn, selected_stride;
  index_t [Cfg.NumLoops-1:0] index_q, bound_q, bound_sd, bound_sq;
  logic [Cfg.RptWidth-1:0] rep_q, rep_sd, rep_sq;
  logic [Cfg.NumLoops-1:0] loop_enabled;
  logic [Cfg.NumLoops-1:0] loop_last;
  logic enable, done;

  typedef struct packed {
    logic idx_shift;
    logic idx_base;
    logic idx_size;
    logic [Cfg.NumLoops-1:0] stride;
    logic [Cfg.NumLoops-1:0] bound;
    logic rep;
    logic status;
  } write_strobe_t;
  write_strobe_t write_strobe;

  logic alias_strobe;

  typedef struct packed {
    logic done;
    logic write;
    logic [DimWidth-1:0] dims;
    logic indir;
  } config_t;
  config_t config_q, config_qn, config_sd, config_sq, config_sqn;

  typedef struct packed {
    logic no_indir;       // Inverted as aliases aligned at upper address edge
    logic write;
    logic [DimWidth-1:0] dims;
  } alias_fields_t;

  alias_fields_t alias_fields;

  // Read map for added indirection registers
  typedef struct packed {
    logic [31:0]  idx_shift;
    logic [31:0]  idx_base;
    logic [31:0]  idx_size;
  } indir_read_map_t;

  // Signals interfacing with indirection datapath
  indir_read_map_t indir_read_map;
  pointer_t mem_pointer;
  logic mem_last;

  if (Cfg.Indirection) begin : gen_indirection

    // Type for output spill register
    typedef struct packed {
      pointer_t pointer;
      logic     last;
    } out_spill_t;

    // Interface between natural iterator 0 and indirector
    logic natit_base_last_d, natit_base_last_q;
    logic natit_ready;
    logic natit_extraword;
    logic natit_last_word_inflight_q;
    logic natit_done;
    bytecnt_t natit_boundoffs;
    index_t natit_base_bound;

    // Address generation output of indirector
    logic indir_valid;
    pointer_t indir_pointer;
    logic indir_last;

    // Indirector configuration registers
    logic [Cfg.ShiftWidth-1:0]    idx_shift_q, idx_shift_sd, idx_shift_sq;
    logic [Cfg.PointerWidth-1:0]  idx_base_q, idx_base_sd, idx_base_sq;
    idx_size_t                    idx_size_q, idx_size_sd, idx_size_sq;

    // Output spill register, if it exists
    out_spill_t spill_in_data;
    logic spill_in_valid, spill_in_ready;

    // Config register write
    always_comb begin
      idx_shift_sd  = idx_shift_sq;
      idx_base_sd   = idx_base_sq;
      idx_size_sd   = idx_size_sq;
      if (write_strobe.idx_shift) idx_shift_sd = cfg_wdata_i;
      if (write_strobe.idx_base)  idx_base_sd  = cfg_wdata_i & WordAddrMask;
      if (write_strobe.idx_size)  idx_size_sd  = cfg_wdata_i;
    end

    // Config register read
    assign indir_read_map = '{idx_shift_q, idx_base_q, idx_size_q};

    // Config registers
    `FFARN(idx_shift_sq, idx_shift_sd, '0, clk_i, rst_ni)
    `FFLARN(idx_shift_q, idx_shift_sd, config_q.done, '0, clk_i, rst_ni)
    `FFARN(idx_base_sq, idx_base_sd, '0, clk_i, rst_ni)
    `FFLARN(idx_base_q, idx_base_sd, config_q.done, '0, clk_i, rst_ni)
    `FFARN(idx_size_sq, idx_size_sd, '0, clk_i, rst_ni)
    `FFLARN(idx_size_q, idx_size_sd, config_q.done, '0, clk_i, rst_ni)

    // Delay register for last iteration of base loop, in case additional iteration needed.
    `FFLARNC(natit_base_last_q, natit_base_last_d, enable, natit_done, 1'b0, clk_i, rst_ni)

    // Indicate last iteration (loop 0)
    assign natit_base_bound   = bound_q[0] >> (config_q.indir ? idx_size_t'('1) - idx_size_q : '0);
    assign natit_base_last_d  = (index_q[0] == natit_base_bound);
    assign loop_last[0]       = (natit_extraword ? natit_base_last_q : natit_base_last_d);

    // Track last index word to set downstream last signal and handle word misalignment at end.
    `FFLARNC(natit_last_word_inflight_q, 1'b1, enable & done, config_q.done, 1'b0, clk_i, rst_ni)

    // Natural iteration loop 0 is done when last word inflight or address gen done.
    assign natit_done = natit_last_word_inflight_q | config_q.done;

    // Determine word offset incurred by indirect loop bound on loop 0.
    assign natit_boundoffs = bytecnt_t'(bound_q[0]) << idx_size_q;

    // Encapsulated indirection datapath
    snitch_ssr_indirector #(
      .Cfg          ( Cfg         ),
      .AddrWidth    ( AddrWidth   ),
      .DataWidth    ( DataWidth   ),
      .tcdm_req_t   ( tcdm_req_t  ),
      .tcdm_rsp_t   ( tcdm_rsp_t  ),
      .tcdm_user_t  ( tcdm_user_t )
    ) i_snitch_ssr_indirector (
      .clk_i,
      .rst_ni,
      .idx_req_o,
      .idx_rsp_i,
      .cfg_launch_i        ( write_strobe.status | alias_strobe ),
      .cfg_wdata_lo_i      ( cfg_wdata_i[BytecntWidth-1:0]      ),
      .cfg_indir_i         ( config_q.indir   ),
      .cfg_size_i          ( idx_size_q       ),
      .cfg_base_i          ( idx_base_q       ),
      .cfg_shift_i         ( idx_shift_q      ),
      .natit_pointer_i     ( pointer_q        ),
      .natit_ready_o       ( natit_ready      ),
      .natit_done_i        ( natit_done       ),
      .natit_boundoffs_i   ( natit_boundoffs  ),
      .natit_extraword_o   ( natit_extraword  ),
      .mem_pointer_o       ( indir_pointer    ),
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
        spill_in_data   = {indir_pointer, indir_last};
        enable          = ~natit_done & natit_ready;
      end else begin
        spill_in_valid  = ~natit_done;
        spill_in_data   = {pointer_q, done};
        enable          = ~natit_done & spill_in_ready;
      end
    end

    // Generate spill register at output to cut timing paths if desired.
    if (Cfg.IndirOutSpill) begin : gen_indir_out_spill
      spill_register #(
        .T      ( out_spill_t ),
        .Bypass ( 1'b0        )
      ) i_out_spill (
        .clk_i,
        .rst_ni,
        .valid_i ( spill_in_valid ),
        .ready_o ( spill_in_ready ),
        .data_i  ( spill_in_data  ),
        .valid_o ( mem_valid_o    ),
        .ready_i ( mem_ready_i    ),
        .data_o  ( {mem_pointer, mem_last} )
      );
    end else begin : gen_no_indir_out_spill
      assign {mem_pointer, mem_last} = spill_in_data;
      assign mem_valid_o    = spill_in_valid;
      assign spill_in_ready = mem_ready_i;
    end

  end else begin : gen_no_indirection

    // Enable the overall count operation if we're not done and the memory
    // interface can make progress.
    assign enable = ~config_q.done & mem_valid_o & mem_ready_i;
    assign mem_valid_o = ~config_q.done;
    assign mem_pointer = pointer_q;
    assign mem_last    = done;

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
    `FFLARNC(index_q[i], index_q[i] + 1, index_ena, index_ena & loop_last[i], '0, clk_i, rst_ni)

    // Indicate last iteration (loops > 0); base loop handled differently in indirection
    if (i > 0) begin : gen_loop_last_upper
      assign loop_last[i] = (index_q[i] == bound_q[i] || config_q.dims < i);
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
    for (int i = 0; i < Cfg.NumLoops; i++)
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
      if (mem_ready_i & mem_valid_o)
        config_qn.done = mem_last;
    end
  end

  typedef struct packed {
    indir_read_map_t indir_read_map;
    logic [Cfg.NumLoops-1:0][31:0] stride;
    logic [Cfg.NumLoops-1:0][31:0] bound;
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
    for (int i = 0; i < Cfg.NumLoops; i++) begin
      read_map.bound[i] = bound_q[i];
      read_map.stride[i] = stride_q[i];
    end

    cfg_rdata_o = read_map[(cfg_word_i*32)+:32];
  end

endmodule
