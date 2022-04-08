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

`include "common_cells/assertions.svh"

module snitch_icache_l0_tb import snitch_pkg::*; #(
    parameter int unsigned AddrWidth = 48,
    parameter type addr_t = logic [AddrWidth-1:0],
    parameter int NR_FETCH_PORTS = 1,
    parameter int L0_LINE_COUNT = 8,
    parameter int LINE_WIDTH = 128,
    parameter int LINE_COUNT = 0,
    parameter int SET_COUNT = 1,
    parameter int FETCH_AW = AddrWidth,
    parameter int FETCH_DW = 32,
    parameter int FILL_AW = AddrWidth,
    parameter int FILL_DW = 64,
    parameter int L0_EARLY_TAG_WIDTH = 8,
    parameter bit EARLY_LATCH = 0,
    parameter bit BUFFER_LOOKUP = 0,
    parameter bit GUARANTEE_ORDERING = 0
);

  localparam time ClkPeriod = 10ns;
  localparam time TA = 2ns;
  localparam time TT = 8ns;
  localparam bit DEBUG = 1'b0;

  // backing memory
  logic [LINE_WIDTH-1:0] memory [logic [AddrWidth-1:0]];

  localparam snitch_icache_pkg::config_t CFG = '{
      NR_FETCH_PORTS:     NR_FETCH_PORTS,
      LINE_WIDTH:         LINE_WIDTH,
      LINE_COUNT:         LINE_COUNT,
      L0_LINE_COUNT:      L0_LINE_COUNT,
      SET_COUNT:          SET_COUNT,
      PENDING_COUNT:      2,
      FETCH_AW:           FETCH_AW,
      FETCH_DW:           FETCH_DW,
      FILL_AW:            FILL_AW,
      FILL_DW:            FILL_DW,
      EARLY_LATCH:        EARLY_LATCH,
      BUFFER_LOOKUP:      BUFFER_LOOKUP,
      GUARANTEE_ORDERING: GUARANTEE_ORDERING,

      FETCH_ALIGN: $clog2(FETCH_DW/8),
      FILL_ALIGN:  $clog2(FILL_DW/8),
      LINE_ALIGN:  $clog2(LINE_WIDTH/8),
      COUNT_ALIGN: $clog2(LINE_COUNT),
      SET_ALIGN:   $clog2(SET_COUNT),
      TAG_WIDTH:   FETCH_AW - $clog2(LINE_WIDTH/8) - $clog2(LINE_COUNT) + 1,
      L0_TAG_WIDTH: FETCH_AW - $clog2(LINE_WIDTH/8),
      L0_EARLY_TAG_WIDTH:
        (L0_EARLY_TAG_WIDTH == -1) ? FETCH_AW - $clog2(LINE_WIDTH/8) : L0_EARLY_TAG_WIDTH,
      ID_WIDTH_REQ: $clog2(NR_FETCH_PORTS) + 1,
      ID_WIDTH_RESP: 2*NR_FETCH_PORTS,
      PENDING_IW:  $clog2(2)
  };

  localparam int unsigned IdWidthReq = $clog2(NR_FETCH_PORTS) + 1;
  localparam int unsigned IdWidthResp = 2*NR_FETCH_PORTS;

  logic  clk, rst;
  logic  dut_flush_valid;
  addr_t dut_addr;
  logic  dut_valid;
  logic [31:0] dut_data;
  logic  dut_ready;
  logic  dut_error;

  typedef struct packed {
    logic [LINE_WIDTH-1:0] data;
    logic error;
    logic [IdWidthResp-1:0] id;
  } dut_in_t;

  typedef struct packed {
    addr_t addr;
    logic [IdWidthReq-1:0] id;
  } dut_out_t;

  typedef stream_test::stream_driver #(
    .payload_t (dut_in_t),
    .TA (TA),
    .TT (TT)
  ) stream_driver_in_t;

  typedef stream_test::stream_driver #(
    .payload_t (dut_out_t),
    .TA (TA),
    .TT (TT)
  ) stream_driver_out_t;

  STREAM_DV #(
    .payload_t (dut_in_t)
  ) dut_in (
    .clk_i (clk)
  );

  STREAM_DV #(
    .payload_t (dut_out_t)
  ) dut_out (
    .clk_i (clk)
  );

  stream_driver_in_t in_driver = new(dut_in);
  stream_driver_out_t out_driver = new(dut_out);

  snitch_icache_l0 #(
    .CFG (CFG),
    .L0_ID ( 0 )
  ) dut (
    .clk_i (clk),
    .rst_ni (~rst),
    .enable_prefetching_i (1'b1),
    .icache_events_o (),
    .flush_valid_i (dut_flush_valid),
    .in_addr_i (dut_addr),
    .in_valid_i (dut_valid),
    .in_data_o (dut_data),
    .in_ready_o (dut_ready),
    .in_error_o (dut_error),

    .out_req_addr_o (dut_out.data.addr),
    .out_req_id_o (dut_out.data.id),
    .out_req_valid_o (dut_out.valid),
    .out_req_ready_i (dut_out.ready),

    .out_rsp_data_i (dut_in.data.data),
    .out_rsp_error_i (dut_in.data.error),
    .out_rsp_id_i (dut_in.data.id),
    .out_rsp_valid_i (dut_in.valid),
    .out_rsp_ready_o (dut_in.ready)
  );

  task static cycle_start;
    #TT;
  endtask

  task static cycle_end;
    @(posedge clk);
  endtask

  task static reset;
    dut_flush_valid = '0;
    dut_addr = '0;
    dut_valid = '0;
  endtask

  /// Drive DUT request side.
  task static send_req (
    /// Request instruction at address
    input addr_t addr,
    /// Flush the L0 cache.
    input logic flush,
    /// Obtain the instructions.
    output logic [31:0] data
  );
      dut_valid       <= #TA ~flush;
      dut_addr        <= #TA addr;
      dut_flush_valid <= #TA flush;
      cycle_start();
      while (!flush && dut_ready != 1) begin cycle_end(); cycle_start(); end
      data      <= dut_data;
      cycle_end();
      dut_valid       <= 0;
      dut_addr        <= 0;
      dut_flush_valid <= 0;
  endtask

  localparam int NrDirectedRequests = 100_000;
  // Request Port
  initial begin
    automatic int unsigned stall_cycles;
    automatic logic [31:0] data;
    automatic logic [31:0] golden;
    automatic addr_t addr, immediate;
    automatic icache_request #(.AddrWidth (AddrWidth)) req = new;
    automatic int requests = 0;
    reset();
    @(negedge rst);
    req.addr = 0;
    req.flush = 0;
    forever begin
      stall_cycles = $urandom_range(0, 3);
      if (requests == 0) $info("Starting Directed Sequence of %d Requests", NrDirectedRequests);
      if (requests == NrDirectedRequests) $info("Starting Randomized Sequence");
      // Send request
      send_req(req.addr, req.flush, data);
      repeat (stall_cycles) @(posedge clk);
      // Check Response
      if (!req.flush) begin
        addr = req.addr >> CFG.LINE_ALIGN << CFG.LINE_ALIGN;
        assert(memory.exists(addr)) else $fatal(1, "Address has not been allocated.");
        golden = memory[addr][req.addr[CFG.LINE_ALIGN-1:0]*8+:32];
        assert(golden === data) else $fatal(1, "Got: %h Expected: %h", data, golden);
      end
      // Next request preparation
      // Directed Sequence
      if (requests < NrDirectedRequests) begin
          // Re-randomize requests every 100 cycles
          // to pull out of loops.
          if (requests % 100 == 0) begin
            assert(std::randomize(addr));
            req.addr = addr >> 2 <<2;
            req.flush = 1;
          end else req.flush = 0;
          casez (data)
            riscv_instr::BEQ,
            riscv_instr::BNE,
            riscv_instr::BLT,
            riscv_instr::BGE,
            riscv_instr::BLTU,
            riscv_instr::BGEU: begin
              if (data[31]) immediate = $signed({data[31], data[7], data[30:25], data[11:8], 1'b0});
              else immediate = 4;
            end
            riscv_instr::JAL: begin
              immediate = $signed({data[20], data[19:12], data[20], data[30:21], 1'b0});
            end
            default: immediate = 4;
          endcase
          req.addr += immediate;
      // Random Sequence
      end else begin
        assert(req.randomize());
      end
      requests++;
      if (requests > 2*NrDirectedRequests) $finish();
    end
  end

  localparam int unsigned RequestTimeout = 100;
  // make sure that we eventually make progress (i.e., a timeout)
  `ASSERT(RequestProgress, dut_valid |-> ##[0:RequestTimeout] dut_ready, clk, rst)

  // Response Drivers
  mailbox #(dut_out_t) addr_mbx [2];
  semaphore response_lock = new (1);

  initial begin
    automatic int unsigned stall_cycles;
    automatic dut_out_t dut_out;
    for (int i = 0; i < 2**IdWidthReq; i++)
      addr_mbx [i] = new();
    out_driver.reset_out();
    @(negedge rst);
    repeat (5) @(posedge clk);
    forever begin
      stall_cycles = $urandom_range(0, 5);
      repeat (stall_cycles) @(posedge clk);
      out_driver.recv(dut_out);
      addr_mbx[dut_out.id].put(dut_out);
      // $info("Requesting from Address: %h, ID: %d", dut_out.addr, dut_out.id);
    end
  end

  initial begin
    in_driver.reset_in();
    @(negedge rst);
    repeat (5) @(posedge clk);

    // I couldn't find any better way to describing this than
    // manual unrolling. Ugly as fuck.
    fork
      forever begin
        automatic int unsigned stall_cycles;
        automatic dut_out_t dut_out;
        automatic dut_in_t send_data;
        automatic riscv_inst rand_data = new;
        automatic addr_t addr;
        addr_mbx[0].get(dut_out);
        stall_cycles = $urandom_range(1, 10);
        repeat (stall_cycles) @(posedge clk);

        send_data.error = 1'b0;
        send_data.id = 0;
        addr = dut_out.addr >> CFG.LINE_ALIGN << CFG.LINE_ALIGN;
        if (!memory.exists(dut_out.addr)) begin
          for (int i = 0; i < CFG.LINE_WIDTH/32; i++) begin
            assert(rand_data.randomize());
            memory[addr][i*32+:32] = rand_data.inst;
          end
        end
        if (DEBUG) $info("Response for Address: %h, ID: 0, Data: %h", dut_out.addr, memory[addr]);
        send_data.data = memory[addr];
        response_lock.get();
        in_driver.send(send_data);
        response_lock.put();
      end
      forever begin
        automatic int unsigned stall_cycles;
        automatic dut_out_t dut_out;
        automatic dut_in_t send_data;
        automatic riscv_inst rand_data = new;
        automatic addr_t addr;
        addr_mbx[1].get(dut_out);
        stall_cycles = $urandom_range(1, 10);
        repeat (stall_cycles) @(posedge clk);

        send_data.error = 1'b0;
        send_data.id = 1;
        addr = dut_out.addr >> CFG.LINE_ALIGN << CFG.LINE_ALIGN;
        if (!memory.exists(dut_out.addr)) begin
          for (int i = 0; i < CFG.LINE_WIDTH/32; i++) begin
            assert(rand_data.randomize());
            memory[addr][i*32+:32] = rand_data.inst;
          end
        end
        if (DEBUG) $info("Response for Address: %h, ID: 1, Data: %h", dut_out.addr, memory[addr]);
        send_data.data = memory[addr];
        response_lock.get();
        in_driver.send(send_data);
        response_lock.put();
      end
    join_none
  end

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
