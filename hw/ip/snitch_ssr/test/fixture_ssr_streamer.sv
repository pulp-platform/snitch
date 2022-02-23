// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Paul Scheffler <paulsc@iis.ee.ethz.ch>

`include "tcdm_interface/typedef.svh"
`include "tcdm_interface/assign.svh"
`include "snitch_ssr/typedef.svh"

module fixture_ssr_streamer import snitch_ssr_pkg::*; #(
  parameter int unsigned NumSsrs    = 0,
  parameter int unsigned RPorts     = 0,
  parameter int unsigned WPorts     = 0,
  parameter int unsigned AddrWidth  = 0,
  parameter int unsigned DataWidth  = 0,
  parameter ssr_cfg_t [NumSsrs-1:0]   SsrCfgs = '0,
  parameter logic [NumSsrs-1:0][4:0]  SsrRegs = '0
);

  // ------------
  //  Parameters
  // ------------

  // Timing parameters
  localparam time TCK = 10ns;
  localparam time TA  = 2ns;
  localparam time TT  = 8ns;
  localparam int unsigned RstCycles = 10;

  // Fixture parameters
  localparam bit  TcdmLog   = 1;
  localparam bit  MatchLog  = 1;
  localparam time Timeout   = 20*TCK;
  localparam time MstIsectTimeout = 1*TCK;

  // TCDM derived parameters
  localparam int unsigned WordBytes      = DataWidth/8;
  localparam int unsigned WordAddrBits   = $clog2(WordBytes);
  localparam int unsigned WordAddrWidth  = AddrWidth - WordAddrBits;

  // TCDM derived types
  typedef logic [AddrWidth-1:0]   addr_t;
  typedef logic [DataWidth-1:0]   data_t;
  typedef logic [DataWidth/8-1:0] strb_t;
  typedef logic                   user_t;
  `TCDM_TYPEDEF_ALL(tcdm, addr_t, data_t, strb_t, user_t);

  // Configuration written through proper registers
  typedef struct packed {
    logic [31:0] idx_base;
    logic [31:0] idx_cfg;
    logic [3:0][31:0] stride;
    logic [3:0][31:0] bound;
    logic [31:0] rep;
  } cfg_regs_t;

  // Status register type
  typedef struct packed {
    cfg_status_upper_t upper;
    logic [31-$bits(cfg_status_upper_t):0] ptr;
  } cfg_status_t;

  // -----------------
  //  Clock and reset
  // -----------------

  logic clk;
  logic rst_n;

  // Clock and reset generator
  clk_rst_gen #(
    .ClkPeriod    ( TCK       ),
    .RstClkCycles ( RstCycles )
  ) i_clk_rst_gen (
    .clk_o  ( clk   ),
    .rst_no ( rst_n )
  );

  // Wait for reset to start
  task automatic wait_for_reset_start;
    @(negedge rst_n);
  endtask

  // Wait for reset to end
  task automatic wait_for_reset_end;
    @(posedge rst_n);
    @(posedge clk);
  endtask

  // -----
  //  DUT
  // -----

  // DUT signals
  logic [11:0]              cfg_word_i;
  logic                     cfg_write_i;
  logic [31:0]              cfg_rdata_o;
  logic [31:0]              cfg_wdata_i;
  logic                     cfg_wready_o;
  logic  [RPorts-1:0][4:0]  ssr_raddr_i;
  data_t [RPorts-1:0]       ssr_rdata_o;
  logic  [RPorts-1:0]       ssr_rvalid_i;
  logic  [RPorts-1:0]       ssr_rready_o;
  logic  [RPorts-1:0]       ssr_rdone_i;
  logic  [WPorts-1:0][4:0]  ssr_waddr_i;
  data_t [WPorts-1:0]       ssr_wdata_i;
  logic  [WPorts-1:0]       ssr_wvalid_i;
  logic  [WPorts-1:0]       ssr_wready_o;
  logic  [WPorts-1:0]       ssr_wdone_i;
  tcdm_req_t [NumSsrs-1:0]  mem_req_o;
  tcdm_rsp_t [NumSsrs-1:0]  mem_rsp_i;
  logic                     streamctl_done_o;
  logic                     streamctl_valid_o;
  logic                     streamctl_ready_i;
  logic [AddrWidth-1:0]     tcdm_start_address_i = '0;

  // Device Under Test (DUT)

  snitch_ssr_streamer #(
    .NumSsrs      ( NumSsrs     ),
    .RPorts       ( RPorts      ),
    .WPorts       ( WPorts      ),
    .AddrWidth    ( AddrWidth   ),
    .DataWidth    ( DataWidth   ),
    .SsrCfgs      ( SsrCfgs     ),
    .SsrRegs      ( SsrRegs     ),
    .tcdm_user_t  ( user_t      ),
    .tcdm_req_t   ( tcdm_req_t  ),
    .tcdm_rsp_t   ( tcdm_rsp_t  )
  ) i_snitch_ssr_streamer (
    .clk_i      ( clk   ),
    .rst_ni     ( rst_n ),
    .cfg_word_i,
    .cfg_write_i,
    .cfg_rdata_o,
    .cfg_wdata_i,
    .cfg_wready_o,
    .ssr_raddr_i,
    .ssr_rdata_o,
    .ssr_rvalid_i,
    .ssr_rready_o,
    .ssr_rdone_i,
    .ssr_waddr_i,
    .ssr_wdata_i,
    .ssr_wvalid_i,
    .ssr_wready_o,
    .ssr_wdone_i,
    .mem_req_o,
    .mem_rsp_i,
    .streamctl_done_o,
    .streamctl_valid_o,
    .streamctl_ready_i
  );

  // ----------------
  //  TCDM interface
  // ----------------

  // Associative (maximum-size) TCDM: models full memory space
  data_t memory [bit [WordAddrWidth-1:0]];

  for (genvar p = 0; p < NumSsrs; p++) begin : gen_tcdm_ports

    // TCDM (memory) bus interface
    TCDM_BUS_DV #(
      .ADDR_WIDTH ( AddrWidth ),
      .DATA_WIDTH ( DataWidth ),
      .user_t     ( user_t    )
    ) tcdm_bus (clk);

    // Connect DUT to TCDM bus
    `TCDM_ASSIGN_FROM_REQ(tcdm_bus, mem_req_o[p])
    `TCDM_ASSIGN_TO_RESP(mem_rsp_i[p], tcdm_bus)

    // TCDM driver
    tcdm_test::tcdm_driver #(
      .AW     ( AddrWidth ),
      .DW     ( DataWidth ),
      .user_t ( user_t    ),
      .TA     ( TA        ),
      .TT     ( TT        )
    ) tcdm_drv = new(tcdm_bus);

    // TCDM types
    typedef tcdm_test::req_t #(.AW(AddrWidth), .DW(DataWidth), .user_t(user_t)) tcdm_req_t;
    typedef tcdm_test::rsp_t #(.DW(DataWidth)) tcdm_rsp_t;

    // Request queue
    tcdm_req_t reqs [$];

    // Receive and process TCDM requests
    initial begin
      // Reset driver
      @(negedge rst_n);
      tcdm_drv.reset_slave();
      @(posedge rst_n);
      @(posedge clk);
      // Serve TCDM until testbench ends
      fork
        // Buffer requests
        forever begin
          automatic tcdm_req_t req;
          tcdm_drv.recv_req(req);
          reqs.push_back(req);
        end
        // Send responses
        forever begin
          automatic tcdm_req_t req;
          automatic tcdm_rsp_t rsp;
          while (reqs.size() == 0) @(posedge clk);
          req = reqs.pop_front();
          rsp = new;
          // Process Write
          if (req.write) begin
            if (TcdmLog) $display("TCDM[%0d]: Write to 0x%x: 0x%x, strobe 0b%b",
                p, req.addr, req.data, req.strb);
            for (int i = 0; i < DataWidth/8; i++) begin
              if (req.strb[i])
                memory[req.addr >> WordAddrBits][i*8 +: 8] = req.data[i*8 +: 8];
            end
          // Process Read
          end else begin
            rsp.data = memory[req.addr >> WordAddrBits];
            if ($isunknown(rsp.data))
                $fatal(0, "TCDM[%0d]: Data read at %0x contains X: %0x", p, req.addr, rsp.data);
            if (TcdmLog) $display("TCDM[%0d]: Read from 0x%x: data 0x%x",
                p, req.addr, rsp.data);
          end
          tcdm_drv.send_rsp(rsp);
        end
      join_any
    end

  end

  // ------------------
  //  Stream control interface
  // ------------------

  // initialize interface
  initial streamctl_ready_i = 1'b0;

  // Read stream control data
  task automatic streamctl_read_done (output logic done);
    streamctl_ready_i <= #TA 1;
    #TT;
    while (streamctl_valid_o != 1) begin #TCK; end
    done = streamctl_done_o;
    @(posedge clk)
    streamctl_ready_i <= #TA 0;
  endtask


  // ------------------
  //  Config interface
  // ------------------

  // initialize interface
  initial begin
    ssr_raddr_i  = '0;
    ssr_rvalid_i = '0;
    ssr_rdone_i  = '0;
    ssr_waddr_i  = '0;
    ssr_wdata_i  = '0;
    ssr_wvalid_i = '0;
    ssr_wdone_i  = '0;
  end

  // Register bus interface for configuration
  REG_BUS #(
    .ADDR_WIDTH ( 12 ),
    .DATA_WIDTH ( 32 )
  ) cfg_bus (clk);

  // Connect DUT to config bus
  assign cfg_word_i     = cfg_bus.addr;
  assign cfg_write_i    = cfg_bus.write;
  assign cfg_wdata_i    = cfg_bus.wdata;
  assign cfg_bus.rdata  = cfg_rdata_o;
  assign cfg_bus.ready  = ~cfg_bus.write | cfg_wready_o;

  // Register bus driver
  reg_test::reg_driver #(
    .AW ( 12 ),
    .DW ( 32 ),
    .TA ( TA ),
    .TT ( TT )
  ) cfg_drv = new(cfg_bus);

  // Reset driver
  initial begin
    @(negedge rst_n);
    cfg_drv.reset_master();
    @(posedge rst_n);
  end

  // Wrapped read and write tasks
  task automatic cfg_write (input logic [4:0] ssr, input logic [4:0] addr, input logic [31:0] data);
    logic error;
    cfg_drv.send_write({ssr, 2'h0, addr}, data, '1, error);
  endtask

  // Wrapped read task
  task automatic cfg_read (input logic [6:0] ssr, input logic [4:0] addr, output logic [31:0] data);
    logic error;
    cfg_drv.send_read({ssr, 2'h0, addr}, data, error);
  endtask

  // Ignores status field: use launch task to launch job
  task automatic cfg_write_regs (input logic [6:0] ssr, input cfg_regs_t cfg);
    cfg_write(ssr, 1, cfg.rep);
    for (int i = 0; i < 4; ++i) begin
      cfg_write(ssr, i+2, cfg.bound[i]);
      cfg_write(ssr, i+6, cfg.stride[i]);
    end
    cfg_write(ssr, 10, cfg.idx_cfg);
    cfg_write(ssr, 11, cfg.idx_base);
  endtask

  task automatic cfg_launch_status (input logic [6:0] ssr, input cfg_status_t cfg);
    cfg_write(ssr, 0, cfg);
  endtask

  task automatic cfg_launch_alias (input logic [6:0] ssr, input cfg_status_t cfg);
    // NOTE: SSRs will mask the `done` bit on alias launch, but *not* on status launch. Revise?
    logic [4:0] addr;
    addr = '1;
    addr [$bits(cfg_alias_fields_t)-1:0] = {~cfg.upper.indir, cfg.upper.write, cfg.upper.dims};
    cfg_write(ssr, addr, cfg.ptr);
  endtask

  // Interface reads
  task automatic cfg_read_regs (input logic [6:0] ssr, output cfg_regs_t cfg);
    logic [11:0] base = ssr << 5;
    cfg_read(ssr, 1, cfg.rep);
    for (int i = 0; i < 4; ++i) begin
      cfg_read(ssr, i+2, cfg.bound[i]);
      cfg_read(ssr, i+6, cfg.stride[i]);
    end
    cfg_read(ssr, 10, cfg.idx_cfg);
    cfg_read(ssr, 11, cfg.idx_base);
  endtask

  task automatic cfg_read_status (input logic [6:0] ssr, output cfg_status_t status);
    cfg_read(ssr, 0, status);
  endtask

  task automatic cfg_read_done (input logic [6:0] ssr, output logic done);
    cfg_status_t status;
    cfg_read_status(ssr, status);
    done = status.upper.done;
  endtask

  // --------------------
  //  Register interface
  // --------------------

  //  Read all SSRs
  task automatic ssr_read_all (
    input logic   [RPorts-1:0]      rmask,
    input logic   [RPorts-1:0][4:0] addr,
    output data_t [RPorts-1:0]      data
  );
    for (int r = 0; r < RPorts; ++r) begin
      if (rmask[r]) begin
        ssr_raddr_i   [r] <= #TA addr   [r];
        ssr_rvalid_i  [r] <= #TA 1;
        #TT;
        while (ssr_rready_o [r] != 1) begin #TCK; end
        data          [r] = ssr_rdata_o [r];
        ssr_rdone_i   [r] = 1;
        @(posedge clk)
        ssr_rdone_i   [r] <= #TA 0;
        ssr_raddr_i   [r] <= #TA '0;
        ssr_rvalid_i  [r] <= #TA 0;
      end
    end
  endtask

  //  Write all SSRs
  task automatic ssr_write_all (
    input logic  [WPorts-1:0]       wmask,
    input logic  [WPorts-1:0][4:0]  addr,
    input data_t [WPorts-1:0]       data
  );
    for (int w = 0; w < WPorts; ++w) begin
      if (wmask[w]) begin
        ssr_waddr_i   [w] <= #TA addr;
        ssr_wdata_i   [w] <= #TA data;
        ssr_wvalid_i  [w] <= #TA 1;
        #TT;
        while (ssr_wready_o [w] != 1) begin #TCK; end
        ssr_wdone_i   [w] = 1;
        @(posedge clk)
        ssr_wdone_i   [w] <= #TA 0;
        ssr_waddr_i   [w] <= #TA '0;
        ssr_wdata_i   [w] <= #TA '0;
        ssr_wvalid_i  [w] <= #TA 0;
      end
    end
  endtask

  // --------------
  //  Verification
  // --------------

  task automatic verify_launch (
    input logic [6:0]   cfg_ssr,
    input cfg_regs_t    regs,
    input cfg_status_t  status,
    input logic         alias_launch
  );
    cfg_regs_t    regs_read;
    cfg_status_t  status_read;
    // Write config regs and launch
    cfg_write_regs(cfg_ssr, regs);
    if (alias_launch) cfg_launch_alias(cfg_ssr, status);
    else cfg_launch_status(cfg_ssr, status);
    // Read back and check
    cfg_read_regs(cfg_ssr, regs_read);
    cfg_read_status(cfg_ssr, status_read);
    $display("SSR %0d: Read Regs: %p Status: %p", cfg_ssr, regs, status);
  endtask

  // Test a scenario where 2 fibers are read and one is written out using intersected indices;
  // We do not test advanced functionality such as index shifting here.
  task automatic verify_isect_inout (
    input addr_t [2:0]      data_base,    // Both masters and slave
    input addr_t [2:0]      idx_base,     // Both masters and slave
    input logic [1:0][31:0] idx_bound,
    input logic             merge,        // Whether to merge (Union) or intersect indices
    input logic [2:0][3:0]  idx_size,     // Both masters and slave
    input logic             alias_launch,
    input addr_t            idx_gold_base,// Location for expected indices to be written
    input int               len_gold      // Length of expected result vector
  );
    cfg_regs_t    [2:0] regs;
    cfg_status_t  [2:0] status;
    data_t        ssr_data_golden [$];
    data_t        idx_actual, idx_golden;
    data_t        val_actual, val_golden;
    logic         done;
    logic [31:0]  reg_read;
    // Configure SSRs
    cfg_idx_ctl_t cfg_idx_ctl;
    logic [31:0]  idx_bound_slave = '1;
    idx_flags_t   idx_flags = '{merge: merge, default: '0};
    // Master 0
    cfg_idx_ctl = '{size: idx_size[0], flags: idx_flags, default: '0};
    regs  [0] = {32'(data_base[0]), 32'(cfg_idx_ctl),
                  (32*4)'(WordBytes), (32*4)'(idx_bound[0]), 32'h0};
    status[0] = '{upper: {1'b0, 1'b0, 2'b11, 1'b1}, ptr: idx_base[0]};
    verify_launch(0, regs[0], status[0], alias_launch);
    // Master 1
    cfg_idx_ctl = '{size: idx_size[1], flags: idx_flags, default: '0};
    regs  [1] = {32'(data_base[1]), 32'(cfg_idx_ctl),
                  (32*4)'(WordBytes), (32*4)'(idx_bound[1]), 32'h0};
    status[1] = '{upper: {1'b0, 1'b0, 2'b11, 1'b1}, ptr: idx_base[1]};
    verify_launch(1, regs[1], status[1], alias_launch);
    // Slave
    cfg_idx_ctl = '{size: idx_size[2], flags: '0, default: '0};
    regs  [2] = {32'(data_base[2]), 32'(cfg_idx_ctl),
                  (32*4)'(WordBytes), (32*4)'(idx_bound_slave), 32'h0};
    status[2] = '{upper: {1'b0, 1'b1, 2'b01, 1'b1}, ptr: idx_base[2]};
    verify_launch(2, regs[2], status[2], alias_launch);
    // Do operation: take two streams and do element-wise addition/multiplication
    fork
      bit     ssr_in_done = 0;
      data_t  ssr_data_out [$];
      data_t  ssr_wdata;
      int     i = '0;
      logic   done = '0;
      begin
        forever begin
          real   op[2];
          data_t  [RPorts-1:0] ssr_rdata;
          // Check whether another value can/should be read; break on kill
          streamctl_read_done(done);
          $display("Streamctl read %0d: done %0d", i, done); ++i;
          if (done) break;
          ssr_read_all(3'b011, '{2, 1, 0}, ssr_rdata);
          // Check that at least one element is nonzero
          assert(ssr_rdata[0] != '0 || ssr_rdata[1] != '0) else
              $fatal(1, "Read zero from both intersection masters");
          op[0] = $bitstoreal(ssr_rdata[0]);
          op[1] = $bitstoreal(ssr_rdata[1]);
          ssr_wdata = $realtobits(merge ? op[0]+op[1] : op[0]*op[1]);
          ssr_data_golden.push_back(ssr_wdata);
          ssr_data_out.push_back(ssr_wdata);
        end
        ssr_in_done = 1;
      end
      while (ssr_in_done == 0 || ssr_data_out.size() != 0) begin
        while (ssr_data_out.size() == '0 && ~done) @(posedge clk);
        if (done) break;
        ssr_wdata = ssr_data_out.pop_front();
        ssr_write_all('b1, '{2}, ssr_wdata);
      end
    join
    // Check that SSRs are done (Masters first)
    #(MstIsectTimeout);
    cfg_read_done(0, done);
    assert(done) else $fatal(1, "Master SSR 0 not done yet");
    cfg_read_done(1, done);
    assert(done) else $fatal(1, "Master SSR 1 not done yet");
    cfg_read_done(2, done);
    assert(done) else $fatal(1, "Slave SSR 2 not done yet");
    // Verify output length
    assert (ssr_data_golden.size() == len_gold) else
        $fatal(1, "Mismatching result length: actual %0d vs golden %0d",
          ssr_data_golden.size(), len_gold);
    // Verify correct final slave index
    cfg_read(2, 12, reg_read);
    assert (reg_read == len_gold) else
        $fatal(1, "Mismatching index count in slave isect_reg: actual %0d vs golden %0d",
          reg_read, len_gold);
    // Verify memory contents
    foreach (ssr_data_golden[i]) begin
      data_t idx_width  = 8 << idx_size[2];
      data_t idx_offs   = (i * idx_width) % DataWidth;
      data_t idx_mask   = ~({DataWidth{1'b1}} << idx_width);
      addr_t idx_actual_addr = (idx_base[2] + (i << idx_size[2])) >> WordAddrBits;
      data_t idx_actual_word = memory[idx_actual_addr];
      idx_actual = (idx_actual_word >> idx_offs) & idx_mask;
      idx_golden = memory[idx_gold_base + (i*DataWidth/8) >> WordAddrBits];
      val_actual = memory[data_base[2]  + (i*DataWidth/8) >> WordAddrBits];
      val_golden = ssr_data_golden[i];
      if (idx_actual !== idx_golden)
          $fatal(1, "Index mismatch at elem %0d: actual %0d vs golden %0d",
            i, idx_actual, idx_golden);
      else if (MatchLog)
          $display("Index match at elem %0d: %0d", i, idx_actual);
      if (val_actual !== val_golden)
          $fatal(1, "Data mismatch at elem %0d: actual %f vs golden %f",
            i, $bitstoreal(val_actual), $bitstoreal(val_golden));
      else if (MatchLog)
          $display("Data match at elem %0d: %f", i, $bitstoreal(val_actual));
    end
  endtask

endmodule
