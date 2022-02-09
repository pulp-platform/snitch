// Copyright 2018-2021 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Florian Zaruba, ETH Zurich
// Date: 15/07/2017
// Description: A RISC-V privilege spec 1.11 (WIP) compatible CLINT (core local interrupt controller)
//

// Platforms provide a real-time counter, exposed as a memory-mapped machine-mode register, mtime. mtime must run at
// constant frequency, and the platform must provide a mechanism for determining the timebase of mtime (device tree).

`include "common_cells/registers.svh"

module clint import clint_reg_pkg::*; #(
    parameter type reg_req_t = logic,
    parameter type reg_rsp_t = logic
) (
    input  logic                clk_i,       // Clock
    input  logic                rst_ni,      // Asynchronous reset active low
    input  logic                testmode_i,
    input  reg_req_t            reg_req_i,
    output reg_rsp_t            reg_rsp_o,
    input  logic                rtc_i,       // Real-time clock in (usually 32.768 kHz)
    output logic [36:0] timer_irq_o, // Timer interrupts
    output logic [36:0] ipi_o        // software interrupt (a.k.a inter-process-interrupt)
);

    logic [63:0]               mtime_q;
    logic [36:0][63:0] mtimecmp_q;
    // increase the timer
    logic increase_timer;

    clint_reg_pkg::clint_reg2hw_t reg2hw;
    clint_reg_pkg::clint_hw2reg_t hw2reg;

    clint_reg_top #(
      .reg_req_t (reg_req_t),
      .reg_rsp_t (reg_rsp_t)
    ) i_clint_reg_top (
      .clk_i,
      .rst_ni,
      .reg_req_i,
      .reg_rsp_o,
      .reg2hw (reg2hw), // Write
      .hw2reg (hw2reg), // Read
      .devmode_i (1'b0)
    );

    assign mtime_q = {reg2hw.mtime_high.q, reg2hw.mtime_low.q};
    assign mtimecmp_q[0] = {reg2hw.mtimecmp_high0.q, reg2hw.mtimecmp_low0.q};
    assign ipi_o[0] = reg2hw.msip[0].q;
    assign mtimecmp_q[1] = {reg2hw.mtimecmp_high1.q, reg2hw.mtimecmp_low1.q};
    assign ipi_o[1] = reg2hw.msip[1].q;
    assign mtimecmp_q[2] = {reg2hw.mtimecmp_high2.q, reg2hw.mtimecmp_low2.q};
    assign ipi_o[2] = reg2hw.msip[2].q;
    assign mtimecmp_q[3] = {reg2hw.mtimecmp_high3.q, reg2hw.mtimecmp_low3.q};
    assign ipi_o[3] = reg2hw.msip[3].q;
    assign mtimecmp_q[4] = {reg2hw.mtimecmp_high4.q, reg2hw.mtimecmp_low4.q};
    assign ipi_o[4] = reg2hw.msip[4].q;
    assign mtimecmp_q[5] = {reg2hw.mtimecmp_high5.q, reg2hw.mtimecmp_low5.q};
    assign ipi_o[5] = reg2hw.msip[5].q;
    assign mtimecmp_q[6] = {reg2hw.mtimecmp_high6.q, reg2hw.mtimecmp_low6.q};
    assign ipi_o[6] = reg2hw.msip[6].q;
    assign mtimecmp_q[7] = {reg2hw.mtimecmp_high7.q, reg2hw.mtimecmp_low7.q};
    assign ipi_o[7] = reg2hw.msip[7].q;
    assign mtimecmp_q[8] = {reg2hw.mtimecmp_high8.q, reg2hw.mtimecmp_low8.q};
    assign ipi_o[8] = reg2hw.msip[8].q;
    assign mtimecmp_q[9] = {reg2hw.mtimecmp_high9.q, reg2hw.mtimecmp_low9.q};
    assign ipi_o[9] = reg2hw.msip[9].q;
    assign mtimecmp_q[10] = {reg2hw.mtimecmp_high10.q, reg2hw.mtimecmp_low10.q};
    assign ipi_o[10] = reg2hw.msip[10].q;
    assign mtimecmp_q[11] = {reg2hw.mtimecmp_high11.q, reg2hw.mtimecmp_low11.q};
    assign ipi_o[11] = reg2hw.msip[11].q;
    assign mtimecmp_q[12] = {reg2hw.mtimecmp_high12.q, reg2hw.mtimecmp_low12.q};
    assign ipi_o[12] = reg2hw.msip[12].q;
    assign mtimecmp_q[13] = {reg2hw.mtimecmp_high13.q, reg2hw.mtimecmp_low13.q};
    assign ipi_o[13] = reg2hw.msip[13].q;
    assign mtimecmp_q[14] = {reg2hw.mtimecmp_high14.q, reg2hw.mtimecmp_low14.q};
    assign ipi_o[14] = reg2hw.msip[14].q;
    assign mtimecmp_q[15] = {reg2hw.mtimecmp_high15.q, reg2hw.mtimecmp_low15.q};
    assign ipi_o[15] = reg2hw.msip[15].q;
    assign mtimecmp_q[16] = {reg2hw.mtimecmp_high16.q, reg2hw.mtimecmp_low16.q};
    assign ipi_o[16] = reg2hw.msip[16].q;
    assign mtimecmp_q[17] = {reg2hw.mtimecmp_high17.q, reg2hw.mtimecmp_low17.q};
    assign ipi_o[17] = reg2hw.msip[17].q;
    assign mtimecmp_q[18] = {reg2hw.mtimecmp_high18.q, reg2hw.mtimecmp_low18.q};
    assign ipi_o[18] = reg2hw.msip[18].q;
    assign mtimecmp_q[19] = {reg2hw.mtimecmp_high19.q, reg2hw.mtimecmp_low19.q};
    assign ipi_o[19] = reg2hw.msip[19].q;
    assign mtimecmp_q[20] = {reg2hw.mtimecmp_high20.q, reg2hw.mtimecmp_low20.q};
    assign ipi_o[20] = reg2hw.msip[20].q;
    assign mtimecmp_q[21] = {reg2hw.mtimecmp_high21.q, reg2hw.mtimecmp_low21.q};
    assign ipi_o[21] = reg2hw.msip[21].q;
    assign mtimecmp_q[22] = {reg2hw.mtimecmp_high22.q, reg2hw.mtimecmp_low22.q};
    assign ipi_o[22] = reg2hw.msip[22].q;
    assign mtimecmp_q[23] = {reg2hw.mtimecmp_high23.q, reg2hw.mtimecmp_low23.q};
    assign ipi_o[23] = reg2hw.msip[23].q;
    assign mtimecmp_q[24] = {reg2hw.mtimecmp_high24.q, reg2hw.mtimecmp_low24.q};
    assign ipi_o[24] = reg2hw.msip[24].q;
    assign mtimecmp_q[25] = {reg2hw.mtimecmp_high25.q, reg2hw.mtimecmp_low25.q};
    assign ipi_o[25] = reg2hw.msip[25].q;
    assign mtimecmp_q[26] = {reg2hw.mtimecmp_high26.q, reg2hw.mtimecmp_low26.q};
    assign ipi_o[26] = reg2hw.msip[26].q;
    assign mtimecmp_q[27] = {reg2hw.mtimecmp_high27.q, reg2hw.mtimecmp_low27.q};
    assign ipi_o[27] = reg2hw.msip[27].q;
    assign mtimecmp_q[28] = {reg2hw.mtimecmp_high28.q, reg2hw.mtimecmp_low28.q};
    assign ipi_o[28] = reg2hw.msip[28].q;
    assign mtimecmp_q[29] = {reg2hw.mtimecmp_high29.q, reg2hw.mtimecmp_low29.q};
    assign ipi_o[29] = reg2hw.msip[29].q;
    assign mtimecmp_q[30] = {reg2hw.mtimecmp_high30.q, reg2hw.mtimecmp_low30.q};
    assign ipi_o[30] = reg2hw.msip[30].q;
    assign mtimecmp_q[31] = {reg2hw.mtimecmp_high31.q, reg2hw.mtimecmp_low31.q};
    assign ipi_o[31] = reg2hw.msip[31].q;
    assign mtimecmp_q[32] = {reg2hw.mtimecmp_high32.q, reg2hw.mtimecmp_low32.q};
    assign ipi_o[32] = reg2hw.msip[32].q;
    assign mtimecmp_q[33] = {reg2hw.mtimecmp_high33.q, reg2hw.mtimecmp_low33.q};
    assign ipi_o[33] = reg2hw.msip[33].q;
    assign mtimecmp_q[34] = {reg2hw.mtimecmp_high34.q, reg2hw.mtimecmp_low34.q};
    assign ipi_o[34] = reg2hw.msip[34].q;
    assign mtimecmp_q[35] = {reg2hw.mtimecmp_high35.q, reg2hw.mtimecmp_low35.q};
    assign ipi_o[35] = reg2hw.msip[35].q;
    assign mtimecmp_q[36] = {reg2hw.mtimecmp_high36.q, reg2hw.mtimecmp_low36.q};
    assign ipi_o[36] = reg2hw.msip[36].q;

    assign {hw2reg.mtime_high.d, hw2reg.mtime_low.d} = mtime_q + 1;
    assign hw2reg.mtime_low.de = increase_timer;
    assign hw2reg.mtime_high.de = increase_timer;

    // -----------------------------
    // IRQ Generation
    // -----------------------------
    // The mtime register has a 64-bit precision on all RV32, RV64, and RV128 systems. Platforms provide a 64-bit
    // memory-mapped machine-mode timer compare register (mtimecmp), which causes a timer interrupt to be posted when the
    // mtime register contains a value greater than or equal (mtime >= mtimecmp) to the value in the mtimecmp register.
    // The interrupt remains posted until it is cleared by writing the mtimecmp register. The interrupt will only be taken
    // if interrupts are enabled and the MTIE bit is set in the mie register.
    always_comb begin : irq_gen
        // check that the mtime cmp register is set to a meaningful value
        for (int unsigned i = 0; i < 37; i++) begin
            if (mtime_q >= mtimecmp_q[i]) begin
                timer_irq_o[i] = 1'b1;
            end else begin
                timer_irq_o[i] = 1'b0;
            end
        end
    end

    // -----------------------------
    // RTC time tracking facilities
    // -----------------------------
    // 1. Put the RTC input through a classic two stage edge-triggered synchronizer to filter out any
    //    metastability effects (or at least make them unlikely :-))
    clint_sync_wedge i_sync_edge (
        .clk_i,
        .rst_ni,
        .serial_i  ( rtc_i          ),
        .r_edge_o  ( increase_timer ),
        .f_edge_o  (                ), // left open
        .serial_o  (                )  // left open
    );


endmodule

// TODO(zarubaf): Replace by common-cells 2.0
module clint_sync_wedge #(
    parameter int unsigned STAGES = 2
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic r_edge_o,
    output logic f_edge_o,
    output logic serial_o
);
    logic serial, serial_q;

    assign serial_o =  serial_q;
    assign f_edge_o = (~serial) & serial_q;
    assign r_edge_o =  serial & (~serial_q);

    clint_sync #(
        .STAGES (STAGES)
    ) i_sync (
        .clk_i,
        .rst_ni,
        .serial_i,
        .serial_o (serial)
    );

    `FF(serial_q, serial, 1'b0)
endmodule

module clint_sync #(
    parameter int unsigned STAGES = 2
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic serial_o
);

  logic [STAGES-1:0] reg_q;
  `FF(reg_q, {reg_q[STAGES-2:0], serial_i}, 'h0)
  assign serial_o = reg_q[STAGES-1];

endmodule
