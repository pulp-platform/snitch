// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Fabian Schuiki <fschuiki@iis.ee.ethz.ch>
// Author: Paul Scheffler <paulsc@iis.ee.ethz.ch>

module snitch_ssr_addr_gen import snitch_pkg::*; #(
  parameter bit Indirection = 0,
  parameter bit IndirOutSpill = 0,
  parameter int unsigned AddrWidth = 0,
  parameter int unsigned DataWidth = 0,
  parameter int unsigned NumIndexCredits = 0,
  parameter type tcdm_req_t   = logic,
  parameter type tcdm_rsp_t   = logic,
  parameter type tcdm_user_t  = logic,
  /// Derived parameters *Do not override*
  parameter type addr_t = logic [AddrWidth-1:0],
  parameter type data_t = logic [DataWidth-1:0]
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

  output logic [3:0]  reg_rep_o,

  output addr_t       mem_addr_o,
  output logic        mem_write_o,
  output logic        mem_valid_o,
  input  logic        mem_ready_i,

  input  addr_t       tcdm_start_address_i
);

  localparam int AW = 18; // address pointer width
  localparam int IW = 16; // loop index width
  localparam int NL = 4;  // number of nested loops
  localparam int DW = $clog2(NL); // width of the dimension field
  typedef logic [AW-1:0] pointer_t;
  typedef logic [IW-1:0] index_t;

  pointer_t [NL-1:0] stride_q, stride_sd, stride_sq;
  pointer_t pointer_q, pointer_sd, pointer_sq, selected_stride;
  index_t [NL-1:0] index_q, bound_q, bound_sd, bound_sq;
  logic [3:0] rep_q, rep_sd, rep_sq;
  logic [NL-1:0] loop_enabled;
  logic [NL-1:0] loop_last;
  logic enable, done;

  typedef struct packed {
    logic idx_shift;
    logic idx_base;
    logic idx_size;
    logic [NL-1:0] stride;
    logic [NL-1:0] bound;
    logic rep;
    logic status;
  } write_strobe_t;
  write_strobe_t write_strobe;

  logic alias_strobe;

  typedef struct packed {
    logic done;
    logic write;
    logic [DW-1:0] dims;
    logic indir;
  } config_t;
  config_t config_q, config_sd, config_sq;

  typedef struct packed {
    logic no_indir;       // Inverted as aliases aligned at upper address edge
    logic write;
    logic [DW-1:0] dims;
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

  if (Indirection) begin : gen_indirection

    // TODO: expose at top
    localparam int unsigned IndexWidth    = IW;
    localparam int unsigned PointerWidth  = AW;
    localparam int unsigned ShiftWidth    = 12;
    localparam int unsigned IndexCredits  = 2;
    localparam type         size_t        = logic [1:0];

    // Type for output spill register
    typedef struct packed {
      pointer_t pointer;
      logic     last;
    } out_spill_t;

    // Type for byte offset within word
    typedef logic [$clog2(DataWidth/8)-1:0] bytecnt_t;

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
    logic [ShiftWidth-1:0]    idx_shift_q, idx_shift_sd, idx_shift_sq;
    logic [PointerWidth-1:0]  idx_base_q, idx_base_sd, idx_base_sq;
    size_t                    idx_size_q, idx_size_sd, idx_size_sq;

    // Output spill register, if it exists
    out_spill_t spill_in_data;
    logic spill_in_valid, spill_in_ready;

    // Config register write
    always_comb begin
      idx_shift_sd  = idx_shift_sq;
      idx_base_sd   = idx_base_sq;
      idx_size_sd   = idx_size_sq;
      if (write_strobe.idx_shift) idx_shift_sd = cfg_wdata_i;
      // TODO: the masking here (and elsewhere) is an artifact of prior fixed 64-bit data_t
      if (write_strobe.idx_base)  idx_base_sd  = cfg_wdata_i & ~32'h3;
      if (write_strobe.idx_size)  idx_size_sd  = cfg_wdata_i;
    end

    // Config register read
    assign indir_read_map = '{idx_shift_q, idx_base_q, idx_size_q};

    // Config registers
    always_ff @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
        idx_shift_q   <= '0;
        idx_base_q    <= '0;
        idx_size_q    <= '0;
        idx_shift_sq  <= '0;
        idx_base_sq   <= '0;
        idx_size_sq   <= '0;
      end else begin
        idx_shift_sq  <= idx_shift_sd;
        idx_base_sq   <= idx_base_sd;
        idx_size_sq   <= idx_size_sd;
        if (config_q.done) begin
          idx_shift_q <= idx_shift_sd;
          idx_base_q  <= idx_base_sd;
          idx_size_q  <= idx_size_sd;
        end
      end
    end

    // Delay register for last iteration of base loop, in case additional iteration needed.
    always_ff @(posedge clk_i, negedge rst_ni) begin
      if(~rst_ni)           natit_base_last_q <= 1'b0;
      else if (enable)      natit_base_last_q <= natit_base_last_d;
      else if (natit_done)  natit_base_last_q <= 1'b0;
    end

    // Indicate last iteration (loop 0)
    assign natit_base_bound   = bound_q[0] >> (config_q.indir ? size_t'('1) - idx_size_q : '0);
    assign natit_base_last_d  = (index_q[0] == natit_base_bound);
    assign loop_last[0]       = (natit_extraword ? natit_base_last_q : natit_base_last_d);

    // Track last index word to set downstream last signal and handle word misalignment at end.
    always_ff @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni)            natit_last_word_inflight_q <= 1'b0;
      else if (config_q.done) natit_last_word_inflight_q <= 1'b0;
      else if (enable & done) natit_last_word_inflight_q <= 1'b1;
    end

    // Natural iteration loop 0 is done when last word inflight or address gen done.
    assign natit_done = natit_last_word_inflight_q | config_q.done;

    // Determine word offset incurred by indirect loop bound on loop 0.
    assign natit_boundoffs = bytecnt_t'(bound_q[0]) << idx_size_q;

    // Encapsulated indirection datapath
    snitch_ssr_indirector #(
      .AddrWidth    ( AddrWidth     ),
      .DataWidth    ( DataWidth     ),
      .IndexWidth   ( IndexWidth    ),
      .PointerWidth ( PointerWidth  ),
      .ShiftWidth   ( ShiftWidth    ),
      .IndexCredits ( IndexCredits  ),
      .tcdm_req_t   ( tcdm_req_t    ),
      .tcdm_rsp_t   ( tcdm_rsp_t    ),
      .tcdm_user_t  ( tcdm_user_t   ),
      .size_t       ( size_t        )
    ) i_snitch_ssr_indirector (
      .clk_i,
      .rst_ni,
      .idx_req_o,
      .idx_rsp_i,
      .cfg_indir_i         ( config_q.indir   ),
      .cfg_size_i          ( idx_size_q       ),
      .cfg_base_i          ( idx_base_q       ),
      .cfg_shift_i         ( idx_shift_q      ),
      .cfg_done_i          ( config_q.done    ),
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
    if (IndirOutSpill) begin : gen_indir_out_spill
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
  assign mem_addr_o   = {tcdm_start_address_i[AddrWidth-1:AW], mem_pointer};

  // Unpack the configuration address and write signal into a write strobe for
  // the individual registers. Also assign the alias strobe if the address is
  // targeting one of the status register aliases.
  assign write_strobe = (cfg_write_i << cfg_word_i);
  assign alias_strobe = cfg_write_i & (cfg_word_i[$bits(cfg_word_i)-1:$bits(alias_fields)] == '1);
  assign alias_fields = cfg_word_i[0+:$bits(alias_fields)];

  // Generate the loop counters.
  for (genvar i = 0; i < NL; i++) begin : gen_loop_counter
    always_comb begin
      stride_sd[i] = stride_sq[i];
      bound_sd[i] = bound_sq[i];
      if (write_strobe.stride[i])
        stride_sd[i] = cfg_wdata_i & ~32'h3;
      if (write_strobe.bound[i])
        bound_sd[i] = cfg_wdata_i;
    end

    always_ff @(posedge clk_i, negedge rst_ni) begin
      if (!rst_ni) begin
        stride_q[i]  <= '0;
        bound_q[i]   <= '0;
        index_q[i]   <= '0;
        stride_sq[i] <= '0;
        bound_sq[i]  <= '0;
      end else begin
        stride_sq[i] <= stride_sd[i];
        bound_sq[i]  <= bound_sd[i];
        if (config_q.done) begin
          stride_q[i] <= stride_sd[i];
          bound_q[i]  <= bound_sd[i];
        end
        if (enable & loop_enabled[i])
          index_q[i] <= loop_last[i] ? '0 : index_q[i] + 1;
      end
    end

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

  always_ff @(posedge clk_i, negedge rst_ni) begin
    if (!rst_ni) begin
      rep_q <= '0;
      rep_sq <= '0;
    end else begin
      rep_sq <= rep_sd;
      if (config_q.done)
        rep_q <= rep_sd;
    end
  end
  assign reg_rep_o = rep_q;

  // Enable a loop if they are enabled globally, and the next inner loop is at
  // its maximum.
  always_comb begin
    logic e;
    e = 1;
    for (int i = 0; i < NL; i++) begin
      loop_enabled[i] = e;
      e &= loop_last[i];
    end
    done = e;
  end

  // Pick the stride of the highest enabled loop.
  always_comb begin
    logic [NL-1:0] outermost;
    outermost = loop_enabled & ~(loop_enabled >> 1);
    selected_stride = '0;
    for (int i = 0; i < NL; i++)
      selected_stride |= outermost[i] ? stride_q[i] : '0;
  end

  // Advance the pointer by the selected stride if enabled.
  always_comb begin
    pointer_sd = pointer_sq;
    config_sd = config_sq;
    if (write_strobe.status) begin
      pointer_sd = cfg_wdata_i & ~32'h3;
      config_sd = cfg_wdata_i[31-:$bits(config_sq)];
    end else if (alias_strobe) begin
      pointer_sd = cfg_wdata_i & ~32'h3;
      config_sd.done = 0;
      config_sd.write = alias_fields.write;
      config_sd.dims = alias_fields.dims;
      config_sd.indir = ~alias_fields.no_indir;
    end
  end

  always_ff @(posedge clk_i, negedge rst_ni) begin
    if (!rst_ni) begin
      pointer_q  <= '0;
      pointer_sq <= '0;
      config_q  <= '0;
      config_sq <= '0;
      config_q.done  <= 1;
      config_sq.done <= 1;
    end else begin
      pointer_sq <= pointer_sd;
      config_sq <= config_sd;
      if (config_q.done) begin
        pointer_q <= pointer_sd;
        config_q <= config_sd;
        config_sq.done <= 1;
      end else begin
        if (enable) begin
          pointer_q <= pointer_q + selected_stride;
        end if (mem_ready_i & mem_valid_o) begin
          config_q.done <= mem_last;
        end
      end
    end
  end

  typedef struct packed {
    indir_read_map_t indir_read_map;
    logic [NL-1:0][31:0] stride;
    logic [NL-1:0][31:0] bound;
    logic [31:0] rep;
    logic [31:0] status;
  } read_map_t;

  // Configuration read access.
  always_comb begin
    read_map_t read_map;

    read_map.indir_read_map = Indirection ? indir_read_map : '0;
    read_map.status = pointer_q;
    read_map.status[31-:$bits(config_q)] = config_q;
    read_map.rep = rep_q;
    for (int i = 0; i < NL; i++) begin
      read_map.bound[i] = bound_q[i];
      read_map.stride[i] = stride_q[i];
    end

    cfg_rdata_o = read_map[(cfg_word_i*32)+:32];
  end

endmodule
