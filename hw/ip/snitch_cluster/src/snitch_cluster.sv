// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

/// Snitch many-core cluster with improved TCDM interconnect.

`include "common_cells/registers.svh"
`include "axi/assign.svh"
`include "register_interface/typedef.svh"

// Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>
// Author: Fabian Schuiki <fschuiki@iis.ee.ethz.ch>
// Author: Thomas Benz <tbenz@iis.ee.ethz.ch>

module snitch_cluster
  import snitch_pkg::*;
#(
  parameter logic [31:0] BootAddr    = 32'h0,
  /// Make sure NrCores and NrBanks are aligned to powers of two at the moment
  parameter int unsigned NrCores     = 16,
  parameter int unsigned BankFactor  = 2,
  parameter int unsigned NrBanks     = BankFactor * NrCores,
  /// Width of a single icache line.
  parameter int unsigned ICacheLineWidth  = NrCores > 2 ? NrCores * 32 : 64,
  /// Number of icache lines per set.
  parameter int unsigned ICacheLineCount  = 128,
  /// Number of icache sets.
  parameter int unsigned ICacheSets       = 4,
  /// Per-core enabling of the standard `E` ISA reduced-register extension.
  parameter bit [NrCores-1:0] RVE = '0,
  /// Per-core enabling of the standard `F` and `D` ISA extensions.
  parameter bit [NrCores-1:0] RVFD = '1 ^ (1 << (NrCores-1)),
  /// Per-core enabling of the custom `Xdma` ISA extensions.
  parameter bit [NrCores-1:0] Xdma = '0 ^ (1 << (NrCores-1)),
  /// Per-core enabling of the custom `Xssr` ISA extensions.
  parameter bit [NrCores-1:0] Xssr = RVFD,
  /// Data/TCDM memory depth per cut (in words).
  parameter int unsigned TCDMDepth   = 1024,
  parameter tcdm_interconnect_pkg::topo_e Topology  = tcdm_interconnect_pkg::BFLY4,
  parameter int unsigned NumPar      = 1,  // number of parallel layers in
  /* Timing Tuning Parameters */
  /// Insert Pipeline registers into off-loading path (request)
  parameter bit          RegisterOffload    = 1'b1,
  /// Insert Pipeline registers into off-loading path (response)
  parameter bit          RegisterOffloadRsp = 1'b0,
  /// Insert Pipeline registers into data memory request path
  parameter bit          RegisterTCDMReq    = 1'b1,
  /// Insert Pipeline registers after each memory cut
  parameter bit          RegisterTCDMCuts   = 1'b0,
  /// Decouple wide external AXI plug
  parameter bit          RegisterExtWide    = 1'b0,
  /// Decouple narrow external AXI plug
  parameter bit          RegisterExtNarrow  = 1'b0,
  /// Insert Pipeline registers after sequencer
  parameter bit          RegisterSequencer  = 1'b0,
  // memory latency parameter
  parameter int unsigned MemoryMacroLatency = 1 + RegisterTCDMCuts,
  /// Run Snitch (the integer part) at half of the clock frequency
  parameter bit          IsoCrossing        = 0,
  /// Do Not Change:
  parameter int          CoresPerHive = 4,
  localparam int NrHives = (NrCores + CoresPerHive - 1) / CoresPerHive
) (
  input  logic                          clk_i,
  input  logic                          rst_i, // asynchronous active high reset
  input  logic [NrCores-1:0]            debug_req_i,
  input  logic [NrCores-1:0]            meip_i,
  input  logic [NrCores-1:0]            mtip_i,
  input  logic [NrCores-1:0]            msip_i,
  input  logic [9:0]                    hart_base_id_i, // first id of the cluster
  input  logic                          clk_d2_bypass_i, // Bypass clock
  input  snitch_axi_pkg::req_t          axi_slv_req_i,
  output snitch_axi_pkg::resp_t         axi_slv_res_o,
  output snitch_axi_pkg::req_slv_t      axi_mst_req_o,
  input  snitch_axi_pkg::resp_slv_t     axi_mst_res_i,
  output snitch_axi_pkg::req_dma_slv_t  ext_dma_req_o, // CAREFUL: This is the MST port!
  input  snitch_axi_pkg::resp_dma_slv_t ext_dma_resp_i // CAREFUL: This is the MST port!
);

  /// Minimum width to hold the core number.
  localparam int unsigned CoreIDWidth = cf_math_pkg::idx_width(NrCores);
  localparam int unsigned TotNrCores = NrCores; // TODO(fschuiki): remove this!
  localparam int unsigned TCDMAddrWidth = $clog2(TCDMDepth);
  // Two ports SSRs + BankFactor * NrCores
  localparam int unsigned DMADataWidth = snitch_axi_pkg::DMADataWidth;  // DMA data port width
  localparam int unsigned BPSB = DMADataWidth / DLEN;                   //BPSB: banks per super bank
  localparam int unsigned NrSuperBanks = NrBanks / BPSB;
  localparam int unsigned NrDMAPorts = 1;

  // the last hive in the cluster can potentially be a special hive (holding the SDMA)
  // it therefore can hold a different number of cores
  localparam int unsigned NrTotalCores  = NrCores; // TODO(fschuiki): remove this!

  // Sanity check the parameters. Not every configuration makes sense.
  // pragma translate_off
  `ifndef VERILATOR
  initial begin
    assert(DMADataWidth == 512)
    else $info("Design was never tested with this configuration");
    assert(DMADataWidth % DLEN == 0)
    else $fatal(1, "DMA port has to be multiple of %0d (bank width)", DLEN);
    assert(NrBanks >= BPSB)
    else $fatal(1, "DMA requires at least %0d banks (one superbank)", BPSB);
    assert(NrBanks % BPSB == 0)
    else $fatal(1, "Number of banks must be a multiple of %0d (one superbank)", BPSB);
  end
  `endif
  // pragma translate_on
  typedef struct packed {
    snitch_pkg::data_t      data;
    snitch_pkg::amo_op_t    amo;
    logic [CoreIDWidth-1:0] core_id;
    bit                     is_core;
  } tcdm_payload_t;

  logic [NrCores-1:0] debug_req;
  logic [NrCores-1:0] meip;
  logic [NrCores-1:0] mtip;
  logic [NrCores-1:0] msip;

  for (genvar i = 0; i < NrCores; i++) begin : gen_sync
    sync #(.STAGES (2))
      i_sync_debug (.clk_i, .rst_ni (~rst_i), .serial_i (debug_req_i[i]), .serial_o (debug_req[i]));
    sync #(.STAGES (2))
      i_sync_meip  (.clk_i, .rst_ni (~rst_i), .serial_i (meip_i[i]), .serial_o (meip[i]));
    sync #(.STAGES (2))
      i_sync_mtip  (.clk_i, .rst_ni (~rst_i), .serial_i (mtip_i[i]), .serial_o (mtip[i]));
    sync #(.STAGES (2))
      i_sync_msip  (.clk_i, .rst_ni (~rst_i), .serial_i (msip_i[i]), .serial_o (msip[i]));
  end

  logic soc_qvalid;
  logic soc_qready;
  logic soc_pvalid;
  logic soc_pready;

  logic refill_qvalid_o;
  logic refill_qready_i;
  logic refill_pvalid_i;
  logic refill_plast_i;
  logic refill_pready_o;

  addr_t  [NrHives-1:0] ptw_data_qaddr;
  logic               [NrHives-1:0] ptw_data_qvalid;
  logic               [NrHives-1:0] ptw_data_qready;
  dresp_t [NrHives-1:0] ptw_data_prsp;
  logic               [NrHives-1:0] ptw_data_pvalid;
  logic               [NrHives-1:0] ptw_data_pready;

  typedef struct packed {
    addr_t addr;
    logic write;
  } ptw_req_t;

  ptw_req_t [NrHives-1:0] ptw_data_req;
  ptw_req_t ptw_req;
  dresp_t ptw_rsp;
  logic ptw_req_ready, ptw_req_valid;
  logic ptw_rsp_ready, ptw_rsp_valid;

  dreq_t soc_req_o;
  dresp_t soc_resp_i;

  dreq_t [NrTotalCores-1:0] in_payload_barrier;
  logic  [NrTotalCores-1:0] in_valid_barrier;
  logic  [NrTotalCores-1:0] in_ready_barrier;
  logic  [NrTotalCores-1:0] out_valid_barrier;
  logic  [NrTotalCores-1:0] out_ready_barrier;

  // need some local signals
  dreq_t  [NrTotalCores-1:0] req_payload_demux;
  logic   [NrTotalCores-1:0] req_valid_demux;
  logic   [NrTotalCores-1:0] req_ready_demux;
  dresp_t [NrTotalCores-1:0] resp_payload_demux;
  logic   [NrTotalCores-1:0] resp_valid_demux;
  logic   [NrTotalCores-1:0] resp_ready_demux;

  snitch_axi_pkg::req_slv_t  [NrSlaves-1:0] slave_req;
  snitch_axi_pkg::resp_slv_t [NrSlaves-1:0] slave_resp;

  snitch_axi_pkg::req_t  [NrMasters-1:0] master_req;
  snitch_axi_pkg::resp_t [NrMasters-1:0] master_resp;

  snitch_axi_pkg::req_t  axi_mst_cut_req;
  snitch_axi_pkg::resp_t axi_mst_cut_resp;

  // DMA AXI buses
  snitch_axi_pkg::req_dma_t      [NrDmaMasters-1:0] axi_dma_mst_req;
  snitch_axi_pkg::resp_dma_t     [NrDmaMasters-1:0] axi_dma_mst_res;
  snitch_axi_pkg::req_dma_slv_t  [NrDmaSlaves-1 :0] axi_dma_slv_req;
  snitch_axi_pkg::resp_dma_slv_t [NrDmaSlaves-1 :0] axi_dma_slv_res;

  // AXI-like read-only interface
  typedef struct packed {
      addr_t      addr;
      logic [7:0] len;
      logic       write;
  } refill_req_t;

  typedef struct packed {
      data_t data;
      logic  error;
  } refill_resp_t;

  logic  [NrBanks-1:0]                    mem_cs;
  logic  [NrBanks-1:0][TCDMAddrWidth-1:0] mem_add;
  logic  [NrBanks-1:0]                    mem_wen;
  data_t [NrBanks-1:0]                    mem_wdata;
  strb_t [NrBanks-1:0]                    mem_be;
  data_t [NrBanks-1:0]                    mem_rdata;

  logic  [NrBanks-1:0]                    mem_amo_req;
  logic  [NrBanks-1:0]                    mem_amo_gnt;
  logic  [NrBanks-1:0][TCDMAddrWidth-1:0] mem_amo_add;
  logic  [NrBanks-1:0]                    mem_amo_wen;
  tcdm_payload_t  [NrBanks-1:0]           mem_amo_wdata;
  strb_t [NrBanks-1:0]                    mem_amo_be;
  tcdm_payload_t  [NrBanks-1:0]           mem_amo_rdata;

  logic  [NrSuperBanks-1:0][BPSB-1:0]                    ic_req;
  logic  [NrSuperBanks-1:0][BPSB-1:0]                    ic_gnt;
  logic  [NrSuperBanks-1:0][BPSB-1:0][TCDMAddrWidth-1:0] ic_add;
  snitch_pkg::amo_op_t [NrSuperBanks-1:0][BPSB-1:0]     ic_amo;
  logic  [NrSuperBanks-1:0][BPSB-1:0]                    ic_wen;
  data_t [NrSuperBanks-1:0][BPSB-1:0]                    ic_wdata;
  strb_t [NrSuperBanks-1:0][BPSB-1:0]                    ic_be;
  data_t [NrSuperBanks-1:0][BPSB-1:0]                    ic_rdata;

  logic [NrSuperBanks-1:0]                     sb_dma_req;
  logic [NrSuperBanks-1:0]                     sb_dma_gnt;
  logic [NrSuperBanks-1:0][TCDMAddrWidth-1:0]  sb_dma_add;
  snitch_pkg::amo_op_t [NrSuperBanks-1:0]      sb_dma_amo;
  logic [NrSuperBanks-1:0]                     sb_dma_wen;
  logic [NrSuperBanks-1:0][DMADataWidth-1:0]   sb_dma_wdata;
  logic [NrSuperBanks-1:0][DMADataWidth/8-1:0] sb_dma_be;
  logic [NrSuperBanks-1:0][DMADataWidth-1:0]   sb_dma_rdata;

  logic                      ext_dma_req;
  logic                      ext_dma_gnt;
  logic [63:0]               ext_dma_add;
  snitch_pkg::amo_op_t      ext_dma_amo;
  logic                      ext_dma_wen;
  logic [DMADataWidth-1:0]   ext_dma_wdata;
  logic [DMADataWidth/8-1:0] ext_dma_be;
  logic [DMADataWidth-1:0]   ext_dma_rdata;

  logic  [NrSuperBanks-1:0][BPSB-1:0]                     amo_req;
  logic  [NrSuperBanks-1:0][BPSB-1:0]                     amo_gnt;
  logic  [NrSuperBanks-1:0][BPSB-1:0][TCDMAddrWidth-1:0]  amo_add;
  snitch_pkg::amo_op_t [NrSuperBanks-1:0][BPSB-1:0]       amo_amo;
  logic  [NrSuperBanks-1:0][BPSB-1:0]                     amo_wen;
  data_t [NrSuperBanks-1:0][BPSB-1:0]                     amo_wdata;
  strb_t [NrSuperBanks-1:0][BPSB-1:0]                     amo_be;
  data_t [NrSuperBanks-1:0][BPSB-1:0]                     amo_rdata;

  // logic [NrSuperBanks-1:0]                               sel_dma;
  logic [NrBanks-1:0]                                    amo_conflict;

  // AXI Ports into TCDM.
  logic [NrDMAPorts-1:0]          axi_req;
  logic [NrDMAPorts-1:0][31:0]    axi_add;
  logic [NrDMAPorts-1:0]          axi_wen;
  tcdm_payload_t [NrDMAPorts-1:0] axi_wdata;
  strb_t [NrDMAPorts-1:0]         axi_be;
  logic [NrDMAPorts-1:0]          axi_gnt;
  logic [NrDMAPorts-1:0]          axi_vld;
  tcdm_payload_t [NrDMAPorts-1:0] axi_rdata;

  // divide bus system into two parts -> one with all hives that do not
  // contain a plattform controller (frankensnitch) and one bus for the hive that can contain it.

  // bus for the normal hives
  logic [TotNrCores-1:0]               wake_up_sync;

  logic          [TotNrCores-1:0][2:0]  tcdm_req;
  addr_t         [TotNrCores-1:0][2:0]  tcdm_add;
  logic          [TotNrCores-1:0][2:0]  tcdm_wen;
  tcdm_payload_t [TotNrCores-1:0][2:0]  tcdm_wdata;
  strb_t         [TotNrCores-1:0][2:0]  tcdm_be;
  logic          [TotNrCores-1:0][2:0]  tcdm_gnt;
  logic          [TotNrCores-1:0][2:0]  tcdm_vld;
  tcdm_payload_t [TotNrCores-1:0][2:0]  tcdm_rdata;

  addr_t               [TotNrCores-1:0][2:0] snitch_data_qaddr;
  logic                [TotNrCores-1:0][2:0] snitch_data_qwrite;
  snitch_pkg::amo_op_t [TotNrCores-1:0][2:0] snitch_data_qamo;
  snitch_pkg::size_t   [TotNrCores-1:0][2:0] snitch_data_qsize;
  data_t               [TotNrCores-1:0][2:0] snitch_data_qdata;
  strb_t               [TotNrCores-1:0][2:0] snitch_data_qstrb;
  logic                [TotNrCores-1:0][2:0] snitch_data_qvalid;
  logic                [TotNrCores-1:0][2:0] snitch_data_qready;
  data_t               [TotNrCores-1:0][2:0] snitch_data_pdata;
  logic                [TotNrCores-1:0][2:0] snitch_data_perror;
  logic                [TotNrCores-1:0][2:0] snitch_data_pvalid;
  logic                [TotNrCores-1:0][2:0] snitch_data_pready;

  dreq_t  [TotNrCores-1:0] soc_data_q;
  logic   [TotNrCores-1:0] soc_data_qvalid, soc_data_qvalid_filtered;
  logic   [TotNrCores-1:0] soc_data_qready, soc_data_qready_filtered;
  dresp_t [TotNrCores-1:0] soc_data_p;
  logic   [TotNrCores-1:0] soc_data_pvalid;
  logic   [TotNrCores-1:0] soc_data_pready;

  refill_req_t  [NrHives-1:0] refill_q;
  logic         [NrHives-1:0] refill_qvalid;
  logic         [NrHives-1:0] refill_qready;

  refill_resp_t [NrHives-1:0] refill_p;
  logic         [NrHives-1:0] refill_pvalid;
  logic         [NrHives-1:0] refill_plast;
  logic         [NrHives-1:0] refill_pready;

  // Event counter increments for the TCDM.
  localparam int unsigned NrTCDMPortsCores = (NrHives * CoresPerHive) * 3;
  typedef struct packed {
    /// Number requests going in
    logic [$clog2(NrTCDMPortsCores):0] inc_accessed;
    /// Number of requests stalled due to congestion
    logic [$clog2(NrTCDMPortsCores):0] inc_congested;
  } tcdm_events_t;

  core_events_t [TotNrCores-1:0] core_events;
  tcdm_events_t                  tcdm_events;

  logic [snitch_axi_pkg::AddrWidth-1:0] ze_soc_req_o_add, ze_refill_req_o_addr, ze_ptw_req_o_addr;

  // Regbus peripherals.
  typedef logic [snitch_axi_pkg::AddrWidth-1:0] reg_addr_t;
  typedef logic [snitch_axi_pkg::DataWidth-1:0] reg_data_t;
  typedef logic [snitch_axi_pkg::DataWidth/8-1:0] reg_strb_t;

  `REG_BUS_TYPEDEF_REQ(reg_req_t, reg_addr_t, reg_data_t, reg_strb_t)
  `REG_BUS_TYPEDEF_RSP(reg_rsp_t, reg_data_t)

  reg_req_t reg_req;
  reg_rsp_t reg_rsp;

  // Optionally decouple the external wide AXI master port.
  axi_cut #(
    .Bypass    ( !RegisterExtWide                  ),
    .aw_chan_t ( snitch_axi_pkg::aw_chan_dma_slv_t ),
    .w_chan_t  ( snitch_axi_pkg::w_chan_dma_t      ),
    .b_chan_t  ( snitch_axi_pkg::b_chan_dma_slv_t  ),
    .ar_chan_t ( snitch_axi_pkg::ar_chan_dma_slv_t ),
    .r_chan_t  ( snitch_axi_pkg::r_chan_dma_slv_t  ),
    .req_t     ( snitch_axi_pkg::req_dma_slv_t     ),
    .resp_t    ( snitch_axi_pkg::resp_dma_slv_t    )
  ) i_cut_ext_wide_mst (
    .clk_i      ( clk_i                               ),
    .rst_ni     ( ~rst_i                              ),
    .slv_req_i  ( axi_dma_slv_req[SoCDMA] ),
    .slv_resp_o ( axi_dma_slv_res[SoCDMA] ),
    .mst_req_o  ( ext_dma_req_o                       ),
    .mst_resp_i ( ext_dma_resp_i                      )
  );

  // x-bar connection TCDM, SDMA, and SoC
  logic [DMA_XBAR_CFG.NoSlvPorts-1:0][$clog2(DMA_XBAR_CFG.NoMstPorts)-1:0] dma_xbar_default_port;
  axi_xbar #(
    .Cfg          ( DMA_XBAR_CFG                          ),
    .slv_aw_chan_t( snitch_axi_pkg::aw_chan_dma_t         ),
    .mst_aw_chan_t( snitch_axi_pkg::aw_chan_dma_slv_t     ),
    .w_chan_t     ( snitch_axi_pkg::w_chan_dma_t          ),
    .slv_b_chan_t ( snitch_axi_pkg::b_chan_dma_t          ),
    .mst_b_chan_t ( snitch_axi_pkg::b_chan_dma_slv_t      ),
    .slv_ar_chan_t( snitch_axi_pkg::ar_chan_dma_t         ),
    .mst_ar_chan_t( snitch_axi_pkg::ar_chan_dma_slv_t     ),
    .slv_r_chan_t ( snitch_axi_pkg::r_chan_dma_t          ),
    .mst_r_chan_t ( snitch_axi_pkg::r_chan_dma_slv_t      ),
    .slv_req_t    ( snitch_axi_pkg::req_dma_t             ),
    .slv_resp_t   ( snitch_axi_pkg::resp_dma_t            ),
    .mst_req_t    ( snitch_axi_pkg::req_dma_slv_t         ),
    .mst_resp_t   ( snitch_axi_pkg::resp_dma_slv_t        ),
    .rule_t       ( snitch_pkg::xbar_rule_t               )
  ) i_axi_dma_xbar (
    .clk_i                  ( clk_i                 ),
    .rst_ni                 ( ~rst_i                ),
    .test_i                 ( 1'b0                  ),
    .slv_ports_req_i        ( axi_dma_mst_req       ),
    .slv_ports_resp_o       ( axi_dma_mst_res       ),
    .mst_ports_req_o        ( axi_dma_slv_req       ),
    .mst_ports_resp_i       ( axi_dma_slv_res       ),
    .addr_map_i             ( DMA_XBAR_RULE         ),
    .en_default_mst_port_i  ( '1                    ),
    .default_mst_port_i     ( dma_xbar_default_port )
  );
  assign dma_xbar_default_port = '{default: SoCDMA};

  // connection to memory
  REQRSP_BUS #(
    .ADDR_WIDTH ( 64                         ),
    .DATA_WIDTH ( DMADataWidth               ),
    .ID_WIDTH   ( IdWidthDmaSlave )
  ) reqresp_dma_to_tcdm[NrDMAPorts-1:0](clk_i);

  AXI_BUS #(
    .AXI_ADDR_WIDTH ( snitch_axi_pkg::DMAAddrWidth ),
    .AXI_DATA_WIDTH ( snitch_axi_pkg::DMADataWidth ),
    .AXI_ID_WIDTH   ( IdWidthDmaSlave  ),
    .AXI_USER_WIDTH ( 1                            )
  ) dma_tcdm_slave ();

  `AXI_ASSIGN_FROM_REQ(dma_tcdm_slave, axi_dma_slv_req[TCDMDMA])
  `AXI_ASSIGN_TO_RESP(axi_dma_slv_res[TCDMDMA], dma_tcdm_slave)

  axi_to_reqrsp #(
    .IN_AW     ( snitch_axi_pkg::DMAAddrWidth    ),
    .IN_DW     ( snitch_axi_pkg::DMADataWidth    ),
    .IN_IW     ( IdWidthDmaSlave      ),
    .IN_UW     ( 1                         ),
    .OUT_AW    ( 64                        ),
    .OUT_DW    ( DMADataWidth              ),
    .NUM_PORTS ( 1                         )
  ) i_dma_axi_to_tcdm (
    .clk_i,
    .rst_ni   ( ~rst_i                     ),
    .axi_i    ( dma_tcdm_slave             ),
    .reqrsp_o ( reqresp_dma_to_tcdm        )
  );

  // the data returned by the memories is always valid N cycle later
  // this is usually handled by the TCDM interconnect correctly
  // we bypass TCDM ic here -> this delay needs to be explicitly
  // calculated.
  logic [MemoryMacroLatency-1:0] ext_dma_vld;
  always_ff @(posedge clk_i or posedge rst_i) begin : proc_delay_gnt_by_one
    if (rst_i) begin
      ext_dma_vld <= '0;
    end else begin
      ext_dma_vld[0] <= ext_dma_gnt & ext_dma_req;
      // variable delay
      if (MemoryMacroLatency > 1) begin
        for (int i = 1; i < MemoryMacroLatency; i++) begin
          ext_dma_vld[i] <= ext_dma_vld[i-1];
        end
      end
    end
  end

  reqrsp_to_tcdm #(
    .AW          ( 64                         ),
    .DW          ( DMADataWidth               ),
    .IW          ( IdWidthDmaSlave)
  ) i_ext_dma_reqrsp_to_tcdm (
    .clk_i,
    .rst_ni       ( ~rst_i                              ),
    .reqrsp_i     ( reqresp_dma_to_tcdm[0]              ),
    .tcdm_add     ( ext_dma_add                         ),
    .tcdm_wen     ( ext_dma_wen                         ),
    .tcdm_wdata   ( ext_dma_wdata                       ),
    .tcdm_be      ( ext_dma_be                          ),
    .tcdm_req     ( ext_dma_req                         ),
    .tcdm_gnt     ( ext_dma_gnt                         ),
    .tcdm_r_rdata ( ext_dma_rdata                       ),
    .tcdm_r_valid ( ext_dma_vld[MemoryMacroLatency-1]   )
  );
  assign ext_dma_amo = snitch_pkg::AMONone;

  // external dma transfer arbiter
  snitch_dma_addr_decoder #(
    .TCDMAddrWidth      ( TCDMAddrWidth          ),
    .DMAAddrWidth       ( 64                     ),
    .BanksPerSuperbank  ( BPSB                   ),
    .NrSuperBanks       ( NrSuperBanks           ),
    .DMADataWidth       ( DMADataWidth           ),
    .MemoryLatency      ( MemoryMacroLatency     )
  ) i_snitch_dma_addr_decoder (
    .clk_i              ( clk_i                 ),
    .rst_i              ( rst_i                 ),
    .dma_req_i          ( ext_dma_req           ),
    .dma_gnt_o          ( ext_dma_gnt           ),
    .dma_add_i          ( ext_dma_add           ),
    .dma_amo_i          ( ext_dma_amo           ),
    .dma_wen_i          ( ext_dma_wen           ),
    .dma_wdata_i        ( ext_dma_wdata         ),
    .dma_be_i           ( ext_dma_be            ),
    .dma_rdata_o        ( ext_dma_rdata         ),
    .super_bank_req_o   ( sb_dma_req            ),
    .super_bank_gnt_i   ( sb_dma_gnt            ),
    .super_bank_add_o   ( sb_dma_add            ),
    .super_bank_amo_o   ( sb_dma_amo            ),
    .super_bank_wen_o   ( sb_dma_wen            ),
    .super_bank_wdata_o ( sb_dma_wdata          ),
    .super_bank_be_o    ( sb_dma_be             ),
    .super_bank_rdata_i ( sb_dma_rdata          )
  );

  // generate tcdm
  for (genvar i = 0; i < NrSuperBanks; i++) begin : tcdm_super_bank
    // wide banks (default: 512bit)
    snitch_tcdm_mux #(
      .AddrMemWidth       ( TCDMAddrWidth     ),
      .BanksPerSuperbank  ( BPSB              ),
      .DataWidth          ( DLEN              ),
      .DMADataWidth       ( DMADataWidth      )
    ) i_snitch_tcdm_mux (
      .clk_i          ( clk_i                 ),
      .rst_i          ( rst_i                 ),
      .ic_req_i       ( ic_req        [i]     ),
      .ic_gnt_o       ( ic_gnt        [i]     ),
      .ic_add_i       ( ic_add        [i]     ),
      .ic_amo_i       ( ic_amo        [i]     ),
      .ic_wen_i       ( ic_wen        [i]     ),
      .ic_wdata_i     ( ic_wdata      [i]     ),
      .ic_be_i        ( ic_be         [i]     ),
      .ic_rdata_o     ( ic_rdata      [i]     ),
      .dma_req_i      ( sb_dma_req    [i]     ),
      .dma_gnt_o      ( sb_dma_gnt    [i]     ),
      .dma_add_i      ( sb_dma_add    [i]     ),
      .dma_amo_i      ( sb_dma_amo    [i]     ),
      .dma_wen_i      ( sb_dma_wen    [i]     ),
      .dma_wdata_i    ( sb_dma_wdata  [i]     ),
      .dma_be_i       ( sb_dma_be     [i]     ),
      .dma_rdata_o    ( sb_dma_rdata  [i]     ),
      .amo_req_o      ( amo_req       [i]     ),
      .amo_gnt_i      ( amo_gnt       [i]     ),
      .amo_add_o      ( amo_add       [i]     ),
      .amo_amo_o      ( amo_amo       [i]     ),
      .amo_wen_o      ( amo_wen       [i]     ),
      .amo_wdata_o    ( amo_wdata     [i]     ),
      .amo_be_o       ( amo_be        [i]     ),
      .amo_rdata_i    ( amo_rdata     [i]     ),
      .sel_dma_i      ( sb_dma_req    [i]     )
    );

    // generate banks of the superbank
    for (genvar j = 0; j < BPSB; j++) begin : tcdm_bank
      // verilog_lint: waive parameter-name-style
      localparam int unsigned k = i*BPSB + j;
      sram #(
        .DATA_WIDTH ( DLEN      ),
        .NUM_WORDS  ( TCDMDepth )
      ) i_data_mem (
        .clk_i   ( clk_i        ),
        .rst_ni  ( ~rst_i       ),
        .req_i   ( mem_cs[k]    ),
        .we_i    ( mem_wen[k]   ),
        .addr_i  ( mem_add[k]   ),
        .wdata_i ( mem_wdata[k] ),
        .be_i    ( mem_be[k]    ),
        .rdata_o ( mem_rdata[k] )
      );

      // assignments to connect the tcdm mux in front of the atomic
      // adapters
      assign ic_req        [i][j]    = mem_amo_req   [k];
      assign mem_amo_gnt   [k]       = ic_gnt        [i][j];
      assign ic_add        [i][j]    = mem_amo_add   [k];
      assign ic_wen        [i][j]    = mem_amo_wen   [k];
      assign ic_wdata      [i][j]    = mem_amo_wdata [k].data;
      assign ic_be         [i][j]    = mem_amo_be    [k];
      assign mem_amo_rdata [k].data  = ic_rdata      [i][j];
      assign ic_amo        [i][j]    = mem_amo_wdata [k].amo;

      data_t amo_rdata_local;

      // TODO(zarubaf): Share atomic units between mutltiple cuts
      snitch_amo_shim #(
        .AddrMemWidth   ( TCDMAddrWidth ),
        .DataWidth      ( DLEN          ),
        .CoreIDWidth    ( CoreIDWidth   )
      ) i_amo_shim (
        .clk_i,
        .rst_ni         ( ~rst_i                    ),
        .valid_i        ( amo_req       [i][j]      ),
        .ready_o        ( amo_gnt       [i][j]      ),
        .addr_i         ( amo_add       [i][j]      ),
        .write_i        ( amo_wen       [i][j]      ),
        .wdata_i        ( amo_wdata     [i][j]      ),
        .wstrb_i        ( amo_be        [i][j]      ),
        .core_id_i      ( mem_amo_wdata [k].core_id ),
        .is_core_i      ( mem_amo_wdata [k].is_core ),
        .rdata_o        ( amo_rdata_local           ),
        .amo_i          ( amo_amo       [i][j]      ),
        .mem_req_o      ( mem_cs        [k]         ),
        .mem_add_o      ( mem_add       [k]         ),
        .mem_wen_o      ( mem_wen       [k]         ),
        .mem_wdata_o    ( mem_wdata     [k]         ),
        .mem_be_o       ( mem_be        [k]         ),
        .mem_rdata_i    ( mem_rdata     [k]         ),
        .dma_access_i   ( sb_dma_req    [i]         ),
        .amo_conflict_o ( amo_conflict  [k]         )
      );
      // Insert a pipeline register at the output of each SRAM.
      if (RegisterTCDMCuts) begin: gen_tcdm_cut
        `FFNR(amo_rdata     [i][j][DLEN-1:0], amo_rdata_local, clk_i)
      end else begin : gen_no_tcdm_cut
        assign amo_rdata     [i][j][DLEN-1:0] = amo_rdata_local;
      end
      assign mem_amo_rdata[k].amo = AMONone;
    end
  end

  localparam int unsigned NumTCDMIn = 3*NrCores + NrDMAPorts;
  // we need some local signals
  logic  [NumTCDMIn-1:0]             tcdm_req_in;
  addr_t [NumTCDMIn-1:0]             tcdm_add_in;
  logic  [NumTCDMIn-1:0]             tcdm_wen_in;
  tcdm_payload_t  [NumTCDMIn-1:0]    tcdm_wdata_in;
  strb_t [NumTCDMIn-1:0]             tcdm_be_in;
  logic  [NumTCDMIn-1:0]             tcdm_gnt_in;
  logic  [NumTCDMIn-1:0]             tcdm_vld_in;
  tcdm_payload_t  [NumTCDMIn-1:0]    tcdm_rdata_in;

  assign tcdm_req_in   = {axi_req,   tcdm_req  };
  assign tcdm_add_in   = {axi_add,   tcdm_add  };
  assign tcdm_wen_in   = {axi_wen,   tcdm_wen  };
  assign tcdm_wdata_in = {axi_wdata, tcdm_wdata};
  assign tcdm_be_in    = {axi_be,    tcdm_be   };
  assign {axi_gnt,   tcdm_gnt  } = tcdm_gnt_in;
  assign {axi_vld,   tcdm_vld  } = tcdm_vld_in;
  assign {axi_rdata, tcdm_rdata} = tcdm_rdata_in;

  tcdm_interconnect #(
    .NumIn        ( NumTCDMIn                          ),
    .NumOut       ( NrBanks                            ),
    .AddrWidth    ( PLEN                               ),
    // Use additional 4 bits as atomic payload
    .DataWidth    ( $bits(tcdm_payload_t)              ),
    .BeWidth      ( $bits(strb_t)                      ),
    .AddrMemWidth ( TCDMAddrWidth                      ),
    .Topology     ( Topology                           ),
    .WriteRespOn  ( {{NrDMAPorts{1'b1}}, {{3*NrCores}{1'b0}}} ),
    .RespLat      ( 1 + RegisterTCDMCuts               ),
    .ByteOffWidth ( $clog2(DLEN-1)-3                   ),
    .NumPar       ( NumPar                             )
  ) i_tcdm_interconnect (
    .clk_i,
    .rst_ni  ( ~rst_i        ),
    .req_i   ( tcdm_req_in   ),
    .add_i   ( tcdm_add_in   ),
    .wen_i   ( tcdm_wen_in   ),
    .wdata_i ( tcdm_wdata_in ),
    .be_i    ( tcdm_be_in    ),
    .gnt_o   ( tcdm_gnt_in   ),
    .vld_o   ( tcdm_vld_in   ),
    .rdata_o ( tcdm_rdata_in ),

    .req_o   ( mem_amo_req   ),
    .gnt_i   ( mem_amo_gnt   ),
    .add_o   ( mem_amo_add   ),
    .wen_o   ( mem_amo_wen   ),
    .wdata_o ( mem_amo_wdata ),
    .be_o    ( mem_amo_be    ),
    .rdata_i ( mem_amo_rdata )
  );

  logic [NrTCDMPortsCores-1:0] flat_acc, flat_con;

  // TCDM event counters
  `FFSR(flat_acc, tcdm_req, '0, clk_i, rst_i)
  `FFSR(flat_con, tcdm_req & ~tcdm_gnt, '0, clk_i, rst_i)

  popcount #(
    .INPUT_WIDTH ( NrTCDMPortsCores )
  ) i_popcount_req (
    .data_i      ( flat_acc                  ),
    .popcount_o  ( tcdm_events.inc_accessed  )
  );

  popcount #(
    .INPUT_WIDTH ( NrTCDMPortsCores )
  ) i_popcount_con (
    .data_i      ( flat_con                  ),
    .popcount_o  ( tcdm_events.inc_congested )
  );

  logic clk_d2;

  if (IsoCrossing) begin : gen_clk_divider
    snitch_clkdiv2 i_snitch_clkdiv2 (
      .clk_i (clk_i),
      .test_mode_i (1'b0),
      .bypass_i ( clk_d2_bypass_i ),
      .clk_o (clk_d2)
    );
  end else begin : gen_no_clk_divider
    assign clk_d2 = clk_i;
  end

  for (genvar i = 0; i < NrHives; i++) begin : gen_snitch_hive
      // Compute the slice of cores that map to this hive.
      // verilog_lint: waive parameter-name-style
      localparam int unsigned idx_l = i * CoresPerHive;
      // verilog_lint: waive parameter-name-style
      localparam int unsigned idx_h =
              idx_l + (CoresPerHive > NrCores ? NrCores : idx_l + CoresPerHive);
      localparam int unsigned CurrentCoresPerHive = idx_h - idx_l;

      // Compute the feature bit masks for the cores in this hive.
      localparam bit [CurrentCoresPerHive-1:0] CurrentRVE  = RVE  >> idx_l;
      localparam bit [CurrentCoresPerHive-1:0] CurrentRVFD = RVFD >> idx_l;
      localparam bit [CurrentCoresPerHive-1:0] CurrentXdma = Xdma >> idx_l;
      localparam bit [CurrentCoresPerHive-1:0] CurrentXssr = Xssr >> idx_l;

      // Generate the TCDM ports for the cores in this hive.
      for (genvar j = 0; j < CurrentCoresPerHive; j++) begin : gen_hive_ports
        // verilog_lint: waive parameter-name-style
        localparam int unsigned idx = idx_l + j;

        for (genvar k = 0; k < 3; k++) begin : gen_ports
          addr_t       soc_qaddr_tmp;
          logic        soc_qwrite_tmp;
          snitch_pkg::amo_op_t soc_qamo_tmp;
          data_t       soc_qdata_tmp;
          strb_t       soc_qstrb_tmp;
          logic [1:0]  soc_qsize_tmp;
          logic        soc_qvalid_tmp;
          logic        soc_qready_tmp;
          data_t       soc_pdata_tmp;
          logic        soc_perror_tmp;
          logic        soc_pvalid_tmp;
          logic        soc_pready_tmp;

          tcdm_shim #(
            .AddrWidth ( PLEN  ),
            .DataWidth ( DLEN  ),
            .InclDemux ( (k == 0) )
          ) i_tcdm_shim (
            .clk_i                                         ,
            .rst_i                                         ,
            .tcdm_req_o    ( tcdm_req           [idx][k] ),
            .tcdm_add_o    ( tcdm_add           [idx][k] ),
            .tcdm_wen_o    ( tcdm_wen           [idx][k] ),
            .tcdm_wdata_o  ( tcdm_wdata[idx][k].data     ),
            .tcdm_amo_o    ( tcdm_wdata[idx][k].amo      ),
            .tcdm_be_o     ( tcdm_be            [idx][k] ),
            .tcdm_gnt_i    ( tcdm_gnt           [idx][k] ),
            .tcdm_vld_i    ( tcdm_vld           [idx][k] ),
            .tcdm_rdata_i  ( tcdm_rdata[idx][k].data     ),
            .soc_qaddr_o   ( soc_qaddr_tmp                ),
            .soc_qwrite_o  ( soc_qwrite_tmp               ),
            .soc_qamo_o    ( soc_qamo_tmp                 ),
            .soc_qdata_o   ( soc_qdata_tmp                ),
            .soc_qsize_o   ( soc_qsize_tmp                ),
            .soc_qstrb_o   ( soc_qstrb_tmp                ),
            .soc_qvalid_o  ( soc_qvalid_tmp               ),
            .soc_qready_i  ( soc_qready_tmp               ),
            .soc_pdata_i   ( soc_pdata_tmp                ),
            .soc_perror_i  ( soc_perror_tmp               ),
            .soc_pvalid_i  ( soc_pvalid_tmp               ),
            .soc_pready_o  ( soc_pready_tmp               ),
            .data_qaddr_i  ( snitch_data_qaddr  [idx][k] ),
            .data_qwrite_i ( snitch_data_qwrite [idx][k] ),
            .data_qamo_i   ( snitch_data_qamo   [idx][k] ),
            .data_qdata_i  ( snitch_data_qdata  [idx][k] ),
            .data_qsize_i  ( snitch_data_qsize  [idx][k] ),
            .data_qstrb_i  ( snitch_data_qstrb  [idx][k] ),
            .data_qvalid_i ( snitch_data_qvalid [idx][k] ),
            .data_qready_o ( snitch_data_qready [idx][k] ),
            .data_pdata_o  ( snitch_data_pdata  [idx][k] ),
            .data_perror_o ( snitch_data_perror [idx][k] ),
            .data_pvalid_o ( snitch_data_pvalid [idx][k] ),
            .data_pready_i ( snitch_data_pready [idx][k] )
          );
          assign tcdm_wdata[idx][k].core_id = idx;
          assign tcdm_wdata[idx][k].is_core = 1'b1;
          // Don't hook-up SSR ports
          if (k == 0) begin : gen_connect_soc
            assign soc_data_q[idx].addr = soc_qaddr_tmp;
            assign soc_data_q[idx].write = soc_qwrite_tmp;
            assign soc_data_q[idx].amo = soc_qamo_tmp;
            assign soc_data_q[idx].data = soc_qdata_tmp;
            assign soc_data_q[idx].size = soc_qsize_tmp;
            assign soc_data_q[idx].strb = soc_qstrb_tmp;
            assign soc_data_qvalid[idx] = soc_qvalid_tmp;
            assign soc_qready_tmp = soc_data_qready[idx];
            assign soc_pdata_tmp = soc_data_p[idx].data;
            assign soc_perror_tmp = soc_data_p[idx].error;
            assign soc_pvalid_tmp = soc_data_pvalid[idx];
            assign soc_data_pready[idx] = soc_pready_tmp;
          // that hopefully optimizes away the logic
          end else begin : gen_no_connect_soc
            assign soc_qready_tmp = '0;
            assign soc_pdata_tmp = '0;
            assign soc_perror_tmp = '0;
            assign soc_pvalid_tmp = '0;
          end
        end
      end

      snitch_axi_pkg::req_dma_t   axi_dma_req;
      snitch_axi_pkg::resp_dma_t  axi_dma_res;

      snitch_hive #(
        .CoreCount          ( CurrentCoresPerHive ),
        .BootAddr           ( BootAddr            ),
        .RVE                ( CurrentRVE          ),
        .RVFD               ( CurrentRVFD         ),
        .Xdma               ( CurrentXdma         ),
        .Xssr               ( CurrentXssr         ),
        .RegisterOffload    ( RegisterOffload     ),
        .RegisterOffloadRsp ( RegisterOffloadRsp  ),
        .RegisterTCDMReq    ( RegisterTCDMReq     ),
        .RegisterSequencer  ( RegisterSequencer   ),
        .ICacheLineWidth    ( ICacheLineWidth     ),
        .ICacheLineCount    ( ICacheLineCount     ),
        .ICacheSets         ( ICacheSets          ),
        .IsoCrossing        ( IsoCrossing         )
      ) i_snitch_hive (
        .clk_i                                                   ,
        .clk_d2_i          ( clk_d2                             ),
        .rst_i                                                   ,
        .hart_base_id_i    ( hart_base_id_i + idx_l             ),
        .debug_req_i       ( debug_req          [idx_h-1:idx_l] ),
        .meip_i            ( meip               [idx_h-1:idx_l] ),
        .mtip_i            ( mtip               [idx_h-1:idx_l] ),
        .msip_i            ( msip               [idx_h-1:idx_l] ),
        .data_qaddr_o      ( snitch_data_qaddr  [idx_h-1:idx_l] ),
        .data_qwrite_o     ( snitch_data_qwrite [idx_h-1:idx_l] ),
        .data_qamo_o       ( snitch_data_qamo   [idx_h-1:idx_l] ),
        .data_qdata_o      ( snitch_data_qdata  [idx_h-1:idx_l] ),
        .data_qsize_o      ( snitch_data_qsize  [idx_h-1:idx_l] ),
        .data_qstrb_o      ( snitch_data_qstrb  [idx_h-1:idx_l] ),
        .data_qvalid_o     ( snitch_data_qvalid [idx_h-1:idx_l] ),
        .data_qready_i     ( snitch_data_qready [idx_h-1:idx_l] ),
        .data_pdata_i      ( snitch_data_pdata  [idx_h-1:idx_l] ),
        .data_perror_i     ( snitch_data_perror [idx_h-1:idx_l] ),
        .data_pvalid_i     ( snitch_data_pvalid [idx_h-1:idx_l] ),
        .data_pready_o     ( snitch_data_pready [idx_h-1:idx_l] ),
        .wake_up_sync_i    ( wake_up_sync       [idx_h-1:idx_l] ),
        .ptw_data_qaddr_o  ( ptw_data_qaddr     [i]             ),
        .ptw_data_qvalid_o ( ptw_data_qvalid    [i]             ),
        .ptw_data_qready_i ( ptw_data_qready    [i]             ),
        .ptw_data_prsp_i   ( ptw_data_prsp      [i]             ),
        .ptw_data_pvalid_i ( ptw_data_pvalid    [i]             ),
        .ptw_data_pready_o ( ptw_data_pready    [i]             ),
        .refill_qaddr_o    ( refill_q[i].addr                   ),
        .refill_qlen_o     ( refill_q[i].len                    ),
        .refill_qvalid_o   ( refill_qvalid      [i]             ),
        .refill_qready_i   ( refill_qready      [i]             ),
        .refill_pdata_i    ( refill_p[i].data                   ),
        .refill_perror_i   ( refill_p[i].error                  ),
        .refill_pvalid_i   ( refill_pvalid      [i]             ),
        .refill_plast_i    ( refill_plast       [i]             ),
        .refill_pready_o   ( refill_pready      [i]             ),
        .axi_dma_req_o     ( axi_dma_req                        ),
        .axi_dma_res_i     ( axi_dma_res                        ),
        .axi_dma_busy_o    (                                    ),
        .core_events_o     ( core_events        [idx_h-1:idx_l] ),
        .axi_dma_perf_o    (                                    )
      );

      assign refill_q[i].write = 1'b0;

      if (|CurrentXdma) begin : gen_dma_connection
        assign axi_dma_mst_req[SDMAMst] = axi_dma_req;
        assign axi_dma_res = axi_dma_mst_res[SDMAMst];
      end
  end

  // Core request
  // zero extend addresses to `snitch_axi_pkg::AddrWidth` coming from each hive.
  always_comb begin
    ze_soc_req_o_add = '0;
    ze_refill_req_o_addr = '0;
    ze_ptw_req_o_addr = '0;
    ze_soc_req_o_add = soc_req_o.addr;
    ze_refill_req_o_addr = refill_req_o.addr;
    ze_ptw_req_o_addr = ptw_req.addr;
  end

  // --------
  // PTW Demux
  // --------
  // workaround as the `snitch_demux` expects a write member.
  for (genvar i = 0; i < NrHives; i++) begin : gen_tie_off_ptw
    assign ptw_data_req[i].addr = ptw_data_qaddr;
    assign ptw_data_req[i].write = 1'b0;
  end

  snitch_demux #(
    .NrPorts   ( NrHives             ),
    .req_t     ( ptw_req_t           ),
    .resp_t    ( dresp_t ),
    .RespDepth ( 2                   )
  ) i_snitch_demux_ptw (
    .clk_i,
    .rst_ni         ( ~rst_i          ),
    .req_payload_i  ( ptw_data_req    ),
    .req_valid_i    ( ptw_data_qvalid ),
    .req_ready_o    ( ptw_data_qready ),
    .resp_payload_o ( ptw_data_prsp   ),
    .resp_last_o    (                 ),
    .resp_valid_o   ( ptw_data_pvalid ),
    .resp_ready_i   ( ptw_data_pready ),
    .req_payload_o  ( ptw_req         ),
    .req_valid_o    ( ptw_req_valid   ),
    .req_ready_i    ( ptw_req_ready   ),
    .resp_payload_i ( ptw_rsp         ),
    .resp_last_i    ( 1'b1            ),
    .resp_valid_i   ( ptw_rsp_valid   ),
    .resp_ready_o   ( ptw_rsp_ready   )
  );

  // Instruction refill request
  snitch_axi_adapter #(
    .addr_t  ( snitch_axi_pkg::addr_t    ),
    .data_t  ( snitch_axi_pkg::data_t    ),
    .strb_t  ( snitch_axi_pkg::strb_t    ),
    .axi_mst_req_t  ( snitch_axi_pkg::req_t  ),
    .axi_mst_resp_t ( snitch_axi_pkg::resp_t )
  ) i_snitch_ptw_axi_adapter (
    .clk_i,
    .rst_ni       ( ~rst_i                       ),
    .slv_qaddr_i  ( ze_ptw_req_o_addr            ),
    .slv_qwrite_i ( '0                           ),
    .slv_qamo_i   ( '0                           ),
    .slv_qdata_i  ( '0                           ),
    .slv_qstrb_i  ( '0                           ),
    .slv_qsize_i  ( 2'b11                        ),
    .slv_qrlen_i  ( '0                           ),
    .slv_qvalid_i ( ptw_req_valid                ),
    .slv_qready_o ( ptw_req_ready                ),
    .slv_pdata_o  ( ptw_rsp.data                 ),
    .slv_perror_o ( ptw_rsp.error                ),
    .slv_plast_o  (                              ),
    .slv_pvalid_o ( ptw_rsp_valid                ),
    .slv_pready_i ( ptw_rsp_ready                ),
    .axi_req_o    ( master_req[PTW]  ),
    .axi_resp_i   ( master_resp[PTW] )
  );

  // --------
  // I$ Demux
  // --------
  refill_req_t refill_req_o;
  refill_resp_t refill_resp_i;

  snitch_demux #(
    .NrPorts ( NrHives       ),
    .req_t   ( refill_req_t  ),
    .resp_t  ( refill_resp_t )
  ) i_snitch_demux_refill (
    .clk_i,
    .rst_ni         ( ~rst_i          ),
    .req_payload_i  ( refill_q        ),
    .req_valid_i    ( refill_qvalid   ),
    .req_ready_o    ( refill_qready   ),
    .resp_payload_o ( refill_p        ),
    .resp_last_o    ( refill_plast    ),
    .resp_valid_o   ( refill_pvalid   ),
    .resp_ready_i   ( refill_pready   ),
    .req_payload_o  ( refill_req_o    ),
    .req_valid_o    ( refill_qvalid_o ),
    .req_ready_i    ( refill_qready_i ),
    .resp_payload_i ( refill_resp_i   ),
    .resp_last_i    ( refill_plast_i  ),
    .resp_valid_i   ( refill_pvalid_i ),
    .resp_ready_o   ( refill_pready_o )
  );

  assign in_payload_barrier       = soc_data_q;
  assign in_valid_barrier         = soc_data_qvalid;
  assign soc_data_qready          = in_ready_barrier;
  assign soc_data_qvalid_filtered = out_valid_barrier;
  assign out_ready_barrier        = soc_data_qready_filtered;

  snitch_barrier #(
    .NrPorts ( NrTotalCores        ),
    .req_t   ( dreq_t  )
  ) i_snitch_barrier (
    .clk_i,
    .rst_i,
    .in_payload_i ( in_payload_barrier   ),
    .in_valid_i   ( in_valid_barrier     ),
    .in_ready_o   ( in_ready_barrier     ),
    .out_valid_o  ( out_valid_barrier    ),
    .out_ready_i  ( out_ready_barrier    )
  );

  assign req_payload_demux        = soc_data_q;
  assign req_valid_demux          = soc_data_qvalid_filtered;
  assign soc_data_qready_filtered = req_ready_demux;
  assign soc_data_p               = resp_payload_demux;
  assign soc_data_pvalid          = resp_valid_demux;
  assign resp_ready_demux         = soc_data_pready;

  snitch_demux #(
    .NrPorts ( NrTotalCores ),
    .req_t   ( dreq_t       ),
    .resp_t  ( dresp_t      )
  ) i_snitch_demux_data (
    .clk_i,
    .rst_ni         ( ~rst_i               ),
    .req_payload_i  ( req_payload_demux    ),
    .req_valid_i    ( req_valid_demux      ),
    .req_ready_o    ( req_ready_demux      ),
    .resp_payload_o ( resp_payload_demux   ),
    .resp_last_o    (                      ),
    .resp_valid_o   ( resp_valid_demux     ),
    .resp_ready_i   ( resp_ready_demux     ),

    .req_payload_o  ( soc_req_o            ),
    .req_valid_o    ( soc_qvalid           ),
    .req_ready_i    ( soc_qready           ),
    .resp_payload_i ( soc_resp_i           ),
    .resp_last_i    ( 1'b1                 ),
    .resp_valid_i   ( soc_pvalid           ),
    .resp_ready_o   ( soc_pready           )
  );


  logic [CLUSTER_XBAR_CFG.NoSlvPorts-1:0][$clog2(CLUSTER_XBAR_CFG.NoMstPorts)-1:0]
    cluster_xbar_default_port;

  axi_xbar #(
    .Cfg           ( CLUSTER_XBAR_CFG              ),
    .slv_aw_chan_t ( snitch_axi_pkg::aw_chan_t     ),
    .mst_aw_chan_t ( snitch_axi_pkg::aw_chan_slv_t ),
    .w_chan_t      ( snitch_axi_pkg::w_chan_t      ),
    .slv_b_chan_t  ( snitch_axi_pkg::b_chan_t      ),
    .mst_b_chan_t  ( snitch_axi_pkg::b_chan_slv_t  ),
    .slv_ar_chan_t ( snitch_axi_pkg::ar_chan_t     ),
    .mst_ar_chan_t ( snitch_axi_pkg::ar_chan_slv_t ),
    .slv_r_chan_t  ( snitch_axi_pkg::r_chan_t      ),
    .mst_r_chan_t  ( snitch_axi_pkg::r_chan_slv_t  ),
    .slv_req_t     ( snitch_axi_pkg::req_t         ),
    .slv_resp_t    ( snitch_axi_pkg::resp_t        ),
    .mst_req_t     ( snitch_axi_pkg::req_slv_t     ),
    .mst_resp_t    ( snitch_axi_pkg::resp_slv_t    ),
    .rule_t        ( snitch_pkg::xbar_rule_t       )
  ) i_cluster_xbar (
    .clk_i,
    .rst_ni                ( ~rst_i                    ),
    .test_i                ( 1'b0                      ),
    .slv_ports_req_i       ( master_req                ),
    .slv_ports_resp_o      ( master_resp               ),
    .mst_ports_req_o       ( slave_req                 ),
    .mst_ports_resp_i      ( slave_resp                ),
    .addr_map_i            ( CLUSTER_XBAR_RULES        ),
    .en_default_mst_port_i ( '1                        ),
    .default_mst_port_i    ( cluster_xbar_default_port )
  );
  assign cluster_xbar_default_port = '{default: SoC};

  // Optionally decouple the external narrow AXI slave port.
  axi_cut #(
    .Bypass    ( !RegisterExtNarrow        ),
    .aw_chan_t ( snitch_axi_pkg::aw_chan_t ),
    .w_chan_t  ( snitch_axi_pkg::w_chan_t  ),
    .b_chan_t  ( snitch_axi_pkg::b_chan_t  ),
    .ar_chan_t ( snitch_axi_pkg::ar_chan_t ),
    .r_chan_t  ( snitch_axi_pkg::r_chan_t  ),
    .req_t     ( snitch_axi_pkg::req_t     ),
    .resp_t    ( snitch_axi_pkg::resp_t    )
  ) i_cut_ext_narrow_slv (
    .clk_i      ( clk_i               ),
    .rst_ni     ( ~rst_i              ),
    .slv_req_i  ( axi_mst_cut_req     ),
    .slv_resp_o ( axi_mst_cut_resp    ),
    .mst_req_o  ( master_req[AXISoC]  ),
    .mst_resp_i ( master_resp[AXISoC] )
  );

  // Masters
  // Truncate address bits.
  always_comb begin
    axi_mst_cut_req = axi_slv_req_i;
    axi_mst_cut_req.aw.atop = '0;
    axi_mst_cut_req.aw.addr = '0;
    axi_mst_cut_req.ar.addr = '0;
    axi_mst_cut_req.aw.addr = TCDMStartAddress + axi_slv_req_i.aw.addr[SoCRequestAddrBits-1:0];
    axi_mst_cut_req.ar.addr = TCDMStartAddress + axi_slv_req_i.ar.addr[SoCRequestAddrBits-1:0];
    axi_slv_res_o = axi_mst_cut_resp;
  end

  snitch_axi_adapter #(
    .addr_t  ( snitch_axi_pkg::addr_t    ),
    .data_t  ( snitch_axi_pkg::data_t    ),
    .strb_t  ( snitch_axi_pkg::strb_t    ),
    .axi_mst_req_t  ( snitch_axi_pkg::req_t     ),
    .axi_mst_resp_t ( snitch_axi_pkg::resp_t    )
  ) i_snitch_core_axi_adapter (
    .clk_i,
    .rst_ni       ( ~rst_i            ),
    // zero extend to 64 bit
    .slv_qaddr_i  ( ze_soc_req_o_add  ),
    .slv_qwrite_i ( soc_req_o.write   ),
    .slv_qamo_i   ( soc_req_o.amo     ),
    .slv_qdata_i  ( soc_req_o.data    ),
    .slv_qstrb_i  ( soc_req_o.strb    ),
    .slv_qsize_i  ( soc_req_o.size    ),
    .slv_qrlen_i  ( '0                ),
    .slv_qvalid_i ( soc_qvalid        ),
    .slv_qready_o ( soc_qready        ),
    .slv_pdata_o  ( soc_resp_i.data   ),
    .slv_perror_o ( soc_resp_i.error  ),
    .slv_plast_o  (                   ),
    .slv_pvalid_o ( soc_pvalid        ),
    .slv_pready_i ( soc_pready        ),
    .axi_req_o    ( master_req[CoreReq]  ),
    .axi_resp_i   ( master_resp[CoreReq] )
  );

  // Instruction refill request
  snitch_axi_adapter #(
    .addr_t  ( snitch_axi_pkg::addr_t    ),
    .data_t  ( snitch_axi_pkg::data_t    ),
    .strb_t  ( snitch_axi_pkg::strb_t    ),
    .axi_mst_req_t  ( snitch_axi_pkg::req_t     ),
    .axi_mst_resp_t ( snitch_axi_pkg::resp_t    )
  ) i_snitch_refill_axi_adapter (
    .clk_i,
    .rst_ni       ( ~rst_i              ),
    .slv_qaddr_i  ( ze_refill_req_o_addr),
    .slv_qwrite_i ( '0                  ),
    .slv_qamo_i   ( '0                  ),
    .slv_qdata_i  ( '0                  ),
    .slv_qstrb_i  ( '0                  ),
    .slv_qsize_i  ( DATA_ALIGN[1:0]     ),
    .slv_qrlen_i  ( refill_req_o.len    ),
    .slv_qvalid_i ( refill_qvalid_o     ),
    .slv_qready_o ( refill_qready_i     ),
    .slv_pdata_o  ( refill_resp_i.data  ),
    .slv_perror_o ( refill_resp_i.error ),
    .slv_plast_o  ( refill_plast_i      ),
    .slv_pvalid_o ( refill_pvalid_i     ),
    .slv_pready_i ( refill_pready_o     ),
    .axi_req_o    ( master_req[ICache]  ),
    .axi_resp_i   ( master_resp[ICache] )
  );

  // ---------
  // Slaves
  // ---------
  // 1. TCDM
  // Add an adapter that allows access from AXI to the TCDM. The adapter
  // translates to a request/response interface, which needs to be further
  // adapted to the TCDM, which does not support response stalls.
  REQRSP_BUS #(
    .ADDR_WIDTH ( snitch_axi_pkg::AddrWidth ),
    .DATA_WIDTH ( snitch_axi_pkg::DataWidth ),
    .ID_WIDTH   ( IdWidthSlave )
  ) axi_to_tcdm[NrDMAPorts-1:0](clk_i);

  // TODO: Remove interface
  AXI_BUS #(
    .AXI_ADDR_WIDTH ( snitch_axi_pkg::AddrWidth ),
    .AXI_DATA_WIDTH ( snitch_axi_pkg::DataWidth ),
    .AXI_ID_WIDTH   ( IdWidthSlave  ),
    .AXI_USER_WIDTH ( snitch_axi_pkg::UserWidth )
  ) tcdm_slave ();

  `AXI_ASSIGN_FROM_REQ(tcdm_slave, slave_req[TCDM])
  `AXI_ASSIGN_TO_RESP(slave_resp[TCDM], tcdm_slave)

  axi_to_reqrsp #(
    .IN_AW     ( snitch_axi_pkg::AddrWidth ),
    .IN_DW     ( snitch_axi_pkg::DataWidth ),
    .IN_IW     ( IdWidthSlave  ),
    .IN_UW     ( snitch_axi_pkg::UserWidth ),
    .OUT_AW    ( snitch_axi_pkg::AddrWidth ),
    .OUT_DW    ( snitch_axi_pkg::DataWidth ),
    .NUM_PORTS ( NrDMAPorts                )
  ) i_axi_to_tcdm (
    .clk_i,
    .rst_ni   ( ~rst_i      ),
    .axi_i    ( tcdm_slave  ),
    .reqrsp_o ( axi_to_tcdm )
  );

  for (genvar i = 0; i < NrDMAPorts; i++) begin : gen_axi_to_tcdm_adapter
    logic [PLEN-1:0] axi_add_local;
    reqrsp_to_tcdm #(
      .AW          ( snitch_axi_pkg::AddrWidth ),
      .DW          ( snitch_axi_pkg::DataWidth ),
      .IW          ( IdWidthSlave )
    ) i_reqrsp_to_tcdm (
      .clk_i,
      .rst_ni       ( ~rst_i                 ),
      .reqrsp_i     ( axi_to_tcdm[i]         ),
      .tcdm_add     ( axi_add_local          ),
      .tcdm_wen     ( axi_wen[i]             ),
      .tcdm_wdata   ( axi_wdata[i].data      ),
      .tcdm_be      ( axi_be[i]              ),
      .tcdm_req     ( axi_req[i]             ),
      .tcdm_gnt     ( axi_gnt[i]             ),
      .tcdm_r_rdata ( axi_rdata[i].data      ),
      .tcdm_r_valid ( axi_vld[i]             )
    );
    assign axi_wdata[i].amo = snitch_pkg::AMONone;
    assign axi_wdata[i].core_id = '0;
    assign axi_wdata[i].is_core = '0;
    // truncate to physical length
    assign axi_add[i] = axi_add_local[PLEN-1:0];
  end

  // 2. Peripherals
  axi_to_reg #(
    .ADDR_WIDTH ( snitch_axi_pkg::AddrWidth  ),
    .DATA_WIDTH ( snitch_axi_pkg::DataWidth  ),
    .DECOUPLE_W ( 1                          ),
    .ID_WIDTH   ( IdWidthSlave   ),
    .USER_WIDTH ( snitch_axi_pkg::UserWidth  ),
    .axi_req_t  ( snitch_axi_pkg::req_slv_t  ),
    .axi_rsp_t  ( snitch_axi_pkg::resp_slv_t ),
    .reg_req_t  ( reg_req_t                  ),
    .reg_rsp_t  ( reg_rsp_t                  )
  ) i_axi_to_reg (
    .clk_i          ( clk_i                          ),
    .rst_ni         ( ~rst_i                         ),
    .testmode_i     ( 1'b0                           ),
    .axi_lite_req_i ( slave_req[ClusterPeripherals]  ),
    .axi_lite_rsp_o ( slave_resp[ClusterPeripherals] ),
    .reg_req_o      ( reg_req                        ),
    .reg_rsp_i      ( reg_rsp                        )
  );

  // local signals
  logic [NrTotalCores-1:0] wake_up_cluster;
  core_events_t [NrTotalCores-1:0] core_events_cluster;

  assign wake_up_sync = wake_up_cluster;
  assign core_events_cluster = core_events;

  snitch_cluster_peripheral #(
    .TCDMStartAddress ( TCDMStartAddress                            ),
    .TCDMEndAddress   (
        TCDMStartAddress + TCDMDepth * NrBanks * snitch_pkg::DLEN/8 ),
    .tcdm_events_t    ( tcdm_events_t                               ),
    .NrCores          ( NrTotalCores                                )
  ) i_snitch_cluster_peripheral (
    .clk_i,
    .rst_i,
    .addr_i               ( reg_req.addr         ),
    .wdata_i              ( reg_req.wdata        ),
    .wstrb_i              ( reg_req.wstrb        ),
    .write_i              ( reg_req.write        ),
    .valid_i              ( reg_req.valid        ),
    .rdata_o              ( reg_rsp.rdata        ),
    .error_o              ( reg_rsp.error        ),
    .ready_o              ( reg_rsp.ready        ),
    .wake_up_o            ( wake_up_cluster      ),
    .cluster_hart_base_id_i ( hart_base_id_i       ),
    .core_events_i        ( core_events_cluster  ),
    .tcdm_events_i        ( tcdm_events          )
  );

  // Optionally decouple the external narrow AXI master ports.
  axi_cut #(
    .Bypass    ( !RegisterExtNarrow            ),
    .aw_chan_t ( snitch_axi_pkg::aw_chan_slv_t ),
    .w_chan_t  ( snitch_axi_pkg::w_chan_t      ),
    .b_chan_t  ( snitch_axi_pkg::b_chan_slv_t  ),
    .ar_chan_t ( snitch_axi_pkg::ar_chan_slv_t ),
    .r_chan_t  ( snitch_axi_pkg::r_chan_slv_t  ),
    .req_t     ( snitch_axi_pkg::req_slv_t     ),
    .resp_t    ( snitch_axi_pkg::resp_slv_t    )
  ) i_cut_ext_narrow_mst (
    .clk_i      ( clk_i                       ),
    .rst_ni     ( ~rst_i                      ),
    .slv_req_i  ( slave_req[SoC]  ),
    .slv_resp_o ( slave_resp[SoC] ),
    .mst_req_o  ( axi_mst_req_o               ),
    .mst_resp_i ( axi_mst_res_i               )
  );
endmodule


module snitch_barrier import snitch_pkg::*; #(
  parameter int NrPorts = 0,
  parameter type req_t = logic
) (
  input  logic clk_i,
  input  logic rst_i,
  input  req_t [NrPorts-1:0] in_payload_i,
  input  logic [NrPorts-1:0] in_valid_i,
  output logic [NrPorts-1:0] in_ready_o,
  output logic [NrPorts-1:0] out_valid_o,
  input  logic [NrPorts-1:0] out_ready_i
);

  typedef enum logic [1:0] {
    Idle,
    Wait,
    Take
  } barrier_state_e;
  barrier_state_e [NrPorts-1:0] state_d, state_q;
  logic [NrPorts-1:0] is_barrier;
  logic take_barrier;

  assign take_barrier = &is_barrier;

  always_comb begin
    state_d     = state_q;
    is_barrier  = '0;
    out_valid_o = in_valid_i;
    in_ready_o  = out_ready_i;

    for (int i = 0; i < NrPorts; i++) begin
      case (state_q[i])
        Idle: begin
          if (in_valid_i[i] &&
            (in_payload_i[i].addr == ClusterPeriphStartAddress + BarrierReg)) begin
            state_d[i] = Wait;
            out_valid_o[i] = 0;
            in_ready_o[i]  = 0;
          end
        end
        Wait: begin
          is_barrier[i]  = 1;
          out_valid_o[i] = 0;
          in_ready_o[i]  = 0;
          if (take_barrier) state_d[i] = Take;
        end
        Take: begin
          if (out_valid_o[i] && in_ready_o[i]) state_d[i] = Idle;
        end
        default: state_d[i] = Idle;
      endcase
    end
  end

  for (genvar i = 0; i < NrPorts; i++) begin : gen_ff
    `FFSR(state_q[i], state_d[i], Idle, clk_i, rst_i)
  end

endmodule
