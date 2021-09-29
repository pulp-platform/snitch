// See LICENSE for license details.

#include "disasm.h"
#include <bitset>
#include <cstdarg>
#include <sstream>
#include <stdlib.h>
#include <string>
#include <vector>

struct : public arg_t {
  std::string to_string(insn_t insn) const {
    return std::to_string((int)insn.i_imm()) + '(' + xpr_name[insn.rs1()] + ')';
  }
} load_address;

struct : public arg_t {
  std::string to_string(insn_t insn) const {
    return std::to_string((int)insn.s_imm()) + '(' + xpr_name[insn.rs1()] + ')';
  }
} store_address;

struct : public arg_t {
  std::string to_string(insn_t insn) const {
    return std::string("(") + xpr_name[insn.rs1()] + ')';
  }
} amo_address;

struct : public arg_t {
  std::string to_string(insn_t insn) const { return xpr_name[insn.rd()]; }
} xrd;

struct : public arg_t {
  std::string to_string(insn_t insn) const { return xpr_name[insn.rs1()]; }
} xrs1;

struct : public arg_t {
  std::string to_string(insn_t insn) const { return xpr_name[insn.rs2()]; }
} xrs2;

struct : public arg_t {
  std::string to_string(insn_t insn) const { return fpr_name[insn.rd()]; }
} frd;

struct : public arg_t {
  std::string to_string(insn_t insn) const { return fpr_name[insn.rs1()]; }
} frs1;

struct : public arg_t {
  std::string to_string(insn_t insn) const { return fpr_name[insn.rs2()]; }
} frs2;

struct : public arg_t {
  std::string to_string(insn_t insn) const { return fpr_name[insn.rs3()]; }
} frs3;

struct : public arg_t {
  std::string to_string(insn_t insn) const {
    switch (insn.csr()) {
#define DECLARE_CSR(name, num)                                                 \
  case num:                                                                    \
    return #name;
#include "encoding.h"
#undef DECLARE_CSR
    default: {
      char buf[16];
      snprintf(buf, sizeof buf, "unknown_%03" PRIx64, insn.csr());
      return std::string(buf);
    }
    }
  }
} csr;

struct : public arg_t {
  std::string to_string(insn_t insn) const {
    return std::to_string((int)insn.i_imm());
  }
} imm;

struct : public arg_t {
  std::string to_string(insn_t insn) const {
    return std::to_string((int)insn.shamt());
  }
} shamt;

struct : public arg_t {
  std::string to_string(insn_t insn) const {
    std::stringstream s;
    s << std::hex << "0x" << ((uint32_t)insn.u_imm() >> 12);
    return s.str();
  }
} bigimm;

struct : public arg_t {
  std::string to_string(insn_t insn) const {
    return std::to_string(insn.rs1());
  }
} zimm5;

struct : public arg_t {
  std::string to_string(insn_t insn) const {
    std::stringstream s;
    int32_t target = insn.sb_imm();
    char sign = target >= 0 ? '+' : '-';
    s << "pc " << sign << ' ' << abs(target);
    return s.str();
  }
} branch_target;

struct : public arg_t {
  std::string to_string(insn_t insn) const {
    std::stringstream s;
    int32_t target = insn.uj_imm();
    char sign = target >= 0 ? '+' : '-';
    s << "pc " << sign << std::hex << " 0x" << abs(target);
    return s.str();
  }
} jump_target;

struct : public arg_t {
  std::string to_string(insn_t insn) const { return xpr_name[insn.rvc_rs1()]; }
} rvc_rs1;

struct : public arg_t {
  std::string to_string(insn_t insn) const { return xpr_name[insn.rvc_rs2()]; }
} rvc_rs2;

struct : public arg_t {
  std::string to_string(insn_t insn) const { return fpr_name[insn.rvc_rs2()]; }
} rvc_fp_rs2;

struct : public arg_t {
  std::string to_string(insn_t insn) const { return xpr_name[insn.rvc_rs1s()]; }
} rvc_rs1s;

struct : public arg_t {
  std::string to_string(insn_t insn) const { return xpr_name[insn.rvc_rs2s()]; }
} rvc_rs2s;

struct : public arg_t {
  std::string to_string(insn_t insn) const { return fpr_name[insn.rvc_rs2s()]; }
} rvc_fp_rs2s;

struct : public arg_t {
  std::string to_string(insn_t insn) const { return xpr_name[X_SP]; }
} rvc_sp;

struct : public arg_t {
  std::string to_string(insn_t insn) const {
    return std::to_string((int)insn.rvc_imm());
  }
} rvc_imm;

struct : public arg_t {
  std::string to_string(insn_t insn) const {
    return std::to_string((int)insn.rvc_addi4spn_imm());
  }
} rvc_addi4spn_imm;

struct : public arg_t {
  std::string to_string(insn_t insn) const {
    return std::to_string((int)insn.rvc_addi16sp_imm());
  }
} rvc_addi16sp_imm;

struct : public arg_t {
  std::string to_string(insn_t insn) const {
    return std::to_string((int)insn.rvc_lwsp_imm());
  }
} rvc_lwsp_imm;

struct : public arg_t {
  std::string to_string(insn_t insn) const {
    return std::to_string((int)(insn.rvc_imm() & 0x3f));
  }
} rvc_shamt;

struct : public arg_t {
  std::string to_string(insn_t insn) const {
    std::stringstream s;
    s << std::hex << "0x" << ((uint32_t)insn.rvc_imm() << 12 >> 12);
    return s.str();
  }
} rvc_uimm;

struct : public arg_t {
  std::string to_string(insn_t insn) const {
    return std::to_string((int)insn.rvc_lwsp_imm()) + '(' + xpr_name[X_SP] +
           ')';
  }
} rvc_lwsp_address;

struct : public arg_t {
  std::string to_string(insn_t insn) const {
    return std::to_string((int)insn.rvc_ldsp_imm()) + '(' + xpr_name[X_SP] +
           ')';
  }
} rvc_ldsp_address;

struct : public arg_t {
  std::string to_string(insn_t insn) const {
    return std::to_string((int)insn.rvc_swsp_imm()) + '(' + xpr_name[X_SP] +
           ')';
  }
} rvc_swsp_address;

struct : public arg_t {
  std::string to_string(insn_t insn) const {
    return std::to_string((int)insn.rvc_sdsp_imm()) + '(' + xpr_name[X_SP] +
           ')';
  }
} rvc_sdsp_address;

struct : public arg_t {
  std::string to_string(insn_t insn) const {
    return std::to_string((int)insn.rvc_lw_imm()) + '(' +
           xpr_name[insn.rvc_rs1s()] + ')';
  }
} rvc_lw_address;

struct : public arg_t {
  std::string to_string(insn_t insn) const {
    return std::to_string((int)insn.rvc_ld_imm()) + '(' +
           xpr_name[insn.rvc_rs1s()] + ')';
  }
} rvc_ld_address;

struct : public arg_t {
  std::string to_string(insn_t insn) const {
    std::stringstream s;
    int32_t target = insn.rvc_b_imm();
    char sign = target >= 0 ? '+' : '-';
    s << "pc " << sign << ' ' << abs(target);
    return s.str();
  }
} rvc_branch_target;

struct : public arg_t {
  std::string to_string(insn_t insn) const {
    std::stringstream s;
    int32_t target = insn.rvc_j_imm();
    char sign = target >= 0 ? '+' : '-';
    s << "pc " << sign << ' ' << abs(target);
    return s.str();
  }
} rvc_jump_target;

std::string disassembler_t::disassemble(insn_t insn) const {
  const disasm_insn_t *disasm_insn = lookup(insn);
  return disasm_insn ? disasm_insn->to_string(insn) : "unknown";
}

struct : public arg_t {
  std::string to_string(insn_t insn) const {
    return std::to_string((int)insn.i_uimm12());
  }
} i_uimm12;

struct : public arg_t {
  std::string to_string(insn_t insn) const {
    return std::to_string((int)insn.rep_num_inst());
  }
} rep_num_inst;

struct : public arg_t {
  std::string to_string(insn_t insn) const {
    return std::to_string((int)insn.rep_stagger_max());
  }
} rep_stagger_max;

struct : public arg_t {
  std::string to_string(insn_t insn) const {
    return "0b" + std::bitset<4>((int)insn.rep_stagger_mask()).to_string();
  }
} rep_stagger_mask;

struct : public arg_t {
  std::string to_string(insn_t insn) const {
    return std::to_string((int)insn.dm_imm());
  }
} dm_imm;

disassembler_t::disassembler_t(int xlen) {
  const uint32_t mask_rd = 0x1fUL << 7;
  const uint32_t match_rd_ra = 1UL << 7;
  const uint32_t mask_rs1 = 0x1fUL << 15;
  const uint32_t match_rs1_ra = 1UL << 15;
  const uint32_t mask_rs2 = 0x1fUL << 20;
  const uint32_t mask_imm = 0xfffUL << 20;
  const uint32_t match_imm_1 = 1UL << 20;
  const uint32_t mask_rvc_rs2 = 0x1fUL << 2;
  const uint32_t mask_rvc_imm = mask_rvc_rs2 | 0x1000UL;

#define DECLARE_INSN(code, match, mask)                                        \
  const uint32_t match_##code = match;                                         \
  const uint32_t mask_##code = mask;
#include "encoding.h"
#undef DECLARE_INSN

// explicit per-instruction disassembly
#define DISASM_INSN(name, code, extra, ...)                                    \
  add_insn(new disasm_insn_t(name, match_##code, mask_##code | (extra),        \
                             __VA_ARGS__));
#define DEFINE_NOARG(code)                                                     \
  add_insn(new disasm_insn_t(#code, match_##code, mask_##code, {}));
#define DEFINE_RTYPE(code) DISASM_INSN(#code, code, 0, {&xrd, &xrs1, &xrs2})
#define DEFINE_ITYPE(code) DISASM_INSN(#code, code, 0, {&xrd, &xrs1, &imm})
#define DEFINE_ITYPE_SHIFT(code)                                               \
  DISASM_INSN(#code, code, 0, {&xrd, &xrs1, &shamt})
#define DEFINE_I0TYPE(name, code)                                              \
  DISASM_INSN(name, code, mask_rs1, {&xrd, &imm})
#define DEFINE_I1TYPE(name, code)                                              \
  DISASM_INSN(name, code, mask_imm, {&xrd, &xrs1})
#define DEFINE_I2TYPE(name, code)                                              \
  DISASM_INSN(name, code, mask_rd | mask_imm, {&xrs1})
#define DEFINE_LTYPE(code) DISASM_INSN(#code, code, 0, {&xrd, &bigimm})
#define DEFINE_BTYPE(code)                                                     \
  DISASM_INSN(#code, code, 0, {&xrs1, &xrs2, &branch_target})
#define DEFINE_B0TYPE(name, code)                                              \
  DISASM_INSN(name, code, mask_rs1 | mask_rs2, {&branch_target})
#define DEFINE_B1TYPE(name, code)                                              \
  DISASM_INSN(name, code, mask_rs2, {&xrs1, &branch_target})
#define DEFINE_XLOAD(code) DISASM_INSN(#code, code, 0, {&xrd, &load_address})
#define DEFINE_XSTORE(code) DISASM_INSN(#code, code, 0, {&xrs2, &store_address})
#define DEFINE_XAMO(code)                                                      \
  DISASM_INSN(#code, code, 0, {&xrd, &xrs2, &amo_address})
#define DEFINE_XAMO_LR(code) DISASM_INSN(#code, code, 0, {&xrd, &amo_address})
#define DEFINE_FLOAD(code) DISASM_INSN(#code, code, 0, {&frd, &load_address})
#define DEFINE_FSTORE(code) DISASM_INSN(#code, code, 0, {&frs2, &store_address})
#define DEFINE_FRTYPE(code) DISASM_INSN(#code, code, 0, {&frd, &frs1, &frs2})
#define DEFINE_FR1TYPE(code) DISASM_INSN(#code, code, 0, {&frd, &frs1})
#define DEFINE_FR3TYPE(code)                                                   \
  DISASM_INSN(#code, code, 0, {&frd, &frs1, &frs2, &frs3})
#define DEFINE_FXTYPE(code) DISASM_INSN(#code, code, 0, {&xrd, &frs1})
#define DEFINE_FX2TYPE(code) DISASM_INSN(#code, code, 0, {&xrd, &frs1, &frs2})
#define DEFINE_XFTYPE(code) DISASM_INSN(#code, code, 0, {&frd, &xrs1})
#define DEFINE_SFENCE_TYPE(code) DISASM_INSN(#code, code, 0, {&xrs1, &xrs2})
#define DEFINE_RS1RS2_TYPE(code) DISASM_INSN(#code, code, 0, {&xrs1, &xrs2})
#define DEFINE_RDRS1IMM5_TYPE(code)                                            \
  DISASM_INSN(#code, code, 0, {&xrd, &xrs1, &dm_imm})
#define DEFINE_RDIMM5_TYPE(code) DISASM_INSN(#code, code, 0, {&xrd, &dm_imm})
#define DEFINE_RDRS2_TYPE(code) DISASM_INSN(#code, code, 0, {&xrd, &xrs2})
#define DEFINE_RS1_TYPE(code) DISASM_INSN(#code, code, 0, {&xrs1})
#define DEFINE_RDUIMM12_TYPE(code)                                             \
  DISASM_INSN(#code, code, 0, {&xrd, &i_uimm12})
#define DEFINE_RS1UIMM12_TYPE(code)                                            \
  DISASM_INSN(#code, code, 0, {&xrs1, &i_uimm12})

  DEFINE_XLOAD(lb)
  DEFINE_XLOAD(lbu)
  DEFINE_XLOAD(lh)
  DEFINE_XLOAD(lhu)
  DEFINE_XLOAD(lw)
  DEFINE_XLOAD(lwu)
  DEFINE_XLOAD(ld)

  DEFINE_XSTORE(sb)
  DEFINE_XSTORE(sh)
  DEFINE_XSTORE(sw)
  DEFINE_XSTORE(sd)

  DEFINE_XAMO(amoadd_w)
  DEFINE_XAMO(amoswap_w)
  DEFINE_XAMO(amoand_w)
  DEFINE_XAMO(amoor_w)
  DEFINE_XAMO(amoxor_w)
  DEFINE_XAMO(amomin_w)
  DEFINE_XAMO(amomax_w)
  DEFINE_XAMO(amominu_w)
  DEFINE_XAMO(amomaxu_w)
  DEFINE_XAMO(amoadd_d)
  DEFINE_XAMO(amoswap_d)
  DEFINE_XAMO(amoand_d)
  DEFINE_XAMO(amoor_d)
  DEFINE_XAMO(amoxor_d)
  DEFINE_XAMO(amomin_d)
  DEFINE_XAMO(amomax_d)
  DEFINE_XAMO(amominu_d)
  DEFINE_XAMO(amomaxu_d)

  DEFINE_XAMO_LR(lr_w)
  DEFINE_XAMO(sc_w)
  DEFINE_XAMO_LR(lr_d)
  DEFINE_XAMO(sc_d)

  DEFINE_FLOAD(flw)
  DEFINE_FLOAD(fld)
  DEFINE_FLOAD(flq)

  DEFINE_FSTORE(fsw)
  DEFINE_FSTORE(fsd)
  DEFINE_FSTORE(fsq)

  add_insn(
      new disasm_insn_t("j", match_jal, mask_jal | mask_rd, {&jump_target}));
  add_insn(new disasm_insn_t("jal", match_jal | match_rd_ra, mask_jal | mask_rd,
                             {&jump_target}));
  add_insn(new disasm_insn_t("jal", match_jal, mask_jal, {&xrd, &jump_target}));

  DEFINE_B1TYPE("beqz", beq);
  DEFINE_B1TYPE("bnez", bne);
  DEFINE_B1TYPE("bltz", blt);
  DEFINE_B1TYPE("bgez", bge);
  DEFINE_BTYPE(beq)
  DEFINE_BTYPE(bne)
  DEFINE_BTYPE(blt)
  DEFINE_BTYPE(bge)
  DEFINE_BTYPE(bltu)
  DEFINE_BTYPE(bgeu)

  DEFINE_LTYPE(lui);
  DEFINE_LTYPE(auipc);

  add_insn(new disasm_insn_t("ret", match_jalr | match_rs1_ra,
                             mask_jalr | mask_rd | mask_rs1 | mask_imm, {}));
  DEFINE_I2TYPE("jr", jalr);
  add_insn(new disasm_insn_t("jalr", match_jalr | match_rd_ra,
                             mask_jalr | mask_rd | mask_imm, {&xrs1}));
  DEFINE_ITYPE(jalr);

  add_insn(new disasm_insn_t("nop", match_addi,
                             mask_addi | mask_rd | mask_rs1 | mask_imm, {}));
  add_insn(new disasm_insn_t(" - ", match_xor,
                             mask_xor | mask_rd | mask_rs1 | mask_rs2,
                             {})); // for machine-generated bubbles
  DEFINE_I0TYPE("li", addi);
  DEFINE_I1TYPE("mv", addi);
  DEFINE_ITYPE(addi);
  DEFINE_ITYPE(slti);
  add_insn(new disasm_insn_t("seqz", match_sltiu | match_imm_1,
                             mask_sltiu | mask_imm, {&xrd, &xrs1}));
  DEFINE_ITYPE(sltiu);
  add_insn(new disasm_insn_t("not", match_xori | mask_imm, mask_xori | mask_imm,
                             {&xrd, &xrs1}));
  DEFINE_ITYPE(xori);

  DEFINE_ITYPE_SHIFT(slli);
  DEFINE_ITYPE_SHIFT(srli);
  DEFINE_ITYPE_SHIFT(srai);

  DEFINE_ITYPE(ori);
  DEFINE_ITYPE(andi);
  DEFINE_I1TYPE("sext.w", addiw);
  DEFINE_ITYPE(addiw);

  DEFINE_ITYPE_SHIFT(slliw);
  DEFINE_ITYPE_SHIFT(srliw);
  DEFINE_ITYPE_SHIFT(sraiw);

  DEFINE_RTYPE(add);
  DEFINE_RTYPE(sub);
  DEFINE_RTYPE(sll);
  DEFINE_RTYPE(slt);
  add_insn(new disasm_insn_t("snez", match_sltu, mask_sltu | mask_rs1,
                             {&xrd, &xrs2}));
  DEFINE_RTYPE(sltu);
  DEFINE_RTYPE(xor);
  DEFINE_RTYPE(srl);
  DEFINE_RTYPE(sra);
  DEFINE_RTYPE(or);
  DEFINE_RTYPE(and);
  DEFINE_RTYPE(mul);
  DEFINE_RTYPE(mulh);
  DEFINE_RTYPE(mulhu);
  DEFINE_RTYPE(mulhsu);
  DEFINE_RTYPE(div);
  DEFINE_RTYPE(divu);
  DEFINE_RTYPE(rem);
  DEFINE_RTYPE(remu);
  DEFINE_RTYPE(addw);
  DEFINE_RTYPE(subw);
  DEFINE_RTYPE(sllw);
  DEFINE_RTYPE(srlw);
  DEFINE_RTYPE(sraw);
  DEFINE_RTYPE(mulw);
  DEFINE_RTYPE(divw);
  DEFINE_RTYPE(divuw);
  DEFINE_RTYPE(remw);
  DEFINE_RTYPE(remuw);

  DEFINE_NOARG(ecall);
  DEFINE_NOARG(ebreak);
  DEFINE_NOARG(uret);
  DEFINE_NOARG(sret);
  DEFINE_NOARG(mret);
  DEFINE_NOARG(dret);
  DEFINE_NOARG(wfi);
  DEFINE_NOARG(fence);
  DEFINE_NOARG(fence_i);
  DEFINE_SFENCE_TYPE(sfence_vma);

  add_insn(new disasm_insn_t("csrr", match_csrrs, mask_csrrs | mask_rs1,
                             {&xrd, &csr}));
  add_insn(new disasm_insn_t("csrw", match_csrrw, mask_csrrw | mask_rd,
                             {&csr, &xrs1}));
  add_insn(new disasm_insn_t("csrs", match_csrrs, mask_csrrs | mask_rd,
                             {&csr, &xrs1}));
  add_insn(new disasm_insn_t("csrc", match_csrrc, mask_csrrc | mask_rd,
                             {&csr, &xrs1}));
  add_insn(new disasm_insn_t("csrwi", match_csrrwi, mask_csrrwi | mask_rd,
                             {&csr, &zimm5}));
  add_insn(new disasm_insn_t("csrsi", match_csrrsi, mask_csrrsi | mask_rd,
                             {&csr, &zimm5}));
  add_insn(new disasm_insn_t("csrci", match_csrrci, mask_csrrci | mask_rd,
                             {&csr, &zimm5}));
  add_insn(
      new disasm_insn_t("csrrw", match_csrrw, mask_csrrw, {&xrd, &csr, &xrs1}));
  add_insn(
      new disasm_insn_t("csrrs", match_csrrs, mask_csrrs, {&xrd, &csr, &xrs1}));
  add_insn(
      new disasm_insn_t("csrrc", match_csrrc, mask_csrrc, {&xrd, &csr, &xrs1}));
  add_insn(new disasm_insn_t("csrrwi", match_csrrwi, mask_csrrwi,
                             {&xrd, &csr, &zimm5}));
  add_insn(new disasm_insn_t("csrrsi", match_csrrsi, mask_csrrsi,
                             {&xrd, &csr, &zimm5}));
  add_insn(new disasm_insn_t("csrrci", match_csrrci, mask_csrrci,
                             {&xrd, &csr, &zimm5}));

  DEFINE_FRTYPE(fadd_s);
  DEFINE_FRTYPE(fsub_s);
  DEFINE_FRTYPE(fmul_s);
  DEFINE_FRTYPE(fdiv_s);
  DEFINE_FR1TYPE(fsqrt_s);
  DEFINE_FRTYPE(fmin_s);
  DEFINE_FRTYPE(fmax_s);
  DEFINE_FR3TYPE(fmadd_s);
  DEFINE_FR3TYPE(fmsub_s);
  DEFINE_FR3TYPE(fnmadd_s);
  DEFINE_FR3TYPE(fnmsub_s);
  DEFINE_FRTYPE(fsgnj_s);
  DEFINE_FRTYPE(fsgnjn_s);
  DEFINE_FRTYPE(fsgnjx_s);
  DEFINE_FR1TYPE(fcvt_s_d);
  DEFINE_FR1TYPE(fcvt_s_q);
  DEFINE_XFTYPE(fcvt_s_l);
  DEFINE_XFTYPE(fcvt_s_lu);
  DEFINE_XFTYPE(fcvt_s_w);
  DEFINE_XFTYPE(fcvt_s_wu);
  DEFINE_XFTYPE(fcvt_s_wu);
  DEFINE_XFTYPE(fmv_w_x);
  DEFINE_FXTYPE(fcvt_l_s);
  DEFINE_FXTYPE(fcvt_lu_s);
  DEFINE_FXTYPE(fcvt_w_s);
  DEFINE_FXTYPE(fcvt_wu_s);
  DEFINE_FXTYPE(fclass_s);
  DEFINE_FXTYPE(fmv_x_w);
  DEFINE_FX2TYPE(feq_s);
  DEFINE_FX2TYPE(flt_s);
  DEFINE_FX2TYPE(fle_s);

  DEFINE_FRTYPE(fadd_d);
  DEFINE_FRTYPE(fsub_d);
  DEFINE_FRTYPE(fmul_d);
  DEFINE_FRTYPE(fdiv_d);
  DEFINE_FR1TYPE(fsqrt_d);
  DEFINE_FRTYPE(fmin_d);
  DEFINE_FRTYPE(fmax_d);
  DEFINE_FR3TYPE(fmadd_d);
  DEFINE_FR3TYPE(fmsub_d);
  DEFINE_FR3TYPE(fnmadd_d);
  DEFINE_FR3TYPE(fnmsub_d);
  DEFINE_FRTYPE(fsgnj_d);
  DEFINE_FRTYPE(fsgnjn_d);
  DEFINE_FRTYPE(fsgnjx_d);
  DEFINE_FR1TYPE(fcvt_d_s);
  DEFINE_FR1TYPE(fcvt_d_q);
  DEFINE_XFTYPE(fcvt_d_l);
  DEFINE_XFTYPE(fcvt_d_lu);
  DEFINE_XFTYPE(fcvt_d_w);
  DEFINE_XFTYPE(fcvt_d_wu);
  DEFINE_XFTYPE(fcvt_d_wu);
  DEFINE_XFTYPE(fmv_d_x);
  DEFINE_FXTYPE(fcvt_l_d);
  DEFINE_FXTYPE(fcvt_lu_d);
  DEFINE_FXTYPE(fcvt_w_d);
  DEFINE_FXTYPE(fcvt_wu_d);
  DEFINE_FXTYPE(fclass_d);
  DEFINE_FXTYPE(fmv_x_d);
  DEFINE_FX2TYPE(feq_d);
  DEFINE_FX2TYPE(flt_d);
  DEFINE_FX2TYPE(fle_d);

  DEFINE_FRTYPE(fadd_q);
  DEFINE_FRTYPE(fsub_q);
  DEFINE_FRTYPE(fmul_q);
  DEFINE_FRTYPE(fdiv_q);
  DEFINE_FR1TYPE(fsqrt_q);
  DEFINE_FRTYPE(fmin_q);
  DEFINE_FRTYPE(fmax_q);
  DEFINE_FR3TYPE(fmadd_q);
  DEFINE_FR3TYPE(fmsub_q);
  DEFINE_FR3TYPE(fnmadd_q);
  DEFINE_FR3TYPE(fnmsub_q);
  DEFINE_FRTYPE(fsgnj_q);
  DEFINE_FRTYPE(fsgnjn_q);
  DEFINE_FRTYPE(fsgnjx_q);
  DEFINE_FR1TYPE(fcvt_q_s);
  DEFINE_FR1TYPE(fcvt_q_d);
  DEFINE_XFTYPE(fcvt_q_l);
  DEFINE_XFTYPE(fcvt_q_lu);
  DEFINE_XFTYPE(fcvt_q_w);
  DEFINE_XFTYPE(fcvt_q_wu);
  DEFINE_XFTYPE(fcvt_q_wu);
  DEFINE_XFTYPE(fmv_q_x);
  DEFINE_FXTYPE(fcvt_l_q);
  DEFINE_FXTYPE(fcvt_lu_q);
  DEFINE_FXTYPE(fcvt_w_q);
  DEFINE_FXTYPE(fcvt_wu_q);
  DEFINE_FXTYPE(fclass_q);
  DEFINE_FXTYPE(fmv_x_q);
  DEFINE_FX2TYPE(feq_q);
  DEFINE_FX2TYPE(flt_q);
  DEFINE_FX2TYPE(fle_q);

  DISASM_INSN("c.ebreak", c_add, mask_rd | mask_rvc_rs2, {});
  add_insn(new disasm_insn_t("ret", match_c_jr | match_rd_ra,
                             mask_c_jr | mask_rd | mask_rvc_imm, {}));
  DISASM_INSN("c.jr", c_jr, mask_rvc_imm, {&rvc_rs1});
  DISASM_INSN("c.jalr", c_jalr, mask_rvc_imm, {&rvc_rs1});
  DISASM_INSN("c.nop", c_addi, mask_rd | mask_rvc_imm, {});
  DISASM_INSN("c.addi16sp", c_addi16sp, mask_rd, {&rvc_sp, &rvc_addi16sp_imm});
  DISASM_INSN("c.addi4spn", c_addi4spn, 0,
              {&rvc_rs2s, &rvc_sp, &rvc_addi4spn_imm});
  DISASM_INSN("c.li", c_li, 0, {&xrd, &rvc_imm});
  DISASM_INSN("c.lui", c_lui, 0, {&xrd, &rvc_uimm});
  DISASM_INSN("c.addi", c_addi, 0, {&xrd, &rvc_imm});
  DISASM_INSN("c.slli", c_slli, 0, {&rvc_rs1, &rvc_shamt});
  DISASM_INSN("c.srli", c_srli, 0, {&rvc_rs1s, &rvc_shamt});
  DISASM_INSN("c.srai", c_srai, 0, {&rvc_rs1s, &rvc_shamt});
  DISASM_INSN("c.andi", c_andi, 0, {&rvc_rs1s, &rvc_imm});
  DISASM_INSN("c.mv", c_mv, 0, {&xrd, &rvc_rs2});
  DISASM_INSN("c.add", c_add, 0, {&xrd, &rvc_rs2});
  DISASM_INSN("c.addw", c_addw, 0, {&rvc_rs1s, &rvc_rs2s});
  DISASM_INSN("c.sub", c_sub, 0, {&rvc_rs1s, &rvc_rs2s});
  DISASM_INSN("c.subw", c_subw, 0, {&rvc_rs1s, &rvc_rs2s});
  DISASM_INSN("c.and", c_and, 0, {&rvc_rs1s, &rvc_rs2s});
  DISASM_INSN("c.or", c_or, 0, {&rvc_rs1s, &rvc_rs2s});
  DISASM_INSN("c.xor", c_xor, 0, {&rvc_rs1s, &rvc_rs2s});
  DISASM_INSN("c.lwsp", c_lwsp, 0, {&xrd, &rvc_lwsp_address});
  DISASM_INSN("c.fld", c_fld, 0, {&rvc_fp_rs2s, &rvc_ld_address});
  DISASM_INSN("c.swsp", c_swsp, 0, {&rvc_rs2, &rvc_swsp_address});
  DISASM_INSN("c.lw", c_lw, 0, {&rvc_rs2s, &rvc_lw_address});
  DISASM_INSN("c.sw", c_sw, 0, {&rvc_rs2s, &rvc_lw_address});
  DISASM_INSN("c.beqz", c_beqz, 0, {&rvc_rs1s, &rvc_branch_target});
  DISASM_INSN("c.bnez", c_bnez, 0, {&rvc_rs1s, &rvc_branch_target});
  DISASM_INSN("c.j", c_j, 0, {&rvc_jump_target});
  DISASM_INSN("c.fldsp", c_fldsp, 0, {&rvc_fp_rs2s, &rvc_ldsp_address});
  DISASM_INSN("c.fsd", c_fsd, 0, {&rvc_fp_rs2s, &rvc_ld_address});
  DISASM_INSN("c.fsdsp", c_fsdsp, 0, {&rvc_fp_rs2s, &rvc_sdsp_address});

  if (xlen == 32) {
    DISASM_INSN("c.flw", c_flw, 0, {&rvc_fp_rs2s, &rvc_lw_address});
    DISASM_INSN("c.flwsp", c_flwsp, 0, {&frd, &rvc_lwsp_address});
    DISASM_INSN("c.fsw", c_fsw, 0, {&rvc_fp_rs2s, &rvc_lw_address});
    DISASM_INSN("c.fswsp", c_fswsp, 0, {&rvc_fp_rs2, &rvc_swsp_address});
    DISASM_INSN("c.jal", c_jal, 0, {&rvc_jump_target});
  } else {
    DISASM_INSN("c.ld", c_ld, 0, {&rvc_rs2s, &rvc_ld_address});
    DISASM_INSN("c.ldsp", c_ldsp, 0, {&xrd, &rvc_ldsp_address});
    DISASM_INSN("c.sd", c_sd, 0, {&rvc_rs2s, &rvc_ld_address});
    DISASM_INSN("c.sdsp", c_sdsp, 0, {&rvc_rs2, &rvc_sdsp_address});
    DISASM_INSN("c.addiw", c_addiw, 0, {&xrd, &rvc_imm});
  }
  // "Xdma" Extension for Asynchronous Data Movement
  DEFINE_RTYPE(dmcpy);
  DEFINE_RS1RS2_TYPE(dmsrc);
  DEFINE_RS1RS2_TYPE(dmdst);
  DEFINE_RS1RS2_TYPE(dmstr);
  DEFINE_RDRS1IMM5_TYPE(dmcpyi);
  DEFINE_RDIMM5_TYPE(dmstati);
  DEFINE_RDRS2_TYPE(dmstat);
  DEFINE_RS1_TYPE(dmrep);

  // "Xssr" Extension for Stream Semantic Registers
  DEFINE_RDUIMM12_TYPE(scfgri);
  DEFINE_RS1UIMM12_TYPE(scfgwi);
  DEFINE_RDRS2_TYPE(scfgr);
  DEFINE_RS1RS2_TYPE(scfgw);

  // "Xfrep" Extension for Floating-Point Repetition
#define DEFINE_REP_TYPE(code)                                                  \
  DISASM_INSN(#code, code, 0,                                                  \
              {&xrs1, &rep_num_inst, &rep_stagger_max, &rep_stagger_mask})
  DEFINE_REP_TYPE(frep_o);
  DEFINE_REP_TYPE(frep_i);

  // smallfloat: half
  DEFINE_FLOAD(flh)
  DEFINE_FRTYPE(fadd_h);
  DEFINE_FRTYPE(fsub_h);
  DEFINE_FRTYPE(fmul_h);
  DEFINE_FRTYPE(fdiv_h);
  DEFINE_FR1TYPE(fsqrt_h);
  DEFINE_FRTYPE(fmin_h);
  DEFINE_FRTYPE(fmax_h);
  DEFINE_FR3TYPE(fmadd_h);
  DEFINE_FR3TYPE(fmsub_h);
  DEFINE_FR3TYPE(fnmadd_h);
  DEFINE_FR3TYPE(fnmsub_h);
  DEFINE_FRTYPE(fsgnj_h);
  DEFINE_FRTYPE(fsgnjn_h);
  DEFINE_FRTYPE(fsgnjx_h);
  DEFINE_FR1TYPE(fcvt_d_h);
  DEFINE_FR1TYPE(fcvt_h_d);
  DEFINE_FR1TYPE(fcvt_h_h);
  DEFINE_FR1TYPE(fcvt_s_h);
  DEFINE_FR1TYPE(fcvt_h_s);
  DEFINE_XFTYPE(fcvt_h_l);
  DEFINE_XFTYPE(fcvt_h_lu);
  DEFINE_XFTYPE(fcvt_h_w);
  DEFINE_XFTYPE(fcvt_h_wu);
  DEFINE_FXTYPE(fcvt_l_h);
  DEFINE_FXTYPE(fcvt_lu_h);
  DEFINE_FXTYPE(fcvt_w_h);
  DEFINE_FXTYPE(fcvt_wu_h);
  DEFINE_FXTYPE(fclass_h);
  DEFINE_XFTYPE(fmv_h_x);
  DEFINE_FXTYPE(fmv_x_h);
  DEFINE_FX2TYPE(feq_h);
  DEFINE_FX2TYPE(flt_h);
  DEFINE_FX2TYPE(fle_h);
  // smallfloat: alt-half
  DEFINE_FLOAD(flah)
  DEFINE_FRTYPE(fadd_ah);
  DEFINE_FRTYPE(fsub_ah);
  DEFINE_FRTYPE(fmul_ah);
  DEFINE_FRTYPE(fdiv_ah);
  DEFINE_FR1TYPE(fsqrt_ah);
  DEFINE_FRTYPE(fmin_ah);
  DEFINE_FRTYPE(fmax_ah);
  DEFINE_FR3TYPE(fmadd_ah);
  DEFINE_FR3TYPE(fmsub_ah);
  DEFINE_FR3TYPE(fnmadd_ah);
  DEFINE_FR3TYPE(fnmsub_ah);
  DEFINE_FRTYPE(fsgnj_ah);
  DEFINE_FRTYPE(fsgnjn_ah);
  DEFINE_FRTYPE(fsgnjx_ah);
  DEFINE_FR1TYPE(fcvt_ah_d);
  DEFINE_FR1TYPE(fcvt_d_ah);
  DEFINE_FR1TYPE(fcvt_h_h);
  DEFINE_FR1TYPE(fcvt_ah_h);
  DEFINE_FR1TYPE(fcvt_ah_ah);
  DEFINE_FR1TYPE(fcvt_h_ah);
  DEFINE_XFTYPE(fcvt_ah_l);
  DEFINE_XFTYPE(fcvt_ah_lu);
  DEFINE_XFTYPE(fcvt_ah_w);
  DEFINE_XFTYPE(fcvt_ah_wu);
  DEFINE_FXTYPE(fcvt_l_ah);
  DEFINE_FXTYPE(fcvt_lu_ah);
  DEFINE_FXTYPE(fcvt_w_ah);
  DEFINE_FXTYPE(fcvt_wu_ah);
  DEFINE_FXTYPE(fclass_ah);
  DEFINE_XFTYPE(fmv_ah_x);
  DEFINE_FXTYPE(fmv_x_ah);
  DEFINE_FX2TYPE(feq_ah);
  DEFINE_FX2TYPE(flt_ah);
  DEFINE_FX2TYPE(fle_ah);
  // smallfloat: quarter
  DEFINE_FLOAD(flb)
  DEFINE_FRTYPE(fadd_b);
  DEFINE_FRTYPE(fsub_b);
  DEFINE_FRTYPE(fmul_b);
  DEFINE_FRTYPE(fdiv_b);
  DEFINE_FR1TYPE(fsqrt_b);
  DEFINE_FRTYPE(fmin_b);
  DEFINE_FRTYPE(fmax_b);
  DEFINE_FR3TYPE(fmadd_b);
  DEFINE_FR3TYPE(fmsub_b);
  DEFINE_FR3TYPE(fnmadd_b);
  DEFINE_FR3TYPE(fnmsub_b);
  DEFINE_FRTYPE(fsgnj_b);
  DEFINE_FRTYPE(fsgnjn_b);
  DEFINE_FRTYPE(fsgnjx_b);
  DEFINE_FR1TYPE(fcvt_b_d);
  DEFINE_FR1TYPE(fcvt_b_b);
  DEFINE_XFTYPE(fcvt_b_l);
  DEFINE_XFTYPE(fcvt_b_lu);
  DEFINE_XFTYPE(fcvt_b_w);
  DEFINE_XFTYPE(fcvt_b_wu);
  DEFINE_FXTYPE(fcvt_l_b);
  DEFINE_FXTYPE(fcvt_lu_b);
  DEFINE_FXTYPE(fcvt_w_b);
  DEFINE_FXTYPE(fcvt_wu_b);
  DEFINE_FXTYPE(fclass_b);
  DEFINE_XFTYPE(fmv_b_x);
  DEFINE_FXTYPE(fmv_x_b);
  DEFINE_FX2TYPE(feq_b);
  DEFINE_FX2TYPE(flt_b);
  DEFINE_FX2TYPE(fle_b);
  // smallfloat: alt-quarter
  DEFINE_FLOAD(flab)
  DEFINE_FRTYPE(fadd_ab);
  DEFINE_FRTYPE(fsub_ab);
  DEFINE_FRTYPE(fmul_ab);
  DEFINE_FRTYPE(fdiv_ab);
  DEFINE_FR1TYPE(fsqrt_ab);
  DEFINE_FRTYPE(fmin_ab);
  DEFINE_FRTYPE(fmax_ab);
  DEFINE_FR3TYPE(fmadd_ab);
  DEFINE_FR3TYPE(fmsub_ab);
  DEFINE_FR3TYPE(fnmadd_ab);
  DEFINE_FR3TYPE(fnmsub_ab);
  DEFINE_FRTYPE(fsgnj_ab);
  DEFINE_FRTYPE(fsgnjn_ab);
  DEFINE_FRTYPE(fsgnjx_ab);
  DEFINE_FR1TYPE(fcvt_ab_d);
  DEFINE_FR1TYPE(fcvt_ab_ab);
  DEFINE_XFTYPE(fcvt_ab_l);
  DEFINE_XFTYPE(fcvt_ab_lu);
  DEFINE_XFTYPE(fcvt_ab_w);
  DEFINE_XFTYPE(fcvt_ab_wu);
  DEFINE_FXTYPE(fcvt_l_ab);
  DEFINE_FXTYPE(fcvt_lu_ab);
  DEFINE_FXTYPE(fcvt_w_ab);
  DEFINE_FXTYPE(fcvt_wu_ab);
  DEFINE_FXTYPE(fclass_ab);
  DEFINE_XFTYPE(fmv_ab_x);
  DEFINE_FXTYPE(fmv_x_ab);
  DEFINE_FX2TYPE(feq_ab);
  DEFINE_FX2TYPE(flt_ab);
  DEFINE_FX2TYPE(fle_ab);
  // vector single
  DEFINE_FRTYPE(vfadd_s);
  DEFINE_FRTYPE(vfadd_r_s);
  DEFINE_FRTYPE(vfsub_s);
  DEFINE_FRTYPE(vfsub_r_s);
  DEFINE_FRTYPE(vfmul_s);
  DEFINE_FRTYPE(vfmul_r_s);
  DEFINE_FRTYPE(vfdiv_s);
  DEFINE_FRTYPE(vfdiv_r_s);
  DEFINE_FRTYPE(vfmin_s);
  DEFINE_FRTYPE(vfmin_r_s);
  DEFINE_FRTYPE(vfmax_s);
  DEFINE_FRTYPE(vfmax_r_s);
  DEFINE_FR1TYPE(vfsqrt_s);
  DEFINE_FRTYPE(vfmac_s);
  DEFINE_FRTYPE(vfmac_r_s);
  DEFINE_FRTYPE(vfmre_s);
  DEFINE_FRTYPE(vfmre_r_s);
  DEFINE_FR1TYPE(vfclass_s);
  DEFINE_FRTYPE(vfsgnj_s);
  DEFINE_FRTYPE(vfsgnj_r_s);
  DEFINE_FRTYPE(vfsgnjn_s);
  DEFINE_FRTYPE(vfsgnjn_r_s);
  DEFINE_FRTYPE(vfsgnjx_s);
  DEFINE_FRTYPE(vfsgnjx_r_s);
  DEFINE_FRTYPE(vfeq_s);
  DEFINE_FRTYPE(vfeq_r_s);
  DEFINE_FRTYPE(vfne_s);
  DEFINE_FRTYPE(vfne_r_s);
  DEFINE_FRTYPE(vflt_s);
  DEFINE_FRTYPE(vflt_r_s);
  DEFINE_FRTYPE(vfge_s);
  DEFINE_FRTYPE(vfge_r_s);
  DEFINE_FRTYPE(vfle_s);
  DEFINE_FRTYPE(vfle_r_s);
  DEFINE_FRTYPE(vfgt_s);
  DEFINE_FRTYPE(vfgt_r_s);
  DEFINE_FR1TYPE(vfmv_x_s);
  DEFINE_FR1TYPE(vfmv_s_x);
  DEFINE_FR1TYPE(vfcvt_x_s);
  DEFINE_FR1TYPE(vfcvt_xu_s);
  DEFINE_FR1TYPE(vfcvt_s_x);
  DEFINE_FR1TYPE(vfcvt_s_xu);
  DEFINE_FRTYPE(vfcpka_s_s);
  DEFINE_FRTYPE(vfcpkb_s_s);
  DEFINE_FRTYPE(vfcpkc_s_s);
  DEFINE_FRTYPE(vfcpkd_s_s);
  DEFINE_FRTYPE(vfcpka_s_d);
  DEFINE_FRTYPE(vfcpkb_s_d);
  DEFINE_FRTYPE(vfcpkc_s_d);
  DEFINE_FRTYPE(vfcpkd_s_d);
  DEFINE_FR1TYPE(vfcvt_h_h);
  DEFINE_FR1TYPE(vfcvt_h_ah);
  DEFINE_FR1TYPE(vfcvt_ah_h);
  DEFINE_FR1TYPE(vfcvtu_h_h);
  DEFINE_FR1TYPE(vfcvtu_h_ah);
  DEFINE_FR1TYPE(vfcvtu_ah_h);
  // vector half
  DEFINE_FRTYPE(vfadd_h);
  DEFINE_FRTYPE(vfadd_r_h);
  DEFINE_FRTYPE(vfsub_h);
  DEFINE_FRTYPE(vfsub_r_h);
  DEFINE_FRTYPE(vfmul_h);
  DEFINE_FRTYPE(vfmul_r_h);
  DEFINE_FRTYPE(vfdiv_h);
  DEFINE_FRTYPE(vfdiv_r_h);
  DEFINE_FRTYPE(vfmin_h);
  DEFINE_FRTYPE(vfmin_r_h);
  DEFINE_FRTYPE(vfmax_h);
  DEFINE_FRTYPE(vfmax_r_h);
  DEFINE_FR1TYPE(vfsqrt_h);
  DEFINE_FRTYPE(vfmac_h);
  DEFINE_FRTYPE(vfmac_r_h);
  DEFINE_FRTYPE(vfmre_h);
  DEFINE_FRTYPE(vfmre_r_h);
  DEFINE_FR1TYPE(vfclass_h);
  DEFINE_FRTYPE(vfsgnj_h);
  DEFINE_FRTYPE(vfsgnj_r_h);
  DEFINE_FRTYPE(vfsgnjn_h);
  DEFINE_FRTYPE(vfsgnjn_r_h);
  DEFINE_FRTYPE(vfsgnjx_h);
  DEFINE_FRTYPE(vfsgnjx_r_h);
  DEFINE_FRTYPE(vfeq_h);
  DEFINE_FRTYPE(vfeq_r_h);
  DEFINE_FRTYPE(vfne_h);
  DEFINE_FRTYPE(vfne_r_h);
  DEFINE_FRTYPE(vflt_h);
  DEFINE_FRTYPE(vflt_r_h);
  DEFINE_FRTYPE(vfge_h);
  DEFINE_FRTYPE(vfge_r_h);
  DEFINE_FRTYPE(vfle_h);
  DEFINE_FRTYPE(vfle_r_h);
  DEFINE_FRTYPE(vfgt_h);
  DEFINE_FRTYPE(vfgt_r_h);
  DEFINE_FR1TYPE(vfmv_x_h);
  DEFINE_FR1TYPE(vfmv_h_x);
  DEFINE_FR1TYPE(vfcvt_x_h);
  DEFINE_FR1TYPE(vfcvt_xu_h);
  DEFINE_FR1TYPE(vfcvt_h_x);
  DEFINE_FR1TYPE(vfcvt_h_xu);
  DEFINE_FRTYPE(vfcpka_h_s);
  DEFINE_FRTYPE(vfcpkb_h_s);
  DEFINE_FRTYPE(vfcpkc_h_s);
  DEFINE_FRTYPE(vfcpkd_h_s);
  DEFINE_FRTYPE(vfcpka_h_d);
  DEFINE_FRTYPE(vfcpkb_h_d);
  DEFINE_FRTYPE(vfcpkc_h_d);
  DEFINE_FRTYPE(vfcpkd_h_d);
  DEFINE_FR1TYPE(vfcvt_s_h);
  DEFINE_FR1TYPE(vfcvtu_s_h);
  DEFINE_FR1TYPE(vfcvt_h_s);
  DEFINE_FR1TYPE(vfcvtu_h_s);
  // vector alt-half
  DEFINE_FRTYPE(vfadd_ah);
  DEFINE_FRTYPE(vfadd_r_ah);
  DEFINE_FRTYPE(vfsub_ah);
  DEFINE_FRTYPE(vfsub_r_ah);
  DEFINE_FRTYPE(vfmul_ah);
  DEFINE_FRTYPE(vfmul_r_ah);
  DEFINE_FRTYPE(vfdiv_ah);
  DEFINE_FRTYPE(vfdiv_r_ah);
  DEFINE_FRTYPE(vfmin_ah);
  DEFINE_FRTYPE(vfmin_r_ah);
  DEFINE_FRTYPE(vfmax_ah);
  DEFINE_FRTYPE(vfmax_r_ah);
  DEFINE_FR1TYPE(vfsqrt_ah);
  DEFINE_FRTYPE(vfmac_ah);
  DEFINE_FRTYPE(vfmac_r_ah);
  DEFINE_FRTYPE(vfmre_ah);
  DEFINE_FRTYPE(vfmre_r_ah);
  DEFINE_FR1TYPE(vfclass_ah);
  DEFINE_FRTYPE(vfsgnj_ah);
  DEFINE_FRTYPE(vfsgnj_r_ah);
  DEFINE_FRTYPE(vfsgnjn_ah);
  DEFINE_FRTYPE(vfsgnjn_r_ah);
  DEFINE_FRTYPE(vfsgnjx_ah);
  DEFINE_FRTYPE(vfsgnjx_r_ah);
  DEFINE_FRTYPE(vfeq_ah);
  DEFINE_FRTYPE(vfeq_r_ah);
  DEFINE_FRTYPE(vfne_ah);
  DEFINE_FRTYPE(vfne_r_ah);
  DEFINE_FRTYPE(vflt_ah);
  DEFINE_FRTYPE(vflt_r_ah);
  DEFINE_FRTYPE(vfge_ah);
  DEFINE_FRTYPE(vfge_r_ah);
  DEFINE_FRTYPE(vfle_ah);
  DEFINE_FRTYPE(vfle_r_ah);
  DEFINE_FRTYPE(vfgt_ah);
  DEFINE_FRTYPE(vfgt_r_ah);
  DEFINE_FR1TYPE(vfmv_x_ah);
  DEFINE_FR1TYPE(vfmv_ah_x);
  DEFINE_FR1TYPE(vfcvt_x_ah);
  DEFINE_FR1TYPE(vfcvt_xu_ah);
  DEFINE_FR1TYPE(vfcvt_ah_x);
  DEFINE_FR1TYPE(vfcvt_ah_xu);
  DEFINE_FRTYPE(vfcpka_ah_s);
  DEFINE_FRTYPE(vfcpkb_ah_s);
  DEFINE_FRTYPE(vfcpkc_ah_s);
  DEFINE_FRTYPE(vfcpkd_ah_s);
  DEFINE_FRTYPE(vfcpka_ah_d);
  DEFINE_FRTYPE(vfcpkb_ah_d);
  DEFINE_FRTYPE(vfcpkc_ah_d);
  DEFINE_FRTYPE(vfcpkd_ah_d);
  DEFINE_FR1TYPE(vfcvt_s_ah);
  DEFINE_FR1TYPE(vfcvtu_s_ah);
  DEFINE_FR1TYPE(vfcvt_ah_s);
  DEFINE_FR1TYPE(vfcvtu_ah_s);
  // vector quarter
  DEFINE_FRTYPE(vfadd_b);
  DEFINE_FRTYPE(vfadd_r_b);
  DEFINE_FRTYPE(vfsub_b);
  DEFINE_FRTYPE(vfsub_r_b);
  DEFINE_FRTYPE(vfmul_b);
  DEFINE_FRTYPE(vfmul_r_b);
  DEFINE_FRTYPE(vfdiv_b);
  DEFINE_FRTYPE(vfdiv_r_b);
  DEFINE_FRTYPE(vfmin_b);
  DEFINE_FRTYPE(vfmin_r_b);
  DEFINE_FRTYPE(vfmax_b);
  DEFINE_FRTYPE(vfmax_r_b);
  DEFINE_FR1TYPE(vfsqrt_b);
  DEFINE_FRTYPE(vfmac_b);
  DEFINE_FRTYPE(vfmac_r_b);
  DEFINE_FRTYPE(vfmre_b);
  DEFINE_FRTYPE(vfmre_r_b);
  DEFINE_FRTYPE(vfsgnj_b);
  DEFINE_FRTYPE(vfsgnj_r_b);
  DEFINE_FRTYPE(vfsgnjn_b);
  DEFINE_FRTYPE(vfsgnjn_r_b);
  DEFINE_FRTYPE(vfsgnjx_b);
  DEFINE_FRTYPE(vfsgnjx_r_b);
  DEFINE_FRTYPE(vfeq_b);
  DEFINE_FRTYPE(vfeq_r_b);
  DEFINE_FRTYPE(vfne_b);
  DEFINE_FRTYPE(vfne_r_b);
  DEFINE_FRTYPE(vflt_b);
  DEFINE_FRTYPE(vflt_r_b);
  DEFINE_FRTYPE(vfge_b);
  DEFINE_FRTYPE(vfge_r_b);
  DEFINE_FRTYPE(vfle_b);
  DEFINE_FRTYPE(vfle_r_b);
  DEFINE_FRTYPE(vfgt_b);
  DEFINE_FRTYPE(vfgt_r_b);
  DEFINE_FR1TYPE(vfmv_x_b);
  DEFINE_FR1TYPE(vfmv_b_x);
  DEFINE_FR1TYPE(vfclass_b);
  DEFINE_FR1TYPE(vfcvt_x_b);
  DEFINE_FR1TYPE(vfcvt_xu_b);
  DEFINE_FR1TYPE(vfcvt_b_x);
  DEFINE_FR1TYPE(vfcvt_b_xu);
  DEFINE_FRTYPE(vfcpka_b_s);
  DEFINE_FRTYPE(vfcpkb_b_s);
  DEFINE_FRTYPE(vfcpkc_b_s);
  DEFINE_FRTYPE(vfcpkd_b_s);
  DEFINE_FRTYPE(vfcpka_b_d);
  DEFINE_FRTYPE(vfcpkb_b_d);
  DEFINE_FRTYPE(vfcpkc_b_d);
  DEFINE_FRTYPE(vfcpkd_b_d);
  DEFINE_FR1TYPE(vfcvt_s_b);
  DEFINE_FR1TYPE(vfcvtu_s_b);
  DEFINE_FR1TYPE(vfcvt_b_s);
  DEFINE_FR1TYPE(vfcvtu_b_s);
  DEFINE_FR1TYPE(vfcvt_h_b);
  DEFINE_FR1TYPE(vfcvtu_h_b);
  DEFINE_FR1TYPE(vfcvt_b_h);
  DEFINE_FR1TYPE(vfcvtu_b_h);
  DEFINE_FR1TYPE(vfcvt_ah_b);
  DEFINE_FR1TYPE(vfcvtu_ah_b);
  DEFINE_FR1TYPE(vfcvt_b_ah);
  DEFINE_FR1TYPE(vfcvtu_b_ah);
  DEFINE_FR1TYPE(vfcvt_b_b);
  DEFINE_FR1TYPE(vfcvt_ab_b);
  DEFINE_FR1TYPE(vfcvt_b_ab);
  DEFINE_FR1TYPE(vfcvtu_b_b);
  DEFINE_FR1TYPE(vfcvtu_ab_b);
  DEFINE_FR1TYPE(vfcvtu_b_ab);
  // vector alt-quarter
  DEFINE_FRTYPE(vfadd_ab);
  DEFINE_FRTYPE(vfadd_r_ab);
  DEFINE_FRTYPE(vfsub_ab);
  DEFINE_FRTYPE(vfsub_r_ab);
  DEFINE_FRTYPE(vfmul_ab);
  DEFINE_FRTYPE(vfmul_r_ab);
  DEFINE_FRTYPE(vfdiv_ab);
  DEFINE_FRTYPE(vfdiv_r_ab);
  DEFINE_FRTYPE(vfmin_ab);
  DEFINE_FRTYPE(vfmin_r_ab);
  DEFINE_FRTYPE(vfmax_ab);
  DEFINE_FRTYPE(vfmax_r_ab);
  DEFINE_FR1TYPE(vfsqrt_ab);
  DEFINE_FRTYPE(vfmac_ab);
  DEFINE_FRTYPE(vfmac_r_ab);
  DEFINE_FRTYPE(vfmre_ab);
  DEFINE_FRTYPE(vfmre_r_ab);
  DEFINE_FRTYPE(vfsgnj_ab);
  DEFINE_FRTYPE(vfsgnj_r_ab);
  DEFINE_FRTYPE(vfsgnjn_ab);
  DEFINE_FRTYPE(vfsgnjn_r_ab);
  DEFINE_FRTYPE(vfsgnjx_ab);
  DEFINE_FRTYPE(vfsgnjx_r_ab);
  DEFINE_FRTYPE(vfeq_ab);
  DEFINE_FRTYPE(vfeq_r_ab);
  DEFINE_FRTYPE(vfne_ab);
  DEFINE_FRTYPE(vfne_r_ab);
  DEFINE_FRTYPE(vflt_ab);
  DEFINE_FRTYPE(vflt_r_ab);
  DEFINE_FRTYPE(vfge_ab);
  DEFINE_FRTYPE(vfge_r_ab);
  DEFINE_FRTYPE(vfle_ab);
  DEFINE_FRTYPE(vfle_r_ab);
  DEFINE_FRTYPE(vfgt_ab);
  DEFINE_FRTYPE(vfgt_r_ab);
  DEFINE_FR1TYPE(vfmv_x_ab);
  DEFINE_FR1TYPE(vfmv_ab_x);
  DEFINE_FR1TYPE(vfclass_ab);
  DEFINE_FR1TYPE(vfcvt_x_ab);
  DEFINE_FR1TYPE(vfcvt_xu_ab);
  DEFINE_FR1TYPE(vfcvt_ab_x);
  DEFINE_FR1TYPE(vfcvt_ab_xu);
  DEFINE_FRTYPE(vfcpka_ab_s);
  DEFINE_FRTYPE(vfcpkb_ab_s);
  DEFINE_FRTYPE(vfcpkc_ab_s);
  DEFINE_FRTYPE(vfcpkd_ab_s);
  DEFINE_FRTYPE(vfcpka_ab_d);
  DEFINE_FRTYPE(vfcpkb_ab_d);
  DEFINE_FRTYPE(vfcpkc_ab_d);
  DEFINE_FRTYPE(vfcpkd_ab_d);
  DEFINE_FR1TYPE(vfcvt_s_ab);
  DEFINE_FR1TYPE(vfcvtu_s_ab);
  DEFINE_FR1TYPE(vfcvt_ab_s);
  DEFINE_FR1TYPE(vfcvtu_ab_s);
  DEFINE_FR1TYPE(vfcvt_h_ab);
  DEFINE_FR1TYPE(vfcvtu_h_ab);
  DEFINE_FR1TYPE(vfcvt_ab_h);
  DEFINE_FR1TYPE(vfcvtu_ab_h);
  DEFINE_FR1TYPE(vfcvt_ah_ab);
  DEFINE_FR1TYPE(vfcvtu_ah_ab);
  DEFINE_FR1TYPE(vfcvt_ab_ah);
  DEFINE_FR1TYPE(vfcvtu_ab_ah);
  // auxiliary
  DEFINE_FRTYPE(fmulex_s_h);
  DEFINE_FRTYPE(fmacex_s_h);
  DEFINE_FRTYPE(fmulex_s_ah);
  DEFINE_FRTYPE(fmacex_s_ah);
  DEFINE_FRTYPE(fmulex_s_b);
  DEFINE_FRTYPE(fmacex_s_b);
  DEFINE_FRTYPE(fmulex_s_ab);
  DEFINE_FRTYPE(fmacex_s_ab);
  // aux vector
  DEFINE_FR1TYPE(vfsum_s);
  DEFINE_FR1TYPE(vfnsum_s);
  DEFINE_FR1TYPE(vfsum_h);
  DEFINE_FR1TYPE(vfnsum_h);
  DEFINE_FR1TYPE(vfsum_ah);
  DEFINE_FR1TYPE(vfnsum_ah);
  DEFINE_FR1TYPE(vfsum_b);
  DEFINE_FR1TYPE(vfnsum_b);
  DEFINE_FR1TYPE(vfsum_ab);
  DEFINE_FR1TYPE(vfnsum_ab);
  // expanding vector
  DEFINE_FR1TYPE(vfsumex_s_h);
  DEFINE_FR1TYPE(vfnsumex_s_h);
  DEFINE_FRTYPE(vfdotpex_s_h);
  DEFINE_FRTYPE(vfdotpex_s_r_h);
  DEFINE_FRTYPE(vfndotpex_s_h);
  DEFINE_FRTYPE(vfndotpex_s_r_h);
  DEFINE_FR1TYPE(vfsumex_s_ah);
  DEFINE_FR1TYPE(vfnsumex_s_ah);
  DEFINE_FRTYPE(vfdotpex_s_ah);
  DEFINE_FRTYPE(vfdotpex_s_r_ah);
  DEFINE_FRTYPE(vfndotpex_s_ah);
  DEFINE_FRTYPE(vfndotpex_s_r_ah);
  DEFINE_FR1TYPE(vfsumex_h_b);
  DEFINE_FR1TYPE(vfnsumex_h_b);
  DEFINE_FRTYPE(vfdotpex_h_b);
  DEFINE_FRTYPE(vfdotpex_h_r_b);
  DEFINE_FRTYPE(vfndotpex_h_b);
  DEFINE_FRTYPE(vfndotpex_h_r_b);
  DEFINE_FR1TYPE(vfsumex_ah_b);
  DEFINE_FR1TYPE(vfnsumex_ah_b);
  DEFINE_FRTYPE(vfdotpex_ah_b);
  DEFINE_FRTYPE(vfdotpex_ah_r_b);
  DEFINE_FRTYPE(vfndotpex_ah_b);
  DEFINE_FRTYPE(vfndotpex_ah_r_b);
  DEFINE_FR1TYPE(vfsumex_h_ab);
  DEFINE_FR1TYPE(vfnsumex_h_ab);
  DEFINE_FRTYPE(vfdotpex_h_ab);
  DEFINE_FRTYPE(vfdotpex_h_r_ab);
  DEFINE_FRTYPE(vfndotpex_h_ab);
  DEFINE_FRTYPE(vfndotpex_h_r_ab);
  DEFINE_FR1TYPE(vfsumex_ah_ab);
  DEFINE_FR1TYPE(vfnsumex_ah_ab);
  DEFINE_FRTYPE(vfdotpex_ah_ab);
  DEFINE_FRTYPE(vfdotpex_ah_r_ab);
  DEFINE_FRTYPE(vfndotpex_ah_ab);
  DEFINE_FRTYPE(vfndotpex_ah_r_ab);

// provide a default disassembly for all instructions as a fallback
#define DECLARE_INSN(code, match, mask)                                        \
  add_insn(new disasm_insn_t(#code " (args unknown)", match, mask, {}));
#include "encoding.h"
#undef DECLARE_INSN
}

const disasm_insn_t *disassembler_t::lookup(insn_t insn) const {
  size_t idx = insn.bits() % HASH_SIZE;
  for (size_t j = 0; j < chain[idx].size(); j++)
    if (*chain[idx][j] == insn)
      return chain[idx][j];

  idx = HASH_SIZE;
  for (size_t j = 0; j < chain[idx].size(); j++)
    if (*chain[idx][j] == insn)
      return chain[idx][j];

  return NULL;
}

void disassembler_t::add_insn(disasm_insn_t *insn) {
  size_t idx = HASH_SIZE;
  if (insn->get_mask() % HASH_SIZE == HASH_SIZE - 1)
    idx = insn->get_match() % HASH_SIZE;
  chain[idx].push_back(insn);
}

disassembler_t::~disassembler_t() {
  for (size_t i = 0; i < HASH_SIZE + 1; i++)
    for (size_t j = 0; j < chain[i].size(); j++)
      delete chain[i][j];
}
