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
  parameter int unsigned DMADataWidth = 0,
  parameter type reg_req_t = logic,
  parameter type reg_rsp_t = logic,
  parameter type         tcdm_events_t = logic,
  parameter type         dma_events_t = logic,
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
  output logic                       icache_prefetch_enable_o,
  output logic [NrCores-1:0]         cl_clint_o,
  input  logic [9:0]                 cluster_hart_base_id_i,
  input  core_events_t [NrCores-1:0] core_events_i,
  input  tcdm_events_t               tcdm_events_i,
  input  dma_events_t                dma_events_i,
  input  snitch_icache_pkg::icache_events_t [NrCores-1:0] icache_events_i
);

  // Pipeline register to ease timing.
  tcdm_events_t tcdm_events_q;
  dma_events_t dma_events_q;
  snitch_icache_pkg::icache_events_t [NrCores-1:0] icache_events_q;
  `FF(tcdm_events_q, tcdm_events_i, '0)
  `FF(dma_events_q, dma_events_i, '0)
  `FF(icache_events_q, icache_events_i, '0)

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

  logic [NumPerfCounters-1:0][47:0] perf_counter_d, perf_counter_q;
  logic [31:0] cl_clint_d, cl_clint_q;

  // Wake-up logic: Bits in cl_clint_q can be set/cleared with writes to
  // cl_clint_set/cl_clint_clear
  always_comb begin
    cl_clint_d = cl_clint_q;
    if (reg2hw.cl_clint_set.qe) begin
      cl_clint_d = cl_clint_q | reg2hw.cl_clint_set.q;
    end else if (reg2hw.cl_clint_clear.qe) begin
      cl_clint_d = cl_clint_q & ~reg2hw.cl_clint_clear.q;
    end
  end
  `FF(cl_clint_q, cl_clint_d, '0, clk_i, rst_ni)
  assign cl_clint_o = cl_clint_q[NrCores-1:0];

  // Enable icache prefetch
  assign icache_prefetch_enable_o = reg2hw.icache_prefetch_enable.q;

  // Continuously assign the perf values.
  for (genvar i = 0; i < NumPerfCounters; i++) begin : gen_perf_assign
    assign hw2reg.perf_counter[i].d = perf_counter_q[i];
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
      else if (reg2hw.perf_counter_enable[i].tcdm_accessed.q) begin
        perf_counter_d[i] = perf_counter_d[i] + tcdm_events_q.inc_accessed;
      end
      // TCDM Congested
      else if (reg2hw.perf_counter_enable[i].tcdm_congested.q) begin
        perf_counter_d[i] = perf_counter_d[i] + tcdm_events_q.inc_congested;
      end
      // Per-hart performance counter.
      // Issue FPU
      else if (reg2hw.perf_counter_enable[i].issue_fpu.q) begin
        perf_counter_d[i] = perf_counter_d[i] + sel_core_events.issue_fpu;
      end
      // Issue FPU Sequencer
      else if (reg2hw.perf_counter_enable[i].issue_fpu_seq.q) begin
        perf_counter_d[i] = perf_counter_d[i] + sel_core_events.issue_fpu_seq;
      end
      // Issue Core to FPU
      else if (reg2hw.perf_counter_enable[i].issue_core_to_fpu.q) begin
        perf_counter_d[i] = perf_counter_d[i] + sel_core_events.issue_core_to_fpu;
      end
      // Retired instructions
      else if (reg2hw.perf_counter_enable[i].retired_instr.q) begin
        perf_counter_d[i] = perf_counter_d[i] + sel_core_events.retired_instr;
      end
      // Retired load instructions
      else if (reg2hw.perf_counter_enable[i].retired_load.q) begin
        perf_counter_d[i] = perf_counter_d[i] + sel_core_events.retired_load;
      end
      // Retired base instructions
      else if (reg2hw.perf_counter_enable[i].retired_i.q) begin
        perf_counter_d[i] = perf_counter_d[i] + sel_core_events.retired_i;
      end
      // Retired offloaded instructions
      else if (reg2hw.perf_counter_enable[i].retired_acc.q) begin
        perf_counter_d[i] = perf_counter_d[i] + sel_core_events.retired_acc;
      end
      // DMA AW stall
      else if (reg2hw.perf_counter_enable[i].dma_aw_stall.q) begin
        perf_counter_d[i] = perf_counter_d[i] + dma_events_q.aw_stall;
      end
      // DMA AR stall
      else if (reg2hw.perf_counter_enable[i].dma_ar_stall.q) begin
        perf_counter_d[i] = perf_counter_d[i] + dma_events_q.ar_stall;
      end
      // DMA R stall
      else if (reg2hw.perf_counter_enable[i].dma_r_stall.q) begin
        perf_counter_d[i] = perf_counter_d[i] + dma_events_q.r_stall;
      end
      // DMA W stall
      else if (reg2hw.perf_counter_enable[i].dma_w_stall.q) begin
        perf_counter_d[i] = perf_counter_d[i] + dma_events_q.w_stall;
      end
      // DMA BUF W stall
      else if (reg2hw.perf_counter_enable[i].dma_buf_w_stall.q) begin
        perf_counter_d[i] = perf_counter_d[i] + dma_events_q.buf_w_stall;
      end
      // DMA BUF R stall
      else if (reg2hw.perf_counter_enable[i].dma_buf_r_stall.q) begin
        perf_counter_d[i] = perf_counter_d[i] + dma_events_q.buf_r_stall;
      end
      // DMA AW done
      else if (reg2hw.perf_counter_enable[i].dma_aw_done.q) begin
        perf_counter_d[i] = perf_counter_d[i] + dma_events_q.aw_done;
      end
      // DMA AW BW
      else if (reg2hw.perf_counter_enable[i].dma_aw_bw.q &&
                dma_events_q.aw_done) begin
        perf_counter_d[i] = perf_counter_d[i] +
              ((dma_events_q.aw_len + 1) << (dma_events_q.aw_size));
      end
      // DMA AR done
      else if (reg2hw.perf_counter_enable[i].dma_ar_done.q) begin
        perf_counter_d[i] = perf_counter_d[i] + dma_events_q.ar_done;
      end
      // DMA AR BW
      else if (reg2hw.perf_counter_enable[i].dma_ar_bw.q &&
                dma_events_q.ar_done) begin
          perf_counter_d[i] = perf_counter_d[i] +
                ((dma_events_q.ar_len + 1) << (dma_events_q.ar_size));
      end
      // DMA R done
      else if (reg2hw.perf_counter_enable[i].dma_r_done.q) begin
        perf_counter_d[i] = perf_counter_d[i] + dma_events_q.r_done;
      end
      // DMA R BW
      else if (reg2hw.perf_counter_enable[i].dma_r_bw.q &&
                dma_events_q.r_done) begin
        perf_counter_d[i] = perf_counter_d[i] + DMADataWidth/8;
      end
      // DMA W done
      else if (reg2hw.perf_counter_enable[i].dma_w_done.q) begin
        perf_counter_d[i] = perf_counter_d[i] + dma_events_q.w_done;
      end
      // DMA W BW
      else if (reg2hw.perf_counter_enable[i].dma_w_bw.q &&
                dma_events_q.w_done) begin
        perf_counter_d[i] = perf_counter_d[i] + dma_events_q.num_bytes_written;
      end
      // DMA B done
      else if (reg2hw.perf_counter_enable[i].dma_b_done.q) begin
        perf_counter_d[i] = perf_counter_d[i] + dma_events_q.b_done;
      end
      // DMA busy
      else if (reg2hw.perf_counter_enable[i].dma_busy.q) begin
        perf_counter_d[i] = perf_counter_d[i] + dma_events_q.dma_busy;
      end
      // icache miss
      else if (reg2hw.perf_counter_enable[i].icache_miss.q) begin
        perf_counter_d[i] = perf_counter_d[i] +
              icache_events_q[reg2hw.hart_select[i].q].l0_miss;
      end
      // icache hit
      else if (reg2hw.perf_counter_enable[i].icache_hit.q) begin
        perf_counter_d[i] = perf_counter_d[i] +
              icache_events_q[reg2hw.hart_select[i].q].l0_hit;
      end
      // icache prefetch
      else if (reg2hw.perf_counter_enable[i].icache_prefetch.q) begin
        perf_counter_d[i] = perf_counter_d[i] +
              icache_events_q[reg2hw.hart_select[i].q].l0_prefetch;
      end
      // icache double hit
        else if (reg2hw.perf_counter_enable[i].icache_double_hit.q) begin
        perf_counter_d[i] = perf_counter_d[i] +
              icache_events_q[reg2hw.hart_select[i].q].l0_double_hit;
      end
      // icache stall
      else if (reg2hw.perf_counter_enable[i].icache_stall.q) begin
        perf_counter_d[i] = perf_counter_d[i] +
              icache_events_q[reg2hw.hart_select[i].q].l0_stall;
      end
      // Reset performance counter.
      if (reg2hw.perf_counter[i].qe) begin
        perf_counter_d[i] = reg2hw.perf_counter[i].q;
      end
    end
  end

  `FF(perf_counter_q, perf_counter_d, '0, clk_i, rst_ni)

endmodule
