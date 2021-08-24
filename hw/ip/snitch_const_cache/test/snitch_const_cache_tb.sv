// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>

class icache_request #(
  parameter int unsigned AddrWidth = 48
);
  rand logic [AddrWidth-1:0] addr;
  rand bit flush;

  constraint flush_c {
    flush dist { 1 := 2, 0 := 200};
  }

  constraint addr_c {
    addr[1:0] == 0;
  }
endclass

class riscv_inst;
  rand logic [31:0] inst;
  rand bit ctrl_flow;
  constraint inst_c {
    ctrl_flow dist { 1 := 3, 0 := 10};
    inst[1:0] == 2'b11;
    if (ctrl_flow) {
      inst[6:0] inside {
        riscv_instr::BEQ[6:0],
        riscv_instr::JAL[6:0]
      };
      // we don't support compressed instructions, make sure
      // that we only emit aligned jump targets.
      if (inst[6:0] == riscv_instr::BEQ[6:0]) {
        inst[8] == 0;
      }
      if (inst[6:0] == riscv_instr::JAL[6:0]) {
        inst[21] == 0;
      }
    // make sure that we don't emit control flow instructions
    } else {
      !(inst[6:0] inside {
        riscv_instr::BEQ[6:0],
        riscv_instr::JAL[6:0]
      });
    }
  }
endclass

// Inherit from the random AXI slave, but return the same data for reads from the same address.
// --> Emulate a random ROM
class const_axi_slave #(
  // AXI interface parameters
  parameter int   AW = 32,
  parameter int   DW = 32,
  parameter int   IW = 8,
  parameter int   UW = 1,
  // Stimuli application and test time
  parameter time  TA = 0ps,
  parameter time  TT = 0ps,
  parameter bit   RAND_RESP = 0,
  // Upper and lower bounds on wait cycles on Ax, W, and resp (R and B) channels
  parameter int   AX_MIN_WAIT_CYCLES = 0,
  parameter int   AX_MAX_WAIT_CYCLES = 100,
  parameter int   R_MIN_WAIT_CYCLES = 0,
  parameter int   R_MAX_WAIT_CYCLES = 5,
  parameter int   RESP_MIN_WAIT_CYCLES = 0,
  parameter int   RESP_MAX_WAIT_CYCLES = 20
) extends axi_test::rand_axi_slave #(
  .AW                   ( AW                   ),
  .DW                   ( DW                   ),
  .IW                   ( IW                   ),
  .UW                   ( UW                   ),
  .TA                   ( TA                   ),
  .TT                   ( TT                   ),
  .RAND_RESP            ( RAND_RESP            ),
  .AX_MIN_WAIT_CYCLES   ( AX_MIN_WAIT_CYCLES   ),
  .AX_MAX_WAIT_CYCLES   ( AX_MAX_WAIT_CYCLES   ),
  .R_MIN_WAIT_CYCLES    ( R_MIN_WAIT_CYCLES    ),
  .R_MAX_WAIT_CYCLES    ( R_MAX_WAIT_CYCLES    ),
  .RESP_MIN_WAIT_CYCLES ( RESP_MIN_WAIT_CYCLES ),
  .RESP_MAX_WAIT_CYCLES ( RESP_MAX_WAIT_CYCLES )
);
  function new(
    virtual AXI_BUS_DV #(
      .AXI_ADDR_WIDTH(AW),
      .AXI_DATA_WIDTH(DW),
      .AXI_ID_WIDTH(IW),
      .AXI_USER_WIDTH(UW)
    ) axi
  );
    super.new(axi);
  endfunction

  task send_rs();
    forever begin
      automatic logic rand_success;
      automatic ax_beat_t ar_beat;
      automatic r_beat_t r_beat = new;
      wait (!ar_queue.empty());
      ar_beat = ar_queue.peek();
      rand_success = std::randomize(r_beat); assert(rand_success);
      // TODO:
      r_beat.r_data = {{DW/AW}{ar_beat.ax_addr}};
      r_beat.r_id = ar_beat.ax_id;
      if (RAND_RESP && !ar_beat.ax_atop[5])
        r_beat.r_resp[1] = $random();
      if (ar_beat.ax_lock)
        r_beat.r_resp[0]= $random();
      rand_wait(R_MIN_WAIT_CYCLES, R_MAX_WAIT_CYCLES);
      if (ar_beat.ax_len == '0) begin
        r_beat.r_last = 1'b1;
        void'(ar_queue.pop_id(ar_beat.ax_id));
      end else begin
        ar_beat.ax_len--;
        ar_beat.ax_addr += 1 << ar_beat.ax_size;
        ar_queue.set(ar_beat.ax_id, ar_beat);
      end
      drv.send_r(r_beat);
    end
  endtask

  task run();
    fork
      recv_ars();
      send_rs();
      recv_aws();
      recv_ws();
      send_bs();
    join
  endtask

endclass

`include "common_cells/assertions.svh"

module snitch_const_cache_tb import snitch_pkg::*; #(
    parameter int unsigned AddrWidth = 32,
    parameter type addr_t = logic [AddrWidth-1:0],
    parameter int NR_FETCH_PORTS = 1,
    parameter int LINE_WIDTH = 128,
    parameter int LINE_COUNT = 128,
    parameter int SET_COUNT = 1,
    parameter int FETCH_AW = AddrWidth,
    parameter int FETCH_DW = 32,
    parameter int FILL_AW = AddrWidth,
    parameter int FILL_DW = 64,
    parameter int L0_EARLY_TAG_WIDTH = 8,
    parameter bit EARLY_LATCH = 0
);

  localparam time ClkPeriod = 10ns;
  localparam time TA = 2ns;
  localparam time TT = 8ns;
  localparam bit DEBUG = 1'b0;

  // AXI parameters
  `include "axi/typedef.svh"
  `include "axi/assign.svh"

  localparam int unsigned AxiAddrWidth = AddrWidth;
  localparam int unsigned AxiDataWidth = FILL_DW;
  localparam int unsigned AxiStrbWidth = AxiDataWidth/8;
  localparam int unsigned AxiInIdWidth = 2;
  localparam int unsigned AxiOutIdWidth = AxiInIdWidth+1;
  localparam int unsigned AxiUserWidth = 1;

  typedef logic [AxiAddrWidth-1:0]  axi_addr_t;
  typedef logic [AxiDataWidth-1:0]  axi_data_t;
  typedef logic [AxiStrbWidth-1:0]  axi_strb_t;
  typedef logic [AxiInIdWidth-1:0]  axi_in_id_t;
  typedef logic [AxiOutIdWidth-1:0] axi_out_id_t;
  typedef logic [AxiUserWidth-1:0]  axi_user_t;

  `AXI_TYPEDEF_ALL(axi_mst, axi_addr_t, axi_in_id_t, axi_data_t, axi_strb_t, axi_user_t)
  `AXI_TYPEDEF_ALL(axi_slv, axi_addr_t, axi_out_id_t, axi_data_t, axi_strb_t, axi_user_t)

  // Address regions
  localparam axi_addr_t CachedRegionStart = axi_addr_t'(32'h8000_0000);
  localparam axi_addr_t CachedRegionEnd   = axi_addr_t'(32'h8000_0040);

  // backing memory
  logic [LINE_WIDTH-1:0] memory [logic [AddrWidth-1:0]];

  // localparam int unsigned IdWidthReq = $clog2(NR_FETCH_PORTS) + 1;
  // localparam int unsigned IdWidthResp = 2*NR_FETCH_PORTS;

  logic  clk, rst;
  // logic  dut_flush_valid;
  // addr_t dut_addr;
  // logic  dut_valid;
  // logic [31:0] dut_data;
  // logic  dut_ready;
  // logic  dut_error;

  // typedef struct packed {
  //   logic [LINE_WIDTH-1:0] data;
  //   logic error;
  //   logic [IdWidthResp-1:0] id;
  // } dut_in_t;

  // typedef struct packed {
  //   addr_t addr;
  //   logic [IdWidthReq-1:0] id;
  // } dut_out_t;

  typedef axi_test::rand_axi_master #(
    .AW                   ( AddrWidth    ),
    .DW                   ( AxiDataWidth ),
    .IW                   ( AxiInIdWidth ),
    .UW                   ( AxiUserWidth ),
    .TA                   ( TA           ),
    .TT                   ( TT           ),
    .MAX_READ_TXNS        ( 1            ),
    .MAX_WRITE_TXNS       ( 1            ),
    .AX_MIN_WAIT_CYCLES   ( 0            ),
    .AX_MAX_WAIT_CYCLES   ( 0            ),
    .W_MIN_WAIT_CYCLES    ( 0            ),
    .W_MAX_WAIT_CYCLES    ( 0            ),
    .RESP_MIN_WAIT_CYCLES ( 0            ),
    .RESP_MAX_WAIT_CYCLES ( 1            ),
    .AXI_MAX_BURST_LEN    ( 1            ),
    .TRAFFIC_SHAPING      ( 0            ),
    .AXI_EXCLS            ( 1'b0         ),
    .AXI_ATOPS            ( 1'b0         ),
    .AXI_BURST_FIXED      ( 1'b0         ),
    .AXI_BURST_INCR       ( 1'b1         ),
    .AXI_BURST_WRAP       ( 1'b0         )
  ) axi_rand_master_t;

  typedef const_axi_slave #(
    .AW                   ( AddrWidth     ),
    .DW                   ( AxiDataWidth  ),
    .IW                   ( AxiOutIdWidth ),
    .UW                   ( AxiUserWidth  ),
    .TA                   ( TA            ),
    .TT                   ( TT            ),
    .RAND_RESP            ( 0             ),
    .AX_MIN_WAIT_CYCLES   ( 0             ),
    .AX_MAX_WAIT_CYCLES   ( 50            ),
    .R_MIN_WAIT_CYCLES    ( 10            ),
    .R_MAX_WAIT_CYCLES    ( 20            ),
    .RESP_MIN_WAIT_CYCLES ( 10            ),
    .RESP_MAX_WAIT_CYCLES ( 20            )
  ) axi_rand_slave_t;

  AXI_BUS_DV #(
    .AXI_ADDR_WIDTH ( AddrWidth    ),
    .AXI_DATA_WIDTH ( AxiDataWidth ),
    .AXI_ID_WIDTH   ( AxiInIdWidth ),
    .AXI_USER_WIDTH ( AxiUserWidth )
  ) axi_mst_dv (
    .clk_i ( clk )
  );

  AXI_BUS_DV #(
    .AXI_ADDR_WIDTH ( AddrWidth     ),
    .AXI_DATA_WIDTH ( AxiDataWidth  ),
    .AXI_ID_WIDTH   ( AxiOutIdWidth ),
    .AXI_USER_WIDTH ( AxiUserWidth  )
  ) axi_slv_dv (
    .clk_i ( clk )
  );

  axi_rand_master_t mst_intf = new(axi_mst_dv);
  axi_rand_slave_t slv_intf = new(axi_slv_dv);

  axi_mst_req_t  axi_mst_req;
  axi_mst_resp_t axi_mst_resp;

  axi_slv_req_t  axi_slv_req;
  axi_slv_resp_t axi_slv_resp;

  `AXI_ASSIGN_TO_REQ(axi_mst_req, axi_mst_dv)
  `AXI_ASSIGN_FROM_RESP(axi_mst_dv, axi_mst_resp)

  `AXI_ASSIGN_FROM_REQ(axi_slv_dv, axi_slv_req)
  `AXI_ASSIGN_TO_RESP(axi_slv_resp, axi_slv_dv)

  snitch_const_cache #(
    .LineWidth    ( LINE_WIDTH     ),
    .LineCount    ( LINE_COUNT     ),
    .SetCount     ( SET_COUNT      ),
    .AxiAddrWidth ( AddrWidth      ),
    .AxiDataWidth ( FILL_DW        ),
    .AxiIdWidth   ( AxiInIdWidth   ),
    .AxiUserWidth ( 1              ),
    .MaxTrans     ( 32'd8          ),
    .NrAddrRules  ( 1              ),
    .slv_req_t    ( axi_mst_req_t  ),
    .slv_rsp_t    ( axi_mst_resp_t ),
    .mst_req_t    ( axi_slv_req_t  ),
    .mst_rsp_t    ( axi_slv_resp_t )
  ) dut (
    .clk_i         ( clk                 ),
    .rst_ni        ( ~rst                ),
    .flush_valid_i ( 1'b0                ),
    .flush_ready_o ( /*unused*/          ),
    .start_addr_i  ( {CachedRegionStart} ),
    .end_addr_i    ( {CachedRegionEnd}   ),
    .axi_slv_req_i ( axi_mst_req         ),
    .axi_slv_rsp_o ( axi_mst_resp        ),
    .axi_mst_req_o ( axi_slv_req         ),
    .axi_mst_rsp_i ( axi_slv_resp        )
  );

  // always_ff @(posedge clk or negedge rst) begin
  //   if(~rst) begin
  //      <= 0;
  //   end else begin
  //      <= ;
  //   end
  // end

  task static cycle_start;
    #TT;
  endtask

  task static cycle_end;
    @(posedge clk);
  endtask

  task static reset;
    // dut_flush_valid = '0;
    // dut_addr = '0;
    // dut_valid = '0;
  endtask

  initial begin
    automatic logic rand_success;
    $timeformat(-9, 0, " ns", 20);

    // Initialize memory region of random axi master
    mst_intf.add_memory_region(CachedRegionStart, CachedRegionEnd, axi_pkg::WTHRU_RALLOCATE);

    // Reset
    reset();
    mst_intf.reset();
    @(negedge rst);

    mst_intf.run(1000, 0);

    #1000ns;
    $finish();
  end

  initial begin : proc_sim_mem
    slv_intf.reset();
    @(negedge rst);
    slv_intf.run();
  end

  // Debug
  axi_chan_logger #(
    .TestTime   ( 8ns                   ),
    .LoggerName ( "mst_logger"          ),
    .aw_chan_t  ( axi_mst_aw_chan_t     ),
    .w_chan_t   ( axi_mst_w_chan_t      ),
    .b_chan_t   ( axi_mst_b_chan_t      ),
    .ar_chan_t  ( axi_mst_ar_chan_t     ),
    .r_chan_t   ( axi_mst_r_chan_t      )
  ) i_axi_chan_logger_mst (
    .clk_i      ( clk                   ),
    .rst_ni     ( ~rst                  ),
    .end_sim_i  ( 1'b0                  ),
    .aw_chan_i  ( axi_mst_req.aw        ),
    .aw_valid_i ( axi_mst_req.aw_valid  ),
    .aw_ready_i ( axi_mst_resp.aw_ready ),
    .w_chan_i   ( axi_mst_req.w         ),
    .w_valid_i  ( axi_mst_req.w_valid   ),
    .w_ready_i  ( axi_mst_resp.w_ready  ),
    .b_chan_i   ( axi_mst_resp.b        ),
    .b_valid_i  ( axi_mst_resp.b_valid  ),
    .b_ready_i  ( axi_mst_req.b_ready   ),
    .ar_chan_i  ( axi_mst_req.ar        ),
    .ar_valid_i ( axi_mst_req.ar_valid  ),
    .ar_ready_i ( axi_mst_resp.ar_ready ),
    .r_chan_i   ( axi_mst_resp.r        ),
    .r_valid_i  ( axi_mst_resp.r_valid  ),
    .r_ready_i  ( axi_mst_req.r_ready   )
  );

  axi_chan_logger #(
    .TestTime   ( 8ns                   ),
    .LoggerName ( "slv_logger"          ),
    .aw_chan_t  ( axi_slv_aw_chan_t     ),
    .w_chan_t   ( axi_slv_w_chan_t      ),
    .b_chan_t   ( axi_slv_b_chan_t      ),
    .ar_chan_t  ( axi_slv_ar_chan_t     ),
    .r_chan_t   ( axi_slv_r_chan_t      )
  ) i_axi_chan_logger_slv (
    .clk_i      ( clk                   ),
    .rst_ni     ( ~rst                  ),
    .end_sim_i  ( 1'b0                  ),
    .aw_chan_i  ( axi_slv_req.aw        ),
    .aw_valid_i ( axi_slv_req.aw_valid  ),
    .aw_ready_i ( axi_slv_resp.aw_ready ),
    .w_chan_i   ( axi_slv_req.w         ),
    .w_valid_i  ( axi_slv_req.w_valid   ),
    .w_ready_i  ( axi_slv_resp.w_ready  ),
    .b_chan_i   ( axi_slv_resp.b        ),
    .b_valid_i  ( axi_slv_resp.b_valid  ),
    .b_ready_i  ( axi_slv_req.b_ready   ),
    .ar_chan_i  ( axi_slv_req.ar        ),
    .ar_valid_i ( axi_slv_req.ar_valid  ),
    .ar_ready_i ( axi_slv_resp.ar_ready ),
    .r_chan_i   ( axi_slv_resp.r        ),
    .r_valid_i  ( axi_slv_resp.r_valid  ),
    .r_ready_i  ( axi_slv_req.r_ready   )
  );
  // /// Drive DUT request side.
  // task static send_req (
  //   /// Request instruction at address
  //   input addr_t addr,
  //   /// Flush the L0 cache.
  //   input logic flush,
  //   /// Obtain the instructions.
  //   output logic [31:0] data
  // );
  //     dut_valid       <= #TA ~flush;
  //     dut_addr        <= #TA addr;
  //     dut_flush_valid <= #TA flush;
  //     cycle_start();
  //     while (!flush && dut_ready != 1) begin cycle_end(); cycle_start(); end
  //     data      <= dut_data;
  //     cycle_end();
  //     dut_valid       <= 0;
  //     dut_addr        <= 0;
  //     dut_flush_valid <= 0;
  // endtask

  // localparam int NrDirectedRequests = 100_000;
  // // Request Port
  // initial begin
  //   automatic int unsigned stall_cycles;
  //   automatic logic [31:0] data;
  //   automatic logic [31:0] golden;
  //   automatic addr_t addr, immediate;
  //   automatic icache_request #(.AddrWidth (AddrWidth)) req = new;
  //   automatic int requests = 0;
  //   reset();
  //   @(negedge rst);
  //   req.addr = 0;
  //   req.flush = 0;
  //   forever begin
  //     stall_cycles = $urandom_range(0, 3);
  //     if (requests == 0) $info("Starting Directed Sequence of %d Requests", NrDirectedRequests);
  //     if (requests == NrDirectedRequests) $info("Starting Randomized Sequence");
  //     // Send request
  //     send_req(req.addr, req.flush, data);
  //     repeat (stall_cycles) @(posedge clk);
  //     // Check Response
  //     if (!req.flush) begin
  //       addr = req.addr >> CFG.LINE_ALIGN << CFG.LINE_ALIGN;
  //       assert(memory.exists(addr)) else $fatal(1, "Address has not been allocated.");
  //       golden = memory[addr][req.addr[CFG.LINE_ALIGN-1:0]*8+:32];
  //       assert(golden === data) else $fatal(1, "Got: %h Expected: %h", data, golden);
  //     end
  //     // Next request preparation
  //     // Directed Sequence
  //     if (requests < NrDirectedRequests) begin
  //         // Re-randomize requests every 100 cycles
  //         // to pull out of loops.
  //         if (requests % 100 == 0) begin
  //           assert(std::randomize(addr));
  //           req.addr = addr >> 2 <<2;
  //           req.flush = 1;
  //         end else req.flush = 0;
  //         casez (data)
  //           riscv_instr::BEQ,
  //           riscv_instr::BNE,
  //           riscv_instr::BLT,
  //           riscv_instr::BGE,
  //           riscv_instr::BLTU,
  //           riscv_instr::BGEU: begin
  //             if (data[31]) immediate = $signed({data[31], data[7], data[30:25], data[11:8], 1'b0});
  //             else immediate = 4;
  //           end
  //           riscv_instr::JAL: begin
  //             immediate = $signed({data[20], data[19:12], data[20], data[30:21], 1'b0});
  //           end
  //           default: immediate = 4;
  //         endcase
  //         req.addr += immediate;
  //     // Random Sequence
  //     end else begin
  //       assert(req.randomize());
  //     end
  //     requests++;
  //     if (requests > 2*NrDirectedRequests) $finish();
  //   end
  // end

  // localparam int unsigned RequestTimeout = 100;
  // // make sure that we eventually make progress (i.e., a timeout)
  // `ASSERT(RequestProgress, dut_valid |-> ##[0:RequestTimeout] dut_ready, clk, rst)

  // // Response Drivers
  // mailbox #(dut_out_t) addr_mbx [2];
  // semaphore response_lock = new (1);

  // initial begin
  //   automatic int unsigned stall_cycles;
  //   automatic dut_out_t dut_out;
  //   for (int i = 0; i < 2**IdWidthReq; i++)
  //     addr_mbx [i] = new();
  //   out_driver.reset_out();
  //   @(negedge rst);
  //   repeat (5) @(posedge clk);
  //   forever begin
  //     stall_cycles = $urandom_range(0, 5);
  //     repeat (stall_cycles) @(posedge clk);
  //     out_driver.recv(dut_out);
  //     addr_mbx[dut_out.id].put(dut_out);
  //     // $info("Requesting from Address: %h, ID: %d", dut_out.addr, dut_out.id);
  //   end
  // end

  // initial begin
  //   in_driver.reset_in();
  //   @(negedge rst);
  //   repeat (5) @(posedge clk);

  //   // I couldn't find any better way to describing this than
  //   // manual unrolling. Ugly as fuck.
  //   fork
  //     forever begin
  //       automatic int unsigned stall_cycles;
  //       automatic dut_out_t dut_out;
  //       automatic dut_in_t send_data;
  //       automatic riscv_inst rand_data = new;
  //       automatic addr_t addr;
  //       addr_mbx[0].get(dut_out);
  //       stall_cycles = $urandom_range(1, 10);
  //       repeat (stall_cycles) @(posedge clk);

  //       send_data.error = 1'b0;
  //       send_data.id = 0;
  //       addr = dut_out.addr >> CFG.LINE_ALIGN << CFG.LINE_ALIGN;
  //       if (!memory.exists(dut_out.addr)) begin
  //         for (int i = 0; i < CFG.LINE_WIDTH/32; i++) begin
  //           assert(rand_data.randomize());
  //           memory[addr][i*32+:32] = rand_data.inst;
  //         end
  //       end
  //       if (DEBUG) $info("Response for Address: %h, ID: 0, Data: %h", dut_out.addr, memory[addr]);
  //       send_data.data = memory[addr];
  //       response_lock.get();
  //       in_driver.send(send_data);
  //       response_lock.put();
  //     end
  //     forever begin
  //       automatic int unsigned stall_cycles;
  //       automatic dut_out_t dut_out;
  //       automatic dut_in_t send_data;
  //       automatic riscv_inst rand_data = new;
  //       automatic addr_t addr;
  //       addr_mbx[1].get(dut_out);
  //       stall_cycles = $urandom_range(1, 10);
  //       repeat (stall_cycles) @(posedge clk);

  //       send_data.error = 1'b0;
  //       send_data.id = 1;
  //       addr = dut_out.addr >> CFG.LINE_ALIGN << CFG.LINE_ALIGN;
  //       if (!memory.exists(dut_out.addr)) begin
  //         for (int i = 0; i < CFG.LINE_WIDTH/32; i++) begin
  //           assert(rand_data.randomize());
  //           memory[addr][i*32+:32] = rand_data.inst;
  //         end
  //       end
  //       if (DEBUG) $info("Response for Address: %h, ID: 1, Data: %h", dut_out.addr, memory[addr]);
  //       send_data.data = memory[addr];
  //       response_lock.get();
  //       in_driver.send(send_data);
  //       response_lock.put();
  //     end
  //   join_none
  // end

  // Clock generation.
  initial begin
    rst = 1;
    repeat (3) begin
      #(ClkPeriod/2) clk = 0;
      #(ClkPeriod/2) clk = 1;
    end
    rst = 0;
    forever begin
      #(ClkPeriod/2) clk = 0;
      #(ClkPeriod/2) clk = 1;
    end
  end
endmodule
