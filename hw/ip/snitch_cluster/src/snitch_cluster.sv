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
  parameter int unsigned NarrowUserWidth    = 1,
  /// AXI: dma user width.
  parameter int unsigned WideUserWidth      = 1,
  /// Address from which to fetch the first instructions.
  parameter logic [31:0] BootAddr           = 32'h0,
  /// Number of Hives. Each Hive can hold 1-many cores.
  parameter int unsigned NrHives            = 1,
  /// The total (not per Hive) amount of cores.
  parameter int unsigned NrCores            = 8,
  /// Data/TCDM memory depth per cut (in words).
  parameter int unsigned TCDMDepth          = 1024,
  /// Zero memory address region size (in kB).
  parameter int unsigned ZeroMemorySize     = 64,
  /// Cluster peripheral address region size (in kB).
  parameter int unsigned ClusterPeriphSize  = 64,
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
  /// Enable virtual memory support.
  parameter bit          VMSupport          = 1,
  /// Per-core enabling of the standard `E` ISA reduced-register extension.
  parameter bit [NrCores-1:0] RVE           = '0,
  /// Per-core enabling of the standard `F` ISA extensions.
  parameter bit [NrCores-1:0] RVF           = '0,
  /// Per-core enabling of the standard `D` ISA extensions.
  parameter bit [NrCores-1:0] RVD           = '0,
  /// Per-core enabling of `XDivSqrt` ISA extensions.
  parameter bit [NrCores-1:0] XDivSqrt      = '0,
  // Small-float extensions
  /// FP 16-bit
  parameter bit [NrCores-1:0] XF16          = '0,
  /// FP 16 alt a.k.a. brain-float
  parameter bit [NrCores-1:0] XF16ALT       = '0,
  /// FP 8-bit
  parameter bit [NrCores-1:0] XF8           = '0,
  /// FP 8-bit alt
  parameter bit [NrCores-1:0] XF8ALT        = '0,
  /// Enable SIMD support.
  parameter bit [NrCores-1:0] XFVEC         = '0,
  /// Enable DOTP support.
  parameter bit [NrCores-1:0] XFDOTP        = '0,
  /// Per-core enabling of the custom `Xdma` ISA extensions.
  parameter bit [NrCores-1:0] Xdma          = '0,
  /// Per-core enabling of the custom `Xssr` ISA extensions.
  parameter bit [NrCores-1:0] Xssr          = '0,
  /// Per-core enabling of the custom `Xfrep` ISA extensions.
  parameter bit [NrCores-1:0] Xfrep         = '0,
  /// # Core-global parameters
  /// FPU configuration.
  parameter fpnew_pkg::fpu_implementation_t FPUImplementation [NrCores] =
    '{default: fpnew_pkg::fpu_implementation_t'(0)},
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
  /// Insert Pipeline registers immediately before FPU datapath
  parameter bit          RegisterFPUIn      = 0,
  /// Insert Pipeline registers immediately after FPU datapath
  parameter bit          RegisterFPUOut     = 0,
  /// Run Snitch (the integer part) at half of the clock frequency
  parameter bit          IsoCrossing        = 0,
  parameter axi_pkg::xbar_latency_e NarrowXbarLatency = axi_pkg::CUT_ALL_PORTS,
  parameter axi_pkg::xbar_latency_e WideXbarLatency = axi_pkg::CUT_ALL_PORTS,
  /// Outstanding transactions on the wide network
  parameter int unsigned WideMaxMstTrans    = 4,
  parameter int unsigned WideMaxSlvTrans    = 4,
  /// Outstanding transactions on the narrow network
  parameter int unsigned NarrowMaxMstTrans  = 4,
  parameter int unsigned NarrowMaxSlvTrans  = 4,
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
  // Memory configuration input types; these vary depending on implementation.
  parameter type         sram_cfg_t        = logic,
  parameter type         sram_cfgs_t       = logic,
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
  /// Configuration inputs for the memory cuts used in implementation.
  /// These signals are pseudo-static.
  input  sram_cfgs_t                    sram_cfgs_i,
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
  localparam int unsigned TCDMMemAddrWidth = $clog2(TCDMDepth);
  localparam int unsigned TCDMSize = NrBanks * TCDMDepth * (NarrowDataWidth/8);
  localparam int unsigned TCDMAddrWidth = $clog2(TCDMSize);
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

  // Core Requests, SoC Request, PTW.
  localparam int unsigned NrNarrowMasters = 3;
  localparam int unsigned NarrowIdWidthOut = $clog2(NrNarrowMasters) + NarrowIdWidthIn;

  localparam int unsigned NrSlaves = 3;
  localparam int unsigned NrRules = NrSlaves - 1;

  // DMA, SoC Request, `n` instruction caches.
  localparam int unsigned NrWideMasters = 2 + NrHives;
  localparam int unsigned WideIdWidthOut = $clog2(NrWideMasters) + WideIdWidthIn;
  // DMA X-BAR configuration
  localparam int unsigned NrWideSlaves = 3;

  // AXI Configuration
  localparam axi_pkg::xbar_cfg_t ClusterXbarCfg = '{
    NoSlvPorts: NrNarrowMasters,
    NoMstPorts: NrSlaves,
    MaxMstTrans: NarrowMaxMstTrans,
    MaxSlvTrans: NarrowMaxSlvTrans,
    FallThrough: 1'b0,
    LatencyMode: NarrowXbarLatency,
    PipelineStages: 0,
    AxiIdWidthSlvPorts: NarrowIdWidthIn,
    AxiIdUsedSlvPorts: NarrowIdWidthIn,
    UniqueIds: 1'b0,
    AxiAddrWidth: PhysicalAddrWidth,
    AxiDataWidth: NarrowDataWidth,
    NoAddrRules: NrRules
  };

  // DMA configuration struct
  localparam axi_pkg::xbar_cfg_t DmaXbarCfg = '{
    NoSlvPorts: NrWideMasters,
    NoMstPorts: NrWideSlaves,
    MaxMstTrans: WideMaxMstTrans,
    MaxSlvTrans: WideMaxSlvTrans,
    FallThrough: 1'b0,
    LatencyMode: WideXbarLatency,
    PipelineStages: 0,
    AxiIdWidthSlvPorts: WideIdWidthIn,
    AxiIdUsedSlvPorts: WideIdWidthIn,
    UniqueIds: 1'b0,
    AxiAddrWidth: PhysicalAddrWidth,
    AxiDataWidth: WideDataWidth,
    NoAddrRules: 2
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
  typedef logic [NarrowIdWidthOut-1:0]  id_slv_t;
  typedef logic [WideIdWidthIn-1:0]     id_dma_mst_t;
  typedef logic [WideIdWidthOut-1:0]    id_dma_slv_t;
  typedef logic [NarrowUserWidth-1:0]   user_t;
  typedef logic [WideUserWidth-1:0]     user_dma_t;

  typedef logic [TCDMMemAddrWidth-1:0]  tcdm_mem_addr_t;
  typedef logic [TCDMAddrWidth-1:0]     tcdm_addr_t;

  typedef struct packed {
    logic [CoreIDWidth-1:0] core_id;
    bit                     is_core;
  } tcdm_user_t;

  // Regbus peripherals.
  `AXI_TYPEDEF_ALL(axi_mst, addr_t, id_mst_t, data_t, strb_t, user_t)
  `AXI_TYPEDEF_ALL(axi_slv, addr_t, id_slv_t, data_t, strb_t, user_t)
  `AXI_TYPEDEF_ALL(axi_mst_dma, addr_t, id_dma_mst_t, data_dma_t, strb_dma_t, user_dma_t)
  `AXI_TYPEDEF_ALL(axi_slv_dma, addr_t, id_dma_slv_t, data_dma_t, strb_dma_t, user_dma_t)

  `REQRSP_TYPEDEF_ALL(reqrsp, addr_t, data_t, strb_t)

  `MEM_TYPEDEF_ALL(mem, tcdm_mem_addr_t, data_t, strb_t, tcdm_user_t)
  `MEM_TYPEDEF_ALL(mem_dma, tcdm_mem_addr_t, data_dma_t, strb_dma_t, logic)

  `TCDM_TYPEDEF_ALL(tcdm, tcdm_addr_t, data_t, strb_t, tcdm_user_t)
  `TCDM_TYPEDEF_ALL(tcdm_dma, tcdm_addr_t, data_dma_t, strb_dma_t, logic)

  `REG_BUS_TYPEDEF_REQ(reg_req_t, addr_t, data_t, strb_t)
  `REG_BUS_TYPEDEF_RSP(reg_rsp_t, data_t)

  // Event counter increments for the TCDM.
  typedef struct packed {
    /// Number requests going in
    logic [$clog2(NrTCDMPortsCores):0] inc_accessed;
    /// Number of requests stalled due to congestion
    logic [$clog2(NrTCDMPortsCores):0] inc_congested;
  } tcdm_events_t;

  // Event counter increments for DMA.
  typedef struct packed {
      logic aw_stall, ar_stall, r_stall, w_stall,
                   buf_w_stall, buf_r_stall;
      logic aw_valid, aw_ready, aw_done, aw_bw;
      logic ar_valid, ar_ready, ar_done, ar_bw;
      logic r_valid,  r_ready,  r_done, r_bw;
      logic w_valid,  w_ready,  w_done, w_bw;
      logic b_valid,  b_ready,  b_done;
      logic dma_busy;
      axi_pkg::len_t aw_len, ar_len;
      axi_pkg::size_t aw_size, ar_size;
      logic [$clog2(WideDataWidth/8):0] num_bytes_written;
  } dma_events_t;

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
  assign tcdm_start_address = (cluster_base_addr_i & TCDMMask);
  assign tcdm_end_address   = (tcdm_start_address + TCDMSize) & TCDMMask;

  addr_t cluster_periph_start_address, cluster_periph_end_address;
  assign cluster_periph_start_address = tcdm_end_address;
  assign cluster_periph_end_address   = tcdm_end_address + ClusterPeriphSize * 1024;

  addr_t zero_mem_start_address, zero_mem_end_address;
  assign zero_mem_start_address = cluster_periph_end_address;
  assign zero_mem_end_address   = cluster_periph_end_address + ZeroMemorySize * 1024;

  // ----------------
  // Wire Definitions
  // ----------------
  // 1. AXI
  axi_slv_req_t  [NrSlaves-1:0] narrow_axi_slv_req;
  axi_slv_resp_t [NrSlaves-1:0] narrow_axi_slv_rsp;

  axi_mst_req_t  [NrNarrowMasters-1:0] narrow_axi_mst_req;
  axi_mst_resp_t [NrNarrowMasters-1:0] narrow_axi_mst_rsp;

  // DMA AXI buses
  axi_mst_dma_req_t  [NrWideMasters-1:0] wide_axi_mst_req;
  axi_mst_dma_resp_t [NrWideMasters-1:0] wide_axi_mst_rsp;
  axi_slv_dma_req_t  [NrWideSlaves-1 :0] wide_axi_slv_req;
  axi_slv_dma_resp_t [NrWideSlaves-1 :0] wide_axi_slv_rsp;

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
  dma_events_t                dma_events;
  snitch_icache_pkg::icache_events_t [NrCores-1:0] icache_events;

  // 4. Memory Subsystem (Core side).
  reqrsp_req_t [NrCores-1:0] core_req, filtered_core_req;
  reqrsp_rsp_t [NrCores-1:0] core_rsp, filtered_core_rsp;
  reqrsp_req_t [NrHives-1:0] ptw_req;
  reqrsp_rsp_t [NrHives-1:0] ptw_rsp;

  // 5. Peripheral Subsystem
  reg_req_t reg_req;
  reg_rsp_t reg_rsp;

  // 5. Misc. Wires.
  logic icache_prefetch_enable;
  logic [NrCores-1:0] cl_interrupt;

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
    .axi_req_t (axi_slv_dma_req_t),
    .axi_resp_t (axi_slv_dma_resp_t)
  ) i_cut_ext_wide_out (
    .clk_i (clk_i),
    .rst_ni (rst_ni),
    .slv_req_i (wide_axi_slv_req[SoCDMAOut]),
    .slv_resp_o (wide_axi_slv_rsp[SoCDMAOut]),
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
    .axi_req_t (axi_mst_dma_req_t),
    .axi_resp_t (axi_mst_dma_resp_t)
  ) i_cut_ext_wide_in (
    .clk_i (clk_i),
    .rst_ni (rst_ni),
    .slv_req_i (wide_in_req_i),
    .slv_resp_o (wide_in_resp_o),
    .mst_req_o (wide_axi_mst_req[SoCDMAIn]),
    .mst_resp_i (wide_axi_mst_rsp[SoCDMAIn])
  );

  logic [DmaXbarCfg.NoSlvPorts-1:0][$clog2(DmaXbarCfg.NoMstPorts)-1:0] dma_xbar_default_port;
  xbar_rule_t [DmaXbarCfg.NoAddrRules-1:0] dma_xbar_rule;

  assign dma_xbar_default_port = '{default: SoCDMAOut};
  assign dma_xbar_rule = '{
    '{
      idx:        TCDMDMA,
      start_addr: tcdm_start_address,
      end_addr:   tcdm_end_address
    },
    '{
      idx:        ZeroMemory,
      start_addr: zero_mem_start_address,
      end_addr:   zero_mem_end_address
    }
  };
  localparam bit [DmaXbarCfg.NoSlvPorts-1:0] DMAEnableDefaultMstPort = '1;
  axi_xbar #(
    .Cfg (DmaXbarCfg),
    .ATOPs (0),
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
    .slv_ports_req_i (wide_axi_mst_req),
    .slv_ports_resp_o (wide_axi_mst_rsp),
    .mst_ports_req_o (wide_axi_slv_req),
    .mst_ports_resp_i (wide_axi_slv_rsp),
    .addr_map_i (dma_xbar_rule),
    .en_default_mst_port_i (DMAEnableDefaultMstPort),
    .default_mst_port_i (dma_xbar_default_port)
  );

  axi_zero_mem #(
    .axi_req_t (axi_slv_dma_req_t),
    .axi_resp_t (axi_slv_dma_resp_t),
    .AddrWidth (PhysicalAddrWidth),
    .DataWidth (WideDataWidth),
    .IdWidth (WideIdWidthOut),
    .NumBanks (1),
    .BufDepth (1)
  ) i_axi_zeromem (
    .clk_i,
    .rst_ni,
    .busy_o (),
    .axi_req_i (wide_axi_slv_req[ZeroMemory]),
    .axi_resp_o (wide_axi_slv_rsp[ZeroMemory])
  );

  addr_t ext_dma_req_q_addr_nontrunc;

  axi_to_mem_interleaved #(
    .axi_req_t (axi_slv_dma_req_t),
    .axi_resp_t (axi_slv_dma_resp_t),
    .AddrWidth (PhysicalAddrWidth),
    .DataWidth (WideDataWidth),
    .IdWidth (WideIdWidthOut),
    .NumBanks (1),
    .BufDepth (MemoryMacroLatency + 1)
  ) i_axi_to_mem_dma (
    .clk_i,
    .rst_ni,
    .busy_o (),
    .axi_req_i (wide_axi_slv_req[TCDMDMA]),
    .axi_resp_o (wide_axi_slv_rsp[TCDMDMA]),
    .mem_req_o (ext_dma_req.q_valid),
    .mem_gnt_i (ext_dma_rsp.q_ready),
    .mem_addr_o (ext_dma_req_q_addr_nontrunc),
    .mem_wdata_o (ext_dma_req.q.data),
    .mem_strb_o (ext_dma_req.q.strb),
    .mem_atop_o (/* The DMA does not support atomics */),
    .mem_we_o (ext_dma_req.q.write),
    .mem_rvalid_i (ext_dma_rsp.p_valid),
    .mem_rdata_i (ext_dma_rsp.p.data)
  );

  assign ext_dma_req.q.addr = tcdm_addr_t'(ext_dma_req_q_addr_nontrunc);
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
    .MemAddrWidth (TCDMMemAddrWidth),
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
      tcdm_mem_addr_t mem_add;
      strb_t mem_be;
      data_t mem_rdata, mem_wdata;

      tc_sram_impl #(
        .NumWords (TCDMDepth),
        .DataWidth (NarrowDataWidth),
        .ByteWidth (8),
        .NumPorts (1),
        .Latency (1),
        .impl_in_t (sram_cfg_t)
      ) i_data_mem (
        .clk_i,
        .rst_ni,
        .impl_i (sram_cfgs_i.tcdm),
        .impl_o (  ),
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
        .AddrMemWidth ( TCDMMemAddrWidth ),
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
    .MemAddrWidth (TCDMMemAddrWidth),
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
    dma_events_t        dma_core_events;

    sync #(.STAGES (2))
      i_sync_debug (.clk_i, .rst_ni, .serial_i (debug_req_i[i]), .serial_o (irq.debug));
    sync #(.STAGES (2))
      i_sync_meip  (.clk_i, .rst_ni, .serial_i (meip_i[i]), .serial_o (irq.meip));
    sync #(.STAGES (2))
      i_sync_mtip  (.clk_i, .rst_ni, .serial_i (mtip_i[i]), .serial_o (irq.mtip));
    sync #(.STAGES (2))
      i_sync_msip  (.clk_i, .rst_ni, .serial_i (msip_i[i]), .serial_o (irq.msip));
    assign irq.mcip = cl_interrupt[i];

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
        .dma_events_t (dma_events_t),
        .BootAddr (BootAddr),
        .RVE (RVE[i]),
        .RVF (RVF[i]),
        .RVD (RVD[i]),
        .XDivSqrt (XDivSqrt[i]),
        .XF16 (XF16[i]),
        .XF16ALT (XF16ALT[i]),
        .XF8 (XF8[i]),
        .XF8ALT (XF8ALT[i]),
        .XFVEC (XFVEC[i]),
        .XFDOTP (XFDOTP[i]),
        .Xdma (Xdma[i]),
        .IsoCrossing (IsoCrossing),
        .Xfrep (Xfrep[i]),
        .Xssr (Xssr[i]),
        .Xipu (1'b0),
        .VMSupport (VMSupport),
        .NumIntOutstandingLoads (NumIntOutstandingLoads[i]),
        .NumIntOutstandingMem (NumIntOutstandingMem[i]),
        .NumFPOutstandingLoads (NumFPOutstandingLoads[i]),
        .NumFPOutstandingMem (NumFPOutstandingMem[i]),
        .FPUImplementation (FPUImplementation[i]),
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
        .RegisterSequencer (RegisterSequencer),
        .RegisterFPUIn (RegisterFPUIn),
        .RegisterFPUOut (RegisterFPUOut),
        .TCDMAddrWidth (TCDMAddrWidth)
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
        .axi_dma_req_o (axi_dma_req),
        .axi_dma_res_i (axi_dma_res),
        .axi_dma_busy_o (),
        .axi_dma_perf_o (),
        .axi_dma_events_o (dma_core_events),
        .core_events_o (core_events[i]),
        .tcdm_addr_base_i (tcdm_start_address)
      );
      for (genvar j = 0; j < TcdmPorts; j++) begin : gen_tcdm_user
        always_comb begin
          tcdm_req[TcdmPortsOffs+j] = tcdm_req_wo_user[j];
          tcdm_req[TcdmPortsOffs+j].q.user.core_id = i;
          tcdm_req[TcdmPortsOffs+j].q.user.is_core = 1;
        end
      end
      if (Xdma[i]) begin : gen_dma_connection
        assign wide_axi_mst_req[SDMAMst] = axi_dma_req;
        assign axi_dma_res = wide_axi_mst_rsp[SDMAMst];
        assign dma_events = dma_core_events;
      end
  end

  for (genvar i = 0; i < NrHives; i++) begin : gen_hive
      localparam int unsigned HiveSize = get_hive_size(i);

      hive_req_t [HiveSize-1:0] hive_req_reshape;
      hive_rsp_t [HiveSize-1:0] hive_rsp_reshape;

      snitch_icache_pkg::icache_events_t [HiveSize-1:0] icache_events_reshape;

      for (genvar j = 0; j < NrCores; j++) begin : gen_hive_matrix
        // Check whether the core actually belongs to the current hive.
        if (Hive[j] == i) begin : gen_hive_connection
          localparam int unsigned HivePosition = get_core_position(i, j);
          assign hive_req_reshape[HivePosition] = hive_req[j];
          assign hive_rsp[j] = hive_rsp_reshape[HivePosition];
          assign icache_events[j] = icache_events_reshape[HivePosition];
        end
      end

      snitch_hive #(
        .AddrWidth (PhysicalAddrWidth),
        .NarrowDataWidth (NarrowDataWidth),
        .WideDataWidth (WideDataWidth),
        .VMSupport (VMSupport),
        .dreq_t (reqrsp_req_t),
        .drsp_t (reqrsp_rsp_t),
        .hive_req_t (hive_req_t),
        .hive_rsp_t (hive_rsp_t),
        .CoreCount (HiveSize),
        .ICacheLineWidth (ICacheLineWidth[i]),
        .ICacheLineCount (ICacheLineCount[i]),
        .ICacheSets (ICacheSets[i]),
        .IsoCrossing (IsoCrossing),
        .sram_cfg_t  (sram_cfg_t),
        .sram_cfgs_t (sram_cfgs_t),
        .axi_req_t (axi_mst_dma_req_t),
        .axi_rsp_t (axi_mst_dma_resp_t)
      ) i_snitch_hive (
        .clk_i,
        .clk_d2_i (clk_d2),
        .rst_ni,
        .hive_req_i (hive_req_reshape),
        .hive_rsp_o (hive_rsp_reshape),
        .ptw_data_req_o (ptw_req[i]),
        .ptw_data_rsp_i (ptw_rsp[i]),
        .axi_req_o (wide_axi_mst_req[ICache+i]),
        .axi_rsp_i (wide_axi_mst_rsp[ICache+i]),
        .icache_prefetch_enable_i (icache_prefetch_enable),
        .icache_events_o(icache_events_reshape),
        .sram_cfgs_i
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
    .mst_rsp_i (ptw_to_axi_rsp),
    .idx_o (/*not connected*/)
  );

  reqrsp_to_axi #(
    .DataWidth (NarrowDataWidth),
    .UserWidth (NarrowUserWidth),
    .reqrsp_req_t (reqrsp_req_t),
    .reqrsp_rsp_t (reqrsp_rsp_t),
    .axi_req_t (axi_mst_req_t),
    .axi_rsp_t (axi_mst_resp_t)
  ) i_reqrsp_to_axi_ptw (
    .clk_i,
    .rst_ni,
    .user_i ('0),
    .reqrsp_req_i (ptw_to_axi_req),
    .reqrsp_rsp_o (ptw_to_axi_rsp),
    .axi_req_o (narrow_axi_mst_req[PTW]),
    .axi_rsp_i (narrow_axi_mst_rsp[PTW])
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
    .cluster_periph_start_address_i (cluster_periph_start_address)
  );

  reqrsp_req_t core_to_axi_req;
  reqrsp_rsp_t core_to_axi_rsp;
  user_t cluster_user;
  // Atomic ID, needs to be unique ID of cluster
  // cluster_id + HartIdOffset + 1 (because 0 is for non-atomic masters)
  assign cluster_user = (hart_base_id_i / NrCores) +  (hart_base_id_i % NrCores) + 1'b1;

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
    .mst_rsp_i (core_to_axi_rsp),
    .idx_o (/*unused*/)
  );

  reqrsp_to_axi #(
    .DataWidth (NarrowDataWidth),
    .UserWidth (NarrowUserWidth),
    .reqrsp_req_t (reqrsp_req_t),
    .reqrsp_rsp_t (reqrsp_rsp_t),
    .axi_req_t (axi_mst_req_t),
    .axi_rsp_t (axi_mst_resp_t)
  ) i_reqrsp_to_axi_core (
    .clk_i,
    .rst_ni,
    .user_i (cluster_user),
    .reqrsp_req_i (core_to_axi_req),
    .reqrsp_rsp_o (core_to_axi_rsp),
    .axi_req_o (narrow_axi_mst_req[CoreReq]),
    .axi_rsp_i (narrow_axi_mst_rsp[CoreReq])
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
      start_addr: cluster_periph_start_address,
      end_addr:   cluster_periph_end_address
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
    .slv_ports_req_i (narrow_axi_mst_req),
    .slv_ports_resp_o (narrow_axi_mst_rsp),
    .mst_ports_req_o (narrow_axi_slv_req),
    .mst_ports_resp_i (narrow_axi_slv_rsp),
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
    .axi_req_t (axi_mst_req_t),
    .axi_resp_t (axi_mst_resp_t)
  ) i_cut_ext_narrow_slv (
    .clk_i,
    .rst_ni,
    .slv_req_i (narrow_in_req_i),
    .slv_resp_o (narrow_in_resp_o),
    .mst_req_o (narrow_axi_mst_req[AXISoC]),
    .mst_resp_i (narrow_axi_mst_rsp[AXISoC])
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
    .IdWidth (NarrowIdWidthOut),
    .BufDepth (MemoryMacroLatency + 1)
  ) i_axi_to_tcdm (
    .clk_i,
    .rst_ni,
    .axi_req_i (narrow_axi_slv_req[TCDM]),
    .axi_rsp_o (narrow_axi_slv_rsp[TCDM]),
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
    .ID_WIDTH (NarrowIdWidthOut),
    .USER_WIDTH (NarrowUserWidth),
    .axi_req_t (axi_slv_req_t),
    .axi_rsp_t (axi_slv_resp_t),
    .reg_req_t (reg_req_t),
    .reg_rsp_t (reg_rsp_t)
  ) i_axi_to_reg (
    .clk_i,
    .rst_ni,
    .testmode_i (1'b0),
    .axi_req_i (narrow_axi_slv_req[ClusterPeripherals]),
    .axi_rsp_o (narrow_axi_slv_rsp[ClusterPeripherals]),
    .reg_req_o (reg_req),
    .reg_rsp_i (reg_rsp)
  );

  snitch_cluster_peripheral #(
    .AddrWidth (PhysicalAddrWidth),
    .reg_req_t (reg_req_t),
    .reg_rsp_t (reg_rsp_t),
    .tcdm_events_t (tcdm_events_t),
    .dma_events_t (dma_events_t),
    .NrCores (NrCores)
  ) i_snitch_cluster_peripheral (
    .clk_i,
    .rst_ni,
    .reg_req_i (reg_req),
    .reg_rsp_o (reg_rsp),
    /// The TCDM always starts at the cluster base.
    .tcdm_start_address_i (tcdm_start_address),
    .tcdm_end_address_i (tcdm_end_address),
    .icache_prefetch_enable_o (icache_prefetch_enable),
    .cl_clint_o (cl_interrupt),
    .cluster_hart_base_id_i (hart_base_id_i),
    .core_events_i (core_events),
    .tcdm_events_i (tcdm_events),
    .dma_events_i (dma_events),
    .icache_events_i (icache_events)
  );

  // Optionally decouple the external narrow AXI master ports.
  axi_cut #(
    .Bypass     ( !RegisterExtNarrow ),
    .aw_chan_t  ( axi_slv_aw_chan_t ),
    .w_chan_t   ( axi_slv_w_chan_t ),
    .b_chan_t   ( axi_slv_b_chan_t ),
    .ar_chan_t  ( axi_slv_ar_chan_t ),
    .r_chan_t   ( axi_slv_r_chan_t ),
    .axi_req_t  ( axi_slv_req_t ),
    .axi_resp_t ( axi_slv_resp_t )
  ) i_cut_ext_narrow_mst (
    .clk_i      ( clk_i           ),
    .rst_ni     ( rst_ni          ),
    .slv_req_i  ( narrow_axi_slv_req[SoC] ),
    .slv_resp_o ( narrow_axi_slv_rsp[SoC] ),
    .mst_req_o  ( narrow_out_req_o   ),
    .mst_resp_i ( narrow_out_resp_i   )
  );

  // --------------------
  // TCDM event counters
  // --------------------
  logic [NrTCDMPortsCores-1:0] flat_acc, flat_con;
  for (genvar i = 0; i < NrTCDMPortsCores; i++) begin  : gen_event_counter
    `FFARN(flat_acc[i], tcdm_req[i].q_valid, '0, clk_i, rst_ni)
    `FFARN(flat_con[i], tcdm_req[i].q_valid & ~tcdm_rsp[i].q_ready, '0, clk_i, rst_ni)
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
