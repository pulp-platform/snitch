// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

/// # Snitch-wide Constants.
/// Fixed constants for a Snitch system.

package snitch_pkg;

  localparam dm::hartinfo_t SnitchHartinfo = '{
    zero1: '0,
    nscratch: 1,
    zero0: '0,
    dataaccess: 1,
    datasize: dm::DataCount,
    dataaddr: dm::DataAddr
  };

  /// Async interrupts of the core.
  typedef struct packed {
    /// Debug request
    logic debug;
    /// Machine external interrupt pending
    logic meip;
    /// Machine external timer interrupt pending
    logic mtip;
    /// Machine external software interrupt pending
    logic msip;
  } interrupts_t;

  typedef enum logic [31:0] {
    FP_SS = 0,
    SHARED_MULDIV = 1,
    DMA_SS = 2,
    INT_SS = 3,
    SSR_CFG = 4
  } acc_addr_e;

  typedef enum logic [1:0] {
    PrivLvlM = 2'b11,
    PrivLvlS = 2'b01,
    PrivLvlU = 2'b00
  } priv_lvl_t;

  // Extension state.
  typedef enum logic [1:0] {
    XOff = 2'b00,
    XInitial = 2'b01,
    XClean = 2'b10,
    XDirty = 2'b11
  } x_state_e;

  typedef struct packed {
    logic         sd;     // signal dirty - read-only - hardwired zero
    logic [7:0]   wpri3;  // writes preserved reads ignored
    logic         tsr;    // trap sret
    logic         tw;     // time wait
    logic         tvm;    // trap virtual memory
    logic         mxr;    // make executable readable
    logic         sum;    // permit supervisor user memory access
    logic         mprv;   // modify privilege - privilege level for ld/st
    x_state_e     xs;     // extension register - hardwired to zero
    x_state_e     fs;     // extension register - hardwired to zero for non FP and to Dirty for FP.
    priv_lvl_t    mpp;    // holds the previous privilege mode up to machine
    logic [1:0]   wpri2;  // writes preserved reads ignored
    logic         spp;    // holds the previous privilege mode up to supervisor
    logic         mpie;   // machine interrupts enable bit active prior to trap
    logic         wpri1;  // writes preserved reads ignored
    logic         spie;   // supervisor interrupts enable bit active prior to trap
    logic         upie;   // user interrupts enable bit active prior to trap - hardwired to zero
    logic         mie;    // machine interrupts enable
    logic         wpri0;  // writes preserved reads ignored
    logic         sie;    // supervisor interrupts enable
    logic         uie;    // user interrupts enable - hardwired to zero
  } status_rv32_t;

  // Virtual Memory
  localparam int unsigned PAGE_SHIFT = 12;
  /// Size in bits of the virtual address segments
  localparam int unsigned VPN_SIZE = 10;

  /// Virtual Address Definition
  typedef struct packed {
    /// Virtual Page Number 1
    logic [31:32-VPN_SIZE] vpn1;
    /// Virtual Page Number 0
    logic [PAGE_SHIFT+VPN_SIZE-1:PAGE_SHIFT] vpn0;
  } va_t;

  typedef struct packed {
    logic               d;
    logic               a;
    logic               u;
    logic               x;
    logic               w;
    logic               r;
  } pte_flags_t;

  localparam logic [3:0] INSTR_ADDR_MISALIGNED = 0;
  localparam logic [3:0] INSTR_ACCESS_FAULT    = 1;
  localparam logic [3:0] ILLEGAL_INSTR         = 2;
  localparam logic [3:0] BREAKPOINT            = 3;
  localparam logic [3:0] LD_ADDR_MISALIGNED    = 4;
  localparam logic [3:0] LD_ACCESS_FAULT       = 5;
  localparam logic [3:0] ST_ADDR_MISALIGNED    = 6;
  localparam logic [3:0] ST_ACCESS_FAULT       = 7;
  localparam logic [3:0] ENV_CALL_UMODE        = 8;  // environment call from user mode
  localparam logic [3:0] ENV_CALL_SMODE        = 9;  // environment call from supervisor mode
  localparam logic [3:0] ENV_CALL_MMODE        = 11; // environment call from machine mode
  localparam logic [3:0] INSTR_PAGE_FAULT      = 12; // Instruction page fault
  localparam logic [3:0] LOAD_PAGE_FAULT       = 13; // Load page fault
  localparam logic [3:0] STORE_PAGE_FAULT      = 15; // Store page fault

  localparam logic [3:0] MSI = 3;
  localparam logic [3:0] MTI = 7;
  localparam logic [3:0] MEI = 11;
  localparam logic [3:0] SSI = 1;
  localparam logic [3:0] STI = 5;
  localparam logic [3:0] SEI = 9;

  // Registers which are used as SSRs
  localparam [4:0] FT0 = 5'd0;
  localparam [4:0] FT1 = 5'd1;
  localparam [4:0] FT2 = 5'd2;
  localparam [1:0][4:0] SSRRegs = {FT2, FT1, FT0};
  function automatic logic is_ssr(logic [4:0] register);
    unique case (register)
      FT0, FT1, FT2: return 1'b1;
      default : return 0;
    endcase
  endfunction

  // Slaves on Cluster AXI Bus
  typedef enum integer {
    TCDM               = 0,
    ClusterPeripherals = 1,
    SoC                = 2
  } cluster_slave_e;

  typedef enum integer {
    CoreReq = 0,
    AXISoC  = 1,
    PTW     = 2,
    ICache  = 3
  } cluster_master_e;

  // Slaves on Cluster DMA AXI Bus
  typedef enum int unsigned {
    TCDMDMA  = 32'd0,
    SoCDMA   = 32'd1
  } cluster_slave_dma_e;

  typedef enum int unsigned {
    SDMAMst  = 32'd0
  } cluster_master_dma_e;

  /// Possible interconnect implementations.
  typedef enum bit {
    /// Crossbar implementation. We call it `LogarithmicInterconnect` because the
    /// response path isn't arbitrated.
    LogarithmicInterconnect,
    /// Omega Network. It is isomorphic to a butterfly network.
    OmegaNet
  } topo_e;

  // Event strobes per core, counted by the performance counters in the cluster
  // peripherals.
  typedef struct packed {
    logic issue_fpu;          // core operations performed in the FPU
    logic issue_fpu_seq;      // includes load/store operations
    logic issue_core_to_fpu;  // instructions issued from core to FPU
  } core_events_t;

  // Trace-Port Definitions
  typedef struct packed {
    longint acc_q_hs;
    longint fpu_out_hs;
    longint lsu_q_hs;
    longint op_in;
    longint rs1;
    longint rs2;
    longint rs3;
    longint rd;
    longint op_sel_0;
    longint op_sel_1;
    longint op_sel_2;
    longint src_fmt;
    longint dst_fmt;
    longint int_fmt;
    longint acc_qdata_0;
    longint acc_qdata_1;
    longint acc_qdata_2;
    longint op_0;
    longint op_1;
    longint op_2;
    longint use_fpu;
    longint fpu_in_rd;
    longint fpu_in_acc;
    longint ls_size;
    longint is_load;
    longint is_store;
    longint lsu_qaddr;
    longint lsu_rd;
    longint acc_wb_ready;
    longint fpu_out_acc;
    longint fpr_waddr;
    longint fpr_wdata;
    longint fpr_we;
  } fpu_trace_port_t;

  typedef struct packed {
    longint cbuf_push;
    longint is_outer;
    longint max_inst;
    longint max_rpt;
    longint stg_max;
    longint stg_mask;
  } fpu_sequencer_trace_port_t;

  // SSRs
  localparam logic [11:0] CSR_SSR = 'h7c0;
  localparam logic [11:0] CSR_MSEG = 12'hBC0;

endpackage
