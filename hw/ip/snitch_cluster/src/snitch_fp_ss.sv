// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

`include "common_cells/registers.svh"
`include "common_cells/assertions.svh"

// Floating Point Subsystem
module snitch_fp_ss import snitch_pkg::*; #(
  parameter int unsigned AddrWidth = 32,
  parameter int unsigned DataWidth = 32,
  parameter int unsigned NumFPOutstandingLoads = 0,
  parameter int unsigned NumFPOutstandingMem = 0,
  parameter int unsigned NumFPUSequencerInstr = 0,
  parameter type dreq_t = logic,
  parameter type drsp_t = logic,
  parameter bit RegisterSequencer = 0,
  parameter bit Xfrep = 1,
  parameter fpnew_pkg::fpu_implementation_t FPUImplementation = '0,
  parameter bit Xssr = 1,
  parameter int unsigned NumSsrs = 0,
  parameter logic [NumSsrs-1:0][4:0]  SsrRegs = '0,
  parameter type acc_req_t = logic,
  parameter type acc_resp_t = logic,
  parameter bit RVF = 1,
  parameter bit RVD = 1,
  parameter bit XF16 = 0,
  parameter bit XF16ALT = 0,
  parameter bit XF8 = 0,
  parameter bit XF8ALT = 0,
  parameter bit XFVEC = 0,
  parameter int unsigned FLEN = DataWidth,
  /// Derived parameter *Do not override*
  parameter type addr_t = logic [AddrWidth-1:0],
  parameter type data_t = logic [DataWidth-1:0]
) (
  input  logic             clk_i,
  input  logic             rst_i,
  // pragma translate_off
  output fpu_trace_port_t  trace_port_o,
  output fpu_sequencer_trace_port_t sequencer_tracer_port_o,
  // pragma translate_on
  // Accelerator Interface - Slave
  input  acc_req_t         acc_req_i,
  input  logic             acc_req_valid_i,
  output logic             acc_req_ready_o,
  output acc_resp_t        acc_resp_o,
  output logic             acc_resp_valid_o,
  input  logic             acc_resp_ready_i,
  // TCDM Data Interface for regular FP load/stores.
  output dreq_t            data_req_o,
  input  drsp_t            data_rsp_i,
  // Register Interface
  // FPU **un-timed** Side-channel
  input  fpnew_pkg::roundmode_e fpu_rnd_mode_i,
  input  fpnew_pkg::fmt_mode_t  fpu_fmt_mode_i,
  output fpnew_pkg::status_t    fpu_status_o,
  // SSR Interface
  output logic  [2:0][4:0] ssr_raddr_o,
  input  data_t [2:0]      ssr_rdata_i,
  output logic  [2:0]      ssr_rvalid_o,
  input  logic  [2:0]      ssr_rready_i,
  output logic  [2:0]      ssr_rdone_o,
  output logic  [0:0][4:0] ssr_waddr_o,
  output data_t [0:0]      ssr_wdata_o,
  output logic  [0:0]      ssr_wvalid_o,
  input  logic  [0:0]      ssr_wready_i,
  output logic  [0:0]      ssr_wdone_o,
  // SSR stream control interface
  input  logic             streamctl_done_i,
  input  logic             streamctl_valid_i,
  output logic             streamctl_ready_o,
  // Core event strobes
  output core_events_t core_events_o
);

  fpnew_pkg::operation_e  fpu_op;
  fpnew_pkg::roundmode_e  fpu_rnd_mode;
  fpnew_pkg::fp_format_e  src_fmt, dst_fmt;
  fpnew_pkg::int_format_e int_fmt;
  logic                   vectorial_op;
  logic                   set_dyn_rm;

  logic [2:0][4:0]      fpr_raddr;
  logic [2:0][FLEN-1:0] fpr_rdata;

  logic [0:0]           fpr_we;
  logic [0:0][4:0]      fpr_waddr;
  logic [0:0][FLEN-1:0] fpr_wdata;
  logic [0:0]           fpr_wvalid;
  logic [0:0]           fpr_wready;

  logic ssr_active_d, ssr_active_q;
  `FFSR(ssr_active_q, Xssr & ssr_active_d, 1'b0, clk_i, rst_i)

  typedef struct packed {
    logic       ssr; // write-back to SSR at rd
    logic       acc; // write-back to result bus
    logic [4:0] rd;  // write-back to floating point regfile
  } tag_t;
  tag_t fpu_tag_in, fpu_tag_out;

  logic use_fpu;
  logic [2:0][FLEN-1:0] op;
  logic [2:0] op_ready; // operand is ready

  logic        lsu_qready;
  logic        lsu_qvalid;
  logic [FLEN-1:0] ld_result;
  logic [4:0]  lsu_rd;
  logic        lsu_pvalid;
  logic        lsu_pready;
  logic is_store, is_load;

  logic [31:0] sb_d, sb_q;
  logic rd_is_fp;
  `FFSR(sb_q, sb_d, '0, clk_i, rst_i)

  logic csr_instr;

  // FPU Controller
  logic fpu_out_valid, fpu_out_ready;
  logic fpu_in_valid, fpu_in_ready;

  typedef enum logic [2:0] {
    None,
    AccBus,
    RegA, RegB, RegC,
    RegBRep, // Replication for vectors
    RegDest
  } op_select_e;
  op_select_e [2:0] op_select;

  typedef enum logic [1:0] {
    ResNone, ResAccBus
  } result_select_e;
  result_select_e result_select;

  logic op_mode;

  logic [4:0] rs1, rs2, rs3, rd;

  // LSU
  typedef enum logic [1:0] {
    Byte       = 2'b00,
    HalfWord   = 2'b01,
    Word       = 2'b10,
    DoubleWord = 2'b11
  } ls_size_e;
  ls_size_e ls_size;


  logic dst_ready;

  // -------------
  // FPU Sequencer
  // -------------
  acc_req_t         acc_req, acc_req_q;
  logic             acc_req_valid, acc_req_valid_q;
  logic             acc_req_ready, acc_req_ready_q;
  if (Xfrep) begin : gen_fpu_sequencer
    snitch_sequencer #(
      .AddrWidth (AddrWidth),
      .DataWidth (DataWidth),
      .Depth     (NumFPUSequencerInstr)
    ) i_snitch_fpu_sequencer (
      .clk_i,
      .rst_i,
      // pragma translate_off
      .trace_port_o     ( sequencer_tracer_port_o ),
      // pragma translate_on
      .inp_qaddr_i      ( acc_req_i.addr      ),
      .inp_qid_i        ( acc_req_i.id        ),
      .inp_qdata_op_i   ( acc_req_i.data_op   ),
      .inp_qdata_arga_i ( acc_req_i.data_arga ),
      .inp_qdata_argb_i ( acc_req_i.data_argb ),
      .inp_qdata_argc_i ( acc_req_i.data_argc ),
      .inp_qvalid_i     ( acc_req_valid_i     ),
      .inp_qready_o     ( acc_req_ready_o     ),
      .oup_qaddr_o      ( acc_req.addr        ),
      .oup_qid_o        ( acc_req.id          ),
      .oup_qdata_op_o   ( acc_req.data_op     ),
      .oup_qdata_arga_o ( acc_req.data_arga   ),
      .oup_qdata_argb_o ( acc_req.data_argb   ),
      .oup_qdata_argc_o ( acc_req.data_argc   ),
      .oup_qvalid_o     ( acc_req_valid       ),
      .oup_qready_i     ( acc_req_ready       ),
      .streamctl_done_i,
      .streamctl_valid_i,
      .streamctl_ready_o
    );
  end else begin : gen_no_fpu_sequencer
    // pragma translate_off
    assign sequencer_tracer_port_o = 0;
    // pragma translate_on
    assign acc_req_ready_o = acc_req_ready;
    assign acc_req_valid = acc_req_valid_i;
    assign acc_req = acc_req_i;
  end

  // Optional spill-register
  spill_register  #(
    .T      ( acc_req_t                           ),
    .Bypass ( !RegisterSequencer || !Xfrep )
  ) i_spill_register_acc (
    .clk_i   ,
    .rst_ni  ( ~rst_i          ),
    .valid_i ( acc_req_valid   ),
    .ready_o ( acc_req_ready   ),
    .data_i  ( acc_req         ),
    .valid_o ( acc_req_valid_q ),
    .ready_i ( acc_req_ready_q ),
    .data_o  ( acc_req_q       )
  );

  // this handles WAW Hazards - Potentially this can be relaxed if necessary
  // at the expense of increased timing pressure
  assign dst_ready = ~(rd_is_fp & sb_q[rd]);

  // check that either:
  // 1. The FPU and all operands are ready
  // 2. The LSU request can be handled
  // 3. The regfile operand is ready
  assign fpu_in_valid = use_fpu & acc_req_valid_q & (&op_ready) & dst_ready;
                                      // FPU ready
  assign acc_req_ready_q = dst_ready & ((fpu_in_ready & fpu_in_valid)
                                      // Load/Store
                                      | (lsu_qvalid & lsu_qready)
                                      | csr_instr
                                      // Direct Reg Write
                                      | (acc_req_valid_q && result_select == ResAccBus));

  // either the FPU or the regfile produced a result
  assign acc_resp_valid_o = (fpu_tag_out.acc & fpu_out_valid);
  // stall FPU if we forward from reg
  assign fpu_out_ready = ((fpu_tag_out.acc & acc_resp_ready_i) | (~fpu_tag_out.acc & fpr_wready));

  // FPU Result
  logic [FLEN-1:0] fpu_result;

  // FPU Tag
  assign acc_resp_o.id = fpu_tag_out.rd;
  // accelerator bus write-port
  assign acc_resp_o.data = fpu_result;

  assign rd = acc_req_q.data_op[11:7];
  assign rs1 = acc_req_q.data_op[19:15];
  assign rs2 = acc_req_q.data_op[24:20];
  assign rs3 = acc_req_q.data_op[31:27];

  // Scoreboard/Operand Valid
  // Track floating point destination registers
  always_comb begin
    sb_d = sb_q;
    // if the instruction is going to write the FPR mark it
    if (acc_req_valid_q & acc_req_ready_q & rd_is_fp) sb_d[rd] = 1'b1;
    // reset the value if we are committing the register
    if (fpr_we) sb_d[fpr_waddr] = 1'b0;
    // don't track any dependencies for SSRs if enabled
    if (ssr_active_q) begin
      for (int i = 0; i < NumSsrs; i++) sb_d[SsrRegs[i]] = 1'b0;
    end
  end

  // Determine whether destination register is SSR
  logic is_rd_ssr;
  always_comb begin
    is_rd_ssr = 1'b0;
    for (int s = 0; s < NumSsrs; s++)
      is_rd_ssr |= (SsrRegs[s] == rd);
  end

  always_comb begin
    acc_resp_o.error = 1'b0;
    fpu_op = fpnew_pkg::ADD;
    use_fpu = 1'b1;
    fpu_rnd_mode = (fpnew_pkg::roundmode_e'(acc_req_q.data_op[14:12]) == fpnew_pkg::DYN)
                   ? fpu_rnd_mode_i
                   : fpnew_pkg::roundmode_e'(acc_req_q.data_op[14:12]);

    set_dyn_rm = 1'b0;

    src_fmt = fpnew_pkg::FP32;
    dst_fmt = fpnew_pkg::FP32;
    int_fmt = fpnew_pkg::INT32;

    result_select = ResNone;

    op_select[0] = None;
    op_select[1] = None;
    op_select[2] = None;

    vectorial_op = 1'b0;
    op_mode = 1'b0;

    fpu_tag_in.rd = rd;
    fpu_tag_in.acc = 1'b0; // RD is on accelerator bus
    fpu_tag_in.ssr = ssr_active_q & is_rd_ssr;

    is_store = 1'b0;
    is_load = 1'b0;
    ls_size = Word;

    // Destination register is in FPR
    rd_is_fp = 1'b1;
    csr_instr = 1'b0; // is a csr instruction
    // SSR register
    ssr_active_d = ssr_active_q;
    unique casez (acc_req_q.data_op)
      // FP - FP Operations
      // Single Precision
      riscv_instr::FADD_S: begin
        fpu_op = fpnew_pkg::ADD;
        op_select[1] = RegA;
        op_select[2] = RegB;
      end
      riscv_instr::FSUB_S: begin
        fpu_op = fpnew_pkg::ADD;
        op_select[1] = RegA;
        op_select[2] = RegB;
        op_mode = 1'b1;
      end
      riscv_instr::FMUL_S: begin
        fpu_op = fpnew_pkg::MUL;
        op_select[0] = RegA;
        op_select[1] = RegB;
      end
      riscv_instr::FDIV_S: begin  // currently illegal
        fpu_op = fpnew_pkg::DIV;
        op_select[0] = RegA;
        op_select[1] = RegB;
      end
      riscv_instr::FSGNJ_S,
      riscv_instr::FSGNJN_S,
      riscv_instr::FSGNJX_S: begin
        fpu_op = fpnew_pkg::SGNJ;
        op_select[0] = RegA;
        op_select[1] = RegB;
      end
      riscv_instr::FMIN_S,
      riscv_instr::FMAX_S: begin
        fpu_op = fpnew_pkg::MINMAX;
        op_select[0] = RegA;
        op_select[1] = RegB;
      end
      riscv_instr::FSQRT_S: begin  // currently illegal
        fpu_op = fpnew_pkg::SQRT;
        op_select[0] = RegA;
        op_select[1] = RegA;
      end
      riscv_instr::FMADD_S: begin
        fpu_op = fpnew_pkg::FMADD;
        op_select[0] = RegA;
        op_select[1] = RegB;
        op_select[2] = RegC;
      end
      riscv_instr::FMSUB_S: begin
        fpu_op = fpnew_pkg::FMADD;
        op_select[0] = RegA;
        op_select[1] = RegB;
        op_select[2] = RegC;
        op_mode      = 1'b1;
      end
      riscv_instr::FNMSUB_S: begin
        fpu_op = fpnew_pkg::FNMSUB;
        op_select[0] = RegA;
        op_select[1] = RegB;
        op_select[2] = RegC;
      end
      riscv_instr::FNMADD_S: begin
        fpu_op = fpnew_pkg::FNMSUB;
        op_select[0] = RegA;
        op_select[1] = RegB;
        op_select[2] = RegC;
        op_mode      = 1'b1;
      end
      // Vectorial Single Precision
      riscv_instr::VFADD_S,
      riscv_instr::VFADD_R_S: begin
        fpu_op = fpnew_pkg::ADD;
        op_select[1] = RegA;
        op_select[2] = RegB;
        vectorial_op = 1'b1;
        set_dyn_rm   = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFADD_R_S}) op_select[2] = RegBRep;
      end
      riscv_instr::VFSUB_S,
      riscv_instr::VFSUB_R_S: begin
        fpu_op  = fpnew_pkg::ADD;
        op_select[1] = RegA;
        op_select[2] = RegB;
        op_mode      = 1'b1;
        vectorial_op = 1'b1;
        set_dyn_rm   = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFSUB_R_S}) op_select[2] = RegBRep;
      end
      riscv_instr::VFMUL_S,
      riscv_instr::VFMUL_R_S: begin
        fpu_op = fpnew_pkg::MUL;
        op_select[0] = RegA;
        op_select[1] = RegB;
        vectorial_op = 1'b1;
        set_dyn_rm   = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFMUL_R_S}) op_select[1] = RegBRep;
      end
      riscv_instr::VFDIV_S,
      riscv_instr::VFDIV_R_S: begin  // currently illegal
        fpu_op = fpnew_pkg::DIV;
        op_select[0] = RegA;
        op_select[1] = RegB;
        vectorial_op = 1'b1;
        set_dyn_rm   = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFDIV_R_S}) op_select[1] = RegBRep;
      end
      riscv_instr::VFMIN_S,
      riscv_instr::VFMIN_R_S: begin
        fpu_op = fpnew_pkg::MINMAX;
        op_select[0] = RegA;
        op_select[1] = RegB;
        fpu_rnd_mode = fpnew_pkg::RNE;
        vectorial_op = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFMIN_R_S}) op_select[1] = RegBRep;
      end
      riscv_instr::VFMAX_S,
      riscv_instr::VFMAX_R_S: begin
        fpu_op = fpnew_pkg::MINMAX;
        op_select[0] = RegA;
        op_select[1] = RegB;
        fpu_rnd_mode = fpnew_pkg::RTZ;
        vectorial_op = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFMAX_R_S}) op_select[1] = RegBRep;
      end
      riscv_instr::VFSQRT_S: begin // currently illegal
        fpu_op = fpnew_pkg::SQRT;
        op_select[0] = RegA;
        op_select[1] = RegA;
        vectorial_op = 1'b1;
        set_dyn_rm   = 1'b1;
      end
      riscv_instr::VFMAC_S,
      riscv_instr::VFMAC_R_S: begin
        fpu_op = fpnew_pkg::FMADD;
        op_select[0] = RegA;
        op_select[1] = RegB;
        op_select[2] = RegDest;
        vectorial_op = 1'b1;
        set_dyn_rm   = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFMAC_R_S}) op_select[1] = RegBRep;
      end
      riscv_instr::VFMRE_S,
      riscv_instr::VFMRE_R_S: begin
        fpu_op = fpnew_pkg::FNMSUB;
        op_select[0] = RegA;
        op_select[1] = RegB;
        op_select[2] = RegDest;
        vectorial_op = 1'b1;
        set_dyn_rm   = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFMRE_R_S}) op_select[1] = RegBRep;
      end
      riscv_instr::VFSGNJ_S,
      riscv_instr::VFSGNJ_R_S: begin
        fpu_op = fpnew_pkg::SGNJ;
        op_select[0] = RegA;
        op_select[1] = RegB;
        fpu_rnd_mode = fpnew_pkg::RNE;
        vectorial_op = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFSGNJ_R_S}) op_select[1] = RegBRep;
      end
      riscv_instr::VFSGNJN_S,
      riscv_instr::VFSGNJN_R_S: begin
        fpu_op = fpnew_pkg::SGNJ;
        op_select[0] = RegA;
        op_select[1] = RegB;
        fpu_rnd_mode = fpnew_pkg::RTZ;
        vectorial_op = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFSGNJN_R_S}) op_select[1] = RegBRep;
      end
      riscv_instr::VFSGNJX_S,
      riscv_instr::VFSGNJX_R_S: begin
        fpu_op = fpnew_pkg::SGNJ;
        op_select[0] = RegA;
        op_select[1] = RegB;
        fpu_rnd_mode = fpnew_pkg::RDN;
        vectorial_op = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFSGNJX_R_S}) op_select[1] = RegBRep;
      end
      riscv_instr::VFSUM_S,
      riscv_instr::VFNSUM_S: begin
        fpu_op = fpnew_pkg::VSUM;
        op_select[0] = RegA;
        op_select[2] = RegDest;
        src_fmt      = fpnew_pkg::FP32;
        dst_fmt      = fpnew_pkg::FP32;
        vectorial_op = 1'b1;
        set_dyn_rm   = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFNSUM_S}) op_mode = 1'b1;
      end
      riscv_instr::VFCPKA_S_S: begin
        fpu_op = fpnew_pkg::CPKAB;
        op_select[0] = RegA;
        op_select[1] = RegB;
        vectorial_op = 1'b1;
        set_dyn_rm   = 1'b1;
      end
      riscv_instr::VFCPKA_S_D: begin
        fpu_op = fpnew_pkg::CPKAB;
        op_select[0] = RegA;
        op_select[1] = RegB;
        src_fmt      = fpnew_pkg::FP64;
        vectorial_op = 1'b1;
        set_dyn_rm   = 1'b1;
      end
      // Double Precision
      riscv_instr::FADD_D: begin
        fpu_op = fpnew_pkg::ADD;
        op_select[1] = RegA;
        op_select[2] = RegB;
        src_fmt      = fpnew_pkg::FP64;
        dst_fmt      = fpnew_pkg::FP64;
      end
      riscv_instr::FSUB_D: begin
        fpu_op = fpnew_pkg::ADD;
        op_select[1] = RegA;
        op_select[2] = RegB;
        op_mode = 1'b1;
        src_fmt      = fpnew_pkg::FP64;
        dst_fmt      = fpnew_pkg::FP64;
      end
      riscv_instr::FMUL_D: begin
        fpu_op = fpnew_pkg::MUL;
        op_select[0] = RegA;
        op_select[1] = RegB;
        src_fmt      = fpnew_pkg::FP64;
        dst_fmt      = fpnew_pkg::FP64;
      end
      riscv_instr::FDIV_D: begin
        fpu_op = fpnew_pkg::DIV;
        op_select[0] = RegA;
        op_select[1] = RegB;
        src_fmt      = fpnew_pkg::FP64;
        dst_fmt      = fpnew_pkg::FP64;
      end
      riscv_instr::FSGNJ_D,
      riscv_instr::FSGNJN_D,
      riscv_instr::FSGNJX_D: begin
        fpu_op = fpnew_pkg::SGNJ;
        op_select[0] = RegA;
        op_select[1] = RegB;
        src_fmt      = fpnew_pkg::FP64;
        dst_fmt      = fpnew_pkg::FP64;
      end
      riscv_instr::FMIN_D,
      riscv_instr::FMAX_D: begin
        fpu_op = fpnew_pkg::MINMAX;
        op_select[0] = RegA;
        op_select[1] = RegB;
        src_fmt      = fpnew_pkg::FP64;
        dst_fmt      = fpnew_pkg::FP64;
      end
      riscv_instr::FSQRT_D: begin
        fpu_op = fpnew_pkg::SQRT;
        op_select[0] = RegA;
        op_select[1] = RegA;
        src_fmt      = fpnew_pkg::FP64;
        dst_fmt      = fpnew_pkg::FP64;
      end
      riscv_instr::FMADD_D: begin
        fpu_op = fpnew_pkg::FMADD;
        op_select[0] = RegA;
        op_select[1] = RegB;
        op_select[2] = RegC;
        src_fmt      = fpnew_pkg::FP64;
        dst_fmt      = fpnew_pkg::FP64;
      end
      riscv_instr::FMSUB_D: begin
        fpu_op = fpnew_pkg::FMADD;
        op_select[0] = RegA;
        op_select[1] = RegB;
        op_select[2] = RegC;
        op_mode      = 1'b1;
        src_fmt      = fpnew_pkg::FP64;
        dst_fmt      = fpnew_pkg::FP64;
      end
      riscv_instr::FNMSUB_D: begin
        fpu_op = fpnew_pkg::FNMSUB;
        op_select[0] = RegA;
        op_select[1] = RegB;
        op_select[2] = RegC;
        src_fmt      = fpnew_pkg::FP64;
        dst_fmt      = fpnew_pkg::FP64;
      end
      riscv_instr::FNMADD_D: begin
        fpu_op = fpnew_pkg::FNMSUB;
        op_select[0] = RegA;
        op_select[1] = RegB;
        op_select[2] = RegC;
        op_mode      = 1'b1;
        src_fmt      = fpnew_pkg::FP64;
        dst_fmt      = fpnew_pkg::FP64;
      end
      riscv_instr::FCVT_S_D: begin
        fpu_op = fpnew_pkg::F2F;
        op_select[0] = RegA;
        op_select[1] = RegB;
        src_fmt      = fpnew_pkg::FP64;
        dst_fmt      = fpnew_pkg::FP32;
      end
      riscv_instr::FCVT_D_S: begin
        fpu_op = fpnew_pkg::F2F;
        op_select[0] = RegA;
        op_select[1] = RegB;
        src_fmt      = fpnew_pkg::FP32;
        dst_fmt      = fpnew_pkg::FP64;
      end
      // [Alternate] Half Precision
      riscv_instr::FADD_H: begin
        fpu_op = fpnew_pkg::ADD;
        op_select[1] = RegA;
        op_select[2] = RegB;
        src_fmt      = fpnew_pkg::FP16;
        dst_fmt      = fpnew_pkg::FP16;
        if (fpu_fmt_mode_i.dst == 1'b1) begin
          src_fmt    = fpnew_pkg::FP16ALT;
          dst_fmt    = fpnew_pkg::FP16ALT;
        end
      end
      riscv_instr::FSUB_H: begin
        fpu_op = fpnew_pkg::ADD;
        op_select[1] = RegA;
        op_select[2] = RegB;
        op_mode = 1'b1;
        src_fmt      = fpnew_pkg::FP16;
        dst_fmt      = fpnew_pkg::FP16;
        if (fpu_fmt_mode_i.dst == 1'b1) begin
          src_fmt    = fpnew_pkg::FP16ALT;
          dst_fmt    = fpnew_pkg::FP16ALT;
        end
      end
      riscv_instr::FMUL_H: begin
        fpu_op = fpnew_pkg::MUL;
        op_select[0] = RegA;
        op_select[1] = RegB;
        src_fmt      = fpnew_pkg::FP16;
        dst_fmt      = fpnew_pkg::FP16;
        if (fpu_fmt_mode_i.dst == 1'b1) begin
          src_fmt    = fpnew_pkg::FP16ALT;
          dst_fmt    = fpnew_pkg::FP16ALT;
        end
      end
      riscv_instr::FDIV_H: begin
        fpu_op = fpnew_pkg::DIV;
        op_select[0] = RegA;
        op_select[1] = RegB;
        src_fmt      = fpnew_pkg::FP16;
        dst_fmt      = fpnew_pkg::FP16;
        if (fpu_fmt_mode_i.dst == 1'b1) begin
          src_fmt    = fpnew_pkg::FP16ALT;
          dst_fmt    = fpnew_pkg::FP16ALT;
        end
      end
      riscv_instr::FSGNJ_H,
      riscv_instr::FSGNJN_H,
      riscv_instr::FSGNJX_H: begin
        fpu_op = fpnew_pkg::SGNJ;
        op_select[0] = RegA;
        op_select[1] = RegB;
        src_fmt      = fpnew_pkg::FP16;
        dst_fmt      = fpnew_pkg::FP16;
        if (fpu_fmt_mode_i.dst == 1'b1) begin
          src_fmt    = fpnew_pkg::FP16ALT;
          dst_fmt    = fpnew_pkg::FP16ALT;
        end
      end
      riscv_instr::FMIN_H,
      riscv_instr::FMAX_H: begin
        fpu_op = fpnew_pkg::MINMAX;
        op_select[0] = RegA;
        op_select[1] = RegB;
        src_fmt      = fpnew_pkg::FP16;
        dst_fmt      = fpnew_pkg::FP16;
        if (fpu_fmt_mode_i.dst == 1'b1) begin
          src_fmt    = fpnew_pkg::FP16ALT;
          dst_fmt    = fpnew_pkg::FP16ALT;
        end
      end
      riscv_instr::FSQRT_H: begin
        fpu_op = fpnew_pkg::SQRT;
        op_select[0] = RegA;
        op_select[1] = RegA;
        src_fmt      = fpnew_pkg::FP16;
        dst_fmt      = fpnew_pkg::FP16;
        if (fpu_fmt_mode_i.dst == 1'b1) begin
          src_fmt    = fpnew_pkg::FP16ALT;
          dst_fmt    = fpnew_pkg::FP16ALT;
        end
      end
      riscv_instr::FMADD_H: begin
        fpu_op = fpnew_pkg::FMADD;
        op_select[0] = RegA;
        op_select[1] = RegB;
        op_select[2] = RegC;
        src_fmt      = fpnew_pkg::FP16;
        dst_fmt      = fpnew_pkg::FP16;
        if (fpu_fmt_mode_i.dst == 1'b1) begin
          src_fmt    = fpnew_pkg::FP16ALT;
          dst_fmt    = fpnew_pkg::FP16ALT;
        end
      end
      riscv_instr::FMSUB_H: begin
        fpu_op = fpnew_pkg::FMADD;
        op_select[0] = RegA;
        op_select[1] = RegB;
        op_select[2] = RegC;
        op_mode      = 1'b1;
        src_fmt      = fpnew_pkg::FP16;
        dst_fmt      = fpnew_pkg::FP16;
        if (fpu_fmt_mode_i.dst == 1'b1) begin
          src_fmt    = fpnew_pkg::FP16ALT;
          dst_fmt    = fpnew_pkg::FP16ALT;
        end
      end
      riscv_instr::FNMSUB_H: begin
        fpu_op = fpnew_pkg::FNMSUB;
        op_select[0] = RegA;
        op_select[1] = RegB;
        op_select[2] = RegC;
        src_fmt      = fpnew_pkg::FP16;
        dst_fmt      = fpnew_pkg::FP16;
        if (fpu_fmt_mode_i.dst == 1'b1) begin
          src_fmt    = fpnew_pkg::FP16ALT;
          dst_fmt    = fpnew_pkg::FP16ALT;
        end
      end
      riscv_instr::FNMADD_H: begin
        fpu_op = fpnew_pkg::FNMSUB;
        op_select[0] = RegA;
        op_select[1] = RegB;
        op_select[2] = RegC;
        op_mode      = 1'b1;
        src_fmt      = fpnew_pkg::FP16;
        dst_fmt      = fpnew_pkg::FP16;
        if (fpu_fmt_mode_i.dst == 1'b1) begin
          src_fmt    = fpnew_pkg::FP16ALT;
          dst_fmt    = fpnew_pkg::FP16ALT;
        end
      end
      riscv_instr::VFSUM_H,
      riscv_instr::VFNSUM_H: begin
        fpu_op = fpnew_pkg::VSUM;
        op_select[0] = RegA;
        op_select[2] = RegDest;
        src_fmt      = fpnew_pkg::FP16;
        dst_fmt      = fpnew_pkg::FP16;
        vectorial_op = 1'b1;
        set_dyn_rm   = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFNSUM_H}) op_mode = 1'b1;
      end
      riscv_instr::FMULEX_S_H: begin
        fpu_op = fpnew_pkg::MUL;
        op_select[0] = RegA;
        op_select[1] = RegB;
        src_fmt      = fpnew_pkg::FP16;
        dst_fmt      = fpnew_pkg::FP32;
      end
      riscv_instr::FMACEX_S_H: begin
        fpu_op = fpnew_pkg::FMADD;
        op_select[0] = RegA;
        op_select[1] = RegB;
        op_select[2] = RegC;
        src_fmt      = fpnew_pkg::FP16;
        dst_fmt      = fpnew_pkg::FP32;
      end
      riscv_instr::FCVT_S_H: begin
        fpu_op = fpnew_pkg::F2F;
        op_select[0] = RegA;
        op_select[1] = RegB;
        src_fmt      = fpnew_pkg::FP16;
        dst_fmt      = fpnew_pkg::FP32;
      end
      riscv_instr::FCVT_H_S: begin
        fpu_op = fpnew_pkg::F2F;
        op_select[0] = RegA;
        op_select[1] = RegB;
        src_fmt      = fpnew_pkg::FP32;
        dst_fmt      = fpnew_pkg::FP16;
      end
      riscv_instr::FCVT_D_H: begin
        fpu_op = fpnew_pkg::F2F;
        op_select[0] = RegA;
        op_select[1] = RegB;
        src_fmt      = fpnew_pkg::FP16;
        dst_fmt      = fpnew_pkg::FP64;
      end
      riscv_instr::FCVT_H_D: begin
        fpu_op = fpnew_pkg::F2F;
        op_select[0] = RegA;
        op_select[1] = RegB;
        src_fmt      = fpnew_pkg::FP64;
        dst_fmt      = fpnew_pkg::FP16;
      end
      riscv_instr::FCVT_H_H: begin
        fpu_op = fpnew_pkg::F2F;
        op_select[0] = RegA;
        op_select[1] = RegB;
        src_fmt      = fpnew_pkg::FP16;
        dst_fmt      = fpnew_pkg::FP16;
      end
      // Vectorial [alternate] Half Precision
      riscv_instr::VFADD_H,
      riscv_instr::VFADD_R_H: begin
        fpu_op = fpnew_pkg::ADD;
        op_select[1] = RegA;
        op_select[2] = RegB;
        src_fmt      = fpnew_pkg::FP16;
        dst_fmt      = fpnew_pkg::FP16;
        if (fpu_fmt_mode_i.dst == 1'b1) begin
          src_fmt    = fpnew_pkg::FP16ALT;
          dst_fmt    = fpnew_pkg::FP16ALT;
        end
        vectorial_op = 1'b1;
        set_dyn_rm   = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFADD_R_H}) op_select[2] = RegBRep;
      end
      riscv_instr::VFSUB_H,
      riscv_instr::VFSUB_R_H: begin
        fpu_op  = fpnew_pkg::ADD;
        op_select[1] = RegA;
        op_select[2] = RegB;
        op_mode      = 1'b1;
        src_fmt      = fpnew_pkg::FP16;
        dst_fmt      = fpnew_pkg::FP16;
        if (fpu_fmt_mode_i.dst == 1'b1) begin
          src_fmt    = fpnew_pkg::FP16ALT;
          dst_fmt    = fpnew_pkg::FP16ALT;
        end
        vectorial_op = 1'b1;
        set_dyn_rm   = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFSUB_R_H}) op_select[2] = RegBRep;
      end
      riscv_instr::VFMUL_H,
      riscv_instr::VFMUL_R_H: begin
        fpu_op = fpnew_pkg::MUL;
        op_select[0] = RegA;
        op_select[1] = RegB;
        src_fmt      = fpnew_pkg::FP16;
        dst_fmt      = fpnew_pkg::FP16;
        if (fpu_fmt_mode_i.dst == 1'b1) begin
          src_fmt    = fpnew_pkg::FP16ALT;
          dst_fmt    = fpnew_pkg::FP16ALT;
        end
        vectorial_op = 1'b1;
        set_dyn_rm   = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFMUL_R_H}) op_select[1] = RegBRep;
      end
      riscv_instr::VFDIV_H,
      riscv_instr::VFDIV_R_H: begin
        fpu_op = fpnew_pkg::DIV;
        op_select[0] = RegA;
        op_select[1] = RegB;
        src_fmt      = fpnew_pkg::FP16;
        dst_fmt      = fpnew_pkg::FP16;
        if (fpu_fmt_mode_i.dst == 1'b1) begin
          src_fmt    = fpnew_pkg::FP16ALT;
          dst_fmt    = fpnew_pkg::FP16ALT;
        end
        vectorial_op = 1'b1;
        set_dyn_rm   = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFDIV_R_H}) op_select[1] = RegBRep;
      end
      riscv_instr::VFMIN_H,
      riscv_instr::VFMIN_R_H: begin
        fpu_op = fpnew_pkg::MINMAX;
        op_select[0] = RegA;
        op_select[1] = RegB;
        fpu_rnd_mode = fpnew_pkg::RNE;
        src_fmt      = fpnew_pkg::FP16;
        dst_fmt      = fpnew_pkg::FP16;
        if (fpu_fmt_mode_i.dst == 1'b1) begin
          src_fmt    = fpnew_pkg::FP16ALT;
          dst_fmt    = fpnew_pkg::FP16ALT;
        end
        vectorial_op = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFMIN_R_H}) op_select[1] = RegBRep;
      end
      riscv_instr::VFMAX_H,
      riscv_instr::VFMAX_R_H: begin
        fpu_op = fpnew_pkg::MINMAX;
        op_select[0] = RegA;
        op_select[1] = RegB;
        src_fmt      = fpnew_pkg::FP16;
        dst_fmt      = fpnew_pkg::FP16;
        if (fpu_fmt_mode_i.dst == 1'b1) begin
          src_fmt    = fpnew_pkg::FP16ALT;
          dst_fmt    = fpnew_pkg::FP16ALT;
        end
        fpu_rnd_mode = fpnew_pkg::RTZ;
        vectorial_op = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFMAX_R_H}) op_select[1] = RegBRep;
      end
      riscv_instr::VFSQRT_H: begin
        fpu_op = fpnew_pkg::SQRT;
        op_select[0] = RegA;
        op_select[1] = RegA;
        src_fmt      = fpnew_pkg::FP16;
        dst_fmt      = fpnew_pkg::FP16;
        if (fpu_fmt_mode_i.dst == 1'b1) begin
          src_fmt    = fpnew_pkg::FP16ALT;
          dst_fmt    = fpnew_pkg::FP16ALT;
        end
        vectorial_op = 1'b1;
        set_dyn_rm   = 1'b1;
      end
      riscv_instr::VFMAC_H,
      riscv_instr::VFMAC_R_H: begin
        fpu_op = fpnew_pkg::FMADD;
        op_select[0] = RegA;
        op_select[1] = RegB;
        op_select[2] = RegDest;
        src_fmt      = fpnew_pkg::FP16;
        dst_fmt      = fpnew_pkg::FP16;
        if (fpu_fmt_mode_i.dst == 1'b1) begin
          src_fmt    = fpnew_pkg::FP16ALT;
          dst_fmt    = fpnew_pkg::FP16ALT;
        end
        vectorial_op = 1'b1;
        set_dyn_rm   = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFMAC_R_H}) op_select[1] = RegBRep;
      end
      riscv_instr::VFMRE_H,
      riscv_instr::VFMRE_R_H: begin
        fpu_op = fpnew_pkg::FNMSUB;
        op_select[0] = RegA;
        op_select[1] = RegB;
        op_select[2] = RegDest;
        src_fmt      = fpnew_pkg::FP16;
        dst_fmt      = fpnew_pkg::FP16;
        if (fpu_fmt_mode_i.dst == 1'b1) begin
          src_fmt    = fpnew_pkg::FP16ALT;
          dst_fmt    = fpnew_pkg::FP16ALT;
        end
        vectorial_op = 1'b1;
        set_dyn_rm   = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFMRE_R_H}) op_select[1] = RegBRep;
      end
      riscv_instr::VFSGNJ_H,
      riscv_instr::VFSGNJ_R_H: begin
        fpu_op = fpnew_pkg::SGNJ;
        op_select[0] = RegA;
        op_select[1] = RegB;
        fpu_rnd_mode = fpnew_pkg::RNE;
        src_fmt      = fpnew_pkg::FP16;
        dst_fmt      = fpnew_pkg::FP16;
        if (fpu_fmt_mode_i.dst == 1'b1) begin
          src_fmt    = fpnew_pkg::FP16ALT;
          dst_fmt    = fpnew_pkg::FP16ALT;
        end
        vectorial_op = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFSGNJ_R_H}) op_select[1] = RegBRep;
      end
      riscv_instr::VFSGNJN_H,
      riscv_instr::VFSGNJN_R_H: begin
        fpu_op = fpnew_pkg::SGNJ;
        op_select[0] = RegA;
        op_select[1] = RegB;
        fpu_rnd_mode = fpnew_pkg::RTZ;
        src_fmt      = fpnew_pkg::FP16;
        dst_fmt      = fpnew_pkg::FP16;
        if (fpu_fmt_mode_i.dst == 1'b1) begin
          src_fmt    = fpnew_pkg::FP16ALT;
          dst_fmt    = fpnew_pkg::FP16ALT;
        end
        vectorial_op = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFSGNJN_R_H}) op_select[1] = RegBRep;
      end
      riscv_instr::VFSGNJX_H,
      riscv_instr::VFSGNJX_R_H: begin
        fpu_op = fpnew_pkg::SGNJ;
        op_select[0] = RegA;
        op_select[1] = RegB;
        fpu_rnd_mode = fpnew_pkg::RDN;
        src_fmt      = fpnew_pkg::FP16;
        dst_fmt      = fpnew_pkg::FP16;
        if (fpu_fmt_mode_i.dst == 1'b1) begin
          src_fmt    = fpnew_pkg::FP16ALT;
          dst_fmt    = fpnew_pkg::FP16ALT;
        end
        vectorial_op = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFSGNJX_R_H}) op_select[1] = RegBRep;
      end
      riscv_instr::VFCPKA_H_S: begin
        fpu_op = fpnew_pkg::CPKAB;
        op_select[0] = RegA;
        op_select[1] = RegB;
        op_select[2] = RegDest;
        src_fmt      = fpnew_pkg::FP32;
        dst_fmt      = fpnew_pkg::FP16;
        vectorial_op = 1'b1;
        set_dyn_rm   = 1'b1;
      end
      riscv_instr::VFCPKB_H_S: begin
        fpu_op = fpnew_pkg::CPKAB;
        op_select[0] = RegA;
        op_select[1] = RegB;
        op_select[2] = RegDest;
        op_mode      = 1'b1;
        src_fmt      = fpnew_pkg::FP32;
        dst_fmt      = fpnew_pkg::FP16;
        vectorial_op = 1'b1;
        set_dyn_rm   = 1'b1;
      end
      riscv_instr::VFCVT_S_H,
      riscv_instr::VFCVTU_S_H: begin
        fpu_op = fpnew_pkg::F2F;
        op_select[0] = RegA;
        op_select[1] = RegB;
        src_fmt      = fpnew_pkg::FP16;
        dst_fmt      = fpnew_pkg::FP32;
        vectorial_op = 1'b1;
        set_dyn_rm   = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFCVTU_S_H}) op_mode = 1'b1;
      end
      riscv_instr::VFCVT_H_S,
      riscv_instr::VFCVTU_H_S: begin
        fpu_op = fpnew_pkg::F2F;
        op_select[0] = RegA;
        op_select[1] = RegB;
        src_fmt      = fpnew_pkg::FP32;
        dst_fmt      = fpnew_pkg::FP16;
        vectorial_op = 1'b1;
        set_dyn_rm   = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFCVTU_H_S}) op_mode = 1'b1;
      end
      riscv_instr::VFCPKA_H_D: begin
        fpu_op = fpnew_pkg::CPKAB;
        op_select[0] = RegA;
        op_select[1] = RegB;
        op_select[2] = RegDest;
        src_fmt      = fpnew_pkg::FP64;
        dst_fmt      = fpnew_pkg::FP16;
        vectorial_op = 1'b1;
        set_dyn_rm   = 1'b1;
      end
      riscv_instr::VFCPKB_H_D: begin
        fpu_op = fpnew_pkg::CPKAB;
        op_select[0] = RegA;
        op_select[1] = RegB;
        op_select[2] = RegDest;
        op_mode      = 1'b1;
        src_fmt      = fpnew_pkg::FP64;
        dst_fmt      = fpnew_pkg::FP16;
        vectorial_op = 1'b1;
        set_dyn_rm   = 1'b1;
      end
      riscv_instr::VFDOTPEX_S_H,
      riscv_instr::VFDOTPEX_S_R_H: begin
        fpu_op = fpnew_pkg::SDOTP;
        op_select[0] = RegA;
        op_select[1] = RegB;
        op_select[2] = RegDest;
        src_fmt      = fpnew_pkg::FP16;
        dst_fmt      = fpnew_pkg::FP32;
        vectorial_op = 1'b1;
        set_dyn_rm   = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFDOTPEX_S_R_H}) op_select[2] = RegBRep;
      end
      riscv_instr::VFNDOTPEX_S_H,
      riscv_instr::VFNDOTPEX_S_R_H: begin
        fpu_op = fpnew_pkg::SDOTP;
        op_select[0] = RegA;
        op_select[1] = RegB;
        op_select[2] = RegDest;
        op_mode      = 1'b1;
        src_fmt      = fpnew_pkg::FP16;
        dst_fmt      = fpnew_pkg::FP32;
        vectorial_op = 1'b1;
        set_dyn_rm   = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFNDOTPEX_S_R_H}) op_select[2] = RegBRep;
      end
      riscv_instr::VFSUMEX_S_H,
      riscv_instr::VFNSUMEX_S_H: begin
        fpu_op = fpnew_pkg::EXVSUM;
        op_select[0] = RegA;
        op_select[2] = RegDest;
        src_fmt      = fpnew_pkg::FP16;
        dst_fmt      = fpnew_pkg::FP32;
        vectorial_op = 1'b1;
        set_dyn_rm   = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFNSUMEX_S_H}) op_mode = 1'b1;
      end
      // [Alternate] Quarter Precision
      riscv_instr::FADD_B: begin
        fpu_op = fpnew_pkg::ADD;
        op_select[1] = RegA;
        op_select[2] = RegB;
        src_fmt      = fpnew_pkg::FP8;
        dst_fmt      = fpnew_pkg::FP8;
        if (fpu_fmt_mode_i.dst == 1'b1) begin
          src_fmt    = fpnew_pkg::FP8ALT;
          dst_fmt    = fpnew_pkg::FP8ALT;
        end
      end
      riscv_instr::FSUB_B: begin
        fpu_op = fpnew_pkg::ADD;
        op_select[1] = RegA;
        op_select[2] = RegB;
        op_mode = 1'b1;
        src_fmt      = fpnew_pkg::FP8;
        dst_fmt      = fpnew_pkg::FP8;
        if (fpu_fmt_mode_i.dst == 1'b1) begin
          src_fmt    = fpnew_pkg::FP8ALT;
          dst_fmt    = fpnew_pkg::FP8ALT;
        end
      end
      riscv_instr::FMUL_B: begin
        fpu_op = fpnew_pkg::MUL;
        op_select[0] = RegA;
        op_select[1] = RegB;
        src_fmt      = fpnew_pkg::FP8;
        dst_fmt      = fpnew_pkg::FP8;
        if (fpu_fmt_mode_i.dst == 1'b1) begin
          src_fmt    = fpnew_pkg::FP8ALT;
          dst_fmt    = fpnew_pkg::FP8ALT;
        end
      end
      riscv_instr::FDIV_B: begin
        fpu_op = fpnew_pkg::DIV;
        op_select[0] = RegA;
        op_select[1] = RegB;
        src_fmt      = fpnew_pkg::FP8;
        dst_fmt      = fpnew_pkg::FP8;
        if (fpu_fmt_mode_i.dst == 1'b1) begin
          src_fmt    = fpnew_pkg::FP8ALT;
          dst_fmt    = fpnew_pkg::FP8ALT;
        end
      end
      riscv_instr::FSGNJ_B,
      riscv_instr::FSGNJN_B,
      riscv_instr::FSGNJX_B: begin
        fpu_op = fpnew_pkg::SGNJ;
        op_select[0] = RegA;
        op_select[1] = RegB;
        src_fmt      = fpnew_pkg::FP8;
        dst_fmt      = fpnew_pkg::FP8;
        if (fpu_fmt_mode_i.dst == 1'b1) begin
          src_fmt    = fpnew_pkg::FP8ALT;
          dst_fmt    = fpnew_pkg::FP8ALT;
        end
      end
      riscv_instr::FMIN_B,
      riscv_instr::FMAX_B: begin
        fpu_op = fpnew_pkg::MINMAX;
        op_select[0] = RegA;
        op_select[1] = RegB;
        src_fmt      = fpnew_pkg::FP8;
        dst_fmt      = fpnew_pkg::FP8;
        if (fpu_fmt_mode_i.dst == 1'b1) begin
          src_fmt    = fpnew_pkg::FP8ALT;
          dst_fmt    = fpnew_pkg::FP8ALT;
        end
      end
      riscv_instr::FSQRT_B: begin
        fpu_op = fpnew_pkg::SQRT;
        op_select[0] = RegA;
        op_select[1] = RegA;
        src_fmt      = fpnew_pkg::FP8;
        dst_fmt      = fpnew_pkg::FP8;
        if (fpu_fmt_mode_i.dst == 1'b1) begin
          src_fmt    = fpnew_pkg::FP8ALT;
          dst_fmt    = fpnew_pkg::FP8ALT;
        end
      end
      riscv_instr::FMADD_B: begin
        fpu_op = fpnew_pkg::FMADD;
        op_select[0] = RegA;
        op_select[1] = RegB;
        op_select[2] = RegC;
        src_fmt      = fpnew_pkg::FP8;
        dst_fmt      = fpnew_pkg::FP8;
        if (fpu_fmt_mode_i.dst == 1'b1) begin
          src_fmt    = fpnew_pkg::FP8ALT;
          dst_fmt    = fpnew_pkg::FP8ALT;
        end
      end
      riscv_instr::FMSUB_B: begin
        fpu_op = fpnew_pkg::FMADD;
        op_select[0] = RegA;
        op_select[1] = RegB;
        op_select[2] = RegC;
        op_mode      = 1'b1;
        src_fmt      = fpnew_pkg::FP8;
        dst_fmt      = fpnew_pkg::FP8;
        if (fpu_fmt_mode_i.dst == 1'b1) begin
          src_fmt    = fpnew_pkg::FP8ALT;
          dst_fmt    = fpnew_pkg::FP8ALT;
        end
      end
      riscv_instr::FNMSUB_B: begin
        fpu_op = fpnew_pkg::FNMSUB;
        op_select[0] = RegA;
        op_select[1] = RegB;
        op_select[2] = RegC;
        src_fmt      = fpnew_pkg::FP8;
        dst_fmt      = fpnew_pkg::FP8;
        if (fpu_fmt_mode_i.dst == 1'b1) begin
          src_fmt    = fpnew_pkg::FP8ALT;
          dst_fmt    = fpnew_pkg::FP8ALT;
        end
      end
      riscv_instr::FNMADD_B: begin
        fpu_op = fpnew_pkg::FNMSUB;
        op_select[0] = RegA;
        op_select[1] = RegB;
        op_select[2] = RegC;
        op_mode      = 1'b1;
        src_fmt      = fpnew_pkg::FP8;
        dst_fmt      = fpnew_pkg::FP8;
        if (fpu_fmt_mode_i.dst == 1'b1) begin
          src_fmt    = fpnew_pkg::FP8ALT;
          dst_fmt    = fpnew_pkg::FP8ALT;
        end
      end
      riscv_instr::VFSUM_B,
      riscv_instr::VFNSUM_B: begin
        fpu_op = fpnew_pkg::VSUM;
        op_select[0] = RegA;
        op_select[2] = RegDest;
        src_fmt      = fpnew_pkg::FP8;
        dst_fmt      = fpnew_pkg::FP8;
        vectorial_op = 1'b1;
        set_dyn_rm   = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFNSUM_B}) op_mode = 1'b1;
      end
      riscv_instr::FMULEX_S_B: begin
        fpu_op = fpnew_pkg::MUL;
        op_select[0] = RegA;
        op_select[1] = RegB;
        src_fmt      = fpnew_pkg::FP8;
        dst_fmt      = fpnew_pkg::FP32;
      end
      riscv_instr::FMACEX_S_B: begin
        fpu_op = fpnew_pkg::FMADD;
        op_select[0] = RegA;
        op_select[1] = RegB;
        op_select[2] = RegDest;
        src_fmt      = fpnew_pkg::FP8;
        dst_fmt      = fpnew_pkg::FP32;
      end
      riscv_instr::FCVT_S_B: begin
        fpu_op = fpnew_pkg::F2F;
        op_select[0] = RegA;
        op_select[1] = RegB;
        src_fmt      = fpnew_pkg::FP8;
        dst_fmt      = fpnew_pkg::FP32;
      end
      riscv_instr::FCVT_B_S: begin
        fpu_op = fpnew_pkg::F2F;
        op_select[0] = RegA;
        op_select[1] = RegB;
        src_fmt      = fpnew_pkg::FP32;
        dst_fmt      = fpnew_pkg::FP8;
      end
      riscv_instr::FCVT_D_B: begin
        fpu_op = fpnew_pkg::F2F;
        op_select[0] = RegA;
        op_select[1] = RegB;
        src_fmt      = fpnew_pkg::FP8;
        dst_fmt      = fpnew_pkg::FP64;
      end
      riscv_instr::FCVT_B_D: begin
        fpu_op = fpnew_pkg::F2F;
        op_select[0] = RegA;
        op_select[1] = RegB;
        src_fmt      = fpnew_pkg::FP64;
        dst_fmt      = fpnew_pkg::FP8;
      end
      riscv_instr::FCVT_H_B: begin
        fpu_op = fpnew_pkg::F2F;
        op_select[0] = RegA;
        op_select[1] = RegB;
        src_fmt      = fpnew_pkg::FP8;
        dst_fmt      = fpnew_pkg::FP16;
      end
      riscv_instr::FCVT_B_H: begin
        fpu_op = fpnew_pkg::F2F;
        op_select[0] = RegA;
        op_select[1] = RegB;
        src_fmt      = fpnew_pkg::FP16;
        dst_fmt      = fpnew_pkg::FP8;
      end
      // Vectorial [alternate] Quarter Precision
      riscv_instr::VFADD_B,
      riscv_instr::VFADD_R_B: begin
        fpu_op = fpnew_pkg::ADD;
        op_select[1] = RegA;
        op_select[2] = RegB;
        src_fmt      = fpnew_pkg::FP8;
        dst_fmt      = fpnew_pkg::FP8;
        if (fpu_fmt_mode_i.dst == 1'b1) begin
          src_fmt    = fpnew_pkg::FP8ALT;
          dst_fmt    = fpnew_pkg::FP8ALT;
        end
        vectorial_op = 1'b1;
        set_dyn_rm   = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFADD_R_B}) op_select[2] = RegBRep;
      end
      riscv_instr::VFSUB_B,
      riscv_instr::VFSUB_R_B: begin
        fpu_op  = fpnew_pkg::ADD;
        op_select[1] = RegA;
        op_select[2] = RegB;
        op_mode      = 1'b1;
        src_fmt      = fpnew_pkg::FP8;
        dst_fmt      = fpnew_pkg::FP8;
        if (fpu_fmt_mode_i.dst == 1'b1) begin
          src_fmt    = fpnew_pkg::FP8ALT;
          dst_fmt    = fpnew_pkg::FP8ALT;
        end
        vectorial_op = 1'b1;
        set_dyn_rm   = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFSUB_R_B}) op_select[2] = RegBRep;
      end
      riscv_instr::VFMUL_B,
      riscv_instr::VFMUL_R_B: begin
        fpu_op = fpnew_pkg::MUL;
        op_select[0] = RegA;
        op_select[1] = RegB;
        src_fmt      = fpnew_pkg::FP8;
        dst_fmt      = fpnew_pkg::FP8;
        if (fpu_fmt_mode_i.dst == 1'b1) begin
          src_fmt    = fpnew_pkg::FP8ALT;
          dst_fmt    = fpnew_pkg::FP8ALT;
        end
        vectorial_op = 1'b1;
        set_dyn_rm   = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFMUL_R_B}) op_select[1] = RegBRep;
      end
      riscv_instr::VFDIV_B,
      riscv_instr::VFDIV_R_B: begin
        fpu_op = fpnew_pkg::DIV;
        op_select[0] = RegA;
        op_select[1] = RegB;
        src_fmt      = fpnew_pkg::FP8;
        dst_fmt      = fpnew_pkg::FP8;
        if (fpu_fmt_mode_i.dst == 1'b1) begin
          src_fmt    = fpnew_pkg::FP8ALT;
          dst_fmt    = fpnew_pkg::FP8ALT;
        end
        vectorial_op = 1'b1;
        set_dyn_rm   = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFDIV_R_B}) op_select[1] = RegBRep;
      end
      riscv_instr::VFMIN_B,
      riscv_instr::VFMIN_R_B: begin
        fpu_op = fpnew_pkg::MINMAX;
        op_select[0] = RegA;
        op_select[1] = RegB;
        fpu_rnd_mode = fpnew_pkg::RNE;
        src_fmt      = fpnew_pkg::FP8;
        dst_fmt      = fpnew_pkg::FP8;
        if (fpu_fmt_mode_i.dst == 1'b1) begin
          src_fmt    = fpnew_pkg::FP8ALT;
          dst_fmt    = fpnew_pkg::FP8ALT;
        end
        vectorial_op = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFMIN_R_B}) op_select[1] = RegBRep;
      end
      riscv_instr::VFMAX_B,
      riscv_instr::VFMAX_R_B: begin
        fpu_op = fpnew_pkg::MINMAX;
        op_select[0] = RegA;
        op_select[1] = RegB;
        src_fmt      = fpnew_pkg::FP8;
        dst_fmt      = fpnew_pkg::FP8;
        if (fpu_fmt_mode_i.dst == 1'b1) begin
          src_fmt    = fpnew_pkg::FP8ALT;
          dst_fmt    = fpnew_pkg::FP8ALT;
        end
        fpu_rnd_mode = fpnew_pkg::RTZ;
        vectorial_op = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFMAX_R_B}) op_select[1] = RegBRep;
      end
      riscv_instr::VFSQRT_B: begin
        fpu_op = fpnew_pkg::SQRT;
        op_select[0] = RegA;
        op_select[1] = RegA;
        src_fmt      = fpnew_pkg::FP8;
        dst_fmt      = fpnew_pkg::FP8;
        if (fpu_fmt_mode_i.dst == 1'b1) begin
          src_fmt    = fpnew_pkg::FP8ALT;
          dst_fmt    = fpnew_pkg::FP8ALT;
        end
        vectorial_op = 1'b1;
        set_dyn_rm   = 1'b1;
      end
      riscv_instr::VFMAC_B,
      riscv_instr::VFMAC_R_B: begin
        fpu_op = fpnew_pkg::FMADD;
        op_select[0] = RegA;
        op_select[1] = RegB;
        op_select[2] = RegDest;
        src_fmt      = fpnew_pkg::FP8;
        dst_fmt      = fpnew_pkg::FP8;
        if (fpu_fmt_mode_i.dst == 1'b1) begin
          src_fmt    = fpnew_pkg::FP8ALT;
          dst_fmt    = fpnew_pkg::FP8ALT;
        end
        vectorial_op = 1'b1;
        set_dyn_rm   = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFMAC_R_B}) op_select[1] = RegBRep;
      end
      riscv_instr::VFMRE_B,
      riscv_instr::VFMRE_R_B: begin
        fpu_op = fpnew_pkg::FNMSUB;
        op_select[0] = RegA;
        op_select[1] = RegB;
        op_select[2] = RegDest;
        src_fmt      = fpnew_pkg::FP8;
        dst_fmt      = fpnew_pkg::FP8;
        if (fpu_fmt_mode_i.dst == 1'b1) begin
          src_fmt    = fpnew_pkg::FP8ALT;
          dst_fmt    = fpnew_pkg::FP8ALT;
        end
        vectorial_op = 1'b1;
        set_dyn_rm   = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFMRE_R_B}) op_select[1] = RegBRep;
      end
      riscv_instr::VFSGNJ_B,
      riscv_instr::VFSGNJ_R_B: begin
        fpu_op = fpnew_pkg::SGNJ;
        op_select[0] = RegA;
        op_select[1] = RegB;
        fpu_rnd_mode = fpnew_pkg::RNE;
        src_fmt      = fpnew_pkg::FP8;
        dst_fmt      = fpnew_pkg::FP8;
        if (fpu_fmt_mode_i.dst == 1'b1) begin
          src_fmt    = fpnew_pkg::FP8ALT;
          dst_fmt    = fpnew_pkg::FP8ALT;
        end
        vectorial_op = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFSGNJ_R_B}) op_select[1] = RegBRep;
      end
      riscv_instr::VFSGNJN_B,
      riscv_instr::VFSGNJN_R_B: begin
        fpu_op = fpnew_pkg::SGNJ;
        op_select[0] = RegA;
        op_select[1] = RegB;
        fpu_rnd_mode = fpnew_pkg::RTZ;
        src_fmt      = fpnew_pkg::FP8;
        dst_fmt      = fpnew_pkg::FP8;
        if (fpu_fmt_mode_i.dst == 1'b1) begin
          src_fmt    = fpnew_pkg::FP8ALT;
          dst_fmt    = fpnew_pkg::FP8ALT;
        end
        vectorial_op = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFSGNJN_R_B}) op_select[1] = RegBRep;
      end
      riscv_instr::VFSGNJX_B,
      riscv_instr::VFSGNJX_R_B: begin
        fpu_op = fpnew_pkg::SGNJ;
        op_select[0] = RegA;
        op_select[1] = RegB;
        fpu_rnd_mode = fpnew_pkg::RDN;
        src_fmt      = fpnew_pkg::FP8;
        dst_fmt      = fpnew_pkg::FP8;
        if (fpu_fmt_mode_i.dst == 1'b1) begin
          src_fmt    = fpnew_pkg::FP8ALT;
          dst_fmt    = fpnew_pkg::FP8ALT;
        end
        vectorial_op = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFSGNJX_R_B}) op_select[1] = RegBRep;
      end
      riscv_instr::VFCPKA_B_S,
      riscv_instr::VFCPKB_B_S: begin
        fpu_op = fpnew_pkg::CPKAB;
        op_select[0] = RegA;
        op_select[1] = RegB;
        op_select[2] = RegDest;
        src_fmt      = fpnew_pkg::FP32;
        dst_fmt      = fpnew_pkg::FP8;
        vectorial_op = 1'b1;
        set_dyn_rm   = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFCPKB_B_S}) op_mode = 1;
      end
      riscv_instr::VFCPKC_B_S,
      riscv_instr::VFCPKD_B_S: begin
        fpu_op = fpnew_pkg::CPKCD;
        op_select[0] = RegA;
        op_select[1] = RegB;
        op_select[2] = RegDest;
        src_fmt      = fpnew_pkg::FP32;
        dst_fmt      = fpnew_pkg::FP8;
        vectorial_op = 1'b1;
        set_dyn_rm   = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFCPKD_B_S}) op_mode = 1;
      end
     riscv_instr::VFCPKA_B_D,
      riscv_instr::VFCPKB_B_D: begin
        fpu_op = fpnew_pkg::CPKAB;
        op_select[0] = RegA;
        op_select[1] = RegB;
        op_select[2] = RegDest;
        src_fmt      = fpnew_pkg::FP64;
        dst_fmt      = fpnew_pkg::FP8;
        vectorial_op = 1'b1;
        set_dyn_rm   = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFCPKB_B_D}) op_mode = 1;
      end
      riscv_instr::VFCPKC_B_D,
      riscv_instr::VFCPKD_B_D: begin
        fpu_op = fpnew_pkg::CPKCD;
        op_select[0] = RegA;
        op_select[1] = RegB;
        op_select[2] = RegDest;
        src_fmt      = fpnew_pkg::FP64;
        dst_fmt      = fpnew_pkg::FP8;
        vectorial_op = 1'b1;
        set_dyn_rm   = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFCPKD_B_D}) op_mode = 1;
      end
      riscv_instr::VFCVT_S_B,
      riscv_instr::VFCVTU_S_B: begin
        fpu_op = fpnew_pkg::F2F;
        op_select[0] = RegA;
        op_select[1] = RegB;
        src_fmt      = fpnew_pkg::FP8;
        dst_fmt      = fpnew_pkg::FP32;
        vectorial_op = 1'b1;
        set_dyn_rm   = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFCVTU_S_B}) op_mode = 1'b1;
      end
      riscv_instr::VFCVT_B_S,
      riscv_instr::VFCVTU_B_S: begin
        fpu_op = fpnew_pkg::F2F;
        op_select[0] = RegA;
        op_select[1] = RegB;
        src_fmt      = fpnew_pkg::FP32;
        dst_fmt      = fpnew_pkg::FP8;
        vectorial_op = 1'b1;
        set_dyn_rm   = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFCVTU_B_S}) op_mode = 1'b1;
      end
      riscv_instr::VFCVT_H_H,
      riscv_instr::VFCVTU_H_H: begin
        fpu_op = fpnew_pkg::F2F;
        op_select[0] = RegA;
        op_select[1] = RegB;
        src_fmt      = fpnew_pkg::FP16;
        dst_fmt      = fpnew_pkg::FP16;
        vectorial_op = 1'b1;
        set_dyn_rm   = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFCVTU_H_H}) op_mode = 1'b1;
      end
      riscv_instr::VFCVT_H_B,
      riscv_instr::VFCVTU_H_B: begin
        fpu_op = fpnew_pkg::F2F;
        op_select[0] = RegA;
        op_select[1] = RegB;
        src_fmt      = fpnew_pkg::FP8;
        dst_fmt      = fpnew_pkg::FP16;
        vectorial_op = 1'b1;
        set_dyn_rm   = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFCVTU_H_B}) op_mode = 1'b1;
      end
      riscv_instr::VFCVT_B_H,
      riscv_instr::VFCVTU_B_H: begin
        fpu_op = fpnew_pkg::F2F;
        op_select[0] = RegA;
        op_select[1] = RegB;
        src_fmt      = fpnew_pkg::FP16;
        dst_fmt      = fpnew_pkg::FP8;
        vectorial_op = 1'b1;
        set_dyn_rm   = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFCVTU_B_H}) op_mode = 1'b1;
      end
      riscv_instr::VFCVT_B_B,
      riscv_instr::VFCVTU_B_B: begin
        fpu_op = fpnew_pkg::F2F;
        op_select[0] = RegA;
        op_select[1] = RegB;
        src_fmt      = fpnew_pkg::FP8;
        dst_fmt      = fpnew_pkg::FP8;
        vectorial_op = 1'b1;
        set_dyn_rm   = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFCVTU_B_B}) op_mode = 1'b1;
      end
      riscv_instr::VFDOTPEX_H_B,
      riscv_instr::VFDOTPEX_H_R_B: begin
        fpu_op = fpnew_pkg::SDOTP;
        op_select[0] = RegA;
        op_select[1] = RegB;
        op_select[2] = RegDest;
        src_fmt      = fpnew_pkg::FP8;
        dst_fmt      = fpnew_pkg::FP16;
        vectorial_op = 1'b1;
        set_dyn_rm   = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFDOTPEX_H_R_B}) op_select[2] = RegBRep;
      end
      riscv_instr::VFNDOTPEX_H_B,
      riscv_instr::VFNDOTPEX_H_R_B: begin
        fpu_op = fpnew_pkg::SDOTP;
        op_select[0] = RegA;
        op_select[1] = RegB;
        op_select[2] = RegDest;
        op_mode      = 1'b1;
        src_fmt      = fpnew_pkg::FP8;
        dst_fmt      = fpnew_pkg::FP16;
        vectorial_op = 1'b1;
        set_dyn_rm   = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFNDOTPEX_H_R_B}) op_select[2] = RegBRep;
      end
      riscv_instr::VFSUMEX_H_B,
      riscv_instr::VFNSUMEX_H_B: begin
        fpu_op = fpnew_pkg::EXVSUM;
        op_select[0] = RegA;
        op_select[2] = RegDest;
        src_fmt      = fpnew_pkg::FP8;
        dst_fmt      = fpnew_pkg::FP16;
        vectorial_op = 1'b1;
        set_dyn_rm   = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFNSUMEX_H_B}) op_mode = 1'b1;
      end
      // -------------------
      // From float to int
      // -------------------
      // Single Precision Floating-Point
      riscv_instr::FLE_S,
      riscv_instr::FLT_S,
      riscv_instr::FEQ_S: begin
        fpu_op = fpnew_pkg::CMP;
        op_select[0]   = RegA;
        op_select[1]   = RegB;
        src_fmt        = fpnew_pkg::FP32;
        dst_fmt        = fpnew_pkg::FP32;
        fpu_tag_in.acc = 1'b1;
        rd_is_fp       = 1'b0;
      end
      riscv_instr::FCLASS_S: begin
        fpu_op = fpnew_pkg::CLASSIFY;
        op_select[0]   = RegA;
        fpu_rnd_mode   = fpnew_pkg::RNE;
        src_fmt        = fpnew_pkg::FP32;
        dst_fmt        = fpnew_pkg::FP32;
        fpu_tag_in.acc = 1'b1;
        rd_is_fp       = 1'b0;
      end
      riscv_instr::FCVT_W_S,
      riscv_instr::FCVT_WU_S: begin
        fpu_op = fpnew_pkg::F2I;
        op_select[0]   = RegA;
        src_fmt        = fpnew_pkg::FP32;
        dst_fmt        = fpnew_pkg::FP32;
        fpu_tag_in.acc = 1'b1;
        rd_is_fp       = 1'b0;
        if (acc_req_q.data_op inside {riscv_instr::FCVT_WU_S}) op_mode = 1'b1; // unsigned
      end
      riscv_instr::FMV_X_W: begin
        fpu_op = fpnew_pkg::SGNJ;
        fpu_rnd_mode   = fpnew_pkg::RUP; // passthrough without checking nan-box
        src_fmt        = fpnew_pkg::FP32;
        dst_fmt        = fpnew_pkg::FP32;
        op_mode        = 1'b1; // sign-extend result
        op_select[0]   = RegA;
        fpu_tag_in.acc = 1'b1;
        rd_is_fp       = 1'b0;
      end
      // Vectorial Single Precision
      riscv_instr::VFEQ_S,
      riscv_instr::VFEQ_R_S: begin
        fpu_op = fpnew_pkg::CMP;
        op_select[0]   = RegA;
        op_select[1]   = RegB;
        fpu_rnd_mode   = fpnew_pkg::RDN;
        src_fmt        = fpnew_pkg::FP32;
        dst_fmt        = fpnew_pkg::FP32;
        vectorial_op   = 1'b1;
        fpu_tag_in.acc = 1'b1;
        rd_is_fp       = 1'b0;
        if (acc_req_q.data_op inside {riscv_instr::VFEQ_R_S}) op_select[1] = RegBRep;
      end
      riscv_instr::VFNE_S,
      riscv_instr::VFNE_R_S: begin
        fpu_op = fpnew_pkg::CMP;
        op_select[0]   = RegA;
        op_select[1]   = RegB;
        fpu_rnd_mode   = fpnew_pkg::RDN;
        src_fmt        = fpnew_pkg::FP32;
        dst_fmt        = fpnew_pkg::FP32;
        op_mode        = 1'b1;
        vectorial_op   = 1'b1;
        fpu_tag_in.acc = 1'b1;
        rd_is_fp       = 1'b0;
        if (acc_req_q.data_op inside {riscv_instr::VFNE_R_S}) op_select[1] = RegBRep;
      end
      riscv_instr::VFLT_S,
      riscv_instr::VFLT_R_S: begin
        fpu_op = fpnew_pkg::CMP;
        op_select[0]   = RegA;
        op_select[1]   = RegB;
        fpu_rnd_mode   = fpnew_pkg::RTZ;
        src_fmt        = fpnew_pkg::FP32;
        dst_fmt        = fpnew_pkg::FP32;
        vectorial_op   = 1'b1;
        fpu_tag_in.acc = 1'b1;
        rd_is_fp       = 1'b0;
        if (acc_req_q.data_op inside {riscv_instr::VFLT_R_S}) op_select[1] = RegBRep;
      end
      riscv_instr::VFGE_S,
      riscv_instr::VFGE_R_S: begin
        fpu_op = fpnew_pkg::CMP;
        op_select[0]   = RegA;
        op_select[1]   = RegB;
        fpu_rnd_mode   = fpnew_pkg::RTZ;
        src_fmt        = fpnew_pkg::FP32;
        dst_fmt        = fpnew_pkg::FP32;
        op_mode        = 1'b1;
        vectorial_op   = 1'b1;
        fpu_tag_in.acc = 1'b1;
        rd_is_fp       = 1'b0;
        if (acc_req_q.data_op inside {riscv_instr::VFGE_R_S}) op_select[1] = RegBRep;
      end
      riscv_instr::VFLE_S,
      riscv_instr::VFLE_R_S: begin
        fpu_op = fpnew_pkg::CMP;
        op_select[0]   = RegA;
        op_select[1]   = RegB;
        fpu_rnd_mode   = fpnew_pkg::RNE;
        src_fmt        = fpnew_pkg::FP32;
        dst_fmt        = fpnew_pkg::FP32;
        vectorial_op   = 1'b1;
        fpu_tag_in.acc = 1'b1;
        rd_is_fp       = 1'b0;
        if (acc_req_q.data_op inside {riscv_instr::VFLE_R_S}) op_select[1] = RegBRep;
      end
      riscv_instr::VFGT_S,
      riscv_instr::VFGT_R_S: begin
        fpu_op = fpnew_pkg::CMP;
        op_select[0]   = RegA;
        op_select[1]   = RegB;
        fpu_rnd_mode   = fpnew_pkg::RNE;
        src_fmt        = fpnew_pkg::FP32;
        dst_fmt        = fpnew_pkg::FP32;
        op_mode        = 1'b1;
        vectorial_op   = 1'b1;
        fpu_tag_in.acc = 1'b1;
        rd_is_fp       = 1'b0;
        if (acc_req_q.data_op inside {riscv_instr::VFGT_R_S}) op_select[1] = RegBRep;
      end
      riscv_instr::VFCLASS_S: begin
        fpu_op = fpnew_pkg::CLASSIFY;
        op_select[0]   = RegA;
        fpu_rnd_mode   = fpnew_pkg::RNE;
        src_fmt        = fpnew_pkg::FP32;
        dst_fmt        = fpnew_pkg::FP32;
        vectorial_op   = 1'b1;
        fpu_tag_in.acc = 1'b1;
        rd_is_fp       = 1'b0;
      end
      // Double Precision Floating-Point
      riscv_instr::FLE_D,
      riscv_instr::FLT_D,
      riscv_instr::FEQ_D: begin
        fpu_op = fpnew_pkg::CMP;
        op_select[0]   = RegA;
        op_select[1]   = RegB;
        src_fmt        = fpnew_pkg::FP64;
        dst_fmt        = fpnew_pkg::FP64;
        fpu_tag_in.acc = 1'b1;
        rd_is_fp       = 1'b0;
      end
      riscv_instr::FCLASS_D: begin
        fpu_op = fpnew_pkg::CLASSIFY;
        op_select[0]   = RegA;
        fpu_rnd_mode   = fpnew_pkg::RNE;
        src_fmt        = fpnew_pkg::FP64;
        dst_fmt        = fpnew_pkg::FP64;
        fpu_tag_in.acc = 1'b1;
        rd_is_fp       = 1'b0;
      end
      riscv_instr::FCVT_W_D,
      riscv_instr::FCVT_WU_D: begin
        fpu_op = fpnew_pkg::F2I;
        op_select[0]   = RegA;
        src_fmt        = fpnew_pkg::FP64;
        dst_fmt        = fpnew_pkg::FP64;
        fpu_tag_in.acc = 1'b1;
        rd_is_fp       = 1'b0;
        if (acc_req_q.data_op inside {riscv_instr::FCVT_WU_D}) op_mode = 1'b1; // unsigned
      end
      riscv_instr::FMV_X_D: begin
        fpu_op = fpnew_pkg::SGNJ;
        fpu_rnd_mode   = fpnew_pkg::RUP; // passthrough without checking nan-box
        src_fmt        = fpnew_pkg::FP64;
        dst_fmt        = fpnew_pkg::FP64;
        op_mode        = 1'b1; // sign-extend result
        op_select[0]   = RegA;
        fpu_tag_in.acc = 1'b1;
        rd_is_fp       = 1'b0;
      end
      // [Alternate] Half Precision Floating-Point
      riscv_instr::FLE_H,
      riscv_instr::FLT_H,
      riscv_instr::FEQ_H: begin
        fpu_op = fpnew_pkg::CMP;
        op_select[0]   = RegA;
        op_select[1]   = RegB;
        src_fmt        = fpnew_pkg::FP16;
        dst_fmt        = fpnew_pkg::FP16;
        if (fpu_fmt_mode_i.src == 1'b1) begin
          src_fmt    = fpnew_pkg::FP16ALT;
          dst_fmt    = fpnew_pkg::FP16ALT;
        end
        fpu_tag_in.acc = 1'b1;
        rd_is_fp       = 1'b0;
      end
      riscv_instr::FCLASS_H: begin
        fpu_op = fpnew_pkg::CLASSIFY;
        op_select[0]   = RegA;
        fpu_rnd_mode   = fpnew_pkg::RNE;
        src_fmt        = fpnew_pkg::FP16;
        dst_fmt        = fpnew_pkg::FP16;
        if (fpu_fmt_mode_i.src == 1'b1) begin
          src_fmt      = fpnew_pkg::FP16ALT;
          dst_fmt      = fpnew_pkg::FP16ALT;
        end
        fpu_tag_in.acc = 1'b1;
        rd_is_fp       = 1'b0;
      end
      riscv_instr::FCVT_W_H,
      riscv_instr::FCVT_WU_H: begin
        fpu_op = fpnew_pkg::F2I;
        op_select[0]   = RegA;
        src_fmt        = fpnew_pkg::FP16;
        dst_fmt        = fpnew_pkg::FP16;
        fpu_tag_in.acc = 1'b1;
        rd_is_fp       = 1'b0;
        if (acc_req_q.data_op inside {riscv_instr::FCVT_WU_H}) op_mode = 1'b1; // unsigned
      end
      riscv_instr::FMV_X_H: begin
        fpu_op = fpnew_pkg::SGNJ;
        fpu_rnd_mode   = fpnew_pkg::RUP; // passthrough without checking nan-box
        src_fmt        = fpnew_pkg::FP16;
        dst_fmt        = fpnew_pkg::FP16;
        if (fpu_fmt_mode_i.src == 1'b1) begin
          src_fmt      = fpnew_pkg::FP16ALT;
          dst_fmt      = fpnew_pkg::FP16ALT;
        end
        op_mode        = 1'b1; // sign-extend result
        op_select[0]   = RegA;
        fpu_tag_in.acc = 1'b1;
        rd_is_fp       = 1'b0;
      end
      // Vectorial [alternate] Half Precision
      riscv_instr::VFEQ_H,
      riscv_instr::VFEQ_R_H: begin
        fpu_op = fpnew_pkg::CMP;
        op_select[0]   = RegA;
        op_select[1]   = RegB;
        fpu_rnd_mode   = fpnew_pkg::RDN;
        src_fmt        = fpnew_pkg::FP16;
        dst_fmt        = fpnew_pkg::FP16;
        if (fpu_fmt_mode_i.src == 1'b1) begin
          src_fmt      = fpnew_pkg::FP16ALT;
          dst_fmt      = fpnew_pkg::FP16ALT;
        end
        vectorial_op   = 1'b1;
        fpu_tag_in.acc = 1'b1;
        rd_is_fp       = 1'b0;
        if (acc_req_q.data_op inside {riscv_instr::VFEQ_R_H}) op_select[1] = RegBRep;
      end
      riscv_instr::VFNE_H,
      riscv_instr::VFNE_R_H: begin
        fpu_op = fpnew_pkg::CMP;
        op_select[0]   = RegA;
        op_select[1]   = RegB;
        fpu_rnd_mode   = fpnew_pkg::RDN;
        src_fmt        = fpnew_pkg::FP16;
        dst_fmt        = fpnew_pkg::FP16;
        if (fpu_fmt_mode_i.src == 1'b1) begin
          src_fmt      = fpnew_pkg::FP16ALT;
          dst_fmt      = fpnew_pkg::FP16ALT;
        end
        op_mode        = 1'b1;
        vectorial_op   = 1'b1;
        fpu_tag_in.acc = 1'b1;
        rd_is_fp       = 1'b0;
        if (acc_req_q.data_op inside {riscv_instr::VFNE_R_H}) op_select[1] = RegBRep;
      end
      riscv_instr::VFLT_H,
      riscv_instr::VFLT_R_H: begin
        fpu_op = fpnew_pkg::CMP;
        op_select[0]   = RegA;
        op_select[1]   = RegB;
        fpu_rnd_mode   = fpnew_pkg::RTZ;
        src_fmt        = fpnew_pkg::FP16;
        dst_fmt        = fpnew_pkg::FP16;
        if (fpu_fmt_mode_i.src == 1'b1) begin
          src_fmt      = fpnew_pkg::FP16ALT;
          dst_fmt      = fpnew_pkg::FP16ALT;
        end
        vectorial_op   = 1'b1;
        fpu_tag_in.acc = 1'b1;
        rd_is_fp       = 1'b0;
        if (acc_req_q.data_op inside {riscv_instr::VFLT_R_H}) op_select[1] = RegBRep;
      end
      riscv_instr::VFGE_H,
      riscv_instr::VFGE_R_H: begin
        fpu_op = fpnew_pkg::CMP;
        op_select[0]   = RegA;
        op_select[1]   = RegB;
        fpu_rnd_mode   = fpnew_pkg::RTZ;
        src_fmt        = fpnew_pkg::FP16;
        dst_fmt        = fpnew_pkg::FP16;
        if (fpu_fmt_mode_i.src == 1'b1) begin
          src_fmt      = fpnew_pkg::FP16ALT;
          dst_fmt      = fpnew_pkg::FP16ALT;
        end
        op_mode        = 1'b1;
        vectorial_op   = 1'b1;
        fpu_tag_in.acc = 1'b1;
        rd_is_fp       = 1'b0;
        if (acc_req_q.data_op inside {riscv_instr::VFGE_R_H}) op_select[1] = RegBRep;
      end
      riscv_instr::VFLE_H,
      riscv_instr::VFLE_R_H: begin
        fpu_op = fpnew_pkg::CMP;
        op_select[0]   = RegA;
        op_select[1]   = RegB;
        fpu_rnd_mode   = fpnew_pkg::RNE;
        src_fmt        = fpnew_pkg::FP16;
        dst_fmt        = fpnew_pkg::FP16;
        if (fpu_fmt_mode_i.src == 1'b1) begin
          src_fmt      = fpnew_pkg::FP16ALT;
          dst_fmt      = fpnew_pkg::FP16ALT;
        end
        vectorial_op   = 1'b1;
        fpu_tag_in.acc = 1'b1;
        rd_is_fp       = 1'b0;
        if (acc_req_q.data_op inside {riscv_instr::VFLE_R_H}) op_select[1] = RegBRep;
      end
      riscv_instr::VFGT_H,
      riscv_instr::VFGT_R_H: begin
        fpu_op = fpnew_pkg::CMP;
        op_select[0]   = RegA;
        op_select[1]   = RegB;
        fpu_rnd_mode   = fpnew_pkg::RNE;
        src_fmt        = fpnew_pkg::FP16;
        dst_fmt        = fpnew_pkg::FP16;
        if (fpu_fmt_mode_i.src == 1'b1) begin
          src_fmt      = fpnew_pkg::FP16ALT;
          dst_fmt      = fpnew_pkg::FP16ALT;
        end
        op_mode        = 1'b1;
        vectorial_op   = 1'b1;
        fpu_tag_in.acc = 1'b1;
        rd_is_fp       = 1'b0;
        if (acc_req_q.data_op inside {riscv_instr::VFGT_R_H}) op_select[1] = RegBRep;
      end
      riscv_instr::VFCLASS_H: begin
        fpu_op = fpnew_pkg::CLASSIFY;
        op_select[0]   = RegA;
        fpu_rnd_mode   = fpnew_pkg::RNE;
        src_fmt        = fpnew_pkg::FP16;
        dst_fmt        = fpnew_pkg::FP16;
        if (fpu_fmt_mode_i.src == 1'b1) begin
          src_fmt      = fpnew_pkg::FP16ALT;
          dst_fmt      = fpnew_pkg::FP16ALT;
        end
        vectorial_op   = 1'b1;
        fpu_tag_in.acc = 1'b1;
        rd_is_fp       = 1'b0;
      end
      riscv_instr::VFMV_X_H: begin
        fpu_op = fpnew_pkg::SGNJ;
        fpu_rnd_mode   = fpnew_pkg::RUP; // passthrough without checking nan-box
        src_fmt        = fpnew_pkg::FP16;
        dst_fmt        = fpnew_pkg::FP16;
        if (fpu_fmt_mode_i.src == 1'b1) begin
          src_fmt      = fpnew_pkg::FP16ALT;
          dst_fmt      = fpnew_pkg::FP16ALT;
        end
        op_mode        = 1'b1; // sign-extend result
        op_select[0]   = RegA;
        vectorial_op   = 1'b1;
        fpu_tag_in.acc = 1'b1;
        rd_is_fp       = 1'b0;
      end
      riscv_instr::VFCVT_X_H,
      riscv_instr::VFCVT_XU_H: begin
        fpu_op = fpnew_pkg::F2I;
        op_select[0]   = RegA;
        src_fmt        = fpnew_pkg::FP16;
        dst_fmt        = fpnew_pkg::FP16;
        if (fpu_fmt_mode_i.src == 1'b1) begin
          src_fmt      = fpnew_pkg::FP16ALT;
          dst_fmt      = fpnew_pkg::FP16ALT;
        end
        int_fmt        = fpnew_pkg::INT16;
        vectorial_op   = 1'b1;
        fpu_tag_in.acc = 1'b1;
        rd_is_fp       = 1'b0;
        set_dyn_rm     = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFCVT_XU_H}) op_mode = 1'b1; // upper
      end
      // [Alternate] Quarter Precision Floating-Point
      riscv_instr::FLE_B,
      riscv_instr::FLT_B,
      riscv_instr::FEQ_B: begin
        fpu_op = fpnew_pkg::CMP;
        op_select[0]   = RegA;
        op_select[1]   = RegB;
        src_fmt        = fpnew_pkg::FP8;
        dst_fmt        = fpnew_pkg::FP8;
        if (fpu_fmt_mode_i.src == 1'b1) begin
          src_fmt      = fpnew_pkg::FP8ALT;
          dst_fmt      = fpnew_pkg::FP8ALT;
        end
        fpu_tag_in.acc = 1'b1;
        rd_is_fp       = 1'b0;
      end
      riscv_instr::FCLASS_B: begin
        fpu_op = fpnew_pkg::CLASSIFY;
        op_select[0]   = RegA;
        fpu_rnd_mode   = fpnew_pkg::RNE;
        src_fmt        = fpnew_pkg::FP8;
        dst_fmt        = fpnew_pkg::FP8;
        if (fpu_fmt_mode_i.src == 1'b1) begin
          src_fmt      = fpnew_pkg::FP8ALT;
          dst_fmt      = fpnew_pkg::FP8ALT;
        end
        fpu_tag_in.acc = 1'b1;
        rd_is_fp       = 1'b0;
      end
      riscv_instr::FCVT_W_B,
      riscv_instr::FCVT_WU_B: begin
        fpu_op = fpnew_pkg::F2I;
        op_select[0]   = RegA;
        src_fmt        = fpnew_pkg::FP8;
        dst_fmt        = fpnew_pkg::FP8;
        if (fpu_fmt_mode_i.src == 1'b1) begin
          src_fmt      = fpnew_pkg::FP8ALT;
          dst_fmt      = fpnew_pkg::FP8ALT;
        end
        fpu_tag_in.acc = 1'b1;
        rd_is_fp       = 1'b0;
        if (acc_req_q.data_op inside {riscv_instr::FCVT_WU_B}) op_mode = 1'b1; // unsigned
      end
      riscv_instr::FMV_X_B: begin
        fpu_op = fpnew_pkg::SGNJ;
        fpu_rnd_mode   = fpnew_pkg::RUP; // passthrough without checking nan-box
        src_fmt        = fpnew_pkg::FP8;
        dst_fmt        = fpnew_pkg::FP8;
        if (fpu_fmt_mode_i.src == 1'b1) begin
          src_fmt      = fpnew_pkg::FP8ALT;
          dst_fmt      = fpnew_pkg::FP8ALT;
        end
        op_mode        = 1'b1; // sign-extend result
        op_select[0]   = RegA;
        vectorial_op   = 1'b1;
        fpu_tag_in.acc = 1'b1;
        rd_is_fp       = 1'b0;
      end
      // Vectorial Quarter Precision
      riscv_instr::VFEQ_B,
      riscv_instr::VFEQ_R_B: begin
        fpu_op = fpnew_pkg::CMP;
        op_select[0]   = RegA;
        op_select[1]   = RegB;
        fpu_rnd_mode   = fpnew_pkg::RDN;
        src_fmt        = fpnew_pkg::FP8;
        dst_fmt        = fpnew_pkg::FP8;
        if (fpu_fmt_mode_i.src == 1'b1) begin
          src_fmt      = fpnew_pkg::FP8ALT;
          dst_fmt      = fpnew_pkg::FP8ALT;
        end
        vectorial_op   = 1'b1;
        fpu_tag_in.acc = 1'b1;
        rd_is_fp       = 1'b0;
        if (acc_req_q.data_op inside {riscv_instr::VFEQ_R_B}) op_select[1] = RegBRep;
      end
      riscv_instr::VFNE_B,
      riscv_instr::VFNE_R_B: begin
        fpu_op = fpnew_pkg::CMP;
        op_select[0]   = RegA;
        op_select[1]   = RegB;
        fpu_rnd_mode   = fpnew_pkg::RDN;
        src_fmt        = fpnew_pkg::FP8;
        dst_fmt        = fpnew_pkg::FP8;
        if (fpu_fmt_mode_i.src == 1'b1) begin
          src_fmt      = fpnew_pkg::FP8ALT;
          dst_fmt      = fpnew_pkg::FP8ALT;
        end
        op_mode        = 1'b1;
        vectorial_op   = 1'b1;
        fpu_tag_in.acc = 1'b1;
        rd_is_fp       = 1'b0;
        if (acc_req_q.data_op inside {riscv_instr::VFNE_R_B}) op_select[1] = RegBRep;
      end
      riscv_instr::VFLT_B,
      riscv_instr::VFLT_R_B: begin
        fpu_op = fpnew_pkg::CMP;
        op_select[0]   = RegA;
        op_select[1]   = RegB;
        fpu_rnd_mode   = fpnew_pkg::RTZ;
        src_fmt        = fpnew_pkg::FP8;
        dst_fmt        = fpnew_pkg::FP8;
        if (fpu_fmt_mode_i.src == 1'b1) begin
          src_fmt      = fpnew_pkg::FP8ALT;
          dst_fmt      = fpnew_pkg::FP8ALT;
        end
        vectorial_op   = 1'b1;
        fpu_tag_in.acc = 1'b1;
        rd_is_fp       = 1'b0;
        if (acc_req_q.data_op inside {riscv_instr::VFLT_R_B}) op_select[1] = RegBRep;
      end
      riscv_instr::VFGE_B,
      riscv_instr::VFGE_R_B: begin
        fpu_op = fpnew_pkg::CMP;
        op_select[0]   = RegA;
        op_select[1]   = RegB;
        fpu_rnd_mode   = fpnew_pkg::RTZ;
        src_fmt        = fpnew_pkg::FP8;
        dst_fmt        = fpnew_pkg::FP8;
        if (fpu_fmt_mode_i.src == 1'b1) begin
          src_fmt      = fpnew_pkg::FP8ALT;
          dst_fmt      = fpnew_pkg::FP8ALT;
        end
        op_mode        = 1'b1;
        vectorial_op   = 1'b1;
        fpu_tag_in.acc = 1'b1;
        rd_is_fp       = 1'b0;
        if (acc_req_q.data_op inside {riscv_instr::VFGE_R_B}) op_select[1] = RegBRep;
      end
      riscv_instr::VFLE_B,
      riscv_instr::VFLE_R_B: begin
        fpu_op = fpnew_pkg::CMP;
        op_select[0]   = RegA;
        op_select[1]   = RegB;
        fpu_rnd_mode   = fpnew_pkg::RNE;
        src_fmt        = fpnew_pkg::FP8;
        dst_fmt        = fpnew_pkg::FP8;
        if (fpu_fmt_mode_i.src == 1'b1) begin
          src_fmt      = fpnew_pkg::FP8ALT;
          dst_fmt      = fpnew_pkg::FP8ALT;
        end
        vectorial_op   = 1'b1;
        fpu_tag_in.acc = 1'b1;
        rd_is_fp       = 1'b0;
        if (acc_req_q.data_op inside {riscv_instr::VFLE_R_B}) op_select[1] = RegBRep;
      end
      riscv_instr::VFGT_B,
      riscv_instr::VFGT_R_B: begin
        fpu_op = fpnew_pkg::CMP;
        op_select[0]   = RegA;
        op_select[1]   = RegB;
        fpu_rnd_mode   = fpnew_pkg::RNE;
        src_fmt        = fpnew_pkg::FP8;
        dst_fmt        = fpnew_pkg::FP8;
        if (fpu_fmt_mode_i.src == 1'b1) begin
          src_fmt      = fpnew_pkg::FP8ALT;
          dst_fmt      = fpnew_pkg::FP8ALT;
        end
        op_mode        = 1'b1;
        vectorial_op   = 1'b1;
        fpu_tag_in.acc = 1'b1;
        rd_is_fp       = 1'b0;
        if (acc_req_q.data_op inside {riscv_instr::VFGT_R_B}) op_select[1] = RegBRep;
      end
      riscv_instr::VFCLASS_B: begin
        fpu_op = fpnew_pkg::CLASSIFY;
        op_select[0]   = RegA;
        fpu_rnd_mode   = fpnew_pkg::RNE;
        src_fmt        = fpnew_pkg::FP8;
        dst_fmt        = fpnew_pkg::FP8;
        if (fpu_fmt_mode_i.src == 1'b1) begin
          src_fmt      = fpnew_pkg::FP8ALT;
          dst_fmt      = fpnew_pkg::FP8ALT;
        end
        vectorial_op   = 1'b1;
        fpu_tag_in.acc = 1'b1;
        rd_is_fp       = 1'b0;
      end
      riscv_instr::VFMV_X_B: begin
        fpu_op = fpnew_pkg::SGNJ;
        fpu_rnd_mode   = fpnew_pkg::RUP; // passthrough without checking nan-box
        src_fmt        = fpnew_pkg::FP8;
        dst_fmt        = fpnew_pkg::FP8;
        if (fpu_fmt_mode_i.src == 1'b1) begin
          src_fmt      = fpnew_pkg::FP8ALT;
          dst_fmt      = fpnew_pkg::FP8ALT;
        end
        op_mode        = 1'b1; // sign-extend result
        op_select[0]   = RegA;
        vectorial_op   = 1'b1;
        fpu_tag_in.acc = 1'b1;
        rd_is_fp       = 1'b0;
      end
      riscv_instr::VFCVT_X_B,
      riscv_instr::VFCVT_XU_B: begin
        fpu_op = fpnew_pkg::F2I;
        op_select[0]   = RegA;
        src_fmt        = fpnew_pkg::FP8;
        dst_fmt        = fpnew_pkg::FP8;
        if (fpu_fmt_mode_i.src == 1'b1) begin
          src_fmt      = fpnew_pkg::FP8ALT;
          dst_fmt      = fpnew_pkg::FP8ALT;
        end
        int_fmt        = fpnew_pkg::INT8;
        vectorial_op   = 1'b1;
        fpu_tag_in.acc = 1'b1;
        rd_is_fp       = 1'b0;
        set_dyn_rm     = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFCVT_XU_B}) op_mode = 1'b1; // upper
      end
      // -------------------
      // From int to float
      // -------------------
      // Single Precision Floating-Point
      riscv_instr::FMV_W_X: begin
        fpu_op = fpnew_pkg::SGNJ;
        op_select[0] = AccBus;
        fpu_rnd_mode = fpnew_pkg::RUP; // passthrough without checking nan-box
        src_fmt      = fpnew_pkg::FP32;
        dst_fmt      = fpnew_pkg::FP32;
      end
      riscv_instr::FCVT_S_W,
      riscv_instr::FCVT_S_WU: begin
        fpu_op = fpnew_pkg::I2F;
        op_select[0] = AccBus;
        dst_fmt      = fpnew_pkg::FP32;
        if (acc_req_q.data_op inside {riscv_instr::FCVT_S_WU}) op_mode = 1'b1; // unsigned
      end
      // Double Precision Floating-Point
      riscv_instr::FCVT_D_W,
      riscv_instr::FCVT_D_WU: begin
        fpu_op = fpnew_pkg::I2F;
        op_select[0] = AccBus;
        src_fmt      = fpnew_pkg::FP64;
        dst_fmt      = fpnew_pkg::FP64;
        if (acc_req_q.data_op inside {riscv_instr::FCVT_D_WU}) op_mode = 1'b1; // unsigned
      end
      // [Alternate] Half Precision Floating-Point
      riscv_instr::FMV_H_X: begin
        fpu_op = fpnew_pkg::SGNJ;
        op_select[0] = AccBus;
        fpu_rnd_mode = fpnew_pkg::RUP; // passthrough without checking nan-box
        src_fmt      = fpnew_pkg::FP16;
        dst_fmt      = fpnew_pkg::FP16;
        if (fpu_fmt_mode_i.dst == 1'b1) begin
          src_fmt    = fpnew_pkg::FP16ALT;
          dst_fmt    = fpnew_pkg::FP16ALT;
        end
      end
      riscv_instr::FCVT_H_W: begin
        fpu_op = fpnew_pkg::I2F;
        op_select[0] = AccBus;
        src_fmt      = fpnew_pkg::FP16;
        dst_fmt      = fpnew_pkg::FP16;
        if (fpu_fmt_mode_i.dst == 1'b1) begin
          src_fmt    = fpnew_pkg::FP16ALT;
          dst_fmt    = fpnew_pkg::FP16ALT;
        end
        if (acc_req_q.data_op inside {riscv_instr::FCVT_H_W}) op_mode = 1'b1; // unsigned
      end
      riscv_instr::FCVT_H_WU: begin
        fpu_op = fpnew_pkg::I2F;
        op_select[0] = AccBus;
        src_fmt      = fpnew_pkg::FP16;
        dst_fmt      = fpnew_pkg::FP16;
        if (fpu_fmt_mode_i.dst == 1'b1) begin
          src_fmt    = fpnew_pkg::FP16ALT;
          dst_fmt    = fpnew_pkg::FP16ALT;
        end
        if (acc_req_q.data_op inside {riscv_instr::FCVT_H_WU}) op_mode = 1'b1; // unsigned
      end
      // Vectorial Half Precision Floating-Point
      riscv_instr::VFMV_H_X: begin
        fpu_op = fpnew_pkg::SGNJ;
        op_select[0] = AccBus;
        fpu_rnd_mode = fpnew_pkg::RUP; // passthrough without checking nan-box
        src_fmt      = fpnew_pkg::FP16;
        dst_fmt      = fpnew_pkg::FP16;
        if (fpu_fmt_mode_i.dst == 1'b1) begin
          src_fmt    = fpnew_pkg::FP16ALT;
          dst_fmt    = fpnew_pkg::FP16ALT;
        end
        vectorial_op = 1'b1;
      end
      riscv_instr::VFCVT_H_X,
      riscv_instr::VFCVT_H_XU: begin
        fpu_op = fpnew_pkg::I2F;
        op_select[0] = AccBus;
        src_fmt      = fpnew_pkg::FP16;
        dst_fmt      = fpnew_pkg::FP16;
        if (fpu_fmt_mode_i.dst == 1'b1) begin
          src_fmt    = fpnew_pkg::FP16ALT;
          dst_fmt    = fpnew_pkg::FP16ALT;
        end
        int_fmt      = fpnew_pkg::INT16;
        vectorial_op = 1'b1;
        set_dyn_rm   = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFCVT_H_XU}) op_mode = 1'b1; // upper
      end
      // [Alternate] Quarter Precision Floating-Point
      riscv_instr::FMV_B_X: begin
        fpu_op = fpnew_pkg::SGNJ;
        op_select[0] = AccBus;
        fpu_rnd_mode = fpnew_pkg::RUP; // passthrough without checking nan-box
        src_fmt      = fpnew_pkg::FP8;
        dst_fmt      = fpnew_pkg::FP8;
        if (fpu_fmt_mode_i.dst == 1'b1) begin
          src_fmt    = fpnew_pkg::FP8ALT;
          dst_fmt    = fpnew_pkg::FP8ALT;
        end
      end
      riscv_instr::FCVT_B_W,
      riscv_instr::FCVT_B_WU: begin
        fpu_op = fpnew_pkg::I2F;
        op_select[0] = AccBus;
        src_fmt      = fpnew_pkg::FP8;
        dst_fmt      = fpnew_pkg::FP8;
        if (acc_req_q.data_op inside {riscv_instr::FCVT_B_WU}) op_mode = 1'b1; // unsigned
      end
      // Vectorial Quarter Precision Floating-Point
      riscv_instr::VFMV_B_X: begin
        fpu_op = fpnew_pkg::SGNJ;
        op_select[0] = AccBus;
        fpu_rnd_mode = fpnew_pkg::RUP; // passthrough without checking nan-box
        src_fmt      = fpnew_pkg::FP8;
        dst_fmt      = fpnew_pkg::FP8;
        vectorial_op = 1'b1;
      end
      riscv_instr::VFCVT_B_X,
      riscv_instr::VFCVT_B_XU: begin
        fpu_op = fpnew_pkg::I2F;
        op_select[0] = AccBus;
        src_fmt      = fpnew_pkg::FP8;
        dst_fmt      = fpnew_pkg::FP8;
        int_fmt      = fpnew_pkg::INT8;
        vectorial_op = 1'b1;
        set_dyn_rm   = 1'b1;
        if (acc_req_q.data_op inside {riscv_instr::VFCVT_B_XU}) op_mode = 1'b1; // upper
      end
      // -------------
      // Load / Store
      // -------------
      // Single Precision Floating-Point
      riscv_instr::FLW: begin
        is_load = 1'b1;
        use_fpu = 1'b0;
      end
      riscv_instr::FSW: begin
        is_store = 1'b1;
        op_select[1] = RegB;
        use_fpu = 1'b0;
        rd_is_fp = 1'b0;
      end
      // Double Precision Floating-Point
      riscv_instr::FLD: begin
        is_load = 1'b1;
        ls_size = DoubleWord;
        use_fpu = 1'b0;
      end
      riscv_instr::FSD: begin
        is_store = 1'b1;
        op_select[1] = RegB;
        ls_size = DoubleWord;
        use_fpu = 1'b0;
        rd_is_fp = 1'b0;
      end
      // [Alternate] Half Precision Floating-Point
      riscv_instr::FLH: begin
        is_load = 1'b1;
        ls_size = HalfWord;
        use_fpu = 1'b0;
      end
      riscv_instr::FSH: begin
        is_store = 1'b1;
        op_select[1] = RegB;
        ls_size = HalfWord;
        use_fpu = 1'b0;
        rd_is_fp = 1'b0;
      end
      // [Alternate] Quarter Precision Floating-Point
      riscv_instr::FLB: begin
        is_load = 1'b1;
        ls_size = Byte;
        use_fpu = 1'b0;
      end
      riscv_instr::FSB: begin
        is_store = 1'b1;
        op_select[1] = RegB;
        ls_size = Byte;
        use_fpu = 1'b0;
        rd_is_fp = 1'b0;
      end
      // -------------
      // CSR Handling
      // -------------
      // Set or clear corresponding CSR
      riscv_instr::CSRRSI: begin
        use_fpu = 1'b0;
        rd_is_fp = 1'b0;
        csr_instr = 1'b1;
        ssr_active_d |= rs1[0];
      end
      riscv_instr::CSRRCI: begin
        use_fpu = 1'b0;
        rd_is_fp = 1'b0;
        csr_instr = 1'b1;
        ssr_active_d &= ~rs1[0];
      end
      default: begin
        use_fpu = 1'b0;
        acc_resp_o.error = 1'b1;
        rd_is_fp = 1'b0;
      end
    endcase
    // fix round mode for vectors and fp16alt
    if (set_dyn_rm) fpu_rnd_mode = fpu_rnd_mode_i;
    // check if src_fmt or dst_fmt is acutually the alternate version
    // single-format float operations ignore fpu_fmt_mode_i.src
    // reason: for performance reasons when mixing expanding and non-expanding operations
    if (src_fmt == fpnew_pkg::FP16 && fpu_fmt_mode_i.src == 1'b1) src_fmt = fpnew_pkg::FP16ALT;
    if (dst_fmt == fpnew_pkg::FP16 && fpu_fmt_mode_i.dst == 1'b1) dst_fmt = fpnew_pkg::FP16ALT;
    if (src_fmt == fpnew_pkg::FP8 && fpu_fmt_mode_i.src == 1'b1) src_fmt = fpnew_pkg::FP8ALT;
    if (dst_fmt == fpnew_pkg::FP8 && fpu_fmt_mode_i.dst == 1'b1) dst_fmt = fpnew_pkg::FP8ALT;
  end

  snitch_regfile #(
    .DATA_WIDTH     ( FLEN ),
    .NR_READ_PORTS  ( 3    ),
    .NR_WRITE_PORTS ( 1    ),
    .ZERO_REG_ZERO  ( 0    ),
    .ADDR_WIDTH     ( 5    )
  ) i_ff_regfile (
    .clk_i,
    .raddr_i   ( fpr_raddr ),
    .rdata_o   ( fpr_rdata ),
    .waddr_i   ( fpr_waddr ),
    .wdata_i   ( fpr_wdata ),
    .we_i      ( fpr_we    )
  );

  // ----------------------
  // Operand Select
  // ----------------------
  logic [2:0][FLEN-1:0] acc_qdata;
  assign acc_qdata = {acc_req_q.data_argc, acc_req_q.data_argb, acc_req_q.data_arga};

  // Mux address lines as operands for the FPU can be mangled
  always_comb begin
    fpr_raddr[0] = rs1;
    fpr_raddr[1] = rs2;
    fpr_raddr[2] = rs3;

    unique case (op_select[1])
      RegA: begin
        fpr_raddr[1] = rs1;
      end
      default:;
    endcase

    unique case (op_select[2])
      RegB,
      RegBRep: begin
        fpr_raddr[2] = rs2;
      end
      RegDest: begin
        fpr_raddr[2] = rd;
      end
      default:;
    endcase
  end

  for (genvar i = 0; i < 3; i++) begin: gen_operand_select
    logic is_raddr_ssr;
    always_comb begin
      is_raddr_ssr = 1'b0;
      for (int s = 0; s < NumSsrs; s++)
        is_raddr_ssr |= (SsrRegs[s] == fpr_raddr[i]);
    end
    always_comb begin
      ssr_rvalid_o[i] = 1'b0;
      unique case (op_select[i])
        None: begin
          op[i] = '1;
          op_ready[i] = 1'b1;
        end
        AccBus: begin
          op[i] = acc_qdata[i];
          op_ready[i] = acc_req_valid_q;
        end
        // Scoreboard or SSR
        RegA, RegB, RegBRep, RegC, RegDest: begin
          // map register 0 and 1 to SSRs
          ssr_rvalid_o[i] = ssr_active_q & is_raddr_ssr;
          op[i] = ssr_rvalid_o[i] ? ssr_rdata_i[i] : fpr_rdata[i];
          // the operand is ready if it is not marked in the scoreboard
          // and in case of it being an SSR it need to be ready as well
          op_ready[i] = ~sb_q[fpr_raddr[i]] & (~ssr_rvalid_o[i] | ssr_rready_i[i]);
          // Replicate if needed
          if (op_select[i] == RegBRep) begin
            unique case (src_fmt)
              fpnew_pkg::FP32:    op[i] = {(FLEN / 32){op[i][31:0]}};
              fpnew_pkg::FP16,
              fpnew_pkg::FP16ALT: op[i] = {(FLEN / 16){op[i][15:0]}};
              fpnew_pkg::FP8,
              fpnew_pkg::FP8ALT:  op[i] = {(FLEN /  8){op[i][ 7:0]}};
              default:            op[i] = op[i][FLEN-1:0];
            endcase
          end
        end
        default: begin
          op[i] = '0;
          op_ready[i] = 1'b1;
        end
      endcase
    end
  end

  // ----------------------
  // Floating Point Unit
  // ----------------------
  snitch_fpu #(
    .RVF     ( RVF     ),
    .RVD     ( RVD     ),
    .XF16    ( XF16    ),
    .XF16ALT ( XF16ALT ),
    .XF8     ( XF8     ),
    .XF8ALT  ( XF8ALT  ),
    .XFVEC   ( XFVEC   ),
    .FLEN    ( FLEN    ),
    .FPUImplementation (FPUImplementation)
  ) i_fpu (
    .clk_i                           ,
    .rst_ni         ( ~rst_i        ),
    .operands_i     ( op            ),
    .rnd_mode_i     ( fpu_rnd_mode  ),
    .op_i           ( fpu_op        ),
    .op_mod_i       ( op_mode       ), // Sign of operand?
    .src_fmt_i      ( src_fmt       ),
    .dst_fmt_i      ( dst_fmt       ),
    .int_fmt_i      ( int_fmt       ),
    .vectorial_op_i ( vectorial_op  ),
    .tag_i          ( fpu_tag_in    ),
    .in_valid_i     ( fpu_in_valid  ),
    .in_ready_o     ( fpu_in_ready  ),
    .result_o       ( fpu_result    ),
    .status_o       ( fpu_status_o  ),
    .tag_o          ( fpu_tag_out   ),
    .out_valid_o    ( fpu_out_valid ),
    .out_ready_i    ( fpu_out_ready )
  );

  assign ssr_waddr_o = fpr_waddr;
  assign ssr_wdata_o = fpr_wdata;
  logic [63:0] nan_boxed_arga;
  assign nan_boxed_arga = {{32{1'b1}}, acc_req_q.data_arga[31:0]};

  // Arbitrate Register File Write Port
  always_comb begin
    fpr_we = 1'b0;
    fpr_waddr = '0;
    fpr_wdata = '0;
    fpr_wvalid = 1'b0;
    lsu_pready = 1'b0;
    fpr_wready = 1'b1;
    ssr_wvalid_o = 1'b0;
    ssr_wdone_o = 1'b1;
    // the accelerator master wants to write
    if (acc_req_valid_q && result_select == ResAccBus) begin
      fpr_we = 1'b1;
      // NaN-Box the value
      fpr_wdata = nan_boxed_arga[FLEN-1:0];
      fpr_waddr = rd;
      fpr_wvalid = 1'b1;
      fpr_wready = 1'b0;
    end else if (fpu_out_valid && !fpu_tag_out.acc) begin
      fpr_we = 1'b1;
      if (fpu_tag_out.ssr) begin
        ssr_wvalid_o = 1'b1;
        // stall write-back to SSR
        if (!ssr_wready_i) begin
          fpr_wready = 1'b0;
          fpr_we = 1'b0;
        end else begin
          ssr_wdone_o = 1'b1;
        end
      end
      fpr_wdata = fpu_result;
      fpr_waddr = fpu_tag_out.rd;
      fpr_wvalid = 1'b1;
    end else if (lsu_pvalid) begin
      lsu_pready = 1'b1;
      fpr_we = 1'b1;
      fpr_wdata = ld_result;
      fpr_waddr = lsu_rd;
      fpr_wvalid = 1'b1;
      fpr_wready = 1'b0;
    end
  end

  // ----------------------
  // Load/Store Unit
  // ----------------------
  assign lsu_qvalid = acc_req_valid_q & (&op_ready) & (is_load | is_store);

  snitch_lsu #(
    .AddrWidth (AddrWidth),
    .DataWidth (DataWidth),
    .dreq_t (dreq_t),
    .drsp_t (drsp_t),
    .tag_t (logic [4:0]),
    .NumOutstandingMem (NumFPOutstandingMem),
    .NumOutstandingLoads (NumFPOutstandingLoads),
    .NaNBox (1'b1)
  ) i_snitch_lsu (
    .clk_i (clk_i),
    .rst_i (rst_i),
    .lsu_qtag_i (rd),
    .lsu_qwrite_i (is_store),
    .lsu_qsigned_i (1'b1), // all floating point loads are signed
    .lsu_qaddr_i (acc_req_q.data_argc[AddrWidth-1:0]),
    .lsu_qdata_i (op[1]),
    .lsu_qsize_i (ls_size),
    .lsu_qamo_i (reqrsp_pkg::AMONone),
    .lsu_qvalid_i (lsu_qvalid),
    .lsu_qready_o (lsu_qready),
    .lsu_pdata_o (ld_result),
    .lsu_ptag_o (lsu_rd),
    .lsu_perror_o (), // ignored for the moment
    .lsu_pvalid_o (lsu_pvalid),
    .lsu_pready_i (lsu_pready),
    .lsu_empty_o (/* unused */),
    .data_req_o,
    .data_rsp_i
  );

  // SSRs
  for (genvar i = 0; i < 3; i++) assign ssr_rdone_o[i] = ssr_rvalid_o[i] & acc_req_ready_q;
  assign ssr_raddr_o = fpr_raddr;

  // Counter pipeline.
  logic issue_fpu, issue_core_to_fpu, issue_fpu_seq;
  `FFAR(issue_fpu, fpu_in_valid & fpu_in_ready, 1'b0, clk_i, rst_i)
  `FFAR(issue_core_to_fpu, acc_req_valid_i & acc_req_ready_o, 1'b0, clk_i, rst_i)
  `FFAR(issue_fpu_seq, acc_req_valid & acc_req_ready, 1'b0, clk_i, rst_i)

  always_comb begin
    core_events_o = '0;
    core_events_o.issue_fpu = issue_fpu;
    core_events_o.issue_core_to_fpu = issue_core_to_fpu;
    core_events_o.issue_fpu_seq = issue_fpu_seq;
  end

  // Tracer
  // pragma translate_off
  assign trace_port_o.source       = snitch_pkg::SrcFpu;
  assign trace_port_o.acc_q_hs     = (acc_req_valid_q  && acc_req_ready_q );
  assign trace_port_o.fpu_out_hs   = (fpu_out_valid && fpu_out_ready );
  assign trace_port_o.lsu_q_hs     = (lsu_qvalid    && lsu_qready    );
  assign trace_port_o.op_in        = acc_req_q.data_op;
  assign trace_port_o.rs1          = rs1;
  assign trace_port_o.rs2          = rs2;
  assign trace_port_o.rs3          = rs3;
  assign trace_port_o.rd           = rd;
  assign trace_port_o.op_sel_0     = op_select[0];
  assign trace_port_o.op_sel_1     = op_select[1];
  assign trace_port_o.op_sel_2     = op_select[2];
  assign trace_port_o.src_fmt      = src_fmt;
  assign trace_port_o.dst_fmt      = dst_fmt;
  assign trace_port_o.int_fmt      = int_fmt;
  assign trace_port_o.acc_qdata_0  = acc_qdata[0];
  assign trace_port_o.acc_qdata_1  = acc_qdata[1];
  assign trace_port_o.acc_qdata_2  = acc_qdata[2];
  assign trace_port_o.op_0         = op[0];
  assign trace_port_o.op_1         = op[1];
  assign trace_port_o.op_2         = op[2];
  assign trace_port_o.use_fpu      = use_fpu;
  assign trace_port_o.fpu_in_rd    = fpu_tag_in.rd;
  assign trace_port_o.fpu_in_acc   = fpu_tag_in.acc;
  assign trace_port_o.ls_size      = ls_size;
  assign trace_port_o.is_load      = is_load;
  assign trace_port_o.is_store     = is_store;
  assign trace_port_o.lsu_qaddr    = i_snitch_lsu.lsu_qaddr_i;
  assign trace_port_o.lsu_rd       = lsu_rd;
  assign trace_port_o.acc_wb_ready = (result_select == ResAccBus);
  assign trace_port_o.fpu_out_acc  = fpu_tag_out.acc;
  assign trace_port_o.fpr_waddr    = fpr_waddr[0];
  assign trace_port_o.fpr_wdata    = fpr_wdata[0];
  assign trace_port_o.fpr_we       = fpr_we[0];
  // pragma translate_on

  /// Assertions
  `ASSERT(RegWriteKnown, fpr_we |-> !$isunknown(fpr_wdata), clk_i, rst_i)
endmodule
