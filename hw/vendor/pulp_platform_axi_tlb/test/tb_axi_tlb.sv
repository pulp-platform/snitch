// Copyright 2018-2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Andreas Kurth <akurth@iis.ee.ethz.ch>
// Author: Paul Scheffler <paulsc@iis.ee.ethz.ch>

`include "axi/assign.svh"
`include "axi/typedef.svh"
`include "register_interface/assign.svh"
`include "register_interface/typedef.svh"

/// Testbench for [`axi_tlb`](module.axi_tlb)
module tb_axi_tlb #(
  // DUT Parameters
  parameter int unsigned AxiSlvPortAddrWidth = 32,
  parameter int unsigned AxiMstPortAddrWidth = 64,
  parameter int unsigned AxiDataWidth = 32,
  parameter int unsigned AxiIdWidth = 4,
  parameter int unsigned AxiUserWidth = 4,
  parameter int unsigned AxiSlvPortMaxTxns = 4,
  parameter bit L1CutAx = 1'b1,
  // TB Parameters
  parameter int unsigned NumReads = 1000,
  parameter int unsigned NumWrites = 1000,
  parameter int unsigned MaxInflightReads = 100,
  parameter int unsigned MaxInflightWrites = 100,
  parameter time CyclTime = 10ns,
  parameter time ApplTime = 2ns,
  parameter time TestTime = 8ns,
  // Local parameters; do not override
  parameter type slv_addr_t  = logic [AxiSlvPortAddrWidth-1:0],
  parameter type mst_addr_t  = logic [AxiMstPortAddrWidth-1:0],
  parameter type data_t      = logic [AxiDataWidth-1:0],
  parameter type strb_t      = logic [AxiDataWidth/8-1:0],
  parameter type id_t        = logic [AxiIdWidth-1:0],
  parameter type user_t      = logic [AxiUserWidth-1:0]
);

  // Clock and reset
  logic clk, rst_n;
  clk_rst_gen #(
    .ClkPeriod    ( CyclTime  ),
    .RstClkCycles ( 5         )
  ) i_clk_rst_gen (
    .clk_o  ( clk   ),
    .rst_no ( rst_n )
  );

  // Upstream interface
  `AXI_TYPEDEF_ALL(slv, slv_addr_t, id_t, data_t, strb_t, user_t)
  slv_req_t slv_req;
  slv_resp_t slv_rsp;
  AXI_BUS_DV #(
    .AXI_ADDR_WIDTH ( AxiSlvPortAddrWidth ),
    .AXI_DATA_WIDTH ( AxiDataWidth        ),
    .AXI_ID_WIDTH   ( AxiIdWidth          ),
    .AXI_USER_WIDTH ( AxiUserWidth        )
  ) slv_dv (clk);
  `AXI_ASSIGN_TO_REQ(slv_req, slv_dv)
  `AXI_ASSIGN_FROM_RESP(slv_dv, slv_rsp)

  // Downstream interface
  `AXI_TYPEDEF_ALL(mst, mst_addr_t, id_t, data_t, strb_t, user_t)
  mst_req_t mst_req;
  mst_resp_t mst_rsp;
  AXI_BUS_DV #(
    .AXI_ADDR_WIDTH ( AxiMstPortAddrWidth ),
    .AXI_DATA_WIDTH ( AxiDataWidth        ),
    .AXI_ID_WIDTH   ( AxiIdWidth          ),
    .AXI_USER_WIDTH ( AxiUserWidth        )
  ) mst_dv (clk);
  `AXI_ASSIGN_FROM_REQ(mst_dv, mst_req)
  `AXI_ASSIGN_TO_RESP(mst_rsp, mst_dv)

  // Config interface
  typedef logic [31:0] cfg_addr_t;
  typedef logic [31:0] cfg_data_t;
  typedef logic [3:0] cfg_strb_t;
  `REG_BUS_TYPEDEF_ALL(cfg, cfg_addr_t, cfg_data_t, cfg_strb_t)
  cfg_req_t cfg_req;
  cfg_rsp_t cfg_rsp;
  REG_BUS #(
    .ADDR_WIDTH(32),
    .DATA_WIDTH(32)
  ) cfg(clk);
  `REG_BUS_ASSIGN_TO_REQ(cfg_req, cfg)
  `REG_BUS_ASSIGN_FROM_RSP(cfg, cfg_rsp)

  // DUT
  axi_tlb #(
    .AxiSlvPortAddrWidth ( AxiSlvPortAddrWidth  ),
    .AxiMstPortAddrWidth ( AxiMstPortAddrWidth  ),
    .AxiDataWidth        ( AxiDataWidth         ),
    .AxiIdWidth          ( AxiIdWidth           ),
    .AxiUserWidth        ( AxiUserWidth         ),
    .AxiSlvPortMaxTxns   ( AxiSlvPortMaxTxns    ),
    .L1CutAx             ( L1CutAx              ),
    .slv_req_t           ( slv_req_t  ),
    .mst_req_t           ( mst_req_t  ),
    .axi_resp_t          ( mst_resp_t ),
    .cfg_req_t           ( cfg_req_t  ),
    .cfg_rsp_t           ( cfg_rsp_t  )
  ) i_axi_tlb (
    .clk_i      ( clk     ),
    .rst_ni     ( rst_n   ),
    .test_en_i  ( 1'b0    ),
    .slv_req_i  ( slv_req ),
    .slv_resp_o ( slv_rsp ),
    .mst_req_o  ( mst_req ),
    .mst_resp_i ( mst_rsp ),
    .cfg_req_i  ( cfg_req ),
    .cfg_rsp_o  ( cfg_rsp )
  );

  // TB orchestration
  logic end_of_sim = 1'b0;
  logic end_of_config = 1'b0;
  initial begin
    wait (rst_n);
    wait (end_of_config);
    wait (end_of_sim);
    $info("SUCCESS");
    $finish;
  end

  // Configuration interface
  typedef reg_test::reg_driver #(
    .AW (32),
    .DW (32),
    .TA (CyclTime*0.2),
    .TT (CyclTime*0.8)
  ) cfg_driver_t;
  cfg_driver_t cfg_driver = new (cfg);
  typedef logic [31:0] pfn_t;
  localparam pfn_t first_pfn = 32'h1;      // first PFN (page frame number) of input range
  localparam pfn_t last_pfn = 32'h7_FFFF;  // last PFN of input range
  localparam pfn_t base_pfn = 32'h1_0000;  // map to output range starting with this address
  initial begin
    automatic logic error;
    cfg_driver.reset_master();
    wait (rst_n);
    // Configure page table
    cfg_driver.send_write(32'h0000_0020, first_pfn, '1, error);
    cfg_driver.send_write(32'h0000_0028, last_pfn, '1, error);
    cfg_driver.send_write(32'h0000_0030, base_pfn, '1, error);
    // make valid and read-writable
    cfg_driver.send_write(32'h0000_0038, 32'h0000_0001, '1, error);
    // Enable TLB
    cfg_driver.send_write(32'h0000_0000, 32'h0000_0001, '1, error);
    end_of_config = 1'b1;
  end

  // Capture transactions into upstream and downstream queues.
  localparam int unsigned AxiNumIds = 2**AxiIdWidth;
  mst_aw_chan_t downstream_aw,
                downstream_exp_aw_queue[$];
  mst_w_chan_t  upstream_w,
                downstream_w,
                downstream_exp_w_queue[$];
  mst_b_chan_t  upstream_b,
                downstream_b_queue[AxiNumIds-1:0][$],
                downstream_b;
  mst_ar_chan_t downstream_ar,
                downstream_exp_ar_queue[$];
  mst_r_chan_t  upstream_r,
                downstream_r_queue[AxiNumIds-1:0][$],
                downstream_r;
  `AXI_ASSIGN_TO_W(upstream_w, slv_dv)
  `AXI_ASSIGN_TO_B(upstream_b, slv_dv)
  `AXI_ASSIGN_TO_R(upstream_r, slv_dv)
  `AXI_ASSIGN_TO_AW(downstream_aw, mst_dv)
  `AXI_ASSIGN_TO_W(downstream_w, mst_dv)
  `AXI_ASSIGN_TO_B(downstream_b, mst_dv)
  `AXI_ASSIGN_TO_AR(downstream_ar, mst_dv)
  `AXI_ASSIGN_TO_R(downstream_r, mst_dv)
  function bit addr_in_pfn_range(slv_addr_t addr, pfn_t first_pfn, pfn_t last_pfn);
    automatic pfn_t pfn = addr >> 12;
    return (pfn >= first_pfn) && (pfn <= last_pfn);
  endfunction
  function bit addr_is_mapped(slv_addr_t addr);
    return addr_in_pfn_range(addr, first_pfn, last_pfn);
  endfunction
  function mst_addr_t addr_maps_to(slv_addr_t addr);
    automatic pfn_t maps_to_pfn = (addr >> 12) + base_pfn - first_pfn;
    return (maps_to_pfn << 12) | (addr & 12'hFFF);
  endfunction
  typedef struct {
    bit goes_through;
    id_t id;
    axi_pkg::len_t len;
  } dcsn_t;
  dcsn_t w_dcsn_queue[$], b_dcsn_queue[AxiNumIds-1:0][$], r_dcsn_queue[AxiNumIds-1:0][$];
  initial begin
    wait (rst_n);
    forever begin
      @(posedge clk);
      #TestTime;
      // AW
      if (slv_req.aw_valid && slv_rsp.aw_ready) begin
        automatic dcsn_t w_dcsn;
        w_dcsn.id = slv_req.aw.id;
        if (addr_is_mapped(slv_req.aw.addr)) begin
          automatic mst_aw_chan_t exp_aw;
          `AXI_SET_AW_STRUCT(exp_aw, slv_req.aw)
          exp_aw.addr = addr_maps_to(slv_req.aw.addr);
          downstream_exp_aw_queue.push_back(exp_aw);
          w_dcsn.goes_through = 1'b1;
        end else begin
          w_dcsn.goes_through = 1'b0;
        end
        w_dcsn.len = slv_req.aw.len;
        w_dcsn_queue.push_back(w_dcsn);
      end
      if (mst_req.aw_valid && mst_rsp.aw_ready) begin
        automatic mst_aw_chan_t exp_aw;
        assert (downstream_exp_aw_queue.size() != 0)
          else $fatal(1, "Unexpected AW at master port!");
        exp_aw = downstream_exp_aw_queue.pop_front();
        assert (downstream_aw == exp_aw)
          else $error("AW at master port does not match: %p != %p!", downstream_aw, exp_aw);
      end
      // W
      if (slv_req.w_valid && slv_rsp.w_ready) begin
        automatic dcsn_t w_dcsn;
        assert (w_dcsn_queue.size() != 0)
          else $fatal(1, "W beat that TB cannot handle at slave port!");
        w_dcsn = w_dcsn_queue[0];
        if (w_dcsn.goes_through) begin
          downstream_exp_w_queue.push_back(upstream_w);
        end
        if (upstream_w.last) begin
          b_dcsn_queue[w_dcsn.id].push_back(w_dcsn);
          void'(w_dcsn_queue.pop_front());
        end
      end
      if (mst_req.w_valid && mst_rsp.w_ready) begin
        automatic mst_w_chan_t exp_w;
        assert (downstream_exp_w_queue.size() != 0)
          else $fatal(1, "Unexpected W at master port!");
        exp_w = downstream_exp_w_queue.pop_front();
        assert (downstream_w == exp_w)
          else $error("W at master port does not match: %p != %p!", downstream_w, exp_w);
      end
      // B
      if (mst_rsp.b_valid && mst_req.b_ready) begin
        downstream_b_queue[mst_rsp.b.id].push_back(downstream_b);
      end
      if (slv_rsp.b_valid && slv_req.b_ready) begin
        automatic slv_b_chan_t exp_b;
        automatic dcsn_t b_dcsn;
        assert (b_dcsn_queue[slv_rsp.b.id].size() != 0)
          else $fatal(1, "Unexpected B with ID %0d at slave port!", slv_rsp.b.id);
        b_dcsn = b_dcsn_queue[slv_rsp.b.id].pop_front();
        if (b_dcsn.goes_through) begin
          assert (downstream_b_queue[slv_rsp.b.id].size() != 0)
            else $fatal(1, "Unexpected B with ID %0d at slave port!", slv_rsp.b.id);
          exp_b = downstream_b_queue[slv_rsp.b.id].pop_front();
        end else begin
          exp_b = '{
            id: b_dcsn.id,
            resp: axi_pkg::RESP_SLVERR,
            user: 'x
          };
        end
        assert (upstream_b ==? exp_b)
          else $fatal("B at slave port does not match: %p != %p!", upstream_b, exp_b);
      end
      // AR
      if (slv_req.ar_valid && slv_rsp.ar_ready) begin
        automatic dcsn_t r_dcsn;
        r_dcsn.id = slv_req.ar.id;
        if (addr_is_mapped(slv_req.ar.addr)) begin
          automatic mst_ar_chan_t exp_ar;
          `AXI_SET_AR_STRUCT(exp_ar, slv_req.ar)
          exp_ar.addr = addr_maps_to(slv_req.ar.addr);
          downstream_exp_ar_queue.push_back(exp_ar);
          r_dcsn.goes_through = 1'b1;
        end else begin
          r_dcsn.goes_through = 1'b0;
        end
        r_dcsn.len = slv_req.ar.len;
        r_dcsn_queue[r_dcsn.id].push_back(r_dcsn);
      end
      if (mst_req.ar_valid && mst_rsp.ar_ready) begin
        automatic mst_ar_chan_t exp_ar;
        assert (downstream_exp_ar_queue.size() != 0)
          else $fatal(1, "Unexpected AR at master port!");
        exp_ar = downstream_exp_ar_queue.pop_front();
        assert (downstream_ar == exp_ar)
          else $fatal("AR at master port does not match: %p != %p!", downstream_ar, exp_ar);
      end
      // R
      if (mst_rsp.r_valid && mst_req.r_ready) begin
        downstream_r_queue[mst_rsp.r.id].push_back(downstream_r);
      end
      if (slv_rsp.r_valid && slv_req.r_ready) begin
        automatic mst_r_chan_t exp_r;
        automatic dcsn_t r_dcsn;
        assert (r_dcsn_queue[slv_rsp.r.id].size() != 0)
          else $fatal(1, "Unexpected R with ID %0d at slave port!", slv_rsp.r.id);
        r_dcsn = r_dcsn_queue[slv_rsp.r.id][0];
        if (r_dcsn.goes_through) begin
          assert (downstream_r_queue[slv_rsp.r.id].size() != 0)
            else $fatal(1, "Unexpected R with ID %0d at slave port!", slv_rsp.r.id);
          exp_r = downstream_r_queue[slv_rsp.r.id].pop_front();
        end else begin
          exp_r = '{
            data: 'x,
            id: r_dcsn.id,
            last: (r_dcsn.len == '0),
            resp: axi_pkg::RESP_SLVERR,
            user: 'x
          };
        end
        assert (upstream_r ==? exp_r)
          else $fatal("R at slave port does not match: %p != %p!", upstream_r, exp_r);
        if (r_dcsn.len == '0) begin
          assert (exp_r.last) else $fatal("Expected last R beat!");
          void'(r_dcsn_queue[exp_r.id].pop_front());
        end else begin
          r_dcsn_queue[exp_r.id][0].len -= 1;
        end
      end
    end
  end

  // Upstream driver
  axi_test::axi_rand_master #(
    .AW               ( AxiSlvPortAddrWidth ),
    .DW               ( AxiDataWidth        ),
    .IW               ( AxiIdWidth          ),
    .UW               ( AxiUserWidth        ),
    .TA               ( ApplTime            ),
    .TT               ( TestTime            ),
    .MAX_READ_TXNS    ( MaxInflightReads    ),
    .MAX_WRITE_TXNS   ( MaxInflightWrites   ),
    .AXI_EXCLS        ( 1'b1                ),
    .AXI_ATOPS        ( 1'b0                ),
    .AXI_BURST_FIXED  ( 1'b1                ),
    .AXI_BURST_INCR   ( 1'b1                ),
    .AXI_BURST_WRAP   ( 1'b1                )
  ) upstream_driver = new(slv_dv);
  initial begin
    // TODO: add two memory regions: one that is mapped in the TLB and one that is not
    //upstream_driver.add_memory_region(32'h0000_0000, 32'h1000_0000, axi_pkg::DEVICE_NONBUFFERABLE);
    //upstream_driver.add_memory_region(/* ... */);
    upstream_driver.reset();
    wait (rst_n);
    //wait (end_of_config);
    upstream_driver.run(NumReads, NumWrites);
    end_of_sim = 1'b1;
  end

  // Downstream driver
  axi_test::axi_rand_slave #(
    .AW ( AxiMstPortAddrWidth ),
    .DW ( AxiDataWidth        ),
    .IW ( AxiIdWidth          ),
    .UW ( AxiUserWidth        ),
    .TA ( ApplTime            ),
    .TT ( TestTime            )
  ) downstream_driver = new(mst_dv);
  initial begin
    downstream_driver.reset();
    wait (rst_n);
    downstream_driver.run();
  end

endmodule
