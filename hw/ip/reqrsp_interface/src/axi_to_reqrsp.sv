// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Fabian Schuiki <fschuiki@iis.ee.ethz.ch>

/// A protocol adapter from AXI4 to REQRSP.
module axi_to_reqrsp #(
    /// The address width of the AXI bus. >=1.
    parameter int IN_AW = -1,
    /// The data width of the AXI bus. >=1.
    parameter int IN_DW = -1,
    /// The ID width of the AXI bus. >=0.
    parameter int IN_IW = -1,
    /// The user data width of the AXI bus. >=0.
    parameter int IN_UW = -1,
    /// The address width of the REQRSP bus. >=1.
    parameter int OUT_AW = -1,
    /// The data width of the REQRSP bus. >=1.
    parameter int OUT_DW = -1,
    /// The number of REQRSP ports. Power of two; >=1.
    parameter int NUM_PORTS = 1
)(
    input logic    clk_i,
    input logic    rst_ni,
    AXI_BUS.Slave  axi_i,
    REQRSP_BUS.out reqrsp_o[NUM_PORTS]
);

    localparam int unsigned LogPorts = $clog2(NUM_PORTS);

    localparam int unsigned InAlign   = $clog2(IN_DW/8);
    localparam int unsigned OutAlign  = $clog2(OUT_DW/8);
    localparam int unsigned OutWord   = NUM_PORTS*OUT_DW;
    localparam int unsigned WordAlign = $clog2(OutWord/8);
    localparam int unsigned AlignDiffReq = InAlign > WordAlign ? InAlign-WordAlign : 0;
    localparam int unsigned AlignDiffRsp = WordAlign > InAlign ? WordAlign-InAlign : 0;

    // Check invariants.
    `ifndef SYNTHESIS
    initial begin
        assert(IN_AW >  0);
        assert(IN_DW >  0);
        assert(IN_IW >= 0);
        assert(IN_UW >= 0);
        assert(NUM_PORTS > 0);
        assert(2**LogPorts == NUM_PORTS);
        assert(axi_i.AXI_ADDR_WIDTH == IN_AW);
        assert(axi_i.AXI_DATA_WIDTH == IN_DW);
        assert(axi_i.AXI_ID_WIDTH   == IN_IW);
        assert(axi_i.AXI_USER_WIDTH == IN_UW);
    end
    for (genvar i = 0; i < NUM_PORTS; i++) initial begin
        assert(reqrsp_o[i].ADDR_WIDTH == OUT_AW);
        assert(reqrsp_o[i].DATA_WIDTH == OUT_DW);
    end
    `endif

    // The request metadata contains information about a read/write request.
    typedef struct packed {
        logic              write; // 0=AR, 1=AW
        logic [OUT_AW-1:0] addr;  // AxADDR
        logic [2:0]        size;  // AxSIZE
        logic [7:0]        len;   // AxLEN
        logic [IN_IW-1:0]  id;    // AxID
        logic [IN_UW-1:0]  user;  // AxUSER
    } req_meta_t;

    // The response metadata contains information about a response coming in on
    // the REQRSP bus.
    typedef struct packed {
        logic                      write;  // 0=AR, 1=AW
        logic                      last;   // whether this is the last beat of the transfer
        logic                      send;   // whether this beat is completely assembled
        logic [AlignDiffReq-1:0] offset; // first byte of the AXI word that is active
        logic [NUM_PORTS-1:0]      mask;   // which ports will provide a response
        logic [IN_IW-1:0]          id;     // AxID
        logic [IN_UW-1:0]          user;   // AxUSER
    } rsp_meta_t;

    // The request and response queues transport the metadata between the
    // different processing stages.
    req_meta_t req_queue_in, req_queue_out;
    rsp_meta_t rsp_queue_in, rsp_queue_out;
    logic req_queue_push, req_queue_pop, req_queue_empty, req_queue_full;
    logic rsp_queue_push, rsp_queue_pop, rsp_queue_empty, rsp_queue_full;

    fifo_v3 #(
        .DEPTH ( 4          ),
        .dtype ( req_meta_t )
    ) i_req_queue (
        .clk_i       ( clk_i           ),
        .rst_ni      ( rst_ni          ),
        .flush_i     ( 1'b0            ),
        .testmode_i  ( 1'b0            ),
        .full_o      ( req_queue_full  ),
        .empty_o     ( req_queue_empty ),
        .usage_o     (                 ),
        .data_i      ( req_queue_in    ),
        .push_i      ( req_queue_push  ),
        .data_o      ( req_queue_out   ),
        .pop_i       ( req_queue_pop   )
    );

    fifo_v3 #(
        .DEPTH ( 4          ),
        .dtype ( rsp_meta_t )
    ) i_rsp_queue (
        .clk_i       ( clk_i           ),
        .rst_ni      ( rst_ni          ),
        .flush_i     ( 1'b0            ),
        .testmode_i  ( 1'b0            ),
        .full_o      ( rsp_queue_full  ),
        .empty_o     ( rsp_queue_empty ),
        .usage_o     (                 ),
        .data_i      ( rsp_queue_in    ),
        .push_i      ( rsp_queue_push  ),
        .data_o      ( rsp_queue_out   ),
        .pop_i       ( rsp_queue_pop   )
    );

    // The arbitration flag is used as a tie breaker when both an AW and AR beat
    // are available.
    logic arb_q, arb_dn;

    always_ff @(posedge clk_i, negedge rst_ni) begin
        if (!rst_ni)
            arb_q <= 0;
        else if (req_queue_push)
            arb_q <= ~arb_dn;
    end

    // The request multiplexer is responsible for arbitrating between the
    // incoming AR and AW requests, and filling the request queue.
    always_comb begin : p_mux
        req_queue_push = 0;
        req_queue_in   = '0;
        axi_i.aw_ready = 0;
        axi_i.ar_ready = 0;

        // Arbitrate between the incoming requests.
        if (axi_i.aw_valid && axi_i.ar_valid)
            arb_dn = arb_q;
        else if (axi_i.aw_valid)
            arb_dn = 0;
        else if (axi_i.ar_valid)
            arb_dn = 1;
        else
            arb_dn = ~arb_q;

        // Handle writes.
        if (axi_i.aw_valid && arb_dn == 0) begin
            req_queue_in.write = 1;
            req_queue_in.addr  = axi_i.aw_addr & ('1 << axi_i.aw_size);
            req_queue_in.size  = axi_i.aw_size ;
            req_queue_in.len   = axi_i.aw_len  ;
            req_queue_in.id    = axi_i.aw_id   ;
            req_queue_in.user  = axi_i.aw_user ;
            if (!req_queue_full) begin
                axi_i.aw_ready = 1;
                req_queue_push = 1;
            end
        end

        // Handle reads.
        if (axi_i.ar_valid && arb_dn == 1) begin
            req_queue_in.write = 0;
            req_queue_in.addr  = axi_i.ar_addr & ('1 << axi_i.ar_size);
            req_queue_in.size  = axi_i.ar_size ;
            req_queue_in.len   = axi_i.ar_len  ;
            req_queue_in.id    = axi_i.ar_id   ;
            req_queue_in.user  = axi_i.ar_user ;
            if (!req_queue_full) begin
                axi_i.ar_ready = 1;
                req_queue_push = 1;
            end
        end
    end

    // The request address counter keeps track of the current address and AXI
    // beat for each transfer. It is reset whenever the item at the queue's
    // output changes.
    typedef struct packed {
        logic              valid;
        logic [OUT_AW-1:0] addr;
        logic [7:0]        beat;
    } reqcnt_t;
    reqcnt_t reqcnt, reqcnt_q;
    logic              req_next;          // advance to the next request
    logic [OUT_AW-1:0] req_addr_last;     // address pattern that signals beat completion
    logic [OUT_AW-1:0] req_addr_step;     // address increment per request burst
    logic              req_beat_complete; // whether the beat is complete

    always_ff @(posedge clk_i, negedge rst_ni) begin : ps_reqcnt
        if (!rst_ni) begin
            reqcnt_q <= '0;
        end else if (req_next) begin
            reqcnt_q.valid <= !req_queue_pop && !req_queue_empty;
            reqcnt_q.addr  <= reqcnt.addr + req_addr_step;
            reqcnt_q.beat  <= req_beat_complete ? reqcnt.beat + 1 : reqcnt.beat;
        end
    end

    always_comb begin : pc_reqcnt
        req_addr_step =
          $unsigned(1 << (req_queue_out.size < WordAlign ? req_queue_out.size : WordAlign));
        if (reqcnt_q.valid) begin
            reqcnt = reqcnt_q;
        end else begin
            reqcnt.valid = !req_queue_empty;
            reqcnt.addr  = req_queue_out.addr;
            reqcnt.beat  = 0;
        end
    end

    // Determine the address pattern of the last transfer in a beat. Based
    // on this, determine whether after dealing with the requests the AXI
    // beat is complete.
    assign req_addr_last = ('1 << WordAlign) & ~('1 << req_queue_out.size);
    assign req_beat_complete = (reqcnt.addr & req_addr_last) == req_addr_last;

    // Align the data on the AXI W channel on the REQRSP outputs. The outputs
    // together form a word. The width of the W channel may be less, equal, or
    // greater than that word. Depending on which is the case, and what the
    // current address is, different parts of the bus are multiplexed onto the
    // outputs.
    //
    // - `data` and `strb` carry the multiplexed data and strobe of the AXI W
    //   channel.
    // - `active` indicates which output bytes are to be active.
    logic [NUM_PORTS-1:0][OUT_DW-1:0]   reqadj_data;
    logic [NUM_PORTS-1:0][OUT_DW/8-1:0] reqadj_strb;
    logic [NUM_PORTS-1:0][OUT_DW/8-1:0] reqadj_active;

    if (OutWord < IN_DW) begin : g_reqadj_mux
        always_comb begin
            automatic logic [AlignDiffReq-1:0] sel;
            sel = reqcnt.addr >> WordAlign;
            reqadj_data = axi_i.w_data >> (sel * OutWord);
            reqadj_strb = axi_i.w_strb >> (sel * OutWord/8);
        end
    end else if (OutWord == IN_DW) begin : g_reqadj_pass
        always_comb begin
            reqadj_data = axi_i.w_data;
            reqadj_strb = axi_i.w_strb;
        end
    end else if (OutWord > IN_DW) begin : g_reqadj_repl
        always_comb begin
            automatic logic [OutWord-1:0]   data;
            automatic logic [OutWord/8-1:0] strb;
            for (int i = 0; i < OutWord; i += IN_DW) begin
                data[i   +: IN_DW  ] = axi_i.w_data[0 +: IN_DW];
                strb[i/8 +: IN_DW/8] = axi_i.w_strb[0 +: IN_DW/8];
            end
            reqadj_data = data;
            reqadj_strb = strb;
        end
    end

    always_comb begin : p_reqadj_active
        // This is a funny process. It generates a second byte strobe that
        // indicates which bytes of the output word are currently active, as
        // determined by AxSIZE and the current address.
        //
        // - `active` is a signal with the lower 2**AxSIZE bits set.
        // - `shift` indicates the offset of the first byte in the output word
        //   that is valid.
        automatic logic [OutWord/8-1:0] active;
        automatic logic [OUT_AW-1:0]     shift;
        active = ~('1 << 2**req_queue_out.size);
        shift  = reqcnt.addr & ~('1 << WordAlign);
        reqadj_active = active << shift;
    end

    // The global and per-port request processes are responsible for emitting
    // requests on the output ports. Each output port has its lower address bits
    // fixed depending on its position in the output word. A transaction is only
    // triggered if a port
    //
    // Note that the qvalid/qready handshake for each of the ports may terminate
    // at different times. Therefore we generate a `req_drive` signal which
    // indicates whether a transaction should occur for a port. The `req_served`
    // signal then indicates for which ports the request has been acknowledged.
    logic                 req_drive_all, req_drive_all_late;
    logic [NUM_PORTS-1:0] req_drive;
    logic [NUM_PORTS-1:0] req_served_q, req_served;

    always_comb begin : p_req
        req_drive_all  = 0;
        req_next       = 0;
        req_queue_pop  = 0;
        rsp_queue_push = 0;
        axi_i.w_ready  = 0;

        // Handle reads and writes.
        if (!req_queue_empty && !rsp_queue_full) begin
            if (req_queue_out.write) begin
                req_drive_all = axi_i.w_valid;
                req_next = req_drive_all && &req_served;
                axi_i.w_ready = req_next && req_beat_complete;
            end else begin
                req_drive_all = 1;
                req_next = req_drive_all && &req_served;
            end
            if (req_next && req_beat_complete && reqcnt.beat == req_queue_out.len)
                req_queue_pop = 1;
        end

        // For each transfer, push metadata into the response queue.
        rsp_queue_in.write  = req_queue_out.write;
        rsp_queue_in.last   = reqcnt.beat == req_queue_out.len;
        rsp_queue_in.send   = req_beat_complete;
        rsp_queue_in.offset = reqcnt.addr >> WordAlign;
        rsp_queue_in.mask   = req_drive;
        rsp_queue_in.id     = req_queue_out.id;
        rsp_queue_in.user   = req_queue_out.user;
        // push in the first cycle of each transfer
        rsp_queue_push = req_drive_all & ~req_drive_all_late;
    end

    for (genvar i = 0; i < NUM_PORTS; i++) begin : g_req_port
        always_comb begin : p_req_port
            automatic logic [OUT_AW-1:0] addr_mask, addr_fixed;
            addr_mask  = '1 << WordAlign;
            addr_fixed = $unsigned(i << OutAlign);
            reqrsp_o[i].q_addr  = (reqcnt.addr & addr_mask) | addr_fixed;
            reqrsp_o[i].q_write = req_queue_out.write;
            reqrsp_o[i].q_data  = reqadj_data[i];
            reqrsp_o[i].q_strb  = reqadj_strb[i] & reqadj_active[i];
            if (req_queue_out.write)
                req_drive[i] = req_drive_all & |reqrsp_o[i].q_strb;
            else
                req_drive[i] = req_drive_all & |reqadj_active[i];
            reqrsp_o[i].q_valid = req_drive[i] & ~req_served_q[i];
        end

        always_ff @(posedge clk_i, negedge rst_ni) begin : ps_req_served
            if (!rst_ni)
                req_served_q[i] <= 0;
            else
                req_served_q[i] <= ~req_next & (req_served_q[i] | reqrsp_o[i].q_ready);
        end

        always_comb begin : pc_req_served
            req_served[i] = req_served_q[i] | reqrsp_o[i].q_ready | ~req_drive[i];
        end
    end

    always_ff @(posedge clk_i, negedge rst_ni) begin
        if (!rst_ni)
            req_drive_all_late <= 0;
        else
            req_drive_all_late <= ~req_next & req_drive_all;
    end


    // Pack the response ports.
    logic                               rsp_next;
    logic [NUM_PORTS-1:0][OUT_DW-1:0]   rsp_data;
    logic [NUM_PORTS-1:0][OUT_DW/8-1:0] rsp_error;
    logic [NUM_PORTS-1:0][OUT_DW/8-1:0] rsp_valid;
    logic [NUM_PORTS-1:0][OUT_DW/8-1:0] rsp_active;

    for (genvar i = 0; i < NUM_PORTS; i++) begin : g_rsp_port
        always_comb begin : p_rsp_pack
            rsp_data[i]   = reqrsp_o[i].p_data;
            rsp_error[i]  = reqrsp_o[i].p_error ? '1 : '0;
            rsp_valid[i]  = reqrsp_o[i].p_valid ? '1 : '0;
            rsp_active[i] = rsp_queue_out.mask[i] ? '1 : '0;
            reqrsp_o[i].p_ready = rsp_next;
        end
    end

    logic [OutWord-1:0]   rsp_pack_data;
    logic [OutWord/8-1:0] rsp_pack_error;
    logic [OutWord/8-1:0] rsp_pack_valid;
    logic [OutWord/8-1:0] rsp_pack_active;

    always_comb begin : p_rsp_pack
        rsp_pack_data   = rsp_data;
        rsp_pack_error  = rsp_error;
        rsp_pack_valid  = rsp_valid;
        rsp_pack_active = rsp_active;
    end

    // Align the output ports to the AXI R channel.
    logic [IN_DW-1:0]   rspadj_data;
    logic [IN_DW/8-1:0] rspadj_error;
    logic [IN_DW/8-1:0] rspadj_valid;
    logic [IN_DW/8-1:0] rspadj_active;

    if (OutWord > IN_DW) begin : g_rspadj_mux
        always_comb begin
            automatic logic [OutWord/IN_DW-1:0][IN_DW-1:0]   reshaped_data;
            automatic logic [OutWord/IN_DW-1:0][IN_DW/8-1:0] reshaped_error;
            automatic logic [OutWord/IN_DW-1:0][IN_DW/8-1:0] reshaped_valid;
            automatic logic [OutWord/IN_DW-1:0][IN_DW/8-1:0] reshaped_active;

            automatic logic [IN_DW-1:0][OutWord/IN_DW-1:0]   masked_data;
            automatic logic [IN_DW/8-1:0][OutWord/IN_DW-1:0] masked_error;
            automatic logic [IN_DW/8-1:0][OutWord/IN_DW-1:0] masked_valid;
            automatic logic [IN_DW/8-1:0][OutWord/IN_DW-1:0] masked_active;

            // Reshape the port data to make it easier to index.
            reshaped_data   = rsp_pack_data;
            reshaped_error  = rsp_pack_error;
            reshaped_valid  = rsp_pack_valid;
            reshaped_active = rsp_pack_active;

            // Mask the port data with the corresponding active signal.
            for (int i = 0; i < OutWord/IN_DW; i++) begin
                for (int n = 0; n < IN_DW/8; n++) begin
                    for (int m = 0; m < 8; m++)
                        masked_data[n*8+m][i] = reshaped_active[i][n] & reshaped_data[i][n*8+m];
                    masked_error[n][i]  = reshaped_active[i][n] & reshaped_error[i][n];
                    masked_valid[n][i]  = reshaped_active[i][n] & reshaped_valid[i][n];
                    masked_active[n][i] = reshaped_active[i][n];
                end
            end

            // Create a OR tree for each of the adjusted bits.
            for (int i = 0; i < IN_DW; i++) begin
                rspadj_data[i] = |masked_data[i];
            end
            for (int i = 0; i < IN_DW/8; i++) begin
                rspadj_error[i]  = |masked_error[i];
                rspadj_valid[i]  = |masked_valid[i];
                rspadj_active[i] = |masked_active[i];
            end
        end
    end else if (OutWord == IN_DW) begin : g_rspadj_pass
        always_comb begin
            rspadj_data   = rsp_pack_data;
            rspadj_error  = rsp_pack_error;
            rspadj_valid  = rsp_pack_valid;
            rspadj_active = rsp_pack_active;
        end
    end else if (OutWord < IN_DW) begin : g_rspadj_repl
        always_comb begin
            for (int i = 0; i < IN_DW/OutWord; i++) begin
                rspadj_data  [i*OutWord   +: OutWord  ] = rsp_pack_data  [0 +: OutWord  ];
                rspadj_error [i*OutWord/8 +: OutWord/8] = rsp_pack_error [0 +: OutWord/8];
                rspadj_valid [i*OutWord/8 +: OutWord/8] = rsp_pack_valid [0 +: OutWord/8];
            end
            rspadj_active = rsp_pack_active << (rsp_queue_out.offset * OutWord/8);
        end
    end

    // The response assembly register stores the response data coming from the
    // output ports.
    logic [IN_DW-1:0] rsp_data_assembled_q, rsp_data_assembled;
    logic rsp_error_q;

    always_ff @(posedge clk_i, negedge rst_ni) begin : ps_rsp_assemble
        if (!rst_ni) begin
            rsp_data_assembled_q <= '0;
            rsp_error_q <= 0;
        end else if (rsp_next) begin
            rsp_data_assembled_q <= rsp_queue_out.send ? '0 : rsp_data_assembled;
            rsp_error_q <= ~rsp_queue_pop & (rsp_error_q | (|(rspadj_error & rspadj_active)));
        end
    end

    always_comb begin : pc_rsp_assemble
        rsp_data_assembled = rsp_data_assembled_q;
        if (~rsp_queue_out.write)
            for (int i = 0; i < IN_DW/8; i++)
                if (rspadj_active[i])
                    rsp_data_assembled[i*8+:8] = rspadj_data[i*8+:8];
    end

    // The response process is responsible for emitting AXI R or B beats, and
    // controlling the handshake with the response queue and output ports.
    always_comb begin : p_rsp
        rsp_next      = 0;
        rsp_queue_pop = 0;

        axi_i.b_id    = rsp_queue_out.id;
        axi_i.b_user  = rsp_queue_out.user;
        axi_i.b_resp  = rsp_error_q ? axi_pkg::RESP_DECERR : axi_pkg::RESP_OKAY;
        axi_i.b_valid = 0;

        axi_i.r_id    = rsp_queue_out.id;
        axi_i.r_user  = rsp_queue_out.user;
        axi_i.r_resp  = rsp_error_q ? axi_pkg::RESP_DECERR : axi_pkg::RESP_OKAY;
        axi_i.r_data  = rsp_data_assembled;
        axi_i.r_last  = rsp_queue_out.last;
        axi_i.r_valid = 0;

        if (!rsp_queue_empty && &(rsp_pack_valid | ~rsp_pack_active)) begin
            if (rsp_queue_out.send) begin
                if (rsp_queue_out.write) begin
                    axi_i.b_valid = rsp_queue_out.last;
                    rsp_next = ~rsp_queue_out.last | axi_i.b_ready;
                end else begin
                    axi_i.r_valid = 1;
                    rsp_next = axi_i.r_ready;
                end
            end else begin
                rsp_next = 1;
            end
            rsp_queue_pop = rsp_next;
        end
    end

endmodule
