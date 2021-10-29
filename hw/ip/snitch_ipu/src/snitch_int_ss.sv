// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

`include "common_cells/registers.svh"

module snitch_int_ss import riscv_instr::*; import snitch_ipu_pkg::*; import snitch_pkg::*; #(
  parameter int unsigned AddrWidth = 0,
  parameter int unsigned DataWidth = 0,
  parameter int unsigned NumIPUSequencerInstr = 0,
  parameter bit          IPUSequencer = 1,
  parameter bit          RegisterSequencer = 1,
  parameter type         acc_req_t = logic,
  parameter type         acc_resp_t = logic,
  /// Derived parameter *Do not override*
  parameter type addr_t = logic [AddrWidth-1:0],
  parameter type data_t = logic [DataWidth-1:0]
) (
  input  logic          clk_i,
  input  logic          rst_i,

  // Accelerator Interface - Slave
  input  acc_req_t         acc_req_i,
  input  logic             acc_req_valid_i,
  output logic             acc_req_ready_o,
  output acc_resp_t        acc_resp_o,
  output logic             acc_resp_valid_o,
  input  logic             acc_resp_ready_i,
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
  output logic             streamctl_ready_o
);

  logic [2:0][4:0]  int_raddr;
  logic [2:0][31:0] int_rdata;

  logic [0:0]       int_we;
  logic [0:0][4:0]  int_waddr;
  logic [0:0][31:0] int_wdata;
  logic [0:0]       int_wvalid;
  logic [0:0]       int_wready;

  logic illegal;
  logic stall;
  logic valid_inst;

  logic multicycle_active_d, multicycle_active_q;
  logic is_multicycle;

  logic [31:0] iimm;

  logic [4:0] rs1, rs2, rs3, rd;
  logic [31:0] alu_result;
  logic [31:0]  imd_val_q [2];
  logic [31:0]  imd_val_d [2];
  logic [1:0]  imd_val_we;
  logic [2:0][31:0] alu_operand;

  typedef enum logic [1:0] {
    None,
    AccBus,
    IImm,
    Reg
  } op_select_e;

  typedef enum logic [1:0] {
    ResNone, ResAccBus
  } result_select_e;
  result_select_e result_select;

  op_select_e [2:0] op_select;
  alu_op_e alu_op;

  assign ssr_raddr_o = '0;
  assign ssr_rvalid_o = '0;
  assign ssr_rdone_o = '0;
  assign ssr_waddr_o = '0;
  assign ssr_wdata_o = '0;
  assign ssr_wvalid_o = '0;
  assign ssr_wdone_o = '0;

  // -------------
  // IPU Sequencer
  // -------------
  acc_req_t         acc_req, acc_req_q;
  logic             acc_req_valid, acc_req_valid_q;
  logic             acc_req_ready, acc_req_ready_q;
  if (IPUSequencer) begin : gen_ipu_sequencer
    snitch_sequencer #(
      .Depth    ( NumIPUSequencerInstr )
    ) i_snitch_ipu_sequencer (
      .clk_i,
      .rst_i,
      // pragma translate_off
      .trace_port_o     ( /* TODO(zarubaf,fschuiki) Connect */  ),
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
  end else begin : gen_no_ipu_sequencer
    // assign sequencer_tracer_port_o = 0;
    assign acc_req_ready_o = acc_req_ready;
    assign acc_req_valid = acc_req_valid_i;
    assign acc_req = acc_req_i;
  end

  // Optional spill-register
  spill_register  #(
    .T      ( acc_req_t                           ),
    .Bypass ( !RegisterSequencer || !IPUSequencer )
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

  assign iimm = $signed({acc_req_q.data_op[31:20]});

  // Assignments
  assign rd = acc_req_q.data_op[11:7];
  assign rs1 = acc_req_q.data_op[19:15];
  assign rs2 = acc_req_q.data_op[24:20];
  assign rs3 = acc_req_q.data_op[31:27];

  `FFLAR(multicycle_active_q, multicycle_active_d, ~stall, '0, clk_i, rst_i)
  assign multicycle_active_d = is_multicycle & ~multicycle_active_q;

  // stall in case the downstream circuit isn't ready
  assign stall = acc_resp_valid_o & ~acc_resp_ready_i;
  assign valid_inst = acc_req_valid_q & (~is_multicycle | multicycle_active_q);
  // TODO(zarubaf): Fix handshake
  // A |-> B = ~A | B
  assign acc_req_ready_q = ~stall;
  assign acc_resp_valid_o = valid_inst & (result_select == ResAccBus);

  assign acc_resp_o.data = $unsigned(alu_result);
  assign acc_resp_o.error = illegal;
  assign acc_resp_o.id = acc_req_q.id;

  // Decoder
  always_comb begin
    alu_op = ALU_ANDN;

    result_select = ResNone;

    op_select[0] = None;
    op_select[1] = None;
    op_select[2] = None;

    illegal = 1'b0;

    is_multicycle = 1'b0;

    unique casez (acc_req_q.data_op)
      ANDN: begin
        result_select = ResAccBus;
        op_select[0] = AccBus;
        op_select[1] = AccBus;
      end
      ORN: begin
        result_select = ResAccBus;
        op_select[0] = AccBus;
        op_select[1] = AccBus;
        alu_op = ALU_ORN;
      end
      XNOR: begin
        result_select = ResAccBus;
        op_select[0] = AccBus;
        op_select[1] = AccBus;
        alu_op = ALU_XNOR;
      end
      SLO, SLOI: begin
        result_select = ResAccBus;
        op_select[0] = AccBus;
        op_select[1] = AccBus;
        alu_op = ALU_SLO;
      end
      SRO, SROI: begin
        result_select = ResAccBus;
        op_select[0] = AccBus;
        op_select[1] = AccBus;
        alu_op = ALU_SRO;
      end
      ROL: begin
        result_select = ResAccBus;
        op_select[0] = AccBus;
        op_select[1] = AccBus;
        alu_op = ALU_ROL;
      end
      ROR, RORI: begin
        result_select = ResAccBus;
        op_select[0] = AccBus;
        op_select[1] = AccBus;
        alu_op = ALU_ROR;
      end
      SBCLR, SBCLRI: begin
        result_select = ResAccBus;
        op_select[0] = AccBus;
        op_select[1] = AccBus;
        alu_op = ALU_SBCLR;
      end
      SBSET, SBSETI: begin
        result_select = ResAccBus;
        op_select[0] = AccBus;
        op_select[1] = AccBus;
        alu_op = ALU_SBSET;
      end
      SBINV, SBINVI: begin
        result_select = ResAccBus;
        op_select[0] = AccBus;
        op_select[1] = AccBus;
        alu_op = ALU_SBINV;
      end
      SBEXT, SBEXTI: begin
        result_select = ResAccBus;
        op_select[0] = AccBus;
        op_select[1] = AccBus;
        alu_op = ALU_SBEXT;
      end
      GORC, GORCI: begin
        result_select = ResAccBus;
        op_select[0] = AccBus;
        op_select[1] = AccBus;
        alu_op = ALU_GORC;
      end
      GREV, GREVI: begin
        result_select = ResAccBus;
        op_select[0] = AccBus;
        op_select[1] = AccBus;
        alu_op = ALU_GREV;
      end
      CLZ: begin
        result_select = ResAccBus;
        op_select[0] = AccBus;
        op_select[1] = AccBus;
        alu_op = ALU_CLZ;
      end
      CTZ: begin
        result_select = ResAccBus;
        op_select[0] = AccBus;
        op_select[1] = AccBus;
        alu_op = ALU_CTZ;
      end
      PCNT: begin
        result_select = ResAccBus;
        op_select[0] = AccBus;
        op_select[1] = AccBus;
        alu_op = ALU_PCNT;
      end
      SEXT_B: begin
        result_select = ResAccBus;
        op_select[0] = AccBus;
        op_select[1] = AccBus;
        alu_op = ALU_SEXTB;
      end
      SEXT_H: begin
        result_select = ResAccBus;
        op_select[0] = AccBus;
        op_select[1] = AccBus;
        alu_op = ALU_SEXTH;
      end
      CRC32_B: begin
        result_select = ResAccBus;
        op_select[0] = AccBus;
        op_select[1] = AccBus;
        is_multicycle = 1'b1;
        alu_op = ALU_CRC32_B;
      end
      CRC32_H: begin
        result_select = ResAccBus;
        op_select[0] = AccBus;
        op_select[1] = AccBus;
        is_multicycle = 1'b1;
        alu_op = ALU_CRC32_H;
      end
      CRC32_W: begin
        result_select = ResAccBus;
        op_select[0] = AccBus;
        op_select[1] = AccBus;
        is_multicycle = 1'b1;
        alu_op = ALU_CRC32_W;
      end
      CRC32C_B: begin
        result_select = ResAccBus;
        op_select[0] = AccBus;
        op_select[1] = AccBus;
        is_multicycle = 1'b1;
        alu_op = ALU_CRC32C_B;
      end
      CRC32C_H: begin
        result_select = ResAccBus;
        op_select[0] = AccBus;
        op_select[1] = AccBus;
        is_multicycle = 1'b1;
        alu_op = ALU_CRC32C_H;
      end
      CRC32C_W: begin
        result_select = ResAccBus;
        op_select[0] = AccBus;
        op_select[1] = AccBus;
        is_multicycle = 1'b1;
        alu_op = ALU_CRC32C_W;
      end
      // Not implemented.
      // SH1ADD:;
      // SH2ADD:;
      // SH3ADD:;
      CLMUL: begin
        result_select = ResAccBus;
        op_select[0] = AccBus;
        op_select[1] = AccBus;
        is_multicycle = 1'b1;
        alu_op = ALU_CLMUL;
      end
      ALU_CLMULR: begin
        result_select = ResAccBus;
        op_select[0] = AccBus;
        op_select[1] = AccBus;
        is_multicycle = 1'b1;
        alu_op = ALU_CLMUL;
      end
      CLMULH: begin
        result_select = ResAccBus;
        op_select[0] = AccBus;
        op_select[1] = AccBus;
        is_multicycle = 1'b1;
        alu_op = ALU_CLMULH;
      end
      MIN: begin
        result_select = ResAccBus;
        op_select[0] = AccBus;
        op_select[1] = AccBus;
        alu_op = ALU_MIN;
      end
      MAX: begin
        result_select = ResAccBus;
        op_select[0] = AccBus;
        op_select[1] = AccBus;
        alu_op = ALU_MAX;
      end
      MINU: begin
        result_select = ResAccBus;
        op_select[0] = AccBus;
        op_select[1] = AccBus;
        alu_op = ALU_MINU;
      end
      MAXU: begin
        result_select = ResAccBus;
        op_select[0] = AccBus;
        op_select[1] = AccBus;
        alu_op = ALU_MAXU;
      end
      SHFL, SHFLI: begin
        result_select = ResAccBus;
        op_select[0] = AccBus;
        op_select[1] = AccBus;
        alu_op = ALU_SHFL;
      end
      UNSHFL, UNSHFLI: begin
        result_select = ResAccBus;
        op_select[0] = AccBus;
        op_select[1] = AccBus;
        alu_op = ALU_UNSHFL;
      end
      BEXT: begin
        result_select = ResAccBus;
        is_multicycle = 1'b1;
      end
      BDEP: begin
        result_select = ResAccBus;
        is_multicycle = 1'b1;
      end
      PACK: begin
        result_select = ResAccBus;
        op_select[0] = AccBus;
        op_select[1] = AccBus;
        alu_op = ALU_PACK;
      end
      PACKU: begin
        result_select = ResAccBus;
        op_select[0] = AccBus;
        op_select[1] = AccBus;
        alu_op = ALU_PACKU;
      end
      PACKH: begin
        result_select = ResAccBus;
        op_select[0] = AccBus;
        op_select[1] = AccBus;
        alu_op = ALU_PACKH;
      end
      BFP: begin
        result_select = ResAccBus;
        op_select[0] = AccBus;
        op_select[1] = AccBus;
        alu_op = ALU_BFP;
      end
      // Move back to integer register file
      IMV_X_W: begin
        op_select[0] = Reg;
        alu_op = ALU_OR;
        result_select = ResAccBus;
      end
      // Move from integer to IPU
      IMV_W_X: begin
        op_select[0] = AccBus;
        alu_op = ALU_OR;
      end
      // IPU Operations
      // Reg immediate
      IADDI: begin
        op_select[0] = Reg;
        op_select[1] = IImm;
        alu_op = ALU_ADD;
      end
      ISLLI: begin
        op_select[0] = Reg;
        op_select[1] = IImm;
        alu_op = ALU_SLL;
      end
      ISLTI: begin
        op_select[0] = Reg;
        op_select[1] = IImm;
        alu_op = ALU_SLT;
      end
      ISLTIU: begin
        op_select[0] = Reg;
        op_select[1] = IImm;
        alu_op = ALU_SLTU;
      end
      IXORI: begin
        op_select[0] = Reg;
        op_select[1] = IImm;
        alu_op = ALU_XOR;
      end
      ISRLI: begin
        op_select[0] = Reg;
        op_select[1] = IImm;
        alu_op = ALU_SRL;
      end
      ISRAI: begin
        op_select[0] = Reg;
        op_select[1] = IImm;
        alu_op = ALU_SRA;
      end
      IORI: begin
        op_select[0] = Reg;
        op_select[1] = IImm;
        alu_op = ALU_OR;
      end
      IANDI: begin
        op_select[0] = Reg;
        op_select[1] = IImm;
        alu_op = ALU_AND;
      end
      // Reg - Reg operations
      IADD: begin
        op_select[0] = Reg;
        op_select[1] = Reg;
        alu_op = ALU_ADD;
      end
      ISUB: begin
        op_select[0] = Reg;
        op_select[1] = Reg;
        alu_op = ALU_SUB;
      end
      ISLL: begin
        op_select[0] = Reg;
        op_select[1] = Reg;
        alu_op = ALU_SLL;
      end
      ISLT: begin
        op_select[0] = Reg;
        op_select[1] = Reg;
        alu_op = ALU_SLT;
      end
      ISLTU: begin
        op_select[0] = Reg;
        op_select[1] = Reg;
        alu_op = ALU_SLTU;
      end
      IXOR: begin
        op_select[0] = Reg;
        op_select[1] = Reg;
        alu_op = ALU_XOR;
      end
      ISRL: begin
        op_select[0] = Reg;
        op_select[1] = Reg;
        alu_op = ALU_SRL;
      end
      ISRA: begin
        op_select[0] = Reg;
        op_select[1] = Reg;
        alu_op = ALU_SRA;
      end
      IOR: begin
        op_select[0] = Reg;
        op_select[1] = Reg;
        alu_op = ALU_OR;
      end
      IAND: begin
        op_select[0] = Reg;
        op_select[1] = Reg;
        alu_op = ALU_AND;
      end
      // TODO(zarubaf): Implement the rest.
      default: begin
        illegal = 1'b1;
      end
    endcase
  end

  // ----------------------
  // Operand Select
  // ----------------------
  always_comb begin
    int_raddr[0] = rs1;
    int_raddr[1] = rs2;
    int_raddr[2] = rs3;
  end

  for (genvar i = 0; i < 3; i++) begin: gen_operand_select
    always_comb begin
      alu_operand[i] = '0;
      unique case (op_select[i])
        None:;
        Reg: alu_operand[i] = int_rdata[i];
        AccBus: begin
          unique case (i)
            0: alu_operand[i] = acc_req_q.data_arga;
            1: alu_operand[i] = acc_req_q.data_argb;
            2: alu_operand[i] = acc_req_q.data_argc;
            default:;
          endcase
        end
        IImm: begin
           alu_operand[i] = iimm;
        end
        default:;
      endcase
    end
  end

  // Write Port
  always_comb begin
    int_we = ~stall & valid_inst & (result_select == ResNone);
    int_wdata = alu_result;
    int_waddr = rd;
  end

  // -------
  // IPU ALU
  // -------
  snitch_ipu_alu #(
    .RV32B (RV32BFull)
  ) snitch_ipu_alu (
    .operator_i (alu_op),
    .operand_a_i (alu_operand[0]),
    .operand_b_i (alu_operand[1]),
    .instr_first_cycle_i (~multicycle_active_q),
    .imd_val_q_i (imd_val_q),
    .imd_val_d_o (imd_val_d),
    .imd_val_we_o (imd_val_we),
    .result_o (alu_result),
    .comparison_result_o (),
    .is_equal_result_o ()
  );

  for (genvar i = 0; i < 2; i++) begin : gen_multi_cycle_buffer
    `FFLNR(imd_val_q[i], imd_val_q[i], imd_val_we[i], clk_i)
  end

  // ---------------
  // Integer Regfile
  // ---------------
  snitch_regfile #(
    .DATA_WIDTH     ( 32 ),
    .NR_READ_PORTS  ( 3  ),
    .NR_WRITE_PORTS ( 1  ),
    .ZERO_REG_ZERO  ( 0  ),
    .ADDR_WIDTH     ( 5  )
  ) i_ipu_regfile (
    .clk_i,
    .raddr_i   ( int_raddr ),
    .rdata_o   ( int_rdata ),
    .waddr_i   ( int_waddr ),
    .wdata_i   ( int_wdata ),
    .we_i      ( int_we    )
  );

endmodule
