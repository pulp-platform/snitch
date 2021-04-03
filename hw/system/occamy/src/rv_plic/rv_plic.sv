// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// RISC-V Platform-Level Interrupt Controller compliant INTC
//
//   Current version doesn't support MSI interrupt but it is easy to add
//   the feature. Create one external register and connect qe signal to the
//   gateway module (as edge-triggered)
//
//   Consider to set MAX_PRIO as small number as possible. It is main factor
//   of area increase if edge-triggered counter isn't implemented.
//
// Verilog parameter
//   MAX_PRIO: Maximum value of interrupt priority

module rv_plic import rv_plic_reg_pkg::*; #(
  parameter type reg_req_t = logic,
  parameter type reg_rsp_t = logic,
  // derived parameter
  localparam int SRCW    = $clog2(NumSrc)
) (
  input     clk_i,
  input     rst_ni,

  // Bus Interface (device)
  input  reg_req_t reg_req_i,
  output reg_rsp_t reg_rsp_o,

  // Interrupt Sources
  input  [NumSrc-1:0] intr_src_i,

  // Interrupt notification to targets
  output [NumTarget-1:0] irq_o,
  output [SRCW-1:0]      irq_id_o [NumTarget],

  output logic [NumTarget-1:0] msip_o
);

  rv_plic_reg2hw_t reg2hw;
  rv_plic_hw2reg_t hw2reg;

  localparam int MAX_PRIO    = 6;
  localparam int PRIOW = $clog2(MAX_PRIO+1);

  logic [NumSrc-1:0] le; // 0:level 1:edge
  logic [NumSrc-1:0] ip;

  logic [NumSrc-1:0] ie [NumTarget];

  logic [NumTarget-1:0] claim_re; // Target read indicator
  logic [SRCW-1:0]      claim_id [NumTarget];
  logic [NumSrc-1:0]    claim; // Converted from claim_re/claim_id

  logic [NumTarget-1:0] complete_we; // Target write indicator
  logic [SRCW-1:0]      complete_id [NumTarget];
  logic [NumSrc-1:0]    complete; // Converted from complete_re/complete_id

  logic [SRCW-1:0]      cc_id [NumTarget]; // Write ID

  logic [PRIOW-1:0] prio [NumSrc];

  logic [PRIOW-1:0] threshold [NumTarget];

  // Glue logic between rv_plic_reg_top and others
  assign cc_id = irq_id_o;

  always_comb begin
    claim = '0;
    for (int i = 0 ; i < NumTarget ; i++) begin
      if (claim_re[i]) claim[claim_id[i]] = 1'b1;
    end
  end
  always_comb begin
    complete = '0;
    for (int i = 0 ; i < NumTarget ; i++) begin
      if (complete_we[i]) complete[complete_id[i]] = 1'b1;
    end
  end

  //`ASSERT_PULSE(claimPulse, claim_re[i])
  //`ASSERT_PULSE(completePulse, complete_we[i])

  `ASSERT(onehot0Claim, $onehot0(claim_re))

  `ASSERT(onehot0Complete, $onehot0(complete_we))

  //////////////
  // Priority //
  //////////////
  assign prio[0] = reg2hw.prio0.q;
  assign prio[1] = reg2hw.prio1.q;
  assign prio[2] = reg2hw.prio2.q;
  assign prio[3] = reg2hw.prio3.q;
  assign prio[4] = reg2hw.prio4.q;
  assign prio[5] = reg2hw.prio5.q;
  assign prio[6] = reg2hw.prio6.q;
  assign prio[7] = reg2hw.prio7.q;
  assign prio[8] = reg2hw.prio8.q;
  assign prio[9] = reg2hw.prio9.q;

  //////////////////////
  // Interrupt Enable //
  //////////////////////
  for (genvar s = 0; s < 10; s++) begin : gen_ie0
    assign ie[0][s] = reg2hw.ie0[s].q;
  end
  for (genvar s = 0; s < 10; s++) begin : gen_ie1
    assign ie[1][s] = reg2hw.ie1[s].q;
  end

  ////////////////////////
  // THRESHOLD register //
  ////////////////////////
  assign threshold[0] = reg2hw.threshold0.q;
  assign threshold[1] = reg2hw.threshold1.q;

  /////////////////
  // CC register //
  /////////////////
  assign claim_re[0]    = reg2hw.cc0.re;
  assign claim_id[0]    = irq_id_o[0];
  assign complete_we[0] = reg2hw.cc0.qe;
  assign complete_id[0] = reg2hw.cc0.q;
  assign hw2reg.cc0.d   = cc_id[0];
  assign claim_re[1]    = reg2hw.cc1.re;
  assign claim_id[1]    = irq_id_o[1];
  assign complete_we[1] = reg2hw.cc1.qe;
  assign complete_id[1] = reg2hw.cc1.q;
  assign hw2reg.cc1.d   = cc_id[1];

  ///////////////////
  // MSIP register //
  ///////////////////
  assign msip_o[0] = reg2hw.msip0.q;
  assign msip_o[1] = reg2hw.msip1.q;

  ////////
  // IP //
  ////////
  for (genvar s = 0; s < 10; s++) begin : gen_ip
    assign hw2reg.ip[s].de = 1'b1; // Always write
    assign hw2reg.ip[s].d  = ip[s];
  end

  ///////////////////////////////////
  // Detection:: 0: Level, 1: Edge //
  ///////////////////////////////////
  for (genvar s = 0; s < 10; s++) begin : gen_le
    assign le[s] = reg2hw.le[s].q;
  end

  //////////////
  // Gateways //
  //////////////
  rv_plic_gateway #(
    .N_SOURCE   (NumSrc)
  ) u_gateway (
    .clk_i,
    .rst_ni,

    .src_i      (intr_src_i),
    .le_i       (le),

    .claim_i    (claim),
    .complete_i (complete),

    .ip_o       (ip)
  );

  ///////////////////////////////////
  // Target interrupt notification //
  ///////////////////////////////////
  for (genvar i = 0 ; i < NumTarget ; i++) begin : gen_target
    rv_plic_target #(
      .N_SOURCE    (NumSrc),
      .MAX_PRIO    (MAX_PRIO)
    ) u_target (
      .clk_i,
      .rst_ni,

      .ip_i        (ip),
      .ie_i        (ie[i]),

      .prio_i      (prio),
      .threshold_i (threshold[i]),

      .irq_o       (irq_o[i]),
      .irq_id_o    (irq_id_o[i])

    );
  end

  ////////////////////////
  // Register interface //
  ////////////////////////
  //  Limitation of register tool prevents the module from having flexibility to parameters
  //  So, signals are manually tied at the top.
  rv_plic_reg_top #(
    .reg_req_t (reg_req_t),
    .reg_rsp_t (reg_rsp_t)
  ) u_reg (
    .clk_i,
    .rst_ni,

    .reg_req_i,
    .reg_rsp_o,

    .reg2hw,
    .hw2reg,

    .devmode_i  (1'b1)
  );

  // Assertions
  `ASSERT_KNOWN(IrqKnownO_A, irq_o)
  `ASSERT_KNOWN(MsipKnownO_A, msip_o)
  for (genvar k = 0; k < NumTarget; k++) begin : gen_irq_id_known
    `ASSERT_KNOWN(IrqIdKnownO_A, irq_id_o[k])
  end

  // Assume
  `ASSUME(Irq0Tied_A, intr_src_i[0] == 1'b0)

endmodule

