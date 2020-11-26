// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Fabian Schuiki <fschuiki@iis.ee.ethz.ch>

module snitch_ssr_addr_gen import snitch_pkg::*; (
  input  logic        clk_i,
  input  logic        rst_ni,

  input  logic [4:0]  cfg_word_i,
  output logic [31:0] cfg_rdata_o,
  input  logic [31:0] cfg_wdata_i,
  input  logic        cfg_write_i,

  output logic [3:0]  reg_rep_o,

  output addr_t       mem_addr_o,
  output logic        mem_write_o,
  output logic        mem_valid_o,
  input  logic        mem_ready_i
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
  } config_t;
  config_t config_q, config_sd, config_sq;

  typedef struct packed {
    logic write;
    logic [DW-1:0] dims;
  } alias_fields_t;

  alias_fields_t alias_fields;

  // Enable the overall count operation if we're not done and the memory
  // interface can make progress.
  assign enable = ~config_q.done & mem_valid_o & mem_ready_i;
  assign mem_valid_o = ~config_q.done;
  assign mem_write_o = config_q.write;
  assign mem_addr_o = {TCDMStartAddress[PLEN-1:AW], pointer_q};

  // Unpack the configuration address and write signal into a write strobe for
  // the individual registers. Also assign the alias strobe if the address is
  // targeting one of the status register aliases.
  assign write_strobe = (cfg_write_i << cfg_word_i);
  assign alias_strobe = cfg_write_i & (cfg_word_i[$bits(cfg_word_i)-1:$bits(alias_fields)] == '1);
  assign alias_fields = cfg_word_i[0+:$bits(alias_fields)];

  // Generate the loop counters.
  for (genvar i = 0; i < NL; i++) begin : loop
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

    assign loop_last[i] = (index_q[i] == bound_q[i] || config_q.dims < i);
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
      end else if (enable) begin
        pointer_q <= pointer_q + selected_stride;
        config_q.done <= done;
      end
    end
  end

  typedef struct packed {
    logic [NL-1:0][31:0] stride;
    logic [NL-1:0][31:0] bound;
    logic [31:0] rep;
    logic [31:0] status;
  } read_map_t;

  // Configuration read access.
  always_comb begin
    read_map_t read_map;

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
