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
    TCDMDMA = 32'd0,
    SoCDMAOut = 32'd1
  } cluster_slave_dma_e;

  typedef enum int unsigned {
    SDMAMst = 32'd0,
    SoCDMAIn = 32'd1
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

  // SSRs
  localparam logic [11:0] CSR_SSR = 'h7c0;
  localparam logic [11:0] CSR_MSEG = 12'hBC0;

  // --------------------
  // Trace Infrastructure
  // --------------------
  // pragma translate_off
  typedef enum logic [1:0] {
    SrcSnitch =  0,
    SrcFpu = 1,
    SrcFpuSeq = 2
  } trace_src_e;

  typedef struct packed {
    longint source;
    longint stall;
    longint rs1;
    longint rs2;
    longint rd;
    longint is_load;
    longint is_store;
    longint is_branch;
    longint pc_d;
    longint opa;
    longint opb;
    longint opa_select;
    longint opb_select;
    longint write_rd;
    longint csr_addr;
    longint writeback;
    longint gpr_rdata_1;
    longint ls_size;
    longint ld_result_32;
    longint lsu_rd;
    longint retire_load;
    longint alu_result;
    longint ls_amo;
    longint retire_acc;
    longint acc_pid;
    longint acc_pdata_32;
    longint fpu_offload;
    longint is_seq_insn;
  } snitch_trace_port_t;

  function automatic string print_snitch_trace(snitch_trace_port_t snitch_trace);
    string extras_str = "{";
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "source", snitch_trace.source);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "stall", snitch_trace.stall);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "rs1", snitch_trace.rs1);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "rs2", snitch_trace.rs2);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "rd", snitch_trace.rd);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "is_load", snitch_trace.is_load);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "is_store", snitch_trace.is_store);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "is_branch", snitch_trace.is_branch);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "pc_d", snitch_trace.pc_d);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "opa", snitch_trace.opa);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "opb", snitch_trace.opb);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "opa_select", snitch_trace.opa_select);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "opb_select", snitch_trace.opb_select);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "write_rd", snitch_trace.write_rd);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "csr_addr", snitch_trace.csr_addr);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "writeback", snitch_trace.writeback);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "gpr_rdata_1", snitch_trace.gpr_rdata_1);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "ls_size", snitch_trace.ls_size);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "ld_result_32", snitch_trace.ld_result_32);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "lsu_rd", snitch_trace.lsu_rd);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "retire_load", snitch_trace.retire_load);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "alu_result", snitch_trace.alu_result);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "ls_amo", snitch_trace.ls_amo);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "retire_acc", snitch_trace.retire_acc);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "acc_pid", snitch_trace.acc_pid);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "acc_pdata_32", snitch_trace.acc_pdata_32);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "fpu_offload", snitch_trace.fpu_offload);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "is_seq_insn", snitch_trace.is_seq_insn);
    extras_str = $sformatf("%s}", extras_str);
    return extras_str;
  endfunction

  // Trace-Port Definitions
  typedef struct packed {
    longint source;
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

  function automatic string print_fpu_trace(fpu_trace_port_t fpu_trace);
    string extras_str = "{";
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "source", fpu_trace.source);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "acc_q_hs", fpu_trace.acc_q_hs);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "fpu_out_hs", fpu_trace.fpu_out_hs);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "lsu_q_hs", fpu_trace.lsu_q_hs);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "op_in", fpu_trace.op_in);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "rs1", fpu_trace.rs1);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "rs2", fpu_trace.rs2);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "rs3", fpu_trace.rs3);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "rd", fpu_trace.rd);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "op_sel_0", fpu_trace.op_sel_0);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "op_sel_1", fpu_trace.op_sel_1);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "op_sel_2", fpu_trace.op_sel_2);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "src_fmt", fpu_trace.src_fmt);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "dst_fmt", fpu_trace.dst_fmt);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "int_fmt", fpu_trace.int_fmt);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "acc_qdata_0", fpu_trace.acc_qdata_0);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "acc_qdata_1", fpu_trace.acc_qdata_1);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "acc_qdata_2", fpu_trace.acc_qdata_2);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "op_0", fpu_trace.op_0);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "op_1", fpu_trace.op_1);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "op_2", fpu_trace.op_2);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "use_fpu", fpu_trace.use_fpu);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "fpu_in_rd", fpu_trace.fpu_in_rd);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "fpu_in_acc", fpu_trace.fpu_in_acc);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "ls_size", fpu_trace.ls_size);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "is_load", fpu_trace.is_load);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "is_store", fpu_trace.is_store);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "lsu_qaddr", fpu_trace.lsu_qaddr);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "lsu_rd", fpu_trace.lsu_rd);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "acc_wb_ready", fpu_trace.acc_wb_ready);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "fpu_out_acc", fpu_trace.fpu_out_acc);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "fpr_waddr", fpu_trace.fpr_waddr);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "fpr_wdata", fpu_trace.fpr_wdata);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "fpr_we", fpu_trace.fpr_we);
    extras_str = $sformatf("%s}", extras_str);
    return extras_str;
  endfunction

  typedef struct packed {
    longint source;
    longint cbuf_push;
    longint is_outer;
    longint max_inst;
    longint max_rpt;
    longint stg_max;
    longint stg_mask;
  } fpu_sequencer_trace_port_t;

  function automatic string print_fpu_sequencer_trace(fpu_sequencer_trace_port_t fpu_sequencer);
    string extras_str = "{";
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "source", fpu_sequencer.source);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "cbuf_push", fpu_sequencer.cbuf_push);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "is_outer", fpu_sequencer.is_outer);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "max_inst", fpu_sequencer.max_inst);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "max_rpt", fpu_sequencer.max_rpt);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "stg_max", fpu_sequencer.stg_max);
    extras_str = $sformatf("%s'%s': 0x%0x, ", extras_str, "stg_mask", fpu_sequencer.stg_mask);
    extras_str = $sformatf("%s}", extras_str);
    return extras_str;
  endfunction
  // pragma translate_on

endpackage
