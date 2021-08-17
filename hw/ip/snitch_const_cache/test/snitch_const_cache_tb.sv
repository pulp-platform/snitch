// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>

parameter CacheLineWidth = 256;

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

// Inherit from the random AXI master, but modify the request to emulate a core requesting intstructions.
class semirand_axi_master #(
  // AXI interface parameters
  parameter int   AW = 32,
  parameter int   DW = 32,
  parameter int   IW = 8,
  parameter int   UW = 1,
  // Stimuli application and test time
  parameter time  TA = 0ps,
  parameter time  TT = 0ps,
  // Maximum number of read and write transactions in flight
  parameter int   MAX_READ_TXNS = 1,
  parameter int   MAX_WRITE_TXNS = 1,
  // Upper and lower bounds on wait cycles on Ax, W, and resp (R and B) channels
  parameter int   AX_MIN_WAIT_CYCLES = 0,
  parameter int   AX_MAX_WAIT_CYCLES = 100,
  parameter int   W_MIN_WAIT_CYCLES = 0,
  parameter int   W_MAX_WAIT_CYCLES = 5,
  parameter int   RESP_MIN_WAIT_CYCLES = 0,
  parameter int   RESP_MAX_WAIT_CYCLES = 20,
  // AXI feature usage
  parameter int   AXI_MAX_BURST_LEN = 0, // maximum number of beats in burst; 0 = AXI max (256)
  parameter int   TRAFFIC_SHAPING   = 0,
  parameter bit   AXI_EXCLS         = 1'b0,
  parameter bit   AXI_ATOPS         = 1'b0,
  parameter bit   AXI_BURST_FIXED   = 1'b1,
  parameter bit   AXI_BURST_INCR    = 1'b1,
  parameter bit   AXI_BURST_WRAP    = 1'b0,
  // Dependent parameters, do not override.
  parameter int   AXI_STRB_WIDTH = DW/8,
  parameter int   N_AXI_IDS = 2**IW
) extends axi_test::rand_axi_master #(
  .AW                   ( AW                   ),
  .DW                   ( DW                   ),
  .IW                   ( IW                   ),
  .UW                   ( UW                   ),
  .TA                   ( TA                   ),
  .TT                   ( TT                   ),
  .MAX_READ_TXNS        ( MAX_READ_TXNS        ),
  .MAX_WRITE_TXNS       ( MAX_WRITE_TXNS       ),
  .AX_MIN_WAIT_CYCLES   ( AX_MIN_WAIT_CYCLES   ),
  .AX_MAX_WAIT_CYCLES   ( AX_MAX_WAIT_CYCLES   ),
  .W_MIN_WAIT_CYCLES    ( W_MIN_WAIT_CYCLES    ),
  .W_MAX_WAIT_CYCLES    ( W_MAX_WAIT_CYCLES    ),
  .RESP_MIN_WAIT_CYCLES ( RESP_MIN_WAIT_CYCLES ),
  .RESP_MAX_WAIT_CYCLES ( RESP_MAX_WAIT_CYCLES ),
  .AXI_MAX_BURST_LEN    ( AXI_MAX_BURST_LEN    ),
  .TRAFFIC_SHAPING      ( TRAFFIC_SHAPING      ),
  .AXI_EXCLS            ( AXI_EXCLS            ),
  .AXI_ATOPS            ( AXI_ATOPS            ),
  .AXI_BURST_FIXED      ( AXI_BURST_FIXED      ),
  .AXI_BURST_INCR       ( AXI_BURST_INCR       ),
  .AXI_BURST_WRAP       ( AXI_BURST_WRAP       )
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

  task send_ars(input int n_reads);
    automatic logic rand_success;
    automatic ax_beat_t ar_beat = new_rand_burst(1'b1);
    repeat (n_reads) begin
      automatic id_t id;
      automatic logic jump;
      // Increment address per default, randomize sporadically
      rand_success = std::randomize(jump) with {jump dist {1'b0 := 90, 1'b1 := 10};}; assert(rand_success);
      if (jump) begin
        ar_beat = new_rand_burst(1'b1);
      end else begin
        ar_beat.ax_addr = ar_beat.ax_addr + CacheLineWidth/8;
      end
      // Align address
      ar_beat.ax_addr = ar_beat.ax_addr >> $clog2(CacheLineWidth/8) << $clog2(CacheLineWidth/8);
      while (tot_r_flight_cnt >= MAX_READ_TXNS) begin
        rand_wait(1, 1);
      end
      if (AXI_EXCLS) begin
        rand_excl_ar(ar_beat);
      end
      if (AXI_ATOPS) begin
        // The ID must not be the same as that of any in-flight ATOP.
        forever begin
          cnt_sem.get();
          rand_success = std::randomize(id); assert(rand_success);
          if (!atop_resp_b[id] && !atop_resp_r[id]) begin
            break;
          end else begin
            // The random ID does not meet the requirements, so try another ID in the next cycle.
            cnt_sem.put();
            rand_wait(1, 1);
          end
        end
        ar_beat.ax_id = id;
      end else begin
        cnt_sem.get();
      end
      r_flight_cnt[ar_beat.ax_id]++;
      tot_r_flight_cnt++;
      cnt_sem.put();
      rand_wait(AX_MIN_WAIT_CYCLES, AX_MAX_WAIT_CYCLES);
      drv.send_ar(ar_beat);
      if (ar_beat.ax_lock) excl_queue.push_back(ar_beat);
    end
  endtask

  // Issue n_reads random read and n_writes random write transactions to an address range.
  task run(input int n_reads, input int n_writes);
    automatic logic  ar_done = 1'b0,
                     aw_done = 1'b0;
    fork
      begin
        send_ars(n_reads);
        ar_done = 1'b1;
      end
      recv_rs(ar_done, aw_done);
      begin
        create_aws(n_writes);
        aw_done = 1'b1;
      end
      send_aws(aw_done);
      send_ws(aw_done);
      recv_bs(aw_done);
    join
  endtask

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
      for (int i = 0; i < (DW/32); i++) begin
        r_beat.r_data[i*32 +: 32] = (ar_beat.ax_addr >> $clog2(DW/8) << $clog2(DW/8)) + (4*i);
      end
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
    parameter int LINE_WIDTH = 256,
    parameter int LINE_COUNT = 64,
    parameter int SET_COUNT = 2, // TODO Case with one set not working
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
  localparam int unsigned AxiInIdWidth = 3;
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
  localparam axi_addr_t CachedRegionEnd   = axi_addr_t'(32'h8000_1000);

  // backing memory
  logic [LINE_WIDTH-1:0] memory [logic [AddrWidth-1:0]];

  logic  clk, rst;

  typedef semirand_axi_master #(
    .AW                   ( AddrWidth    ),
    .DW                   ( AxiDataWidth ),
    .IW                   ( AxiInIdWidth ),
    .UW                   ( AxiUserWidth ),
    .TA                   ( TA           ),
    .TT                   ( TT           ),
    .MAX_READ_TXNS        ( 16           ),
    .MAX_WRITE_TXNS       ( 4            ),
    .AX_MIN_WAIT_CYCLES   ( 0            ),
    .AX_MAX_WAIT_CYCLES   ( 8            ),
    .W_MIN_WAIT_CYCLES    ( 0            ),
    .W_MAX_WAIT_CYCLES    ( 8            ),
    .RESP_MIN_WAIT_CYCLES ( 0            ),
    .RESP_MAX_WAIT_CYCLES ( 8            ),
    .AXI_MAX_BURST_LEN    ( 16           ),
    .TRAFFIC_SHAPING      ( 0            ),
    .AXI_EXCLS            ( 1'b1         ),
    .AXI_ATOPS            ( 1'b1         ),
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
    .AX_MAX_WAIT_CYCLES   ( 8             ),
    .R_MIN_WAIT_CYCLES    ( 0             ),
    .R_MAX_WAIT_CYCLES    ( 8             ),
    .RESP_MIN_WAIT_CYCLES ( 0             ),
    .RESP_MAX_WAIT_CYCLES ( 8             )
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
    .enable_i      ( 1'b1                ),
    .flush_valid_i ( 1'b0                ),
    .flush_ready_o ( /*unused*/          ),
    .start_addr_i  ( {CachedRegionStart} ),
    .end_addr_i    ( {CachedRegionEnd}   ),
    .axi_slv_req_i ( axi_mst_req         ),
    .axi_slv_rsp_o ( axi_mst_resp        ),
    .axi_mst_req_o ( axi_slv_req         ),
    .axi_mst_rsp_i ( axi_slv_resp        )
  );

  task static cycle_start;
    #TT;
  endtask

  task static cycle_end;
    @(posedge clk);
  endtask

  // typedef axi_test::axi_ax_beat #(.AW(AxiAddrWidth), .IW(AxiInIdWidth), .UW(AxiUserWidth)) ar_beat_t;

  typedef axi_test::axi_driver #(
    .AW(AxiAddrWidth), .DW(AxiDataWidth), .IW(AxiInIdWidth), .UW(AxiUserWidth), .TA(TA), .TT(TT)
  ) axi_driver_t;

  typedef axi_driver_t::ax_beat_t ar_beat_t;
  typedef axi_driver_t::r_beat_t  r_beat_t;

  initial begin
    automatic logic rand_success;
    automatic ar_beat_t ar_beat = new;
    automatic r_beat_t r_beat = new;

    ar_beat.ax_id     = '1;
    ar_beat.ax_addr   = CachedRegionStart;
    ar_beat.ax_len    = 7;
    ar_beat.ax_size   = $clog2(AxiStrbWidth);
    ar_beat.ax_burst  = axi_pkg::BURST_INCR;
    ar_beat.ax_lock   = 1'b0;
    ar_beat.ax_cache  = axi_pkg::WTHRU_RALLOCATE;
    ar_beat.ax_prot   = '0;
    ar_beat.ax_qos    = '0;
    ar_beat.ax_region = '0;
    ar_beat.ax_atop   = '0;
    ar_beat.ax_user   = '1;

    // Initialize memory region of random axi master to only fetch from two lines
    mst_intf.add_memory_region(CachedRegionStart, CachedRegionEnd, axi_pkg::WTHRU_RALLOCATE);

    // Reset
    mst_intf.reset();
    @(negedge rst);
    #1000ns;

    mst_intf.drv.send_ar(ar_beat);
    for (int i = 0; i <= ar_beat.ax_len; i++) begin
      mst_intf.drv.recv_r(r_beat);
    end
    #10000ns;
    mst_intf.drv.send_ar(ar_beat);
    for (int i = 0; i <= ar_beat.ax_len; i++) begin
      mst_intf.drv.recv_r(r_beat);
    end
    #10000ns;
    fork
      begin
        ar_beat.ax_addr   = CachedRegionStart+'h100;
        ar_beat.ax_len    = 0;
        mst_intf.drv.send_ar(ar_beat);
        ar_beat.ax_id     = '0;
        mst_intf.drv.send_ar(ar_beat);
      end
      begin
        for (int i = 0; i <= ar_beat.ax_len; i++) begin
          mst_intf.drv.recv_r(r_beat);
        end
        for (int i = 0; i <= ar_beat.ax_len; i++) begin
          mst_intf.drv.recv_r(r_beat);
        end
      end
    join
    #10000ns;

    mst_intf.run(1000, 0);

    mst_intf.add_memory_region(CachedRegionStart, CachedRegionStart+2*(CachedRegionEnd-CachedRegionStart), axi_pkg::WTHRU_RALLOCATE);
    #1000ns;
    mst_intf.run(1000, 0);

    $finish();
  end

  initial begin : proc_sim_mem
    slv_intf.reset();
    @(negedge rst);
    slv_intf.run();
  end

  ////////////////////////
  // Checker tasks      //
  ////////////////////////

  // Queues
  localparam int unsigned NoIds = 2**AxiInIdWidth;
  axi_mst_ar_chan_t ar_queues[NoIds-1:0][$];
  axi_mst_r_chan_t  r_queues[NoIds-1:0][$];

  // channel sampling into queues
  always @(posedge clk) #TT begin : proc_channel_sample
    automatic axi_mst_ar_chan_t ar_beat;
    // only execute when reset is high
    if (!rst) begin
      // AR channel
      if (axi_mst_req.ar_valid && axi_mst_resp.ar_ready) begin
        ar_queues[axi_mst_req.ar.id].push_back(axi_mst_req.ar);
      end
      // R channel
      if (axi_mst_resp.r_valid && axi_mst_req.r_ready) begin
        r_queues[axi_mst_resp.r.id].push_back(axi_mst_resp.r);
      end
    end
  end

  initial begin
    automatic axi_mst_ar_chan_t  ar_beat;
    automatic axi_mst_r_chan_t   r_beat;
    automatic axi_addr_t         addr;
    automatic axi_addr_t         aligned_addr;
    automatic axi_data_t         exp_data;
    automatic int unsigned       no_r_beat[NoIds];
    $timeformat(-9, 2, " ns", 20);
    @(negedge rst);
    forever begin
      @(posedge clk);
      #TT;
      // Check all read queues
      for (int unsigned i = 0; i < NoIds; i++) begin
        while (ar_queues[i].size() != 0 && r_queues[i].size() != 0) begin
          ar_beat = ar_queues[i][0];
          addr = ar_beat.addr;
          for (int unsigned j = 0; j <= ar_beat.len; j++) begin
            wait (r_queues[i].size() > 0);
            r_beat  = r_queues[i].pop_front();
            // Check data
            aligned_addr = addr >> $clog2(AxiDataWidth/8) << $clog2(AxiDataWidth/8);
            for (int i = 0; i < (AxiDataWidth/32); i++) begin
              exp_data[i*32 +: 32] = aligned_addr + (4*i);
            end
            if (r_beat.data != exp_data) begin // TODO: Only works for DW = AW and non-bursts
              $display("Error (%0t): Read returned wrong data. Addr=0x%x, Beat=%d, Size=%d Aqc=0x%x Exp=0x%x", $time, ar_beat.addr, no_r_beat[i], ar_beat.size, r_beat.data, exp_data);
            end

            if (r_beat.last && !(ar_beat.len == no_r_beat[i])) begin
              $display("ERROR> Last flag was not expected!!!!!!!!!!!!!");
            end
            no_r_beat[i]++;
            // pop the queue if it is the last flag
            if (r_beat.last) begin
              ar_beat = ar_queues[i].pop_front();
              no_r_beat[i] = 0;
            end else begin
              addr = addr + (1 << ar_beat.size);
            end
          end
        end
      end
    end
  end

  ////////////////////////
  // Debug              //
  ////////////////////////
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
