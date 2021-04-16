// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Paul Scheffler <paulsc@iis.ee.ethz.ch>

`include "tcdm_interface/typedef.svh"
`include "tcdm_interface/assign.svh"

module fixture_ssr import snitch_ssr_pkg::*; #(
  parameter int unsigned  AddrWidth = 0,
  parameter int unsigned  DataWidth = 0,
  parameter ssr_cfg_t     Cfg       = '0
);

  // ------------
  //  Parameters
  // ------------

  // Fixture parameters
  localparam bit  TcdmLog   = 0;
  localparam bit  MatchLog  = 1;
  localparam time Timeout   = 200ns;

  // Timing parameters
  localparam time TCK = 10ns;
  localparam time TA  = 2ns;
  localparam time TT  = 8ns;
  localparam int unsigned RstCycles = 10;

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

  // SSR constant / derived parameters
  localparam int unsigned DimWidth = $clog2(Cfg.NumLoops);

  // Configuration written through proper registers
  typedef struct packed {
    logic [31:0] idx_shift;
    logic [31:0] idx_base;
    logic [31:0] idx_size;
    logic [Cfg.NumLoops-1:0][31:0] stride;
    logic [Cfg.NumLoops-1:0][31:0] bound;
    logic [31:0] rep;
  } cfg_regs_t;

  // Fields used in addresses of upper alias registers
  // *Not* the same order as alias address, but as in upper status fields
  typedef struct packed {
    logic no_indir;
    logic write;
    logic [DimWidth-1:0] dims;
  } cfg_alias_fields_t;

  // Upper fields accessible on status register
  typedef struct packed {
    logic done;
    logic write;
    logic [DimWidth-1:0] dims;
    logic indir;
  } cfg_status_upper_t;

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
  logic [4:0]   cfg_word_i;
  logic         cfg_write_i;
  logic [31:0]  cfg_rdata_o;
  logic [31:0]  cfg_wdata_i;
  logic         lane_valid_o;
  logic         lane_ready_i;
  tcdm_req_t    mem_req_o;
  tcdm_rsp_t    mem_rsp_i;
  logic [DataWidth-1:0] lane_rdata_o;
  logic [DataWidth-1:0] lane_wdata_i;
  logic [AddrWidth-1:0] tcdm_start_address_i = '0;    // (currently) required for test flow

  // Device Under Test (DUT)
  snitch_ssr #(
    .Cfg          ( Cfg         ),
    .AddrWidth    ( AddrWidth   ),
    .DataWidth    ( DataWidth   ),
    .tcdm_user_t  ( user_t      ),
    .tcdm_req_t   ( tcdm_req_t  ),
    .tcdm_rsp_t   ( tcdm_rsp_t  )
  ) i_snitch_ssr (
    .clk_i          ( clk       ),
    .rst_ni         ( rst_n     ),
    .cfg_word_i,
    .cfg_write_i,
    .cfg_rdata_o,
    .cfg_wdata_i,
    .lane_rdata_o,
    .lane_wdata_i,
    .lane_valid_o,
    .lane_ready_i,
    .mem_req_o,
    .mem_rsp_i,
    .tcdm_start_address_i
  );

  // ----------------
  //  TCDM interface
  // ----------------

  // Associative (maximum-size) TCDM: models full memory space
  data_t memory [bit [WordAddrWidth-1:0]];

  // TCDM (memory) bus interface
  TCDM_BUS_DV #(
    .ADDR_WIDTH ( AddrWidth ),
    .DATA_WIDTH ( DataWidth ),
    .user_t     ( user_t    )
  ) tcdm_bus (clk);

  // Connect DUT to TCDM bus
  `TCDM_ASSIGN_FROM_REQ(tcdm_bus, mem_req_o)
  `TCDM_ASSIGN_TO_RESP(mem_rsp_i, tcdm_bus)

  // TCDM driver
  tcdm_test::tcdm_driver #(
    .AW     ( AddrWidth ),
    .DW     ( DataWidth ),
    .user_t ( user_t    ),
    .TA     ( TA        ),
    .TT     ( TT        )
  ) tcdm_drv = new(tcdm_bus);

  // Receive and process TCDM requests
  initial begin
    // Reset driver
    @(negedge rst_n);
    tcdm_drv.reset_slave();
    @(posedge rst_n);
    // Serve TCDM until testbench ends
    forever begin
      automatic tcdm_test::req_t #(.AW(AddrWidth), .DW(DataWidth), .user_t(user_t)) req;
      automatic tcdm_test::rsp_t #(.DW(DataWidth)) rsp;
      // Receive request
      tcdm_drv.recv_req(req);
      rsp = new;
      // Process Write
      if (req.write) begin
        if (TcdmLog) $write("Write to 0x%x: 0x%x, strobe 0b%b ... ",
            req.addr, req.data, req.strb);
        for (int i = 0; i < DataWidth/8; i++) begin
          if (req.strb[i])
            memory[req.addr >> WordAddrBits][i*8 +: 8] = req.data[i*8 +: 8];
        end
      // Process Read
      end else begin
        if (TcdmLog) $write("Read from 0x%x: ", req.addr);
        rsp.data = memory[req.addr >> WordAddrBits];
        if (TcdmLog) $write("data 0x%x ... ", rsp.data);
      end
      tcdm_drv.send_rsp(rsp);
      if (TcdmLog) $display("OK");
    end
  end

  // ------------------
  //  Config interface
  // ------------------

  // Register bus interface for configuration
  REG_BUS #(
    .ADDR_WIDTH ( 5  ),
    .DATA_WIDTH ( 32 )
  ) cfg_bus (clk);

  // Connect DUT to config bus
  assign cfg_word_i     = cfg_bus.addr;
  assign cfg_write_i    = cfg_bus.write;
  assign cfg_wdata_i    = cfg_bus.wdata;
  assign cfg_bus.rdata  = cfg_rdata_o;
  assign cfg_bus.ready  = 1'b1;   // SSR always ready for config write

  // Register bus driver
  reg_test::reg_driver #(
    .AW ( 5  ),
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
  task automatic cfg_write (input logic [4:0] addr, input logic [31:0] data);
    logic error;
    cfg_drv.send_write(addr, data, '1, error);
  endtask

  // Wrapped read task
  task automatic cfg_read (input logic [4:0] addr, output logic [31:0] data);
    logic error;
    cfg_drv.send_read(addr, data, error);
  endtask

  // Ignores status field: use launch task to launch job
  task automatic cfg_write_regs (input cfg_regs_t cfg);
    cfg_write(5'h1, cfg.rep);
    for (int i = 0; i < Cfg.NumLoops; ++i) begin
      cfg_write(i+2, cfg.bound[i]);
      cfg_write(i+2+Cfg.NumLoops, cfg.stride[i]);
    end
    cfg_write(2*Cfg.NumLoops+2 + 0, cfg.idx_size);
    cfg_write(2*Cfg.NumLoops+2 + 1, cfg.idx_base);
    cfg_write(2*Cfg.NumLoops+2 + 2, cfg.idx_shift);
  endtask

  task automatic cfg_launch_status (input cfg_status_t cfg);
    cfg_write(0, cfg);
  endtask

  task automatic cfg_launch_alias (input cfg_status_t cfg);
    // NOTE: SSRs will mask the `done` bit on alias launch, but *not* on status launch. Revise?
    logic [4:0] addr;
    addr = '1;
    addr [$bits(cfg_alias_fields_t)-1:0] = {~cfg.upper.indir, cfg.upper.write, cfg.upper.dims};
    cfg_write(addr, cfg.ptr);
  endtask

  // Interface reads
  task automatic cfg_read_regs (output cfg_regs_t cfg);
    cfg_read(5'h1, cfg.rep);
    for (int i = 0; i < 4; ++i) begin
      cfg_read(i+2,  cfg.bound[i]);
      cfg_read(i+2+Cfg.NumLoops, cfg.stride[i]);
    end
  endtask

  task automatic cfg_read_status (output cfg_status_t status);
    cfg_read(5'h0, status);
  endtask

  task automatic cfg_read_done (output logic done);
    cfg_status_t status;
    cfg_read_status(status);
    done = status.upper.done;
  endtask

  // --------------------
  //  Register interface
  // --------------------

  // Register bus interface for hypothetical regfile
  // TODO: this is a bit hacky. Provide a proper SSR interface?
  REG_BUS #(
    .ADDR_WIDTH ( 1         ),  // unused
    .DATA_WIDTH ( DataWidth )
  ) ssr_bus (clk);

  // Register bus driver
  reg_test::reg_driver #(
    .AW ( 1         ),
    .DW ( DataWidth ),
    .TA ( TA        ),
    .TT ( TT        )
  ) ssr_drv = new(ssr_bus);

  // Swap valid and ready to emulate 3-way handshake
  assign lane_wdata_i   = ssr_bus.wdata;
  assign lane_ready_i   = ssr_bus.valid;
  assign ssr_bus.rdata  = lane_rdata_o;
  assign ssr_bus.ready  = lane_valid_o;

  // Reset driver
  initial begin
    @(negedge rst_n);
    ssr_drv.reset_master();
    @(posedge rst_n);
  end

  // Read from SSR
  task automatic ssr_read (output data_t data, input logic timeout = 1);
    logic error;
    fork begin
      ssr_drv.send_read(1'b0, data, error);
    end begin
      #Timeout;
      if (timeout) $fatal(1, "SSR read timed out");
    end join_any
    disable fork;
  endtask

  // Write to SSR
  task automatic ssr_write (input data_t data, input logic timeout = 1);
    logic error;
    fork begin
      ssr_drv.send_write(1'b0, data, '1, error);
    end begin
      #Timeout;
      if (timeout) $fatal(1, "SSR write timed out");
    end join_any
    disable fork;
  endtask

  // Deassert SSR lane readiness manually, e.g. if read or write killed in a timeout fork
  task automatic ssr_ready_kill;
    ssr_bus.valid = 0;
  endtask

  // --------------
  //  Verification
  // --------------

  // Check whether SSR job is done, then try to obtain additional read to be sure
  task automatic verify_done (input logic write);
    logic done;
    data_t data_dummy;
    // Give ample timeout to make sure no more values are provided
    if (write) begin
      // Give some time for writes to complete
      #Timeout;
      // Ensure we signal done
      cfg_read_done(done);
      if (done !== 1) $fatal(1, "write job should be done by now");
    end else begin
      fork begin
        // Ensure we signal done
        cfg_read_done(done);
        if (done !== 1) $fatal(1, "read job should be done by now");
        // Ensure no additional data can be read (do not time out here)
        ssr_read(data_dummy, 0);
        $fatal(1, "Read additional value: %f", $bitstoreal(data_dummy));
      end begin
        #Timeout;
      end join_any
      disable fork;
      // Terminate attempted read
      ssr_ready_kill();
    end
  endtask

  task automatic verify_launch (
    input cfg_regs_t    regs,
    input cfg_status_t  status,
    input logic         alias_launch
  );
    cfg_regs_t    regs_read;
    cfg_status_t  status_read;
    // Write config regs and launch
    cfg_write_regs(regs);
    if (alias_launch) cfg_launch_alias(status);
    else cfg_launch_status(status);
    // Read back and check
    cfg_read_regs(regs_read);
    cfg_read_status(status_read);
    $display("Read Regs: %p Status: %p", regs, status);
  endtask

  // Verify reads of one loop level; used recursively
  // TODO: we assume floating point data when using $bitstoreal. Find a better option?
  task automatic verify_nat_job_loop (
    input logic                           write,
    input logic                           write_check,
    input logic [Cfg.RptWidth-1:0]        rep,
    input logic [Cfg.NumLoops-1:0][31:0]  bound,
    input logic [Cfg.NumLoops-1:0][31:0]  stride,
    input logic [Cfg.NumLoops-1:0]        loop_ena,
    input logic [DimWidth-1:0]            loop_top_idx,
    ref   logic [Cfg.NumLoops-1:0][31:0]  loop_idcs,
    ref   addr_t                          ptr,
    ref   addr_t                          ptr_next,
    ref   addr_t                          ptr_source
  );
    data_t data_actual, data_golden;
    // Lowestmost loop: read from SSR and memory to compare
    if (loop_top_idx == '0) begin
      for (loop_idcs[0] = 0; loop_idcs[0] <= bound[0]; ++loop_idcs[0]) begin
        ptr = ptr_next;
        if (write) begin
          if (write_check) begin
            // NOTE: we assume no write overlaps with read data or other written data here!
            data_actual = memory[ptr >> WordAddrBits];
            data_golden = memory[ptr_source >> WordAddrBits];
            if (data_actual !== data_golden)
              $fatal(1, "Direct write mismatch @ %p, 0x%8x Actual %f vs Golden %f",
                  loop_idcs, ptr, $bitstoreal(data_actual), $bitstoreal(data_golden));
            else if (MatchLog)
              $display("Direct write match @ %p, 0x%8x: %f",
                  loop_idcs, ptr, $bitstoreal(data_actual));
          end else begin
            // SSR reads from ptr_source and writes without immediate check (done later)
            data_golden = memory[ptr_source >> WordAddrBits];
            ssr_write(data_golden);
            if (MatchLog)
                $display("Direct write @ %p, 0x%8x: %f",
                    loop_idcs, ptr, $bitstoreal(data_golden));
          end
          // Linearly advance source pointer
          ptr_source += WordBytes;
        end else begin
          data_golden = memory[ptr >> WordAddrBits];
          for (int r = 0; r <= rep; ++r) begin
            ssr_read(data_actual);
            if (data_actual !== data_golden)
              $fatal(1, "Direct read mismatch @ %p, 0x%8x, rep %0d: Actual %f vs Golden %f",
                  loop_idcs, ptr, r, $bitstoreal(data_actual), $bitstoreal(data_golden));
            else if (MatchLog)
              $display("Direct read match @ %p, 0x%8x, rep %0d: %f",
                  loop_idcs, ptr, r, $bitstoreal(data_actual));
          end
        end
        ptr_next = ptr + stride[0];
      end
    // Higher loop: recurse
    end else begin
      for (loop_idcs[loop_top_idx] = 0;
          loop_idcs[loop_top_idx] <= bound[loop_top_idx] || ~loop_ena[loop_top_idx];
          ++loop_idcs[loop_top_idx])
      begin
        verify_nat_job_loop(write, write_check, rep, bound, stride,
            loop_ena, loop_top_idx-1, loop_idcs, ptr, ptr_next, ptr_source);
        ptr_next = ptr + stride[loop_top_idx];
        if (~loop_ena[loop_top_idx]) break;
      end
    end
  endtask

  // Verify a given natural iteration job
  task automatic verify_nat_job (
    input logic                     write,
    input logic                     alias_launch,
    input addr_t                    data_base,
    input logic [DimWidth-1:0]      num_loops,
    input logic [Cfg.RptWidth-1:0]  rep,
    input logic [3:0][31:0]         bound,
    input logic [3:0][31:0]         stride_elems,
    input addr_t ptr_source = '0,   // For writes only: pointer to linearly-read SSR input data
    input addr_t offs_dest  = '0    // For writes only: pointer to target region for writes
  );
    cfg_regs_t    regs;
    cfg_status_t  status;
    logic [Cfg.NumLoops-1:0]        loop_ena;
    logic [Cfg.NumLoops-1:0][31:0]  stride;
    logic [Cfg.NumLoops-1:0][31:0]  loop_idcs;
    addr_t ptr;
    addr_t data_base_ptr  = data_base + (write ? offs_dest : '0);
    addr_t ptr_next       = data_base_ptr;
    addr_t ptr_source_mut = ptr_source;
    // Determine whether each loop is activated and byte stride
    for (int i = 0; unsigned'(i) < Cfg.NumLoops; ++i) begin
      loop_ena [i]  = (num_loops >= i);
      stride   [i]  = WordBytes * stride_elems[i];
    end
    regs          = {'0, {stride[Cfg.NumLoops-1:0], bound[Cfg.NumLoops-1:0], 32'(rep)}};
    status.upper  = {1'b0, write, num_loops, 1'b0};
    status.ptr    = ptr_next;
    verify_launch(regs, status, alias_launch);
    // Do loops
    verify_nat_job_loop(write, 0, rep, bound, stride,
        loop_ena, Cfg.NumLoops-1, loop_idcs, ptr, ptr_next, ptr_source_mut);
    // Ensure SSR is done after some time to write back
    verify_done(write);
    #Timeout;
    // Check data written to memory if write in separate iteration
    if (write) begin
        // Reset pointers
        ptr_next        = data_base_ptr;
        ptr_source_mut  = ptr_source;
        // Reiterate with checking
        verify_nat_job_loop(1, 1, rep, bound, stride,
            loop_ena, Cfg.NumLoops-1, loop_idcs, ptr, ptr_next, ptr_source_mut);
        $display("%t: Direct write success", $time);
    end else begin
      $display("%t: Direct read success", $time);
    end
  endtask

  task automatic verify_indir_job (
    input logic                     write,
    input logic                     alias_launch,
    input addr_t                    data_base,
    input addr_t                    idx_base,
    input logic [Cfg.RptWidth-1:0]  rep,
    input logic [31:0]              bound,
    input logic [Cfg.ShiftWidth:0]  idx_shift,
    input logic [1:0]               idx_size,
    input addr_t ptr_source = '0    // For writes only: pointer to linearly-read SSR input data
  );
    cfg_regs_t    regs;
    cfg_status_t  status;
    logic [31:0]  idx_base_ptr  = idx_base;
    regs = {32'(idx_shift), 32'(data_base), 32'(idx_size),
        (32*Cfg.NumLoops)'(WordBytes), (32*Cfg.NumLoops)'(bound), 32'(rep)};
    status.upper  = {1'b0, write, {DimWidth{1'b0}}, 1'b1};
    status.ptr    = idx_base_ptr;
    verify_launch(regs, status, alias_launch);
    // Iterate with Loop 0
    for (int i = 0; i <= bound; ++i) begin
      if (write) begin
        data_t data_write = fix.memory[(ptr_source + WordBytes * i) >> WordAddrBits];
        fix.ssr_write(data_write);
        $display("Indirect write @ %0d: %f", i, $bitstoreal(data_write));
      end else begin
        // Model index streaming
        addr_t idx_addr     = idx_base_ptr + (i << idx_size);
        data_t idx_word     = memory[idx_addr >> WordAddrBits];
        data_t idx_mask     = ~(data_t'('1) << (8 << idx_size));
        data_t idx_shft     = idx_word >> (WordAddrBits+3)'(idx_addr[WordAddrBits-1:0] << 3);
        data_t idx          = (idx_shft & idx_mask) << idx_shift;
        addr_t data_addr    = data_base + WordBytes * idx;
        data_t data_golden  = memory[data_addr >> WordAddrBits];
        // Model repetitions
        for (int r = 0; r <= rep; ++r) begin
          data_t data_actual;
          ssr_read(data_actual);
          if (data_actual !== data_golden)
            $fatal(1, string'({"Indirect read mismatch @ %0d, idx 0x%8x, data 0x%8x, ",
                "rep %0d: Actual %f vs Golden %f"}), i, idx_addr, data_addr, r,
                $bitstoreal(data_actual), $bitstoreal(data_golden));
          else if (MatchLog)
            $display("Indirect read match @ %0d, idx 0x%8x, data 0x%8x, rep %0d: %f",
                i, idx_addr, data_addr, r, $bitstoreal(data_actual));
        end
      end
    end
    // Ensure SSR is done after some time to write back
    verify_done(write);
    #Timeout;
    // Check data written to memory if write in separate iteration
    if (write) begin
      // Check results
      for (int i = 0; i <= bound; ++i) begin
        // Recompute addresses SSR should have emitted for each element
        addr_t idx_addr   = idx_base_ptr + (i << idx_size);
        data_t idx_word   = memory[idx_addr >> WordAddrBits];
        data_t idx_mask   = ~(data_t'('1) << (8 << idx_size));
        data_t idx_shft   = idx_word >> (WordAddrBits+3)'(idx_addr[WordAddrBits-1:0] << 3);
        data_t idx        = (idx_shft & idx_mask) << idx_shift;
        addr_t data_addr  = data_base + WordBytes * idx;
        // Load data at this location
        data_t data_actual = fix.memory[data_addr >> WordAddrBits];
        // Load golden data from originally read location
        data_t data_golden = fix.memory[(ptr_source + WordBytes * i) >> WordAddrBits];
        if (data_actual !== data_golden)
          $fatal(1, "Indirect write mismatch @ %0d, idx 0x%8x, data 0x%8x: Actual %f vs Golden %f",
              i, idx_addr, data_addr, $bitstoreal(data_actual), $bitstoreal(data_golden));
        else if (MatchLog)
          $display("Indirect write match @ %0d, idx 0x%8x, data 0x%8x: %f",
              i, idx_addr, data_addr, $bitstoreal(data_actual));
      end
      $display("%t: Indirect write success", $time);
    end else begin
      $display("%t: Indirect read success", $time);
    end
  endtask

endmodule
