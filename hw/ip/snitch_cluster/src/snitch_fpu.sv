// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

/// FPU Synthesis Wrapper
module snitch_fpu import snitch_pkg::*; #(
  parameter fpnew_pkg::fpu_implementation_t FPUImplementation = '0,
  parameter bit          RVF                = 1,
  parameter bit          RVD                = 1,
  parameter bit          XF16               = 0,
  parameter bit          XF16ALT            = 0,
  parameter bit          XF8                = 0,
  parameter bit          XF8ALT             = 0,
  parameter bit          XFVEC              = 0,
  parameter int unsigned FLEN               = 0,
  parameter bit          RegisterFPUIn      = 0,
  parameter bit          RegisterFPUOut     = 0
) (
  input logic                               clk_i,
  input logic                               rst_ni,
  // Input signals
  input logic [2:0][FLEN-1:0]               operands_i,
  input fpnew_pkg::roundmode_e              rnd_mode_i,
  input fpnew_pkg::operation_e              op_i,
  input logic                               op_mod_i,
  input fpnew_pkg::fp_format_e              src_fmt_i,
  input fpnew_pkg::fp_format_e              dst_fmt_i,
  input fpnew_pkg::int_format_e             int_fmt_i,
  input logic                               vectorial_op_i,
  input logic [6:0]                         tag_i,
  // Input Handshake
  input  logic                              in_valid_i,
  output logic                              in_ready_o,
  // Output signals
  output logic [FLEN-1:0]                   result_o,
  output logic [4:0]                        status_o,
  output logic [6:0]                        tag_o,
  // Output handshake
  output logic                              out_valid_o,
  input  logic                              out_ready_i
);

  localparam fpnew_pkg::fpu_features_t FPUFeatures = '{
    Width:             fpnew_pkg::maximum(FLEN, 32),
    EnableVectors:     XFVEC,
    EnableNanBox:      1'b1,
    FpFmtMask:         {RVF, RVD, XF16, XF8, XF16ALT, XF8ALT},
    IntFmtMask:        {XFVEC && (XF8 || XF8ALT), XFVEC && (XF16 || XF16ALT), 1'b1, 1'b0}
  };

  typedef struct packed {
    logic [2:0][FLEN-1:0]    operands;
    fpnew_pkg::roundmode_e   rnd_mode;
    fpnew_pkg::operation_e   op;
    logic                    op_mod;
    fpnew_pkg::fp_format_e   src_fmt;
    fpnew_pkg::fp_format_e   dst_fmt;
    fpnew_pkg::int_format_e  int_fmt;
    logic                    vectorial_op;
    logic [6:0]              tag;
  } fpu_in_t;

  typedef struct packed {
    logic [FLEN-1:0] result;
    logic [4:0]      status;
    logic [6:0]      tag;
  } fpu_out_t;

  fpu_in_t fpu_in_q, fpu_in;
  fpu_out_t fpu_out_q, fpu_out;
  logic in_valid_q, in_ready_q;
  logic out_valid, out_ready;

  assign fpu_in = '{
    operands: operands_i,
    rnd_mode: rnd_mode_i,
    op: op_i,
    op_mod: op_mod_i,
    src_fmt: src_fmt_i,
    dst_fmt: dst_fmt_i,
    int_fmt: int_fmt_i,
    vectorial_op: vectorial_op_i,
    tag: tag_i
  };

  spill_register #(
    .T      ( fpu_in_t ),
    .Bypass ( ~RegisterFPUIn )
  ) i_spill_register_fpu_in (
    .clk_i                 ,
    .rst_ni                ,
    .valid_i ( in_valid_i ),
    .ready_o ( in_ready_o ),
    .data_i  ( fpu_in     ),
    .valid_o ( in_valid_q ),
    .ready_i ( in_ready_q ),
    .data_o  ( fpu_in_q   )
  );

  fpnew_top #(
    // FPU configuration
    .Features       ( FPUFeatures ),
    .Implementation ( FPUImplementation ),
    .TagType        ( logic[6:0]        )
  ) i_fpu (
    .clk_i                                    ,
    .rst_ni                                   ,
    .operands_i      ( fpu_in_q.operands     ),
    .rnd_mode_i      ( fpu_in_q.rnd_mode     ),
    .op_i            ( fpu_in_q.op           ),
    .op_mod_i        ( fpu_in_q.op_mod       ),
    .src_fmt_i       ( fpu_in_q.src_fmt      ),
    .dst_fmt_i       ( fpu_in_q.dst_fmt      ),
    .int_fmt_i       ( fpu_in_q.int_fmt      ),
    .vectorial_op_i  ( fpu_in_q.vectorial_op ),
    .tag_i           ( fpu_in_q.tag          ),
    .in_valid_i      ( in_valid_q            ),
    .in_ready_o      ( in_ready_q            ),
    .flush_i         ( 1'b0                  ),
    .result_o        ( fpu_out.result        ),
    .status_o        ( fpu_out.status        ),
    .tag_o           ( fpu_out.tag           ),
    .out_valid_o     ( out_valid             ),
    .out_ready_i     ( out_ready             ),
    .busy_o          (                       )
  );

  spill_register #(
    .T      ( fpu_out_t ),
    .Bypass ( ~RegisterFPUOut )
  ) i_spill_register_fpu_out (
    .clk_i                  ,
    .rst_ni                 ,
    .valid_i ( out_valid   ),
    .ready_o ( out_ready   ),
    .data_i  ( fpu_out     ),
    .valid_o ( out_valid_o ),
    .ready_i ( out_ready_i ),
    .data_o  ( fpu_out_q   )
  );

  assign result_o = fpu_out_q.result;
  assign status_o = fpu_out_q.status;
  assign tag_o = fpu_out_q.tag;

endmodule
