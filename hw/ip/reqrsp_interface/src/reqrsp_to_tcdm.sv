// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Fabian Schuiki <fschuiki@iis.ee.ethz.ch>

/// A protocol adapter from REQRSP to TCDM.
module reqrsp_to_tcdm #(
    /// The address width. >=1.
    parameter int AW = -1,
    /// The data width. >=1.
    parameter int DW = -1,
    /// The ID width. >=0.
    parameter int IW = -1,
    /// The number of TCDM requests that can be in flight at most. >=1.
    parameter int NUM_PENDING = 2
)(
    input  logic            clk_i        ,
    input  logic            rst_ni       ,

    REQRSP_BUS.in           reqrsp_i     ,

    output logic [AW-1:0]   tcdm_add     ,
    output logic            tcdm_wen     ,
    output logic [DW-1:0]   tcdm_wdata   ,
    output logic [DW/8-1:0] tcdm_be      ,
    output logic            tcdm_req     ,
    input  logic            tcdm_gnt     ,
    input  logic [DW-1:0]   tcdm_r_rdata ,
    input  logic            tcdm_r_valid
);

    // Check invariants.
    `ifndef SYNTHESIS
    initial begin
        assert(AW > 0);
        assert(DW > 0);
        assert(IW >= 0);
        assert(NUM_PENDING > 0);
        assert(reqrsp_i.ADDR_WIDTH == AW);
        assert(reqrsp_i.DATA_WIDTH == DW);
    end
    `endif

    // The request counter makes sure that at most NUM_PENDING requests are in
    // flight simultaneously. This ensures that the queue can always capture all
    // responses.
    localparam int W = $clog2(NUM_PENDING+1);
    logic [W-1:0] count_q, count_d;

    always_ff @(posedge clk_i, negedge rst_ni) begin : ps_count
        if (!rst_ni)
            count_q <= '0;
        else
            count_q <= count_d;
    end

    always_comb begin : pc_count
        count_d = count_q;
        if (reqrsp_i.q_valid && reqrsp_i.q_ready)
            count_d++;
        if (reqrsp_i.p_valid && reqrsp_i.p_ready)
            count_d--;
    end

    // Stall the incoming requests if too many requests are pending.
    always_comb begin : p_req
        tcdm_add   = reqrsp_i.q_addr;
        tcdm_wen   = reqrsp_i.q_write;
        tcdm_wdata = reqrsp_i.q_data;
        tcdm_be    = reqrsp_i.q_strb;
        if (count_q == NUM_PENDING) begin
            tcdm_req = 0;
            reqrsp_i.q_ready = 0;
        end else begin
            tcdm_req = reqrsp_i.q_valid;
            reqrsp_i.q_ready = tcdm_gnt;
        end
    end

    // The response queue holds the responses as they come back from the TCDM.
    logic queue_full;
    logic queue_empty;

    fifo #(
        .DEPTH        ( NUM_PENDING ),
        .DATA_WIDTH   ( DW          ),
        .FALL_THROUGH ( 1           )
    ) i_rsp_queue (
        .clk_i       ( clk_i                              ),
        .rst_ni      ( rst_ni                             ),
        .flush_i     ( 1'b0                               ),
        .testmode_i  ( 1'b0                               ),
        .full_o      ( queue_full                         ),
        .empty_o     ( queue_empty                        ),
        .threshold_o (                                    ),
        .data_i      ( tcdm_r_rdata                       ),
        .push_i      ( tcdm_r_valid                       ),
        .data_o      ( reqrsp_i.p_data                     ),
        .pop_i       ( reqrsp_i.p_ready && reqrsp_i.p_valid )
    );

    always_comb begin : p_rsp
        reqrsp_i.p_error = 0;
        reqrsp_i.p_valid = !queue_empty;
    end

    // The queue should never fill up, as this is prevented by the counter in
    // the request path.
    // pragma translate_off
    `ifndef VERILATOR
    assert property (@(posedge clk_i) tcdm_r_valid |-> !queue_full);
    `endif
    // pragma translate_on

endmodule
