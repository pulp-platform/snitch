// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>
// Author: Fabian Schuiki <fschuiki@iis.ee.ethz.ch>
// Author: Thomas Benz <tbenz@iis.ee.ethz.ch>

`include "axi/assign.svh"
`include "axi/typedef.svh"
`include "common_cells/assertions.svh"
`include "common_cells/registers.svh"

`include "mem_interface/typedef.svh"
`include "register_interface/typedef.svh"
`include "reqrsp_interface/typedef.svh"
`include "tcdm_interface/typedef.svh"

`include "snitch_vm/typedef.svh"

/// Snitch many-core cluster with improved TCDM interconnect.
/// Snitch Cluster Top-Level.
module snitch_cluster
  import snitch_pkg::*;
#(
  /// Width of physical address.
  parameter int unsigned PhysicalAddrWidth  = 48,
  /// Width of regular data bus.
  parameter int unsigned NarrowDataWidth    = 64,
  /// Width of wide AXI port.
  parameter int unsigned WideDataWidth      = 512,
  /// AXI: id width in.
  parameter int unsigned NarrowIdWidthIn    = 2,
  /// AXI: dma id with in *currently not available*
  parameter int unsigned WideIdWidthIn      = 2,
  /// AXI: user width.
  parameter int unsigned UserWidth          = 1,
  /// Address from which to fetch the first instructions.
  parameter logic [31:0] BootAddr           = 32'h0,
  /// Number of Hives. Each Hive can hold 1-many cores.
  parameter int unsigned NrHives            = 1,
  /// The total (not per Hive) amount of cores.
  parameter int unsigned NrCores            = 8,
  /// Data/TCDM memory depth per cut (in words).
  parameter int unsigned TCDMDepth          = 1024,
  /// Number of TCDM Banks. It is recommended to have twice the number of banks
  /// as cores. If SSRs are enabled, we recommend 4 times the the number of
  /// banks.
  parameter int unsigned NrBanks            = NrCores,
  /// Size of DMA AXI buffer.
  parameter int unsigned DMAAxiReqFifoDepth = 3,
  /// Size of DMA request fifo.
  parameter int unsigned DMAReqFifoDepth    = 3,
  /// Width of a single icache line.
  parameter int unsigned ICacheLineWidth [NrHives] = '{default: 0},
  /// Number of icache lines per set.
  parameter int unsigned ICacheLineCount [NrHives] = '{default: 0},
  /// Number of icache sets.
  parameter int unsigned ICacheSets [NrHives]      = '{default: 0},
  /// Per-core enabling of the standard `E` ISA reduced-register extension.
  parameter bit [NrCores-1:0] RVE           = '0,
  /// Per-core enabling of the standard `F` ISA extensions.
  parameter bit [NrCores-1:0] RVF           = '0,
  /// Per-core enabling of the standard `D` ISA extensions.
  parameter bit [NrCores-1:0] RVD           = '0,
  // Small-float extensions
  /// FP 16-bit
  parameter bit [NrCores-1:0] XF16          = '0,
  /// FP 16 alt a.k.a. brain-float
  parameter bit [NrCores-1:0] XF16ALT       = '0,
  /// FP 8-bit
  parameter bit [NrCores-1:0] XF8           = '0,
  /// Enable SIMD support.
  parameter bit [NrCores-1:0] XFVEC         = '0,
  /// Per-core enabling of the custom `Xdma` ISA extensions.
  parameter bit [NrCores-1:0] Xdma          = '0,
  /// Per-core enabling of the custom `Xssr` ISA extensions.
  parameter bit [NrCores-1:0] Xssr          = '0,
  /// Per-core enabling of the custom `Xfrep` ISA extensions.
  parameter bit [NrCores-1:0] Xfrep         = '0,
  /// # Core-global parameters
  /// FPU configuration.
  parameter fpnew_pkg::fpu_implementation_t FPUImplementation = '0,
  /// Physical Memory Attribute Configuration
  parameter snitch_pma_pkg::snitch_pma_t SnitchPMACfg = '0,
  /// # Per-core parameters
  /// Per-core integer outstanding loads
  parameter int unsigned NumIntOutstandingLoads [NrCores] = '{default: 0},
  /// Per-core integer outstanding memory operations (load and stores)
  parameter int unsigned NumIntOutstandingMem [NrCores] = '{default: 0},
  /// Per-core floating-point outstanding loads
  parameter int unsigned NumFPOutstandingLoads [NrCores] = '{default: 0},
  /// Per-core floating-point outstanding memory operations (load and stores)
  parameter int unsigned NumFPOutstandingMem [NrCores] = '{default: 0},
  /// Per-core number of data TLB entries.
  parameter int unsigned NumDTLBEntries [NrCores] = '{default: 0},
  /// Per-core number of instruction TLB entries.
  parameter int unsigned NumITLBEntries [NrCores] = '{default: 0},
  /// Maximum number of SSRs per core.
  parameter int unsigned NumSsrsMax = 0,
  /// Per-core number of SSRs.
  parameter int unsigned NumSsrs [NrCores] = '{default: 0},
  /// Per-core depth of TCDM Mux unifying SSR 0 and Snitch requests.
  parameter int unsigned SsrMuxRespDepth [NrCores] = '{default: 0},
  /// Per-core internal parameters for each SSR.
  parameter snitch_ssr_pkg::ssr_cfg_t [NumSsrsMax-1:0] SsrCfgs [NrCores] = '{default: '0},
  /// Per-core register indices for each SSR.
  parameter logic [NumSsrsMax-1:0][4:0]  SsrRegs [NrCores] = '{default: 0},
  /// Per-core amount of sequencer instructions for IPU and FPU if enabled.
  parameter int unsigned NumSequencerInstr [NrCores] = '{default: 0},
  /// Parent Hive id, a.k.a a mapping which core is assigned to which Hive.
  parameter int unsigned Hive [NrCores] = '{default: 0},
  /// TCDM Configuration.
  parameter topo_e       Topology           = LogarithmicInterconnect,
  /// Radix of the individual switch points of the network.
  /// Currently supported are `32'd2` and `32'd4`.
  parameter int unsigned Radix              = 32'd2,
  /// ## Timing Tuning Parameters
  /// Insert Pipeline registers into off-loading path (request)
  parameter bit          RegisterOffloadReq = 1'b0,
  /// Insert Pipeline registers into off-loading path (response)
  parameter bit          RegisterOffloadRsp = 1'b0,
  /// Insert Pipeline registers into data memory path (request)
  parameter bit          RegisterCoreReq    = 1'b0,
  /// Insert Pipeline registers into data memory path (response)
  parameter bit          RegisterCoreRsp    = 1'b0,
  /// Insert Pipeline registers after each memory cut
  parameter bit          RegisterTCDMCuts   = 1'b0,
  /// Decouple wide external AXI plug
  parameter bit          RegisterExtWide    = 1'b0,
  /// Decouple narrow external AXI plug
  parameter bit          RegisterExtNarrow  = 1'b0,
  /// Insert Pipeline register into the FPU data path (request)
  parameter bit          RegisterFPUReq     = 1'b0,
  /// Insert Pipeline registers after sequencer
  parameter bit          RegisterSequencer  = 1'b0,
  /// Run Snitch (the integer part) at half of the clock frequency
  parameter bit          IsoCrossing        = 0,
  parameter axi_pkg::xbar_latency_e NarrowXbarLatency = axi_pkg::CUT_ALL_PORTS,
  parameter axi_pkg::xbar_latency_e WideXbarLatency = axi_pkg::CUT_ALL_PORTS,
  /// # Interface
  /// AXI Ports
  parameter type         narrow_in_req_t   = logic,
  parameter type         narrow_in_resp_t  = logic,
  parameter type         narrow_out_req_t  = logic,
  parameter type         narrow_out_resp_t = logic,
  parameter type         wide_out_req_t    = logic,
  parameter type         wide_out_resp_t   = logic,
  parameter type         wide_in_req_t     = logic,
  parameter type         wide_in_resp_t    = logic,
  // Memory latency parameter. Most of the memories have a read latency of 1. In
  // case you have memory macros which are pipelined you want to adjust this
  // value here. This only applies to the TCDM. The instruction cache macros will break!
  // In case you are using the `RegisterTCDMCuts` feature this adds an
  // additional cycle latency, which is taken into account here.
  parameter int unsigned MemoryMacroLatency = 1 + RegisterTCDMCuts
) (
  /// System clock. If `IsoCrossing` is enabled this port is the _fast_ clock.
  /// The slower, half-frequency clock, is derived internally.
  input  logic                          clk_i,
  /// Asynchronous active high reset. This signal is assumed to be _async_.
  input  logic                          rst_ni,
  /// Per-core debug request signal. Asserting this signals puts the
  /// corresponding core into debug mode. This signal is assumed to be _async_.
  input  logic [NrCores-1:0]            debug_req_i,
  /// Machine external interrupt pending. Usually those interrupts come from a
  /// platform-level interrupt controller. This signal is assumed to be _async_.
  input  logic [NrCores-1:0]            meip_i,
  /// Machine timer interrupt pending. Usually those interrupts come from a
  /// core-local interrupt controller such as a timer/RTC. This signal is
  /// assumed to be _async_.
  input  logic [NrCores-1:0]            mtip_i,
  /// Core software interrupt pending. Usually those interrupts come from
  /// another core to facilitate inter-processor-interrupts. This signal is
  /// assumed to be _async_.
  input  logic [NrCores-1:0]            msip_i,
  /// First hartid of the cluster. Cores of a cluster are monotonically
  /// increasing without a gap, i.e., a cluster with 8 cores and a
  /// `hart_base_id_i` of 5 get the hartids 5 - 12.
  input  logic [9:0]                    hart_base_id_i,
  /// Base address of cluster. TCDM and cluster peripheral location are derived from
  /// it. This signal is pseudo-static.
  input  logic [PhysicalAddrWidth-1:0]  cluster_base_addr_i,
  /// Bypass half-frequency clock. (`d2` = divide-by-two). This signal is
  /// pseudo-static.
  input  logic                          clk_d2_bypass_i,
  /// AXI Core cluster in-port.
  input  narrow_in_req_t                narrow_in_req_i,
  output narrow_in_resp_t               narrow_in_resp_o,
  /// AXI Core cluster out-port.
  output narrow_out_req_t               narrow_out_req_o,
  input  narrow_out_resp_t              narrow_out_resp_i,
  /// AXI DMA cluster out-port. Usually wider than the cluster ports so that the
  /// DMA engine can efficiently transfer bulk of data.
  output wide_out_req_t                 wide_out_req_o,
  input  wide_out_resp_t                wide_out_resp_i,
  /// AXI DMA cluster in-port.
  input  wide_in_req_t                  wide_in_req_i,
  output wide_in_resp_t                 wide_in_resp_o
);
  // ---------
  // Constants
  // ---------
  /// Minimum width to hold the core number.
  localparam int unsigned CoreIDWidth = cf_math_pkg::idx_width(NrCores);
  localparam int unsigned TCDMAddrWidth = $clog2(TCDMDepth);
  localparam int unsigned TCDMSize = NrBanks * TCDMDepth * (NarrowDataWidth/8);
  localparam int unsigned BanksPerSuperBank = WideDataWidth / NarrowDataWidth;
  localparam int unsigned NrSuperBanks = NrBanks / BanksPerSuperBank;

  function automatic int unsigned get_tcdm_ports(int unsigned core);
    return (NumSsrs[core] > 1 ? NumSsrs[core] : 1);
  endfunction

  function automatic int unsigned get_tcdm_port_offs(int unsigned core_idx);
    automatic int n = 0;
    for (int i = 0; i < core_idx; i++) n += get_tcdm_ports(i);
    return n;
  endfunction

  localparam int unsigned NrTCDMPortsCores = get_tcdm_port_offs(NrCores);
  localparam int unsigned NumTCDMIn = NrTCDMPortsCores + 1;
  localparam logic [PhysicalAddrWidth-1:0] TCDMMask = ~(TCDMSize-1);

  // Core Requests, SoC Request, PTW, `n` instruction caches.
  localparam int unsigned NrMasters = 3 + NrHives;
  localparam int unsigned IdWidthOut = $clog2(NrMasters) + NarrowIdWidthIn;

  localparam int unsigned NrSlaves = 3;
  localparam int unsigned NrRules = NrSlaves - 1;

  localparam int unsigned NrDmaMasters = 2;
  localparam int unsigned IdWidthDMAOut = $clog2(NrDmaMasters) + WideIdWidthIn;
  // DMA X-BAR configuration
  localparam int unsigned NrDmaSlaves = 2;

  // AXI Configuration
  localparam axi_pkg::xbar_cfg_t ClusterXbarCfg = '{
    NoSlvPorts: NrMasters,
    NoMstPorts: NrSlaves,
    MaxMstTrans: 4,
    MaxSlvTrans: 4,
    FallThrough: 1'b0,
    LatencyMode: NarrowXbarLatency,
    AxiIdWidthSlvPorts: NarrowIdWidthIn,
    AxiIdUsedSlvPorts: NarrowIdWidthIn,
    AxiAddrWidth: PhysicalAddrWidth,
    AxiDataWidth: NarrowDataWidth,
    NoAddrRules: NrRules
  };

  // DMA configuration struct
  localparam axi_pkg::xbar_cfg_t DmaXbarCfg = '{
    NoSlvPorts: NrDmaMasters,
    NoMstPorts: NrDmaSlaves,
    MaxMstTrans: 4,
    MaxSlvTrans: 4,
    FallThrough: 1'b0,
    LatencyMode: WideXbarLatency,
    AxiIdWidthSlvPorts: WideIdWidthIn,
    AxiIdUsedSlvPorts: WideIdWidthIn,
    AxiAddrWidth: PhysicalAddrWidth,
    AxiDataWidth: WideDataWidth,
    NoAddrRules: 1
  };

  function automatic int unsigned get_hive_size(int unsigned current_hive);
    automatic int n = 0;
    for (int i = 0; i < NrCores; i++) if (Hive[i] == current_hive) n++;
    return n;
  endfunction

  function automatic int unsigned get_core_position(int unsigned hive_id, int unsigned core_id);
    automatic int n = 0;
    for (int i = 0; i < NrCores; i++) begin
      if (core_id == i) break;
      if (Hive[i] == hive_id) n++;
    end
    return n;
  endfunction

  // --------
  // Typedefs
  // --------
  typedef logic [PhysicalAddrWidth-1:0] addr_t;
  typedef logic [NarrowDataWidth-1:0]   data_t;
  typedef logic [NarrowDataWidth/8-1:0] strb_t;
  typedef logic [WideDataWidth-1:0]     data_dma_t;
  typedef logic [WideDataWidth/8-1:0]   strb_dma_t;
  typedef logic [NarrowIdWidthIn-1:0]   id_mst_t;
  typedef logic [IdWidthOut-1:0]        id_slv_t;
  typedef logic [WideIdWidthIn-1:0]     id_dma_mst_t;
  typedef logic [IdWidthDMAOut-1:0]     id_dma_slv_t;
  typedef logic [UserWidth-1:0]         user_t;

  typedef logic [TCDMAddrWidth-1:0]     tcdm_addr_t;

  typedef struct packed {
    logic [CoreIDWidth-1:0] core_id;
    bit                     is_core;
  } tcdm_user_t;

  // Regbus peripherals.
  `AXI_TYPEDEF_ALL(axi_mst, addr_t, id_mst_t, data_t, strb_t, user_t)
  `AXI_TYPEDEF_ALL(axi_slv, addr_t, id_slv_t, data_t, strb_t, user_t)
  `AXI_TYPEDEF_ALL(axi_mst_dma, addr_t, id_dma_mst_t, data_dma_t, strb_dma_t, user_t)
  `AXI_TYPEDEF_ALL(axi_slv_dma, addr_t, id_dma_slv_t, data_dma_t, strb_dma_t, user_t)

  `REQRSP_TYPEDEF_ALL(reqrsp, addr_t, data_t, strb_t)

  `MEM_TYPEDEF_ALL(mem, tcdm_addr_t, data_t, strb_t, tcdm_user_t)
  `MEM_TYPEDEF_ALL(mem_dma, tcdm_addr_t, data_dma_t, strb_dma_t, logic)

  `TCDM_TYPEDEF_ALL(tcdm, addr_t, data_t, strb_t, tcdm_user_t)
  `TCDM_TYPEDEF_ALL(tcdm_dma, addr_t, data_dma_t, strb_dma_t, logic)

  `REG_BUS_TYPEDEF_REQ(reg_req_t, addr_t, data_t, strb_t)
  `REG_BUS_TYPEDEF_RSP(reg_rsp_t, data_t)

  // Event counter increments for the TCDM.
  typedef struct packed {
    /// Number requests going in
    logic [$clog2(NrTCDMPortsCores):0] inc_accessed;
    /// Number of requests stalled due to congestion
    logic [$clog2(NrTCDMPortsCores):0] inc_congested;
  } tcdm_events_t;

  typedef struct packed {
    int unsigned idx;
    addr_t start_addr;
    addr_t end_addr;
  } xbar_rule_t;

  typedef struct packed {
    acc_addr_e   addr;
    logic [4:0]  id;
    logic [31:0] data_op;
    data_t       data_arga;
    data_t       data_argb;
    addr_t       data_argc;
  } acc_req_t;

    typedef struct packed {
    logic [4:0] id;
    logic       error;
    data_t      data;
  } acc_resp_t;

  `SNITCH_VM_TYPEDEF(PhysicalAddrWidth)

  typedef struct packed {
    // Slow domain.
    logic       flush_i_valid;
    addr_t      inst_addr;
    logic       inst_cacheable;
    logic       inst_valid;
    // Fast domain.
    acc_req_t   acc_req;
    logic       acc_qvalid;
    logic       acc_pready;
    // Slow domain.
    logic [1:0] ptw_valid;
    va_t [1:0]  ptw_va;
    pa_t [1:0]  ptw_ppn;
  } hive_req_t;

  typedef struct packed {
    // Slow domain.
    logic          flush_i_ready;
    logic [31:0]   inst_data;
    logic          inst_ready;
    logic          inst_error;
    // Fast domain.
    logic          acc_qready;
    acc_resp_t     acc_resp;
    logic          acc_pvalid;
    // Slow domain.
    logic [1:0]    ptw_ready;
    l0_pte_t [1:0] ptw_pte;
    logic [1:0]    ptw_is_4mega;
  } hive_rsp_t;

  // -----------
  // Assignments
  // -----------
  // Calculate start and end address of TCDM based on the `cluster_base_addr_i`.
  addr_t tcdm_start_address, tcdm_end_address;
  assign tcdm_start_address = cluster_base_addr_i;
  assign tcdm_end_address = cluster_base_addr_i + TCDMSize;

  // ----------------
  // Wire Definitions
  // ----------------
  // 1. AXI
  axi_slv_req_t  [NrSlaves-1:0] slave_req;
  axi_slv_resp_t [NrSlaves-1:0] slave_resp;

  axi_mst_req_t  [NrMasters-1:0] master_req;
  axi_mst_resp_t [NrMasters-1:0] master_resp;

  // DMA AXI buses
  axi_mst_dma_req_t  [NrDmaMasters-1:0] axi_dma_mst_req;
  axi_mst_dma_resp_t [NrDmaMasters-1:0] axi_dma_mst_res;
  axi_slv_dma_req_t  [NrDmaSlaves-1 :0] axi_dma_slv_req;
  axi_slv_dma_resp_t [NrDmaSlaves-1 :0] axi_dma_slv_res;

  // 2. Memory Subsystem (Banks)
  mem_req_t [NrSuperBanks-1:0][BanksPerSuperBank-1:0] ic_req;
  mem_rsp_t [NrSuperBanks-1:0][BanksPerSuperBank-1:0] ic_rsp;

  mem_dma_req_t [NrSuperBanks-1:0] sb_dma_req;
  mem_dma_rsp_t [NrSuperBanks-1:0] sb_dma_rsp;

  // 3. Memory Subsystem (Interconnect)
  tcdm_dma_req_t ext_dma_req;
  tcdm_dma_rsp_t ext_dma_rsp;

  // AXI Ports into TCDM (from SoC).
  tcdm_req_t axi_soc_req;
  tcdm_rsp_t axi_soc_rsp;

  tcdm_req_t [NrTCDMPortsCores-1:0] tcdm_req;
  tcdm_rsp_t [NrTCDMPortsCores-1:0] tcdm_rsp;

  core_events_t [NrCores-1:0] core_events;
  tcdm_events_t               tcdm_events;

  // 4. Memory Subsystem (Core side).
  reqrsp_req_t [NrCores-1:0] core_req, filtered_core_req;
  reqrsp_rsp_t [NrCores-1:0] core_rsp, filtered_core_rsp;
  reqrsp_req_t [NrHives-1:0] ptw_req;
  reqrsp_rsp_t [NrHives-1:0] ptw_rsp;

  // 5. Peripheral Subsystem
  reg_req_t reg_req;
  reg_rsp_t reg_rsp;

  // 5. Misc. Wires.
  logic [NrCores-1:0] wake_up_sync;

  // -------------
  // DMA Subsystem
  // -------------
  // Optionally decouple the external wide AXI master port.
  axi_cut #(
    .Bypass (!RegisterExtWide),
    .aw_chan_t (axi_slv_dma_aw_chan_t),
    .w_chan_t (axi_slv_dma_w_chan_t),
    .b_chan_t (axi_slv_dma_b_chan_t),
    .ar_chan_t (axi_slv_dma_ar_chan_t),
    .r_chan_t (axi_slv_dma_r_chan_t),
    .req_t (axi_slv_dma_req_t),
    .resp_t (axi_slv_dma_resp_t)
  ) i_cut_ext_wide_out (
    .clk_i (clk_i),
    .rst_ni (rst_ni),
    .slv_req_i (axi_dma_slv_req[SoCDMAOut]),
    .slv_resp_o (axi_dma_slv_res[SoCDMAOut]),
    .mst_req_o (wide_out_req_o),
    .mst_resp_i (wide_out_resp_i)
  );

  axi_cut #(
    .Bypass (!RegisterExtWide),
    .aw_chan_t (axi_mst_dma_aw_chan_t),
    .w_chan_t (axi_mst_dma_w_chan_t),
    .b_chan_t (axi_mst_dma_b_chan_t),
    .ar_chan_t (axi_mst_dma_ar_chan_t),
    .r_chan_t (axi_mst_dma_r_chan_t),
    .req_t (axi_mst_dma_req_t),
    .resp_t (axi_mst_dma_resp_t)
  ) i_cut_ext_wide_in (
    .clk_i (clk_i),
    .rst_ni (rst_ni),
    .slv_req_i (wide_in_req_i),
    .slv_resp_o (wide_in_resp_o),
    .mst_req_o (axi_dma_mst_req[SoCDMAIn]),
    .mst_resp_i (axi_dma_mst_res[SoCDMAIn])
  );

  logic [DmaXbarCfg.NoSlvPorts-1:0][$clog2(DmaXbarCfg.NoMstPorts)-1:0] dma_xbar_default_port;
  xbar_rule_t [DmaXbarCfg.NoAddrRules-1:0] dma_xbar_rule;

  assign dma_xbar_default_port = '{default: SoCDMAOut};
  assign dma_xbar_rule = '{
    '{
      idx:        TCDMDMA,
      start_addr: tcdm_start_address,
      end_addr:   tcdm_end_address
    }
  };
  localparam bit [DmaXbarCfg.NoSlvPorts-1:0] DMAEnableDefaultMstPort = '1;
  axi_xbar #(
    .Cfg (DmaXbarCfg),
    .slv_aw_chan_t (axi_mst_dma_aw_chan_t),
    .mst_aw_chan_t (axi_slv_dma_aw_chan_t),
    .w_chan_t (axi_mst_dma_w_chan_t),
    .slv_b_chan_t (axi_mst_dma_b_chan_t),
    .mst_b_chan_t (axi_slv_dma_b_chan_t),
    .slv_ar_chan_t (axi_mst_dma_ar_chan_t),
    .mst_ar_chan_t (axi_slv_dma_ar_chan_t),
    .slv_r_chan_t (axi_mst_dma_r_chan_t),
    .mst_r_chan_t (axi_slv_dma_r_chan_t),
    .slv_req_t (axi_mst_dma_req_t),
    .slv_resp_t (axi_mst_dma_resp_t),
    .mst_req_t (axi_slv_dma_req_t),
    .mst_resp_t (axi_slv_dma_resp_t),
    .rule_t (xbar_rule_t)
  ) i_axi_dma_xbar (
    .clk_i (clk_i),
    .rst_ni (rst_ni),
    .test_i (1'b0),
    .slv_ports_req_i (axi_dma_mst_req),
    .slv_ports_resp_o (axi_dma_mst_res),
    .mst_ports_req_o (axi_dma_slv_req),
    .mst_ports_resp_i (axi_dma_slv_res),
    .addr_map_i (dma_xbar_rule),
    .en_default_mst_port_i (DMAEnableDefaultMstPort),
    .default_mst_port_i (dma_xbar_default_port)
  );

  axi_to_mem #(
    .axi_req_t (axi_slv_dma_req_t),
    .axi_resp_t (axi_slv_dma_resp_t),
    .AddrWidth (PhysicalAddrWidth),
    .DataWidth (WideDataWidth),
    .IdWidth (IdWidthDMAOut),
    .NumBanks (1),
    .BufDepth (MemoryMacroLatency + 1)
  ) i_axi_to_mem_dma (
    .clk_i,
    .rst_ni,
    .busy_o (),
    .axi_req_i (axi_dma_slv_req[TCDMDMA]),
    .axi_resp_o (axi_dma_slv_res[TCDMDMA]),
    .mem_req_o (ext_dma_req.q_valid),
    .mem_gnt_i (ext_dma_rsp.q_ready),
    .mem_addr_o (ext_dma_req.q.addr),
    .mem_wdata_o (ext_dma_req.q.data),
    .mem_strb_o (ext_dma_req.q.strb),
    .mem_atop_o (/* The DMA does not support atomics */),
    .mem_we_o (ext_dma_req.q.write),
    .mem_rvalid_i (ext_dma_rsp.p_valid),
    .mem_rdata_i (ext_dma_rsp.p.data)
  );

  assign ext_dma_req.q.amo = reqrsp_pkg::AMONone;
  assign ext_dma_req.q.user = '0;

  snitch_tcdm_interconnect #(
    .NumInp (1),
    .NumOut (NrSuperBanks),
    .tcdm_req_t (tcdm_dma_req_t),
    .tcdm_rsp_t (tcdm_dma_rsp_t),
    .mem_req_t (mem_dma_req_t),
    .mem_rsp_t (mem_dma_rsp_t),
    .user_t (logic),
    .MemAddrWidth (TCDMAddrWidth),
    .DataWidth (WideDataWidth),
    .MemoryResponseLatency (MemoryMacroLatency)
  ) i_dma_interconnect (
    .clk_i,
    .rst_ni,
    .req_i (ext_dma_req),
    .rsp_o (ext_dma_rsp),
    .mem_req_o (sb_dma_req),
    .mem_rsp_i (sb_dma_rsp)
  );

  // ----------------
  // Memory Subsystem
  // ----------------
  for (genvar i = 0; i < NrSuperBanks; i++) begin : gen_tcdm_super_bank

    mem_req_t [BanksPerSuperBank-1:0] amo_req;
    mem_rsp_t [BanksPerSuperBank-1:0] amo_rsp;

    mem_wide_narrow_mux #(
      .NarrowDataWidth (NarrowDataWidth),
      .WideDataWidth (WideDataWidth),
      .mem_narrow_req_t (mem_req_t),
      .mem_narrow_rsp_t (mem_rsp_t),
      .mem_wide_req_t (mem_dma_req_t),
      .mem_wide_rsp_t (mem_dma_rsp_t)
    ) i_tcdm_mux (
      .clk_i,
      .rst_ni,
      .in_narrow_req_i (ic_req [i]),
      .in_narrow_rsp_o (ic_rsp [i]),
      .in_wide_req_i (sb_dma_req [i]),
      .in_wide_rsp_o (sb_dma_rsp [i]),
      .out_req_o (amo_req),
      .out_rsp_i (amo_rsp),
      .sel_wide_i (sb_dma_req[i].q_valid)
    );

    // generate banks of the superbank
    for (genvar j = 0; j < BanksPerSuperBank; j++) begin : gen_tcdm_bank

      logic mem_cs, mem_wen;
      logic [TCDMAddrWidth-1:0] mem_add;
      strb_t mem_be;
      data_t mem_rdata, mem_wdata;

      tc_sram #(
        .NumWords (TCDMDepth),
        .DataWidth (NarrowDataWidth),
        .ByteWidth (8),
        .NumPorts (1),
        .Latency (1)
      ) i_data_mem (
        .clk_i,
        .rst_ni,
        .req_i (mem_cs),
        .we_i (mem_wen),
        .addr_i (mem_add),
        .wdata_i (mem_wdata),
        .be_i (mem_be),
        .rdata_o (mem_rdata)
      );

      data_t amo_rdata_local;

      // TODO(zarubaf): Share atomic units between mutltiple cuts
      snitch_amo_shim #(
        .AddrMemWidth ( TCDMAddrWidth ),
        .DataWidth ( NarrowDataWidth ),
        .CoreIDWidth ( CoreIDWidth )
      ) i_amo_shim (
        .clk_i,
        .rst_ni ( rst_ni ),
        .valid_i ( amo_req[j].q_valid ),
        .ready_o ( amo_rsp[j].q_ready ),
        .addr_i ( amo_req[j].q.addr ),
        .write_i ( amo_req[j].q.write ),
        .wdata_i ( amo_req[j].q.data ),
        .wstrb_i ( amo_req[j].q.strb ),
        .core_id_i ( amo_req[j].q.user.core_id ),
        .is_core_i ( amo_req[j].q.user.is_core ),
        .rdata_o ( amo_rdata_local ),
        .amo_i ( amo_req[j].q.amo ),
        .mem_req_o ( mem_cs ),
        .mem_add_o ( mem_add ),
        .mem_wen_o ( mem_wen ),
        .mem_wdata_o ( mem_wdata ),
        .mem_be_o ( mem_be ),
        .mem_rdata_i ( mem_rdata ),
        .dma_access_i ( sb_dma_req[i].q_valid ),
        // TODO(zarubaf): Signal AMO conflict somewhere. Socregs?
        .amo_conflict_o (  )
      );

      // Insert a pipeline register at the output of each SRAM.
      shift_reg #( .dtype (data_t), .Depth (RegisterTCDMCuts)) i_sram_pipe (
        .clk_i, .rst_ni,
        .d_i (amo_rdata_local), .d_o (amo_rsp[j].p.data)
      );
    end
  end

  snitch_tcdm_interconnect #(
    .NumInp (NumTCDMIn),
    .NumOut (NrBanks),
    .tcdm_req_t (tcdm_req_t),
    .tcdm_rsp_t (tcdm_rsp_t),
    .mem_req_t (mem_req_t),
    .mem_rsp_t (mem_rsp_t),
    .MemAddrWidth (TCDMAddrWidth),
    .DataWidth (NarrowDataWidth),
    .user_t (tcdm_user_t),
    .MemoryResponseLatency (1 + RegisterTCDMCuts),
    .Radix (Radix),
    .Topology (Topology)
  ) i_tcdm_interconnect (
    .clk_i,
    .rst_ni,
    .req_i ({axi_soc_req, tcdm_req}),
    .rsp_o ({axi_soc_rsp, tcdm_rsp}),
    .mem_req_o (ic_req),
    .mem_rsp_i (ic_rsp)
  );

  logic clk_d2;

  if (IsoCrossing) begin : gen_clk_divider
    snitch_clkdiv2 i_snitch_clkdiv2 (
      .clk_i,
      .test_mode_i (1'b0),
      .bypass_i ( clk_d2_bypass_i ),
      .clk_o (clk_d2)
    );
  end else begin : gen_no_clk_divider
    assign clk_d2 = clk_i;
  end

  hive_req_t [NrCores-1:0] hive_req;
  hive_rsp_t [NrCores-1:0] hive_rsp;

  for (genvar i = 0; i < NrCores; i++) begin : gen_core
    localparam int unsigned TcdmPorts = get_tcdm_ports(i);
    localparam int unsigned TcdmPortsOffs = get_tcdm_port_offs(i);

    axi_mst_dma_req_t   axi_dma_req;
    axi_mst_dma_resp_t  axi_dma_res;
    interrupts_t irq;

    sync #(.STAGES (2))
      i_sync_debug (.clk_i, .rst_ni, .serial_i (debug_req_i[i]), .serial_o (irq.debug));
    sync #(.STAGES (2))
      i_sync_meip  (.clk_i, .rst_ni, .serial_i (meip_i[i]), .serial_o (irq.meip));
    sync #(.STAGES (2))
      i_sync_mtip  (.clk_i, .rst_ni, .serial_i (mtip_i[i]), .serial_o (irq.mtip));
    sync #(.STAGES (2))
      i_sync_msip  (.clk_i, .rst_ni, .serial_i (msip_i[i]), .serial_o (irq.msip));

      tcdm_req_t [TcdmPorts-1:0] tcdm_req_wo_user;

      snitch_cc #(
        .AddrWidth (PhysicalAddrWidth),
        .DataWidth (NarrowDataWidth),
        .DMADataWidth (WideDataWidth),
        .DMAIdWidth (WideIdWidthIn),
        .SnitchPMACfg (SnitchPMACfg),
        .DMAAxiReqFifoDepth (DMAAxiReqFifoDepth),
        .DMAReqFifoDepth (DMAReqFifoDepth),
        .dreq_t (reqrsp_req_t),
        .drsp_t (reqrsp_rsp_t),
        .tcdm_req_t (tcdm_req_t),
        .tcdm_rsp_t (tcdm_rsp_t),
        .tcdm_user_t (tcdm_user_t),
        .axi_req_t (axi_mst_dma_req_t),
        .axi_rsp_t (axi_mst_dma_resp_t),
        .hive_req_t (hive_req_t),
        .hive_rsp_t (hive_rsp_t),
        .acc_req_t (acc_req_t),
        .acc_resp_t (acc_resp_t),
        .BootAddr (BootAddr),
        .RVE (RVE[i]),
        .RVF (RVF[i]),
        .RVD (RVD[i]),
        .XF16 (XF16[i]),
        .XF16ALT (XF16ALT[i]),
        .XF8 (XF8[i]),
        .XFVEC (XFVEC[i]),
        .Xdma (Xdma[i]),
        .IsoCrossing (IsoCrossing),
        .Xfrep (Xfrep[i]),
        .Xssr (Xssr[i]),
        .Xipu (1'b0),
        .NumIntOutstandingLoads (NumIntOutstandingLoads[i]),
        .NumIntOutstandingMem (NumIntOutstandingMem[i]),
        .NumFPOutstandingLoads (NumFPOutstandingLoads[i]),
        .NumFPOutstandingMem (NumFPOutstandingMem[i]),
        .FPUImplementation (FPUImplementation),
        .NumDTLBEntries (NumDTLBEntries[i]),
        .NumITLBEntries (NumITLBEntries[i]),
        .NumSequencerInstr (NumSequencerInstr[i]),
        .NumSsrs (NumSsrs[i]),
        .SsrMuxRespDepth (SsrMuxRespDepth[i]),
        .SsrCfgs (SsrCfgs[i][NumSsrs[i]-1:0]),
        .SsrRegs (SsrRegs[i][NumSsrs[i]-1:0]),
        .RegisterOffloadReq (RegisterOffloadReq),
        .RegisterOffloadRsp (RegisterOffloadRsp),
        .RegisterCoreReq (RegisterCoreReq),
        .RegisterCoreRsp (RegisterCoreRsp),
        .RegisterFPUReq (RegisterFPUReq),
        .RegisterSequencer (RegisterSequencer)
      ) i_snitch_cc (
        .clk_i,
        .clk_d2_i (clk_d2),
        .rst_ni,
        .rst_int_ss_ni (1'b1),
        .rst_fp_ss_ni (1'b1),
        .hart_id_i (hart_base_id_i + i),
        .hive_req_o (hive_req[i]),
        .hive_rsp_i (hive_rsp[i]),
        .irq_i (irq),
        .data_req_o (core_req[i]),
        .data_rsp_i (core_rsp[i]),
        .tcdm_req_o (tcdm_req_wo_user),
        .tcdm_rsp_i (tcdm_rsp[TcdmPortsOffs+:TcdmPorts]),
        .wake_up_sync_i (wake_up_sync[i]),
        .axi_dma_req_o (axi_dma_req),
        .axi_dma_res_i (axi_dma_res),
        .axi_dma_busy_o (),
        .axi_dma_perf_o (),
        .core_events_o (core_events[i]),
        .tcdm_addr_base_i (tcdm_start_address),
        .tcdm_addr_mask_i (TCDMMask)
      );
      for (genvar j = 0; j < TcdmPorts; j++) begin : gen_tcdm_user
        always_comb begin
          tcdm_req[TcdmPortsOffs+j] = tcdm_req_wo_user[j];
          tcdm_req[TcdmPortsOffs+j].q.user.core_id = i;
          tcdm_req[TcdmPortsOffs+j].q.user.is_core = 1;
        end
      end
      if (Xdma[i]) begin : gen_dma_connection
        assign axi_dma_mst_req[SDMAMst] = axi_dma_req;
        assign axi_dma_res = axi_dma_mst_res[SDMAMst];
      end
  end

  for (genvar i = 0; i < NrHives; i++) begin : gen_hive
      localparam int unsigned HiveSize = get_hive_size(i);

      hive_req_t [HiveSize-1:0] hive_req_reshape;
      hive_rsp_t [HiveSize-1:0] hive_rsp_reshape;

      for (genvar j = 0; j < NrCores; j++) begin : gen_hive_matrix
        // Check whether the core actually belongs to the current hive.
        if (Hive[j] == i) begin : gen_hive_connection
          localparam int unsigned HivePosition = get_core_position(i, j);
          assign hive_req_reshape[HivePosition] = hive_req[j];
          assign hive_rsp[j] = hive_rsp_reshape[HivePosition];
        end
      end

      snitch_hive #(
        .AddrWidth (PhysicalAddrWidth),
        .DataWidth (NarrowDataWidth),
        .dreq_t (reqrsp_req_t),
        .drsp_t (reqrsp_rsp_t),
        .hive_req_t (hive_req_t),
        .hive_rsp_t (hive_rsp_t),
        .CoreCount (HiveSize),
        .ICacheLineWidth (ICacheLineWidth[i]),
        .ICacheLineCount (ICacheLineCount[i]),
        .ICacheSets (ICacheSets[i]),
        .IsoCrossing (IsoCrossing),
        .axi_req_t (axi_mst_req_t),
        .axi_rsp_t (axi_mst_resp_t)
      ) i_snitch_hive (
        .clk_i,
        .clk_d2_i (clk_d2),
        .rst_ni,
        .hive_req_i (hive_req_reshape),
        .hive_rsp_o (hive_rsp_reshape),
        .ptw_data_req_o (ptw_req[i]),
        .ptw_data_rsp_i (ptw_rsp[i]),
        .axi_req_o (master_req[ICache+i]),
        .axi_rsp_i (master_resp[ICache+i])
      );
  end

  // --------
  // PTW Demux
  // --------
  reqrsp_req_t ptw_to_axi_req;
  reqrsp_rsp_t ptw_to_axi_rsp;

  reqrsp_mux #(
    .NrPorts (NrHives),
    .AddrWidth (PhysicalAddrWidth),
    .DataWidth (NarrowDataWidth),
    .req_t (reqrsp_req_t),
    .rsp_t (reqrsp_rsp_t),
    .RespDepth (2)
  ) i_reqrsp_mux_ptw (
    .clk_i,
    .rst_ni,
    .slv_req_i (ptw_req),
    .slv_rsp_o (ptw_rsp),
    .mst_req_o (ptw_to_axi_req),
    .mst_rsp_i (ptw_to_axi_rsp)
  );

  reqrsp_to_axi #(
    .DataWidth (NarrowDataWidth),
    .reqrsp_req_t (reqrsp_req_t),
    .reqrsp_rsp_t (reqrsp_rsp_t),
    .axi_req_t (axi_mst_req_t),
    .axi_rsp_t (axi_mst_resp_t)
  ) i_reqrsp_to_axi_ptw (
    .clk_i,
    .rst_ni,
    .reqrsp_req_i (ptw_to_axi_req),
    .reqrsp_rsp_o (ptw_to_axi_rsp),
    .axi_req_o (master_req[PTW]),
    .axi_rsp_i (master_resp[PTW])
  );

  // --------
  // Coes SoC
  // --------
  snitch_barrier #(
    .AddrWidth (PhysicalAddrWidth),
    .NrPorts (NrCores),
    .dreq_t  (reqrsp_req_t),
    .drsp_t  (reqrsp_rsp_t)
  ) i_snitch_barrier (
    .clk_i,
    .rst_ni,
    .in_req_i (core_req),
    .in_rsp_o (core_rsp),
    .out_req_o (filtered_core_req),
    .out_rsp_i (filtered_core_rsp),
    .cluster_periph_start_address_i (tcdm_end_address)
  );

  reqrsp_req_t core_to_axi_req;
  reqrsp_rsp_t core_to_axi_rsp;

  reqrsp_mux #(
    .NrPorts (NrCores),
    .AddrWidth (PhysicalAddrWidth),
    .DataWidth (NarrowDataWidth),
    .req_t (reqrsp_req_t),
    .rsp_t (reqrsp_rsp_t),
    .RespDepth (2)
  ) i_reqrsp_mux_core (
    .clk_i,
    .rst_ni,
    .slv_req_i (filtered_core_req),
    .slv_rsp_o (filtered_core_rsp),
    .mst_req_o (core_to_axi_req),
    .mst_rsp_i (core_to_axi_rsp)
  );

  reqrsp_to_axi #(
    .DataWidth (NarrowDataWidth),
    .reqrsp_req_t (reqrsp_req_t),
    .reqrsp_rsp_t (reqrsp_rsp_t),
    .axi_req_t (axi_mst_req_t),
    .axi_rsp_t (axi_mst_resp_t)
  ) i_reqrsp_to_axi_core (
    .clk_i,
    .rst_ni,
    .reqrsp_req_i (core_to_axi_req),
    .reqrsp_rsp_o (core_to_axi_rsp),
    .axi_req_o (master_req[CoreReq]),
    .axi_rsp_i (master_resp[CoreReq])
  );

  logic [ClusterXbarCfg.NoSlvPorts-1:0][$clog2(ClusterXbarCfg.NoMstPorts)-1:0]
    cluster_xbar_default_port;
  xbar_rule_t [NrRules-1:0] cluster_xbar_rules;

  assign cluster_xbar_rules = '{
    '{
      idx:        TCDM,
      start_addr: tcdm_start_address,
      end_addr:   tcdm_end_address
    },
    '{
      idx:        ClusterPeripherals,
      start_addr: tcdm_end_address,
      end_addr:   tcdm_end_address + TCDMSize
    }
  };

  localparam bit [ClusterXbarCfg.NoSlvPorts-1:0] ClusterEnableDefaultMstPort = '1;
  axi_xbar #(
    .Cfg (ClusterXbarCfg),
    .slv_aw_chan_t (axi_mst_aw_chan_t),
    .mst_aw_chan_t (axi_slv_aw_chan_t),
    .w_chan_t (axi_mst_w_chan_t),
    .slv_b_chan_t (axi_mst_b_chan_t),
    .mst_b_chan_t (axi_slv_b_chan_t),
    .slv_ar_chan_t (axi_mst_ar_chan_t),
    .mst_ar_chan_t (axi_slv_ar_chan_t),
    .slv_r_chan_t (axi_mst_r_chan_t),
    .mst_r_chan_t (axi_slv_r_chan_t),
    .slv_req_t (axi_mst_req_t),
    .slv_resp_t (axi_mst_resp_t),
    .mst_req_t (axi_slv_req_t),
    .mst_resp_t (axi_slv_resp_t),
    .rule_t (xbar_rule_t)
  ) i_cluster_xbar (
    .clk_i,
    .rst_ni,
    .test_i (1'b0),
    .slv_ports_req_i (master_req),
    .slv_ports_resp_o (master_resp),
    .mst_ports_req_o (slave_req),
    .mst_ports_resp_i (slave_resp),
    .addr_map_i (cluster_xbar_rules),
    .en_default_mst_port_i (ClusterEnableDefaultMstPort),
    .default_mst_port_i (cluster_xbar_default_port)
  );
  assign cluster_xbar_default_port = '{default: SoC};

  // Optionally decouple the external narrow AXI slave port.
  axi_cut #(
    .Bypass (!RegisterExtNarrow),
    .aw_chan_t (axi_mst_aw_chan_t),
    .w_chan_t (axi_mst_w_chan_t),
    .b_chan_t (axi_mst_b_chan_t),
    .ar_chan_t (axi_mst_ar_chan_t),
    .r_chan_t (axi_mst_r_chan_t),
    .req_t (axi_mst_req_t),
    .resp_t (axi_mst_resp_t)
  ) i_cut_ext_narrow_slv (
    .clk_i,
    .rst_ni,
    .slv_req_i (narrow_in_req_i),
    .slv_resp_o (narrow_in_resp_o),
    .mst_req_o (master_req[AXISoC]),
    .mst_resp_i (master_resp[AXISoC])
  );

  // ---------
  // Slaves
  // ---------
  // 1. TCDM
  // Add an adapter that allows access from AXI to the TCDM.
  axi_to_tcdm #(
    .axi_req_t (axi_slv_req_t),
    .axi_rsp_t (axi_slv_resp_t),
    .tcdm_req_t (tcdm_req_t),
    .tcdm_rsp_t (tcdm_rsp_t),
    .AddrWidth (PhysicalAddrWidth),
    .DataWidth (NarrowDataWidth),
    .IdWidth (IdWidthOut),
    .BufDepth (MemoryMacroLatency + 1)
  ) i_axi_to_tcdm (
    .clk_i,
    .rst_ni,
    .axi_req_i (slave_req[TCDM]),
    .axi_rsp_o (slave_resp[TCDM]),
    .tcdm_req_o (axi_soc_req),
    .tcdm_rsp_i (axi_soc_rsp)
  );

  // 2. Peripherals
  axi_to_reg #(
    .ADDR_WIDTH (PhysicalAddrWidth),
    .DATA_WIDTH (NarrowDataWidth),
    .AXI_MAX_WRITE_TXNS (1),
    .AXI_MAX_READ_TXNS (1),
    .DECOUPLE_W (0),
    .ID_WIDTH (IdWidthOut),
    .USER_WIDTH (UserWidth),
    .axi_req_t (axi_slv_req_t),
    .axi_rsp_t (axi_slv_resp_t),
    .reg_req_t (reg_req_t),
    .reg_rsp_t (reg_rsp_t)
  ) i_axi_to_reg (
    .clk_i,
    .rst_ni,
    .testmode_i (1'b0),
    .axi_req_i (slave_req[ClusterPeripherals]),
    .axi_rsp_o (slave_resp[ClusterPeripherals]),
    .reg_req_o (reg_req),
    .reg_rsp_i (reg_rsp)
  );

  snitch_cluster_peripheral #(
    .AddrWidth (PhysicalAddrWidth),
    .reg_req_t (reg_req_t),
    .reg_rsp_t (reg_rsp_t),
    .tcdm_events_t (tcdm_events_t),
    .NrCores (NrCores)
  ) i_snitch_cluster_peripheral (
    .clk_i,
    .rst_ni,
    .reg_req_i (reg_req),
    .reg_rsp_o (reg_rsp),
    /// The TCDM always starts at the cluster base.
    .tcdm_start_address_i (tcdm_start_address),
    .tcdm_end_address_i (tcdm_end_address),
    .wake_up_o (wake_up_sync),
    .cluster_hart_base_id_i (hart_base_id_i),
    .core_events_i (core_events),
    .tcdm_events_i (tcdm_events)
  );

  // Optionally decouple the external narrow AXI master ports.
  axi_cut #(
    .Bypass    ( !RegisterExtNarrow ),
    .aw_chan_t ( axi_slv_aw_chan_t ),
    .w_chan_t  ( axi_slv_w_chan_t ),
    .b_chan_t  ( axi_slv_b_chan_t ),
    .ar_chan_t ( axi_slv_ar_chan_t ),
    .r_chan_t  ( axi_slv_r_chan_t ),
    .req_t     ( axi_slv_req_t ),
    .resp_t    ( axi_slv_resp_t )
  ) i_cut_ext_narrow_mst (
    .clk_i      ( clk_i           ),
    .rst_ni     ( rst_ni          ),
    .slv_req_i  ( slave_req[SoC]  ),
    .slv_resp_o ( slave_resp[SoC] ),
    .mst_req_o  ( narrow_out_req_o   ),
    .mst_resp_i ( narrow_out_resp_i   )
  );

  // --------------------
  // TCDM event counters
  // --------------------
  logic [NrTCDMPortsCores-1:0] flat_acc, flat_con;
  for (genvar i = 0; i < NrTCDMPortsCores; i++) begin  : gen_event_counter
    `FFSRN(flat_acc[i], tcdm_req[i].q_valid, '0, clk_i, rst_ni)
    `FFSRN(flat_con[i], tcdm_req[i].q_valid & ~tcdm_rsp[i].q_ready, '0, clk_i, rst_ni)
  end

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

  // -------------
  // Sanity Checks
  // -------------
  // Sanity check the parameters. Not every configuration makes sense.
  `ASSERT_INIT(CheckSuperBankSanity, NrBanks >= BanksPerSuperBank);
  `ASSERT_INIT(CheckSuperBankFactor, (NrBanks % BanksPerSuperBank) == 0);
  // Check that the cluster base address aligns to the TCDMSize.
  `ASSERT(ClusterBaseAddrAlign, ((TCDMSize - 1) & cluster_base_addr_i) == 0)
  // Make sure we only have one DMA in the system.
  `ASSERT_INIT(NumberDMA, $onehot0(Xdma))

endmodule
