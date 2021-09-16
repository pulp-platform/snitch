// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Thomas Benz <tbenz@ethz.ch>

`include "common_cells/registers.svh"

// Sample implementation of performance counters.
module axi_dma_perf_counters #(
    parameter int unsigned TRANSFER_ID_WIDTH  = -1,
    parameter int unsigned DATA_WIDTH         = -1,
    parameter type         axi_req_t          = logic,
    parameter type         axi_res_t          = logic,
    parameter type         dma_events_t       = logic,
    localparam bit         EnablePerfCounters = 0
) (
    input  logic                         clk_i,
    input  logic                         rst_ni,
    // AXI4 bus
    input  axi_req_t                     axi_dma_req_i,
    input  axi_res_t                     axi_dma_res_i,
    // ID input
    input  logic [TRANSFER_ID_WIDTH-1:0] next_id_i,
    input  logic [TRANSFER_ID_WIDTH-1:0] completed_id_i,
    // DMA busy
    input  logic                         dma_busy_i,
    // performance bus
    output axi_dma_pkg::dma_perf_t       dma_perf_o,
    output dma_events_t                  dma_events_o
);

    localparam int unsigned StrbWidth = DATA_WIDTH / 8;

    // internal state
    axi_dma_pkg::dma_perf_t dma_perf_d, dma_perf_q;

    // Event counter
    dma_events_t dma_events;

    // need popcount common cell to get the number of bytes active in the strobe signal
    logic [$clog2(StrbWidth)+1-1:0] num_bytes_written;
    popcount #(
        .INPUT_WIDTH ( StrbWidth  )
    ) i_popcount (
        .data_i      ( axi_dma_req_i.w.strb   ),
        .popcount_o  ( num_bytes_written      )
    );

    // see if counters should be increased
    always_comb begin : proc_next_perf_state

        // default: keep old value
        dma_perf_d = dma_perf_q;
        dma_events = '0;

        // aw
        if ( axi_dma_req_i.aw_valid) begin
          dma_perf_d.aw_valid_cnt = dma_perf_q.aw_valid_cnt + 'h1;
          dma_events.aw_valid = 1'b1;
        end

        if ( axi_dma_res_i.aw_ready) begin
          dma_perf_d.aw_ready_cnt = dma_perf_q.aw_ready_cnt + 'h1;
          dma_events.aw_ready = 1'b1;
        end

        if ( axi_dma_res_i.aw_ready && axi_dma_req_i.aw_valid) begin
          dma_perf_d.aw_done_cnt  = dma_perf_q.aw_done_cnt  + 'h1;
          dma_events.aw_done = 1'b1;
        end

        if ( axi_dma_res_i.aw_ready && axi_dma_req_i.aw_valid) begin
          dma_perf_d.aw_bw =
            dma_perf_q.aw_bw + ((axi_dma_req_i.aw.len + 1) << axi_dma_req_i.aw.size);
          dma_events.aw_len = axi_dma_req_i.aw.len;
          dma_events.aw_size = axi_dma_req_i.aw.size;
        end

        if (!axi_dma_res_i.aw_ready && axi_dma_req_i.aw_valid) begin
          dma_perf_d.aw_stall_cnt = dma_perf_q.aw_stall_cnt + 'h1;
          dma_events.aw_stall = 1'b1;
        end


        // ar
        if (axi_dma_req_i.ar_valid) begin
          dma_perf_d.ar_valid_cnt = dma_perf_q.ar_valid_cnt + 'h1;
          dma_events.ar_valid = 1'b1;
        end
        if (axi_dma_res_i.ar_ready) begin
          dma_perf_d.ar_ready_cnt = dma_perf_q.ar_ready_cnt + 'h1;
          dma_events.ar_ready = 1'b1;
        end
        if (axi_dma_res_i.ar_ready && axi_dma_req_i.ar_valid) begin
          dma_perf_d.ar_done_cnt  = dma_perf_q.ar_done_cnt  + 'h1;
          dma_events.ar_done = 1'b1;
        end
        if (axi_dma_res_i.ar_ready && axi_dma_req_i.ar_valid) begin
          dma_perf_d.ar_bw        =
            dma_perf_q.ar_bw        + ((axi_dma_req_i.ar.len + 1) << axi_dma_req_i.ar.size);
          dma_events.ar_len = axi_dma_req_i.ar.len;
          dma_events.ar_size = axi_dma_req_i.ar.size;
        end
        if (!axi_dma_res_i.ar_ready && axi_dma_req_i.ar_valid) begin
          dma_perf_d.ar_stall_cnt = dma_perf_q.ar_stall_cnt + 'h1;
          dma_events.ar_stall = 1'b1;
        end

        // r
        if (axi_dma_res_i.r_valid) begin
          dma_perf_d.r_valid_cnt  = dma_perf_q.r_valid_cnt  + 'h1;
          dma_events.r_valid = 1'b1;
        end
        if (axi_dma_req_i.r_ready) begin
          dma_perf_d.r_ready_cnt  = dma_perf_q.r_ready_cnt  + 'h1;
          dma_events.r_ready = 1'b1;
        end
        if (axi_dma_req_i.r_ready &&  axi_dma_res_i.r_valid) begin
          dma_perf_d.r_done_cnt   = dma_perf_q.r_done_cnt   + 'h1;
          dma_events.r_done = 1'b1;
        end
        if (axi_dma_req_i.r_ready &&  axi_dma_res_i.r_valid) begin
          dma_perf_d.r_bw         = dma_perf_q.r_bw         + DATA_WIDTH / 8;
          dma_events.r_bw = 1'b1;
        end
        if (axi_dma_req_i.r_ready && !axi_dma_res_i.r_valid) begin
          dma_perf_d.r_stall_cnt  = dma_perf_q.r_stall_cnt  + 'h1;
          dma_events.r_stall = 1'b1;
        end

        // w
        if (axi_dma_req_i.w_valid) begin
          dma_perf_d.w_valid_cnt  = dma_perf_q.w_valid_cnt  + 'h1;
          dma_events.w_valid = 1'b1;
        end
        if (axi_dma_res_i.w_ready) begin
          dma_perf_d.w_ready_cnt  = dma_perf_q.w_ready_cnt  + 'h1;
          dma_events.w_ready = 1'b1;
        end
        if (axi_dma_res_i.w_ready && axi_dma_req_i.w_valid) begin
          dma_perf_d.w_done_cnt   = dma_perf_q.w_done_cnt   + 'h1;
          dma_events.w_done = 1'b1;
        end
        if (axi_dma_res_i.w_ready && axi_dma_req_i.w_valid) begin
          dma_perf_d.w_bw         = dma_perf_q.w_bw         + num_bytes_written;
          dma_events.num_bytes_written = num_bytes_written;
        end
        if (!axi_dma_res_i.w_ready && axi_dma_req_i.w_valid) begin
          dma_perf_d.w_stall_cnt  = dma_perf_q.w_stall_cnt  + 'h1;
          dma_events.w_stall = 1'b1;
        end

        // b
        if (axi_dma_res_i.b_valid) begin
          dma_perf_d.b_valid_cnt  = dma_perf_q.b_valid_cnt  + 'h1;
          dma_events.b_valid = 1'b1;
        end
        if (axi_dma_req_i.b_ready) begin
          dma_perf_d.b_ready_cnt  = dma_perf_q.b_ready_cnt  + 'h1;
          dma_events.b_ready = 1'b1;
        end
        if (axi_dma_req_i.b_ready && axi_dma_res_i.b_valid) begin
          dma_perf_d.b_done_cnt   = dma_perf_q.b_done_cnt   + 'h1;
          dma_events.b_done = 1'b1;
        end

        // buffer
        if ( axi_dma_res_i.w_ready && !axi_dma_req_i.w_valid) begin
          dma_perf_d.buf_w_stall_cnt = dma_perf_q.buf_w_stall_cnt + 'h1;
          dma_events.w_stall = 1'b1;
        end
        if (!axi_dma_req_i.r_ready &&  axi_dma_res_i.r_valid) begin
          dma_perf_d.buf_r_stall_cnt = dma_perf_q.buf_r_stall_cnt + 'h1;
          dma_events.r_stall = 1'b1;
        end

        // ids
        dma_perf_d.next_id      = 32'h0 + next_id_i;
        dma_perf_d.completed_id = 32'h0 + completed_id_i;

        // busy
        if (dma_busy_i) begin
          dma_perf_d.dma_busy_cnt = dma_perf_q.dma_busy_cnt + 'h1;
          dma_events.dma_busy = 1'b1;
        end
    end

    assign dma_events_o = dma_events;

    if (EnablePerfCounters) begin : gen_perf_counters
      `FF(dma_perf_q, dma_perf_d, 0);
      assign dma_perf_o = dma_perf_q;
    end



endmodule
