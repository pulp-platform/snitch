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
    output logic [216:0] timer_irq_o, // Timer interrupts
    output logic [216:0] ipi_o        // software interrupt (a.k.a inter-process-interrupt)
);

    logic [63:0]               mtime_q;
    logic [216:0][63:0] mtimecmp_q;
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
    assign mtimecmp_q[37] = {reg2hw.mtimecmp_high37.q, reg2hw.mtimecmp_low37.q};
    assign ipi_o[37] = reg2hw.msip[37].q;
    assign mtimecmp_q[38] = {reg2hw.mtimecmp_high38.q, reg2hw.mtimecmp_low38.q};
    assign ipi_o[38] = reg2hw.msip[38].q;
    assign mtimecmp_q[39] = {reg2hw.mtimecmp_high39.q, reg2hw.mtimecmp_low39.q};
    assign ipi_o[39] = reg2hw.msip[39].q;
    assign mtimecmp_q[40] = {reg2hw.mtimecmp_high40.q, reg2hw.mtimecmp_low40.q};
    assign ipi_o[40] = reg2hw.msip[40].q;
    assign mtimecmp_q[41] = {reg2hw.mtimecmp_high41.q, reg2hw.mtimecmp_low41.q};
    assign ipi_o[41] = reg2hw.msip[41].q;
    assign mtimecmp_q[42] = {reg2hw.mtimecmp_high42.q, reg2hw.mtimecmp_low42.q};
    assign ipi_o[42] = reg2hw.msip[42].q;
    assign mtimecmp_q[43] = {reg2hw.mtimecmp_high43.q, reg2hw.mtimecmp_low43.q};
    assign ipi_o[43] = reg2hw.msip[43].q;
    assign mtimecmp_q[44] = {reg2hw.mtimecmp_high44.q, reg2hw.mtimecmp_low44.q};
    assign ipi_o[44] = reg2hw.msip[44].q;
    assign mtimecmp_q[45] = {reg2hw.mtimecmp_high45.q, reg2hw.mtimecmp_low45.q};
    assign ipi_o[45] = reg2hw.msip[45].q;
    assign mtimecmp_q[46] = {reg2hw.mtimecmp_high46.q, reg2hw.mtimecmp_low46.q};
    assign ipi_o[46] = reg2hw.msip[46].q;
    assign mtimecmp_q[47] = {reg2hw.mtimecmp_high47.q, reg2hw.mtimecmp_low47.q};
    assign ipi_o[47] = reg2hw.msip[47].q;
    assign mtimecmp_q[48] = {reg2hw.mtimecmp_high48.q, reg2hw.mtimecmp_low48.q};
    assign ipi_o[48] = reg2hw.msip[48].q;
    assign mtimecmp_q[49] = {reg2hw.mtimecmp_high49.q, reg2hw.mtimecmp_low49.q};
    assign ipi_o[49] = reg2hw.msip[49].q;
    assign mtimecmp_q[50] = {reg2hw.mtimecmp_high50.q, reg2hw.mtimecmp_low50.q};
    assign ipi_o[50] = reg2hw.msip[50].q;
    assign mtimecmp_q[51] = {reg2hw.mtimecmp_high51.q, reg2hw.mtimecmp_low51.q};
    assign ipi_o[51] = reg2hw.msip[51].q;
    assign mtimecmp_q[52] = {reg2hw.mtimecmp_high52.q, reg2hw.mtimecmp_low52.q};
    assign ipi_o[52] = reg2hw.msip[52].q;
    assign mtimecmp_q[53] = {reg2hw.mtimecmp_high53.q, reg2hw.mtimecmp_low53.q};
    assign ipi_o[53] = reg2hw.msip[53].q;
    assign mtimecmp_q[54] = {reg2hw.mtimecmp_high54.q, reg2hw.mtimecmp_low54.q};
    assign ipi_o[54] = reg2hw.msip[54].q;
    assign mtimecmp_q[55] = {reg2hw.mtimecmp_high55.q, reg2hw.mtimecmp_low55.q};
    assign ipi_o[55] = reg2hw.msip[55].q;
    assign mtimecmp_q[56] = {reg2hw.mtimecmp_high56.q, reg2hw.mtimecmp_low56.q};
    assign ipi_o[56] = reg2hw.msip[56].q;
    assign mtimecmp_q[57] = {reg2hw.mtimecmp_high57.q, reg2hw.mtimecmp_low57.q};
    assign ipi_o[57] = reg2hw.msip[57].q;
    assign mtimecmp_q[58] = {reg2hw.mtimecmp_high58.q, reg2hw.mtimecmp_low58.q};
    assign ipi_o[58] = reg2hw.msip[58].q;
    assign mtimecmp_q[59] = {reg2hw.mtimecmp_high59.q, reg2hw.mtimecmp_low59.q};
    assign ipi_o[59] = reg2hw.msip[59].q;
    assign mtimecmp_q[60] = {reg2hw.mtimecmp_high60.q, reg2hw.mtimecmp_low60.q};
    assign ipi_o[60] = reg2hw.msip[60].q;
    assign mtimecmp_q[61] = {reg2hw.mtimecmp_high61.q, reg2hw.mtimecmp_low61.q};
    assign ipi_o[61] = reg2hw.msip[61].q;
    assign mtimecmp_q[62] = {reg2hw.mtimecmp_high62.q, reg2hw.mtimecmp_low62.q};
    assign ipi_o[62] = reg2hw.msip[62].q;
    assign mtimecmp_q[63] = {reg2hw.mtimecmp_high63.q, reg2hw.mtimecmp_low63.q};
    assign ipi_o[63] = reg2hw.msip[63].q;
    assign mtimecmp_q[64] = {reg2hw.mtimecmp_high64.q, reg2hw.mtimecmp_low64.q};
    assign ipi_o[64] = reg2hw.msip[64].q;
    assign mtimecmp_q[65] = {reg2hw.mtimecmp_high65.q, reg2hw.mtimecmp_low65.q};
    assign ipi_o[65] = reg2hw.msip[65].q;
    assign mtimecmp_q[66] = {reg2hw.mtimecmp_high66.q, reg2hw.mtimecmp_low66.q};
    assign ipi_o[66] = reg2hw.msip[66].q;
    assign mtimecmp_q[67] = {reg2hw.mtimecmp_high67.q, reg2hw.mtimecmp_low67.q};
    assign ipi_o[67] = reg2hw.msip[67].q;
    assign mtimecmp_q[68] = {reg2hw.mtimecmp_high68.q, reg2hw.mtimecmp_low68.q};
    assign ipi_o[68] = reg2hw.msip[68].q;
    assign mtimecmp_q[69] = {reg2hw.mtimecmp_high69.q, reg2hw.mtimecmp_low69.q};
    assign ipi_o[69] = reg2hw.msip[69].q;
    assign mtimecmp_q[70] = {reg2hw.mtimecmp_high70.q, reg2hw.mtimecmp_low70.q};
    assign ipi_o[70] = reg2hw.msip[70].q;
    assign mtimecmp_q[71] = {reg2hw.mtimecmp_high71.q, reg2hw.mtimecmp_low71.q};
    assign ipi_o[71] = reg2hw.msip[71].q;
    assign mtimecmp_q[72] = {reg2hw.mtimecmp_high72.q, reg2hw.mtimecmp_low72.q};
    assign ipi_o[72] = reg2hw.msip[72].q;
    assign mtimecmp_q[73] = {reg2hw.mtimecmp_high73.q, reg2hw.mtimecmp_low73.q};
    assign ipi_o[73] = reg2hw.msip[73].q;
    assign mtimecmp_q[74] = {reg2hw.mtimecmp_high74.q, reg2hw.mtimecmp_low74.q};
    assign ipi_o[74] = reg2hw.msip[74].q;
    assign mtimecmp_q[75] = {reg2hw.mtimecmp_high75.q, reg2hw.mtimecmp_low75.q};
    assign ipi_o[75] = reg2hw.msip[75].q;
    assign mtimecmp_q[76] = {reg2hw.mtimecmp_high76.q, reg2hw.mtimecmp_low76.q};
    assign ipi_o[76] = reg2hw.msip[76].q;
    assign mtimecmp_q[77] = {reg2hw.mtimecmp_high77.q, reg2hw.mtimecmp_low77.q};
    assign ipi_o[77] = reg2hw.msip[77].q;
    assign mtimecmp_q[78] = {reg2hw.mtimecmp_high78.q, reg2hw.mtimecmp_low78.q};
    assign ipi_o[78] = reg2hw.msip[78].q;
    assign mtimecmp_q[79] = {reg2hw.mtimecmp_high79.q, reg2hw.mtimecmp_low79.q};
    assign ipi_o[79] = reg2hw.msip[79].q;
    assign mtimecmp_q[80] = {reg2hw.mtimecmp_high80.q, reg2hw.mtimecmp_low80.q};
    assign ipi_o[80] = reg2hw.msip[80].q;
    assign mtimecmp_q[81] = {reg2hw.mtimecmp_high81.q, reg2hw.mtimecmp_low81.q};
    assign ipi_o[81] = reg2hw.msip[81].q;
    assign mtimecmp_q[82] = {reg2hw.mtimecmp_high82.q, reg2hw.mtimecmp_low82.q};
    assign ipi_o[82] = reg2hw.msip[82].q;
    assign mtimecmp_q[83] = {reg2hw.mtimecmp_high83.q, reg2hw.mtimecmp_low83.q};
    assign ipi_o[83] = reg2hw.msip[83].q;
    assign mtimecmp_q[84] = {reg2hw.mtimecmp_high84.q, reg2hw.mtimecmp_low84.q};
    assign ipi_o[84] = reg2hw.msip[84].q;
    assign mtimecmp_q[85] = {reg2hw.mtimecmp_high85.q, reg2hw.mtimecmp_low85.q};
    assign ipi_o[85] = reg2hw.msip[85].q;
    assign mtimecmp_q[86] = {reg2hw.mtimecmp_high86.q, reg2hw.mtimecmp_low86.q};
    assign ipi_o[86] = reg2hw.msip[86].q;
    assign mtimecmp_q[87] = {reg2hw.mtimecmp_high87.q, reg2hw.mtimecmp_low87.q};
    assign ipi_o[87] = reg2hw.msip[87].q;
    assign mtimecmp_q[88] = {reg2hw.mtimecmp_high88.q, reg2hw.mtimecmp_low88.q};
    assign ipi_o[88] = reg2hw.msip[88].q;
    assign mtimecmp_q[89] = {reg2hw.mtimecmp_high89.q, reg2hw.mtimecmp_low89.q};
    assign ipi_o[89] = reg2hw.msip[89].q;
    assign mtimecmp_q[90] = {reg2hw.mtimecmp_high90.q, reg2hw.mtimecmp_low90.q};
    assign ipi_o[90] = reg2hw.msip[90].q;
    assign mtimecmp_q[91] = {reg2hw.mtimecmp_high91.q, reg2hw.mtimecmp_low91.q};
    assign ipi_o[91] = reg2hw.msip[91].q;
    assign mtimecmp_q[92] = {reg2hw.mtimecmp_high92.q, reg2hw.mtimecmp_low92.q};
    assign ipi_o[92] = reg2hw.msip[92].q;
    assign mtimecmp_q[93] = {reg2hw.mtimecmp_high93.q, reg2hw.mtimecmp_low93.q};
    assign ipi_o[93] = reg2hw.msip[93].q;
    assign mtimecmp_q[94] = {reg2hw.mtimecmp_high94.q, reg2hw.mtimecmp_low94.q};
    assign ipi_o[94] = reg2hw.msip[94].q;
    assign mtimecmp_q[95] = {reg2hw.mtimecmp_high95.q, reg2hw.mtimecmp_low95.q};
    assign ipi_o[95] = reg2hw.msip[95].q;
    assign mtimecmp_q[96] = {reg2hw.mtimecmp_high96.q, reg2hw.mtimecmp_low96.q};
    assign ipi_o[96] = reg2hw.msip[96].q;
    assign mtimecmp_q[97] = {reg2hw.mtimecmp_high97.q, reg2hw.mtimecmp_low97.q};
    assign ipi_o[97] = reg2hw.msip[97].q;
    assign mtimecmp_q[98] = {reg2hw.mtimecmp_high98.q, reg2hw.mtimecmp_low98.q};
    assign ipi_o[98] = reg2hw.msip[98].q;
    assign mtimecmp_q[99] = {reg2hw.mtimecmp_high99.q, reg2hw.mtimecmp_low99.q};
    assign ipi_o[99] = reg2hw.msip[99].q;
    assign mtimecmp_q[100] = {reg2hw.mtimecmp_high100.q, reg2hw.mtimecmp_low100.q};
    assign ipi_o[100] = reg2hw.msip[100].q;
    assign mtimecmp_q[101] = {reg2hw.mtimecmp_high101.q, reg2hw.mtimecmp_low101.q};
    assign ipi_o[101] = reg2hw.msip[101].q;
    assign mtimecmp_q[102] = {reg2hw.mtimecmp_high102.q, reg2hw.mtimecmp_low102.q};
    assign ipi_o[102] = reg2hw.msip[102].q;
    assign mtimecmp_q[103] = {reg2hw.mtimecmp_high103.q, reg2hw.mtimecmp_low103.q};
    assign ipi_o[103] = reg2hw.msip[103].q;
    assign mtimecmp_q[104] = {reg2hw.mtimecmp_high104.q, reg2hw.mtimecmp_low104.q};
    assign ipi_o[104] = reg2hw.msip[104].q;
    assign mtimecmp_q[105] = {reg2hw.mtimecmp_high105.q, reg2hw.mtimecmp_low105.q};
    assign ipi_o[105] = reg2hw.msip[105].q;
    assign mtimecmp_q[106] = {reg2hw.mtimecmp_high106.q, reg2hw.mtimecmp_low106.q};
    assign ipi_o[106] = reg2hw.msip[106].q;
    assign mtimecmp_q[107] = {reg2hw.mtimecmp_high107.q, reg2hw.mtimecmp_low107.q};
    assign ipi_o[107] = reg2hw.msip[107].q;
    assign mtimecmp_q[108] = {reg2hw.mtimecmp_high108.q, reg2hw.mtimecmp_low108.q};
    assign ipi_o[108] = reg2hw.msip[108].q;
    assign mtimecmp_q[109] = {reg2hw.mtimecmp_high109.q, reg2hw.mtimecmp_low109.q};
    assign ipi_o[109] = reg2hw.msip[109].q;
    assign mtimecmp_q[110] = {reg2hw.mtimecmp_high110.q, reg2hw.mtimecmp_low110.q};
    assign ipi_o[110] = reg2hw.msip[110].q;
    assign mtimecmp_q[111] = {reg2hw.mtimecmp_high111.q, reg2hw.mtimecmp_low111.q};
    assign ipi_o[111] = reg2hw.msip[111].q;
    assign mtimecmp_q[112] = {reg2hw.mtimecmp_high112.q, reg2hw.mtimecmp_low112.q};
    assign ipi_o[112] = reg2hw.msip[112].q;
    assign mtimecmp_q[113] = {reg2hw.mtimecmp_high113.q, reg2hw.mtimecmp_low113.q};
    assign ipi_o[113] = reg2hw.msip[113].q;
    assign mtimecmp_q[114] = {reg2hw.mtimecmp_high114.q, reg2hw.mtimecmp_low114.q};
    assign ipi_o[114] = reg2hw.msip[114].q;
    assign mtimecmp_q[115] = {reg2hw.mtimecmp_high115.q, reg2hw.mtimecmp_low115.q};
    assign ipi_o[115] = reg2hw.msip[115].q;
    assign mtimecmp_q[116] = {reg2hw.mtimecmp_high116.q, reg2hw.mtimecmp_low116.q};
    assign ipi_o[116] = reg2hw.msip[116].q;
    assign mtimecmp_q[117] = {reg2hw.mtimecmp_high117.q, reg2hw.mtimecmp_low117.q};
    assign ipi_o[117] = reg2hw.msip[117].q;
    assign mtimecmp_q[118] = {reg2hw.mtimecmp_high118.q, reg2hw.mtimecmp_low118.q};
    assign ipi_o[118] = reg2hw.msip[118].q;
    assign mtimecmp_q[119] = {reg2hw.mtimecmp_high119.q, reg2hw.mtimecmp_low119.q};
    assign ipi_o[119] = reg2hw.msip[119].q;
    assign mtimecmp_q[120] = {reg2hw.mtimecmp_high120.q, reg2hw.mtimecmp_low120.q};
    assign ipi_o[120] = reg2hw.msip[120].q;
    assign mtimecmp_q[121] = {reg2hw.mtimecmp_high121.q, reg2hw.mtimecmp_low121.q};
    assign ipi_o[121] = reg2hw.msip[121].q;
    assign mtimecmp_q[122] = {reg2hw.mtimecmp_high122.q, reg2hw.mtimecmp_low122.q};
    assign ipi_o[122] = reg2hw.msip[122].q;
    assign mtimecmp_q[123] = {reg2hw.mtimecmp_high123.q, reg2hw.mtimecmp_low123.q};
    assign ipi_o[123] = reg2hw.msip[123].q;
    assign mtimecmp_q[124] = {reg2hw.mtimecmp_high124.q, reg2hw.mtimecmp_low124.q};
    assign ipi_o[124] = reg2hw.msip[124].q;
    assign mtimecmp_q[125] = {reg2hw.mtimecmp_high125.q, reg2hw.mtimecmp_low125.q};
    assign ipi_o[125] = reg2hw.msip[125].q;
    assign mtimecmp_q[126] = {reg2hw.mtimecmp_high126.q, reg2hw.mtimecmp_low126.q};
    assign ipi_o[126] = reg2hw.msip[126].q;
    assign mtimecmp_q[127] = {reg2hw.mtimecmp_high127.q, reg2hw.mtimecmp_low127.q};
    assign ipi_o[127] = reg2hw.msip[127].q;
    assign mtimecmp_q[128] = {reg2hw.mtimecmp_high128.q, reg2hw.mtimecmp_low128.q};
    assign ipi_o[128] = reg2hw.msip[128].q;
    assign mtimecmp_q[129] = {reg2hw.mtimecmp_high129.q, reg2hw.mtimecmp_low129.q};
    assign ipi_o[129] = reg2hw.msip[129].q;
    assign mtimecmp_q[130] = {reg2hw.mtimecmp_high130.q, reg2hw.mtimecmp_low130.q};
    assign ipi_o[130] = reg2hw.msip[130].q;
    assign mtimecmp_q[131] = {reg2hw.mtimecmp_high131.q, reg2hw.mtimecmp_low131.q};
    assign ipi_o[131] = reg2hw.msip[131].q;
    assign mtimecmp_q[132] = {reg2hw.mtimecmp_high132.q, reg2hw.mtimecmp_low132.q};
    assign ipi_o[132] = reg2hw.msip[132].q;
    assign mtimecmp_q[133] = {reg2hw.mtimecmp_high133.q, reg2hw.mtimecmp_low133.q};
    assign ipi_o[133] = reg2hw.msip[133].q;
    assign mtimecmp_q[134] = {reg2hw.mtimecmp_high134.q, reg2hw.mtimecmp_low134.q};
    assign ipi_o[134] = reg2hw.msip[134].q;
    assign mtimecmp_q[135] = {reg2hw.mtimecmp_high135.q, reg2hw.mtimecmp_low135.q};
    assign ipi_o[135] = reg2hw.msip[135].q;
    assign mtimecmp_q[136] = {reg2hw.mtimecmp_high136.q, reg2hw.mtimecmp_low136.q};
    assign ipi_o[136] = reg2hw.msip[136].q;
    assign mtimecmp_q[137] = {reg2hw.mtimecmp_high137.q, reg2hw.mtimecmp_low137.q};
    assign ipi_o[137] = reg2hw.msip[137].q;
    assign mtimecmp_q[138] = {reg2hw.mtimecmp_high138.q, reg2hw.mtimecmp_low138.q};
    assign ipi_o[138] = reg2hw.msip[138].q;
    assign mtimecmp_q[139] = {reg2hw.mtimecmp_high139.q, reg2hw.mtimecmp_low139.q};
    assign ipi_o[139] = reg2hw.msip[139].q;
    assign mtimecmp_q[140] = {reg2hw.mtimecmp_high140.q, reg2hw.mtimecmp_low140.q};
    assign ipi_o[140] = reg2hw.msip[140].q;
    assign mtimecmp_q[141] = {reg2hw.mtimecmp_high141.q, reg2hw.mtimecmp_low141.q};
    assign ipi_o[141] = reg2hw.msip[141].q;
    assign mtimecmp_q[142] = {reg2hw.mtimecmp_high142.q, reg2hw.mtimecmp_low142.q};
    assign ipi_o[142] = reg2hw.msip[142].q;
    assign mtimecmp_q[143] = {reg2hw.mtimecmp_high143.q, reg2hw.mtimecmp_low143.q};
    assign ipi_o[143] = reg2hw.msip[143].q;
    assign mtimecmp_q[144] = {reg2hw.mtimecmp_high144.q, reg2hw.mtimecmp_low144.q};
    assign ipi_o[144] = reg2hw.msip[144].q;
    assign mtimecmp_q[145] = {reg2hw.mtimecmp_high145.q, reg2hw.mtimecmp_low145.q};
    assign ipi_o[145] = reg2hw.msip[145].q;
    assign mtimecmp_q[146] = {reg2hw.mtimecmp_high146.q, reg2hw.mtimecmp_low146.q};
    assign ipi_o[146] = reg2hw.msip[146].q;
    assign mtimecmp_q[147] = {reg2hw.mtimecmp_high147.q, reg2hw.mtimecmp_low147.q};
    assign ipi_o[147] = reg2hw.msip[147].q;
    assign mtimecmp_q[148] = {reg2hw.mtimecmp_high148.q, reg2hw.mtimecmp_low148.q};
    assign ipi_o[148] = reg2hw.msip[148].q;
    assign mtimecmp_q[149] = {reg2hw.mtimecmp_high149.q, reg2hw.mtimecmp_low149.q};
    assign ipi_o[149] = reg2hw.msip[149].q;
    assign mtimecmp_q[150] = {reg2hw.mtimecmp_high150.q, reg2hw.mtimecmp_low150.q};
    assign ipi_o[150] = reg2hw.msip[150].q;
    assign mtimecmp_q[151] = {reg2hw.mtimecmp_high151.q, reg2hw.mtimecmp_low151.q};
    assign ipi_o[151] = reg2hw.msip[151].q;
    assign mtimecmp_q[152] = {reg2hw.mtimecmp_high152.q, reg2hw.mtimecmp_low152.q};
    assign ipi_o[152] = reg2hw.msip[152].q;
    assign mtimecmp_q[153] = {reg2hw.mtimecmp_high153.q, reg2hw.mtimecmp_low153.q};
    assign ipi_o[153] = reg2hw.msip[153].q;
    assign mtimecmp_q[154] = {reg2hw.mtimecmp_high154.q, reg2hw.mtimecmp_low154.q};
    assign ipi_o[154] = reg2hw.msip[154].q;
    assign mtimecmp_q[155] = {reg2hw.mtimecmp_high155.q, reg2hw.mtimecmp_low155.q};
    assign ipi_o[155] = reg2hw.msip[155].q;
    assign mtimecmp_q[156] = {reg2hw.mtimecmp_high156.q, reg2hw.mtimecmp_low156.q};
    assign ipi_o[156] = reg2hw.msip[156].q;
    assign mtimecmp_q[157] = {reg2hw.mtimecmp_high157.q, reg2hw.mtimecmp_low157.q};
    assign ipi_o[157] = reg2hw.msip[157].q;
    assign mtimecmp_q[158] = {reg2hw.mtimecmp_high158.q, reg2hw.mtimecmp_low158.q};
    assign ipi_o[158] = reg2hw.msip[158].q;
    assign mtimecmp_q[159] = {reg2hw.mtimecmp_high159.q, reg2hw.mtimecmp_low159.q};
    assign ipi_o[159] = reg2hw.msip[159].q;
    assign mtimecmp_q[160] = {reg2hw.mtimecmp_high160.q, reg2hw.mtimecmp_low160.q};
    assign ipi_o[160] = reg2hw.msip[160].q;
    assign mtimecmp_q[161] = {reg2hw.mtimecmp_high161.q, reg2hw.mtimecmp_low161.q};
    assign ipi_o[161] = reg2hw.msip[161].q;
    assign mtimecmp_q[162] = {reg2hw.mtimecmp_high162.q, reg2hw.mtimecmp_low162.q};
    assign ipi_o[162] = reg2hw.msip[162].q;
    assign mtimecmp_q[163] = {reg2hw.mtimecmp_high163.q, reg2hw.mtimecmp_low163.q};
    assign ipi_o[163] = reg2hw.msip[163].q;
    assign mtimecmp_q[164] = {reg2hw.mtimecmp_high164.q, reg2hw.mtimecmp_low164.q};
    assign ipi_o[164] = reg2hw.msip[164].q;
    assign mtimecmp_q[165] = {reg2hw.mtimecmp_high165.q, reg2hw.mtimecmp_low165.q};
    assign ipi_o[165] = reg2hw.msip[165].q;
    assign mtimecmp_q[166] = {reg2hw.mtimecmp_high166.q, reg2hw.mtimecmp_low166.q};
    assign ipi_o[166] = reg2hw.msip[166].q;
    assign mtimecmp_q[167] = {reg2hw.mtimecmp_high167.q, reg2hw.mtimecmp_low167.q};
    assign ipi_o[167] = reg2hw.msip[167].q;
    assign mtimecmp_q[168] = {reg2hw.mtimecmp_high168.q, reg2hw.mtimecmp_low168.q};
    assign ipi_o[168] = reg2hw.msip[168].q;
    assign mtimecmp_q[169] = {reg2hw.mtimecmp_high169.q, reg2hw.mtimecmp_low169.q};
    assign ipi_o[169] = reg2hw.msip[169].q;
    assign mtimecmp_q[170] = {reg2hw.mtimecmp_high170.q, reg2hw.mtimecmp_low170.q};
    assign ipi_o[170] = reg2hw.msip[170].q;
    assign mtimecmp_q[171] = {reg2hw.mtimecmp_high171.q, reg2hw.mtimecmp_low171.q};
    assign ipi_o[171] = reg2hw.msip[171].q;
    assign mtimecmp_q[172] = {reg2hw.mtimecmp_high172.q, reg2hw.mtimecmp_low172.q};
    assign ipi_o[172] = reg2hw.msip[172].q;
    assign mtimecmp_q[173] = {reg2hw.mtimecmp_high173.q, reg2hw.mtimecmp_low173.q};
    assign ipi_o[173] = reg2hw.msip[173].q;
    assign mtimecmp_q[174] = {reg2hw.mtimecmp_high174.q, reg2hw.mtimecmp_low174.q};
    assign ipi_o[174] = reg2hw.msip[174].q;
    assign mtimecmp_q[175] = {reg2hw.mtimecmp_high175.q, reg2hw.mtimecmp_low175.q};
    assign ipi_o[175] = reg2hw.msip[175].q;
    assign mtimecmp_q[176] = {reg2hw.mtimecmp_high176.q, reg2hw.mtimecmp_low176.q};
    assign ipi_o[176] = reg2hw.msip[176].q;
    assign mtimecmp_q[177] = {reg2hw.mtimecmp_high177.q, reg2hw.mtimecmp_low177.q};
    assign ipi_o[177] = reg2hw.msip[177].q;
    assign mtimecmp_q[178] = {reg2hw.mtimecmp_high178.q, reg2hw.mtimecmp_low178.q};
    assign ipi_o[178] = reg2hw.msip[178].q;
    assign mtimecmp_q[179] = {reg2hw.mtimecmp_high179.q, reg2hw.mtimecmp_low179.q};
    assign ipi_o[179] = reg2hw.msip[179].q;
    assign mtimecmp_q[180] = {reg2hw.mtimecmp_high180.q, reg2hw.mtimecmp_low180.q};
    assign ipi_o[180] = reg2hw.msip[180].q;
    assign mtimecmp_q[181] = {reg2hw.mtimecmp_high181.q, reg2hw.mtimecmp_low181.q};
    assign ipi_o[181] = reg2hw.msip[181].q;
    assign mtimecmp_q[182] = {reg2hw.mtimecmp_high182.q, reg2hw.mtimecmp_low182.q};
    assign ipi_o[182] = reg2hw.msip[182].q;
    assign mtimecmp_q[183] = {reg2hw.mtimecmp_high183.q, reg2hw.mtimecmp_low183.q};
    assign ipi_o[183] = reg2hw.msip[183].q;
    assign mtimecmp_q[184] = {reg2hw.mtimecmp_high184.q, reg2hw.mtimecmp_low184.q};
    assign ipi_o[184] = reg2hw.msip[184].q;
    assign mtimecmp_q[185] = {reg2hw.mtimecmp_high185.q, reg2hw.mtimecmp_low185.q};
    assign ipi_o[185] = reg2hw.msip[185].q;
    assign mtimecmp_q[186] = {reg2hw.mtimecmp_high186.q, reg2hw.mtimecmp_low186.q};
    assign ipi_o[186] = reg2hw.msip[186].q;
    assign mtimecmp_q[187] = {reg2hw.mtimecmp_high187.q, reg2hw.mtimecmp_low187.q};
    assign ipi_o[187] = reg2hw.msip[187].q;
    assign mtimecmp_q[188] = {reg2hw.mtimecmp_high188.q, reg2hw.mtimecmp_low188.q};
    assign ipi_o[188] = reg2hw.msip[188].q;
    assign mtimecmp_q[189] = {reg2hw.mtimecmp_high189.q, reg2hw.mtimecmp_low189.q};
    assign ipi_o[189] = reg2hw.msip[189].q;
    assign mtimecmp_q[190] = {reg2hw.mtimecmp_high190.q, reg2hw.mtimecmp_low190.q};
    assign ipi_o[190] = reg2hw.msip[190].q;
    assign mtimecmp_q[191] = {reg2hw.mtimecmp_high191.q, reg2hw.mtimecmp_low191.q};
    assign ipi_o[191] = reg2hw.msip[191].q;
    assign mtimecmp_q[192] = {reg2hw.mtimecmp_high192.q, reg2hw.mtimecmp_low192.q};
    assign ipi_o[192] = reg2hw.msip[192].q;
    assign mtimecmp_q[193] = {reg2hw.mtimecmp_high193.q, reg2hw.mtimecmp_low193.q};
    assign ipi_o[193] = reg2hw.msip[193].q;
    assign mtimecmp_q[194] = {reg2hw.mtimecmp_high194.q, reg2hw.mtimecmp_low194.q};
    assign ipi_o[194] = reg2hw.msip[194].q;
    assign mtimecmp_q[195] = {reg2hw.mtimecmp_high195.q, reg2hw.mtimecmp_low195.q};
    assign ipi_o[195] = reg2hw.msip[195].q;
    assign mtimecmp_q[196] = {reg2hw.mtimecmp_high196.q, reg2hw.mtimecmp_low196.q};
    assign ipi_o[196] = reg2hw.msip[196].q;
    assign mtimecmp_q[197] = {reg2hw.mtimecmp_high197.q, reg2hw.mtimecmp_low197.q};
    assign ipi_o[197] = reg2hw.msip[197].q;
    assign mtimecmp_q[198] = {reg2hw.mtimecmp_high198.q, reg2hw.mtimecmp_low198.q};
    assign ipi_o[198] = reg2hw.msip[198].q;
    assign mtimecmp_q[199] = {reg2hw.mtimecmp_high199.q, reg2hw.mtimecmp_low199.q};
    assign ipi_o[199] = reg2hw.msip[199].q;
    assign mtimecmp_q[200] = {reg2hw.mtimecmp_high200.q, reg2hw.mtimecmp_low200.q};
    assign ipi_o[200] = reg2hw.msip[200].q;
    assign mtimecmp_q[201] = {reg2hw.mtimecmp_high201.q, reg2hw.mtimecmp_low201.q};
    assign ipi_o[201] = reg2hw.msip[201].q;
    assign mtimecmp_q[202] = {reg2hw.mtimecmp_high202.q, reg2hw.mtimecmp_low202.q};
    assign ipi_o[202] = reg2hw.msip[202].q;
    assign mtimecmp_q[203] = {reg2hw.mtimecmp_high203.q, reg2hw.mtimecmp_low203.q};
    assign ipi_o[203] = reg2hw.msip[203].q;
    assign mtimecmp_q[204] = {reg2hw.mtimecmp_high204.q, reg2hw.mtimecmp_low204.q};
    assign ipi_o[204] = reg2hw.msip[204].q;
    assign mtimecmp_q[205] = {reg2hw.mtimecmp_high205.q, reg2hw.mtimecmp_low205.q};
    assign ipi_o[205] = reg2hw.msip[205].q;
    assign mtimecmp_q[206] = {reg2hw.mtimecmp_high206.q, reg2hw.mtimecmp_low206.q};
    assign ipi_o[206] = reg2hw.msip[206].q;
    assign mtimecmp_q[207] = {reg2hw.mtimecmp_high207.q, reg2hw.mtimecmp_low207.q};
    assign ipi_o[207] = reg2hw.msip[207].q;
    assign mtimecmp_q[208] = {reg2hw.mtimecmp_high208.q, reg2hw.mtimecmp_low208.q};
    assign ipi_o[208] = reg2hw.msip[208].q;
    assign mtimecmp_q[209] = {reg2hw.mtimecmp_high209.q, reg2hw.mtimecmp_low209.q};
    assign ipi_o[209] = reg2hw.msip[209].q;
    assign mtimecmp_q[210] = {reg2hw.mtimecmp_high210.q, reg2hw.mtimecmp_low210.q};
    assign ipi_o[210] = reg2hw.msip[210].q;
    assign mtimecmp_q[211] = {reg2hw.mtimecmp_high211.q, reg2hw.mtimecmp_low211.q};
    assign ipi_o[211] = reg2hw.msip[211].q;
    assign mtimecmp_q[212] = {reg2hw.mtimecmp_high212.q, reg2hw.mtimecmp_low212.q};
    assign ipi_o[212] = reg2hw.msip[212].q;
    assign mtimecmp_q[213] = {reg2hw.mtimecmp_high213.q, reg2hw.mtimecmp_low213.q};
    assign ipi_o[213] = reg2hw.msip[213].q;
    assign mtimecmp_q[214] = {reg2hw.mtimecmp_high214.q, reg2hw.mtimecmp_low214.q};
    assign ipi_o[214] = reg2hw.msip[214].q;
    assign mtimecmp_q[215] = {reg2hw.mtimecmp_high215.q, reg2hw.mtimecmp_low215.q};
    assign ipi_o[215] = reg2hw.msip[215].q;
    assign mtimecmp_q[216] = {reg2hw.mtimecmp_high216.q, reg2hw.mtimecmp_low216.q};
    assign ipi_o[216] = reg2hw.msip[216].q;

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
        for (int unsigned i = 0; i < 217; i++) begin
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
