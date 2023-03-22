// Copyright 2018-2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Andreas Kurth <akurth@iis.ee.ethz.ch>
// Author: Paul Scheffler <paulsc@iis.ee.ethz.ch>

`include "axi/typedef.svh"
`include "common_cells/registers.svh"

/// AXI4+ATOP Translation Lookaside Buffer (TLB) *without* integrated regfile.
/// Use this as a top level if you want to reuse an existing register file,
/// a different register interface, or avoid this IP's generated registers.
module axi_tlb_noreg #(
  /// Address width of main AXI4+ATOP slave port
  parameter int unsigned AxiSlvPortAddrWidth = 0,
  /// Address width of main AXI4+ATOP master port
  parameter int unsigned AxiMstPortAddrWidth = 0,
  /// Data width of main AXI4+ATOP slave and master port
  parameter int unsigned AxiDataWidth = 0,
  /// ID width of main AXI4+ATOP slave and master port
  parameter int unsigned AxiIdWidth = 0,
  /// Width of user signal of main AXI4+ATOP slave and master port
  parameter int unsigned AxiUserWidth = 0,
  /// Maximum number of in-flight transactions on main AXI4+ATOP slave port
  parameter int unsigned AxiSlvPortMaxTxns = 0,
  /// Number of entries in L1 TLB
  parameter int unsigned L1NumEntries = 0,
  /// Pipeline AW and AR channel after L1 TLB
  parameter bit L1CutAx = 1'b1,
  /// Request type of main AXI4+ATOP slave port
  parameter type slv_req_t = logic,
  /// Request type of main AXI4+ATOP master port
  parameter type mst_req_t = logic,
  /// Response type of main AXI4+ATOP slave and master ports
  parameter type axi_resp_t = logic,
  /// Type of page table entry
  parameter type entry_t = logic
) (
  /// Rising-edge clock of all ports
  input  logic        clk_i,
  /// Asynchronous reset, active low
  input  logic        rst_ni,
  /// Test mode enable
  input  logic        test_en_i,
  /// Main slave port request
  input  slv_req_t    slv_req_i,
  /// Main slave port response
  output axi_resp_t   slv_resp_o,
  /// Main master port request
  output mst_req_t    mst_req_o,
  /// Main master port response
  input  axi_resp_t   mst_resp_i,
  /// Configured translation entries
  input  entry_t [L1NumEntries-1:0] entries_i,
  /// Whether TLB is bypassed (no translation)
  input logic         bypass_i
);

  typedef logic [AxiSlvPortAddrWidth-1:0] slv_addr_t;
  typedef logic [AxiMstPortAddrWidth-1:0] mst_addr_t;
  typedef logic [AxiDataWidth       -1:0] data_t;
  typedef logic [AxiIdWidth         -1:0] id_t;
  typedef logic [AxiDataWidth/8     -1:0] strb_t;
  typedef logic [AxiUserWidth       -1:0] user_t;
  `AXI_TYPEDEF_AW_CHAN_T(slv_aw_t, slv_addr_t, id_t, user_t)
  `AXI_TYPEDEF_AW_CHAN_T(mst_aw_t, mst_addr_t, id_t, user_t)
  `AXI_TYPEDEF_W_CHAN_T(w_t, data_t, strb_t, user_t)
  `AXI_TYPEDEF_B_CHAN_T(b_t, id_t, user_t)
  `AXI_TYPEDEF_AR_CHAN_T(slv_ar_t, slv_addr_t, id_t, user_t)
  `AXI_TYPEDEF_AR_CHAN_T(mst_ar_t, mst_addr_t, id_t, user_t)
  `AXI_TYPEDEF_R_CHAN_T(r_t, data_t, id_t, user_t)
  /// Translation lookup result.
  typedef struct packed {
    logic       hit;
    mst_addr_t  addr;
  } tlb_res_t;

  // Fork input requests into L1 TLB.
  logic aw_valid,             ar_valid,
        aw_ready,             ar_ready,
        l1_tlb_wr_req_valid,  l1_tlb_rd_req_valid,
        l1_tlb_wr_req_ready,  l1_tlb_rd_req_ready;
  stream_fork #(
    .N_OUP  ( 2 )
  ) i_aw_fork (
    .clk_i,
    .rst_ni,
    .valid_i  ( slv_req_i.aw_valid              ),
    .ready_o  ( slv_resp_o.aw_ready             ),
    .valid_o  ( {l1_tlb_wr_req_valid, aw_valid} ),
    .ready_i  ( {l1_tlb_wr_req_ready, aw_ready} )
  );
  stream_fork #(
    .N_OUP  ( 2 )
  ) i_ar_fork (
    .clk_i,
    .rst_ni,
    .valid_i  ( slv_req_i.ar_valid              ),
    .ready_o  ( slv_resp_o.ar_ready             ),
    .valid_o  ( {l1_tlb_rd_req_valid, ar_valid} ),
    .ready_i  ( {l1_tlb_rd_req_ready, ar_ready} )
  );

  // L1 TLB
  tlb_res_t l1_tlb_wr_res,        l1_tlb_rd_res;
  logic     l1_tlb_wr_res_valid,  l1_tlb_rd_res_valid,
            l1_tlb_wr_res_ready,  l1_tlb_rd_res_ready;
  axi_tlb_l1 #(
    .InpAddrWidth     ( AxiSlvPortAddrWidth ),
    .OupAddrWidth     ( AxiMstPortAddrWidth ),
    .NumEntries       ( L1NumEntries        ),
    .res_t            ( tlb_res_t           ),
    .entry_t          ( entry_t             )
  ) i_l1_tlb (
    .clk_i,
    .rst_ni,
    .test_en_i,
    .wr_req_addr_i  ( slv_req_i.aw.addr   ),
    .wr_req_valid_i ( l1_tlb_wr_req_valid ),
    .wr_req_ready_o ( l1_tlb_wr_req_ready ),
    .wr_res_o       ( l1_tlb_wr_res       ),
    .wr_res_valid_o ( l1_tlb_wr_res_valid ),
    .wr_res_ready_i ( l1_tlb_wr_res_ready ),
    .rd_req_addr_i  ( slv_req_i.ar.addr   ),
    .rd_req_valid_i ( l1_tlb_rd_req_valid ),
    .rd_req_ready_o ( l1_tlb_rd_req_ready ),
    .rd_res_o       ( l1_tlb_rd_res       ),
    .rd_res_valid_o ( l1_tlb_rd_res_valid ),
    .rd_res_ready_i ( l1_tlb_rd_res_ready ),
    .entries_i,
    .bypass_i
  );

  // Join L1 TLB responses with Ax requests into demultiplexer.
  slv_req_t   demux_req;
  axi_resp_t  demux_resp;
  stream_join #(
    .N_INP  ( 2 )
  ) i_aw_join (
    .inp_valid_i  ( {l1_tlb_wr_res_valid, aw_valid} ),
    .inp_ready_o  ( {l1_tlb_wr_res_ready, aw_ready} ),
    .oup_valid_o  ( demux_req.aw_valid              ),
    .oup_ready_i  ( demux_resp.aw_ready             )
  );
  assign demux_req.aw = slv_req_i.aw;
  stream_join #(
    .N_INP  ( 2 )
  ) i_ar_join (
    .inp_valid_i  ( {l1_tlb_rd_res_valid, ar_valid} ),
    .inp_ready_o  ( {l1_tlb_rd_res_ready, ar_ready} ),
    .oup_valid_o  ( demux_req.ar_valid              ),
    .oup_ready_i  ( demux_resp.ar_ready             )
  );
  assign demux_req.ar = slv_req_i.ar;

  // Connect W, B, and R channels directly between demultiplexer and slave port.
  assign demux_req.w = slv_req_i.w;
  assign demux_req.w_valid = slv_req_i.w_valid;
  assign slv_resp_o.w_ready = demux_resp.w_ready;
  assign slv_resp_o.b = demux_resp.b;
  assign slv_resp_o.b_valid = demux_resp.b_valid;
  assign demux_req.b_ready = slv_req_i.b_ready;
  assign slv_resp_o.r = demux_resp.r;
  assign slv_resp_o.r_valid = demux_resp.r_valid;
  assign demux_req.r_ready = slv_req_i.r_ready;

  // Demultiplex between address modifier for TLB hits and error slave for TLB misses.
  slv_req_t   mod_addr_req,   err_slv_req;
  axi_resp_t  mod_addr_resp,  err_slv_resp;
  axi_demux #(
    .AxiIdWidth   ( AxiIdWidth        ),
    .aw_chan_t    ( slv_aw_t          ),
    .w_chan_t     ( w_t               ),
    .b_chan_t     ( b_t               ),
    .ar_chan_t    ( slv_ar_t          ),
    .r_chan_t     ( r_t               ),
    .axi_req_t    ( slv_req_t         ),
    .axi_resp_t   ( axi_resp_t        ),
    .NoMstPorts   ( 2                 ),
    .MaxTrans     ( AxiSlvPortMaxTxns ),
    .AxiLookBits  ( AxiIdWidth        ),
    .SpillAw      ( L1CutAx           ),
    .SpillW       ( 1'b0              ),
    .SpillB       ( 1'b0              ),
    .SpillAr      ( L1CutAx           ),
    .SpillR       ( 1'b0              )
  ) i_slv_demux (
    .clk_i,
    .rst_ni,
    .test_i           ( test_en_i                       ),
    .slv_req_i        ( demux_req                       ),
    .slv_aw_select_i  ( l1_tlb_wr_res.hit               ),
    .slv_ar_select_i  ( l1_tlb_rd_res.hit               ),
    .slv_resp_o       ( demux_resp                      ),
    .mst_reqs_o       ( {mod_addr_req,   err_slv_req}   ),
    .mst_resps_i      ( {mod_addr_resp,  err_slv_resp}  )
  );

  // Pipeline translated address together with AW and AR.
  mst_addr_t  l1_tlb_wr_res_addr_buf,
              l1_tlb_rd_res_addr_buf;
  spill_register #(
    .T      ( mst_addr_t  ),
    .Bypass ( ~L1CutAx    )
  ) i_spill_reg_wr_addr (
    .clk_i,
    .rst_ni,
    .valid_i  ( demux_req.aw_valid && l1_tlb_wr_res.hit && demux_resp.aw_ready  ),
    .ready_o  ( /* unused */                                                    ),
    .data_i   ( l1_tlb_wr_res.addr                                              ),
    .valid_o  ( /* unused */                                                    ),
    .ready_i  ( mod_addr_req.aw_valid && mod_addr_resp.aw_ready                 ),
    .data_o   ( l1_tlb_wr_res_addr_buf                                          )
  );
  spill_register #(
    .T      ( mst_addr_t  ),
    .Bypass ( ~L1CutAx    )
  ) i_spill_reg_rd_addr (
    .clk_i,
    .rst_ni,
    .valid_i  ( demux_req.ar_valid && l1_tlb_rd_res.hit && demux_resp.ar_ready  ),
    .ready_o  ( /* unused */                                                    ),
    .data_i   ( l1_tlb_rd_res.addr                                              ),
    .valid_o  ( /* unused */                                                    ),
    .ready_i  ( mod_addr_req.ar_valid && mod_addr_resp.ar_ready                 ),
    .data_o   ( l1_tlb_rd_res_addr_buf                                          )
  );

  // Handle TLB hits: Replace address and forward to master port.
  axi_modify_address #(
    .slv_req_t  ( slv_req_t   ),
    .mst_addr_t ( mst_addr_t  ),
    .mst_req_t  ( mst_req_t   ),
    .axi_resp_t ( axi_resp_t  )
  ) i_mod_addr (
    .slv_req_i      ( mod_addr_req            ),
    .slv_resp_o     ( mod_addr_resp           ),
    .mst_aw_addr_i  ( l1_tlb_wr_res_addr_buf  ),
    .mst_ar_addr_i  ( l1_tlb_rd_res_addr_buf  ),
    .mst_req_o,
    .mst_resp_i
  );

  // Handle TLB misses: Absorb burst and respond with slave error.
  axi_err_slv #(
    .AxiIdWidth   ( AxiIdWidth            ),
    .axi_req_t    ( slv_req_t             ),
    .axi_resp_t   ( axi_resp_t            ),
    .Resp         ( axi_pkg::RESP_SLVERR  ),
    .RespWidth    ( 32'd32                ),
    .RespData     ( 32'hDEC0FFEE          ),
    .ATOPs        ( 1'b1                  ),
    .MaxTrans     ( 1                     )
  ) i_err_slv (
    .clk_i,
    .rst_ni,
    .test_i     ( test_en_i     ),
    .slv_req_i  ( err_slv_req   ),
    .slv_resp_o ( err_slv_resp  )
  );

  // TODO: many parameter and type assertions
endmodule
