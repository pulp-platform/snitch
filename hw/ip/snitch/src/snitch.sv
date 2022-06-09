// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>
// Description: Top-Level of Snitch Integer Core RV32E

`include "common_cells/registers.svh"
`include "common_cells/assertions.svh"

// `SNITCH_ENABLE_PERF Enables mcycle, minstret performance counters (read only)

module snitch import snitch_pkg::*; import riscv_instr::*; #(
  /// Boot address of core.
  parameter logic [31:0] BootAddr  = 32'h0000_1000,
  /// Physical Address width of the core.
  parameter int unsigned AddrWidth = 48,
  /// Data width of memory interface.
  parameter int unsigned DataWidth = 64,
  /// Reduced-register extension.
  parameter bit          RVE       = 0,
  /// Enable Snitch DMA as accelerator.
  parameter bit          Xdma      = 0,
  parameter bit          Xssr      = 0,
  /// Enable FP in general
  parameter bit          FP_EN     = 1,
  /// Enable F Extension.
  parameter bit          RVF       = 0,
  /// Enable D Extension.
  parameter bit          RVD       = 0,
  parameter bit          XF16      = 0,
  parameter bit          XF16ALT   = 0,
  parameter bit          XF8       = 0,
  parameter bit          XF8ALT    = 0,
  /// Enable div/sqrt unit (buggy - use with caution)
  parameter bit          XDivSqrt  = 0,
  parameter bit          XFVEC     = 0,
  parameter bit          XFDOTP    = 0,
  parameter bit          XFAUX     = 0,
  int unsigned           FLEN      = DataWidth,
  /// Enable experimental IPU extension.
  parameter bit          Xipu      = 1,
  /// Data port request type.
  parameter type         dreq_t    = logic,
  /// Data port response type.
  parameter type         drsp_t     = logic,
  parameter type         acc_req_t  = logic,
  parameter type         acc_resp_t = logic,
  parameter type         pa_t       = logic,
  parameter type         l0_pte_t   = logic,
  parameter int unsigned NumIntOutstandingLoads = 0,
  parameter int unsigned NumIntOutstandingMem = 0,
  parameter int unsigned NumDTLBEntries = 0,
  parameter int unsigned NumITLBEntries = 0,
  parameter int unsigned NumSsrs =  0,
  parameter logic [NumSsrs-1:0][4:0]  IntSsrRegs = '0,                                                           
  snitch_pma_pkg::snitch_pma_t SnitchPMACfg = '{default: 0},
  /// Derived parameter *Do not override*
  parameter type addr_t = logic [AddrWidth-1:0],
  parameter type data_t = logic [DataWidth-1:0],
  parameter type data_t_core = logic [31:0]                                                           
) (
  input  logic          clk_i,
  input  logic          rst_i,
  input  logic [31:0]   hart_id_i,
  /// Interrupts
  input  interrupts_t   irq_i,
  /// Instruction cache flush request
  output logic          flush_i_valid_o,
  /// Flush has completed when the signal goes to `1`.
  /// Tie to `1` if unused
  input  logic          flush_i_ready_i,
  // Instruction Refill Port
  output addr_t         inst_addr_o,
  output logic          inst_cacheable_o,
  input  logic [31:0]   inst_data_i,
  output logic          inst_valid_o,
  input  logic          inst_ready_i,
  /// Accelerator Interface - Master Port
  /// Independent channels for transaction request and read completion.
  /// AXI-like handshaking.
  /// Same IDs need to be handled in-order.
  output acc_req_t      acc_qreq_o,
  output logic          acc_qvalid_o,
  input  logic          acc_qready_i,
  input  acc_resp_t     acc_prsp_i,
  input  logic          acc_pvalid_i,
  output logic          acc_pready_o,
  input  logic          acc_ssr_status_i,
  /// TCDM Data Interface
  /// Write transactions do not return data on the `P Channel`
  /// Transactions need to be handled strictly in-order.
  output dreq_t         data_req_o,
  input  drsp_t         data_rsp_i,
  // Address Translation interface.
  output logic    [1:0] ptw_valid_o,
  input  logic    [1:0] ptw_ready_i,
  output va_t     [1:0] ptw_va_o,
  output pa_t     [1:0] ptw_ppn_o,
  input  l0_pte_t [1:0] ptw_pte_i,
  input  logic    [1:0] ptw_is_4mega_i,
  // FPU **un-timed** Side-channel
  output fpnew_pkg::roundmode_e fpu_rnd_mode_o,
  output fpnew_pkg::fmt_mode_t  fpu_fmt_mode_o,
  input  fpnew_pkg::status_t    fpu_status_i,
  // SSR Interface
  output logic       [1:0][4:0] ssr_raddr_o,
  input  data_t_core [1:0]      ssr_rdata_i,
  output logic       [1:0]      ssr_rvalid_o,
  input  logic       [1:0]      ssr_rready_i,
  output logic       [1:0]      ssr_rdone_o,
  output logic       [0:0][4:0] ssr_waddr_o,
  output data_t_core [0:0]      ssr_wdata_o,
  output logic       [0:0]      ssr_wvalid_o,
  input  logic       [0:0]      ssr_wready_i,
  output logic       [0:0]      ssr_wdone_o,
  output logic                  ssr_sel_o 
);
  // Debug module's base address
  localparam logic [31:0] DmBaseAddress = 0;
  localparam int RegWidth = RVE ? 4 : 5;
  localparam int RegNrReadPorts = Xipu ? 3 : 2;
  localparam int RegNrWritePorts = Xipu ? 2 : 1;
   
  /// Total physical address portion.
  localparam int unsigned PPNSize = AddrWidth - PAGE_SHIFT;
  localparam bit NSX = XF16 | XF16ALT | XF8 | XFVEC;

  logic illegal_inst, illegal_csr;
  logic interrupt, ecall, ebreak;
  logic zero_lsb;

  logic meip, mtip, msip, mcip;
  logic seip, stip, ssip, scip;
  logic interrupts_enabled;
  logic any_interrupt_pending;

  // Instruction fetch
  logic [31:0] pc_d, pc_q;
  logic wfi_d, wfi_q;
  logic [31:0] consec_pc;
  // Immediates
  logic [31:0] iimm, uimm, jimm, bimm, simm, pbimm;
  /* verilator lint_off WIDTH */
  assign iimm = $signed({inst_data_i[31:20]});
  assign uimm = {inst_data_i[31:12], 12'b0};
  assign jimm = $signed({inst_data_i[31],
                                  inst_data_i[19:12], inst_data_i[20], inst_data_i[30:21], 1'b0});
  assign bimm = $signed({inst_data_i[31],
                                    inst_data_i[7], inst_data_i[30:25], inst_data_i[11:8], 1'b0});
  assign simm = $signed({inst_data_i[31:25], inst_data_i[11:7]});
  assign pbimm = $signed({inst_data_i[24:20]}); // Xpulpimg immediate branching signed immediate
  /* verilator lint_on WIDTH */

  logic [31:0] opa, opb;
  logic [32:0] adder_result;
  logic [31:0] alu_result;

  logic [RegWidth-1:0] rd, rs1, rs2;
  logic stall, lsu_stall;
  // Register connections
  logic [RegNrReadPorts-1:0][RegWidth-1:0]  gpr_raddr;
  logic [RegNrReadPorts-1:0][31:0]          gpr_rdata;
  logic [RegNrWritePorts-1:0][RegWidth-1:0] gpr_waddr;
  logic [RegNrWritePorts-1:0][31:0]         gpr_wdata;
  logic [RegNrWritePorts-1:0]               gpr_we;
  logic [2**RegWidth-1:0]                   sb_d, sb_q;

  // Load/Store Defines
  logic is_load, is_store, is_signed, is_postincr;
  logic is_fp_load, is_fp_store;
  logic ls_misaligned;
  logic ld_addr_misaligned;
  logic st_addr_misaligned;
  logic inst_addr_misaligned;

  logic  itlb_valid, itlb_ready;
  va_t   itlb_va;
  logic  itlb_page_fault;
  pa_t   itlb_pa;

  logic  dtlb_valid, dtlb_ready;
  va_t   dtlb_va;
  logic  dtlb_page_fault;
  pa_t   dtlb_pa;
  logic  trans_ready;
  logic  trans_active;
  logic  itlb_trans_valid, dtlb_trans_valid;
  logic [PPNSize-1:0] trans_active_exp;
  logic  tlb_flush;


  typedef enum logic [1:0] {
    Byte = 2'b00,
    HalfWord = 2'b01,
    Word = 2'b10,
    Double = 2'b11
  } ls_size_e;
  ls_size_e ls_size;

  reqrsp_pkg::amo_op_e ls_amo;

  data_t ld_result;
  logic  lsu_qready, lsu_qvalid;
  logic  lsu_tlb_qready, lsu_tlb_qvalid; // gated version considering TLB and LSU
  logic  lsu_pvalid, lsu_pready;
  logic  lsu_empty;
  addr_t ls_paddr;
  logic [31:0] ls_addr_sel; // address selection for post-increment ld/st or normal addressing mode
  logic [RegWidth-1:0] lsu_rd;

  logic retire_load; // retire a load instruction
  logic retire_p; // retire from post-increment instructions
  logic retire_i; // retire the rest of the base instruction set
  logic retire_acc; // retire an instruction we offloaded

  logic acc_stall;
  logic valid_instr;
  logic exception;

  // ALU Operations
  typedef enum logic [3:0]  {
    Add, Sub,
    Slt, Sltu,
    Sll, Srl, Sra,
    LXor, LOr, LAnd, LNAnd,
    Eq, Neq, Ge, Geu,
    BypassA
  } alu_op_e;
  alu_op_e alu_op;

  typedef enum logic [3:0] {
    None, Reg, IImmediate, UImmediate, JImmediate, 
    SImmediate, SFImmediate, PC, CSR, 
    CSRImmmediate, PBImmediate, RegRd, RegRs2
  } op_select_e;
  op_select_e opa_select, opb_select, opc_select;

  logic write_rd; // write destination this cycle
  logic uses_rd;
  logic write_rs1; // write rs1 destination this cycle
  logic uses_rs1;
  typedef enum logic [2:0] {Consec, Alu, Exception, MRet, SRet, DRet} next_pc_e;
  next_pc_e next_pc;

  typedef enum logic [1:0] {RdAlu, RdConsecPC, RdBypass} rd_select_e;
  rd_select_e rd_select;
  logic [31:0] rd_bypass;

  // FSM handling SSR multiplexing
  typedef enum logic [1:0] {
    Idle = 2'b00, 
    FPIssue = 2'b01, 
    FPActive = 2'b10, 
    IActive = 2'b11
  } ssr_state_e;
  ssr_state_e ssr_state_q, ssr_state_d;
  logic is_fp_ssr, is_int_ssr;

  logic is_branch;

  // -----
  // CSRs
  // -----
  logic [31:0] csr_rvalue;
  logic csr_en;

  localparam logic M = 0;
  localparam logic S = 1;

  logic [1:0][31:0] scratch_d, scratch_q;
  logic [1:0][31:0] epc_d, epc_q;
  logic [0:0][31:2] tvec_d, tvec_q;
  logic [0:0][4:0] cause_d, cause_q;
  logic [0:0] cause_irq_d, cause_irq_q;
  logic spp_d, spp_q;
  snitch_pkg::priv_lvl_t mpp_d, mpp_q;
  logic [0:0] ie_d, ie_q;
  logic [0:0] pie_d, pie_q;
  // Interrupts
  logic [1:0] eie_d, eie_q;
  logic [1:0] tie_d, tie_q;
  logic [1:0] sie_d, sie_q;
  logic [1:0] cie_d, cie_q;
  logic       seip_d, seip_q;
  logic       stip_d, stip_q;
  logic       ssip_d, ssip_q;
  logic       scip_d, scip_q;
  logic       ssr_active_d, ssr_active_q;
  snitch_pkg::priv_lvl_t priv_lvl_d, priv_lvl_q;

  typedef struct packed {
    logic mode;
    logic [21:0] ppn;
  } satp_t;
  satp_t satp_d, satp_q;

  dm::dcsr_t dcsr_d, dcsr_q;
  logic [31:0] dpc_d, dpc_q;
  logic [31:0] dscratch_d, dscratch_q;
  logic debug_d, debug_q;

  `FFNR(scratch_q, scratch_d, clk_i)
  `FFNR(tvec_q, tvec_d, clk_i)
  `FFNR(epc_q, epc_d, clk_i)
  `FFNR(satp_q, satp_d, clk_i)
  `FFAR(cause_q, cause_d, '0, clk_i, rst_i)
  `FFAR(cause_irq_q, cause_irq_d, '0, clk_i, rst_i)
  `FFAR(priv_lvl_q, priv_lvl_d, snitch_pkg::PrivLvlM, clk_i, rst_i)
  `FFAR(mpp_q, mpp_d, snitch_pkg::PrivLvlU, clk_i, rst_i)
  `FFAR(spp_q, spp_d, 1'b0, clk_i, rst_i)
  `FFAR(ie_q, ie_d, '0, clk_i, rst_i)
  `FFAR(pie_q, pie_d, '0, clk_i, rst_i)
  `FFAR(ssr_active_q, Xssr & ssr_active_d, 1'b0, clk_i, rst_i);
  // Interrupts
  `FFAR(eie_q, eie_d, '0, clk_i, rst_i)
  `FFAR(tie_q, tie_d, '0, clk_i, rst_i)
  `FFAR(sie_q, sie_d, '0, clk_i, rst_i)
  `FFAR(cie_q, cie_d, '0, clk_i, rst_i)
  `FFAR(seip_q, seip_d, '0, clk_i, rst_i)
  `FFAR(stip_q, stip_d, '0, clk_i, rst_i)
  `FFAR(ssip_q, ssip_d, '0, clk_i, rst_i)
  `FFAR(scip_q, scip_d, '0, clk_i, rst_i)

  `FFAR(dcsr_q, dcsr_d, '0, clk_i, rst_i)
  `FFNR(dpc_q, dpc_d, clk_i)
  `FFNR(dscratch_q, dscratch_d, clk_i)
  `FFAR(debug_q, debug_d, '0, clk_i, rst_i) // Debug mode

  typedef struct packed {
    fpnew_pkg::roundmode_e frm;
    fpnew_pkg::status_t    fflags;
    fpnew_pkg::fmt_mode_t  fmode;
  } fcsr_t;
  fcsr_t fcsr_d, fcsr_q;

  assign fpu_rnd_mode_o = fcsr_q.frm;
  assign fpu_fmt_mode_o = fcsr_q.fmode;

  // Registers
  `FFAR(pc_q, pc_d, BootAddr, clk_i, rst_i)
  `FFAR(wfi_q, wfi_d, '0, clk_i, rst_i)
  `FFAR(sb_q, sb_d, '0, clk_i, rst_i)
  `FFAR(fcsr_q, fcsr_d, '0, clk_i, rst_i)

  // performance counter
  `ifdef SNITCH_ENABLE_PERF
  logic [63:0] cycle_q;
  logic [63:0] instret_q;
  `FFAR(cycle_q, cycle_q + 1, '0, clk_i, rst_i)
  `FFLAR(instret_q, instret_q + 1, !stall, '0, clk_i, rst_i)
  `endif

  logic [AddrWidth-32-1:0] mseg_q, mseg_d;
  `FFAR(mseg_q, mseg_d, '0, clk_i, rst_i)

  // accelerator offloading interface
  // register int destination in scoreboard
  logic  acc_register_rd;
  // multiplexing argc for the fp_ss and ipu
  logic  acc_opc_sel;

  assign acc_qreq_o.id = rd;
  assign acc_qreq_o.data_op = inst_data_i;
  assign acc_qreq_o.data_arga = {{32{gpr_rdata[0][31]}}, gpr_rdata[0]};
  assign acc_qreq_o.data_argb = {{32{gpr_rdata[1][31]}}, gpr_rdata[1]};
  assign acc_qreq_o.data_argc = acc_opc_sel ? {{32{gpr_rdata[2][31]}}, gpr_rdata[2]} : ls_paddr;

  // ---------
  // L0 ITLB
  // ---------
  assign itlb_va = va_t'(pc_q[31:PAGE_SHIFT]);

  snitch_l0_tlb #(
    .pa_t (pa_t),
    .l0_pte_t (l0_pte_t),
    .NrEntries ( NumITLBEntries )
  ) i_snitch_l0_tlb_inst (
    .clk_i,
    .rst_i,
    .flush_i ( tlb_flush ),
    .priv_lvl_i ( priv_lvl_q ),
    .valid_i ( itlb_valid ),
    .ready_o ( itlb_ready ),
    .va_i ( itlb_va ),
    .write_i ( 1'b0 ),
    .read_i  ( 1'b0 ),
    .execute_i ( 1'b1 ),
    .page_fault_o ( itlb_page_fault ),
    .pa_o ( itlb_pa ),
    // Refill port
    .valid_o ( ptw_valid_o[0] ),
    .ready_i ( ptw_ready_i[0] ),
    .va_o ( ptw_va_o[0] ),
    .pte_i ( ptw_pte_i[0] ),
    .is_4mega_i ( ptw_is_4mega_i[0] )
  );

  assign itlb_valid = trans_active & inst_valid_o;
  assign itlb_trans_valid = trans_active & itlb_valid & itlb_ready;

  // ---------------------------
  // Instruction Fetch Interface
  // ---------------------------
  // Mulitplexer using and/or as this signal is likely timing critical.
  assign inst_addr_o[PPNSize+PAGE_SHIFT-1:PAGE_SHIFT] =
      (trans_active & itlb_pa)
    | (~trans_active & {{{AddrWidth-32}{1'b0}}, pc_q[31:PAGE_SHIFT]});
  assign inst_addr_o[PAGE_SHIFT-1:0] = pc_q[PAGE_SHIFT-1:0];
  assign inst_cacheable_o = snitch_pma_pkg::is_inside_cacheable_regions(SnitchPMACfg, inst_addr_o);
  assign inst_valid_o = ~wfi_q;

  // --------------------
  // Control
  // --------------------
  // Scoreboard: Keep track of rd dependencies (only loads at the moment)
  logic operands_ready;
  logic dst_ready;
  logic opa_ready, opb_ready, opc_ready;
  logic dstrd_ready, dstrs1_ready;
   
  always_comb begin
    sb_d = sb_q;
    if (retire_load) sb_d[lsu_rd] = 1'b0;
    // only place the reservation if we actually executed the load or offload instruction
    if ((is_load | acc_register_rd) && !stall && !exception) sb_d[rd] = 1'b1;
    if (retire_acc) sb_d[acc_prsp_i.id[RegWidth-1:0]] = 1'b0;
    if (ssr_active_q) begin
       for (int i = 0; i < NumSsrs; i++) sb_d[IntSsrRegs[i]] = 1'b0;
    end
    sb_d[0] = 1'b0;
  end

  // TODO(zarubaf): This can probably be described a bit more efficient
  assign opa_ready = (opa_select != Reg) | (~sb_q[rs1] & (~ssr_rvalid_o[0] | ssr_rready_i[0]));
  assign opb_ready = ((opb_select != Reg & opb_select != SImmediate) | 
                      (~sb_q[rs2] & (~ssr_rvalid_o[1] | ssr_rready_i[1]))) &
                     ((opb_select != RegRd) | ~sb_q[rd]);
  assign opc_ready = ((opc_select != Reg) | ~sb_q[rd]) & ((opc_select != RegRs2) | ~sb_q[rs2]);
  assign operands_ready = opa_ready & opb_ready & opc_ready;
  // either we are not using the destination register or we need to make
  // sure that its destination operand is not marked busy in the scoreboard.
  assign dstrd_ready = ~uses_rd | (uses_rd & ~sb_q[rd]);
  assign dstrs1_ready = ~uses_rs1 | (uses_rs1 & ~sb_q[rs1]);
  assign dst_ready = dstrd_ready & dstrs1_ready;

  assign valid_instr = inst_ready_i
                      & inst_valid_o
                      & operands_ready
                      & dst_ready
                      & ((itlb_valid & itlb_ready) | ~trans_active);
  // the accelerator interface stalled us
  assign acc_stall = acc_qvalid_o & ~acc_qready_i;
  // the LSU Interface didn't accept our request yet
  assign lsu_stall = lsu_tlb_qvalid & ~lsu_tlb_qready;
  // Stall the stage if we either didn't get a valid instruction or the LSU/Accelerator is not ready
  assign stall = ~valid_instr
                // The LSU is stalling.
                | lsu_stall
                // The accelerator port is stalling.
                | acc_stall
                // We are waiting on the `fence.i` flush.
                | (flush_i_valid_o & ~flush_i_ready_i)
                // We are waiting on the `fence` flush.
                | (valid_instr & (inst_data_i ==? FENCE) & ~lsu_empty);

  // --------------------
  // Instruction Frontend
  // --------------------
  assign consec_pc = pc_q + ((is_branch & alu_result[0]) ? bimm : 'd4);

  logic [31:0] npc;
  always_comb begin
    pc_d = pc_q;
    npc = pc_q; // the next PC if we wouldn't be in debug mode
    // if we got a valid instruction word increment the PC unless we are waiting for an event
    if (!stall && !wfi_q) begin
      casez (next_pc)
        Consec: npc = consec_pc;
        Alu: npc = alu_result & {{31{1'b1}}, ~zero_lsb};
        Exception: npc = {tvec_q[M], 2'b0};
        MRet: npc = epc_q[M];
        SRet: npc = epc_q[S];
        DRet: npc = dpc_q;
        default:;
      endcase
      // default update
      pc_d = npc;
      // debug mode updates
      // if we are in debug mode, and encounter an exception go to exception address
      // the only exception is EBREAK which terminates the program buffer.
      if (debug_q && next_pc == Exception) begin
        pc_d = (inst_data_i == EBREAK) ?
          DmBaseAddress + dm::HaltAddress : DmBaseAddress + dm::ExceptionAddress;
      end else begin
      end
      if (!debug_q && (irq_i.debug || dcsr_q.step)) pc_d = DmBaseAddress + dm::HaltAddress;
    end
  end

  // --------------------
  // Decoder
  // --------------------
  assign rd = inst_data_i[7 + RegWidth - 1:7];
  assign rs1 = inst_data_i[15 + RegWidth - 1:15];
  assign rs2 = inst_data_i[20 + RegWidth - 1:20];

  always_comb begin
    illegal_inst = 1'b0;
    ecall = 1'b0;
    ebreak = 1'b0;
    alu_op = Add;
    opa_select = None;
    opb_select = None;
    opc_select = None;

    flush_i_valid_o = 1'b0;
    tlb_flush = 1'b0;
    next_pc = Consec;

    rd_select = RdAlu;
    write_rd = 1'b1;
    // if we are writing the field this cycle we need
    // an int destination register
    uses_rd = write_rd;
    // set up rs1 destination
    write_rs1 = 1'b0;
    uses_rs1 = write_rs1;

    rd_bypass = '0;
    zero_lsb = 1'b0;
    is_branch = 1'b0;
    // LSU interface
    is_load = 1'b0;
    is_store = 1'b0;
    is_postincr = 1'b0;
    is_fp_load = 1'b0;
    is_fp_store = 1'b0;
    is_signed = 1'b0;
    ls_size = Byte;
    ls_amo = reqrsp_pkg::AMONone;

    acc_qvalid_o = 1'b0;
    acc_qreq_o.addr = FP_SS;
    acc_register_rd = 1'b0;
    acc_opc_sel = 1'b0;

    is_fp_ssr = 1'b0;
    is_int_ssr = 1'b0;

    debug_d = (!debug_q && (
          // the external debugger or an ebreak instruction triggerd the
          // request to debug.
          irq_i.debug ||
          // We encountered an ebreak and the default ebreak behaviour is switched off
          (dcsr_q.ebreakm && inst_data_i == EBREAK) ||
          // This was a single-step
          dcsr_q.step)
        ) ? valid_instr : debug_q;

    csr_en = 1'b0;
    // Debug request and wake up are possibilties to move out of
    // the low power state.
    wfi_d = (irq_i.debug || debug_q || any_interrupt_pending) ? 1'b0 : wfi_q;

    unique casez (inst_data_i)
      ADD: begin
        opa_select = Reg;
        opb_select = Reg;
      end
      ADDI: begin
        opa_select = Reg;
        opb_select = IImmediate;
      end
      SUB: begin
        alu_op = Sub;
        opa_select = Reg;
        opb_select = Reg;
      end
      XOR: begin
        opa_select = Reg;
        opb_select = Reg;
        alu_op = LXor;
      end
      XORI: begin
        alu_op = LXor;
        opa_select = Reg;
        opb_select = IImmediate;
      end
      OR: begin
        opa_select = Reg;
        opb_select = Reg;
        alu_op = LOr;
      end
      ORI: begin
        alu_op = LOr;
        opa_select = Reg;
        opb_select = IImmediate;
      end
      AND: begin
        alu_op = LAnd;
        opa_select = Reg;
        opb_select = Reg;
      end
      ANDI: begin
        alu_op = LAnd;
        opa_select = Reg;
        opb_select = IImmediate;
      end
      SLT: begin
        alu_op = Slt;
        opa_select = Reg;
        opb_select = Reg;
      end
      SLTI: begin
        alu_op = Slt;
        opa_select = Reg;
        opb_select = IImmediate;
      end
      SLTU: begin
        alu_op = Sltu;
        opa_select = Reg;
        opb_select = Reg;
      end
      SLTIU: begin
        alu_op = Sltu;
        opa_select = Reg;
        opb_select = IImmediate;
      end
      SLL: begin
        alu_op = Sll;
        opa_select = Reg;
        opb_select = Reg;
      end
      SRL: begin
        alu_op = Srl;
        opa_select = Reg;
        opb_select = Reg;
      end
      SRA: begin
        alu_op = Sra;
        opa_select = Reg;
        opb_select = Reg;
      end
      SLLI: begin
        alu_op = Sll;
        opa_select = Reg;
        opb_select = IImmediate;
      end
      SRLI: begin
        alu_op = Srl;
        opa_select = Reg;
        opb_select = IImmediate;
      end
      SRAI: begin
        alu_op = Sra;
        opa_select = Reg;
        opb_select = IImmediate;
      end
      LUI: begin
        opa_select = None;
        opb_select = None;
        rd_select = RdBypass;
        rd_bypass = uimm;
      end
      AUIPC: begin
        opa_select = UImmediate;
        opb_select = PC;
      end
      JAL: begin
        rd_select = RdConsecPC;
        opa_select = JImmediate;
        opb_select = PC;
        next_pc = Alu;
      end
      JALR: begin
        rd_select = RdConsecPC;
        opa_select = Reg;
        opb_select = IImmediate;
        next_pc = Alu;
        zero_lsb = 1'b1;
      end
      // use the ALU for comparisons
      BEQ: begin
        is_branch = 1'b1;
        write_rd = 1'b0;
        alu_op = Eq;
        opa_select = Reg;
        opb_select = Reg;
      end
      BNE: begin
        is_branch = 1'b1;
        write_rd = 1'b0;
        alu_op = Neq;
        opa_select = Reg;
        opb_select = Reg;
      end
      BLT: begin
        is_branch = 1'b1;
        write_rd = 1'b0;
        alu_op = Slt;
        opa_select = Reg;
        opb_select = Reg;
      end
      BLTU: begin
        is_branch = 1'b1;
        write_rd = 1'b0;
        alu_op = Sltu;
        opa_select = Reg;
        opb_select = Reg;
      end
      BGE: begin
        is_branch = 1'b1;
        write_rd = 1'b0;
        alu_op = Ge;
        opa_select = Reg;
        opb_select = Reg;
      end
      BGEU: begin
        is_branch = 1'b1;
        write_rd = 1'b0;
        alu_op = Geu;
        opa_select = Reg;
        opb_select = Reg;
      end
      // Load/Stores
      SB: begin
        write_rd = 1'b0;
        is_store = 1'b1;
        opa_select = Reg;
        opb_select = SImmediate;
      end
      SH: begin
        write_rd = 1'b0;
        is_store = 1'b1;
        ls_size = HalfWord;
        opa_select = Reg;
        opb_select = SImmediate;
      end
      SW: begin
        write_rd = 1'b0;
        is_store = 1'b1;
        ls_size = Word;
        opa_select = Reg;
        opb_select = SImmediate;
      end
      LB: begin
        write_rd = 1'b0;
        uses_rd = 1'b1;
        is_load = 1'b1;
        is_signed = 1'b1;
        opa_select = Reg;
        opb_select = IImmediate;
      end
      LH: begin
        write_rd = 1'b0;
        uses_rd = 1'b1;
        is_load = 1'b1;
        is_signed = 1'b1;
        ls_size = HalfWord;
        opa_select = Reg;
        opb_select = IImmediate;
      end
      LW: begin
        write_rd = 1'b0;
        uses_rd = 1'b1;
        is_load = 1'b1;
        is_signed = 1'b1;
        ls_size = Word;
        opa_select = Reg;
        opb_select = IImmediate;
      end
      LBU: begin
        write_rd = 1'b0;
        uses_rd = 1'b1;
        is_load = 1'b1;
        opa_select = Reg;
        opb_select = IImmediate;
      end
      LHU: begin
        write_rd = 1'b0;
        uses_rd = 1'b1;
        is_load = 1'b1;
        ls_size = HalfWord;
        opa_select = Reg;
        opb_select = IImmediate;
      end
      // CSR Instructions
      CSRRW: begin // Atomic Read/Write CSR
        opa_select = Reg;
        opb_select = None;
        rd_select = RdBypass;
        rd_bypass = csr_rvalue;
        csr_en = valid_instr;
      end
      CSRRWI: begin
        opa_select = CSRImmmediate;
        opb_select = None;
        rd_select = RdBypass;
        rd_bypass = csr_rvalue;
        csr_en = valid_instr;
      end
      CSRRS: begin  // Atomic Read and Set Bits in CSR
          alu_op = LOr;
          opa_select = Reg;
          opb_select = CSR;
          rd_select = RdBypass;
          rd_bypass = csr_rvalue;
          csr_en = valid_instr;
      end
      CSRRSI: begin
        // offload CSR enable to FP SS
        if (inst_data_i[31:20] != CSR_SSR) begin
          alu_op = LOr;
          opa_select = CSRImmmediate;
          opb_select = CSR;
          rd_select = RdBypass;
          rd_bypass = csr_rvalue;
          csr_en = valid_instr;
          if (inst_data_i[31:20] == CSR_INT_SSR) begin
            is_int_ssr = 1'b1;
          end
        end else begin
          write_rd = 1'b0;
          acc_qvalid_o = valid_instr;
          is_fp_ssr = 1'b1;
        end
      end
       /* if (inst_data_i[31:20] == CSR_INT_SSR) begin
          if (!ssr_track_q) begin
            alu_op = LOr;
            opa_select = CSRImmmediate;
            opb_select = CSR;
            rd_select = RdBypass;
            rd_bypass = csr_rvalue;
            csr_en = valid_instr;
          end else begin
            illegal_inst = 1'b1;
          end
        end else if (inst_data_i[31:20] == CSR_SSR) begin
          write_rd = 1'b0;
          acc_qvalid_o = valid_instr;
          ssr_track_d = 1'b1;
          ssr_pending_d = 1'b1;
        end else begin
          alu_op = LOr;
          opa_select = CSRImmmediate;
          opb_select = CSR;
          rd_select = RdBypass;
          rd_bypass = csr_rvalue;
          csr_en = valid_instr;
        end  */
      CSRRC: begin // Atomic Read and Clear Bits in CSR
        alu_op = LNAnd;
        opa_select = Reg;
        opb_select = CSR;
        rd_select = RdBypass;
        rd_bypass = csr_rvalue;
        csr_en = valid_instr;
      end
      CSRRCI: begin
        if (inst_data_i[31:20] != CSR_SSR) begin
          alu_op = LNAnd;
          opa_select = CSRImmmediate;
          opb_select = CSR;
          rd_select = RdBypass;
          rd_bypass = csr_rvalue;
          csr_en = valid_instr;
        end else begin
          write_rd = 1'b0;
          acc_qvalid_o = valid_instr;
        end
      end
      ECALL: ecall = 1'b1;
      EBREAK: ebreak = 1'b1;
      // Environment return
      SRET: begin
        write_rd = 1'b0;
        if (priv_lvl_q inside {snitch_pkg::PrivLvlM, snitch_pkg::PrivLvlS}) next_pc = SRet;
        else illegal_inst = 1'b1;
      end
      MRET: begin
        write_rd = 1'b0;
        if (priv_lvl_q inside {snitch_pkg::PrivLvlM}) next_pc = MRet;
        else illegal_inst = 1'b1;
      end
      DRET: begin
        if (!debug_q) begin
          illegal_inst = 1'b1;
        end else begin
          next_pc = DRet;
          uses_rd = 1'b0;
          debug_d = ~valid_instr;
        end
      end
      // Decode as NOP
      FENCE: begin
        write_rd = 1'b0;
      end
      FENCE_I: begin
        flush_i_valid_o = valid_instr;
      end
      SFENCE_VMA: begin
        if (priv_lvl_q == PrivLvlU) illegal_inst = 1'b1;
        else tlb_flush = valid_instr;
      end
      WFI: begin
        if (priv_lvl_q == PrivLvlU) illegal_inst = 1'b1;
        else if (!debug_q && valid_instr) wfi_d = 1'b1;
      end
      // Atomics
      AMOADD_W: begin
        alu_op = BypassA;
        write_rd = 1'b0;
        uses_rd = 1'b1;
        is_load = 1'b1;
        is_signed = 1'b1;
        ls_size = Word;
        ls_amo = reqrsp_pkg::AMOAdd;
        opa_select = Reg;
        opb_select = Reg;
      end
      AMOXOR_W: begin
        alu_op = BypassA;
        write_rd = 1'b0;
        uses_rd = 1'b1;
        is_load = 1'b1;
        is_signed = 1'b1;
        ls_size = Word;
        ls_amo = reqrsp_pkg::AMOXor;
        opa_select = Reg;
        opb_select = Reg;
      end
      AMOOR_W: begin
        alu_op = BypassA;
        write_rd = 1'b0;
        uses_rd = 1'b1;
        is_load = 1'b1;
        is_signed = 1'b1;
        ls_size = Word;
        ls_amo = reqrsp_pkg::AMOOr;
        opa_select = Reg;
        opb_select = Reg;
      end
      AMOAND_W: begin
        alu_op = BypassA;
        write_rd = 1'b0;
        uses_rd = 1'b1;
        is_load = 1'b1;
        is_signed = 1'b1;
        ls_size = Word;
        ls_amo = reqrsp_pkg::AMOAnd;
        opa_select = Reg;
        opb_select = Reg;
      end
      AMOMIN_W: begin
        alu_op = BypassA;
        write_rd = 1'b0;
        uses_rd = 1'b1;
        is_load = 1'b1;
        is_signed = 1'b1;
        ls_size = Word;
        ls_amo = reqrsp_pkg::AMOMin;
        opa_select = Reg;
        opb_select = Reg;
      end
      AMOMAX_W: begin
        alu_op = BypassA;
        write_rd = 1'b0;
        uses_rd = 1'b1;
        is_load = 1'b1;
        is_signed = 1'b1;
        ls_size = Word;
        ls_amo = reqrsp_pkg::AMOMax;
        opa_select = Reg;
        opb_select = Reg;
      end
      AMOMINU_W: begin
        alu_op = BypassA;
        write_rd = 1'b0;
        uses_rd = 1'b1;
        is_load = 1'b1;
        is_signed = 1'b1;
        ls_size = Word;
        ls_amo = reqrsp_pkg::AMOMinu;
        opa_select = Reg;
        opb_select = Reg;
      end
      AMOMAXU_W: begin
        alu_op = BypassA;
        write_rd = 1'b0;
        uses_rd = 1'b1;
        is_load = 1'b1;
        is_signed = 1'b1;
        ls_size = Word;
        ls_amo = reqrsp_pkg::AMOMaxu;
        opa_select = Reg;
        opb_select = Reg;
      end
      AMOSWAP_W: begin
        alu_op = BypassA;
        write_rd = 1'b0;
        uses_rd = 1'b1;
        is_load = 1'b1;
        is_signed = 1'b1;
        ls_size = Word;
        ls_amo = reqrsp_pkg::AMOSwap;
        opa_select = Reg;
        opb_select = Reg;
      end
      LR_W: begin
        alu_op = BypassA;
        write_rd = 1'b0;
        uses_rd = 1'b1;
        is_load = 1'b1;
        is_signed = 1'b1;
        ls_size = Word;
        ls_amo = reqrsp_pkg::AMOLR;
        opa_select = Reg;
        opb_select = Reg;
      end
      SC_W: begin
        alu_op = BypassA;
        write_rd = 1'b0;
        uses_rd = 1'b1;
        is_load = 1'b1;
        is_signed = 1'b1;
        ls_size = Word;
        ls_amo = reqrsp_pkg::AMOSC;
        opa_select = Reg;
        opb_select = Reg;
      end
      // Off-load to shared multiplier
      MUL,
      MULH,
      MULHSU,
      MULHU,
      DIV,
      DIVU,
      REM,
      REMU,
      MULW,
      DIVW,
      DIVUW,
      REMW,
      REMUW: begin
        write_rd = 1'b0;
        uses_rd = 1'b1;
        acc_qvalid_o = valid_instr;
        opa_select = Reg;
        opb_select = Reg;
        acc_register_rd = 1'b1;
        acc_qreq_o.addr = SHARED_MULDIV;
      end
      // Off-loaded to IPU
      ANDN, ORN, XNOR, SLO, SRO, ROL, ROR, SBCLR, SBSET, SBINV, SBEXT,
      GORC, GREV, CLZ, CTZ, PCNT, SEXT_B,
      SEXT_H, CRC32_B, CRC32_H, CRC32_W, CRC32C_B, CRC32C_H, CRC32C_W,
      CLMUL, CLMULR, CLMULH, MIN, MAX, MINU, MAXU, SHFL, UNSHFL, BEXT,
      BDEP, PACK, PACKU, PACKH, BFP: begin
        write_rd = 1'b0;
        uses_rd = 1'b1;
        acc_qvalid_o = valid_instr;
        opa_select = Reg;
        opb_select = Reg;
        acc_register_rd = 1'b1;
        acc_qreq_o.addr = INT_SS;
      end
      SLOI, SROI, RORI, SBCLRI, SBSETI, SBINVI, SBEXTI, GORCI,
      GREVI, SHFLI, UNSHFLI: begin
        write_rd = 1'b0;
        uses_rd = 1'b1;
        acc_qvalid_o = valid_instr;
        opa_select = Reg;
        opb_select = IImmediate;
        acc_register_rd = 1'b1;
        acc_qreq_o.addr = INT_SS;
      end
      IADDI, ISLLI, ISLTI, ISLTIU, IXORI, ISRLI, ISRAI, IORI, IANDI, IADD,
      ISUB, ISLL, ISLT, ISLTU, IXOR, ISRL, ISRA, IOR, IAND,
      IAND, IMADD, IMSUB, INMSUB, INMADD, IMUL, IMULH, IMULHSU, IMULHU,
      IANDN, IORN, IXNOR, ISLO, ISRO, IROL, IROR, ISBCLR, ISBSET, ISBINV,
      ISBEXT, IGORC, IGREV, ISLOI, ISROI, IRORI, ISBCLRI, ISBSETI, ISBINVI,
      ISBEXTI, IGORCI, IGREVI, ICLZ, ICTZ, IPCNT, ISEXT_B, ISEXT_H, ICRC32_B,
      ICRC32_H, ICRC32_W, ICRC32C_B, ICRC32C_H, ICRC32C_W, ICLMUL, ICLMULR,
      ICLMULH, IMIN, IMAX, IMINU, IMAXU, ISHFL, IUNSHFL, IBEXT, IBDEP, IPACK,
      IPACKU, IPACKH, IBFP: begin
        if (Xipu) begin
          acc_qreq_o.addr = INT_SS;
          write_rd = 1'b0;
          acc_qvalid_o = valid_instr;
        end else begin
          illegal_inst = 1'b1;
        end
      end
      IMV_X_W: begin
        if (Xipu) begin
          acc_qreq_o.addr = INT_SS;
          write_rd = 1'b0;
          uses_rd = 1'b1;
          acc_qvalid_o = valid_instr;
          acc_register_rd = 1'b1; // No RS in GPR but RD in GPR, register in int scoreboard
        end else begin
          illegal_inst = 1'b1;
        end
      end
      IMV_W_X: begin
        if (Xipu) begin
          acc_qreq_o.addr = INT_SS;
          opa_select = Reg;
          write_rd = 1'b0;
          acc_qvalid_o = valid_instr;
        end else begin
          illegal_inst = 1'b1;
        end
      end
      IREP: begin
        if (Xipu) begin
          acc_qreq_o.addr = INT_SS;
          opa_select = Reg;
          write_rd = 1'b0;
          acc_qvalid_o = valid_instr;
        end else begin
          illegal_inst = 1'b1;
        end
      end

      /* Xpulpimg extension */
      // Post-increment loads/stores
      /*
      P_LB_IRPOST: begin // Xpulpimg: p.lb rd, iimm(rs1!)
         if (Xipu) begin
            write_rd = 1'b0;
            uses_rd = 1'b1;
            write_rs1 = 1'b1;
            is_load = 1'b1;
            is_postincr = 1'b1;
            is_signed = 1'b1;
            opa_select = Reg;
            opb_select = IImmediate;
         end else begin
            illegal_inst = 1'b1;
         end
      end
      P_LBU_IRPOST: begin // Xpulpimg: p.lbu
         if (Xipu) begin
            write_rd = 1'b0;
            uses_rd = 1'b1;
            write_rs1 = 1'b1;
            is_load = 1'b1;
            is_postincr = 1'b1;
            opa_select = Reg;
            opb_select = IImmediate;
         end else begin
            illegal_inst = 1'b1;
         end
      end
      P_LH_IRPOST: begin // Xpulpimg: p.lh
         if (Xipu) begin
            write_rd = 1'b0;
            uses_rd = 1'b1;
            write_rs1 = 1'b1;
            is_load = 1'b1;
            is_postincr = 1'b1;
            is_signed = 1'b1;
            ls_size = HalfWord;
            opa_select = Reg;
            opb_select = IImmediate;
         end else begin
            illegal_inst = 1'b1;
         end
      end
      P_LHU_IRPOST: begin // Xpulpimg: p.lhu
         if (Xipu) begin
            write_rd = 1'b0;
            uses_rd = 1'b1;
            write_rs1 = 1'b1;
            is_load = 1'b1;
            is_postincr = 1'b1;
            ls_size = HalfWord;
            opa_select = Reg;
            opb_select = IImmediate;
         end else begin
            illegal_inst = 1'b1;
         end
      end
      P_LW_IRPOST: begin // Xpulpimg: p.lw
         if (Xipu) begin
            write_rd = 1'b0;
            uses_rd = 1'b1;
            write_rs1 = 1'b1;
            is_load = 1'b1;
            is_postincr = 1'b1;
            is_signed = 1'b1;
            ls_size = Word;
            opa_select = Reg;
            opb_select = IImmediate;
         end else begin
            illegal_inst = 1'b1;
         end
      end
      P_LB_RRPOST: begin // Xpulpimg: p.lb rd rs2(rs1!)
         if (Xipu) begin
            write_rd = 1'b0;
            uses_rd = 1'b1;
            write_rs1 = 1'b1;
            is_load = 1'b1;
            is_postincr = 1'b1;
            is_signed = 1'b1;
            opa_select = Reg;
            opb_select = Reg;
         end else begin
            illegal_inst = 1'b1;
         end
      end
      P_LBU_RRPOST: begin // Xpulpimg: p.lbu
         if (Xipu) begin
            write_rd = 1'b0;
            uses_rd = 1'b1;
            write_rs1 = 1'b1;
            is_load = 1'b1;
            is_postincr = 1'b1;
            opa_select = Reg;
            opb_select = Reg;
         end else begin
            illegal_inst = 1'b1;
         end
      end
      P_LH_RRPOST: begin // Xpulpimg: p.lh
         if (Xipu) begin
            write_rd = 1'b0;
            uses_rd = 1'b1;
            write_rs1 = 1'b1;
            is_load = 1'b1;
            is_postincr = 1'b1;
            is_signed = 1'b1;
            ls_size = HalfWord;
            opa_select = Reg;
            opb_select = Reg;
         end else begin 
            illegal_inst = 1'b1;
         end
      end
      P_LHU_RRPOST: begin // Xpulpimg: p.lhu
         if (Xipu) begin
            write_rd = 1'b0;
            uses_rd = 1'b1;
            write_rs1 = 1'b1;
            is_load = 1'b1;
            is_postincr = 1'b1;
            ls_size = HalfWord;
            opa_select = Reg;
            opb_select = Reg;
         end else begin
            illegal_inst = 1'b1;
         end
      end
      P_LW_RRPOST: begin // Xpulpimg: p.lw
         if (Xipu) begin
            write_rd = 1'b0;
            uses_rd = 1'b1;
            write_rs1 = 1'b1;
            is_load = 1'b1;
            is_postincr = 1'b1;
            is_signed = 1'b1;
            ls_size = Word;
            opa_select = Reg;
            opb_select = Reg;
         end else begin 
            illegal_inst = 1'b1;
         end
      end
      P_LB_RR: begin // Xpulpimg: p.lb rd,rs2(rs1)
         if (Xipu) begin
            write_rd = 1'b0;
            uses_rd = 1'b1;
            is_load = 1'b1;
            is_signed = 1'b1;
            opa_select = Reg;
            opb_select = Reg;
         end else begin
            illegal_inst = 1'b1;
         end
      end
      P_LBU_RR: begin // Xpulpimg: p.lbu
         if (Xipu) begin
            write_rd = 1'b0;
            uses_rd = 1'b1;
            is_load = 1'b1;
            opa_select = Reg;
            opb_select = Reg;
         end else begin
            illegal_inst = 1'b1;
         end
      end
      P_LH_RR: begin // Xpulpimg: p.lh
         if (Xipu) begin
            write_rd = 1'b0;
            uses_rd = 1'b1;
            is_load = 1'b1;
            is_signed = 1'b1;
            ls_size = HalfWord;
            opa_select = Reg;
            opb_select = Reg;
         end else begin
            illegal_inst = 1'b1;
         end
      end
      P_LHU_RR: begin // Xpulpimg: p.lhu
         if (Xipu) begin
            write_rd = 1'b0;
            uses_rd = 1'b1;
            is_load = 1'b1;
            ls_size = HalfWord;
            opa_select = Reg;
            opb_select = Reg;
         end else begin
            illegal_inst = 1'b1;
         end
      end      
      P_LW_RR: begin // Xpulpimg: p.lw
         if (Xipu) begin
            write_rd = 1'b0;
            uses_rd = 1'b1;
            is_load = 1'b1;
            is_signed = 1'b1;
            ls_size = Word;
            opa_select = Reg;
            opb_select = Reg;
         end else begin
            illegal_inst = 1'b1;
         end
      end
      */
      /*
      P_SB_IRPOST: begin // Xpulpimg: p.sb rs2, simm(rs1!)        
         if (Xipu) begin
            write_rd = 1'b0;
            write_rs1 = 1'b1;
            is_store = 1'b1;
            is_postincr = 1'b1;
            opa_select = Reg;
            opb_select = SImmediate;
         end else begin
            illegal_inst = 1'b1;
         end
      end
      P_SH_IRPOST: begin // Xpulpimg: p.sh
         if (Xipu) begin
            write_rd = 1'b0;
            write_rs1 = 1'b1;
            is_store = 1'b1;
            is_postincr = 1'b1;
            ls_size = HalfWord;
            opa_select = Reg;
            opb_select = SImmediate;
         end else begin
            illegal_inst = 1'b1;
         end
      end
      P_SW_IRPOST: begin // Xpulpimg: p.sw
         if (Xipu) begin
            write_rd = 1'b0;
            write_rs1 = 1'b1;
            is_store = 1'b1;
            is_postincr = 1'b1;
            ls_size = Word;
            opa_select = Reg;
            opb_select = SImmediate;
         end else begin
            illegal_inst = 1'b1;
         end
      end
      P_SB_RRPOST: begin // Xpulpimg: p.sb rs2,rs3(rs1!)
         if (Xipu) begin
            write_rd = 1'b0;
            write_rs1 = 1'b1;
            is_store = 1'b1;
            is_postincr = 1'b1;
            opa_select = Reg; // rs1 base address
            opb_select = RegRd; // rs3 (i.e. rd) offset
            opc_select = RegRs2; // rs2 source data
         end else begin
            illegal_inst = 1'b1;
         end
      end
      P_SH_RRPOST: begin // Xpulpimg: p.sh
         if (Xipu) begin
            write_rd = 1'b0;
            write_rs1 = 1'b1;
            is_store = 1'b1;
            is_postincr = 1'b1;
            ls_size = HalfWord;
            opa_select = Reg;
            opb_select = RegRd;
            opc_select = RegRs2;
         end else begin
            illegal_inst = 1'b1;
         end
      end
      P_SW_RRPOST: begin // Xpulpimg: p.sw
         if (Xipu) begin
            write_rd = 1'b0;
            write_rs1 = 1'b1;
            is_store = 1'b1;
            is_postincr = 1'b1;
            ls_size = Word;
            opa_select = Reg;
            opb_select = RegRd;
            opc_select = RegRs2;
         end else begin
            illegal_inst = 1'b1;
         end
      end
      P_SB_RR: begin // Xpulpimg: p.sb rs2, rs3(rs1)
         if (Xipu) begin
            write_rd = 1'b0;
            is_store = 1'b1;
            opa_select = Reg;
            opb_select = RegRd;
            opc_select = RegRs2;
         end else begin
            illegal_inst = 1'b1;
         end
      end
      P_SH_RR: begin // Xpulpimg: p.sh
         if (Xipu) begin
            write_rd = 1'b0;
            is_store = 1'b1;
            ls_size = HalfWord;
            opa_select = Reg;
            opb_select = RegRd;
            opc_select = RegRs2;
         end else begin
            illegal_inst = 1'b1;
         end
      end
      P_SW_RR: begin // Xpulpimg: p.sw
         if (Xipu) begin
            write_rd = 1'b0;
            is_store = 1'b1;
            ls_size = Word;
            opa_select = Reg;
            opb_select = RegRd;
            opc_select = RegRs2;
         end else begin
            illegal_inst = 1'b1;
         end
      end
      */
      // Immediate branching
      P_BEQIMM: begin // Xpulpimg: p.beqimm
         if (Xipu) begin
            is_branch = 1'b1;
            write_rd = 1'b0;
            alu_op = Eq;
            opa_select = Reg;
            opb_select = PBImmediate;
         end else begin
            illegal_inst = 1'b1;
         end
      end
      P_BNEIMM: begin // Xpulpimg: p.bneimm
         if (Xipu) begin
            is_branch = 1'b1;
            write_rd = 1'b0;
            alu_op = Neq;
            opa_select = Reg;
            opb_select = PBImmediate;
         end else begin
            illegal_inst = 1'b1;
         end
      end          
      // Offload to IPU coprocessor
      // 1 source register (rs1)
      P_ABS,                // Xpulpimg: p.abs
      P_EXTHS,              // Xpulpimg: p.exths
      P_EXTHZ,              // Xpulpimg: p.exthz
      P_EXTBS,              // Xpulpimg: p.extbs
      P_EXTBZ,              // Xpulpimg: p.extbz
      P_CLIP,               // Xpulpimg: p.clip
      P_CLIPU,              // Xpulpimg: p.clipu
      PV_ADD_SCI_H,         // Xpulpimg: pv.add.sci.h
      PV_ADD_SCI_B,         // Xpulpimg: pv.add.sci.b
      PV_SUB_SCI_H,         // Xpulpimg: pv.sub.sci.h
      PV_SUB_SCI_B,         // Xpulpimg: pv.sub.sci.b
      PV_AVG_SCI_H,         // Xpulpimg: pv.avg.sci.h
      PV_AVG_SCI_B,         // Xpulpimg: pv.avg.sci.b
      PV_AVGU_SCI_H,        // Xpulpimg: pv.avgu.sci.h
      PV_AVGU_SCI_B,        // Xpulpimg: pv.avgu.sci.b
      PV_MIN_SCI_H,         // Xpulpimg: pv.min.sci.h
      PV_MIN_SCI_B,         // Xpulpimg: pv.min.sci.b
      PV_MINU_SCI_H,        // Xpulpimg: pv.minu.sci.h
      PV_MINU_SCI_B,        // Xpulpimg: pv.minu.sci.b
      PV_MAX_SCI_H,         // Xpulpimg: pv.max.sci.h
      PV_MAX_SCI_B,         // Xpulpimg: pv.max.sci.b
      PV_MAXU_SCI_H,        // Xpulpimg: pv.maxu.sci.h
      PV_MAXU_SCI_B,        // Xpulpimg: pv.maxu.sci.b
      PV_SRL_SCI_H,         // Xpulpimg: pv.srl.sci.h
      PV_SRL_SCI_B,         // Xpulpimg: pv.srl.sci.b
      PV_SRA_SCI_H,         // Xpulpimg: pv.sra.sci.h
      PV_SRA_SCI_B,         // Xpulpimg: pv.sra.sci.b
      PV_SLL_SCI_H,         // Xpulpimg: pv.sll.sci.h
      PV_SLL_SCI_B,         // Xpulpimg: pv.sll.sci.b
      PV_OR_SCI_H,          // Xpulpimg: pv.or.sci.h
      PV_OR_SCI_B,          // Xpulpimg: pv.or.sci.b
      PV_XOR_SCI_H,         // Xpulpimg: pv.xor.sci.h
      PV_XOR_SCI_B,         // Xpulpimg: pv.xor.sci.b
      PV_AND_SCI_B,         // Xpulpimg: pv.and.sci.b
      PV_AND_SCI_H,         // Xpulpimg: pv.and.sci.h
      PV_ABS_H,             // Xpulpimg: pv.abs.h
      PV_ABS_B,             // Xpulpimg: pv.abs.b
      PV_ABS_N,             // Xpulpimg: pv.abs.n
      PV_EXTRACT_H,         // Xpulpimg: pv.extract.h
      PV_EXTRACT_B,         // Xpulpimg: pv.extract.b
      PV_EXTRACTU_H,        // Xpulpimg: pv.extractu.h
      PV_EXTRACTU_B,        // Xpulpimg: pv.extractu.b
      PV_DOTUP_SCI_H,       // Xpulpimg: pv.dotup.sci.h
      PV_DOTUP_SCI_B,       // Xpulpimg: pv.dotup.sci.b
      PV_DOTUSP_SCI_H,      // Xpulpimg: pv.dotusp.sci.h
      PV_DOTUSP_SCI_B,      // Xpulpimg: pv.dotusp.sci.b
      PV_DOTSP_SCI_H,       // Xpulpimg: pv.dotsp.sci.h
      PV_DOTSP_SCI_B: begin // Xpulpimg: pv.dotsp.sci.b
         if (Xipu) begin
            write_rd = 1'b0;
            uses_rd = 1'b1;
            acc_qvalid_o = valid_instr;
            opa_select = Reg;
            acc_register_rd = 1'b1;
            acc_qreq_o.addr = INT_SS;
         end else begin
            illegal_inst = 1'b1;
         end
      end

      // 2 source registers (rs1, rs2)
      P_SLET,              // Xpulpimg: p.slet
      P_SLETU,             // Xpulpimg: p.sletu
      P_MIN,               // Xpulpimg: p.min
      P_MINU,              // Xpulpimg: p.minu
      P_MAX,               // Xpulpimg: p.max
      P_MAXU,              // Xpulpimg: p.maxu
      P_CLIPR,             // Xpulpimg: p.clipr
      P_CLIPUR,            // Xpulpimg: p.clipur
      PV_ADD_H,            // Xpulpimg: pv.add.h
      PV_ADD_SC_H,         // Xpulpimg: pv.add.sc.h
      PV_ADD_B,            // Xpulpimg: pv.add.b
      PV_ADD_SC_B,         // Xpulpimg: pv.add.sc.b
      PV_ADD_N,            // Xpulpimg: pv.add.n
      PV_ADD_SC_N,         // Xpulpimg: pv.add.sc.n
      PV_SUB_H,            // Xpulpimg: pv.sub.h
      PV_SUB_SC_H,         // Xpulpimg: pv.sub.sc.h
      PV_SUB_B,            // Xpulpimg: pv.sub.b
      PV_SUB_SC_B,         // Xpulpimg: pv.sub.sc.b
      PV_SUB_N,            // Xpulpimg: pv.sub.n
      PV_SUB_SC_N,         // Xpulpimg: pv.sub.sc.n
      PV_AVG_H,            // Xpulpimg: pv.avg.h
      PV_AVG_SC_H,         // Xpulpimg: pv.avg.sc.h
      PV_AVG_B,            // Xpulpimg: pv.avg.b
      PV_AVG_SC_B,         // Xpulpimg: pv.avg.sc.b
      PV_AVG_N,            // Xpulpimg: pv.avg.n
      PV_AVG_SC_N,         // Xpulpimg: pv.avg.sc.n
      PV_AVGU_H,           // Xpulpimg: pv.avgu.h
      PV_AVGU_SC_H,        // Xpulpimg: pv.avgu.sc.h
      PV_AVGU_B,           // Xpulpimg: pv.avgu.b
      PV_AVGU_SC_B,        // Xpulpimg: pv.avgu.sc.b
      PV_AVGU_N,           // Xpulpimg: pv.avgu.n
      PV_AVGU_SC_N,        // Xpulpimg: pv.avgu.sc.n
      PV_MIN_H,            // Xpulpimg: pv.min.h
      PV_MIN_SC_H,         // Xpulpimg: pv.min.sc.h
      PV_MIN_B,            // Xpulpimg: pv.min.b
      PV_MIN_SC_B,         // Xpulpimg: pv.min.sc.b
      PV_MIN_N,            // Xpulpimg: pv.min.n
      PV_MIN_SC_N,         // Xpulpimg: pv.min.sc.n
      PV_MINU_H,           // Xpulpimg: pv.minu.h
      PV_MINU_SC_H,        // Xpulpimg: pv.minu.sc.h
      PV_MINU_B,           // Xpulpimg: pv.minu.b
      PV_MINU_SC_B,        // Xpulpimg: pv.minu.sc.b
      PV_MINU_N,           // Xpulpimg: pv.minu.n
      PV_MINU_SC_N,        // Xpulpimg: pv.minu.sc.n
      PV_MAX_H,            // Xpulpimg: pv.max.h
      PV_MAX_SC_H,         // Xpulpimg: pv.max.sc.h
      PV_MAX_B,            // Xpulpimg: pv.max.b
      PV_MAX_SC_B,         // Xpulpimg: pv.max.sc.b
      PV_MAX_N,            // Xpulpimg: pv.max.n
      PV_MAX_SC_N,         // Xpulpimg: pv.max.sc.n
      PV_MAXU_H,           // Xpulpimg: pv.maxu.h
      PV_MAXU_SC_H,        // Xpulpimg: pv.maxu.sc.h
      PV_MAXU_B,           // Xpulpimg: pv.maxu.b
      PV_MAXU_SC_B,        // Xpulpimg: pv.maxu.sc.b
      PV_MAXU_N,           // Xpulpimg: pv.maxu.n
      PV_MAXU_SC_N,        // Xpulpimg: pv.maxu.sc.n
      PV_SRL_H,            // Xpulpimg: pv.srl.h
      PV_SRL_SC_H,         // Xpulpimg: pv.srl.sc.h
      PV_SRL_B,            // Xpulpimg: pv.srl.b
      PV_SRL_SC_B,         // Xpulpimg: pv.srl.sc.b
      PV_SRL_N,            // Xpulpimg: pv.srl.n
      PV_SRL_SC_N,         // Xpulpimg: pv.srl.sc.n
      PV_SRA_H,            // Xpulpimg: pv.sra.h
      PV_SRA_SC_H,         // Xpulpimg: pv.sra.sc.h
      PV_SRA_B,            // Xpulpimg: pv.sra.b
      PV_SRA_SC_B,         // Xpulpimg: pv.sra.sc.b
      PV_SRA_N,            // Xpulpimg: pv.sra.n
      PV_SRA_SC_N,         // Xpulpimg: pv.sra.sc.n
      PV_SLL_H,            // Xpulpimg: pv.sll.h
      PV_SLL_SC_H,         // Xpulpimg: pv.sll.sc.h
      PV_SLL_B,            // Xpulpimg: pv.sll.b
      PV_SLL_SC_B,         // Xpulpimg: pv.sll.sc.b
      PV_SLL_N,            // Xpulpimg: pv.sll.n
      PV_SLL_SC_N,         // Xpulpimg: pv.sll.sc.n
      PV_OR_H,             // Xpulpimg: pv.or.h
      PV_OR_SC_H,          // Xpulpimg: pv.or.sc.h
      PV_OR_B,             // Xpulpimg: pv.or.b
      PV_OR_SC_B,          // Xpulpimg: pv.or.sc.b
      PV_OR_N,             // Xpulpimg: pv.or.n
      PV_OR_SC_N,          // Xpulpimg: pv.or.sc.n
      PV_XOR_H,            // Xpulpimg: pv.xor.h
      PV_XOR_SC_H,         // Xpulpimg: pv.xor.sc.h
      PV_XOR_B,            // Xpulpimg: pv.xor.b
      PV_XOR_SC_B,         // Xpulpimg: pv.xor.sc.b
      PV_XOR_N,            // Xpulpimg: pv.xor.n
      PV_XOR_SC_N,         // Xpulpimg: pv.xor.sc.n
      PV_AND_H,            // Xpulpimg: pv.and.h
      PV_AND_SC_H,         // Xpulpimg: pv.and.sc.h
      PV_AND_B,            // Xpulpimg: pv.and.b
      PV_AND_SC_B,         // Xpulpimg: pv.and.sc.b
      PV_AND_N,            // Xpulpimg: pv.and.n
      PV_AND_SC_N,         // Xpulpimg: pv.and.sc.n
      PV_DOTUP_H,          // Xpulpimg: pv.dotup.h
      PV_DOTUP_SC_H,       // Xpulpimg: pv.dotup.sc.h
      PV_DOTUP_B,          // Xpulpimg: pv.dotup.b
      PV_DOTUP_SC_B,       // Xpulpimg: pv.dotup.sc.b
      PV_DOTUP_N,          // Xpulpimg: pv.dotup.n
      PV_DOTUP_SC_N,       // Xpulpimg: pv.dotup.sc.n
      PV_DOTUSP_H,         // Xpulpimg: pv.dotusp.h
      PV_DOTUSP_SC_H,      // Xpulpimg: pv.dotusp.sc.h
      PV_DOTUSP_B,         // Xpulpimg: pv.dotusp.b
      PV_DOTUSP_SC_B,      // Xpulpimg: pv.dotusp.sc.b
      PV_DOTUSP_N,         // Xpulpimg: pv.dotusp.n
      PV_DOTUSP_SC_N,      // Xpulpimg: pv.dotusp.sc.n
      PV_DOTSP_H,          // Xpulpimg: pv.dotsp.h
      PV_DOTSP_SC_H,       // Xpulpimg: pv.dotsp.sc.h
      PV_DOTSP_B,          // Xpulpimg: pv.dotsp.b
      PV_DOTSP_SC_B,       // Xpulpimg: pv.dotsp.sc.b
      PV_DOTSP_N,          // Xpulpimg: pv.dotsp.n
      PV_DOTSP_SC_N: begin       // Xpulpimg: pv.dotsp.sc.n
         if (Xipu) begin
            write_rd = 1'b0;
            uses_rd = 1'b1;
            acc_qvalid_o = valid_instr;
            opa_select = Reg;
            opb_select = Reg;
            acc_register_rd = 1'b1;
            acc_qreq_o.addr = INT_SS;
         end else begin
            illegal_inst = 1'b1;
         end
      end

      // 2 source registers (rs1, rd)
      PV_INSERT_H,           // Xpulpimg: pv.insert.h
      PV_INSERT_B,           // Xpulpimg: pv.insert.b
      PV_SDOTUP_SCI_H,       // Xpulpimg: pv.sdotup.sci.h
      PV_SDOTUP_SCI_B,       // Xpulpimg: pv.sdotup.sci.b
      PV_SDOTUSP_SCI_H,      // Xpulpimg: pv.sdotusp.sci.h
      PV_SDOTUSP_SCI_B,      // Xpulpimg: pv.sdotusp.sci.b
      PV_SDOTSP_SCI_H,       // Xpulpimg: pv.sdotsp.sci.h
      PV_SDOTSP_SCI_B: begin // Xpulpimg: pv.sdotsp.sci.b
         if (Xipu) begin
            write_rd = 1'b0;
            uses_rd = 1'b1;
            acc_qvalid_o = valid_instr;
            opa_select = Reg;
            opc_select = Reg;
            acc_register_rd = 1'b1;
            acc_qreq_o.addr = INT_SS;
            acc_opc_sel = 1'b1;
         end else begin
            illegal_inst = 1'b1;
         end
      end

      // 3 source registers (rs1, rs2, rd)
      P_MAC,                // Xpulpimg: p.mac
      P_MSU,                // Xpulpimg: p.msu
      PV_SDOTUP_H,          // Xpulpimg: pv.sdotup.h
      PV_SDOTUP_SC_H,       // Xpulpimg: pv.sdotup.sc.h
      PV_SDOTUP_B,          // Xpulpimg: pv.sdotup.b
      PV_SDOTUP_SC_B,       // Xpulpimg: pv.sdotup.sc.b
      PV_SDOTUP_N,          // Xpulpimg: pv.sdotup.n
      PV_SDOTUP_SC_N,       // Xpulpimg: pv.sdotup.sc.n
      PV_SDOTUSP_H,         // Xpulpimg: pv.sdotusp.h
      PV_SDOTUSP_SC_H,      // Xpulpimg: pv.sdotusp.sc.h
      PV_SDOTUSP_B,         // Xpulpimg: pv.sdotusp.b
      PV_SDOTUSP_SC_B,      // Xpulpimg: pv.sdotusp.sc.b
      PV_SDOTUSP_N,         // Xpulpimg: pv.sdotusp.n
      PV_SDOTUSP_SC_N,      // Xpulpimg: pv.sdotusp.sc.n
      PV_SDOTSP_H,          // Xpulpimg: pv.sdotsp.h
      PV_SDOTSP_SC_H,       // Xpulpimg: pv.sdotsp.sc.h
      PV_SDOTSP_B,          // Xpulpimg: pv.sdotsp.b
      PV_SDOTSP_SC_B,       // Xpulpimg: pv.sdotsp.sc.b
      PV_SDOTSP_N,          // Xpulpimg: pv.sdotsp.n
      PV_SDOTSP_SC_N,       // Xpulpimg: pv.sdotsp.sc.n
      PV_SHUFFLE2_H,        // Xpulpimg: pv.shuffle2.h
      PV_SHUFFLE2_B,        // Xpulpimg: pv.shuffle2.b
      PV_SHUFFLE2_N: begin  // Xpulpimg: pv.shullfe2.n
        if (Xipu) begin
          write_rd = 1'b0;
          uses_rd = 1'b1;
          acc_qvalid_o = valid_instr;
          opa_select = Reg;
          opb_select = Reg;
          opc_select = Reg;
          acc_register_rd = 1'b1;
          acc_qreq_o.addr = INT_SS;
          acc_opc_sel = 1'b1;
        end else begin
          illegal_inst = 1'b1;
        end
      end
      /* end of Xpulpimg extension */

      // Offload FP-FP Instructions - fire and forget
      // TODO (smach): Check legal rounding modes and issue illegal isn if needed
      // Single Precision Floating-Point
      FADD_S,
      FSUB_S,
      FMUL_S,
      FDIV_S,
      FSGNJ_S,
      FSGNJN_S,
      FSGNJX_S,
      FMIN_S,
      FMAX_S,
      FSQRT_S,
      FMADD_S,
      FMSUB_S,
      FNMSUB_S,
      FNMADD_S: begin
        if (FP_EN && RVF
          && (!(inst_data_i inside {FDIV_S, FSQRT_S}) || XDivSqrt)) begin
          write_rd = 1'b0;
          acc_qvalid_o = valid_instr;
        end else begin
          illegal_inst = 1'b1;
        end
      end
      // Vectors
      VFADD_S,
      VFADD_R_S,
      VFSUB_S,
      VFSUB_R_S,
      VFMUL_S,
      VFMUL_R_S,
      VFDIV_S,
      VFDIV_R_S,
      VFMIN_S,
      VFMIN_R_S,
      VFMAX_S,
      VFMAX_R_S,
      VFSQRT_S,
      VFMAC_S,
      VFMAC_R_S,
      VFMRE_S,
      VFMRE_R_S,
      VFSGNJ_S,
      VFSGNJ_R_S,
      VFSGNJN_S,
      VFSGNJN_R_S,
      VFSGNJX_S,
      VFSGNJX_R_S,
      VFCPKA_S_S,
      VFCPKA_S_D: begin
        if (FP_EN && XFVEC && RVF && RVD
            && (!(inst_data_i inside {VFDIV_S, VFDIV_R_S, VFSQRT_S}) || XDivSqrt)) begin
          write_rd = 1'b0;
          acc_qvalid_o = valid_instr;
        end else begin
          illegal_inst = 1'b1;
        end
      end
      VFSUM_S,
      VFNSUM_S: begin
        if (FP_EN && XFVEC && FLEN >= 64 && XFDOTP && RVF) begin
          write_rd = 1'b0;
          acc_qvalid_o = valid_instr;
        end else begin
          illegal_inst = 1'b1;
        end
      end
      // Double Precision Floating-Point
      FADD_D,
      FSUB_D,
      FMUL_D,
      FDIV_D,
      FSGNJ_D,
      FSGNJN_D,
      FSGNJX_D,
      FMIN_D,
      FMAX_D,
      FSQRT_D,
      FMADD_D,
      FMSUB_D,
      FNMSUB_D,
      FNMADD_D: begin
        if (FP_EN && RVD && (!(inst_data_i inside {FDIV_D, FSQRT_D}) || XDivSqrt)) begin
          write_rd = 1'b0;
          acc_qvalid_o = valid_instr;
        end else begin
          illegal_inst = 1'b1;
        end
      end
      FCVT_S_D,
      FCVT_D_S: begin
        if (FP_EN && RVF && RVD) begin
          write_rd = 1'b0;
          acc_qvalid_o = valid_instr;
        end else begin
          illegal_inst = 1'b1;
        end
      end
      // [Alt] Half Precision Floating-Point
      FADD_H,
      FSUB_H,
      FMUL_H,
      FDIV_H,
      FSQRT_H,
      FMADD_H,
      FMSUB_H,
      FNMSUB_H,
      FNMADD_H,
      FSGNJ_H,
      FSGNJN_H,
      FSGNJX_H,
      FMIN_H,
      FMAX_H: begin
        if (FP_EN && XF16 && fcsr_q.fmode.dst == 1'b0 &&
            (!(inst_data_i inside {FDIV_H, FSQRT_H}) || XDivSqrt)) begin
          write_rd = 1'b0;
          acc_qvalid_o = valid_instr;
        end else if (FP_EN && XF16ALT && fcsr_q.fmode.dst == 1'b1 &&
            (!(inst_data_i inside {VFDIV_H, VFDIV_R_H, VFSQRT_H}) || XDivSqrt)) begin
          write_rd = 1'b0;
          acc_qvalid_o = valid_instr;
        end else begin
          illegal_inst = 1'b1;
        end
      end
      FMACEX_S_H,
      FMULEX_S_H: begin
        if (FP_EN && RVF && XF16 && XFAUX) begin
          write_rd = 1'b0;
          acc_qvalid_o = valid_instr;
        end else begin
          illegal_inst = 1'b1;
        end
      end
      FCVT_S_H: begin
        if (FP_EN && RVF && XF16 && fcsr_q.fmode.src == 1'b0) begin
          write_rd = 1'b0;
          acc_qvalid_o = valid_instr;
        end else if (FP_EN && RVF && XF16ALT && fcsr_q.fmode.src == 1'b1) begin
          write_rd = 1'b0;
          acc_qvalid_o = valid_instr;
        end else begin
          illegal_inst = 1'b1;
        end
      end
      FCVT_H_S: begin
        if (FP_EN && RVF && XF16 && fcsr_q.fmode.dst == 1'b0) begin
          write_rd = 1'b0;
          acc_qvalid_o = valid_instr;
        end else if (FP_EN && RVF && XF16ALT && fcsr_q.fmode.dst == 1'b1) begin
          write_rd = 1'b0;
          acc_qvalid_o = valid_instr;
        end else begin
          illegal_inst = 1'b1;
        end
      end
      FCVT_D_H: begin
        if (FP_EN && RVD && XF16 && fcsr_q.fmode.src == 1'b0) begin
          write_rd = 1'b0;
          acc_qvalid_o = valid_instr;
        end else if (FP_EN && RVD && XF16ALT && fcsr_q.fmode.src == 1'b1) begin
          write_rd = 1'b0;
          acc_qvalid_o = valid_instr;
        end else begin
          illegal_inst = 1'b1;
        end
      end
      FCVT_H_D: begin
        if (FP_EN && RVD && XF16 && fcsr_q.fmode.dst == 1'b0) begin
          write_rd = 1'b0;
          acc_qvalid_o = valid_instr;
        end else if (FP_EN && RVD && XF16ALT && fcsr_q.fmode.dst == 1'b1) begin
          write_rd = 1'b0;
          acc_qvalid_o = valid_instr;
        end else begin
          illegal_inst = 1'b1;
        end
      end
      // FCVT_H_H: begin
      //   if (FP_EN && XF16 && XF16ALT &&
      //      (fcsr_q.fmode.src != fcsr_q.fmode.dst)) begin
      //     write_rd = 1'b0;
      //     acc_qvalid_o = valid_instr;
      //   end else begin
      //     illegal_inst = 1'b1;
      //   end
      // end

      // Vectorized [Alt] Half Precision Floating-Point
      VFADD_H,
      VFADD_R_H,
      VFSUB_H,
      VFSUB_R_H,
      VFMUL_H,
      VFMUL_R_H,
      VFDIV_H,
      VFDIV_R_H,
      VFMIN_H,
      VFMIN_R_H,
      VFMAX_H,
      VFMAX_R_H,
      VFSQRT_H,
      VFMAC_H,
      VFMAC_R_H,
      VFMRE_H,
      VFMRE_R_H,
      VFSGNJ_H,
      VFSGNJ_R_H,
      VFSGNJN_H,
      VFSGNJN_R_H,
      VFSGNJX_H,
      VFSGNJX_R_H: begin
        if (FP_EN && XFVEC && FLEN >= 32) begin
          if (XF16 && fcsr_q.fmode.dst == 1'b0 &&
              (!(inst_data_i inside {VFDIV_H, VFDIV_R_H, VFSQRT_H}) || XDivSqrt)) begin
            write_rd = 1'b0;
            acc_qvalid_o = valid_instr;
          end else if (XF16ALT && fcsr_q.fmode.dst == 1'b1 &&
              (!(inst_data_i inside {VFDIV_H, VFDIV_R_H, VFSQRT_H}) || XDivSqrt)) begin
            write_rd = 1'b0;
            acc_qvalid_o = valid_instr;
          end else begin
            illegal_inst = 1'b1;
          end
        end else begin
          illegal_inst = 1'b1;
        end
      end
      VFSUM_H,
      VFNSUM_H: begin
        if (FP_EN && XFVEC && FLEN >= 64 && XFDOTP) begin
          if ((XF16 && fcsr_q.fmode.src == 1'b0) ||
             (XF16ALT && fcsr_q.fmode.src == 1'b1)) begin
            write_rd = 1'b0;
            acc_qvalid_o = valid_instr;
          end else begin
            illegal_inst = 1'b1;
          end
        end else begin
          illegal_inst = 1'b1;
        end
      end
      VFCPKA_H_S,
      VFCPKB_H_S,
      VFCVT_H_S,
      VFCVTU_H_S: begin
        if (FP_EN && XFVEC && RVF && FLEN >= 32) begin
          if (XF16 && fcsr_q.fmode.dst == 1'b0) begin
            write_rd = 1'b0;
            acc_qvalid_o = valid_instr;
          end else if (XF16ALT && fcsr_q.fmode.dst == 1'b1) begin
            write_rd = 1'b0;
            acc_qvalid_o = valid_instr;
          end else begin
            illegal_inst = 1'b1;
          end
        end else begin
          illegal_inst = 1'b1;
        end
      end
      VFCVT_S_H,
      VFCVTU_S_H: begin
        if (FP_EN && XFVEC && RVF && FLEN >= 32) begin
          if (XF16 && fcsr_q.fmode.src == 1'b0) begin
            write_rd = 1'b0;
            acc_qvalid_o = valid_instr;
          end else if (XF16ALT && fcsr_q.fmode.src == 1'b1) begin
            write_rd = 1'b0;
            acc_qvalid_o = valid_instr;
          end else begin
            illegal_inst = 1'b1;
          end
        end else begin
          illegal_inst = 1'b1;
        end
      end
      VFCPKA_H_D,
      VFCPKB_H_D: begin
        if (FP_EN && XFVEC && RVD && FLEN >= 32) begin
          if (XF16 && fcsr_q.fmode.dst == 1'b0) begin
            write_rd = 1'b0;
            acc_qvalid_o = valid_instr;
          end else if (XF16ALT && fcsr_q.fmode.dst == 1'b1) begin
            write_rd = 1'b0;
            acc_qvalid_o = valid_instr;
          end else begin
            illegal_inst = 1'b1;
          end
        end else begin
          illegal_inst = 1'b1;
        end
      end
      VFCVT_H_H,
      VFCVTU_H_H: begin
        if (FP_EN && XFVEC && RVF && XF16 && XF16ALT && FLEN >= 32) begin
          if (fcsr_q.fmode.src != fcsr_q.fmode.dst) begin
            write_rd = 1'b0;
            acc_qvalid_o = valid_instr;
          end else begin
            illegal_inst = 1'b1;
          end
        end else begin
          illegal_inst = 1'b1;
        end
      end
      VFDOTPEX_S_H,
      VFDOTPEX_S_R_H,
      VFNDOTPEX_S_H,
      VFNDOTPEX_S_R_H,
      VFSUMEX_S_H,
      VFNSUMEX_S_H: begin
        if (FP_EN && XFVEC && FLEN >= 64 && XFDOTP && RVF) begin
          if ((XF16 && fcsr_q.fmode.src == 1'b0) ||
             (XF16ALT && fcsr_q.fmode.src == 1'b1)) begin
            write_rd = 1'b0;
            acc_qvalid_o = valid_instr;
          end else begin
            illegal_inst = 1'b1;
          end
        end else begin
          illegal_inst = 1'b1;
        end
      end
      // [Alternate] Quarter Precision Floating-Point
      FADD_B,
      FSUB_B,
      FMUL_B,
      // FDIV_B,
      FSGNJ_B,
      FSGNJN_B,
      FSGNJX_B,
      FMIN_B,
      FMAX_B,
      // FSQRT_B,
      FMADD_B,
      FMSUB_B,
      FNMSUB_B,
      FNMADD_B: begin
        if (FP_EN && XF8 && fcsr_q.fmode.dst == 1'b0) begin
          write_rd = 1'b0;
          acc_qvalid_o = valid_instr;
        end else if (FP_EN && XF8ALT && fcsr_q.fmode.dst == 1'b1) begin
          write_rd = 1'b0;
          acc_qvalid_o = valid_instr;
        end else begin
          illegal_inst = 1'b1;
        end
      end
      FMACEX_S_B,
      FMULEX_S_B: begin
        if (FP_EN && RVF && XF16 && XFAUX) begin
          write_rd = 1'b0;
          acc_qvalid_o = valid_instr;
        end else begin
          illegal_inst = 1'b1;
        end
      end
      FCVT_S_B: begin
        if (FP_EN && RVF && XF8 && fcsr_q.fmode.src == 1'b0) begin
          write_rd = 1'b0;
          acc_qvalid_o = valid_instr;
        end else if (FP_EN && RVF && XF8ALT && fcsr_q.fmode.src == 1'b1) begin
          write_rd = 1'b0;
          acc_qvalid_o = valid_instr;
        end else begin
          illegal_inst = 1'b1;
        end
      end
      FCVT_B_S: begin
        if (FP_EN && RVF && XF8 && fcsr_q.fmode.dst == 1'b0) begin
          write_rd = 1'b0;
          acc_qvalid_o = valid_instr;
        end else if (FP_EN && RVF && XF8ALT && fcsr_q.fmode.dst == 1'b1) begin
          write_rd = 1'b0;
          acc_qvalid_o = valid_instr;
        end else begin
          illegal_inst = 1'b1;
        end
      end
      FCVT_D_B: begin
        if (FP_EN && RVD && XF8 && fcsr_q.fmode.src == 1'b0) begin
          write_rd = 1'b0;
          acc_qvalid_o = valid_instr;
        end else if (FP_EN && RVD && XF8ALT && fcsr_q.fmode.src == 1'b1) begin
          write_rd = 1'b0;
          acc_qvalid_o = valid_instr;
        end else begin
          illegal_inst = 1'b1;
        end
      end
      FCVT_B_D: begin
        if (FP_EN && RVD && XF8 && fcsr_q.fmode.dst == 1'b0) begin
          write_rd = 1'b0;
          acc_qvalid_o = valid_instr;
        end else if (FP_EN && RVF && XF8ALT && fcsr_q.fmode.dst == 1'b1) begin
          write_rd = 1'b0;
          acc_qvalid_o = valid_instr;
        end else begin
          illegal_inst = 1'b1;
        end
      end
      FCVT_H_B: begin
        if (FP_EN) begin
          if ((XF8 && fcsr_q.fmode.src == 1'b0) ||
             (XF8ALT && fcsr_q.fmode.src == 1'b1)) begin
            if ((XF16 && fcsr_q.fmode.dst == 1'b0) ||
               (XF16ALT && fcsr_q.fmode.dst == 1'b1)) begin
              write_rd = 1'b0;
              acc_qvalid_o = valid_instr;
            end else begin
              illegal_inst = 1'b1;
            end
          end else begin
            illegal_inst = 1'b1;
          end
        end else begin
          illegal_inst = 1'b1;
        end
      end
      FCVT_B_H: begin
        if (FP_EN) begin
          if ((XF16 && fcsr_q.fmode.src == 1'b0) ||
             (XF16ALT && fcsr_q.fmode.src == 1'b1)) begin
            if ((XF8 && fcsr_q.fmode.dst == 1'b0) ||
               (XF8ALT && fcsr_q.fmode.dst == 1'b1)) begin
              write_rd = 1'b0;
              acc_qvalid_o = valid_instr;
            end else begin
              illegal_inst = 1'b1;
            end
          end else begin
            illegal_inst = 1'b1;
          end
        end else begin
          illegal_inst = 1'b1;
        end
      end
      // Vectorized [Alternate] Quarter Precision Floating-Point
      VFADD_B,
      VFADD_R_B,
      VFSUB_B,
      VFSUB_R_B,
      VFMUL_B,
      VFMUL_R_B,
      VFDIV_B,
      VFDIV_R_B,
      VFMIN_B,
      VFMIN_R_B,
      VFMAX_B,
      VFMAX_R_B,
      VFSQRT_B,
      VFMAC_B,
      VFMAC_R_B,
      VFMRE_B,
      VFMRE_R_B,
      VFSGNJ_B,
      VFSGNJ_R_B,
      VFSGNJN_B,
      VFSGNJN_R_B,
      VFSGNJX_B,
      VFSGNJX_R_B: begin
        if (FP_EN && XFVEC && XF8 && FLEN >= 16
          && (!(inst_data_i inside {VFDIV_B, VFDIV_R_B, VFSQRT_B}) || XDivSqrt)) begin
          write_rd = 1'b0;
          acc_qvalid_o = valid_instr;
        end else begin
          illegal_inst = 1'b1;
        end
      end
      VFSUM_B,
      VFNSUM_B: begin
        if (FP_EN && XFVEC && FLEN >= 32 && XFDOTP) begin
          if ((XF8 && fcsr_q.fmode.src == 1'b0) ||
             (XF8ALT && fcsr_q.fmode.src == 1'b1)) begin
            write_rd = 1'b0;
            acc_qvalid_o = valid_instr;
          end else begin
            illegal_inst = 1'b1;
          end
        end else begin
          illegal_inst = 1'b1;
        end
      end
      VFCVT_B_S,
      VFCVTU_B_S,
      VFCPKA_B_S,
      VFCPKB_B_S,
      VFCPKC_B_S,
      VFCPKD_B_S: begin
        if (FP_EN && XFVEC && RVF && FLEN >= 16) begin
          if (XF8 && fcsr_q.fmode.dst == 1'b0) begin
            write_rd = 1'b0;
            acc_qvalid_o = valid_instr;
          end else if (XF8ALT && fcsr_q.fmode.dst == 1'b1) begin
            write_rd = 1'b0;
            acc_qvalid_o = valid_instr;
          end else begin
            illegal_inst = 1'b1;
          end
        end else begin
          illegal_inst = 1'b1;
        end
      end
      VFCVT_S_B,
      VFCVTU_S_B: begin
        if (FP_EN && XFVEC && RVF && FLEN >= 16) begin
          if (XF8 && fcsr_q.fmode.src == 1'b0) begin
            write_rd = 1'b0;
            acc_qvalid_o = valid_instr;
          end else if (XF8ALT && fcsr_q.fmode.src == 1'b1) begin
            write_rd = 1'b0;
            acc_qvalid_o = valid_instr;
          end else begin
            illegal_inst = 1'b1;
          end
        end else begin
          illegal_inst = 1'b1;
        end
      end
      VFCPKA_B_D,
      VFCPKB_B_D,
      VFCPKC_B_D,
      VFCPKD_B_D: begin
        if (FP_EN && XFVEC && RVD && FLEN >= 16) begin
          if (XF8 && fcsr_q.fmode.dst == 1'b0) begin
            write_rd = 1'b0;
            acc_qvalid_o = valid_instr;
          end else if (XF8ALT && fcsr_q.fmode.dst == 1'b1) begin
            write_rd = 1'b0;
            acc_qvalid_o = valid_instr;
          end else begin
            illegal_inst = 1'b1;
          end
        end else begin
          illegal_inst = 1'b1;
        end
      end
      VFCVT_B_H,
      VFCVTU_B_H: begin
        if (FP_EN && XFVEC && FLEN >= 16) begin
          if ((XF16 && fcsr_q.fmode.src == 1'b0) ||
             (XF16ALT && fcsr_q.fmode.src == 1'b1)) begin
            if ((XF8 && fcsr_q.fmode.dst == 1'b0) ||
               (XF8ALT && fcsr_q.fmode.dst == 1'b1)) begin
              write_rd = 1'b0;
              acc_qvalid_o = valid_instr;
            end else begin
              illegal_inst = 1'b1;
            end
          end else begin
            illegal_inst = 1'b1;
          end
        end else begin
          illegal_inst = 1'b1;
        end
      end
      VFCVT_H_B,
      VFCVTU_H_B: begin
        if (FP_EN && XFVEC && FLEN >= 16) begin
          if ((XF8 && fcsr_q.fmode.src == 1'b0) ||
             (XF8ALT && fcsr_q.fmode.src == 1'b1)) begin
            if ((XF16 && fcsr_q.fmode.dst == 1'b0) ||
               (XF16ALT && fcsr_q.fmode.dst == 1'b1)) begin
              write_rd = 1'b0;
              acc_qvalid_o = valid_instr;
            end else begin
              illegal_inst = 1'b1;
            end
          end else begin
            illegal_inst = 1'b1;
          end
        end else begin
          illegal_inst = 1'b1;
        end
      end
      VFCVT_B_B,
      VFCVTU_B_B: begin
        if (FP_EN && XFVEC && RVF && XF8 && XF8ALT && FLEN >= 16) begin
          if (fcsr_q.fmode.src != fcsr_q.fmode.dst) begin
            write_rd = 1'b0;
            acc_qvalid_o = valid_instr;
          end else begin
            illegal_inst = 1'b1;
          end
        end else begin
          illegal_inst = 1'b1;
        end
      end
      VFDOTPEX_H_B,
      VFDOTPEX_H_R_B,
      VFNDOTPEX_H_B,
      VFNDOTPEX_H_R_B,
      VFSUMEX_H_B,
      VFNSUMEX_H_B: begin
        if (FP_EN && XFVEC && FLEN >= 32 && XFDOTP) begin
          if ((XF8 && fcsr_q.fmode.src == 1'b0) ||
             (XF8ALT && fcsr_q.fmode.src == 1'b1)) begin
            if ((XF16 && fcsr_q.fmode.dst == 1'b0) ||
               (XF16ALT && fcsr_q.fmode.dst == 1'b1)) begin
              write_rd = 1'b0;
              acc_qvalid_o = valid_instr;
            end else begin
              illegal_inst = 1'b1;
            end
          end else begin
            illegal_inst = 1'b1;
          end
        end else begin
          illegal_inst = 1'b1;
        end
      end
      // Offload FP-Int Instructions - fire and forget
      // Double Precision Floating-Point
      FLE_D,
      FLT_D,
      FEQ_D,
      FCLASS_D,
      FCVT_W_D,
      FCVT_WU_D: begin
        if (FP_EN && RVD) begin
          write_rd = 1'b0;
          uses_rd = 1'b1;
          acc_qvalid_o = valid_instr;
          acc_register_rd = 1'b1; // No RS in GPR but RD in GPR, register in int scoreboard
        end else begin
          illegal_inst = 1'b1;
        end
      end
      // Single Precision Floating-Point
      FLE_S,
      FLT_S,
      FEQ_S,
      FCLASS_S,
      FCVT_W_S,
      FCVT_WU_S,
      FMV_X_W: begin
        if (FP_EN && RVF) begin
          write_rd = 1'b0;
          uses_rd = 1'b1;
          acc_qvalid_o = valid_instr;
          acc_register_rd = 1'b1; // No RS in GPR but RD in GPR, register in int scoreboard
        end else begin
          illegal_inst = 1'b1;
        end
      end
      // Vectors
      VFEQ_S,
      VFEQ_R_S,
      VFNE_S,
      VFNE_R_S,
      VFLT_S,
      VFLT_R_S,
      VFGE_S,
      VFGE_R_S,
      VFLE_S,
      VFLE_R_S,
      VFGT_S,
      VFGT_R_S,
      VFCLASS_S: begin
        if (FP_EN && XFVEC && RVF && FLEN >= 64) begin
          write_rd = 1'b0;
          uses_rd = 1'b1;
          acc_qvalid_o = valid_instr;
          acc_register_rd = 1'b1; // No RS in GPR but RD in GPR, register in int scoreboard
        end else begin
          illegal_inst = 1'b1;
        end
      end
      // [Alternate] Half Precision Floating-Point
      FLE_H,
      FLT_H,
      FEQ_H,
      FCLASS_H,
      FCVT_W_H,
      FCVT_WU_H,
      FMV_X_H: begin
        if (FP_EN && XF16 && fcsr_q.fmode.src == 1'b0) begin
          write_rd = 1'b0;
          uses_rd = 1'b1;
          acc_qvalid_o = valid_instr;
          acc_register_rd = 1'b1; // No RS in GPR but RD in GPR, register in int scoreboard
        end else if (FP_EN && XF16ALT && fcsr_q.fmode.src == 1'b1) begin
          write_rd = 1'b0;
          uses_rd = 1'b1;
          acc_qvalid_o = valid_instr;
          acc_register_rd = 1'b1; // No RS in GPR but RD in GPR, register in int scoreboard
        end else begin
          illegal_inst = 1'b1;
        end
      end
      // Vectors
      VFEQ_H,
      VFEQ_R_H,
      VFNE_H,
      VFNE_R_H,
      VFLT_H,
      VFLT_R_H,
      VFGE_H,
      VFGE_R_H,
      VFLE_H,
      VFLE_R_H,
      VFGT_H,
      VFGT_R_H,
      VFCLASS_H: begin
        if (FP_EN && XFVEC && FLEN >= 32) begin
          if (XF16 && fcsr_q.fmode.dst == 1'b0) begin
            write_rd = 1'b0;
            uses_rd = 1'b1;
            acc_qvalid_o = valid_instr;
            acc_register_rd = 1'b1; // No RS in GPR but RD in GPR, register in int scoreboard
          end else if (XF16ALT && fcsr_q.fmode.dst == 1'b1) begin
            write_rd = 1'b0;
            uses_rd = 1'b1;
            acc_qvalid_o = valid_instr;
            acc_register_rd = 1'b1; // No RS in GPR but RD in GPR, register in int scoreboard
          end else begin
            illegal_inst = 1'b1;
          end
        end
      end
      VFMV_X_H,
      VFCVT_X_H,
      VFCVT_XU_H: begin
        if (FP_EN && XFVEC && FLEN >= 32 && ~RVD) begin
          if (XF16 && fcsr_q.fmode.src == 1'b0) begin
            write_rd = 1'b0;
            uses_rd = 1'b1;
            acc_qvalid_o = valid_instr;
            acc_register_rd = 1'b1; // No RS in GPR but RD in GPR, register in int scoreboard
          end else if (XF16ALT && fcsr_q.fmode.src == 1'b1) begin
            write_rd = 1'b0;
            uses_rd = 1'b1;
            acc_qvalid_o = valid_instr;
            acc_register_rd = 1'b1; // No RS in GPR but RD in GPR, register in int scoreboard
          end else begin
            illegal_inst = 1'b1;
          end
        end
      end
      // [Alternate] Quarter Precision Floating-Point
      FLE_B,
      FLT_B,
      FEQ_B,
      FCLASS_B,
      FCVT_W_B,
      FCVT_WU_B,
      FMV_X_B: begin
        if (FP_EN && XF8 && fcsr_q.fmode.src == 1'b0) begin
          write_rd = 1'b0;
          uses_rd = 1'b1;
          acc_qvalid_o = valid_instr;
          acc_register_rd = 1'b1; // No RS in GPR but RD in GPR, register in int scoreboard
        end else if (FP_EN && XF8ALT && fcsr_q.fmode.src == 1'b1) begin
          write_rd = 1'b0;
          uses_rd = 1'b1;
          acc_qvalid_o = valid_instr;
          acc_register_rd = 1'b1; // No RS in GPR but RD in GPR, register in int scoreboard
        end else begin
          illegal_inst = 1'b1;
        end
      end
      // Vectors
      VFEQ_B,
      VFEQ_R_B,
      VFNE_B,
      VFNE_R_B,
      VFLT_B,
      VFLT_R_B,
      VFGE_B,
      VFGE_R_B,
      VFLE_B,
      VFLE_R_B,
      VFGT_B,
      VFGT_R_B: begin
        if (FP_EN && XFVEC && FLEN >= 16) begin
          if (XF8 && fcsr_q.fmode.src == 1'b0) begin
            write_rd = 1'b0;
            uses_rd = 1'b1;
            acc_qvalid_o = valid_instr;
            acc_register_rd = 1'b1; // No RS in GPR but RD in GPR, register in int scoreboard
          end else if (XF8ALT && fcsr_q.fmode.src == 1'b1) begin
            write_rd = 1'b0;
            uses_rd = 1'b1;
            acc_qvalid_o = valid_instr;
            acc_register_rd = 1'b1; // No RS in GPR but RD in GPR, register in int scoreboard
          end else begin
            illegal_inst = 1'b1;
          end
        end
      end
      VFMV_X_B,
      VFCLASS_B,
      VFCVT_X_B,
      VFCVT_XU_B: begin
        if (FP_EN && XFVEC && FLEN >= 16 && ~RVD) begin
          if (XF8 && fcsr_q.fmode.src == 1'b0) begin
            write_rd = 1'b0;
            uses_rd = 1'b1;
            acc_qvalid_o = valid_instr;
            acc_register_rd = 1'b1; // No RS in GPR but RD in GPR, register in int scoreboard
          end else if (XF8ALT && fcsr_q.fmode.src == 1'b1) begin
            write_rd = 1'b0;
            uses_rd = 1'b1;
            acc_qvalid_o = valid_instr;
            acc_register_rd = 1'b1; // No RS in GPR but RD in GPR, register in int scoreboard
          end else begin
            illegal_inst = 1'b1;
          end
        end
      end
      // Offload Int-FP Instructions - fire and forget
      // Double Precision Floating-Point
      FCVT_D_W,
      FCVT_D_WU: begin
        if (FP_EN && RVD) begin
          opa_select = Reg;
          write_rd = 1'b0;
          acc_qvalid_o = valid_instr;
        end else begin
          illegal_inst = 1'b1;
        end
      end
      // Single Precision Floating-Point
      FMV_W_X,
      FCVT_S_W,
      FCVT_S_WU: begin
        if (FP_EN && RVF) begin
          opa_select = Reg;
          write_rd = 1'b0;
          acc_qvalid_o = valid_instr;
        end else begin
          illegal_inst = 1'b1;
        end
      end
      // [Alternate] Half Precision Floating-Point
      FMV_H_X,
      FCVT_H_W,
      FCVT_H_WU: begin
        if (FP_EN && XF16 && (fcsr_q.fmode.dst == 1'b0)) begin
          opa_select = Reg;
          write_rd = 1'b0;
          acc_qvalid_o = valid_instr;
        end else if (FP_EN && XF16ALT && (fcsr_q.fmode.dst == 1'b1)) begin
          opa_select = Reg;
          write_rd = 1'b0;
          acc_qvalid_o = valid_instr;
        end else begin
          illegal_inst = 1'b1;
        end
      end
      // Vectors
      VFMV_H_X,
      VFCVT_H_X,
      VFCVT_H_XU: begin
        if (FP_EN && XFVEC && FLEN >= 32 && ~RVD) begin
          if (XF16 && fcsr_q.fmode.dst == 1'b0) begin
            write_rd = 1'b0;
            acc_qvalid_o = valid_instr;
          end else if (XF16ALT && fcsr_q.fmode.dst == 1'b1) begin
            write_rd = 1'b0;
            acc_qvalid_o = valid_instr;
          end else begin
            illegal_inst = 1'b1;
          end
        end
      end
      // [Alternate] Quarter Precision Floating-Point
      FMV_B_X,
      FCVT_B_W,
      FCVT_B_WU: begin
        if (FP_EN && XF8 && fcsr_q.fmode.dst == 1'b0) begin
          opa_select = Reg;
          write_rd = 1'b0;
          acc_qvalid_o = valid_instr;
        end else if (FP_EN && XF8ALT && fcsr_q.fmode.dst == 1'b1) begin
          opa_select = Reg;
          write_rd = 1'b0;
          acc_qvalid_o = valid_instr;
        end else begin
          illegal_inst = 1'b1;
        end
      end
      // Vectors
      VFMV_B_X,
      VFCVT_B_X,
      VFCVT_B_XU: begin
        if (FP_EN && XFVEC && FLEN >= 16 && ~RVD) begin
          if (XF8 && fcsr_q.fmode.dst == 1'b0) begin
            write_rd = 1'b0;
            acc_qvalid_o = valid_instr;
          end else if (XF8ALT && fcsr_q.fmode.dst == 1'b1) begin
            write_rd = 1'b0;
            acc_qvalid_o = valid_instr;
          end else begin
            illegal_inst = 1'b1;
          end
        end
      end
      // FP Sequencer
      FREP_O,
      FREP_I: begin
        if (FP_EN) begin
          opa_select = Reg;
          write_rd = 1'b0;
          acc_qvalid_o = valid_instr;
        end else begin
          illegal_inst = 1'b1;
        end
      end
      // Floating-Point Load/Store
      // Single Precision Floating-Point
      FLW: begin
        if (FP_EN && RVF) begin
          opa_select = Reg;
          opb_select = IImmediate;
          write_rd = 1'b0;
          acc_qvalid_o = valid_instr & trans_ready;
          ls_size = Word;
          is_fp_load = 1'b1;
        end else begin
          illegal_inst = 1'b1;
        end
      end
      FSW: begin
        if (FP_EN && RVF) begin
          opa_select = Reg;
          opb_select = SFImmediate;
          write_rd = 1'b0;
          acc_qvalid_o = valid_instr & trans_ready;
          ls_size = Word;
          is_fp_store = 1'b1;
        end else begin
          illegal_inst = 1'b1;
        end
      end
      // Double Precision Floating-Point
      FLD: begin
        if (FP_EN && (RVD || XFVEC)) begin
          opa_select = Reg;
          opb_select = IImmediate;
          write_rd = 1'b0;
          acc_qvalid_o = valid_instr & trans_ready;
          ls_size = Double;
          is_fp_load = 1'b1;
        end else begin
          illegal_inst = 1'b1;
        end
      end
      FSD: begin
        if (FP_EN && (RVD || XFVEC)) begin
          opa_select = Reg;
          opb_select = SFImmediate;
          write_rd = 1'b0;
          acc_qvalid_o = valid_instr & trans_ready;
          ls_size = Double;
          is_fp_store = 1'b1;
        end else begin
          illegal_inst = 1'b1;
        end
      end
      // Half Precision Floating-Point
      FLH: begin
        if (FP_EN && (XF16 || XF16ALT)) begin
          opa_select = Reg;
          opb_select = IImmediate;
          write_rd = 1'b0;
          acc_qvalid_o = valid_instr & trans_ready;
          ls_size = HalfWord;
          is_fp_load = 1'b1;
        end else begin
          illegal_inst = 1'b1;
        end
      end
      FSH: begin
        if (FP_EN && (XF16 || XF16ALT)) begin
          opa_select = Reg;
          opb_select = SFImmediate;
          write_rd = 1'b0;
          acc_qvalid_o = valid_instr & trans_ready;
          ls_size = HalfWord;
          is_fp_store = 1'b1;
        end else begin
          illegal_inst = 1'b1;
        end
      end
      // Quarter Precision Floating-Point
      FLB: begin
        if (FP_EN && (XF8 || XF8ALT)) begin
          opa_select = Reg;
          opb_select = IImmediate;
          write_rd = 1'b0;
          acc_qvalid_o = valid_instr & trans_ready;
          ls_size = Byte;
          is_fp_load = 1'b1;
        end else begin
          illegal_inst = 1'b1;
        end
      end
      FSB: begin
        if (FP_EN && (XF8 || XF8ALT)) begin
          opa_select = Reg;
          opb_select = SFImmediate;
          write_rd = 1'b0;
          acc_qvalid_o = valid_instr & trans_ready;
          ls_size = Byte;
          is_fp_store = 1'b1;
        end else begin
          illegal_inst = 1'b1;
        end
      end
      // DMA instructions
      /*DMSRC,
      DMDST,
      DMSTR: begin
        if (Xdma) begin
          acc_qreq_o.addr  = DMA_SS;
          opa_select   = Reg;
          opb_select   = Reg;
          acc_qvalid_o = valid_instr;
          write_rd     = 1'b0;
        end else begin
          illegal_inst = 1'b1;
        end
      end
      DMCPYI: begin
        if (Xdma) begin
          acc_qreq_o.addr     = DMA_SS;
          opa_select      = Reg;
          acc_qvalid_o    = valid_instr;
          write_rd        = 1'b0;
          uses_rd         = 1'b1;
          acc_register_rd = 1'b1;
        end else begin
          illegal_inst = 1'b1;
        end
      end
      DMCPY: begin
        if (Xdma) begin
          acc_qreq_o.addr     = DMA_SS;
          opa_select      = Reg;
          opb_select      = Reg;
          acc_qvalid_o    = valid_instr;
          write_rd        = 1'b0;
          uses_rd         = 1'b1;
          acc_register_rd = 1'b1;
        end else begin
          illegal_inst = 1'b1;
        end
      end
      DMSTATI: begin
        if (Xdma) begin
          acc_qreq_o.addr     = DMA_SS;
          acc_qvalid_o    = valid_instr;
          write_rd        = 1'b0;
          uses_rd         = 1'b1;
          acc_register_rd = 1'b1;
        end else begin
          illegal_inst = 1'b1;
        end
      end
      DMSTAT: begin
        if (Xdma) begin
          acc_qreq_o.addr     = DMA_SS;
          opa_select      = Reg;
          acc_qvalid_o    = valid_instr;
          write_rd        = 1'b0;
          uses_rd         = 1'b1;
          acc_register_rd = 1'b1;
        end else begin
          illegal_inst = 1'b1;
        end
      end
      DMREP: begin
        if (Xdma) begin
          acc_qreq_o.addr     = DMA_SS;
          opa_select      = Reg;
          acc_qvalid_o    = valid_instr;
          write_rd        = 1'b0;
        end else begin
          illegal_inst = 1'b1;
        end
      end
      */
      SCFGRI: begin
        if (Xssr) begin
          acc_qreq_o.addr = SSR_CFG;
          acc_qvalid_o = valid_instr;
          acc_register_rd = 1'b1;
        end else illegal_inst = 1'b1;
      end
      SCFGWI: begin
        if (Xssr) begin
          acc_qreq_o.addr = SSR_CFG;
          opa_select = Reg;
          acc_qvalid_o = valid_instr;
          write_rd = 1'b0;
        end else illegal_inst = 1'b1;
      end
      SCFGR: begin
        if (Xssr) begin
          acc_qreq_o.addr = SSR_CFG;
          opb_select = Reg;
          acc_qvalid_o = valid_instr;
          acc_register_rd = 1'b1;
        end else illegal_inst = 1'b1;
      end
      SCFGW: begin
        if (Xssr) begin
          acc_qreq_o.addr = SSR_CFG;
          opa_select = Reg;
          opb_select = Reg;
          acc_qvalid_o = valid_instr;
          write_rd = 1'b0;
        end else illegal_inst = 1'b1;
      end
      default: begin
        illegal_inst = 1'b1;
      end
    endcase

    // Sanitize illegal instructions so that they don't exert any side-effects.
    if (exception) begin
     write_rd = 1'b0;
     uses_rd = 1'b0;
     write_rs1 = 1'b0;
     uses_rs1 = 1'b0;
     acc_qvalid_o = 1'b0;
     next_pc = Exception;
    end
  end

  assign exception = illegal_inst
                   | ecall
                   | ebreak
                   | interrupt
                   | inst_addr_misaligned
                   | ld_addr_misaligned
                   | st_addr_misaligned
                   | illegal_csr
                   | (dtlb_page_fault & dtlb_trans_valid)
                   | (itlb_page_fault & itlb_trans_valid);

  `ifndef VCS
  // pragma translate_off
  always_ff @(posedge clk_i) begin
    if (!rst_i && illegal_inst && valid_instr) begin
      $display("[Illegal Instruction Core %0d] PC: %h Data: %h",
                                hart_id_i, inst_addr_o, inst_data_i);
    end
  end
  // pragma translate_on
  `endif

  assign meip = irq_i.meip & eie_q[M];
  assign mtip = irq_i.mtip & tie_q[M];
  assign msip = irq_i.msip & sie_q[M];
  assign mcip = irq_i.mcip & cie_q[M];

  assign seip = seip_q & eie_q[S];
  assign stip = stip_q & tie_q[S];
  assign ssip = ssip_q & sie_q[S];
  assign scip = scip_q & cie_q[S];

  assign interrupts_enabled = ((priv_lvl_q == PrivLvlM) & ie_q[M]) || (priv_lvl_q != PrivLvlM);
  assign any_interrupt_pending = meip | mtip | msip | mcip | seip | stip | ssip | scip;
  assign interrupt = interrupts_enabled & any_interrupt_pending;

  // CSR logic
  always_comb begin
    csr_rvalue = '0;
    illegal_csr = '0;
    priv_lvl_d = priv_lvl_q;
    // registers
    fcsr_d = fcsr_q;
    fcsr_d.fflags = fcsr_q.fflags | fpu_status_i;
    fcsr_d.fmode.src = fcsr_q.fmode.src;
    fcsr_d.fmode.dst = fcsr_q.fmode.dst;
    scratch_d = scratch_q;
    epc_d = epc_q;
    cause_d = cause_q;
    cause_irq_d = cause_irq_q;

    satp_d = satp_q;
    mseg_d = mseg_q;
    mpp_d = mpp_q;
    ie_d = ie_q;
    pie_d = pie_q;
    spp_d = spp_q;
    // SSR register
    ssr_active_d = ssr_active_q;
    // Interrupts
    eie_d = eie_q;
    tie_d = tie_q;
    sie_d = sie_q;
    cie_d = cie_q;
    seip_d = seip_q;
    stip_d = stip_q;
    ssip_d = ssip_q;
    scip_d = scip_q;

    tvec_d = tvec_q;

    dcsr_d = dcsr_q;
    dpc_d = dpc_q;
    dscratch_d = dscratch_q;

    // DPC and DCSR update logic
    if (!debug_q) begin
      if (valid_instr && inst_data_i == EBREAK) begin
        dpc_d = pc_q;
        dcsr_d.cause = dm::CauseBreakpoint;
      end else if (irq_i.debug) begin
        dpc_d = npc;
        dcsr_d.cause = dm::CauseRequest;
      end else if (valid_instr && dcsr_q.step) begin
        dpc_d = npc;
        dcsr_d.cause = dm::CauseSingleStep;
      end
    end
    // Right now we skip this due to simplicity.
    if (csr_en) begin
      // Check privilege level.
      if ((priv_lvl_q & inst_data_i[29:28]) == inst_data_i[29:28]) begin
        unique case (inst_data_i[31:20])
          CSR_MISA: csr_rvalue =
                              // A - Atomic Instructions extension
                                (1   <<  0)
                              // C - Compressed extension
                              | (0   <<  2)
                              // D - Double precsision floating-point extension
                              | ((FP_EN & RVD) <<  3)
                              // E - RV32E base ISA
                              | ((FP_EN & RVE) <<  4)
                              // F - Single precsision floating-point extension
                              | ((FP_EN & RVF) <<  5)
                              // I - RV32I/64I/128I base ISA
                              | (1   <<  8)
                              // M - Integer Multiply/Divide extension
                              | (1   << 12)
                              // N - User level interrupts supported
                              | (0   << 13)
                              // S - Supervisor mode implemented
                              | (0   << 18)
                              // U - User mode implemented
                              | (0   << 20)
                              // X - Non-standard extensions present
                              | (((NSX & FP_EN) | Xdma | Xssr) << 23)
                              // RV32
                              | (1   << 30);
          CSR_MHARTID: begin
            csr_rvalue = hart_id_i;
          end
          `ifdef SNITCH_ENABLE_PERF
          CSR_MCYCLE: begin
            csr_rvalue = cycle_q[31:0];
          end
          CSR_MINSTRET: begin
            csr_rvalue = instret_q[31:0];
          end
          CSR_MCYCLEH: begin
            csr_rvalue = cycle_q[63:32];
          end
          CSR_MINSTRETH: begin
            csr_rvalue = instret_q[63:32];
          end
          `endif
          CSR_MSEG: begin
            csr_rvalue = mseg_q;
            if (!exception) mseg_d = alu_result[$bits(mseg_q)-1:0];
          end
          // Privleged Extension:
          CSR_MSTATUS: begin
            automatic snitch_pkg::status_rv32_t mstatus, mstatus_d;
            mstatus = '0;
            if (FP_EN) begin
              mstatus.fs = snitch_pkg::XDirty;
              mstatus.sd = 1'b1;
            end
            mstatus.mpp = mpp_q;
            mstatus.spp = spp_q;
            mstatus.mie = ie_q[M];
            mstatus.mpie = pie_q[M];
            csr_rvalue = mstatus;
            if (!exception) begin
              mstatus_d = snitch_pkg::status_rv32_t'(alu_result);
              mpp_d = mstatus_d.mpp;
              spp_d = mstatus_d.spp;
              ie_d[M] = mstatus_d.mie;
              pie_d[M] = mstatus_d.mpie;
            end
          end
          CSR_MEPC: begin
            csr_rvalue = epc_q[M];
            if (!exception) epc_d[M] = alu_result[31:0];
          end
          CSR_MIP: begin
            csr_rvalue[MEI] = irq_i.meip;
            csr_rvalue[MTI] = irq_i.mtip;
            csr_rvalue[MSI] = irq_i.msip;
            csr_rvalue[MCI] = irq_i.mcip;
            csr_rvalue[SEI] = seip_q;
            csr_rvalue[STI] = stip_q;
            csr_rvalue[SSI] = ssip_q;
            csr_rvalue[SCI] = scip_q;
            if (!exception) begin
              seip_d = alu_result[SEI];
              stip_d = alu_result[STI];
              ssip_d = alu_result[SSI];
              scip_d = alu_result[SCI];
            end
          end
          CSR_MIE: begin
            csr_rvalue[MEI] = eie_q[M];
            csr_rvalue[MTI] = tie_q[M];
            csr_rvalue[MSI] = sie_q[M];
            csr_rvalue[MCI] = cie_q[M];
            csr_rvalue[SEI] = eie_q[S];
            csr_rvalue[STI] = tie_q[S];
            csr_rvalue[SSI] = sie_q[S];
            csr_rvalue[SCI] = cie_q[S];
            if (!exception) begin
              eie_d[M] = alu_result[MEI];
              tie_d[M] = alu_result[MTI];
              sie_d[M] = alu_result[MSI];
              cie_d[M] = alu_result[MCI];
              eie_d[S] = alu_result[SEI];
              tie_d[S] = alu_result[STI];
              sie_d[S] = alu_result[SSI];
              cie_d[S] = alu_result[SCI];
            end
          end
          CSR_MCAUSE: begin
            csr_rvalue = cause_q[M];
            csr_rvalue[31] = cause_irq_q[M];
            if (!exception) begin
              cause_d[M] = alu_result[4:0];
              cause_irq_d[M] = alu_result[31];
            end
          end
          CSR_MTVAL:; // tied-off
          CSR_MTVEC: begin
            csr_rvalue = {tvec_q[M], 2'b0};
            if (!exception) tvec_d[M] = alu_result[31:2];
          end
          CSR_MSCRATCH: begin
            csr_rvalue = scratch_q[M];
            if (!exception) scratch_d[M] = alu_result[31:0];
          end
          CSR_MEDELEG:; // we currently don't support delegation
          CSR_SSTATUS: begin
            automatic snitch_pkg::status_rv32_t mstatus;
            mstatus = '0;
            mstatus.spp = spp_q;
            csr_rvalue = mstatus;
            if (!exception) spp_d = mstatus.spp;
          end
          CSR_SSCRATCH: begin
            csr_rvalue = scratch_q[S];
            if (!exception) scratch_d[S] = alu_result[31:0];
          end
          CSR_SEPC: begin
            csr_rvalue = epc_q[S];
            if (!exception) epc_d[S] = alu_result[31:0];
          end
          CSR_SIP, CSR_SIE:; //tied-off - no delegation
          // Enable if we want to support delegation.
          CSR_SCAUSE:; // tied-off - no delegation
          CSR_STVAL:; // tied-off - no delegation
          CSR_STVEC:; // tied-off - no delegation
          CSR_SATP: begin
            csr_rvalue = satp_q;
            if (!exception) begin
              satp_d.ppn = alu_result[21:0];
              satp_d.mode = alu_result[31];
            end
          end
          CSR_INT_SSR: begin
             csr_rvalue = {31'b0, ssr_active_q};
             if (!exception) ssr_active_d = alu_result[0];
          end
          // F/D Extension
          CSR_FFLAGS: begin
            if (FP_EN) begin
              csr_rvalue = {27'b0, fcsr_q.fflags};
              if (!exception) fcsr_d.fflags = fpnew_pkg::status_t'(alu_result[4:0]);
            end else illegal_csr = 1'b1;
          end
          CSR_FRM: begin
            if (FP_EN) begin
              csr_rvalue = {29'b0, fcsr_q.frm};
              if (!exception) fcsr_d.frm = fpnew_pkg::roundmode_e'(alu_result[2:0]);
            end else illegal_csr = 1'b1;
          end
          CSR_FCSR: begin
            if (FP_EN) begin
              csr_rvalue = {24'b0, fcsr_q};
              if (!exception) fcsr_d = fcsr_t'(alu_result[7:0]);
            end else illegal_csr = 1'b1;
          end
          CSR_FMODE: begin
            if (FP_EN) begin
              csr_rvalue = {30'b0, fcsr_q.fmode};
              if (!exception) fcsr_d.fmode = fpnew_pkg::fmt_mode_t'(alu_result[1:0]);
            end else illegal_csr = 1'b1;
          end
          default: csr_rvalue = '0;
        endcase
      end else illegal_csr = 1'b1;
    end

    // Manipulate CSRs / Privilege Stack
    if (valid_instr) begin
      // Exceptions
      // Illegal Instructions.
      if (illegal_inst || illegal_csr) cause_d[M] = ILLEGAL_INSTR;
      // Environment Calls.
      if (ecall) begin
        unique case (priv_lvl_q)
          PrivLvlM: cause_d[M] = ENV_CALL_MMODE;
          PrivLvlS: cause_d[M] = ENV_CALL_SMODE;
          PrivLvlU: cause_d[M] = ENV_CALL_UMODE;
          default: cause_d[M] = ENV_CALL_MMODE;
        endcase
      end

      if (ebreak) cause_d[M] = BREAKPOINT;
      // Page faults.
      if (dtlb_trans_valid && dtlb_page_fault) begin
        if (is_store) cause_d[M] = STORE_PAGE_FAULT;
        if (is_load)  cause_d[M] = LOAD_PAGE_FAULT;
      end
      if (itlb_trans_valid && itlb_page_fault) cause_d[M] = INSTR_PAGE_FAULT;
      if (inst_addr_misaligned) cause_d[M] = INSTR_ADDR_MISALIGNED;
      // Misaligned load/stores
      if (ld_addr_misaligned) cause_d[M] = LD_ADDR_MISALIGNED;
      if (st_addr_misaligned) cause_d[M] = ST_ADDR_MISALIGNED;

      // Interrupts.
      if (interrupt) begin
        // Priortize interrupts.
        if (meip)      cause_d[M] = MEI;
        else if (mtip) cause_d[M] = MTI;
        else if (msip) cause_d[M] = MSI;
        else if (mcip) cause_d[M] = MCI;
        else if (seip) cause_d[M] = SEI;
        else if (stip) cause_d[M] = STI;
        else if (ssip) cause_d[M] = SSI;
        else if (scip) cause_d[M] = SCI;
      end

      if (exception) begin
        epc_d[M] = pc_q;
        cause_irq_d[M] = interrupt;
        priv_lvl_d = PrivLvlM;

        // Manipulate exception stack.
        mpp_d = priv_lvl_q;
        pie_d[M] = ie_q[M];
        ie_d[M] = 1'b0;
      end

      // Return from Environment.
      if (inst_data_i == riscv_instr::MRET) begin
        priv_lvl_d = mpp_q;
        ie_d[M] = pie_q[M];
        pie_d[M] = 1'b1;
        mpp_d = snitch_pkg::PrivLvlU; // set default back to U-Mode
      end

      if (inst_data_i == riscv_instr::SRET) begin
        priv_lvl_d = snitch_pkg::priv_lvl_t'({1'b0, spp_q});
        spp_d = 1'b0;
      end
    end
    // static fields
    dcsr_d.xdebugver = 4;
    dcsr_d.zero2 = 0;
    dcsr_d.zero1 = 0;
    dcsr_d.zero0 = 0;
    dcsr_d.ebreaks = 0;
    dcsr_d.ebreaku = 0;
    dcsr_d.stepie = 0;
    dcsr_d.stopcount = 0;
    dcsr_d.stoptime = 0;
    dcsr_d.mprven = 0;
    dcsr_d.nmip = 0;
    dcsr_d.prv = dm::priv_lvl_t'(dm::PRIV_LVL_M);
  end

  snitch_regfile #(
    .DATA_WIDTH     ( 32             ),
    .NR_READ_PORTS  ( RegNrReadPorts ),
    .NR_WRITE_PORTS ( RegNrWritePorts),
    .ZERO_REG_ZERO  ( 1              ),
    .ADDR_WIDTH     ( RegWidth       )
  ) i_snitch_regfile (
    .clk_i,
    .raddr_i   ( gpr_raddr ),
    .rdata_o   ( gpr_rdata ),
    .waddr_i   ( gpr_waddr ),
    .wdata_i   ( gpr_wdata ),
    .we_i      ( gpr_we    )
  );

  // --------------------
  // Operand Select
  // --------------------
  assign gpr_raddr[0] = rs1;
  assign gpr_raddr[1] = rs2;
  // connect the third read port only if present
  if (RegNrReadPorts >= 3) begin: gpr_raddr_2
     assign gpr_raddr[2] = rd;
  end

  logic is_raddr_ssr;
  always_comb begin
    ssr_rvalid_o = '0;
    is_raddr_ssr = 1'b0;             
    unique case (opa_select)
      None: opa = '0;
      Reg: begin
         for (int s = 0; s < NumSsrs; s++) begin
           is_raddr_ssr |= (IntSsrRegs[s] == gpr_raddr[0]);
         end
        ssr_rvalid_o[0] = ssr_active_q & is_raddr_ssr;
        opa = ssr_rvalid_o[0] ? ssr_rdata_i[0] : gpr_rdata[0];
      end
      UImmediate: opa = uimm;
      JImmediate: opa = jimm;
      CSRImmmediate: opa = {{{32-RegWidth}{1'b0}}, rs1};
      default: opa = '0;
    endcase

    unique case (opb_select)
      None: opb = '0;
      Reg: begin
         for (int s = 0; s < NumSsrs; s++) begin
           is_raddr_ssr |= (IntSsrRegs[s] == gpr_raddr[1]);
         end
        ssr_rvalid_o[1] = ssr_active_q & is_raddr_ssr;
        opb = ssr_rvalid_o[1] ? ssr_rdata_i[1] : gpr_rdata[1];
      end
      IImmediate: opb = iimm;
      SFImmediate, SImmediate: opb = simm;
      PC: opb = pc_q;
      CSR: opb = csr_rvalue;
      PBImmediate: opb = pbimm;
      RegRd: opb = gpr_rdata[2];
      default: opb = '0;
    endcase
  end

  // --------------------
  // SSRs
  // --------------------  
  assign ssr_waddr_o = gpr_waddr[0];
  assign ssr_wdata_o = gpr_wdata[0];
  for (genvar i = 0; i < 2; i++) assign ssr_rdone_o[i] = ssr_rvalid_o[i];
  assign ssr_raddr_o = gpr_raddr;

  always_comb begin
    ssr_state_d = ssr_state_q;
    ssr_sel_o = 1'b0;
    unique case (ssr_state_q)
      Idle: begin
        if (is_int_ssr) begin
            ssr_state_d = IActive;
        end else if (is_fp_ssr) begin
            ssr_state_d = FPIssue;
        end
      end
      IActive: begin
        if (!ssr_active_q) begin
            ssr_state_d = Idle;
        end
      end
      FPIssue: begin
        if (acc_ssr_status_i) begin
          ssr_state_d = FPActive;
        end
      end
      FPActive: begin
        ssr_sel_o = 1'b1;
        if (!acc_ssr_status_i) begin
          ssr_state_d = Idle;
        end
      end
      default: ssr_state_d = Idle;
    endcase
  end

  always_ff @(posedge clk_i or negedge rst_i) begin
    if (rst_i) begin
      ssr_state_q <= Idle;
    end else begin
      ssr_state_q <= ssr_state_d;
    end
  end
              
  // --------------------
  // ALU
  // --------------------
  // Main Shifter
  logic [31:0] shift_opa, shift_opa_reversed;
  logic [31:0] shift_right_result, shift_left_result;
  logic [32:0] shift_opa_ext, shift_right_result_ext;
  logic shift_left, shift_arithmetic; // shift control
  for (genvar i = 0; i < 32; i++) begin : gen_reverse_opa
    assign shift_opa_reversed[i] = opa[31-i];
    assign shift_left_result[i] = shift_right_result[31-i];
  end
  assign shift_opa = shift_left ? shift_opa_reversed : opa;
  assign shift_opa_ext = {shift_opa[31] & shift_arithmetic, shift_opa};
  assign shift_right_result_ext = $unsigned($signed(shift_opa_ext) >>> opb[4:0]);
  assign shift_right_result = shift_right_result_ext[31:0];

  // Main Adder
  logic [32:0] alu_opa, alu_opb;
  assign adder_result = alu_opa + alu_opb;

  // ALU
  /* verilator lint_off WIDTH */
  always_comb begin
    alu_opa = $signed(opa);
    alu_opb = $signed(opb);

    alu_result = adder_result[31:0];
    shift_left = 1'b0;
    shift_arithmetic = 1'b0;

    unique case (alu_op)
      Sub: alu_opb = -$signed(opb);
      Slt: begin
        alu_opb = -$signed(opb);
        alu_result = {30'b0, adder_result[32]};
      end
      Ge: begin
        alu_opb = -$signed(opb);
        alu_result = {30'b0, ~adder_result[32]};
      end
      Sltu: begin
        alu_opa = $unsigned(opa);
        alu_opb = -$unsigned(opb);
        alu_result = {30'b0, adder_result[32]};
      end
      Geu: begin
        alu_opa = $unsigned(opa);
        alu_opb = -$unsigned(opb);
        alu_result = {30'b0, ~adder_result[32]};
      end
      Sll: begin
        shift_left = 1'b1;
        alu_result = shift_left_result;
      end
      Srl: alu_result = shift_right_result;
      Sra: begin
        shift_arithmetic = 1'b1;
        alu_result = shift_right_result;
      end
      LXor: alu_result = opa ^ opb;
      LAnd: alu_result = opa & opb;
      LNAnd: alu_result = (~opa) & opb;
      LOr: alu_result = opa | opb;
      Eq: begin
        alu_opb = -$signed(opb);
        alu_result = ~|adder_result;
      end
      Neq: begin
        alu_opb = -$signed(opb);
        alu_result = |adder_result;
      end
      BypassA: begin
        alu_result = opa;
      end
      default: alu_result = adder_result[31:0];
    endcase
  end
  /* verilator lint_on WIDTH */

  // --------------------
  // L0 DTLB
  // --------------------
  assign dtlb_va = va_t'(alu_result[31:PAGE_SHIFT]);
  snitch_l0_tlb #(
    .pa_t (pa_t),
    .l0_pte_t (l0_pte_t),
    .NrEntries ( NumDTLBEntries )
  ) i_snitch_l0_tlb_data (
    .clk_i,
    .rst_i,
    .flush_i ( tlb_flush ),
    .priv_lvl_i ( priv_lvl_q ),
    .valid_i ( dtlb_valid ),
    .ready_o ( dtlb_ready ),
    .va_i ( dtlb_va ),
    .write_i ( is_store ),
    .read_i ( is_load ),
    .execute_i ( 1'b0 ),
    .page_fault_o ( dtlb_page_fault ),
    .pa_o ( dtlb_pa ),
    // Refill port
    .valid_o ( ptw_valid_o [1] ),
    .ready_i ( ptw_ready_i [1] ),
    .va_o ( ptw_va_o [1] ),
    .pte_i ( ptw_pte_i [1] ),
    .is_4mega_i ( ptw_is_4mega_i [1] )
  );

  assign ptw_ppn_o[0] = $unsigned(satp_q.ppn);
  assign ptw_ppn_o[1] = $unsigned(satp_q.ppn);

  // Translation is active if it is set in SATP and we are not in machine mode or debug mode.
  assign trans_active = satp_q.mode & (priv_lvl_q != PrivLvlM) & ~debug_q;
  assign dtlb_trans_valid = trans_active & dtlb_valid & dtlb_ready;
  assign trans_active_exp = {{PPNSize}{trans_active}};
  assign trans_ready = ((trans_active & dtlb_ready) | ~trans_active);

  assign dtlb_valid = (lsu_tlb_qvalid & trans_active) | ((is_fp_load | is_fp_store) & trans_active);

  // address can be alu_result (i.e. rs1 + iimm/simm) or rs1 (for post-increment load/stores)
  assign ls_addr_sel = is_postincr ? gpr_rdata[0] : alu_result;
  // Mulitplexer using and/or as this signal is likely timing critical.
  assign ls_paddr[PPNSize+PAGE_SHIFT-1:PAGE_SHIFT] =
            (trans_active & dtlb_pa) | (~trans_active & {mseg_q, ls_addr_sel[31:PAGE_SHIFT]});
  assign ls_paddr[PAGE_SHIFT-1:0] = ls_addr_sel[PAGE_SHIFT-1:0];

  assign lsu_qvalid = lsu_tlb_qvalid & trans_ready;
  assign lsu_tlb_qready = lsu_qready & trans_ready;

  // --------------------
  // LSU
  // --------------------
  data_t lsu_qdata;
  // sign exten to appropriate length
  assign lsu_qdata = $unsigned(gpr_rdata[1]);

  snitch_lsu #(
    .AddrWidth (AddrWidth),
    .DataWidth (DataWidth),
    .dreq_t (dreq_t),
    .drsp_t (drsp_t),
    .tag_t (logic[RegWidth-1:0]),
    .NumOutstandingMem (NumIntOutstandingMem),
    .NumOutstandingLoads (NumIntOutstandingLoads)
  ) i_snitch_lsu (
    .clk_i (clk_i),
    .rst_i (rst_i),
    .lsu_qtag_i (rd),
    .lsu_qwrite_i (is_store),
    .lsu_qsigned_i (is_signed),
    .lsu_qaddr_i (ls_paddr),
    .lsu_qdata_i (lsu_qdata),
    .lsu_qsize_i (ls_size),
    .lsu_qamo_i (ls_amo),
    .lsu_qvalid_i (lsu_qvalid),
    .lsu_qready_o (lsu_qready),
    .lsu_pdata_o (ld_result),
    .lsu_ptag_o (lsu_rd),
    .lsu_perror_o (/* ignored for the moment */),
    .lsu_pvalid_o (lsu_pvalid),
    .lsu_pready_i (lsu_pready),
    .lsu_empty_o (lsu_empty),
    .data_req_o,
    .data_rsp_i
  );

  assign lsu_tlb_qvalid = valid_instr & (is_load | is_store)
                                      & ~(ld_addr_misaligned | st_addr_misaligned);

  // retire post-incremented address on rs1 if valid postincr instruction and LSU not stalling
  assign retire_p = write_rs1 & ~stall & (rs1 != 0);
  // we can retire if we are not stalling and if the instruction is writing a register
  assign retire_i = write_rd & valid_instr & (rd != 0);

  // -----------------------
  // Unaligned Address Check
  // -----------------------
  always_comb begin
    ls_misaligned = 1'b0;
    unique case (ls_size)
      HalfWord: if (alu_result[0] != 1'b0) ls_misaligned = 1'b1;
      Word: if (alu_result[1:0] != 2'b00) ls_misaligned = 1'b1;
      Double: if (alu_result[2:0] != 3'b000) ls_misaligned = 1'b1;
      default: ls_misaligned = 1'b0;
    endcase
  end

  assign st_addr_misaligned = ls_misaligned & (is_store | is_fp_store);
  assign ld_addr_misaligned = ls_misaligned & (is_load | is_fp_load);

  // pragma translate_off
  always_ff @(posedge clk_i) begin
    if (!rst_i && (ld_addr_misaligned || st_addr_misaligned) && valid_instr) begin
      $display("%t [Misaligned Load/Store Core %0d] PC: %h Data: %h",
                              $time, hart_id_i, inst_addr_o, inst_data_i);
    end
  end
  // pragma translate_on

  // --------------------
  // Write-Back
  // --------------------
  // Write-back data, can come from:
  // 1. ALU/Jump Target/Bypass
  // 2. LSU
  // 3. Accelerator Bus
  logic [31:0] alu_writeback;
  always_comb begin
    casez (rd_select)
      RdAlu: alu_writeback = alu_result;
      RdConsecPC: alu_writeback = consec_pc;
      RdBypass: alu_writeback = rd_bypass;
      default: alu_writeback = alu_result;
    endcase
  end

  // Determine whether destination register is SSR
  logic is_rd_ssr;
  always_comb begin
    is_rd_ssr = 1'b0;
    for (int s = 0; s < NumSsrs; s++)
      is_rd_ssr |= (IntSsrRegs[s] == rd);
  end

  logic is_ssr_write;
  assign is_ssr_write = ssr_active_q & is_rd_ssr;

  if (RegNrWritePorts == 1) begin
    always_comb begin
      gpr_we[0] = 1'b0;
      gpr_waddr[0] = retire_p ? rs1 : rd; // choose whether to writeback
      gpr_wdata[0] = alu_writeback;
      // external interfaces
      lsu_pready = 1'b0;
      acc_pready_o = 1'b0;
      retire_acc = 1'b0;
      retire_load = 1'b0;
      ssr_wvalid_o = 1'b0;
      ssr_wdone_o = 1'b1;

      if (retire_i | retire_p) begin
        gpr_we[0] = 1'b1;
        if (is_ssr_write) begin
          ssr_wvalid_o = 1'b1;
          // stall write-back to SSR
          if (!ssr_wready_i) begin
            gpr_we[0] = 1'b0;
          end else begin
            ssr_wdone_o = 1'b1;
          end
        end
      // if we are not retiring another instruction retire the load now
      end else if (lsu_pvalid) begin
        retire_load = 1'b1;
        gpr_we[0] = 1'b1;
        gpr_waddr[0] = lsu_rd;
        gpr_wdata[0] = ld_result[31:0];
        lsu_pready = 1'b1;
      end else if (acc_pvalid_i) begin
        retire_acc = 1'b1;
        gpr_we[0] = 1'b1;
        gpr_waddr[0] = acc_prsp_i.id;
        gpr_wdata[0] = acc_prsp_i.data[31:0];
        acc_pready_o = 1'b1;
      end
    end
  end else if (RegNrWritePorts == 2) begin
    always_comb begin
      gpr_we[0] = 1'b0;
      gpr_waddr[0] = retire_p ? rs1 : rd; 
      gpr_wdata[0] = alu_writeback;
      gpr_we[1] = 1'b0;
      gpr_waddr[1] = lsu_rd;
      gpr_wdata[1] = ld_result[31:0];
      //external interfaces
      lsu_pready = 1'b0;
      acc_pready_o = 1'b0;
      retire_acc = 1'b0;
      retire_load = 1'b0;
      ssr_wvalid_o = 1'b0;
      ssr_wdone_o = 1'b1;

      if (retire_i | retire_p) begin
        gpr_we[0] = 1'b1;
        if (lsu_pvalid) begin
          retire_load = 1'b1;
          gpr_we[1] = 1'b1;
          lsu_pready = 1'b1;
        end else if (acc_pvalid_i) begin
          retire_acc = 1'b1;
          gpr_we[1] = 1'b1;
          gpr_waddr[1] = acc_prsp_i.id;
          gpr_wdata[1] = acc_prsp_i.data[31:0];
          acc_pready_o = 1'b1;
        end else if (is_ssr_write) begin
          ssr_wvalid_o = 1'b1;
          gpr_we[0] = 1'b1;
          // stall write-back to SSR
          if (!ssr_wready_i) begin
            gpr_we[0] = 1'b0;
          end else begin
            ssr_wdone_o = 1'b1;
          end
        end 
      // if we are not retiring another instruction retire the load now
      end else begin
        if (acc_pvalid_i) begin
          retire_acc = 1'b1;
          gpr_we[0] = 1'b1;
          gpr_waddr[0] = acc_prsp_i.id;
          gpr_wdata[0] = acc_prsp_i.data[31:0];
          acc_pready_o = 1'b1;
        end
        if (lsu_pvalid) begin
          retire_load = 1'b1;
          gpr_we[1] = 1'b1;
          lsu_pready = 1'b1;
        end      
      end
    end
  end else begin 
    $fatal(1, "[snitch] Unsupported RegNrWritePorts.");
  end 
   
  assign inst_addr_misaligned = (inst_data_i inside {
    JAL,
    JALR,
    BEQ,
    BNE,
    BLT,
    BLTU,
    BGE,
    BGEU
  }) && (consec_pc[1:0] != 2'b0);

  // ----------
  // Assertions
  // ----------
  // Make sure the instruction interface is stable. Otherwise, Snitch might violate the protocol at
  // the LSU or accelerator interface by withdrawing the valid signal.
  // TODO: Remove cacheability attribute, that should hold true for all instruction fetch transacitons.
  `ASSERT(InstructionInterfaceStable,
      (inst_valid_o && inst_ready_i && inst_cacheable_o) ##1 (inst_valid_o && $stable(inst_addr_o))
      |-> inst_ready_i && $stable(inst_data_i), clk_i, rst_i)

  // Snitch is a 32-bit processor so in case the memory subsystem is 64 bit
  // wide, there is a potential of `x`s to be returned. Its a bit of a nasty
  // hack but in case of retiring a load we want to relax the unknown
  // constraints a bit.
  `ASSERT(RegWriteKnown, gpr_we & (gpr_waddr != 0) & !retire_load
                                    |-> !$isunknown(gpr_wdata[0]), clk_i, rst_i)
  // Check that PMA rule counts do not exceed maximum number of rules
  `ASSERT_INIT(CheckPMANonIdempotent,
    SnitchPMACfg.NrNonIdempotentRegionRules <= snitch_pma_pkg::NrMaxRules);
  `ASSERT_INIT(CheckPMAExecute, SnitchPMACfg.NrExecuteRegionRules <= snitch_pma_pkg::NrMaxRules);
  `ASSERT_INIT(CheckPMACached, SnitchPMACfg.NrCachedRegionRules <= snitch_pma_pkg::NrMaxRules);
  `ASSERT_INIT(CheckPMAAMORegion, SnitchPMACfg.NrAMORegionRules <= snitch_pma_pkg::NrMaxRules);

endmodule
