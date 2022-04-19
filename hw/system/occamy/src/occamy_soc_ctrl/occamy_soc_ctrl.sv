// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>

module occamy_soc_ctrl import occamy_soc_reg_pkg::*; #(
  parameter type reg_req_t = logic,
  parameter type reg_rsp_t = logic
) (
  input clk_i,
  input rst_ni,

  // Below Register interface can be changed
  input  reg_req_t reg_req_i,
  output reg_rsp_t reg_rsp_o,
  // To HW
  output occamy_soc_reg2hw_t reg2hw_o, // Write
  input  occamy_soc_hw2reg_t hw2reg_i,
  // Events in
  input logic [1:0] event_ecc_rerror_narrow_i,
  input logic [1:0] event_ecc_rerror_wide_i,
  // System Interrupts
  output logic intr_ecc_narrow_uncorrectable_o,
  output logic intr_ecc_narrow_correctable_o,
  output logic intr_ecc_wide_uncorrectable_o,
  output logic intr_ecc_wide_correctable_o
);

  occamy_soc_hw2reg_t hw2reg;

  // Add local hw2reg signals
  logic intr_state_ecc_narrow_correctable_d;
  logic intr_state_ecc_narrow_correctable_de;
  logic intr_state_ecc_narrow_uncorrectable_d;
  logic intr_state_ecc_narrow_uncorrectable_de;

  logic intr_state_ecc_wide_correctable_d;
  logic intr_state_ecc_wide_correctable_de;
  logic intr_state_ecc_wide_uncorrectable_d;
  logic intr_state_ecc_wide_uncorrectable_de;

  always_comb begin
    hw2reg = hw2reg_i;
    hw2reg.intr_state.ecc_narrow_correctable.d = intr_state_ecc_narrow_correctable_d;
    hw2reg.intr_state.ecc_narrow_correctable.de = intr_state_ecc_narrow_correctable_de;
    hw2reg.intr_state.ecc_narrow_uncorrectable.d = intr_state_ecc_narrow_uncorrectable_d;
    hw2reg.intr_state.ecc_narrow_uncorrectable.de = intr_state_ecc_narrow_uncorrectable_de;
    hw2reg.intr_state.ecc_wide_correctable.d = intr_state_ecc_wide_correctable_d;
    hw2reg.intr_state.ecc_wide_correctable.de = intr_state_ecc_wide_correctable_de;
    hw2reg.intr_state.ecc_wide_uncorrectable.d = intr_state_ecc_wide_uncorrectable_d;
    hw2reg.intr_state.ecc_wide_uncorrectable.de = intr_state_ecc_wide_uncorrectable_de;
  end

  occamy_soc_reg_top #(
    .reg_req_t ( reg_req_t ),
    .reg_rsp_t ( reg_rsp_t  )
  ) i_soc_ctrl (
    .clk_i     ( clk_i  ),
    .rst_ni    ( rst_ni ),
    .reg_req_i ( reg_req_i ),
    .reg_rsp_o ( reg_rsp_o ),
    .reg2hw    ( reg2hw_o ),
    .hw2reg    ( hw2reg ),
    .devmode_i ( 1'b1 )
  );

  prim_intr_hw #(.Width(1)) intr_hw_ecc_narrow_correctable (
    .clk_i,
    .rst_ni,
    .event_intr_i           (event_ecc_rerror_narrow_i[0]),
    .reg2hw_intr_enable_q_i (reg2hw_o.intr_enable.ecc_narrow_correctable.q),
    .reg2hw_intr_test_q_i   (reg2hw_o.intr_test.ecc_narrow_correctable.q),
    .reg2hw_intr_test_qe_i  (reg2hw_o.intr_test.ecc_narrow_correctable.qe),
    .reg2hw_intr_state_q_i  (reg2hw_o.intr_state.ecc_narrow_correctable.q),
    .hw2reg_intr_state_de_o (intr_state_ecc_narrow_correctable_de),
    .hw2reg_intr_state_d_o  (intr_state_ecc_narrow_correctable_d),
    .intr_o                 (intr_ecc_narrow_correctable_o)
  );

  prim_intr_hw #(.Width(1)) intr_hw_ecc_narrow_uncorrectable (
    .clk_i,
    .rst_ni,
    .event_intr_i           (event_ecc_rerror_narrow_i[1]),
    .reg2hw_intr_enable_q_i (reg2hw_o.intr_enable.ecc_narrow_uncorrectable.q),
    .reg2hw_intr_test_q_i   (reg2hw_o.intr_test.ecc_narrow_uncorrectable.q),
    .reg2hw_intr_test_qe_i  (reg2hw_o.intr_test.ecc_narrow_uncorrectable.qe),
    .reg2hw_intr_state_q_i  (reg2hw_o.intr_state.ecc_narrow_uncorrectable.q),
    .hw2reg_intr_state_de_o (intr_state_ecc_narrow_uncorrectable_de),
    .hw2reg_intr_state_d_o  (intr_state_ecc_narrow_uncorrectable_d),
    .intr_o                 (intr_ecc_narrow_uncorrectable_o)
  );

  prim_intr_hw #(.Width(1)) intr_hw_ecc_wide_correctable (
    .clk_i,
    .rst_ni,
    .event_intr_i           (event_ecc_rerror_wide_i[0]),
    .reg2hw_intr_enable_q_i (reg2hw_o.intr_enable.ecc_wide_correctable.q),
    .reg2hw_intr_test_q_i   (reg2hw_o.intr_test.ecc_wide_correctable.q),
    .reg2hw_intr_test_qe_i  (reg2hw_o.intr_test.ecc_wide_correctable.qe),
    .reg2hw_intr_state_q_i  (reg2hw_o.intr_state.ecc_wide_correctable.q),
    .hw2reg_intr_state_de_o (intr_state_ecc_wide_correctable_de),
    .hw2reg_intr_state_d_o  (intr_state_ecc_wide_correctable_d),
    .intr_o                 (intr_ecc_wide_correctable_o)
  );

  prim_intr_hw #(.Width(1)) intr_hw_ecc_wide_uncorrectable (
    .clk_i,
    .rst_ni,
    .event_intr_i           (event_ecc_rerror_wide_i[1]),
    .reg2hw_intr_enable_q_i (reg2hw_o.intr_enable.ecc_wide_uncorrectable.q),
    .reg2hw_intr_test_q_i   (reg2hw_o.intr_test.ecc_wide_uncorrectable.q),
    .reg2hw_intr_test_qe_i  (reg2hw_o.intr_test.ecc_wide_uncorrectable.qe),
    .reg2hw_intr_state_q_i  (reg2hw_o.intr_state.ecc_wide_uncorrectable.q),
    .hw2reg_intr_state_de_o (intr_state_ecc_wide_uncorrectable_de),
    .hw2reg_intr_state_d_o  (intr_state_ecc_wide_uncorrectable_d),
    .intr_o                 (intr_ecc_wide_uncorrectable_o)
  );

endmodule
