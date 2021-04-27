// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

/// Exposes cluster confugration and information as memory mapped information

`include "common_cells/registers.svh"

module snitch_cluster_peripheral
  import snitch_pkg::*;
  import snitch_cluster_peripheral_reg_pkg::*;
#(
  parameter int unsigned AddrWidth = 0,
  parameter type reg_req_t = logic,
  parameter type reg_rsp_t = logic,
  parameter type         tcdm_events_t = logic,
  // Nr of course in the cluster
  parameter logic [31:0] NrCores       = 0,
  /// Derived parameter *Do not override*
  parameter type addr_t = logic [AddrWidth-1:0]
) (
  input  logic                       clk_i,
  input  logic                       rst_ni,

  input  reg_req_t                   reg_req_i,
  output reg_rsp_t                   reg_rsp_o,

  input  addr_t                      tcdm_start_address_i,
  input  addr_t                      tcdm_end_address_i,
  output logic [NrCores-1:0]         wake_up_o,
  input  logic [9:0]                 cluster_hart_base_id_i,
  input  core_events_t [NrCores-1:0] core_events_i,
  input  tcdm_events_t               tcdm_events_i
);

  // Pipeline register to ease timing.
  tcdm_events_t tcdm_events_q;
  `FF(tcdm_events_q, tcdm_events_i, '0)

  snitch_cluster_peripheral_reg2hw_t reg2hw;
  snitch_cluster_peripheral_hw2reg_t hw2reg;

  snitch_cluster_peripheral_reg_top #(
    .reg_req_t (reg_req_t),
    .reg_rsp_t (reg_rsp_t)
  ) i_snitch_cluster_peripheral_reg_top (
    .clk_i (clk_i),
    .rst_ni (rst_ni),
    .reg_req_i (reg_req_i),
    .reg_rsp_o (reg_rsp_o),
    .devmode_i (1'b0),
    .reg2hw (reg2hw),
    .hw2reg (hw2reg)
  );

  logic [47:0][NumPerfCounters-1:0] perf_counter_d, perf_counter_q;

  // Wake-up logic.
  // Deprecate in favor of RISC-V interrupts.
  always_comb begin
    wake_up_o = '0;
    if (reg2hw.wake_up.qe) begin
      if (reg2hw.wake_up.q == '1) begin
        wake_up_o = '1;
      end else begin
        wake_up_o[reg2hw.wake_up.q] = 1'b1;
      end
    end
  end

  // Continuously assign the perf values.
  for (genvar i = 0; i < NumPerfCounters; i++) begin : gen_perf_assign
    assign hw2reg.perf_counter[i].d = perf_counter_q[i];
    assign hw2reg.perf_counter[i].de = 1'b1;
  end

  // The hardware barrier is external and always reads `0`.
  assign hw2reg.hw_barrier.d = 0;

  always_comb begin
    perf_counter_d = perf_counter_q;
    for (int i = 0; i < NumPerfCounters; i++) begin
      automatic core_events_t sel_core_events;
      sel_core_events = core_events_i[reg2hw.hart_select[i].q[$clog2(NrCores):0]];
      // Cycle
      if (reg2hw.perf_counter_enable[i].cycle.q) begin
        perf_counter_d[i]++;
      end
      // TCDM Accessed
      if (reg2hw.perf_counter_enable[i].tcdm_accessed.q) begin
        perf_counter_d[i] = perf_counter_d[i] + tcdm_events_q.inc_accessed;
      end
      // TCDM Congested
      if (reg2hw.perf_counter_enable[i].tcdm_accessed.q) begin
        perf_counter_d[i] = perf_counter_d[i] + tcdm_events_q.inc_congested;
      end
      // Per-hart performance counter.
      // Issue FPU
      if (reg2hw.perf_counter_enable[i].issue_fpu.q) begin
        perf_counter_d[i] = perf_counter_d[i] + sel_core_events.issue_fpu;
      end
      // Issue FPU Sequencer
      if (reg2hw.perf_counter_enable[i].issue_fpu_seq.q) begin
        perf_counter_d[i] = perf_counter_d[i] + sel_core_events.issue_fpu_seq;
      end
      // Issue Core to FPU
      if (reg2hw.perf_counter_enable[i].issue_core_to_fpu.q) begin
        perf_counter_d[i] = perf_counter_d[i] + sel_core_events.issue_core_to_fpu;
      end
    end
  end

  `FFNR(perf_counter_q, perf_counter_d, clk_i)

endmodule
