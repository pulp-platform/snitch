// See LICENSE for license details.

#ifndef RISCV_CSR_ENCODING_H
#define RISCV_CSR_ENCODING_H

#define MSTATUS_UIE         0x00000001
#define MSTATUS_SIE         0x00000002
#define MSTATUS_HIE         0x00000004
#define MSTATUS_MIE         0x00000008
#define MSTATUS_UPIE        0x00000010
#define MSTATUS_SPIE        0x00000020
#define MSTATUS_HPIE        0x00000040
#define MSTATUS_MPIE        0x00000080
#define MSTATUS_SPP         0x00000100
#define MSTATUS_HPP         0x00000600
#define MSTATUS_MPP         0x00001800
#define MSTATUS_FS          0x00006000
#define MSTATUS_XS          0x00018000
#define MSTATUS_MPRV        0x00020000
#define MSTATUS_SUM         0x00040000
#define MSTATUS_MXR         0x00080000
#define MSTATUS_TVM         0x00100000
#define MSTATUS_TW          0x00200000
#define MSTATUS_TSR         0x00400000
#define MSTATUS32_SD        0x80000000
#define MSTATUS_UXL         0x0000000300000000
#define MSTATUS_SXL         0x0000000C00000000
#define MSTATUS64_SD        0x8000000000000000

#define SSTATUS_UIE         0x00000001
#define SSTATUS_SIE         0x00000002
#define SSTATUS_UPIE        0x00000010
#define SSTATUS_SPIE        0x00000020
#define SSTATUS_SPP         0x00000100
#define SSTATUS_FS          0x00006000
#define SSTATUS_XS          0x00018000
#define SSTATUS_SUM         0x00040000
#define SSTATUS_MXR         0x00080000
#define SSTATUS32_SD        0x80000000
#define SSTATUS_UXL         0x0000000300000000
#define SSTATUS64_SD        0x8000000000000000

#define DCSR_XDEBUGVER      (3U<<30)
#define DCSR_NDRESET        (1<<29)
#define DCSR_FULLRESET      (1<<28)
#define DCSR_EBREAKM        (1<<15)
#define DCSR_EBREAKH        (1<<14)
#define DCSR_EBREAKS        (1<<13)
#define DCSR_EBREAKU        (1<<12)
#define DCSR_STOPCYCLE      (1<<10)
#define DCSR_STOPTIME       (1<<9)
#define DCSR_CAUSE          (7<<6)
#define DCSR_DEBUGINT       (1<<5)
#define DCSR_HALT           (1<<3)
#define DCSR_STEP           (1<<2)
#define DCSR_PRV            (3<<0)

#define DCSR_CAUSE_NONE     0
#define DCSR_CAUSE_SWBP     1
#define DCSR_CAUSE_HWBP     2
#define DCSR_CAUSE_DEBUGINT 3
#define DCSR_CAUSE_STEP     4
#define DCSR_CAUSE_HALT     5

#define MCONTROL_TYPE(xlen)    (0xfULL<<((xlen)-4))
#define MCONTROL_DMODE(xlen)   (1ULL<<((xlen)-5))
#define MCONTROL_MASKMAX(xlen) (0x3fULL<<((xlen)-11))

#define MCONTROL_SELECT     (1<<19)
#define MCONTROL_TIMING     (1<<18)
#define MCONTROL_ACTION     (0x3f<<12)
#define MCONTROL_CHAIN      (1<<11)
#define MCONTROL_MATCH      (0xf<<7)
#define MCONTROL_M          (1<<6)
#define MCONTROL_H          (1<<5)
#define MCONTROL_S          (1<<4)
#define MCONTROL_U          (1<<3)
#define MCONTROL_EXECUTE    (1<<2)
#define MCONTROL_STORE      (1<<1)
#define MCONTROL_LOAD       (1<<0)

#define MCONTROL_TYPE_NONE      0
#define MCONTROL_TYPE_MATCH     2

#define MCONTROL_ACTION_DEBUG_EXCEPTION   0
#define MCONTROL_ACTION_DEBUG_MODE        1
#define MCONTROL_ACTION_TRACE_START       2
#define MCONTROL_ACTION_TRACE_STOP        3
#define MCONTROL_ACTION_TRACE_EMIT        4

#define MCONTROL_MATCH_EQUAL     0
#define MCONTROL_MATCH_NAPOT     1
#define MCONTROL_MATCH_GE        2
#define MCONTROL_MATCH_LT        3
#define MCONTROL_MATCH_MASK_LOW  4
#define MCONTROL_MATCH_MASK_HIGH 5

#define MIP_SSIP            (1 << IRQ_S_SOFT)
#define MIP_HSIP            (1 << IRQ_H_SOFT)
#define MIP_MSIP            (1 << IRQ_M_SOFT)
#define MIP_STIP            (1 << IRQ_S_TIMER)
#define MIP_HTIP            (1 << IRQ_H_TIMER)
#define MIP_MTIP            (1 << IRQ_M_TIMER)
#define MIP_SEIP            (1 << IRQ_S_EXT)
#define MIP_HEIP            (1 << IRQ_H_EXT)
#define MIP_MEIP            (1 << IRQ_M_EXT)

#define SIP_SSIP MIP_SSIP
#define SIP_STIP MIP_STIP

#define PRV_U 0
#define PRV_S 1
#define PRV_H 2
#define PRV_M 3

#define SATP32_MODE 0x80000000
#define SATP32_ASID 0x7FC00000
#define SATP32_PPN  0x003FFFFF
#define SATP64_MODE 0xF000000000000000
#define SATP64_ASID 0x0FFFF00000000000
#define SATP64_PPN  0x00000FFFFFFFFFFF

#define SATP_MODE_OFF  0
#define SATP_MODE_SV32 1
#define SATP_MODE_SV39 8
#define SATP_MODE_SV48 9
#define SATP_MODE_SV57 10
#define SATP_MODE_SV64 11

#define PMP_R     0x01
#define PMP_W     0x02
#define PMP_X     0x04
#define PMP_A     0x18
#define PMP_L     0x80
#define PMP_SHIFT 2

#define PMP_TOR   0x08
#define PMP_NA4   0x10
#define PMP_NAPOT 0x18

#define IRQ_S_SOFT   1
#define IRQ_H_SOFT   2
#define IRQ_M_SOFT   3
#define IRQ_S_TIMER  5
#define IRQ_H_TIMER  6
#define IRQ_M_TIMER  7
#define IRQ_S_EXT    9
#define IRQ_H_EXT    10
#define IRQ_M_EXT    11
#define IRQ_COP      12
#define IRQ_HOST     13

#define DEFAULT_RSTVEC     0x00001000
#define CLINT_BASE         0x02000000
#define CLINT_SIZE         0x000c0000
#define EXT_IO_BASE        0x40000000
#define DRAM_BASE          0x80000000

// page table entry (PTE) fields
#define PTE_V     0x001 // Valid
#define PTE_R     0x002 // Read
#define PTE_W     0x004 // Write
#define PTE_X     0x008 // Execute
#define PTE_U     0x010 // User
#define PTE_G     0x020 // Global
#define PTE_A     0x040 // Accessed
#define PTE_D     0x080 // Dirty
#define PTE_SOFT  0x300 // Reserved for Software

#define PTE_PPN_SHIFT 10

#define PTE_TABLE(PTE) (((PTE) & (PTE_V | PTE_R | PTE_W | PTE_X)) == PTE_V)

#ifdef __riscv

#if __riscv_xlen == 64
# define MSTATUS_SD MSTATUS64_SD
# define SSTATUS_SD SSTATUS64_SD
# define RISCV_PGLEVEL_BITS 9
# define SATP_MODE SATP64_MODE
#else
# define MSTATUS_SD MSTATUS32_SD
# define SSTATUS_SD SSTATUS32_SD
# define RISCV_PGLEVEL_BITS 10
# define SATP_MODE SATP32_MODE
#endif
#define RISCV_PGSHIFT 12
#define RISCV_PGSIZE (1 << RISCV_PGSHIFT)

#ifndef __ASSEMBLER__

#ifdef __GNUC__

#define read_csr(reg) ({ unsigned long __tmp; \
  asm volatile ("csrr %0, " #reg : "=r"(__tmp)); \
  __tmp; })

#define write_csr(reg, val) ({ \
  asm volatile ("csrw " #reg ", %0" :: "rK"(val)); })

#define swap_csr(reg, val) ({ unsigned long __tmp; \
  asm volatile ("csrrw %0, " #reg ", %1" : "=r"(__tmp) : "rK"(val)); \
  __tmp; })

#define set_csr(reg, bit) ({ unsigned long __tmp; \
  asm volatile ("csrrs %0, " #reg ", %1" : "=r"(__tmp) : "rK"(bit)); \
  __tmp; })

#define clear_csr(reg, bit) ({ unsigned long __tmp; \
  asm volatile ("csrrc %0, " #reg ", %1" : "=r"(__tmp) : "rK"(bit)); \
  __tmp; })

#define rdtime() read_csr(time)
#define rdcycle() read_csr(cycle)
#define rdinstret() read_csr(instret)

#endif

#endif

#endif

#endif
/* Automatically generated by parse-opcodes.  */
#ifndef RISCV_ENCODING_H
#define RISCV_ENCODING_H
#define MATCH_BEQ 0x63
#define MASK_BEQ  0x707f
#define MATCH_BNE 0x1063
#define MASK_BNE  0x707f
#define MATCH_BLT 0x4063
#define MASK_BLT  0x707f
#define MATCH_BGE 0x5063
#define MASK_BGE  0x707f
#define MATCH_BLTU 0x6063
#define MASK_BLTU  0x707f
#define MATCH_BGEU 0x7063
#define MASK_BGEU  0x707f
#define MATCH_JALR 0x67
#define MASK_JALR  0x707f
#define MATCH_JAL 0x6f
#define MASK_JAL  0x7f
#define MATCH_LUI 0x37
#define MASK_LUI  0x7f
#define MATCH_AUIPC 0x17
#define MASK_AUIPC  0x7f
#define MATCH_ADDI 0x13
#define MASK_ADDI  0x707f
#define MATCH_SLLI 0x1013
#define MASK_SLLI  0xfc00707f
#define MATCH_SLTI 0x2013
#define MASK_SLTI  0x707f
#define MATCH_SLTIU 0x3013
#define MASK_SLTIU  0x707f
#define MATCH_XORI 0x4013
#define MASK_XORI  0x707f
#define MATCH_SRLI 0x5013
#define MASK_SRLI  0xfc00707f
#define MATCH_SRAI 0x40005013
#define MASK_SRAI  0xfc00707f
#define MATCH_ORI 0x6013
#define MASK_ORI  0x707f
#define MATCH_ANDI 0x7013
#define MASK_ANDI  0x707f
#define MATCH_ADD 0x33
#define MASK_ADD  0xfe00707f
#define MATCH_SUB 0x40000033
#define MASK_SUB  0xfe00707f
#define MATCH_SLL 0x1033
#define MASK_SLL  0xfe00707f
#define MATCH_SLT 0x2033
#define MASK_SLT  0xfe00707f
#define MATCH_SLTU 0x3033
#define MASK_SLTU  0xfe00707f
#define MATCH_XOR 0x4033
#define MASK_XOR  0xfe00707f
#define MATCH_SRL 0x5033
#define MASK_SRL  0xfe00707f
#define MATCH_SRA 0x40005033
#define MASK_SRA  0xfe00707f
#define MATCH_OR 0x6033
#define MASK_OR  0xfe00707f
#define MATCH_AND 0x7033
#define MASK_AND  0xfe00707f
#define MATCH_ADDIW 0x1b
#define MASK_ADDIW  0x707f
#define MATCH_SLLIW 0x101b
#define MASK_SLLIW  0xfe00707f
#define MATCH_SRLIW 0x501b
#define MASK_SRLIW  0xfe00707f
#define MATCH_SRAIW 0x4000501b
#define MASK_SRAIW  0xfe00707f
#define MATCH_ADDW 0x3b
#define MASK_ADDW  0xfe00707f
#define MATCH_SUBW 0x4000003b
#define MASK_SUBW  0xfe00707f
#define MATCH_SLLW 0x103b
#define MASK_SLLW  0xfe00707f
#define MATCH_SRLW 0x503b
#define MASK_SRLW  0xfe00707f
#define MATCH_SRAW 0x4000503b
#define MASK_SRAW  0xfe00707f
#define MATCH_LB 0x3
#define MASK_LB  0x707f
#define MATCH_LH 0x1003
#define MASK_LH  0x707f
#define MATCH_LW 0x2003
#define MASK_LW  0x707f
#define MATCH_LD 0x3003
#define MASK_LD  0x707f
#define MATCH_LBU 0x4003
#define MASK_LBU  0x707f
#define MATCH_LHU 0x5003
#define MASK_LHU  0x707f
#define MATCH_LWU 0x6003
#define MASK_LWU  0x707f
#define MATCH_SB 0x23
#define MASK_SB  0x707f
#define MATCH_SH 0x1023
#define MASK_SH  0x707f
#define MATCH_SW 0x2023
#define MASK_SW  0x707f
#define MATCH_SD 0x3023
#define MASK_SD  0x707f
#define MATCH_FENCE 0xf
#define MASK_FENCE  0x707f
#define MATCH_FENCE_I 0x100f
#define MASK_FENCE_I  0x707f
#define MATCH_MUL 0x2000033
#define MASK_MUL  0xfe00707f
#define MATCH_MULH 0x2001033
#define MASK_MULH  0xfe00707f
#define MATCH_MULHSU 0x2002033
#define MASK_MULHSU  0xfe00707f
#define MATCH_MULHU 0x2003033
#define MASK_MULHU  0xfe00707f
#define MATCH_DIV 0x2004033
#define MASK_DIV  0xfe00707f
#define MATCH_DIVU 0x2005033
#define MASK_DIVU  0xfe00707f
#define MATCH_REM 0x2006033
#define MASK_REM  0xfe00707f
#define MATCH_REMU 0x2007033
#define MASK_REMU  0xfe00707f
#define MATCH_MULW 0x200003b
#define MASK_MULW  0xfe00707f
#define MATCH_DIVW 0x200403b
#define MASK_DIVW  0xfe00707f
#define MATCH_DIVUW 0x200503b
#define MASK_DIVUW  0xfe00707f
#define MATCH_REMW 0x200603b
#define MASK_REMW  0xfe00707f
#define MATCH_REMUW 0x200703b
#define MASK_REMUW  0xfe00707f
#define MATCH_AMOADD_W 0x202f
#define MASK_AMOADD_W  0xf800707f
#define MATCH_AMOXOR_W 0x2000202f
#define MASK_AMOXOR_W  0xf800707f
#define MATCH_AMOOR_W 0x4000202f
#define MASK_AMOOR_W  0xf800707f
#define MATCH_AMOAND_W 0x6000202f
#define MASK_AMOAND_W  0xf800707f
#define MATCH_AMOMIN_W 0x8000202f
#define MASK_AMOMIN_W  0xf800707f
#define MATCH_AMOMAX_W 0xa000202f
#define MASK_AMOMAX_W  0xf800707f
#define MATCH_AMOMINU_W 0xc000202f
#define MASK_AMOMINU_W  0xf800707f
#define MATCH_AMOMAXU_W 0xe000202f
#define MASK_AMOMAXU_W  0xf800707f
#define MATCH_AMOSWAP_W 0x800202f
#define MASK_AMOSWAP_W  0xf800707f
#define MATCH_LR_W 0x1000202f
#define MASK_LR_W  0xf9f0707f
#define MATCH_SC_W 0x1800202f
#define MASK_SC_W  0xf800707f
#define MATCH_AMOADD_D 0x302f
#define MASK_AMOADD_D  0xf800707f
#define MATCH_AMOXOR_D 0x2000302f
#define MASK_AMOXOR_D  0xf800707f
#define MATCH_AMOOR_D 0x4000302f
#define MASK_AMOOR_D  0xf800707f
#define MATCH_AMOAND_D 0x6000302f
#define MASK_AMOAND_D  0xf800707f
#define MATCH_AMOMIN_D 0x8000302f
#define MASK_AMOMIN_D  0xf800707f
#define MATCH_AMOMAX_D 0xa000302f
#define MASK_AMOMAX_D  0xf800707f
#define MATCH_AMOMINU_D 0xc000302f
#define MASK_AMOMINU_D  0xf800707f
#define MATCH_AMOMAXU_D 0xe000302f
#define MASK_AMOMAXU_D  0xf800707f
#define MATCH_AMOSWAP_D 0x800302f
#define MASK_AMOSWAP_D  0xf800707f
#define MATCH_LR_D 0x1000302f
#define MASK_LR_D  0xf9f0707f
#define MATCH_SC_D 0x1800302f
#define MASK_SC_D  0xf800707f
#define MATCH_ECALL 0x73
#define MASK_ECALL  0xffffffff
#define MATCH_EBREAK 0x100073
#define MASK_EBREAK  0xffffffff
#define MATCH_URET 0x200073
#define MASK_URET  0xffffffff
#define MATCH_SRET 0x10200073
#define MASK_SRET  0xffffffff
#define MATCH_MRET 0x30200073
#define MASK_MRET  0xffffffff
#define MATCH_DRET 0x7b200073
#define MASK_DRET  0xffffffff
#define MATCH_SFENCE_VMA 0x12000073
#define MASK_SFENCE_VMA  0xfe007fff
#define MATCH_WFI 0x10500073
#define MASK_WFI  0xffffffff
#define MATCH_CSRRW 0x1073
#define MASK_CSRRW  0x707f
#define MATCH_CSRRS 0x2073
#define MASK_CSRRS  0x707f
#define MATCH_CSRRC 0x3073
#define MASK_CSRRC  0x707f
#define MATCH_CSRRWI 0x5073
#define MASK_CSRRWI  0x707f
#define MATCH_CSRRSI 0x6073
#define MASK_CSRRSI  0x707f
#define MATCH_CSRRCI 0x7073
#define MASK_CSRRCI  0x707f
#define MATCH_FADD_S 0x53
#define MASK_FADD_S  0xfe00007f
#define MATCH_FSUB_S 0x8000053
#define MASK_FSUB_S  0xfe00007f
#define MATCH_FMUL_S 0x10000053
#define MASK_FMUL_S  0xfe00007f
#define MATCH_FDIV_S 0x18000053
#define MASK_FDIV_S  0xfe00007f
#define MATCH_FSGNJ_S 0x20000053
#define MASK_FSGNJ_S  0xfe00707f
#define MATCH_FSGNJN_S 0x20001053
#define MASK_FSGNJN_S  0xfe00707f
#define MATCH_FSGNJX_S 0x20002053
#define MASK_FSGNJX_S  0xfe00707f
#define MATCH_FMIN_S 0x28000053
#define MASK_FMIN_S  0xfe00707f
#define MATCH_FMAX_S 0x28001053
#define MASK_FMAX_S  0xfe00707f
#define MATCH_FSQRT_S 0x58000053
#define MASK_FSQRT_S  0xfff0007f
#define MATCH_FADD_D 0x2000053
#define MASK_FADD_D  0xfe00007f
#define MATCH_FSUB_D 0xa000053
#define MASK_FSUB_D  0xfe00007f
#define MATCH_FMUL_D 0x12000053
#define MASK_FMUL_D  0xfe00007f
#define MATCH_FDIV_D 0x1a000053
#define MASK_FDIV_D  0xfe00007f
#define MATCH_FSGNJ_D 0x22000053
#define MASK_FSGNJ_D  0xfe00707f
#define MATCH_FSGNJN_D 0x22001053
#define MASK_FSGNJN_D  0xfe00707f
#define MATCH_FSGNJX_D 0x22002053
#define MASK_FSGNJX_D  0xfe00707f
#define MATCH_FMIN_D 0x2a000053
#define MASK_FMIN_D  0xfe00707f
#define MATCH_FMAX_D 0x2a001053
#define MASK_FMAX_D  0xfe00707f
#define MATCH_FCVT_S_D 0x40100053
#define MASK_FCVT_S_D  0xfff0007f
#define MATCH_FCVT_D_S 0x42000053
#define MASK_FCVT_D_S  0xfff0007f
#define MATCH_FSQRT_D 0x5a000053
#define MASK_FSQRT_D  0xfff0007f
#define MATCH_FADD_Q 0x6000053
#define MASK_FADD_Q  0xfe00007f
#define MATCH_FSUB_Q 0xe000053
#define MASK_FSUB_Q  0xfe00007f
#define MATCH_FMUL_Q 0x16000053
#define MASK_FMUL_Q  0xfe00007f
#define MATCH_FDIV_Q 0x1e000053
#define MASK_FDIV_Q  0xfe00007f
#define MATCH_FSGNJ_Q 0x26000053
#define MASK_FSGNJ_Q  0xfe00707f
#define MATCH_FSGNJN_Q 0x26001053
#define MASK_FSGNJN_Q  0xfe00707f
#define MATCH_FSGNJX_Q 0x26002053
#define MASK_FSGNJX_Q  0xfe00707f
#define MATCH_FMIN_Q 0x2e000053
#define MASK_FMIN_Q  0xfe00707f
#define MATCH_FMAX_Q 0x2e001053
#define MASK_FMAX_Q  0xfe00707f
#define MATCH_FCVT_S_Q 0x40300053
#define MASK_FCVT_S_Q  0xfff0007f
#define MATCH_FCVT_Q_S 0x46000053
#define MASK_FCVT_Q_S  0xfff0007f
#define MATCH_FCVT_D_Q 0x42300053
#define MASK_FCVT_D_Q  0xfff0007f
#define MATCH_FCVT_Q_D 0x46100053
#define MASK_FCVT_Q_D  0xfff0007f
#define MATCH_FSQRT_Q 0x5e000053
#define MASK_FSQRT_Q  0xfff0007f
#define MATCH_FLE_S 0xa0000053
#define MASK_FLE_S  0xfe00707f
#define MATCH_FLT_S 0xa0001053
#define MASK_FLT_S  0xfe00707f
#define MATCH_FEQ_S 0xa0002053
#define MASK_FEQ_S  0xfe00707f
#define MATCH_FLE_D 0xa2000053
#define MASK_FLE_D  0xfe00707f
#define MATCH_FLT_D 0xa2001053
#define MASK_FLT_D  0xfe00707f
#define MATCH_FEQ_D 0xa2002053
#define MASK_FEQ_D  0xfe00707f
#define MATCH_FLE_Q 0xa6000053
#define MASK_FLE_Q  0xfe00707f
#define MATCH_FLT_Q 0xa6001053
#define MASK_FLT_Q  0xfe00707f
#define MATCH_FEQ_Q 0xa6002053
#define MASK_FEQ_Q  0xfe00707f
#define MATCH_FCVT_W_S 0xc0000053
#define MASK_FCVT_W_S  0xfff0007f
#define MATCH_FCVT_WU_S 0xc0100053
#define MASK_FCVT_WU_S  0xfff0007f
#define MATCH_FCVT_L_S 0xc0200053
#define MASK_FCVT_L_S  0xfff0007f
#define MATCH_FCVT_LU_S 0xc0300053
#define MASK_FCVT_LU_S  0xfff0007f
#define MATCH_FMV_X_W 0xe0000053
#define MASK_FMV_X_W  0xfff0707f
#define MATCH_FCLASS_S 0xe0001053
#define MASK_FCLASS_S  0xfff0707f
#define MATCH_FCVT_W_D 0xc2000053
#define MASK_FCVT_W_D  0xfff0007f
#define MATCH_FCVT_WU_D 0xc2100053
#define MASK_FCVT_WU_D  0xfff0007f
#define MATCH_FCVT_L_D 0xc2200053
#define MASK_FCVT_L_D  0xfff0007f
#define MATCH_FCVT_LU_D 0xc2300053
#define MASK_FCVT_LU_D  0xfff0007f
#define MATCH_FMV_X_D 0xe2000053
#define MASK_FMV_X_D  0xfff0707f
#define MATCH_FCLASS_D 0xe2001053
#define MASK_FCLASS_D  0xfff0707f
#define MATCH_FCVT_W_Q 0xc6000053
#define MASK_FCVT_W_Q  0xfff0007f
#define MATCH_FCVT_WU_Q 0xc6100053
#define MASK_FCVT_WU_Q  0xfff0007f
#define MATCH_FCVT_L_Q 0xc6200053
#define MASK_FCVT_L_Q  0xfff0007f
#define MATCH_FCVT_LU_Q 0xc6300053
#define MASK_FCVT_LU_Q  0xfff0007f
#define MATCH_FMV_X_Q 0xe6000053
#define MASK_FMV_X_Q  0xfff0707f
#define MATCH_FCLASS_Q 0xe6001053
#define MASK_FCLASS_Q  0xfff0707f
#define MATCH_FCVT_S_W 0xd0000053
#define MASK_FCVT_S_W  0xfff0007f
#define MATCH_FCVT_S_WU 0xd0100053
#define MASK_FCVT_S_WU  0xfff0007f
#define MATCH_FCVT_S_L 0xd0200053
#define MASK_FCVT_S_L  0xfff0007f
#define MATCH_FCVT_S_LU 0xd0300053
#define MASK_FCVT_S_LU  0xfff0007f
#define MATCH_FMV_W_X 0xf0000053
#define MASK_FMV_W_X  0xfff0707f
#define MATCH_FCVT_D_W 0xd2000053
#define MASK_FCVT_D_W  0xfff0007f
#define MATCH_FCVT_D_WU 0xd2100053
#define MASK_FCVT_D_WU  0xfff0007f
#define MATCH_FCVT_D_L 0xd2200053
#define MASK_FCVT_D_L  0xfff0007f
#define MATCH_FCVT_D_LU 0xd2300053
#define MASK_FCVT_D_LU  0xfff0007f
#define MATCH_FMV_D_X 0xf2000053
#define MASK_FMV_D_X  0xfff0707f
#define MATCH_FCVT_Q_W 0xd6000053
#define MASK_FCVT_Q_W  0xfff0007f
#define MATCH_FCVT_Q_WU 0xd6100053
#define MASK_FCVT_Q_WU  0xfff0007f
#define MATCH_FCVT_Q_L 0xd6200053
#define MASK_FCVT_Q_L  0xfff0007f
#define MATCH_FCVT_Q_LU 0xd6300053
#define MASK_FCVT_Q_LU  0xfff0007f
#define MATCH_FMV_Q_X 0xf6000053
#define MASK_FMV_Q_X  0xfff0707f
#define MATCH_FLW 0x2007
#define MASK_FLW  0x707f
#define MATCH_FLD 0x3007
#define MASK_FLD  0x707f
#define MATCH_FLQ 0x4007
#define MASK_FLQ  0x707f
#define MATCH_FSW 0x2027
#define MASK_FSW  0x707f
#define MATCH_FSD 0x3027
#define MASK_FSD  0x707f
#define MATCH_FSQ 0x4027
#define MASK_FSQ  0x707f
#define MATCH_FMADD_S 0x43
#define MASK_FMADD_S  0x600007f
#define MATCH_FMSUB_S 0x47
#define MASK_FMSUB_S  0x600007f
#define MATCH_FNMSUB_S 0x4b
#define MASK_FNMSUB_S  0x600007f
#define MATCH_FNMADD_S 0x4f
#define MASK_FNMADD_S  0x600007f
#define MATCH_FMADD_D 0x2000043
#define MASK_FMADD_D  0x600007f
#define MATCH_FMSUB_D 0x2000047
#define MASK_FMSUB_D  0x600007f
#define MATCH_FNMSUB_D 0x200004b
#define MASK_FNMSUB_D  0x600007f
#define MATCH_FNMADD_D 0x200004f
#define MASK_FNMADD_D  0x600007f
#define MATCH_FMADD_Q 0x6000043
#define MASK_FMADD_Q  0x600007f
#define MATCH_FMSUB_Q 0x6000047
#define MASK_FMSUB_Q  0x600007f
#define MATCH_FNMSUB_Q 0x600004b
#define MASK_FNMSUB_Q  0x600007f
#define MATCH_FNMADD_Q 0x600004f
#define MASK_FNMADD_Q  0x600007f
#define MATCH_C_NOP 0x1
#define MASK_C_NOP  0xffff
#define MATCH_C_ADDI16SP 0x6101
#define MASK_C_ADDI16SP  0xef83
#define MATCH_C_JR 0x8002
#define MASK_C_JR  0xf07f
#define MATCH_C_JALR 0x9002
#define MASK_C_JALR  0xf07f
#define MATCH_C_EBREAK 0x9002
#define MASK_C_EBREAK  0xffff
#define MATCH_C_LD 0x6000
#define MASK_C_LD  0xe003
#define MATCH_C_SD 0xe000
#define MASK_C_SD  0xe003
#define MATCH_C_ADDIW 0x2001
#define MASK_C_ADDIW  0xe003
#define MATCH_C_LDSP 0x6002
#define MASK_C_LDSP  0xe003
#define MATCH_C_SDSP 0xe002
#define MASK_C_SDSP  0xe003
#define MATCH_C_ADDI4SPN 0x0
#define MASK_C_ADDI4SPN  0xe003
#define MATCH_C_FLD 0x2000
#define MASK_C_FLD  0xe003
#define MATCH_C_LW 0x4000
#define MASK_C_LW  0xe003
#define MATCH_C_FLW 0x6000
#define MASK_C_FLW  0xe003
#define MATCH_C_FSD 0xa000
#define MASK_C_FSD  0xe003
#define MATCH_C_SW 0xc000
#define MASK_C_SW  0xe003
#define MATCH_C_FSW 0xe000
#define MASK_C_FSW  0xe003
#define MATCH_C_ADDI 0x1
#define MASK_C_ADDI  0xe003
#define MATCH_C_JAL 0x2001
#define MASK_C_JAL  0xe003
#define MATCH_C_LI 0x4001
#define MASK_C_LI  0xe003
#define MATCH_C_LUI 0x6001
#define MASK_C_LUI  0xe003
#define MATCH_C_SRLI 0x8001
#define MASK_C_SRLI  0xec03
#define MATCH_C_SRAI 0x8401
#define MASK_C_SRAI  0xec03
#define MATCH_C_ANDI 0x8801
#define MASK_C_ANDI  0xec03
#define MATCH_C_SUB 0x8c01
#define MASK_C_SUB  0xfc63
#define MATCH_C_XOR 0x8c21
#define MASK_C_XOR  0xfc63
#define MATCH_C_OR 0x8c41
#define MASK_C_OR  0xfc63
#define MATCH_C_AND 0x8c61
#define MASK_C_AND  0xfc63
#define MATCH_C_SUBW 0x9c01
#define MASK_C_SUBW  0xfc63
#define MATCH_C_ADDW 0x9c21
#define MASK_C_ADDW  0xfc63
#define MATCH_C_J 0xa001
#define MASK_C_J  0xe003
#define MATCH_C_BEQZ 0xc001
#define MASK_C_BEQZ  0xe003
#define MATCH_C_BNEZ 0xe001
#define MASK_C_BNEZ  0xe003
#define MATCH_C_SLLI 0x2
#define MASK_C_SLLI  0xe003
#define MATCH_C_FLDSP 0x2002
#define MASK_C_FLDSP  0xe003
#define MATCH_C_LWSP 0x4002
#define MASK_C_LWSP  0xe003
#define MATCH_C_FLWSP 0x6002
#define MASK_C_FLWSP  0xe003
#define MATCH_C_MV 0x8002
#define MASK_C_MV  0xf003
#define MATCH_C_ADD 0x9002
#define MASK_C_ADD  0xf003
#define MATCH_C_FSDSP 0xa002
#define MASK_C_FSDSP  0xe003
#define MATCH_C_SWSP 0xc002
#define MASK_C_SWSP  0xe003
#define MATCH_C_FSWSP 0xe002
#define MASK_C_FSWSP  0xe003
#define MATCH_FREP_O 0x8b
#define MASK_FREP_O  0xff
#define MATCH_FREP_I 0xb
#define MASK_FREP_I  0xff
#define MATCH_IREP 0x3f
#define MASK_IREP  0x7f
#define MATCH_FLH 0x1007
#define MASK_FLH  0x707f
#define MATCH_FSH 0x1027
#define MASK_FSH  0x707f
#define MATCH_FMADD_H 0x4000043
#define MASK_FMADD_H  0x600007f
#define MATCH_FMSUB_H 0x4000047
#define MASK_FMSUB_H  0x600007f
#define MATCH_FNMSUB_H 0x400004b
#define MASK_FNMSUB_H  0x600007f
#define MATCH_FNMADD_H 0x400004f
#define MASK_FNMADD_H  0x600007f
#define MATCH_FADD_H 0x4000053
#define MASK_FADD_H  0xfe00007f
#define MATCH_FSUB_H 0xc000053
#define MASK_FSUB_H  0xfe00007f
#define MATCH_FMUL_H 0x14000053
#define MASK_FMUL_H  0xfe00007f
#define MATCH_FDIV_H 0x1c000053
#define MASK_FDIV_H  0xfe00007f
#define MATCH_FSQRT_H 0x5c000053
#define MASK_FSQRT_H  0xfff0007f
#define MATCH_FSGNJ_H 0x24000053
#define MASK_FSGNJ_H  0xfe00707f
#define MATCH_FSGNJN_H 0x24001053
#define MASK_FSGNJN_H  0xfe00707f
#define MATCH_FSGNJX_H 0x24002053
#define MASK_FSGNJX_H  0xfe00707f
#define MATCH_FMIN_H 0x2c000053
#define MASK_FMIN_H  0xfe00707f
#define MATCH_FMAX_H 0x2c001053
#define MASK_FMAX_H  0xfe00707f
#define MATCH_FEQ_H 0xa4002053
#define MASK_FEQ_H  0xfe00707f
#define MATCH_FLT_H 0xa4001053
#define MASK_FLT_H  0xfe00707f
#define MATCH_FLE_H 0xa4000053
#define MASK_FLE_H  0xfe00707f
#define MATCH_FCVT_W_H 0xc4000053
#define MASK_FCVT_W_H  0xfff0007f
#define MATCH_FCVT_WU_H 0xc4100053
#define MASK_FCVT_WU_H  0xfff0007f
#define MATCH_FCVT_H_W 0xd4000053
#define MASK_FCVT_H_W  0xfff0007f
#define MATCH_FCVT_H_WU 0xd4100053
#define MASK_FCVT_H_WU  0xfff0007f
#define MATCH_FMV_X_H 0xe4000053
#define MASK_FMV_X_H  0xfff0707f
#define MATCH_FCLASS_H 0xe4001053
#define MASK_FCLASS_H  0xfff0707f
#define MATCH_FMV_H_X 0xf4000053
#define MASK_FMV_H_X  0xfff0707f
#define MATCH_FCVT_L_H 0xc4200053
#define MASK_FCVT_L_H  0xfff0007f
#define MATCH_FCVT_LU_H 0xc4300053
#define MASK_FCVT_LU_H  0xfff0007f
#define MATCH_FCVT_H_L 0xd4200053
#define MASK_FCVT_H_L  0xfff0007f
#define MATCH_FCVT_H_LU 0xd4300053
#define MASK_FCVT_H_LU  0xfff0007f
#define MATCH_FCVT_S_H 0x40200053
#define MASK_FCVT_S_H  0xfff0707f
#define MATCH_FCVT_H_S 0x44000053
#define MASK_FCVT_H_S  0xfff0007f
#define MATCH_FCVT_D_H 0x42200053
#define MASK_FCVT_D_H  0xfff0707f
#define MATCH_FCVT_H_D 0x44100053
#define MASK_FCVT_H_D  0xfff0007f
#define MATCH_FLAH 0x1007
#define MASK_FLAH  0x707f
#define MATCH_FSAH 0x1027
#define MASK_FSAH  0x707f
#define MATCH_FMADD_AH 0x4000043
#define MASK_FMADD_AH  0x600007f
#define MATCH_FMSUB_AH 0x4000047
#define MASK_FMSUB_AH  0x600007f
#define MATCH_FNMSUB_AH 0x400004b
#define MASK_FNMSUB_AH  0x600007f
#define MATCH_FNMADD_AH 0x400004f
#define MASK_FNMADD_AH  0x600007f
#define MATCH_FADD_AH 0x4000053
#define MASK_FADD_AH  0xfe00007f
#define MATCH_FSUB_AH 0xc000053
#define MASK_FSUB_AH  0xfe00007f
#define MATCH_FMUL_AH 0x14000053
#define MASK_FMUL_AH  0xfe00007f
#define MATCH_FDIV_AH 0x1c000053
#define MASK_FDIV_AH  0xfe00007f
#define MATCH_FSQRT_AH 0x5c000053
#define MASK_FSQRT_AH  0xfff0007f
#define MATCH_FSGNJ_AH 0x24000053
#define MASK_FSGNJ_AH  0xfe00707f
#define MATCH_FSGNJN_AH 0x24001053
#define MASK_FSGNJN_AH  0xfe00707f
#define MATCH_FSGNJX_AH 0x24002053
#define MASK_FSGNJX_AH  0xfe00707f
#define MATCH_FMIN_AH 0x2c000053
#define MASK_FMIN_AH  0xfe00707f
#define MATCH_FMAX_AH 0x2c001053
#define MASK_FMAX_AH  0xfe00707f
#define MATCH_FEQ_AH 0xa4002053
#define MASK_FEQ_AH  0xfe00707f
#define MATCH_FLT_AH 0xa4001053
#define MASK_FLT_AH  0xfe00707f
#define MATCH_FLE_AH 0xa4000053
#define MASK_FLE_AH  0xfe00707f
#define MATCH_FCVT_W_AH 0xc4000053
#define MASK_FCVT_W_AH  0xfff0007f
#define MATCH_FCVT_WU_AH 0xc4100053
#define MASK_FCVT_WU_AH  0xfff0007f
#define MATCH_FCVT_AH_W 0xd4000053
#define MASK_FCVT_AH_W  0xfff0007f
#define MATCH_FCVT_AH_WU 0xd4100053
#define MASK_FCVT_AH_WU  0xfff0007f
#define MATCH_FMV_X_AH 0xe4000053
#define MASK_FMV_X_AH  0xfff0707f
#define MATCH_FCLASS_AH 0xe4001053
#define MASK_FCLASS_AH  0xfff0707f
#define MATCH_FMV_AH_X 0xf4000053
#define MASK_FMV_AH_X  0xfff0707f
#define MATCH_FCVT_L_AH 0xc4200053
#define MASK_FCVT_L_AH  0xfff0007f
#define MATCH_FCVT_LU_AH 0xc4300053
#define MASK_FCVT_LU_AH  0xfff0007f
#define MATCH_FCVT_AH_L 0xd4200053
#define MASK_FCVT_AH_L  0xfff0007f
#define MATCH_FCVT_AH_LU 0xd4300053
#define MASK_FCVT_AH_LU  0xfff0007f
#define MATCH_FCVT_S_AH 0x40200053
#define MASK_FCVT_S_AH  0xfff0707f
#define MATCH_FCVT_AH_S 0x44000053
#define MASK_FCVT_AH_S  0xfff0007f
#define MATCH_FCVT_D_AH 0x42200053
#define MASK_FCVT_D_AH  0xfff0707f
#define MATCH_FCVT_AH_D 0x44100053
#define MASK_FCVT_AH_D  0xfff0007f
#define MATCH_FCVT_H_H 0x44200053
#define MASK_FCVT_H_H  0xfff0007f
#define MATCH_FCVT_AH_H 0x44200053
#define MASK_FCVT_AH_H  0xfff0007f
#define MATCH_FCVT_H_AH 0x44200053
#define MASK_FCVT_H_AH  0xfff0007f
#define MATCH_FCVT_AH_AH 0x44200053
#define MASK_FCVT_AH_AH  0xfff0007f
#define MATCH_FLB 0x7
#define MASK_FLB  0x707f
#define MATCH_FSB 0x27
#define MASK_FSB  0x707f
#define MATCH_FMADD_B 0x6000043
#define MASK_FMADD_B  0x600007f
#define MATCH_FMSUB_B 0x6000047
#define MASK_FMSUB_B  0x600007f
#define MATCH_FNMSUB_B 0x600004b
#define MASK_FNMSUB_B  0x600007f
#define MATCH_FNMADD_B 0x600004f
#define MASK_FNMADD_B  0x600007f
#define MATCH_FADD_B 0x6000053
#define MASK_FADD_B  0xfe00007f
#define MATCH_FSUB_B 0xe000053
#define MASK_FSUB_B  0xfe00007f
#define MATCH_FMUL_B 0x16000053
#define MASK_FMUL_B  0xfe00007f
#define MATCH_FDIV_B 0x1e000053
#define MASK_FDIV_B  0xfe00007f
#define MATCH_FSQRT_B 0x5e000053
#define MASK_FSQRT_B  0xfff0007f
#define MATCH_FSGNJ_B 0x26000053
#define MASK_FSGNJ_B  0xfe00707f
#define MATCH_FSGNJN_B 0x26001053
#define MASK_FSGNJN_B  0xfe00707f
#define MATCH_FSGNJX_B 0x26002053
#define MASK_FSGNJX_B  0xfe00707f
#define MATCH_FMIN_B 0x2e000053
#define MASK_FMIN_B  0xfe00707f
#define MATCH_FMAX_B 0x2e001053
#define MASK_FMAX_B  0xfe00707f
#define MATCH_FEQ_B 0xa6002053
#define MASK_FEQ_B  0xfe00707f
#define MATCH_FLT_B 0xa6001053
#define MASK_FLT_B  0xfe00707f
#define MATCH_FLE_B 0xa6000053
#define MASK_FLE_B  0xfe00707f
#define MATCH_FCVT_W_B 0xc6000053
#define MASK_FCVT_W_B  0xfff0007f
#define MATCH_FCVT_WU_B 0xc6100053
#define MASK_FCVT_WU_B  0xfff0007f
#define MATCH_FCVT_B_W 0xd6000053
#define MASK_FCVT_B_W  0xfff0007f
#define MATCH_FCVT_B_WU 0xd6100053
#define MASK_FCVT_B_WU  0xfff0007f
#define MATCH_FMV_X_B 0xe6000053
#define MASK_FMV_X_B  0xfff0707f
#define MATCH_FCLASS_B 0xe6001053
#define MASK_FCLASS_B  0xfff0707f
#define MATCH_FMV_B_X 0xf6000053
#define MASK_FMV_B_X  0xfff0707f
#define MATCH_FCVT_L_B 0xc6200053
#define MASK_FCVT_L_B  0xfff0007f
#define MATCH_FCVT_LU_B 0xc6300053
#define MASK_FCVT_LU_B  0xfff0007f
#define MATCH_FCVT_B_L 0xd6200053
#define MASK_FCVT_B_L  0xfff0007f
#define MATCH_FCVT_B_LU 0xd6300053
#define MASK_FCVT_B_LU  0xfff0007f
#define MATCH_FCVT_S_B 0x40300053
#define MASK_FCVT_S_B  0xfff0707f
#define MATCH_FCVT_B_S 0x46000053
#define MASK_FCVT_B_S  0xfff0007f
#define MATCH_FCVT_D_B 0x42300053
#define MASK_FCVT_D_B  0xfff0707f
#define MATCH_FCVT_B_D 0x46100053
#define MASK_FCVT_B_D  0xfff0007f
#define MATCH_FCVT_H_B 0x44300053
#define MASK_FCVT_H_B  0xfff0707f
#define MATCH_FCVT_B_H 0x46200053
#define MASK_FCVT_B_H  0xfff0007f
#define MATCH_FCVT_AH_B 0x44300053
#define MASK_FCVT_AH_B  0xfff0707f
#define MATCH_FCVT_B_AH 0x46200053
#define MASK_FCVT_B_AH  0xfff0007f
#define MATCH_FLAB 0x7
#define MASK_FLAB  0x707f
#define MATCH_FSAB 0x27
#define MASK_FSAB  0x707f
#define MATCH_FMADD_AB 0x6000043
#define MASK_FMADD_AB  0x600007f
#define MATCH_FMSUB_AB 0x6000047
#define MASK_FMSUB_AB  0x600007f
#define MATCH_FNMSUB_AB 0x600004b
#define MASK_FNMSUB_AB  0x600007f
#define MATCH_FNMADD_AB 0x600004f
#define MASK_FNMADD_AB  0x600007f
#define MATCH_FADD_AB 0x6000053
#define MASK_FADD_AB  0xfe00007f
#define MATCH_FSUB_AB 0xe000053
#define MASK_FSUB_AB  0xfe00007f
#define MATCH_FMUL_AB 0x16000053
#define MASK_FMUL_AB  0xfe00007f
#define MATCH_FDIV_AB 0x1e000053
#define MASK_FDIV_AB  0xfe00007f
#define MATCH_FSQRT_AB 0x5e000053
#define MASK_FSQRT_AB  0xfff0007f
#define MATCH_FSGNJ_AB 0x26000053
#define MASK_FSGNJ_AB  0xfe00707f
#define MATCH_FSGNJN_AB 0x26001053
#define MASK_FSGNJN_AB  0xfe00707f
#define MATCH_FSGNJX_AB 0x26002053
#define MASK_FSGNJX_AB  0xfe00707f
#define MATCH_FMIN_AB 0x2e000053
#define MASK_FMIN_AB  0xfe00707f
#define MATCH_FMAX_AB 0x2e001053
#define MASK_FMAX_AB  0xfe00707f
#define MATCH_FEQ_AB 0xa6002053
#define MASK_FEQ_AB  0xfe00707f
#define MATCH_FLT_AB 0xa6001053
#define MASK_FLT_AB  0xfe00707f
#define MATCH_FLE_AB 0xa6000053
#define MASK_FLE_AB  0xfe00707f
#define MATCH_FCVT_W_AB 0xc6000053
#define MASK_FCVT_W_AB  0xfff0007f
#define MATCH_FCVT_WU_AB 0xc6100053
#define MASK_FCVT_WU_AB  0xfff0007f
#define MATCH_FCVT_AB_W 0xd6000053
#define MASK_FCVT_AB_W  0xfff0007f
#define MATCH_FCVT_AB_WU 0xd6100053
#define MASK_FCVT_AB_WU  0xfff0007f
#define MATCH_FMV_X_AB 0xe6000053
#define MASK_FMV_X_AB  0xfff0707f
#define MATCH_FCLASS_AB 0xe6001053
#define MASK_FCLASS_AB  0xfff0707f
#define MATCH_FMV_AB_X 0xf6000053
#define MASK_FMV_AB_X  0xfff0707f
#define MATCH_FCVT_L_AB 0xc6200053
#define MASK_FCVT_L_AB  0xfff0007f
#define MATCH_FCVT_LU_AB 0xc6300053
#define MASK_FCVT_LU_AB  0xfff0007f
#define MATCH_FCVT_AB_L 0xd6200053
#define MASK_FCVT_AB_L  0xfff0007f
#define MATCH_FCVT_AB_LU 0xd6300053
#define MASK_FCVT_AB_LU  0xfff0007f
#define MATCH_FCVT_S_AB 0x40300053
#define MASK_FCVT_S_AB  0xfff0707f
#define MATCH_FCVT_AB_S 0x46000053
#define MASK_FCVT_AB_S  0xfff0007f
#define MATCH_FCVT_D_AB 0x42300053
#define MASK_FCVT_D_AB  0xfff0707f
#define MATCH_FCVT_AB_D 0x46100053
#define MASK_FCVT_AB_D  0xfff0007f
#define MATCH_FCVT_H_AB 0x44300053
#define MASK_FCVT_H_AB  0xfff0707f
#define MATCH_FCVT_AB_H 0x46200053
#define MASK_FCVT_AB_H  0xfff0007f
#define MATCH_FCVT_AH_AB 0x44300053
#define MASK_FCVT_AH_AB  0xfff0707f
#define MATCH_FCVT_AB_AH 0x46200053
#define MASK_FCVT_AB_AH  0xfff0007f
#define MATCH_FCVT_B_B 0x46300053
#define MASK_FCVT_B_B  0xfff0707f
#define MATCH_FCVT_AB_B 0x46300053
#define MASK_FCVT_AB_B  0xfff0707f
#define MATCH_FCVT_B_AB 0x46300053
#define MASK_FCVT_B_AB  0xfff0707f
#define MATCH_FCVT_AB_AB 0x46300053
#define MASK_FCVT_AB_AB  0xfff0707f
#define MATCH_VFADD_S 0x82000033
#define MASK_VFADD_S  0xfe00707f
#define MATCH_VFADD_R_S 0x82004033
#define MASK_VFADD_R_S  0xfe00707f
#define MATCH_VFSUB_S 0x84000033
#define MASK_VFSUB_S  0xfe00707f
#define MATCH_VFSUB_R_S 0x84004033
#define MASK_VFSUB_R_S  0xfe00707f
#define MATCH_VFMUL_S 0x86000033
#define MASK_VFMUL_S  0xfe00707f
#define MATCH_VFMUL_R_S 0x86004033
#define MASK_VFMUL_R_S  0xfe00707f
#define MATCH_VFDIV_S 0x88000033
#define MASK_VFDIV_S  0xfe00707f
#define MATCH_VFDIV_R_S 0x88004033
#define MASK_VFDIV_R_S  0xfe00707f
#define MATCH_VFMIN_S 0x8a000033
#define MASK_VFMIN_S  0xfe00707f
#define MATCH_VFMIN_R_S 0x8a004033
#define MASK_VFMIN_R_S  0xfe00707f
#define MATCH_VFMAX_S 0x8c000033
#define MASK_VFMAX_S  0xfe00707f
#define MATCH_VFMAX_R_S 0x8c004033
#define MASK_VFMAX_R_S  0xfe00707f
#define MATCH_VFSQRT_S 0x8e000033
#define MASK_VFSQRT_S  0xfff0707f
#define MATCH_VFMAC_S 0x90000033
#define MASK_VFMAC_S  0xfe00707f
#define MATCH_VFMAC_R_S 0x90004033
#define MASK_VFMAC_R_S  0xfe00707f
#define MATCH_VFMRE_S 0x92000033
#define MASK_VFMRE_S  0xfe00707f
#define MATCH_VFMRE_R_S 0x92004033
#define MASK_VFMRE_R_S  0xfe00707f
#define MATCH_VFCLASS_S 0x98100033
#define MASK_VFCLASS_S  0xfff0707f
#define MATCH_VFSGNJ_S 0x9a000033
#define MASK_VFSGNJ_S  0xfe00707f
#define MATCH_VFSGNJ_R_S 0x9a004033
#define MASK_VFSGNJ_R_S  0xfe00707f
#define MATCH_VFSGNJN_S 0x9c000033
#define MASK_VFSGNJN_S  0xfe00707f
#define MATCH_VFSGNJN_R_S 0x9c004033
#define MASK_VFSGNJN_R_S  0xfe00707f
#define MATCH_VFSGNJX_S 0x9e000033
#define MASK_VFSGNJX_S  0xfe00707f
#define MATCH_VFSGNJX_R_S 0x9e004033
#define MASK_VFSGNJX_R_S  0xfe00707f
#define MATCH_VFEQ_S 0xa0000033
#define MASK_VFEQ_S  0xfe00707f
#define MATCH_VFEQ_R_S 0xa0004033
#define MASK_VFEQ_R_S  0xfe00707f
#define MATCH_VFNE_S 0xa2000033
#define MASK_VFNE_S  0xfe00707f
#define MATCH_VFNE_R_S 0xa2004033
#define MASK_VFNE_R_S  0xfe00707f
#define MATCH_VFLT_S 0xa4000033
#define MASK_VFLT_S  0xfe00707f
#define MATCH_VFLT_R_S 0xa4004033
#define MASK_VFLT_R_S  0xfe00707f
#define MATCH_VFGE_S 0xa6000033
#define MASK_VFGE_S  0xfe00707f
#define MATCH_VFGE_R_S 0xa6004033
#define MASK_VFGE_R_S  0xfe00707f
#define MATCH_VFLE_S 0xa8000033
#define MASK_VFLE_S  0xfe00707f
#define MATCH_VFLE_R_S 0xa8004033
#define MASK_VFLE_R_S  0xfe00707f
#define MATCH_VFGT_S 0xaa000033
#define MASK_VFGT_S  0xfe00707f
#define MATCH_VFGT_R_S 0xaa004033
#define MASK_VFGT_R_S  0xfe00707f
#define MATCH_VFMV_X_S 0x98000033
#define MASK_VFMV_X_S  0xfff0707f
#define MATCH_VFMV_S_X 0x98004033
#define MASK_VFMV_S_X  0xfff0707f
#define MATCH_VFCVT_X_S 0x98200033
#define MASK_VFCVT_X_S  0xfff0707f
#define MATCH_VFCVT_XU_S 0x98204033
#define MASK_VFCVT_XU_S  0xfff0707f
#define MATCH_VFCVT_S_X 0x98300033
#define MASK_VFCVT_S_X  0xfff0707f
#define MATCH_VFCVT_S_XU 0x98304033
#define MASK_VFCVT_S_XU  0xfff0707f
#define MATCH_VFCPKA_S_S 0xb0000033
#define MASK_VFCPKA_S_S  0xfe00707f
#define MATCH_VFCPKB_S_S 0xb0004033
#define MASK_VFCPKB_S_S  0xfe00707f
#define MATCH_VFCPKC_S_S 0xb2000033
#define MASK_VFCPKC_S_S  0xfe00707f
#define MATCH_VFCPKD_S_S 0xb2004033
#define MASK_VFCPKD_S_S  0xfe00707f
#define MATCH_VFCPKA_S_D 0xb4000033
#define MASK_VFCPKA_S_D  0xfe00707f
#define MATCH_VFCPKB_S_D 0xb4004033
#define MASK_VFCPKB_S_D  0xfe00707f
#define MATCH_VFCPKC_S_D 0xb6000033
#define MASK_VFCPKC_S_D  0xfe00707f
#define MATCH_VFCPKD_S_D 0xb6004033
#define MASK_VFCPKD_S_D  0xfe00707f
#define MATCH_VFCVT_H_H 0x98502033
#define MASK_VFCVT_H_H  0xfff0707f
#define MATCH_VFCVT_H_AH 0x98502033
#define MASK_VFCVT_H_AH  0xfff0707f
#define MATCH_VFCVT_AH_H 0x98502033
#define MASK_VFCVT_AH_H  0xfff0707f
#define MATCH_VFCVTU_H_H 0x98506033
#define MASK_VFCVTU_H_H  0xfff0707f
#define MATCH_VFCVTU_H_AH 0x98506033
#define MASK_VFCVTU_H_AH  0xfff0707f
#define MATCH_VFCVTU_AH_H 0x98506033
#define MASK_VFCVTU_AH_H  0xfff0707f
#define MATCH_VFADD_H 0x82002033
#define MASK_VFADD_H  0xfe00707f
#define MATCH_VFADD_R_H 0x82006033
#define MASK_VFADD_R_H  0xfe00707f
#define MATCH_VFSUB_H 0x84002033
#define MASK_VFSUB_H  0xfe00707f
#define MATCH_VFSUB_R_H 0x84006033
#define MASK_VFSUB_R_H  0xfe00707f
#define MATCH_VFMUL_H 0x86002033
#define MASK_VFMUL_H  0xfe00707f
#define MATCH_VFMUL_R_H 0x86006033
#define MASK_VFMUL_R_H  0xfe00707f
#define MATCH_VFDIV_H 0x88002033
#define MASK_VFDIV_H  0xfe00707f
#define MATCH_VFDIV_R_H 0x88006033
#define MASK_VFDIV_R_H  0xfe00707f
#define MATCH_VFMIN_H 0x8a002033
#define MASK_VFMIN_H  0xfe00707f
#define MATCH_VFMIN_R_H 0x8a006033
#define MASK_VFMIN_R_H  0xfe00707f
#define MATCH_VFMAX_H 0x8c002033
#define MASK_VFMAX_H  0xfe00707f
#define MATCH_VFMAX_R_H 0x8c006033
#define MASK_VFMAX_R_H  0xfe00707f
#define MATCH_VFSQRT_H 0x8e002033
#define MASK_VFSQRT_H  0xfff0707f
#define MATCH_VFMAC_H 0x90002033
#define MASK_VFMAC_H  0xfe00707f
#define MATCH_VFMAC_R_H 0x90006033
#define MASK_VFMAC_R_H  0xfe00707f
#define MATCH_VFMRE_H 0x92002033
#define MASK_VFMRE_H  0xfe00707f
#define MATCH_VFMRE_R_H 0x92006033
#define MASK_VFMRE_R_H  0xfe00707f
#define MATCH_VFCLASS_H 0x98102033
#define MASK_VFCLASS_H  0xfff0707f
#define MATCH_VFSGNJ_H 0x9a002033
#define MASK_VFSGNJ_H  0xfe00707f
#define MATCH_VFSGNJ_R_H 0x9a006033
#define MASK_VFSGNJ_R_H  0xfe00707f
#define MATCH_VFSGNJN_H 0x9c002033
#define MASK_VFSGNJN_H  0xfe00707f
#define MATCH_VFSGNJN_R_H 0x9c006033
#define MASK_VFSGNJN_R_H  0xfe00707f
#define MATCH_VFSGNJX_H 0x9e002033
#define MASK_VFSGNJX_H  0xfe00707f
#define MATCH_VFSGNJX_R_H 0x9e006033
#define MASK_VFSGNJX_R_H  0xfe00707f
#define MATCH_VFEQ_H 0xa0002033
#define MASK_VFEQ_H  0xfe00707f
#define MATCH_VFEQ_R_H 0xa0006033
#define MASK_VFEQ_R_H  0xfe00707f
#define MATCH_VFNE_H 0xa2002033
#define MASK_VFNE_H  0xfe00707f
#define MATCH_VFNE_R_H 0xa2006033
#define MASK_VFNE_R_H  0xfe00707f
#define MATCH_VFLT_H 0xa4002033
#define MASK_VFLT_H  0xfe00707f
#define MATCH_VFLT_R_H 0xa4006033
#define MASK_VFLT_R_H  0xfe00707f
#define MATCH_VFGE_H 0xa6002033
#define MASK_VFGE_H  0xfe00707f
#define MATCH_VFGE_R_H 0xa6006033
#define MASK_VFGE_R_H  0xfe00707f
#define MATCH_VFLE_H 0xa8002033
#define MASK_VFLE_H  0xfe00707f
#define MATCH_VFLE_R_H 0xa8006033
#define MASK_VFLE_R_H  0xfe00707f
#define MATCH_VFGT_H 0xaa002033
#define MASK_VFGT_H  0xfe00707f
#define MATCH_VFGT_R_H 0xaa006033
#define MASK_VFGT_R_H  0xfe00707f
#define MATCH_VFMV_X_H 0x98002033
#define MASK_VFMV_X_H  0xfff0707f
#define MATCH_VFMV_H_X 0x98006033
#define MASK_VFMV_H_X  0xfff0707f
#define MATCH_VFCVT_X_H 0x98202033
#define MASK_VFCVT_X_H  0xfff0707f
#define MATCH_VFCVT_XU_H 0x98206033
#define MASK_VFCVT_XU_H  0xfff0707f
#define MATCH_VFCVT_H_X 0x98302033
#define MASK_VFCVT_H_X  0xfff0707f
#define MATCH_VFCVT_H_XU 0x98306033
#define MASK_VFCVT_H_XU  0xfff0707f
#define MATCH_VFCPKA_H_S 0xb0002033
#define MASK_VFCPKA_H_S  0xfe00707f
#define MATCH_VFCPKB_H_S 0xb0006033
#define MASK_VFCPKB_H_S  0xfe00707f
#define MATCH_VFCPKC_H_S 0xb2002033
#define MASK_VFCPKC_H_S  0xfe00707f
#define MATCH_VFCPKD_H_S 0xb2006033
#define MASK_VFCPKD_H_S  0xfe00707f
#define MATCH_VFCPKA_H_D 0xb4002033
#define MASK_VFCPKA_H_D  0xfe00707f
#define MATCH_VFCPKB_H_D 0xb4006033
#define MASK_VFCPKB_H_D  0xfe00707f
#define MATCH_VFCPKC_H_D 0xb6002033
#define MASK_VFCPKC_H_D  0xfe00707f
#define MATCH_VFCPKD_H_D 0xb6006033
#define MASK_VFCPKD_H_D  0xfe00707f
#define MATCH_VFCVT_S_H 0x98600033
#define MASK_VFCVT_S_H  0xfff0707f
#define MATCH_VFCVTU_S_H 0x98604033
#define MASK_VFCVTU_S_H  0xfff0707f
#define MATCH_VFCVT_H_S 0x98402033
#define MASK_VFCVT_H_S  0xfff0707f
#define MATCH_VFCVTU_H_S 0x98406033
#define MASK_VFCVTU_H_S  0xfff0707f
#define MATCH_VFADD_AH 0x82002033
#define MASK_VFADD_AH  0xfe00707f
#define MATCH_VFADD_R_AH 0x82006033
#define MASK_VFADD_R_AH  0xfe00707f
#define MATCH_VFSUB_AH 0x84002033
#define MASK_VFSUB_AH  0xfe00707f
#define MATCH_VFSUB_R_AH 0x84006033
#define MASK_VFSUB_R_AH  0xfe00707f
#define MATCH_VFMUL_AH 0x86002033
#define MASK_VFMUL_AH  0xfe00707f
#define MATCH_VFMUL_R_AH 0x86006033
#define MASK_VFMUL_R_AH  0xfe00707f
#define MATCH_VFDIV_AH 0x88002033
#define MASK_VFDIV_AH  0xfe00707f
#define MATCH_VFDIV_R_AH 0x88006033
#define MASK_VFDIV_R_AH  0xfe00707f
#define MATCH_VFMIN_AH 0x8a002033
#define MASK_VFMIN_AH  0xfe00707f
#define MATCH_VFMIN_R_AH 0x8a006033
#define MASK_VFMIN_R_AH  0xfe00707f
#define MATCH_VFMAX_AH 0x8c002033
#define MASK_VFMAX_AH  0xfe00707f
#define MATCH_VFMAX_R_AH 0x8c006033
#define MASK_VFMAX_R_AH  0xfe00707f
#define MATCH_VFSQRT_AH 0x8e002033
#define MASK_VFSQRT_AH  0xfff0707f
#define MATCH_VFMAC_AH 0x90002033
#define MASK_VFMAC_AH  0xfe00707f
#define MATCH_VFMAC_R_AH 0x90006033
#define MASK_VFMAC_R_AH  0xfe00707f
#define MATCH_VFMRE_AH 0x92002033
#define MASK_VFMRE_AH  0xfe00707f
#define MATCH_VFMRE_R_AH 0x92006033
#define MASK_VFMRE_R_AH  0xfe00707f
#define MATCH_VFCLASS_AH 0x98102033
#define MASK_VFCLASS_AH  0xfff0707f
#define MATCH_VFSGNJ_AH 0x9a002033
#define MASK_VFSGNJ_AH  0xfe00707f
#define MATCH_VFSGNJ_R_AH 0x9a006033
#define MASK_VFSGNJ_R_AH  0xfe00707f
#define MATCH_VFSGNJN_AH 0x9c002033
#define MASK_VFSGNJN_AH  0xfe00707f
#define MATCH_VFSGNJN_R_AH 0x9c006033
#define MASK_VFSGNJN_R_AH  0xfe00707f
#define MATCH_VFSGNJX_AH 0x9e002033
#define MASK_VFSGNJX_AH  0xfe00707f
#define MATCH_VFSGNJX_R_AH 0x9e006033
#define MASK_VFSGNJX_R_AH  0xfe00707f
#define MATCH_VFEQ_AH 0xa0002033
#define MASK_VFEQ_AH  0xfe00707f
#define MATCH_VFEQ_R_AH 0xa0006033
#define MASK_VFEQ_R_AH  0xfe00707f
#define MATCH_VFNE_AH 0xa2002033
#define MASK_VFNE_AH  0xfe00707f
#define MATCH_VFNE_R_AH 0xa2006033
#define MASK_VFNE_R_AH  0xfe00707f
#define MATCH_VFLT_AH 0xa4002033
#define MASK_VFLT_AH  0xfe00707f
#define MATCH_VFLT_R_AH 0xa4006033
#define MASK_VFLT_R_AH  0xfe00707f
#define MATCH_VFGE_AH 0xa6002033
#define MASK_VFGE_AH  0xfe00707f
#define MATCH_VFGE_R_AH 0xa6006033
#define MASK_VFGE_R_AH  0xfe00707f
#define MATCH_VFLE_AH 0xa8002033
#define MASK_VFLE_AH  0xfe00707f
#define MATCH_VFLE_R_AH 0xa8006033
#define MASK_VFLE_R_AH  0xfe00707f
#define MATCH_VFGT_AH 0xaa002033
#define MASK_VFGT_AH  0xfe00707f
#define MATCH_VFGT_R_AH 0xaa006033
#define MASK_VFGT_R_AH  0xfe00707f
#define MATCH_VFMV_X_AH 0x98002033
#define MASK_VFMV_X_AH  0xfff0707f
#define MATCH_VFMV_AH_X 0x98006033
#define MASK_VFMV_AH_X  0xfff0707f
#define MATCH_VFCVT_X_AH 0x98202033
#define MASK_VFCVT_X_AH  0xfff0707f
#define MATCH_VFCVT_XU_AH 0x98206033
#define MASK_VFCVT_XU_AH  0xfff0707f
#define MATCH_VFCVT_AH_X 0x98302033
#define MASK_VFCVT_AH_X  0xfff0707f
#define MATCH_VFCVT_AH_XU 0x98306033
#define MASK_VFCVT_AH_XU  0xfff0707f
#define MATCH_VFCPKA_AH_S 0xb0002033
#define MASK_VFCPKA_AH_S  0xfe00707f
#define MATCH_VFCPKB_AH_S 0xb0006033
#define MASK_VFCPKB_AH_S  0xfe00707f
#define MATCH_VFCPKC_AH_S 0xb2002033
#define MASK_VFCPKC_AH_S  0xfe00707f
#define MATCH_VFCPKD_AH_S 0xb2006033
#define MASK_VFCPKD_AH_S  0xfe00707f
#define MATCH_VFCPKA_AH_D 0xb4002033
#define MASK_VFCPKA_AH_D  0xfe00707f
#define MATCH_VFCPKB_AH_D 0xb4006033
#define MASK_VFCPKB_AH_D  0xfe00707f
#define MATCH_VFCPKC_AH_D 0xb6002033
#define MASK_VFCPKC_AH_D  0xfe00707f
#define MATCH_VFCPKD_AH_D 0xb6006033
#define MASK_VFCPKD_AH_D  0xfe00707f
#define MATCH_VFCVT_S_AH 0x98600033
#define MASK_VFCVT_S_AH  0xfff0707f
#define MATCH_VFCVTU_S_AH 0x98604033
#define MASK_VFCVTU_S_AH  0xfff0707f
#define MATCH_VFCVT_AH_S 0x98402033
#define MASK_VFCVT_AH_S  0xfff0707f
#define MATCH_VFCVTU_AH_S 0x98406033
#define MASK_VFCVTU_AH_S  0xfff0707f
#define MATCH_VFADD_B 0x82003033
#define MASK_VFADD_B  0xfe00707f
#define MATCH_VFADD_R_B 0x82007033
#define MASK_VFADD_R_B  0xfe00707f
#define MATCH_VFSUB_B 0x84003033
#define MASK_VFSUB_B  0xfe00707f
#define MATCH_VFSUB_R_B 0x84007033
#define MASK_VFSUB_R_B  0xfe00707f
#define MATCH_VFMUL_B 0x86003033
#define MASK_VFMUL_B  0xfe00707f
#define MATCH_VFMUL_R_B 0x86007033
#define MASK_VFMUL_R_B  0xfe00707f
#define MATCH_VFDIV_B 0x88003033
#define MASK_VFDIV_B  0xfe00707f
#define MATCH_VFDIV_R_B 0x88007033
#define MASK_VFDIV_R_B  0xfe00707f
#define MATCH_VFMIN_B 0x8a003033
#define MASK_VFMIN_B  0xfe00707f
#define MATCH_VFMIN_R_B 0x8a007033
#define MASK_VFMIN_R_B  0xfe00707f
#define MATCH_VFMAX_B 0x8c003033
#define MASK_VFMAX_B  0xfe00707f
#define MATCH_VFMAX_R_B 0x8c007033
#define MASK_VFMAX_R_B  0xfe00707f
#define MATCH_VFSQRT_B 0x8e003033
#define MASK_VFSQRT_B  0xfff0707f
#define MATCH_VFMAC_B 0x90003033
#define MASK_VFMAC_B  0xfe00707f
#define MATCH_VFMAC_R_B 0x90007033
#define MASK_VFMAC_R_B  0xfe00707f
#define MATCH_VFMRE_B 0x92003033
#define MASK_VFMRE_B  0xfe00707f
#define MATCH_VFMRE_R_B 0x92007033
#define MASK_VFMRE_R_B  0xfe00707f
#define MATCH_VFSGNJ_B 0x9a003033
#define MASK_VFSGNJ_B  0xfe00707f
#define MATCH_VFSGNJ_R_B 0x9a007033
#define MASK_VFSGNJ_R_B  0xfe00707f
#define MATCH_VFSGNJN_B 0x9c003033
#define MASK_VFSGNJN_B  0xfe00707f
#define MATCH_VFSGNJN_R_B 0x9c007033
#define MASK_VFSGNJN_R_B  0xfe00707f
#define MATCH_VFSGNJX_B 0x9e003033
#define MASK_VFSGNJX_B  0xfe00707f
#define MATCH_VFSGNJX_R_B 0x9e007033
#define MASK_VFSGNJX_R_B  0xfe00707f
#define MATCH_VFEQ_B 0xa0003033
#define MASK_VFEQ_B  0xfe00707f
#define MATCH_VFEQ_R_B 0xa0007033
#define MASK_VFEQ_R_B  0xfe00707f
#define MATCH_VFNE_B 0xa2003033
#define MASK_VFNE_B  0xfe00707f
#define MATCH_VFNE_R_B 0xa2007033
#define MASK_VFNE_R_B  0xfe00707f
#define MATCH_VFLT_B 0xa4003033
#define MASK_VFLT_B  0xfe00707f
#define MATCH_VFLT_R_B 0xa4007033
#define MASK_VFLT_R_B  0xfe00707f
#define MATCH_VFGE_B 0xa6003033
#define MASK_VFGE_B  0xfe00707f
#define MATCH_VFGE_R_B 0xa6007033
#define MASK_VFGE_R_B  0xfe00707f
#define MATCH_VFLE_B 0xa8003033
#define MASK_VFLE_B  0xfe00707f
#define MATCH_VFLE_R_B 0xa8007033
#define MASK_VFLE_R_B  0xfe00707f
#define MATCH_VFGT_B 0xaa003033
#define MASK_VFGT_B  0xfe00707f
#define MATCH_VFGT_R_B 0xaa007033
#define MASK_VFGT_R_B  0xfe00707f
#define MATCH_VFMV_X_B 0x98003033
#define MASK_VFMV_X_B  0xfff0707f
#define MATCH_VFMV_B_X 0x98007033
#define MASK_VFMV_B_X  0xfff0707f
#define MATCH_VFCLASS_B 0x98103033
#define MASK_VFCLASS_B  0xfff0707f
#define MATCH_VFCVT_X_B 0x98203033
#define MASK_VFCVT_X_B  0xfff0707f
#define MATCH_VFCVT_XU_B 0x98207033
#define MASK_VFCVT_XU_B  0xfff0707f
#define MATCH_VFCVT_B_X 0x98303033
#define MASK_VFCVT_B_X  0xfff0707f
#define MATCH_VFCVT_B_XU 0x98307033
#define MASK_VFCVT_B_XU  0xfff0707f
#define MATCH_VFCPKA_B_S 0xb0003033
#define MASK_VFCPKA_B_S  0xfe00707f
#define MATCH_VFCPKB_B_S 0xb0007033
#define MASK_VFCPKB_B_S  0xfe00707f
#define MATCH_VFCPKC_B_S 0xb2003033
#define MASK_VFCPKC_B_S  0xfe00707f
#define MATCH_VFCPKD_B_S 0xb2007033
#define MASK_VFCPKD_B_S  0xfe00707f
#define MATCH_VFCPKA_B_D 0xb4003033
#define MASK_VFCPKA_B_D  0xfe00707f
#define MATCH_VFCPKB_B_D 0xb4007033
#define MASK_VFCPKB_B_D  0xfe00707f
#define MATCH_VFCPKC_B_D 0xb6003033
#define MASK_VFCPKC_B_D  0xfe00707f
#define MATCH_VFCPKD_B_D 0xb6007033
#define MASK_VFCPKD_B_D  0xfe00707f
#define MATCH_VFCVT_S_B 0x98700033
#define MASK_VFCVT_S_B  0xfff0707f
#define MATCH_VFCVTU_S_B 0x98704033
#define MASK_VFCVTU_S_B  0xfff0707f
#define MATCH_VFCVT_B_S 0x98403033
#define MASK_VFCVT_B_S  0xfff0707f
#define MATCH_VFCVTU_B_S 0x98407033
#define MASK_VFCVTU_B_S  0xfff0707f
#define MATCH_VFCVT_H_B 0x98702033
#define MASK_VFCVT_H_B  0xfff0707f
#define MATCH_VFCVTU_H_B 0x98706033
#define MASK_VFCVTU_H_B  0xfff0707f
#define MATCH_VFCVT_B_H 0x98603033
#define MASK_VFCVT_B_H  0xfff0707f
#define MATCH_VFCVTU_B_H 0x98607033
#define MASK_VFCVTU_B_H  0xfff0707f
#define MATCH_VFCVT_AH_B 0x98702033
#define MASK_VFCVT_AH_B  0xfff0707f
#define MATCH_VFCVTU_AH_B 0x98706033
#define MASK_VFCVTU_AH_B  0xfff0707f
#define MATCH_VFCVT_B_AH 0x98603033
#define MASK_VFCVT_B_AH  0xfff0707f
#define MATCH_VFCVTU_B_AH 0x98607033
#define MASK_VFCVTU_B_AH  0xfff0707f
#define MATCH_VFCVT_B_B 0x98703033
#define MASK_VFCVT_B_B  0xfff0707f
#define MATCH_VFCVT_AB_B 0x98703033
#define MASK_VFCVT_AB_B  0xfff0707f
#define MATCH_VFCVT_B_AB 0x98703033
#define MASK_VFCVT_B_AB  0xfff0707f
#define MATCH_VFCVTU_B_B 0x98707033
#define MASK_VFCVTU_B_B  0xfff0707f
#define MATCH_VFCVTU_AB_B 0x98707033
#define MASK_VFCVTU_AB_B  0xfff0707f
#define MATCH_VFCVTU_B_AB 0x98707033
#define MASK_VFCVTU_B_AB  0xfff0707f
#define MATCH_VFADD_AB 0x82003033
#define MASK_VFADD_AB  0xfe00707f
#define MATCH_VFADD_R_AB 0x82007033
#define MASK_VFADD_R_AB  0xfe00707f
#define MATCH_VFSUB_AB 0x84003033
#define MASK_VFSUB_AB  0xfe00707f
#define MATCH_VFSUB_R_AB 0x84007033
#define MASK_VFSUB_R_AB  0xfe00707f
#define MATCH_VFMUL_AB 0x86003033
#define MASK_VFMUL_AB  0xfe00707f
#define MATCH_VFMUL_R_AB 0x86007033
#define MASK_VFMUL_R_AB  0xfe00707f
#define MATCH_VFDIV_AB 0x88003033
#define MASK_VFDIV_AB  0xfe00707f
#define MATCH_VFDIV_R_AB 0x88007033
#define MASK_VFDIV_R_AB  0xfe00707f
#define MATCH_VFMIN_AB 0x8a003033
#define MASK_VFMIN_AB  0xfe00707f
#define MATCH_VFMIN_R_AB 0x8a007033
#define MASK_VFMIN_R_AB  0xfe00707f
#define MATCH_VFMAX_AB 0x8c003033
#define MASK_VFMAX_AB  0xfe00707f
#define MATCH_VFMAX_R_AB 0x8c007033
#define MASK_VFMAX_R_AB  0xfe00707f
#define MATCH_VFSQRT_AB 0x8e003033
#define MASK_VFSQRT_AB  0xfff0707f
#define MATCH_VFMAC_AB 0x90003033
#define MASK_VFMAC_AB  0xfe00707f
#define MATCH_VFMAC_R_AB 0x90007033
#define MASK_VFMAC_R_AB  0xfe00707f
#define MATCH_VFMRE_AB 0x92003033
#define MASK_VFMRE_AB  0xfe00707f
#define MATCH_VFMRE_R_AB 0x92007033
#define MASK_VFMRE_R_AB  0xfe00707f
#define MATCH_VFSGNJ_AB 0x9a003033
#define MASK_VFSGNJ_AB  0xfe00707f
#define MATCH_VFSGNJ_R_AB 0x9a007033
#define MASK_VFSGNJ_R_AB  0xfe00707f
#define MATCH_VFSGNJN_AB 0x9c003033
#define MASK_VFSGNJN_AB  0xfe00707f
#define MATCH_VFSGNJN_R_AB 0x9c007033
#define MASK_VFSGNJN_R_AB  0xfe00707f
#define MATCH_VFSGNJX_AB 0x9e003033
#define MASK_VFSGNJX_AB  0xfe00707f
#define MATCH_VFSGNJX_R_AB 0x9e007033
#define MASK_VFSGNJX_R_AB  0xfe00707f
#define MATCH_VFEQ_AB 0xa0003033
#define MASK_VFEQ_AB  0xfe00707f
#define MATCH_VFEQ_R_AB 0xa0007033
#define MASK_VFEQ_R_AB  0xfe00707f
#define MATCH_VFNE_AB 0xa2003033
#define MASK_VFNE_AB  0xfe00707f
#define MATCH_VFNE_R_AB 0xa2007033
#define MASK_VFNE_R_AB  0xfe00707f
#define MATCH_VFLT_AB 0xa4003033
#define MASK_VFLT_AB  0xfe00707f
#define MATCH_VFLT_R_AB 0xa4007033
#define MASK_VFLT_R_AB  0xfe00707f
#define MATCH_VFGE_AB 0xa6003033
#define MASK_VFGE_AB  0xfe00707f
#define MATCH_VFGE_R_AB 0xa6007033
#define MASK_VFGE_R_AB  0xfe00707f
#define MATCH_VFLE_AB 0xa8003033
#define MASK_VFLE_AB  0xfe00707f
#define MATCH_VFLE_R_AB 0xa8007033
#define MASK_VFLE_R_AB  0xfe00707f
#define MATCH_VFGT_AB 0xaa003033
#define MASK_VFGT_AB  0xfe00707f
#define MATCH_VFGT_R_AB 0xaa007033
#define MASK_VFGT_R_AB  0xfe00707f
#define MATCH_VFMV_X_AB 0x98003033
#define MASK_VFMV_X_AB  0xfff0707f
#define MATCH_VFMV_AB_X 0x98007033
#define MASK_VFMV_AB_X  0xfff0707f
#define MATCH_VFCLASS_AB 0x98103033
#define MASK_VFCLASS_AB  0xfff0707f
#define MATCH_VFCVT_X_AB 0x98203033
#define MASK_VFCVT_X_AB  0xfff0707f
#define MATCH_VFCVT_XU_AB 0x98207033
#define MASK_VFCVT_XU_AB  0xfff0707f
#define MATCH_VFCVT_AB_X 0x98303033
#define MASK_VFCVT_AB_X  0xfff0707f
#define MATCH_VFCVT_AB_XU 0x98307033
#define MASK_VFCVT_AB_XU  0xfff0707f
#define MATCH_VFCPKA_AB_S 0xb0003033
#define MASK_VFCPKA_AB_S  0xfe00707f
#define MATCH_VFCPKB_AB_S 0xb0007033
#define MASK_VFCPKB_AB_S  0xfe00707f
#define MATCH_VFCPKC_AB_S 0xb2003033
#define MASK_VFCPKC_AB_S  0xfe00707f
#define MATCH_VFCPKD_AB_S 0xb2007033
#define MASK_VFCPKD_AB_S  0xfe00707f
#define MATCH_VFCPKA_AB_D 0xb4003033
#define MASK_VFCPKA_AB_D  0xfe00707f
#define MATCH_VFCPKB_AB_D 0xb4007033
#define MASK_VFCPKB_AB_D  0xfe00707f
#define MATCH_VFCPKC_AB_D 0xb6003033
#define MASK_VFCPKC_AB_D  0xfe00707f
#define MATCH_VFCPKD_AB_D 0xb6007033
#define MASK_VFCPKD_AB_D  0xfe00707f
#define MATCH_VFCVT_S_AB 0x98700033
#define MASK_VFCVT_S_AB  0xfff0707f
#define MATCH_VFCVTU_S_AB 0x98704033
#define MASK_VFCVTU_S_AB  0xfff0707f
#define MATCH_VFCVT_AB_S 0x98403033
#define MASK_VFCVT_AB_S  0xfff0707f
#define MATCH_VFCVTU_AB_S 0x98407033
#define MASK_VFCVTU_AB_S  0xfff0707f
#define MATCH_VFCVT_H_AB 0x98702033
#define MASK_VFCVT_H_AB  0xfff0707f
#define MATCH_VFCVTU_H_AB 0x98706033
#define MASK_VFCVTU_H_AB  0xfff0707f
#define MATCH_VFCVT_AB_H 0x98603033
#define MASK_VFCVT_AB_H  0xfff0707f
#define MATCH_VFCVTU_AB_H 0x98607033
#define MASK_VFCVTU_AB_H  0xfff0707f
#define MATCH_VFCVT_AH_AB 0x98702033
#define MASK_VFCVT_AH_AB  0xfff0707f
#define MATCH_VFCVTU_AH_AB 0x98706033
#define MASK_VFCVTU_AH_AB  0xfff0707f
#define MATCH_VFCVT_AB_AH 0x98603033
#define MASK_VFCVT_AB_AH  0xfff0707f
#define MATCH_VFCVTU_AB_AH 0x98607033
#define MASK_VFCVTU_AB_AH  0xfff0707f
#define MATCH_FMULEX_S_H 0x4c000053
#define MASK_FMULEX_S_H  0xfe00007f
#define MATCH_FMACEX_S_H 0x54000053
#define MASK_FMACEX_S_H  0xfe00007f
#define MATCH_FMULEX_S_AH 0x4c000053
#define MASK_FMULEX_S_AH  0xfe00007f
#define MATCH_FMACEX_S_AH 0x54000053
#define MASK_FMACEX_S_AH  0xfe00007f
#define MATCH_FMULEX_S_B 0x4e000053
#define MASK_FMULEX_S_B  0xfe00007f
#define MATCH_FMACEX_S_B 0x56000053
#define MASK_FMACEX_S_B  0xfe00007f
#define MATCH_FMULEX_S_AB 0x4e000053
#define MASK_FMULEX_S_AB  0xfe00007f
#define MATCH_FMACEX_S_AB 0x56000053
#define MASK_FMACEX_S_AB  0xfe00007f
#define MATCH_VFSUM_S 0x8fc00033
#define MASK_VFSUM_S  0xfff0707f
#define MATCH_VFNSUM_S 0xafc00033
#define MASK_VFNSUM_S  0xfff0707f
#define MATCH_VFSUM_H 0x8fe02033
#define MASK_VFSUM_H  0xfff0707f
#define MATCH_VFNSUM_H 0xafe02033
#define MASK_VFNSUM_H  0xfff0707f
#define MATCH_VFSUM_AH 0x8fe02033
#define MASK_VFSUM_AH  0xfff0707f
#define MATCH_VFNSUM_AH 0xafe02033
#define MASK_VFNSUM_AH  0xfff0707f
#define MATCH_VFSUM_B 0x8e703033
#define MASK_VFSUM_B  0xfff0707f
#define MATCH_VFNSUM_B 0xae703033
#define MASK_VFNSUM_B  0xfff0707f
#define MATCH_VFSUM_AB 0x8e703033
#define MASK_VFSUM_AB  0xfff0707f
#define MATCH_VFNSUM_AB 0xae703033
#define MASK_VFNSUM_AB  0xfff0707f
#define MATCH_VFSUMEX_S_H 0x8f600033
#define MASK_VFSUMEX_S_H  0xfff0707f
#define MATCH_VFNSUMEX_S_H 0xaf600033
#define MASK_VFNSUMEX_S_H  0xfff0707f
#define MATCH_VFDOTPEX_S_H 0x96000033
#define MASK_VFDOTPEX_S_H  0xfe00707f
#define MATCH_VFDOTPEX_S_R_H 0x96004033
#define MASK_VFDOTPEX_S_R_H  0xfe00707f
#define MATCH_VFNDOTPEX_S_H 0xba000033
#define MASK_VFNDOTPEX_S_H  0xfe00707f
#define MATCH_VFNDOTPEX_S_R_H 0xba004033
#define MASK_VFNDOTPEX_S_R_H  0xfe00707f
#define MATCH_VFSUMEX_S_AH 0x8f600033
#define MASK_VFSUMEX_S_AH  0xfff0707f
#define MATCH_VFNSUMEX_S_AH 0xaf600033
#define MASK_VFNSUMEX_S_AH  0xfff0707f
#define MATCH_VFDOTPEX_S_AH 0x96000033
#define MASK_VFDOTPEX_S_AH  0xfe00707f
#define MATCH_VFDOTPEX_S_R_AH 0x96004033
#define MASK_VFDOTPEX_S_R_AH  0xfe00707f
#define MATCH_VFNDOTPEX_S_AH 0xba000033
#define MASK_VFNDOTPEX_S_AH  0xfe00707f
#define MATCH_VFNDOTPEX_S_R_AH 0xba004033
#define MASK_VFNDOTPEX_S_R_AH  0xfe00707f
#define MATCH_VFSUMEX_H_B 0x8f702033
#define MASK_VFSUMEX_H_B  0xfff0707f
#define MATCH_VFNSUMEX_H_B 0xaf702033
#define MASK_VFNSUMEX_H_B  0xfff0707f
#define MATCH_VFDOTPEX_H_B 0x96002033
#define MASK_VFDOTPEX_H_B  0xfe00707f
#define MATCH_VFDOTPEX_H_R_B 0x96006033
#define MASK_VFDOTPEX_H_R_B  0xfe00707f
#define MATCH_VFNDOTPEX_H_B 0xba002033
#define MASK_VFNDOTPEX_H_B  0xfe00707f
#define MATCH_VFNDOTPEX_H_R_B 0xba006033
#define MASK_VFNDOTPEX_H_R_B  0xfe00707f
#define MATCH_VFSUMEX_AH_B 0x8f702033
#define MASK_VFSUMEX_AH_B  0xfff0707f
#define MATCH_VFNSUMEX_AH_B 0xaf702033
#define MASK_VFNSUMEX_AH_B  0xfff0707f
#define MATCH_VFDOTPEX_AH_B 0x96002033
#define MASK_VFDOTPEX_AH_B  0xfe00707f
#define MATCH_VFDOTPEX_AH_R_B 0x96006033
#define MASK_VFDOTPEX_AH_R_B  0xfe00707f
#define MATCH_VFNDOTPEX_AH_B 0xba002033
#define MASK_VFNDOTPEX_AH_B  0xfe00707f
#define MATCH_VFNDOTPEX_AH_R_B 0xba006033
#define MASK_VFNDOTPEX_AH_R_B  0xfe00707f
#define MATCH_VFSUMEX_H_AB 0x8f702033
#define MASK_VFSUMEX_H_AB  0xfff0707f
#define MATCH_VFNSUMEX_H_AB 0xaf702033
#define MASK_VFNSUMEX_H_AB  0xfff0707f
#define MATCH_VFDOTPEX_H_AB 0x96002033
#define MASK_VFDOTPEX_H_AB  0xfe00707f
#define MATCH_VFDOTPEX_H_R_AB 0x96006033
#define MASK_VFDOTPEX_H_R_AB  0xfe00707f
#define MATCH_VFNDOTPEX_H_AB 0xba002033
#define MASK_VFNDOTPEX_H_AB  0xfe00707f
#define MATCH_VFNDOTPEX_H_R_AB 0xba006033
#define MASK_VFNDOTPEX_H_R_AB  0xfe00707f
#define MATCH_VFSUMEX_AH_AB 0x8f702033
#define MASK_VFSUMEX_AH_AB  0xfff0707f
#define MATCH_VFNSUMEX_AH_AB 0xaf702033
#define MASK_VFNSUMEX_AH_AB  0xfff0707f
#define MATCH_VFDOTPEX_AH_AB 0x96002033
#define MASK_VFDOTPEX_AH_AB  0xfe00707f
#define MATCH_VFDOTPEX_AH_R_AB 0x96006033
#define MASK_VFDOTPEX_AH_R_AB  0xfe00707f
#define MATCH_VFNDOTPEX_AH_AB 0xba002033
#define MASK_VFNDOTPEX_AH_AB  0xfe00707f
#define MATCH_VFNDOTPEX_AH_R_AB 0xba006033
#define MASK_VFNDOTPEX_AH_R_AB  0xfe00707f
#define MATCH_DMSRC 0x2b
#define MASK_DMSRC  0xfe007fff
#define MATCH_DMDST 0x200002b
#define MASK_DMDST  0xfe007fff
#define MATCH_DMCPYI 0x400002b
#define MASK_DMCPYI  0xfe00707f
#define MATCH_DMCPY 0x600002b
#define MASK_DMCPY  0xfe00707f
#define MATCH_DMSTATI 0x800002b
#define MASK_DMSTATI  0xfe0ff07f
#define MATCH_DMSTAT 0xa00002b
#define MASK_DMSTAT  0xfe0ff07f
#define MATCH_DMSTR 0xc00002b
#define MASK_DMSTR  0xfe007fff
#define MATCH_DMREP 0xe00002b
#define MASK_DMREP  0xfff07fff
#define MATCH_SCFGRI 0x102b
#define MASK_SCFGRI  0xff07f
#define MATCH_SCFGWI 0x202b
#define MASK_SCFGWI  0x7fff
#define MATCH_SCFGR 0x902b
#define MASK_SCFGR  0xfe0ff07f
#define MATCH_SCFGW 0x20ab
#define MASK_SCFGW  0xfe007fff
#define CSR_FFLAGS 0x1
#define CSR_FRM 0x2
#define CSR_FCSR 0x3
#define CSR_FMODE 0x800
#define CSR_CYCLE 0xc00
#define CSR_TIME 0xc01
#define CSR_INSTRET 0xc02
#define CSR_HPMCOUNTER3 0xc03
#define CSR_HPMCOUNTER4 0xc04
#define CSR_HPMCOUNTER5 0xc05
#define CSR_HPMCOUNTER6 0xc06
#define CSR_HPMCOUNTER7 0xc07
#define CSR_HPMCOUNTER8 0xc08
#define CSR_HPMCOUNTER9 0xc09
#define CSR_HPMCOUNTER10 0xc0a
#define CSR_HPMCOUNTER11 0xc0b
#define CSR_HPMCOUNTER12 0xc0c
#define CSR_HPMCOUNTER13 0xc0d
#define CSR_HPMCOUNTER14 0xc0e
#define CSR_HPMCOUNTER15 0xc0f
#define CSR_HPMCOUNTER16 0xc10
#define CSR_HPMCOUNTER17 0xc11
#define CSR_HPMCOUNTER18 0xc12
#define CSR_HPMCOUNTER19 0xc13
#define CSR_HPMCOUNTER20 0xc14
#define CSR_HPMCOUNTER21 0xc15
#define CSR_HPMCOUNTER22 0xc16
#define CSR_HPMCOUNTER23 0xc17
#define CSR_HPMCOUNTER24 0xc18
#define CSR_HPMCOUNTER25 0xc19
#define CSR_HPMCOUNTER26 0xc1a
#define CSR_HPMCOUNTER27 0xc1b
#define CSR_HPMCOUNTER28 0xc1c
#define CSR_HPMCOUNTER29 0xc1d
#define CSR_HPMCOUNTER30 0xc1e
#define CSR_HPMCOUNTER31 0xc1f
#define CSR_SSTATUS 0x100
#define CSR_SIE 0x104
#define CSR_STVEC 0x105
#define CSR_SCOUNTEREN 0x106
#define CSR_SSCRATCH 0x140
#define CSR_SEPC 0x141
#define CSR_SCAUSE 0x142
#define CSR_STVAL 0x143
#define CSR_SIP 0x144
#define CSR_SATP 0x180
#define CSR_BSSTATUS 0x200
#define CSR_BSIE 0x204
#define CSR_BSTVEC 0x205
#define CSR_BSSCRATCH 0x240
#define CSR_BSEPC 0x241
#define CSR_BSCAUSE 0x242
#define CSR_BSTVAL 0x243
#define CSR_BSIP 0x244
#define CSR_BSATP 0x280
#define CSR_HSTATUS 0xa00
#define CSR_HEDELEG 0xa02
#define CSR_HIDELEG 0xa03
#define CSR_HGATP 0xa80
#define CSR_UTVT 0x7
#define CSR_UNXTI 0x45
#define CSR_UINTSTATUS 0x46
#define CSR_USCRATCHCSW 0x48
#define CSR_USCRATCHCSWL 0x49
#define CSR_STVT 0x107
#define CSR_SNXTI 0x145
#define CSR_SINTSTATUS 0x146
#define CSR_SSCRATCHCSW 0x148
#define CSR_SSCRATCHCSWL 0x149
#define CSR_MTVT 0x307
#define CSR_MNXTI 0x345
#define CSR_MINTSTATUS 0x346
#define CSR_MSCRATCHCSW 0x348
#define CSR_MSCRATCHCSWL 0x349
#define CSR_MSTATUS 0x300
#define CSR_MISA 0x301
#define CSR_MEDELEG 0x302
#define CSR_MIDELEG 0x303
#define CSR_MIE 0x304
#define CSR_MTVEC 0x305
#define CSR_MCOUNTEREN 0x306
#define CSR_MSCRATCH 0x340
#define CSR_MEPC 0x341
#define CSR_MCAUSE 0x342
#define CSR_MTVAL 0x343
#define CSR_MIP 0x344
#define CSR_PMPCFG0 0x3a0
#define CSR_PMPCFG1 0x3a1
#define CSR_PMPCFG2 0x3a2
#define CSR_PMPCFG3 0x3a3
#define CSR_PMPADDR0 0x3b0
#define CSR_PMPADDR1 0x3b1
#define CSR_PMPADDR2 0x3b2
#define CSR_PMPADDR3 0x3b3
#define CSR_PMPADDR4 0x3b4
#define CSR_PMPADDR5 0x3b5
#define CSR_PMPADDR6 0x3b6
#define CSR_PMPADDR7 0x3b7
#define CSR_PMPADDR8 0x3b8
#define CSR_PMPADDR9 0x3b9
#define CSR_PMPADDR10 0x3ba
#define CSR_PMPADDR11 0x3bb
#define CSR_PMPADDR12 0x3bc
#define CSR_PMPADDR13 0x3bd
#define CSR_PMPADDR14 0x3be
#define CSR_PMPADDR15 0x3bf
#define CSR_TSELECT 0x7a0
#define CSR_TDATA1 0x7a1
#define CSR_TDATA2 0x7a2
#define CSR_TDATA3 0x7a3
#define CSR_DCSR 0x7b0
#define CSR_DPC 0x7b1
#define CSR_DSCRATCH 0x7b2
#define CSR_MCYCLE 0xb00
#define CSR_MINSTRET 0xb02
#define CSR_MHPMCOUNTER3 0xb03
#define CSR_MHPMCOUNTER4 0xb04
#define CSR_MHPMCOUNTER5 0xb05
#define CSR_MHPMCOUNTER6 0xb06
#define CSR_MHPMCOUNTER7 0xb07
#define CSR_MHPMCOUNTER8 0xb08
#define CSR_MHPMCOUNTER9 0xb09
#define CSR_MHPMCOUNTER10 0xb0a
#define CSR_MHPMCOUNTER11 0xb0b
#define CSR_MHPMCOUNTER12 0xb0c
#define CSR_MHPMCOUNTER13 0xb0d
#define CSR_MHPMCOUNTER14 0xb0e
#define CSR_MHPMCOUNTER15 0xb0f
#define CSR_MHPMCOUNTER16 0xb10
#define CSR_MHPMCOUNTER17 0xb11
#define CSR_MHPMCOUNTER18 0xb12
#define CSR_MHPMCOUNTER19 0xb13
#define CSR_MHPMCOUNTER20 0xb14
#define CSR_MHPMCOUNTER21 0xb15
#define CSR_MHPMCOUNTER22 0xb16
#define CSR_MHPMCOUNTER23 0xb17
#define CSR_MHPMCOUNTER24 0xb18
#define CSR_MHPMCOUNTER25 0xb19
#define CSR_MHPMCOUNTER26 0xb1a
#define CSR_MHPMCOUNTER27 0xb1b
#define CSR_MHPMCOUNTER28 0xb1c
#define CSR_MHPMCOUNTER29 0xb1d
#define CSR_MHPMCOUNTER30 0xb1e
#define CSR_MHPMCOUNTER31 0xb1f
#define CSR_MHPMEVENT3 0x323
#define CSR_MHPMEVENT4 0x324
#define CSR_MHPMEVENT5 0x325
#define CSR_MHPMEVENT6 0x326
#define CSR_MHPMEVENT7 0x327
#define CSR_MHPMEVENT8 0x328
#define CSR_MHPMEVENT9 0x329
#define CSR_MHPMEVENT10 0x32a
#define CSR_MHPMEVENT11 0x32b
#define CSR_MHPMEVENT12 0x32c
#define CSR_MHPMEVENT13 0x32d
#define CSR_MHPMEVENT14 0x32e
#define CSR_MHPMEVENT15 0x32f
#define CSR_MHPMEVENT16 0x330
#define CSR_MHPMEVENT17 0x331
#define CSR_MHPMEVENT18 0x332
#define CSR_MHPMEVENT19 0x333
#define CSR_MHPMEVENT20 0x334
#define CSR_MHPMEVENT21 0x335
#define CSR_MHPMEVENT22 0x336
#define CSR_MHPMEVENT23 0x337
#define CSR_MHPMEVENT24 0x338
#define CSR_MHPMEVENT25 0x339
#define CSR_MHPMEVENT26 0x33a
#define CSR_MHPMEVENT27 0x33b
#define CSR_MHPMEVENT28 0x33c
#define CSR_MHPMEVENT29 0x33d
#define CSR_MHPMEVENT30 0x33e
#define CSR_MHPMEVENT31 0x33f
#define CSR_MVENDORID 0xf11
#define CSR_MARCHID 0xf12
#define CSR_MIMPID 0xf13
#define CSR_MHARTID 0xf14
#define CSR_SSR 0x7c0
#define CSR_FPMODE 0x7c1
#define CSR_CYCLEH 0xc80
#define CSR_TIMEH 0xc81
#define CSR_INSTRETH 0xc82
#define CSR_HPMCOUNTER3H 0xc83
#define CSR_HPMCOUNTER4H 0xc84
#define CSR_HPMCOUNTER5H 0xc85
#define CSR_HPMCOUNTER6H 0xc86
#define CSR_HPMCOUNTER7H 0xc87
#define CSR_HPMCOUNTER8H 0xc88
#define CSR_HPMCOUNTER9H 0xc89
#define CSR_HPMCOUNTER10H 0xc8a
#define CSR_HPMCOUNTER11H 0xc8b
#define CSR_HPMCOUNTER12H 0xc8c
#define CSR_HPMCOUNTER13H 0xc8d
#define CSR_HPMCOUNTER14H 0xc8e
#define CSR_HPMCOUNTER15H 0xc8f
#define CSR_HPMCOUNTER16H 0xc90
#define CSR_HPMCOUNTER17H 0xc91
#define CSR_HPMCOUNTER18H 0xc92
#define CSR_HPMCOUNTER19H 0xc93
#define CSR_HPMCOUNTER20H 0xc94
#define CSR_HPMCOUNTER21H 0xc95
#define CSR_HPMCOUNTER22H 0xc96
#define CSR_HPMCOUNTER23H 0xc97
#define CSR_HPMCOUNTER24H 0xc98
#define CSR_HPMCOUNTER25H 0xc99
#define CSR_HPMCOUNTER26H 0xc9a
#define CSR_HPMCOUNTER27H 0xc9b
#define CSR_HPMCOUNTER28H 0xc9c
#define CSR_HPMCOUNTER29H 0xc9d
#define CSR_HPMCOUNTER30H 0xc9e
#define CSR_HPMCOUNTER31H 0xc9f
#define CSR_MCYCLEH 0xb80
#define CSR_MINSTRETH 0xb82
#define CSR_MHPMCOUNTER3H 0xb83
#define CSR_MHPMCOUNTER4H 0xb84
#define CSR_MHPMCOUNTER5H 0xb85
#define CSR_MHPMCOUNTER6H 0xb86
#define CSR_MHPMCOUNTER7H 0xb87
#define CSR_MHPMCOUNTER8H 0xb88
#define CSR_MHPMCOUNTER9H 0xb89
#define CSR_MHPMCOUNTER10H 0xb8a
#define CSR_MHPMCOUNTER11H 0xb8b
#define CSR_MHPMCOUNTER12H 0xb8c
#define CSR_MHPMCOUNTER13H 0xb8d
#define CSR_MHPMCOUNTER14H 0xb8e
#define CSR_MHPMCOUNTER15H 0xb8f
#define CSR_MHPMCOUNTER16H 0xb90
#define CSR_MHPMCOUNTER17H 0xb91
#define CSR_MHPMCOUNTER18H 0xb92
#define CSR_MHPMCOUNTER19H 0xb93
#define CSR_MHPMCOUNTER20H 0xb94
#define CSR_MHPMCOUNTER21H 0xb95
#define CSR_MHPMCOUNTER22H 0xb96
#define CSR_MHPMCOUNTER23H 0xb97
#define CSR_MHPMCOUNTER24H 0xb98
#define CSR_MHPMCOUNTER25H 0xb99
#define CSR_MHPMCOUNTER26H 0xb9a
#define CSR_MHPMCOUNTER27H 0xb9b
#define CSR_MHPMCOUNTER28H 0xb9c
#define CSR_MHPMCOUNTER29H 0xb9d
#define CSR_MHPMCOUNTER30H 0xb9e
#define CSR_MHPMCOUNTER31H 0xb9f
#define CAUSE_MISALIGNED_FETCH 0x0
#define CAUSE_FETCH_ACCESS 0x1
#define CAUSE_ILLEGAL_INSTRUCTION 0x2
#define CAUSE_BREAKPOINT 0x3
#define CAUSE_MISALIGNED_LOAD 0x4
#define CAUSE_LOAD_ACCESS 0x5
#define CAUSE_MISALIGNED_STORE 0x6
#define CAUSE_STORE_ACCESS 0x7
#define CAUSE_USER_ECALL 0x8
#define CAUSE_SUPERVISOR_ECALL 0x9
#define CAUSE_HYPERVISOR_ECALL 0xa
#define CAUSE_MACHINE_ECALL 0xb
#define CAUSE_FETCH_PAGE_FAULT 0xc
#define CAUSE_LOAD_PAGE_FAULT 0xd
#define CAUSE_STORE_PAGE_FAULT 0xf
#endif
#ifdef DECLARE_INSN
DECLARE_INSN(beq, MATCH_BEQ, MASK_BEQ)
DECLARE_INSN(bne, MATCH_BNE, MASK_BNE)
DECLARE_INSN(blt, MATCH_BLT, MASK_BLT)
DECLARE_INSN(bge, MATCH_BGE, MASK_BGE)
DECLARE_INSN(bltu, MATCH_BLTU, MASK_BLTU)
DECLARE_INSN(bgeu, MATCH_BGEU, MASK_BGEU)
DECLARE_INSN(jalr, MATCH_JALR, MASK_JALR)
DECLARE_INSN(jal, MATCH_JAL, MASK_JAL)
DECLARE_INSN(lui, MATCH_LUI, MASK_LUI)
DECLARE_INSN(auipc, MATCH_AUIPC, MASK_AUIPC)
DECLARE_INSN(addi, MATCH_ADDI, MASK_ADDI)
DECLARE_INSN(slli, MATCH_SLLI, MASK_SLLI)
DECLARE_INSN(slti, MATCH_SLTI, MASK_SLTI)
DECLARE_INSN(sltiu, MATCH_SLTIU, MASK_SLTIU)
DECLARE_INSN(xori, MATCH_XORI, MASK_XORI)
DECLARE_INSN(srli, MATCH_SRLI, MASK_SRLI)
DECLARE_INSN(srai, MATCH_SRAI, MASK_SRAI)
DECLARE_INSN(ori, MATCH_ORI, MASK_ORI)
DECLARE_INSN(andi, MATCH_ANDI, MASK_ANDI)
DECLARE_INSN(add, MATCH_ADD, MASK_ADD)
DECLARE_INSN(sub, MATCH_SUB, MASK_SUB)
DECLARE_INSN(sll, MATCH_SLL, MASK_SLL)
DECLARE_INSN(slt, MATCH_SLT, MASK_SLT)
DECLARE_INSN(sltu, MATCH_SLTU, MASK_SLTU)
DECLARE_INSN(xor, MATCH_XOR, MASK_XOR)
DECLARE_INSN(srl, MATCH_SRL, MASK_SRL)
DECLARE_INSN(sra, MATCH_SRA, MASK_SRA)
DECLARE_INSN(or, MATCH_OR, MASK_OR)
DECLARE_INSN(and, MATCH_AND, MASK_AND)
DECLARE_INSN(addiw, MATCH_ADDIW, MASK_ADDIW)
DECLARE_INSN(slliw, MATCH_SLLIW, MASK_SLLIW)
DECLARE_INSN(srliw, MATCH_SRLIW, MASK_SRLIW)
DECLARE_INSN(sraiw, MATCH_SRAIW, MASK_SRAIW)
DECLARE_INSN(addw, MATCH_ADDW, MASK_ADDW)
DECLARE_INSN(subw, MATCH_SUBW, MASK_SUBW)
DECLARE_INSN(sllw, MATCH_SLLW, MASK_SLLW)
DECLARE_INSN(srlw, MATCH_SRLW, MASK_SRLW)
DECLARE_INSN(sraw, MATCH_SRAW, MASK_SRAW)
DECLARE_INSN(lb, MATCH_LB, MASK_LB)
DECLARE_INSN(lh, MATCH_LH, MASK_LH)
DECLARE_INSN(lw, MATCH_LW, MASK_LW)
DECLARE_INSN(ld, MATCH_LD, MASK_LD)
DECLARE_INSN(lbu, MATCH_LBU, MASK_LBU)
DECLARE_INSN(lhu, MATCH_LHU, MASK_LHU)
DECLARE_INSN(lwu, MATCH_LWU, MASK_LWU)
DECLARE_INSN(sb, MATCH_SB, MASK_SB)
DECLARE_INSN(sh, MATCH_SH, MASK_SH)
DECLARE_INSN(sw, MATCH_SW, MASK_SW)
DECLARE_INSN(sd, MATCH_SD, MASK_SD)
DECLARE_INSN(fence, MATCH_FENCE, MASK_FENCE)
DECLARE_INSN(fence_i, MATCH_FENCE_I, MASK_FENCE_I)
DECLARE_INSN(mul, MATCH_MUL, MASK_MUL)
DECLARE_INSN(mulh, MATCH_MULH, MASK_MULH)
DECLARE_INSN(mulhsu, MATCH_MULHSU, MASK_MULHSU)
DECLARE_INSN(mulhu, MATCH_MULHU, MASK_MULHU)
DECLARE_INSN(div, MATCH_DIV, MASK_DIV)
DECLARE_INSN(divu, MATCH_DIVU, MASK_DIVU)
DECLARE_INSN(rem, MATCH_REM, MASK_REM)
DECLARE_INSN(remu, MATCH_REMU, MASK_REMU)
DECLARE_INSN(mulw, MATCH_MULW, MASK_MULW)
DECLARE_INSN(divw, MATCH_DIVW, MASK_DIVW)
DECLARE_INSN(divuw, MATCH_DIVUW, MASK_DIVUW)
DECLARE_INSN(remw, MATCH_REMW, MASK_REMW)
DECLARE_INSN(remuw, MATCH_REMUW, MASK_REMUW)
DECLARE_INSN(amoadd_w, MATCH_AMOADD_W, MASK_AMOADD_W)
DECLARE_INSN(amoxor_w, MATCH_AMOXOR_W, MASK_AMOXOR_W)
DECLARE_INSN(amoor_w, MATCH_AMOOR_W, MASK_AMOOR_W)
DECLARE_INSN(amoand_w, MATCH_AMOAND_W, MASK_AMOAND_W)
DECLARE_INSN(amomin_w, MATCH_AMOMIN_W, MASK_AMOMIN_W)
DECLARE_INSN(amomax_w, MATCH_AMOMAX_W, MASK_AMOMAX_W)
DECLARE_INSN(amominu_w, MATCH_AMOMINU_W, MASK_AMOMINU_W)
DECLARE_INSN(amomaxu_w, MATCH_AMOMAXU_W, MASK_AMOMAXU_W)
DECLARE_INSN(amoswap_w, MATCH_AMOSWAP_W, MASK_AMOSWAP_W)
DECLARE_INSN(lr_w, MATCH_LR_W, MASK_LR_W)
DECLARE_INSN(sc_w, MATCH_SC_W, MASK_SC_W)
DECLARE_INSN(amoadd_d, MATCH_AMOADD_D, MASK_AMOADD_D)
DECLARE_INSN(amoxor_d, MATCH_AMOXOR_D, MASK_AMOXOR_D)
DECLARE_INSN(amoor_d, MATCH_AMOOR_D, MASK_AMOOR_D)
DECLARE_INSN(amoand_d, MATCH_AMOAND_D, MASK_AMOAND_D)
DECLARE_INSN(amomin_d, MATCH_AMOMIN_D, MASK_AMOMIN_D)
DECLARE_INSN(amomax_d, MATCH_AMOMAX_D, MASK_AMOMAX_D)
DECLARE_INSN(amominu_d, MATCH_AMOMINU_D, MASK_AMOMINU_D)
DECLARE_INSN(amomaxu_d, MATCH_AMOMAXU_D, MASK_AMOMAXU_D)
DECLARE_INSN(amoswap_d, MATCH_AMOSWAP_D, MASK_AMOSWAP_D)
DECLARE_INSN(lr_d, MATCH_LR_D, MASK_LR_D)
DECLARE_INSN(sc_d, MATCH_SC_D, MASK_SC_D)
DECLARE_INSN(ecall, MATCH_ECALL, MASK_ECALL)
DECLARE_INSN(ebreak, MATCH_EBREAK, MASK_EBREAK)
DECLARE_INSN(uret, MATCH_URET, MASK_URET)
DECLARE_INSN(sret, MATCH_SRET, MASK_SRET)
DECLARE_INSN(mret, MATCH_MRET, MASK_MRET)
DECLARE_INSN(dret, MATCH_DRET, MASK_DRET)
DECLARE_INSN(sfence_vma, MATCH_SFENCE_VMA, MASK_SFENCE_VMA)
DECLARE_INSN(wfi, MATCH_WFI, MASK_WFI)
DECLARE_INSN(csrrw, MATCH_CSRRW, MASK_CSRRW)
DECLARE_INSN(csrrs, MATCH_CSRRS, MASK_CSRRS)
DECLARE_INSN(csrrc, MATCH_CSRRC, MASK_CSRRC)
DECLARE_INSN(csrrwi, MATCH_CSRRWI, MASK_CSRRWI)
DECLARE_INSN(csrrsi, MATCH_CSRRSI, MASK_CSRRSI)
DECLARE_INSN(csrrci, MATCH_CSRRCI, MASK_CSRRCI)
DECLARE_INSN(fadd_s, MATCH_FADD_S, MASK_FADD_S)
DECLARE_INSN(fsub_s, MATCH_FSUB_S, MASK_FSUB_S)
DECLARE_INSN(fmul_s, MATCH_FMUL_S, MASK_FMUL_S)
DECLARE_INSN(fdiv_s, MATCH_FDIV_S, MASK_FDIV_S)
DECLARE_INSN(fsgnj_s, MATCH_FSGNJ_S, MASK_FSGNJ_S)
DECLARE_INSN(fsgnjn_s, MATCH_FSGNJN_S, MASK_FSGNJN_S)
DECLARE_INSN(fsgnjx_s, MATCH_FSGNJX_S, MASK_FSGNJX_S)
DECLARE_INSN(fmin_s, MATCH_FMIN_S, MASK_FMIN_S)
DECLARE_INSN(fmax_s, MATCH_FMAX_S, MASK_FMAX_S)
DECLARE_INSN(fsqrt_s, MATCH_FSQRT_S, MASK_FSQRT_S)
DECLARE_INSN(fadd_d, MATCH_FADD_D, MASK_FADD_D)
DECLARE_INSN(fsub_d, MATCH_FSUB_D, MASK_FSUB_D)
DECLARE_INSN(fmul_d, MATCH_FMUL_D, MASK_FMUL_D)
DECLARE_INSN(fdiv_d, MATCH_FDIV_D, MASK_FDIV_D)
DECLARE_INSN(fsgnj_d, MATCH_FSGNJ_D, MASK_FSGNJ_D)
DECLARE_INSN(fsgnjn_d, MATCH_FSGNJN_D, MASK_FSGNJN_D)
DECLARE_INSN(fsgnjx_d, MATCH_FSGNJX_D, MASK_FSGNJX_D)
DECLARE_INSN(fmin_d, MATCH_FMIN_D, MASK_FMIN_D)
DECLARE_INSN(fmax_d, MATCH_FMAX_D, MASK_FMAX_D)
DECLARE_INSN(fcvt_s_d, MATCH_FCVT_S_D, MASK_FCVT_S_D)
DECLARE_INSN(fcvt_d_s, MATCH_FCVT_D_S, MASK_FCVT_D_S)
DECLARE_INSN(fsqrt_d, MATCH_FSQRT_D, MASK_FSQRT_D)
DECLARE_INSN(fadd_q, MATCH_FADD_Q, MASK_FADD_Q)
DECLARE_INSN(fsub_q, MATCH_FSUB_Q, MASK_FSUB_Q)
DECLARE_INSN(fmul_q, MATCH_FMUL_Q, MASK_FMUL_Q)
DECLARE_INSN(fdiv_q, MATCH_FDIV_Q, MASK_FDIV_Q)
DECLARE_INSN(fsgnj_q, MATCH_FSGNJ_Q, MASK_FSGNJ_Q)
DECLARE_INSN(fsgnjn_q, MATCH_FSGNJN_Q, MASK_FSGNJN_Q)
DECLARE_INSN(fsgnjx_q, MATCH_FSGNJX_Q, MASK_FSGNJX_Q)
DECLARE_INSN(fmin_q, MATCH_FMIN_Q, MASK_FMIN_Q)
DECLARE_INSN(fmax_q, MATCH_FMAX_Q, MASK_FMAX_Q)
DECLARE_INSN(fcvt_s_q, MATCH_FCVT_S_Q, MASK_FCVT_S_Q)
DECLARE_INSN(fcvt_q_s, MATCH_FCVT_Q_S, MASK_FCVT_Q_S)
DECLARE_INSN(fcvt_d_q, MATCH_FCVT_D_Q, MASK_FCVT_D_Q)
DECLARE_INSN(fcvt_q_d, MATCH_FCVT_Q_D, MASK_FCVT_Q_D)
DECLARE_INSN(fsqrt_q, MATCH_FSQRT_Q, MASK_FSQRT_Q)
DECLARE_INSN(fle_s, MATCH_FLE_S, MASK_FLE_S)
DECLARE_INSN(flt_s, MATCH_FLT_S, MASK_FLT_S)
DECLARE_INSN(feq_s, MATCH_FEQ_S, MASK_FEQ_S)
DECLARE_INSN(fle_d, MATCH_FLE_D, MASK_FLE_D)
DECLARE_INSN(flt_d, MATCH_FLT_D, MASK_FLT_D)
DECLARE_INSN(feq_d, MATCH_FEQ_D, MASK_FEQ_D)
DECLARE_INSN(fle_q, MATCH_FLE_Q, MASK_FLE_Q)
DECLARE_INSN(flt_q, MATCH_FLT_Q, MASK_FLT_Q)
DECLARE_INSN(feq_q, MATCH_FEQ_Q, MASK_FEQ_Q)
DECLARE_INSN(fcvt_w_s, MATCH_FCVT_W_S, MASK_FCVT_W_S)
DECLARE_INSN(fcvt_wu_s, MATCH_FCVT_WU_S, MASK_FCVT_WU_S)
DECLARE_INSN(fcvt_l_s, MATCH_FCVT_L_S, MASK_FCVT_L_S)
DECLARE_INSN(fcvt_lu_s, MATCH_FCVT_LU_S, MASK_FCVT_LU_S)
DECLARE_INSN(fmv_x_w, MATCH_FMV_X_W, MASK_FMV_X_W)
DECLARE_INSN(fclass_s, MATCH_FCLASS_S, MASK_FCLASS_S)
DECLARE_INSN(fcvt_w_d, MATCH_FCVT_W_D, MASK_FCVT_W_D)
DECLARE_INSN(fcvt_wu_d, MATCH_FCVT_WU_D, MASK_FCVT_WU_D)
DECLARE_INSN(fcvt_l_d, MATCH_FCVT_L_D, MASK_FCVT_L_D)
DECLARE_INSN(fcvt_lu_d, MATCH_FCVT_LU_D, MASK_FCVT_LU_D)
DECLARE_INSN(fmv_x_d, MATCH_FMV_X_D, MASK_FMV_X_D)
DECLARE_INSN(fclass_d, MATCH_FCLASS_D, MASK_FCLASS_D)
DECLARE_INSN(fcvt_w_q, MATCH_FCVT_W_Q, MASK_FCVT_W_Q)
DECLARE_INSN(fcvt_wu_q, MATCH_FCVT_WU_Q, MASK_FCVT_WU_Q)
DECLARE_INSN(fcvt_l_q, MATCH_FCVT_L_Q, MASK_FCVT_L_Q)
DECLARE_INSN(fcvt_lu_q, MATCH_FCVT_LU_Q, MASK_FCVT_LU_Q)
DECLARE_INSN(fmv_x_q, MATCH_FMV_X_Q, MASK_FMV_X_Q)
DECLARE_INSN(fclass_q, MATCH_FCLASS_Q, MASK_FCLASS_Q)
DECLARE_INSN(fcvt_s_w, MATCH_FCVT_S_W, MASK_FCVT_S_W)
DECLARE_INSN(fcvt_s_wu, MATCH_FCVT_S_WU, MASK_FCVT_S_WU)
DECLARE_INSN(fcvt_s_l, MATCH_FCVT_S_L, MASK_FCVT_S_L)
DECLARE_INSN(fcvt_s_lu, MATCH_FCVT_S_LU, MASK_FCVT_S_LU)
DECLARE_INSN(fmv_w_x, MATCH_FMV_W_X, MASK_FMV_W_X)
DECLARE_INSN(fcvt_d_w, MATCH_FCVT_D_W, MASK_FCVT_D_W)
DECLARE_INSN(fcvt_d_wu, MATCH_FCVT_D_WU, MASK_FCVT_D_WU)
DECLARE_INSN(fcvt_d_l, MATCH_FCVT_D_L, MASK_FCVT_D_L)
DECLARE_INSN(fcvt_d_lu, MATCH_FCVT_D_LU, MASK_FCVT_D_LU)
DECLARE_INSN(fmv_d_x, MATCH_FMV_D_X, MASK_FMV_D_X)
DECLARE_INSN(fcvt_q_w, MATCH_FCVT_Q_W, MASK_FCVT_Q_W)
DECLARE_INSN(fcvt_q_wu, MATCH_FCVT_Q_WU, MASK_FCVT_Q_WU)
DECLARE_INSN(fcvt_q_l, MATCH_FCVT_Q_L, MASK_FCVT_Q_L)
DECLARE_INSN(fcvt_q_lu, MATCH_FCVT_Q_LU, MASK_FCVT_Q_LU)
DECLARE_INSN(fmv_q_x, MATCH_FMV_Q_X, MASK_FMV_Q_X)
DECLARE_INSN(flw, MATCH_FLW, MASK_FLW)
DECLARE_INSN(fld, MATCH_FLD, MASK_FLD)
DECLARE_INSN(flq, MATCH_FLQ, MASK_FLQ)
DECLARE_INSN(fsw, MATCH_FSW, MASK_FSW)
DECLARE_INSN(fsd, MATCH_FSD, MASK_FSD)
DECLARE_INSN(fsq, MATCH_FSQ, MASK_FSQ)
DECLARE_INSN(fmadd_s, MATCH_FMADD_S, MASK_FMADD_S)
DECLARE_INSN(fmsub_s, MATCH_FMSUB_S, MASK_FMSUB_S)
DECLARE_INSN(fnmsub_s, MATCH_FNMSUB_S, MASK_FNMSUB_S)
DECLARE_INSN(fnmadd_s, MATCH_FNMADD_S, MASK_FNMADD_S)
DECLARE_INSN(fmadd_d, MATCH_FMADD_D, MASK_FMADD_D)
DECLARE_INSN(fmsub_d, MATCH_FMSUB_D, MASK_FMSUB_D)
DECLARE_INSN(fnmsub_d, MATCH_FNMSUB_D, MASK_FNMSUB_D)
DECLARE_INSN(fnmadd_d, MATCH_FNMADD_D, MASK_FNMADD_D)
DECLARE_INSN(fmadd_q, MATCH_FMADD_Q, MASK_FMADD_Q)
DECLARE_INSN(fmsub_q, MATCH_FMSUB_Q, MASK_FMSUB_Q)
DECLARE_INSN(fnmsub_q, MATCH_FNMSUB_Q, MASK_FNMSUB_Q)
DECLARE_INSN(fnmadd_q, MATCH_FNMADD_Q, MASK_FNMADD_Q)
DECLARE_INSN(c_nop, MATCH_C_NOP, MASK_C_NOP)
DECLARE_INSN(c_addi16sp, MATCH_C_ADDI16SP, MASK_C_ADDI16SP)
DECLARE_INSN(c_jr, MATCH_C_JR, MASK_C_JR)
DECLARE_INSN(c_jalr, MATCH_C_JALR, MASK_C_JALR)
DECLARE_INSN(c_ebreak, MATCH_C_EBREAK, MASK_C_EBREAK)
DECLARE_INSN(c_ld, MATCH_C_LD, MASK_C_LD)
DECLARE_INSN(c_sd, MATCH_C_SD, MASK_C_SD)
DECLARE_INSN(c_addiw, MATCH_C_ADDIW, MASK_C_ADDIW)
DECLARE_INSN(c_ldsp, MATCH_C_LDSP, MASK_C_LDSP)
DECLARE_INSN(c_sdsp, MATCH_C_SDSP, MASK_C_SDSP)
DECLARE_INSN(c_addi4spn, MATCH_C_ADDI4SPN, MASK_C_ADDI4SPN)
DECLARE_INSN(c_fld, MATCH_C_FLD, MASK_C_FLD)
DECLARE_INSN(c_lw, MATCH_C_LW, MASK_C_LW)
DECLARE_INSN(c_flw, MATCH_C_FLW, MASK_C_FLW)
DECLARE_INSN(c_fsd, MATCH_C_FSD, MASK_C_FSD)
DECLARE_INSN(c_sw, MATCH_C_SW, MASK_C_SW)
DECLARE_INSN(c_fsw, MATCH_C_FSW, MASK_C_FSW)
DECLARE_INSN(c_addi, MATCH_C_ADDI, MASK_C_ADDI)
DECLARE_INSN(c_jal, MATCH_C_JAL, MASK_C_JAL)
DECLARE_INSN(c_li, MATCH_C_LI, MASK_C_LI)
DECLARE_INSN(c_lui, MATCH_C_LUI, MASK_C_LUI)
DECLARE_INSN(c_srli, MATCH_C_SRLI, MASK_C_SRLI)
DECLARE_INSN(c_srai, MATCH_C_SRAI, MASK_C_SRAI)
DECLARE_INSN(c_andi, MATCH_C_ANDI, MASK_C_ANDI)
DECLARE_INSN(c_sub, MATCH_C_SUB, MASK_C_SUB)
DECLARE_INSN(c_xor, MATCH_C_XOR, MASK_C_XOR)
DECLARE_INSN(c_or, MATCH_C_OR, MASK_C_OR)
DECLARE_INSN(c_and, MATCH_C_AND, MASK_C_AND)
DECLARE_INSN(c_subw, MATCH_C_SUBW, MASK_C_SUBW)
DECLARE_INSN(c_addw, MATCH_C_ADDW, MASK_C_ADDW)
DECLARE_INSN(c_j, MATCH_C_J, MASK_C_J)
DECLARE_INSN(c_beqz, MATCH_C_BEQZ, MASK_C_BEQZ)
DECLARE_INSN(c_bnez, MATCH_C_BNEZ, MASK_C_BNEZ)
DECLARE_INSN(c_slli, MATCH_C_SLLI, MASK_C_SLLI)
DECLARE_INSN(c_fldsp, MATCH_C_FLDSP, MASK_C_FLDSP)
DECLARE_INSN(c_lwsp, MATCH_C_LWSP, MASK_C_LWSP)
DECLARE_INSN(c_flwsp, MATCH_C_FLWSP, MASK_C_FLWSP)
DECLARE_INSN(c_mv, MATCH_C_MV, MASK_C_MV)
DECLARE_INSN(c_add, MATCH_C_ADD, MASK_C_ADD)
DECLARE_INSN(c_fsdsp, MATCH_C_FSDSP, MASK_C_FSDSP)
DECLARE_INSN(c_swsp, MATCH_C_SWSP, MASK_C_SWSP)
DECLARE_INSN(c_fswsp, MATCH_C_FSWSP, MASK_C_FSWSP)
DECLARE_INSN(frep_o, MATCH_FREP_O, MASK_FREP_O)
DECLARE_INSN(frep_i, MATCH_FREP_I, MASK_FREP_I)
DECLARE_INSN(irep, MATCH_IREP, MASK_IREP)
DECLARE_INSN(flh, MATCH_FLH, MASK_FLH)
DECLARE_INSN(fsh, MATCH_FSH, MASK_FSH)
DECLARE_INSN(fmadd_h, MATCH_FMADD_H, MASK_FMADD_H)
DECLARE_INSN(fmsub_h, MATCH_FMSUB_H, MASK_FMSUB_H)
DECLARE_INSN(fnmsub_h, MATCH_FNMSUB_H, MASK_FNMSUB_H)
DECLARE_INSN(fnmadd_h, MATCH_FNMADD_H, MASK_FNMADD_H)
DECLARE_INSN(fadd_h, MATCH_FADD_H, MASK_FADD_H)
DECLARE_INSN(fsub_h, MATCH_FSUB_H, MASK_FSUB_H)
DECLARE_INSN(fmul_h, MATCH_FMUL_H, MASK_FMUL_H)
DECLARE_INSN(fdiv_h, MATCH_FDIV_H, MASK_FDIV_H)
DECLARE_INSN(fsqrt_h, MATCH_FSQRT_H, MASK_FSQRT_H)
DECLARE_INSN(fsgnj_h, MATCH_FSGNJ_H, MASK_FSGNJ_H)
DECLARE_INSN(fsgnjn_h, MATCH_FSGNJN_H, MASK_FSGNJN_H)
DECLARE_INSN(fsgnjx_h, MATCH_FSGNJX_H, MASK_FSGNJX_H)
DECLARE_INSN(fmin_h, MATCH_FMIN_H, MASK_FMIN_H)
DECLARE_INSN(fmax_h, MATCH_FMAX_H, MASK_FMAX_H)
DECLARE_INSN(feq_h, MATCH_FEQ_H, MASK_FEQ_H)
DECLARE_INSN(flt_h, MATCH_FLT_H, MASK_FLT_H)
DECLARE_INSN(fle_h, MATCH_FLE_H, MASK_FLE_H)
DECLARE_INSN(fcvt_w_h, MATCH_FCVT_W_H, MASK_FCVT_W_H)
DECLARE_INSN(fcvt_wu_h, MATCH_FCVT_WU_H, MASK_FCVT_WU_H)
DECLARE_INSN(fcvt_h_w, MATCH_FCVT_H_W, MASK_FCVT_H_W)
DECLARE_INSN(fcvt_h_wu, MATCH_FCVT_H_WU, MASK_FCVT_H_WU)
DECLARE_INSN(fmv_x_h, MATCH_FMV_X_H, MASK_FMV_X_H)
DECLARE_INSN(fclass_h, MATCH_FCLASS_H, MASK_FCLASS_H)
DECLARE_INSN(fmv_h_x, MATCH_FMV_H_X, MASK_FMV_H_X)
DECLARE_INSN(fcvt_l_h, MATCH_FCVT_L_H, MASK_FCVT_L_H)
DECLARE_INSN(fcvt_lu_h, MATCH_FCVT_LU_H, MASK_FCVT_LU_H)
DECLARE_INSN(fcvt_h_l, MATCH_FCVT_H_L, MASK_FCVT_H_L)
DECLARE_INSN(fcvt_h_lu, MATCH_FCVT_H_LU, MASK_FCVT_H_LU)
DECLARE_INSN(fcvt_s_h, MATCH_FCVT_S_H, MASK_FCVT_S_H)
DECLARE_INSN(fcvt_h_s, MATCH_FCVT_H_S, MASK_FCVT_H_S)
DECLARE_INSN(fcvt_d_h, MATCH_FCVT_D_H, MASK_FCVT_D_H)
DECLARE_INSN(fcvt_h_d, MATCH_FCVT_H_D, MASK_FCVT_H_D)
DECLARE_INSN(flah, MATCH_FLAH, MASK_FLAH)
DECLARE_INSN(fsah, MATCH_FSAH, MASK_FSAH)
DECLARE_INSN(fmadd_ah, MATCH_FMADD_AH, MASK_FMADD_AH)
DECLARE_INSN(fmsub_ah, MATCH_FMSUB_AH, MASK_FMSUB_AH)
DECLARE_INSN(fnmsub_ah, MATCH_FNMSUB_AH, MASK_FNMSUB_AH)
DECLARE_INSN(fnmadd_ah, MATCH_FNMADD_AH, MASK_FNMADD_AH)
DECLARE_INSN(fadd_ah, MATCH_FADD_AH, MASK_FADD_AH)
DECLARE_INSN(fsub_ah, MATCH_FSUB_AH, MASK_FSUB_AH)
DECLARE_INSN(fmul_ah, MATCH_FMUL_AH, MASK_FMUL_AH)
DECLARE_INSN(fdiv_ah, MATCH_FDIV_AH, MASK_FDIV_AH)
DECLARE_INSN(fsqrt_ah, MATCH_FSQRT_AH, MASK_FSQRT_AH)
DECLARE_INSN(fsgnj_ah, MATCH_FSGNJ_AH, MASK_FSGNJ_AH)
DECLARE_INSN(fsgnjn_ah, MATCH_FSGNJN_AH, MASK_FSGNJN_AH)
DECLARE_INSN(fsgnjx_ah, MATCH_FSGNJX_AH, MASK_FSGNJX_AH)
DECLARE_INSN(fmin_ah, MATCH_FMIN_AH, MASK_FMIN_AH)
DECLARE_INSN(fmax_ah, MATCH_FMAX_AH, MASK_FMAX_AH)
DECLARE_INSN(feq_ah, MATCH_FEQ_AH, MASK_FEQ_AH)
DECLARE_INSN(flt_ah, MATCH_FLT_AH, MASK_FLT_AH)
DECLARE_INSN(fle_ah, MATCH_FLE_AH, MASK_FLE_AH)
DECLARE_INSN(fcvt_w_ah, MATCH_FCVT_W_AH, MASK_FCVT_W_AH)
DECLARE_INSN(fcvt_wu_ah, MATCH_FCVT_WU_AH, MASK_FCVT_WU_AH)
DECLARE_INSN(fcvt_ah_w, MATCH_FCVT_AH_W, MASK_FCVT_AH_W)
DECLARE_INSN(fcvt_ah_wu, MATCH_FCVT_AH_WU, MASK_FCVT_AH_WU)
DECLARE_INSN(fmv_x_ah, MATCH_FMV_X_AH, MASK_FMV_X_AH)
DECLARE_INSN(fclass_ah, MATCH_FCLASS_AH, MASK_FCLASS_AH)
DECLARE_INSN(fmv_ah_x, MATCH_FMV_AH_X, MASK_FMV_AH_X)
DECLARE_INSN(fcvt_l_ah, MATCH_FCVT_L_AH, MASK_FCVT_L_AH)
DECLARE_INSN(fcvt_lu_ah, MATCH_FCVT_LU_AH, MASK_FCVT_LU_AH)
DECLARE_INSN(fcvt_ah_l, MATCH_FCVT_AH_L, MASK_FCVT_AH_L)
DECLARE_INSN(fcvt_ah_lu, MATCH_FCVT_AH_LU, MASK_FCVT_AH_LU)
DECLARE_INSN(fcvt_s_ah, MATCH_FCVT_S_AH, MASK_FCVT_S_AH)
DECLARE_INSN(fcvt_ah_s, MATCH_FCVT_AH_S, MASK_FCVT_AH_S)
DECLARE_INSN(fcvt_d_ah, MATCH_FCVT_D_AH, MASK_FCVT_D_AH)
DECLARE_INSN(fcvt_ah_d, MATCH_FCVT_AH_D, MASK_FCVT_AH_D)
DECLARE_INSN(fcvt_h_h, MATCH_FCVT_H_H, MASK_FCVT_H_H)
DECLARE_INSN(fcvt_ah_h, MATCH_FCVT_AH_H, MASK_FCVT_AH_H)
DECLARE_INSN(fcvt_h_ah, MATCH_FCVT_H_AH, MASK_FCVT_H_AH)
DECLARE_INSN(fcvt_ah_ah, MATCH_FCVT_AH_AH, MASK_FCVT_AH_AH)
DECLARE_INSN(flb, MATCH_FLB, MASK_FLB)
DECLARE_INSN(fsb, MATCH_FSB, MASK_FSB)
DECLARE_INSN(fmadd_b, MATCH_FMADD_B, MASK_FMADD_B)
DECLARE_INSN(fmsub_b, MATCH_FMSUB_B, MASK_FMSUB_B)
DECLARE_INSN(fnmsub_b, MATCH_FNMSUB_B, MASK_FNMSUB_B)
DECLARE_INSN(fnmadd_b, MATCH_FNMADD_B, MASK_FNMADD_B)
DECLARE_INSN(fadd_b, MATCH_FADD_B, MASK_FADD_B)
DECLARE_INSN(fsub_b, MATCH_FSUB_B, MASK_FSUB_B)
DECLARE_INSN(fmul_b, MATCH_FMUL_B, MASK_FMUL_B)
DECLARE_INSN(fdiv_b, MATCH_FDIV_B, MASK_FDIV_B)
DECLARE_INSN(fsqrt_b, MATCH_FSQRT_B, MASK_FSQRT_B)
DECLARE_INSN(fsgnj_b, MATCH_FSGNJ_B, MASK_FSGNJ_B)
DECLARE_INSN(fsgnjn_b, MATCH_FSGNJN_B, MASK_FSGNJN_B)
DECLARE_INSN(fsgnjx_b, MATCH_FSGNJX_B, MASK_FSGNJX_B)
DECLARE_INSN(fmin_b, MATCH_FMIN_B, MASK_FMIN_B)
DECLARE_INSN(fmax_b, MATCH_FMAX_B, MASK_FMAX_B)
DECLARE_INSN(feq_b, MATCH_FEQ_B, MASK_FEQ_B)
DECLARE_INSN(flt_b, MATCH_FLT_B, MASK_FLT_B)
DECLARE_INSN(fle_b, MATCH_FLE_B, MASK_FLE_B)
DECLARE_INSN(fcvt_w_b, MATCH_FCVT_W_B, MASK_FCVT_W_B)
DECLARE_INSN(fcvt_wu_b, MATCH_FCVT_WU_B, MASK_FCVT_WU_B)
DECLARE_INSN(fcvt_b_w, MATCH_FCVT_B_W, MASK_FCVT_B_W)
DECLARE_INSN(fcvt_b_wu, MATCH_FCVT_B_WU, MASK_FCVT_B_WU)
DECLARE_INSN(fmv_x_b, MATCH_FMV_X_B, MASK_FMV_X_B)
DECLARE_INSN(fclass_b, MATCH_FCLASS_B, MASK_FCLASS_B)
DECLARE_INSN(fmv_b_x, MATCH_FMV_B_X, MASK_FMV_B_X)
DECLARE_INSN(fcvt_l_b, MATCH_FCVT_L_B, MASK_FCVT_L_B)
DECLARE_INSN(fcvt_lu_b, MATCH_FCVT_LU_B, MASK_FCVT_LU_B)
DECLARE_INSN(fcvt_b_l, MATCH_FCVT_B_L, MASK_FCVT_B_L)
DECLARE_INSN(fcvt_b_lu, MATCH_FCVT_B_LU, MASK_FCVT_B_LU)
DECLARE_INSN(fcvt_s_b, MATCH_FCVT_S_B, MASK_FCVT_S_B)
DECLARE_INSN(fcvt_b_s, MATCH_FCVT_B_S, MASK_FCVT_B_S)
DECLARE_INSN(fcvt_d_b, MATCH_FCVT_D_B, MASK_FCVT_D_B)
DECLARE_INSN(fcvt_b_d, MATCH_FCVT_B_D, MASK_FCVT_B_D)
DECLARE_INSN(fcvt_h_b, MATCH_FCVT_H_B, MASK_FCVT_H_B)
DECLARE_INSN(fcvt_b_h, MATCH_FCVT_B_H, MASK_FCVT_B_H)
DECLARE_INSN(fcvt_ah_b, MATCH_FCVT_AH_B, MASK_FCVT_AH_B)
DECLARE_INSN(fcvt_b_ah, MATCH_FCVT_B_AH, MASK_FCVT_B_AH)
DECLARE_INSN(flab, MATCH_FLAB, MASK_FLAB)
DECLARE_INSN(fsab, MATCH_FSAB, MASK_FSAB)
DECLARE_INSN(fmadd_ab, MATCH_FMADD_AB, MASK_FMADD_AB)
DECLARE_INSN(fmsub_ab, MATCH_FMSUB_AB, MASK_FMSUB_AB)
DECLARE_INSN(fnmsub_ab, MATCH_FNMSUB_AB, MASK_FNMSUB_AB)
DECLARE_INSN(fnmadd_ab, MATCH_FNMADD_AB, MASK_FNMADD_AB)
DECLARE_INSN(fadd_ab, MATCH_FADD_AB, MASK_FADD_AB)
DECLARE_INSN(fsub_ab, MATCH_FSUB_AB, MASK_FSUB_AB)
DECLARE_INSN(fmul_ab, MATCH_FMUL_AB, MASK_FMUL_AB)
DECLARE_INSN(fdiv_ab, MATCH_FDIV_AB, MASK_FDIV_AB)
DECLARE_INSN(fsqrt_ab, MATCH_FSQRT_AB, MASK_FSQRT_AB)
DECLARE_INSN(fsgnj_ab, MATCH_FSGNJ_AB, MASK_FSGNJ_AB)
DECLARE_INSN(fsgnjn_ab, MATCH_FSGNJN_AB, MASK_FSGNJN_AB)
DECLARE_INSN(fsgnjx_ab, MATCH_FSGNJX_AB, MASK_FSGNJX_AB)
DECLARE_INSN(fmin_ab, MATCH_FMIN_AB, MASK_FMIN_AB)
DECLARE_INSN(fmax_ab, MATCH_FMAX_AB, MASK_FMAX_AB)
DECLARE_INSN(feq_ab, MATCH_FEQ_AB, MASK_FEQ_AB)
DECLARE_INSN(flt_ab, MATCH_FLT_AB, MASK_FLT_AB)
DECLARE_INSN(fle_ab, MATCH_FLE_AB, MASK_FLE_AB)
DECLARE_INSN(fcvt_w_ab, MATCH_FCVT_W_AB, MASK_FCVT_W_AB)
DECLARE_INSN(fcvt_wu_ab, MATCH_FCVT_WU_AB, MASK_FCVT_WU_AB)
DECLARE_INSN(fcvt_ab_w, MATCH_FCVT_AB_W, MASK_FCVT_AB_W)
DECLARE_INSN(fcvt_ab_wu, MATCH_FCVT_AB_WU, MASK_FCVT_AB_WU)
DECLARE_INSN(fmv_x_ab, MATCH_FMV_X_AB, MASK_FMV_X_AB)
DECLARE_INSN(fclass_ab, MATCH_FCLASS_AB, MASK_FCLASS_AB)
DECLARE_INSN(fmv_ab_x, MATCH_FMV_AB_X, MASK_FMV_AB_X)
DECLARE_INSN(fcvt_l_ab, MATCH_FCVT_L_AB, MASK_FCVT_L_AB)
DECLARE_INSN(fcvt_lu_ab, MATCH_FCVT_LU_AB, MASK_FCVT_LU_AB)
DECLARE_INSN(fcvt_ab_l, MATCH_FCVT_AB_L, MASK_FCVT_AB_L)
DECLARE_INSN(fcvt_ab_lu, MATCH_FCVT_AB_LU, MASK_FCVT_AB_LU)
DECLARE_INSN(fcvt_s_ab, MATCH_FCVT_S_AB, MASK_FCVT_S_AB)
DECLARE_INSN(fcvt_ab_s, MATCH_FCVT_AB_S, MASK_FCVT_AB_S)
DECLARE_INSN(fcvt_d_ab, MATCH_FCVT_D_AB, MASK_FCVT_D_AB)
DECLARE_INSN(fcvt_ab_d, MATCH_FCVT_AB_D, MASK_FCVT_AB_D)
DECLARE_INSN(fcvt_h_ab, MATCH_FCVT_H_AB, MASK_FCVT_H_AB)
DECLARE_INSN(fcvt_ab_h, MATCH_FCVT_AB_H, MASK_FCVT_AB_H)
DECLARE_INSN(fcvt_ah_ab, MATCH_FCVT_AH_AB, MASK_FCVT_AH_AB)
DECLARE_INSN(fcvt_ab_ah, MATCH_FCVT_AB_AH, MASK_FCVT_AB_AH)
DECLARE_INSN(fcvt_b_b, MATCH_FCVT_B_B, MASK_FCVT_B_B)
DECLARE_INSN(fcvt_ab_b, MATCH_FCVT_AB_B, MASK_FCVT_AB_B)
DECLARE_INSN(fcvt_b_ab, MATCH_FCVT_B_AB, MASK_FCVT_B_AB)
DECLARE_INSN(fcvt_ab_ab, MATCH_FCVT_AB_AB, MASK_FCVT_AB_AB)
DECLARE_INSN(vfadd_s, MATCH_VFADD_S, MASK_VFADD_S)
DECLARE_INSN(vfadd_r_s, MATCH_VFADD_R_S, MASK_VFADD_R_S)
DECLARE_INSN(vfsub_s, MATCH_VFSUB_S, MASK_VFSUB_S)
DECLARE_INSN(vfsub_r_s, MATCH_VFSUB_R_S, MASK_VFSUB_R_S)
DECLARE_INSN(vfmul_s, MATCH_VFMUL_S, MASK_VFMUL_S)
DECLARE_INSN(vfmul_r_s, MATCH_VFMUL_R_S, MASK_VFMUL_R_S)
DECLARE_INSN(vfdiv_s, MATCH_VFDIV_S, MASK_VFDIV_S)
DECLARE_INSN(vfdiv_r_s, MATCH_VFDIV_R_S, MASK_VFDIV_R_S)
DECLARE_INSN(vfmin_s, MATCH_VFMIN_S, MASK_VFMIN_S)
DECLARE_INSN(vfmin_r_s, MATCH_VFMIN_R_S, MASK_VFMIN_R_S)
DECLARE_INSN(vfmax_s, MATCH_VFMAX_S, MASK_VFMAX_S)
DECLARE_INSN(vfmax_r_s, MATCH_VFMAX_R_S, MASK_VFMAX_R_S)
DECLARE_INSN(vfsqrt_s, MATCH_VFSQRT_S, MASK_VFSQRT_S)
DECLARE_INSN(vfmac_s, MATCH_VFMAC_S, MASK_VFMAC_S)
DECLARE_INSN(vfmac_r_s, MATCH_VFMAC_R_S, MASK_VFMAC_R_S)
DECLARE_INSN(vfmre_s, MATCH_VFMRE_S, MASK_VFMRE_S)
DECLARE_INSN(vfmre_r_s, MATCH_VFMRE_R_S, MASK_VFMRE_R_S)
DECLARE_INSN(vfclass_s, MATCH_VFCLASS_S, MASK_VFCLASS_S)
DECLARE_INSN(vfsgnj_s, MATCH_VFSGNJ_S, MASK_VFSGNJ_S)
DECLARE_INSN(vfsgnj_r_s, MATCH_VFSGNJ_R_S, MASK_VFSGNJ_R_S)
DECLARE_INSN(vfsgnjn_s, MATCH_VFSGNJN_S, MASK_VFSGNJN_S)
DECLARE_INSN(vfsgnjn_r_s, MATCH_VFSGNJN_R_S, MASK_VFSGNJN_R_S)
DECLARE_INSN(vfsgnjx_s, MATCH_VFSGNJX_S, MASK_VFSGNJX_S)
DECLARE_INSN(vfsgnjx_r_s, MATCH_VFSGNJX_R_S, MASK_VFSGNJX_R_S)
DECLARE_INSN(vfeq_s, MATCH_VFEQ_S, MASK_VFEQ_S)
DECLARE_INSN(vfeq_r_s, MATCH_VFEQ_R_S, MASK_VFEQ_R_S)
DECLARE_INSN(vfne_s, MATCH_VFNE_S, MASK_VFNE_S)
DECLARE_INSN(vfne_r_s, MATCH_VFNE_R_S, MASK_VFNE_R_S)
DECLARE_INSN(vflt_s, MATCH_VFLT_S, MASK_VFLT_S)
DECLARE_INSN(vflt_r_s, MATCH_VFLT_R_S, MASK_VFLT_R_S)
DECLARE_INSN(vfge_s, MATCH_VFGE_S, MASK_VFGE_S)
DECLARE_INSN(vfge_r_s, MATCH_VFGE_R_S, MASK_VFGE_R_S)
DECLARE_INSN(vfle_s, MATCH_VFLE_S, MASK_VFLE_S)
DECLARE_INSN(vfle_r_s, MATCH_VFLE_R_S, MASK_VFLE_R_S)
DECLARE_INSN(vfgt_s, MATCH_VFGT_S, MASK_VFGT_S)
DECLARE_INSN(vfgt_r_s, MATCH_VFGT_R_S, MASK_VFGT_R_S)
DECLARE_INSN(vfmv_x_s, MATCH_VFMV_X_S, MASK_VFMV_X_S)
DECLARE_INSN(vfmv_s_x, MATCH_VFMV_S_X, MASK_VFMV_S_X)
DECLARE_INSN(vfcvt_x_s, MATCH_VFCVT_X_S, MASK_VFCVT_X_S)
DECLARE_INSN(vfcvt_xu_s, MATCH_VFCVT_XU_S, MASK_VFCVT_XU_S)
DECLARE_INSN(vfcvt_s_x, MATCH_VFCVT_S_X, MASK_VFCVT_S_X)
DECLARE_INSN(vfcvt_s_xu, MATCH_VFCVT_S_XU, MASK_VFCVT_S_XU)
DECLARE_INSN(vfcpka_s_s, MATCH_VFCPKA_S_S, MASK_VFCPKA_S_S)
DECLARE_INSN(vfcpkb_s_s, MATCH_VFCPKB_S_S, MASK_VFCPKB_S_S)
DECLARE_INSN(vfcpkc_s_s, MATCH_VFCPKC_S_S, MASK_VFCPKC_S_S)
DECLARE_INSN(vfcpkd_s_s, MATCH_VFCPKD_S_S, MASK_VFCPKD_S_S)
DECLARE_INSN(vfcpka_s_d, MATCH_VFCPKA_S_D, MASK_VFCPKA_S_D)
DECLARE_INSN(vfcpkb_s_d, MATCH_VFCPKB_S_D, MASK_VFCPKB_S_D)
DECLARE_INSN(vfcpkc_s_d, MATCH_VFCPKC_S_D, MASK_VFCPKC_S_D)
DECLARE_INSN(vfcpkd_s_d, MATCH_VFCPKD_S_D, MASK_VFCPKD_S_D)
DECLARE_INSN(vfcvt_h_h, MATCH_VFCVT_H_H, MASK_VFCVT_H_H)
DECLARE_INSN(vfcvt_h_ah, MATCH_VFCVT_H_AH, MASK_VFCVT_H_AH)
DECLARE_INSN(vfcvt_ah_h, MATCH_VFCVT_AH_H, MASK_VFCVT_AH_H)
DECLARE_INSN(vfcvtu_h_h, MATCH_VFCVTU_H_H, MASK_VFCVTU_H_H)
DECLARE_INSN(vfcvtu_h_ah, MATCH_VFCVTU_H_AH, MASK_VFCVTU_H_AH)
DECLARE_INSN(vfcvtu_ah_h, MATCH_VFCVTU_AH_H, MASK_VFCVTU_AH_H)
DECLARE_INSN(vfadd_h, MATCH_VFADD_H, MASK_VFADD_H)
DECLARE_INSN(vfadd_r_h, MATCH_VFADD_R_H, MASK_VFADD_R_H)
DECLARE_INSN(vfsub_h, MATCH_VFSUB_H, MASK_VFSUB_H)
DECLARE_INSN(vfsub_r_h, MATCH_VFSUB_R_H, MASK_VFSUB_R_H)
DECLARE_INSN(vfmul_h, MATCH_VFMUL_H, MASK_VFMUL_H)
DECLARE_INSN(vfmul_r_h, MATCH_VFMUL_R_H, MASK_VFMUL_R_H)
DECLARE_INSN(vfdiv_h, MATCH_VFDIV_H, MASK_VFDIV_H)
DECLARE_INSN(vfdiv_r_h, MATCH_VFDIV_R_H, MASK_VFDIV_R_H)
DECLARE_INSN(vfmin_h, MATCH_VFMIN_H, MASK_VFMIN_H)
DECLARE_INSN(vfmin_r_h, MATCH_VFMIN_R_H, MASK_VFMIN_R_H)
DECLARE_INSN(vfmax_h, MATCH_VFMAX_H, MASK_VFMAX_H)
DECLARE_INSN(vfmax_r_h, MATCH_VFMAX_R_H, MASK_VFMAX_R_H)
DECLARE_INSN(vfsqrt_h, MATCH_VFSQRT_H, MASK_VFSQRT_H)
DECLARE_INSN(vfmac_h, MATCH_VFMAC_H, MASK_VFMAC_H)
DECLARE_INSN(vfmac_r_h, MATCH_VFMAC_R_H, MASK_VFMAC_R_H)
DECLARE_INSN(vfmre_h, MATCH_VFMRE_H, MASK_VFMRE_H)
DECLARE_INSN(vfmre_r_h, MATCH_VFMRE_R_H, MASK_VFMRE_R_H)
DECLARE_INSN(vfclass_h, MATCH_VFCLASS_H, MASK_VFCLASS_H)
DECLARE_INSN(vfsgnj_h, MATCH_VFSGNJ_H, MASK_VFSGNJ_H)
DECLARE_INSN(vfsgnj_r_h, MATCH_VFSGNJ_R_H, MASK_VFSGNJ_R_H)
DECLARE_INSN(vfsgnjn_h, MATCH_VFSGNJN_H, MASK_VFSGNJN_H)
DECLARE_INSN(vfsgnjn_r_h, MATCH_VFSGNJN_R_H, MASK_VFSGNJN_R_H)
DECLARE_INSN(vfsgnjx_h, MATCH_VFSGNJX_H, MASK_VFSGNJX_H)
DECLARE_INSN(vfsgnjx_r_h, MATCH_VFSGNJX_R_H, MASK_VFSGNJX_R_H)
DECLARE_INSN(vfeq_h, MATCH_VFEQ_H, MASK_VFEQ_H)
DECLARE_INSN(vfeq_r_h, MATCH_VFEQ_R_H, MASK_VFEQ_R_H)
DECLARE_INSN(vfne_h, MATCH_VFNE_H, MASK_VFNE_H)
DECLARE_INSN(vfne_r_h, MATCH_VFNE_R_H, MASK_VFNE_R_H)
DECLARE_INSN(vflt_h, MATCH_VFLT_H, MASK_VFLT_H)
DECLARE_INSN(vflt_r_h, MATCH_VFLT_R_H, MASK_VFLT_R_H)
DECLARE_INSN(vfge_h, MATCH_VFGE_H, MASK_VFGE_H)
DECLARE_INSN(vfge_r_h, MATCH_VFGE_R_H, MASK_VFGE_R_H)
DECLARE_INSN(vfle_h, MATCH_VFLE_H, MASK_VFLE_H)
DECLARE_INSN(vfle_r_h, MATCH_VFLE_R_H, MASK_VFLE_R_H)
DECLARE_INSN(vfgt_h, MATCH_VFGT_H, MASK_VFGT_H)
DECLARE_INSN(vfgt_r_h, MATCH_VFGT_R_H, MASK_VFGT_R_H)
DECLARE_INSN(vfmv_x_h, MATCH_VFMV_X_H, MASK_VFMV_X_H)
DECLARE_INSN(vfmv_h_x, MATCH_VFMV_H_X, MASK_VFMV_H_X)
DECLARE_INSN(vfcvt_x_h, MATCH_VFCVT_X_H, MASK_VFCVT_X_H)
DECLARE_INSN(vfcvt_xu_h, MATCH_VFCVT_XU_H, MASK_VFCVT_XU_H)
DECLARE_INSN(vfcvt_h_x, MATCH_VFCVT_H_X, MASK_VFCVT_H_X)
DECLARE_INSN(vfcvt_h_xu, MATCH_VFCVT_H_XU, MASK_VFCVT_H_XU)
DECLARE_INSN(vfcpka_h_s, MATCH_VFCPKA_H_S, MASK_VFCPKA_H_S)
DECLARE_INSN(vfcpkb_h_s, MATCH_VFCPKB_H_S, MASK_VFCPKB_H_S)
DECLARE_INSN(vfcpkc_h_s, MATCH_VFCPKC_H_S, MASK_VFCPKC_H_S)
DECLARE_INSN(vfcpkd_h_s, MATCH_VFCPKD_H_S, MASK_VFCPKD_H_S)
DECLARE_INSN(vfcpka_h_d, MATCH_VFCPKA_H_D, MASK_VFCPKA_H_D)
DECLARE_INSN(vfcpkb_h_d, MATCH_VFCPKB_H_D, MASK_VFCPKB_H_D)
DECLARE_INSN(vfcpkc_h_d, MATCH_VFCPKC_H_D, MASK_VFCPKC_H_D)
DECLARE_INSN(vfcpkd_h_d, MATCH_VFCPKD_H_D, MASK_VFCPKD_H_D)
DECLARE_INSN(vfcvt_s_h, MATCH_VFCVT_S_H, MASK_VFCVT_S_H)
DECLARE_INSN(vfcvtu_s_h, MATCH_VFCVTU_S_H, MASK_VFCVTU_S_H)
DECLARE_INSN(vfcvt_h_s, MATCH_VFCVT_H_S, MASK_VFCVT_H_S)
DECLARE_INSN(vfcvtu_h_s, MATCH_VFCVTU_H_S, MASK_VFCVTU_H_S)
DECLARE_INSN(vfadd_ah, MATCH_VFADD_AH, MASK_VFADD_AH)
DECLARE_INSN(vfadd_r_ah, MATCH_VFADD_R_AH, MASK_VFADD_R_AH)
DECLARE_INSN(vfsub_ah, MATCH_VFSUB_AH, MASK_VFSUB_AH)
DECLARE_INSN(vfsub_r_ah, MATCH_VFSUB_R_AH, MASK_VFSUB_R_AH)
DECLARE_INSN(vfmul_ah, MATCH_VFMUL_AH, MASK_VFMUL_AH)
DECLARE_INSN(vfmul_r_ah, MATCH_VFMUL_R_AH, MASK_VFMUL_R_AH)
DECLARE_INSN(vfdiv_ah, MATCH_VFDIV_AH, MASK_VFDIV_AH)
DECLARE_INSN(vfdiv_r_ah, MATCH_VFDIV_R_AH, MASK_VFDIV_R_AH)
DECLARE_INSN(vfmin_ah, MATCH_VFMIN_AH, MASK_VFMIN_AH)
DECLARE_INSN(vfmin_r_ah, MATCH_VFMIN_R_AH, MASK_VFMIN_R_AH)
DECLARE_INSN(vfmax_ah, MATCH_VFMAX_AH, MASK_VFMAX_AH)
DECLARE_INSN(vfmax_r_ah, MATCH_VFMAX_R_AH, MASK_VFMAX_R_AH)
DECLARE_INSN(vfsqrt_ah, MATCH_VFSQRT_AH, MASK_VFSQRT_AH)
DECLARE_INSN(vfmac_ah, MATCH_VFMAC_AH, MASK_VFMAC_AH)
DECLARE_INSN(vfmac_r_ah, MATCH_VFMAC_R_AH, MASK_VFMAC_R_AH)
DECLARE_INSN(vfmre_ah, MATCH_VFMRE_AH, MASK_VFMRE_AH)
DECLARE_INSN(vfmre_r_ah, MATCH_VFMRE_R_AH, MASK_VFMRE_R_AH)
DECLARE_INSN(vfclass_ah, MATCH_VFCLASS_AH, MASK_VFCLASS_AH)
DECLARE_INSN(vfsgnj_ah, MATCH_VFSGNJ_AH, MASK_VFSGNJ_AH)
DECLARE_INSN(vfsgnj_r_ah, MATCH_VFSGNJ_R_AH, MASK_VFSGNJ_R_AH)
DECLARE_INSN(vfsgnjn_ah, MATCH_VFSGNJN_AH, MASK_VFSGNJN_AH)
DECLARE_INSN(vfsgnjn_r_ah, MATCH_VFSGNJN_R_AH, MASK_VFSGNJN_R_AH)
DECLARE_INSN(vfsgnjx_ah, MATCH_VFSGNJX_AH, MASK_VFSGNJX_AH)
DECLARE_INSN(vfsgnjx_r_ah, MATCH_VFSGNJX_R_AH, MASK_VFSGNJX_R_AH)
DECLARE_INSN(vfeq_ah, MATCH_VFEQ_AH, MASK_VFEQ_AH)
DECLARE_INSN(vfeq_r_ah, MATCH_VFEQ_R_AH, MASK_VFEQ_R_AH)
DECLARE_INSN(vfne_ah, MATCH_VFNE_AH, MASK_VFNE_AH)
DECLARE_INSN(vfne_r_ah, MATCH_VFNE_R_AH, MASK_VFNE_R_AH)
DECLARE_INSN(vflt_ah, MATCH_VFLT_AH, MASK_VFLT_AH)
DECLARE_INSN(vflt_r_ah, MATCH_VFLT_R_AH, MASK_VFLT_R_AH)
DECLARE_INSN(vfge_ah, MATCH_VFGE_AH, MASK_VFGE_AH)
DECLARE_INSN(vfge_r_ah, MATCH_VFGE_R_AH, MASK_VFGE_R_AH)
DECLARE_INSN(vfle_ah, MATCH_VFLE_AH, MASK_VFLE_AH)
DECLARE_INSN(vfle_r_ah, MATCH_VFLE_R_AH, MASK_VFLE_R_AH)
DECLARE_INSN(vfgt_ah, MATCH_VFGT_AH, MASK_VFGT_AH)
DECLARE_INSN(vfgt_r_ah, MATCH_VFGT_R_AH, MASK_VFGT_R_AH)
DECLARE_INSN(vfmv_x_ah, MATCH_VFMV_X_AH, MASK_VFMV_X_AH)
DECLARE_INSN(vfmv_ah_x, MATCH_VFMV_AH_X, MASK_VFMV_AH_X)
DECLARE_INSN(vfcvt_x_ah, MATCH_VFCVT_X_AH, MASK_VFCVT_X_AH)
DECLARE_INSN(vfcvt_xu_ah, MATCH_VFCVT_XU_AH, MASK_VFCVT_XU_AH)
DECLARE_INSN(vfcvt_ah_x, MATCH_VFCVT_AH_X, MASK_VFCVT_AH_X)
DECLARE_INSN(vfcvt_ah_xu, MATCH_VFCVT_AH_XU, MASK_VFCVT_AH_XU)
DECLARE_INSN(vfcpka_ah_s, MATCH_VFCPKA_AH_S, MASK_VFCPKA_AH_S)
DECLARE_INSN(vfcpkb_ah_s, MATCH_VFCPKB_AH_S, MASK_VFCPKB_AH_S)
DECLARE_INSN(vfcpkc_ah_s, MATCH_VFCPKC_AH_S, MASK_VFCPKC_AH_S)
DECLARE_INSN(vfcpkd_ah_s, MATCH_VFCPKD_AH_S, MASK_VFCPKD_AH_S)
DECLARE_INSN(vfcpka_ah_d, MATCH_VFCPKA_AH_D, MASK_VFCPKA_AH_D)
DECLARE_INSN(vfcpkb_ah_d, MATCH_VFCPKB_AH_D, MASK_VFCPKB_AH_D)
DECLARE_INSN(vfcpkc_ah_d, MATCH_VFCPKC_AH_D, MASK_VFCPKC_AH_D)
DECLARE_INSN(vfcpkd_ah_d, MATCH_VFCPKD_AH_D, MASK_VFCPKD_AH_D)
DECLARE_INSN(vfcvt_s_ah, MATCH_VFCVT_S_AH, MASK_VFCVT_S_AH)
DECLARE_INSN(vfcvtu_s_ah, MATCH_VFCVTU_S_AH, MASK_VFCVTU_S_AH)
DECLARE_INSN(vfcvt_ah_s, MATCH_VFCVT_AH_S, MASK_VFCVT_AH_S)
DECLARE_INSN(vfcvtu_ah_s, MATCH_VFCVTU_AH_S, MASK_VFCVTU_AH_S)
DECLARE_INSN(vfadd_b, MATCH_VFADD_B, MASK_VFADD_B)
DECLARE_INSN(vfadd_r_b, MATCH_VFADD_R_B, MASK_VFADD_R_B)
DECLARE_INSN(vfsub_b, MATCH_VFSUB_B, MASK_VFSUB_B)
DECLARE_INSN(vfsub_r_b, MATCH_VFSUB_R_B, MASK_VFSUB_R_B)
DECLARE_INSN(vfmul_b, MATCH_VFMUL_B, MASK_VFMUL_B)
DECLARE_INSN(vfmul_r_b, MATCH_VFMUL_R_B, MASK_VFMUL_R_B)
DECLARE_INSN(vfdiv_b, MATCH_VFDIV_B, MASK_VFDIV_B)
DECLARE_INSN(vfdiv_r_b, MATCH_VFDIV_R_B, MASK_VFDIV_R_B)
DECLARE_INSN(vfmin_b, MATCH_VFMIN_B, MASK_VFMIN_B)
DECLARE_INSN(vfmin_r_b, MATCH_VFMIN_R_B, MASK_VFMIN_R_B)
DECLARE_INSN(vfmax_b, MATCH_VFMAX_B, MASK_VFMAX_B)
DECLARE_INSN(vfmax_r_b, MATCH_VFMAX_R_B, MASK_VFMAX_R_B)
DECLARE_INSN(vfsqrt_b, MATCH_VFSQRT_B, MASK_VFSQRT_B)
DECLARE_INSN(vfmac_b, MATCH_VFMAC_B, MASK_VFMAC_B)
DECLARE_INSN(vfmac_r_b, MATCH_VFMAC_R_B, MASK_VFMAC_R_B)
DECLARE_INSN(vfmre_b, MATCH_VFMRE_B, MASK_VFMRE_B)
DECLARE_INSN(vfmre_r_b, MATCH_VFMRE_R_B, MASK_VFMRE_R_B)
DECLARE_INSN(vfsgnj_b, MATCH_VFSGNJ_B, MASK_VFSGNJ_B)
DECLARE_INSN(vfsgnj_r_b, MATCH_VFSGNJ_R_B, MASK_VFSGNJ_R_B)
DECLARE_INSN(vfsgnjn_b, MATCH_VFSGNJN_B, MASK_VFSGNJN_B)
DECLARE_INSN(vfsgnjn_r_b, MATCH_VFSGNJN_R_B, MASK_VFSGNJN_R_B)
DECLARE_INSN(vfsgnjx_b, MATCH_VFSGNJX_B, MASK_VFSGNJX_B)
DECLARE_INSN(vfsgnjx_r_b, MATCH_VFSGNJX_R_B, MASK_VFSGNJX_R_B)
DECLARE_INSN(vfeq_b, MATCH_VFEQ_B, MASK_VFEQ_B)
DECLARE_INSN(vfeq_r_b, MATCH_VFEQ_R_B, MASK_VFEQ_R_B)
DECLARE_INSN(vfne_b, MATCH_VFNE_B, MASK_VFNE_B)
DECLARE_INSN(vfne_r_b, MATCH_VFNE_R_B, MASK_VFNE_R_B)
DECLARE_INSN(vflt_b, MATCH_VFLT_B, MASK_VFLT_B)
DECLARE_INSN(vflt_r_b, MATCH_VFLT_R_B, MASK_VFLT_R_B)
DECLARE_INSN(vfge_b, MATCH_VFGE_B, MASK_VFGE_B)
DECLARE_INSN(vfge_r_b, MATCH_VFGE_R_B, MASK_VFGE_R_B)
DECLARE_INSN(vfle_b, MATCH_VFLE_B, MASK_VFLE_B)
DECLARE_INSN(vfle_r_b, MATCH_VFLE_R_B, MASK_VFLE_R_B)
DECLARE_INSN(vfgt_b, MATCH_VFGT_B, MASK_VFGT_B)
DECLARE_INSN(vfgt_r_b, MATCH_VFGT_R_B, MASK_VFGT_R_B)
DECLARE_INSN(vfmv_x_b, MATCH_VFMV_X_B, MASK_VFMV_X_B)
DECLARE_INSN(vfmv_b_x, MATCH_VFMV_B_X, MASK_VFMV_B_X)
DECLARE_INSN(vfclass_b, MATCH_VFCLASS_B, MASK_VFCLASS_B)
DECLARE_INSN(vfcvt_x_b, MATCH_VFCVT_X_B, MASK_VFCVT_X_B)
DECLARE_INSN(vfcvt_xu_b, MATCH_VFCVT_XU_B, MASK_VFCVT_XU_B)
DECLARE_INSN(vfcvt_b_x, MATCH_VFCVT_B_X, MASK_VFCVT_B_X)
DECLARE_INSN(vfcvt_b_xu, MATCH_VFCVT_B_XU, MASK_VFCVT_B_XU)
DECLARE_INSN(vfcpka_b_s, MATCH_VFCPKA_B_S, MASK_VFCPKA_B_S)
DECLARE_INSN(vfcpkb_b_s, MATCH_VFCPKB_B_S, MASK_VFCPKB_B_S)
DECLARE_INSN(vfcpkc_b_s, MATCH_VFCPKC_B_S, MASK_VFCPKC_B_S)
DECLARE_INSN(vfcpkd_b_s, MATCH_VFCPKD_B_S, MASK_VFCPKD_B_S)
DECLARE_INSN(vfcpka_b_d, MATCH_VFCPKA_B_D, MASK_VFCPKA_B_D)
DECLARE_INSN(vfcpkb_b_d, MATCH_VFCPKB_B_D, MASK_VFCPKB_B_D)
DECLARE_INSN(vfcpkc_b_d, MATCH_VFCPKC_B_D, MASK_VFCPKC_B_D)
DECLARE_INSN(vfcpkd_b_d, MATCH_VFCPKD_B_D, MASK_VFCPKD_B_D)
DECLARE_INSN(vfcvt_s_b, MATCH_VFCVT_S_B, MASK_VFCVT_S_B)
DECLARE_INSN(vfcvtu_s_b, MATCH_VFCVTU_S_B, MASK_VFCVTU_S_B)
DECLARE_INSN(vfcvt_b_s, MATCH_VFCVT_B_S, MASK_VFCVT_B_S)
DECLARE_INSN(vfcvtu_b_s, MATCH_VFCVTU_B_S, MASK_VFCVTU_B_S)
DECLARE_INSN(vfcvt_h_b, MATCH_VFCVT_H_B, MASK_VFCVT_H_B)
DECLARE_INSN(vfcvtu_h_b, MATCH_VFCVTU_H_B, MASK_VFCVTU_H_B)
DECLARE_INSN(vfcvt_b_h, MATCH_VFCVT_B_H, MASK_VFCVT_B_H)
DECLARE_INSN(vfcvtu_b_h, MATCH_VFCVTU_B_H, MASK_VFCVTU_B_H)
DECLARE_INSN(vfcvt_ah_b, MATCH_VFCVT_AH_B, MASK_VFCVT_AH_B)
DECLARE_INSN(vfcvtu_ah_b, MATCH_VFCVTU_AH_B, MASK_VFCVTU_AH_B)
DECLARE_INSN(vfcvt_b_ah, MATCH_VFCVT_B_AH, MASK_VFCVT_B_AH)
DECLARE_INSN(vfcvtu_b_ah, MATCH_VFCVTU_B_AH, MASK_VFCVTU_B_AH)
DECLARE_INSN(vfcvt_b_b, MATCH_VFCVT_B_B, MASK_VFCVT_B_B)
DECLARE_INSN(vfcvt_ab_b, MATCH_VFCVT_AB_B, MASK_VFCVT_AB_B)
DECLARE_INSN(vfcvt_b_ab, MATCH_VFCVT_B_AB, MASK_VFCVT_B_AB)
DECLARE_INSN(vfcvtu_b_b, MATCH_VFCVTU_B_B, MASK_VFCVTU_B_B)
DECLARE_INSN(vfcvtu_ab_b, MATCH_VFCVTU_AB_B, MASK_VFCVTU_AB_B)
DECLARE_INSN(vfcvtu_b_ab, MATCH_VFCVTU_B_AB, MASK_VFCVTU_B_AB)
DECLARE_INSN(vfadd_ab, MATCH_VFADD_AB, MASK_VFADD_AB)
DECLARE_INSN(vfadd_r_ab, MATCH_VFADD_R_AB, MASK_VFADD_R_AB)
DECLARE_INSN(vfsub_ab, MATCH_VFSUB_AB, MASK_VFSUB_AB)
DECLARE_INSN(vfsub_r_ab, MATCH_VFSUB_R_AB, MASK_VFSUB_R_AB)
DECLARE_INSN(vfmul_ab, MATCH_VFMUL_AB, MASK_VFMUL_AB)
DECLARE_INSN(vfmul_r_ab, MATCH_VFMUL_R_AB, MASK_VFMUL_R_AB)
DECLARE_INSN(vfdiv_ab, MATCH_VFDIV_AB, MASK_VFDIV_AB)
DECLARE_INSN(vfdiv_r_ab, MATCH_VFDIV_R_AB, MASK_VFDIV_R_AB)
DECLARE_INSN(vfmin_ab, MATCH_VFMIN_AB, MASK_VFMIN_AB)
DECLARE_INSN(vfmin_r_ab, MATCH_VFMIN_R_AB, MASK_VFMIN_R_AB)
DECLARE_INSN(vfmax_ab, MATCH_VFMAX_AB, MASK_VFMAX_AB)
DECLARE_INSN(vfmax_r_ab, MATCH_VFMAX_R_AB, MASK_VFMAX_R_AB)
DECLARE_INSN(vfsqrt_ab, MATCH_VFSQRT_AB, MASK_VFSQRT_AB)
DECLARE_INSN(vfmac_ab, MATCH_VFMAC_AB, MASK_VFMAC_AB)
DECLARE_INSN(vfmac_r_ab, MATCH_VFMAC_R_AB, MASK_VFMAC_R_AB)
DECLARE_INSN(vfmre_ab, MATCH_VFMRE_AB, MASK_VFMRE_AB)
DECLARE_INSN(vfmre_r_ab, MATCH_VFMRE_R_AB, MASK_VFMRE_R_AB)
DECLARE_INSN(vfsgnj_ab, MATCH_VFSGNJ_AB, MASK_VFSGNJ_AB)
DECLARE_INSN(vfsgnj_r_ab, MATCH_VFSGNJ_R_AB, MASK_VFSGNJ_R_AB)
DECLARE_INSN(vfsgnjn_ab, MATCH_VFSGNJN_AB, MASK_VFSGNJN_AB)
DECLARE_INSN(vfsgnjn_r_ab, MATCH_VFSGNJN_R_AB, MASK_VFSGNJN_R_AB)
DECLARE_INSN(vfsgnjx_ab, MATCH_VFSGNJX_AB, MASK_VFSGNJX_AB)
DECLARE_INSN(vfsgnjx_r_ab, MATCH_VFSGNJX_R_AB, MASK_VFSGNJX_R_AB)
DECLARE_INSN(vfeq_ab, MATCH_VFEQ_AB, MASK_VFEQ_AB)
DECLARE_INSN(vfeq_r_ab, MATCH_VFEQ_R_AB, MASK_VFEQ_R_AB)
DECLARE_INSN(vfne_ab, MATCH_VFNE_AB, MASK_VFNE_AB)
DECLARE_INSN(vfne_r_ab, MATCH_VFNE_R_AB, MASK_VFNE_R_AB)
DECLARE_INSN(vflt_ab, MATCH_VFLT_AB, MASK_VFLT_AB)
DECLARE_INSN(vflt_r_ab, MATCH_VFLT_R_AB, MASK_VFLT_R_AB)
DECLARE_INSN(vfge_ab, MATCH_VFGE_AB, MASK_VFGE_AB)
DECLARE_INSN(vfge_r_ab, MATCH_VFGE_R_AB, MASK_VFGE_R_AB)
DECLARE_INSN(vfle_ab, MATCH_VFLE_AB, MASK_VFLE_AB)
DECLARE_INSN(vfle_r_ab, MATCH_VFLE_R_AB, MASK_VFLE_R_AB)
DECLARE_INSN(vfgt_ab, MATCH_VFGT_AB, MASK_VFGT_AB)
DECLARE_INSN(vfgt_r_ab, MATCH_VFGT_R_AB, MASK_VFGT_R_AB)
DECLARE_INSN(vfmv_x_ab, MATCH_VFMV_X_AB, MASK_VFMV_X_AB)
DECLARE_INSN(vfmv_ab_x, MATCH_VFMV_AB_X, MASK_VFMV_AB_X)
DECLARE_INSN(vfclass_ab, MATCH_VFCLASS_AB, MASK_VFCLASS_AB)
DECLARE_INSN(vfcvt_x_ab, MATCH_VFCVT_X_AB, MASK_VFCVT_X_AB)
DECLARE_INSN(vfcvt_xu_ab, MATCH_VFCVT_XU_AB, MASK_VFCVT_XU_AB)
DECLARE_INSN(vfcvt_ab_x, MATCH_VFCVT_AB_X, MASK_VFCVT_AB_X)
DECLARE_INSN(vfcvt_ab_xu, MATCH_VFCVT_AB_XU, MASK_VFCVT_AB_XU)
DECLARE_INSN(vfcpka_ab_s, MATCH_VFCPKA_AB_S, MASK_VFCPKA_AB_S)
DECLARE_INSN(vfcpkb_ab_s, MATCH_VFCPKB_AB_S, MASK_VFCPKB_AB_S)
DECLARE_INSN(vfcpkc_ab_s, MATCH_VFCPKC_AB_S, MASK_VFCPKC_AB_S)
DECLARE_INSN(vfcpkd_ab_s, MATCH_VFCPKD_AB_S, MASK_VFCPKD_AB_S)
DECLARE_INSN(vfcpka_ab_d, MATCH_VFCPKA_AB_D, MASK_VFCPKA_AB_D)
DECLARE_INSN(vfcpkb_ab_d, MATCH_VFCPKB_AB_D, MASK_VFCPKB_AB_D)
DECLARE_INSN(vfcpkc_ab_d, MATCH_VFCPKC_AB_D, MASK_VFCPKC_AB_D)
DECLARE_INSN(vfcpkd_ab_d, MATCH_VFCPKD_AB_D, MASK_VFCPKD_AB_D)
DECLARE_INSN(vfcvt_s_ab, MATCH_VFCVT_S_AB, MASK_VFCVT_S_AB)
DECLARE_INSN(vfcvtu_s_ab, MATCH_VFCVTU_S_AB, MASK_VFCVTU_S_AB)
DECLARE_INSN(vfcvt_ab_s, MATCH_VFCVT_AB_S, MASK_VFCVT_AB_S)
DECLARE_INSN(vfcvtu_ab_s, MATCH_VFCVTU_AB_S, MASK_VFCVTU_AB_S)
DECLARE_INSN(vfcvt_h_ab, MATCH_VFCVT_H_AB, MASK_VFCVT_H_AB)
DECLARE_INSN(vfcvtu_h_ab, MATCH_VFCVTU_H_AB, MASK_VFCVTU_H_AB)
DECLARE_INSN(vfcvt_ab_h, MATCH_VFCVT_AB_H, MASK_VFCVT_AB_H)
DECLARE_INSN(vfcvtu_ab_h, MATCH_VFCVTU_AB_H, MASK_VFCVTU_AB_H)
DECLARE_INSN(vfcvt_ah_ab, MATCH_VFCVT_AH_AB, MASK_VFCVT_AH_AB)
DECLARE_INSN(vfcvtu_ah_ab, MATCH_VFCVTU_AH_AB, MASK_VFCVTU_AH_AB)
DECLARE_INSN(vfcvt_ab_ah, MATCH_VFCVT_AB_AH, MASK_VFCVT_AB_AH)
DECLARE_INSN(vfcvtu_ab_ah, MATCH_VFCVTU_AB_AH, MASK_VFCVTU_AB_AH)
DECLARE_INSN(fmulex_s_h, MATCH_FMULEX_S_H, MASK_FMULEX_S_H)
DECLARE_INSN(fmacex_s_h, MATCH_FMACEX_S_H, MASK_FMACEX_S_H)
DECLARE_INSN(fmulex_s_ah, MATCH_FMULEX_S_AH, MASK_FMULEX_S_AH)
DECLARE_INSN(fmacex_s_ah, MATCH_FMACEX_S_AH, MASK_FMACEX_S_AH)
DECLARE_INSN(fmulex_s_b, MATCH_FMULEX_S_B, MASK_FMULEX_S_B)
DECLARE_INSN(fmacex_s_b, MATCH_FMACEX_S_B, MASK_FMACEX_S_B)
DECLARE_INSN(fmulex_s_ab, MATCH_FMULEX_S_AB, MASK_FMULEX_S_AB)
DECLARE_INSN(fmacex_s_ab, MATCH_FMACEX_S_AB, MASK_FMACEX_S_AB)
DECLARE_INSN(vfsum_s, MATCH_VFSUM_S, MASK_VFSUM_S)
DECLARE_INSN(vfnsum_s, MATCH_VFNSUM_S, MASK_VFNSUM_S)
DECLARE_INSN(vfsum_h, MATCH_VFSUM_H, MASK_VFSUM_H)
DECLARE_INSN(vfnsum_h, MATCH_VFNSUM_H, MASK_VFNSUM_H)
DECLARE_INSN(vfsum_ah, MATCH_VFSUM_AH, MASK_VFSUM_AH)
DECLARE_INSN(vfnsum_ah, MATCH_VFNSUM_AH, MASK_VFNSUM_AH)
DECLARE_INSN(vfsum_b, MATCH_VFSUM_B, MASK_VFSUM_B)
DECLARE_INSN(vfnsum_b, MATCH_VFNSUM_B, MASK_VFNSUM_B)
DECLARE_INSN(vfsum_ab, MATCH_VFSUM_AB, MASK_VFSUM_AB)
DECLARE_INSN(vfnsum_ab, MATCH_VFNSUM_AB, MASK_VFNSUM_AB)
DECLARE_INSN(vfsumex_s_h, MATCH_VFSUMEX_S_H, MASK_VFSUMEX_S_H)
DECLARE_INSN(vfnsumex_s_h, MATCH_VFNSUMEX_S_H, MASK_VFNSUMEX_S_H)
DECLARE_INSN(vfdotpex_s_h, MATCH_VFDOTPEX_S_H, MASK_VFDOTPEX_S_H)
DECLARE_INSN(vfdotpex_s_r_h, MATCH_VFDOTPEX_S_R_H, MASK_VFDOTPEX_S_R_H)
DECLARE_INSN(vfndotpex_s_h, MATCH_VFNDOTPEX_S_H, MASK_VFNDOTPEX_S_H)
DECLARE_INSN(vfndotpex_s_r_h, MATCH_VFNDOTPEX_S_R_H, MASK_VFNDOTPEX_S_R_H)
DECLARE_INSN(vfsumex_s_ah, MATCH_VFSUMEX_S_AH, MASK_VFSUMEX_S_AH)
DECLARE_INSN(vfnsumex_s_ah, MATCH_VFNSUMEX_S_AH, MASK_VFNSUMEX_S_AH)
DECLARE_INSN(vfdotpex_s_ah, MATCH_VFDOTPEX_S_AH, MASK_VFDOTPEX_S_AH)
DECLARE_INSN(vfdotpex_s_r_ah, MATCH_VFDOTPEX_S_R_AH, MASK_VFDOTPEX_S_R_AH)
DECLARE_INSN(vfndotpex_s_ah, MATCH_VFNDOTPEX_S_AH, MASK_VFNDOTPEX_S_AH)
DECLARE_INSN(vfndotpex_s_r_ah, MATCH_VFNDOTPEX_S_R_AH, MASK_VFNDOTPEX_S_R_AH)
DECLARE_INSN(vfsumex_h_b, MATCH_VFSUMEX_H_B, MASK_VFSUMEX_H_B)
DECLARE_INSN(vfnsumex_h_b, MATCH_VFNSUMEX_H_B, MASK_VFNSUMEX_H_B)
DECLARE_INSN(vfdotpex_h_b, MATCH_VFDOTPEX_H_B, MASK_VFDOTPEX_H_B)
DECLARE_INSN(vfdotpex_h_r_b, MATCH_VFDOTPEX_H_R_B, MASK_VFDOTPEX_H_R_B)
DECLARE_INSN(vfndotpex_h_b, MATCH_VFNDOTPEX_H_B, MASK_VFNDOTPEX_H_B)
DECLARE_INSN(vfndotpex_h_r_b, MATCH_VFNDOTPEX_H_R_B, MASK_VFNDOTPEX_H_R_B)
DECLARE_INSN(vfsumex_ah_b, MATCH_VFSUMEX_AH_B, MASK_VFSUMEX_AH_B)
DECLARE_INSN(vfnsumex_ah_b, MATCH_VFNSUMEX_AH_B, MASK_VFNSUMEX_AH_B)
DECLARE_INSN(vfdotpex_ah_b, MATCH_VFDOTPEX_AH_B, MASK_VFDOTPEX_AH_B)
DECLARE_INSN(vfdotpex_ah_r_b, MATCH_VFDOTPEX_AH_R_B, MASK_VFDOTPEX_AH_R_B)
DECLARE_INSN(vfndotpex_ah_b, MATCH_VFNDOTPEX_AH_B, MASK_VFNDOTPEX_AH_B)
DECLARE_INSN(vfndotpex_ah_r_b, MATCH_VFNDOTPEX_AH_R_B, MASK_VFNDOTPEX_AH_R_B)
DECLARE_INSN(vfsumex_h_ab, MATCH_VFSUMEX_H_AB, MASK_VFSUMEX_H_AB)
DECLARE_INSN(vfnsumex_h_ab, MATCH_VFNSUMEX_H_AB, MASK_VFNSUMEX_H_AB)
DECLARE_INSN(vfdotpex_h_ab, MATCH_VFDOTPEX_H_AB, MASK_VFDOTPEX_H_AB)
DECLARE_INSN(vfdotpex_h_r_ab, MATCH_VFDOTPEX_H_R_AB, MASK_VFDOTPEX_H_R_AB)
DECLARE_INSN(vfndotpex_h_ab, MATCH_VFNDOTPEX_H_AB, MASK_VFNDOTPEX_H_AB)
DECLARE_INSN(vfndotpex_h_r_ab, MATCH_VFNDOTPEX_H_R_AB, MASK_VFNDOTPEX_H_R_AB)
DECLARE_INSN(vfsumex_ah_ab, MATCH_VFSUMEX_AH_AB, MASK_VFSUMEX_AH_AB)
DECLARE_INSN(vfnsumex_ah_ab, MATCH_VFNSUMEX_AH_AB, MASK_VFNSUMEX_AH_AB)
DECLARE_INSN(vfdotpex_ah_ab, MATCH_VFDOTPEX_AH_AB, MASK_VFDOTPEX_AH_AB)
DECLARE_INSN(vfdotpex_ah_r_ab, MATCH_VFDOTPEX_AH_R_AB, MASK_VFDOTPEX_AH_R_AB)
DECLARE_INSN(vfndotpex_ah_ab, MATCH_VFNDOTPEX_AH_AB, MASK_VFNDOTPEX_AH_AB)
DECLARE_INSN(vfndotpex_ah_r_ab, MATCH_VFNDOTPEX_AH_R_AB, MASK_VFNDOTPEX_AH_R_AB)
DECLARE_INSN(dmsrc, MATCH_DMSRC, MASK_DMSRC)
DECLARE_INSN(dmdst, MATCH_DMDST, MASK_DMDST)
DECLARE_INSN(dmcpyi, MATCH_DMCPYI, MASK_DMCPYI)
DECLARE_INSN(dmcpy, MATCH_DMCPY, MASK_DMCPY)
DECLARE_INSN(dmstati, MATCH_DMSTATI, MASK_DMSTATI)
DECLARE_INSN(dmstat, MATCH_DMSTAT, MASK_DMSTAT)
DECLARE_INSN(dmstr, MATCH_DMSTR, MASK_DMSTR)
DECLARE_INSN(dmrep, MATCH_DMREP, MASK_DMREP)
DECLARE_INSN(scfgri, MATCH_SCFGRI, MASK_SCFGRI)
DECLARE_INSN(scfgwi, MATCH_SCFGWI, MASK_SCFGWI)
DECLARE_INSN(scfgr, MATCH_SCFGR, MASK_SCFGR)
DECLARE_INSN(scfgw, MATCH_SCFGW, MASK_SCFGW)
#endif
#ifdef DECLARE_CSR
DECLARE_CSR(fflags, CSR_FFLAGS)
DECLARE_CSR(frm, CSR_FRM)
DECLARE_CSR(fcsr, CSR_FCSR)
DECLARE_CSR(fmode, CSR_FMODE)
DECLARE_CSR(cycle, CSR_CYCLE)
DECLARE_CSR(time, CSR_TIME)
DECLARE_CSR(instret, CSR_INSTRET)
DECLARE_CSR(hpmcounter3, CSR_HPMCOUNTER3)
DECLARE_CSR(hpmcounter4, CSR_HPMCOUNTER4)
DECLARE_CSR(hpmcounter5, CSR_HPMCOUNTER5)
DECLARE_CSR(hpmcounter6, CSR_HPMCOUNTER6)
DECLARE_CSR(hpmcounter7, CSR_HPMCOUNTER7)
DECLARE_CSR(hpmcounter8, CSR_HPMCOUNTER8)
DECLARE_CSR(hpmcounter9, CSR_HPMCOUNTER9)
DECLARE_CSR(hpmcounter10, CSR_HPMCOUNTER10)
DECLARE_CSR(hpmcounter11, CSR_HPMCOUNTER11)
DECLARE_CSR(hpmcounter12, CSR_HPMCOUNTER12)
DECLARE_CSR(hpmcounter13, CSR_HPMCOUNTER13)
DECLARE_CSR(hpmcounter14, CSR_HPMCOUNTER14)
DECLARE_CSR(hpmcounter15, CSR_HPMCOUNTER15)
DECLARE_CSR(hpmcounter16, CSR_HPMCOUNTER16)
DECLARE_CSR(hpmcounter17, CSR_HPMCOUNTER17)
DECLARE_CSR(hpmcounter18, CSR_HPMCOUNTER18)
DECLARE_CSR(hpmcounter19, CSR_HPMCOUNTER19)
DECLARE_CSR(hpmcounter20, CSR_HPMCOUNTER20)
DECLARE_CSR(hpmcounter21, CSR_HPMCOUNTER21)
DECLARE_CSR(hpmcounter22, CSR_HPMCOUNTER22)
DECLARE_CSR(hpmcounter23, CSR_HPMCOUNTER23)
DECLARE_CSR(hpmcounter24, CSR_HPMCOUNTER24)
DECLARE_CSR(hpmcounter25, CSR_HPMCOUNTER25)
DECLARE_CSR(hpmcounter26, CSR_HPMCOUNTER26)
DECLARE_CSR(hpmcounter27, CSR_HPMCOUNTER27)
DECLARE_CSR(hpmcounter28, CSR_HPMCOUNTER28)
DECLARE_CSR(hpmcounter29, CSR_HPMCOUNTER29)
DECLARE_CSR(hpmcounter30, CSR_HPMCOUNTER30)
DECLARE_CSR(hpmcounter31, CSR_HPMCOUNTER31)
DECLARE_CSR(sstatus, CSR_SSTATUS)
DECLARE_CSR(sie, CSR_SIE)
DECLARE_CSR(stvec, CSR_STVEC)
DECLARE_CSR(scounteren, CSR_SCOUNTEREN)
DECLARE_CSR(sscratch, CSR_SSCRATCH)
DECLARE_CSR(sepc, CSR_SEPC)
DECLARE_CSR(scause, CSR_SCAUSE)
DECLARE_CSR(stval, CSR_STVAL)
DECLARE_CSR(sip, CSR_SIP)
DECLARE_CSR(satp, CSR_SATP)
DECLARE_CSR(bsstatus, CSR_BSSTATUS)
DECLARE_CSR(bsie, CSR_BSIE)
DECLARE_CSR(bstvec, CSR_BSTVEC)
DECLARE_CSR(bsscratch, CSR_BSSCRATCH)
DECLARE_CSR(bsepc, CSR_BSEPC)
DECLARE_CSR(bscause, CSR_BSCAUSE)
DECLARE_CSR(bstval, CSR_BSTVAL)
DECLARE_CSR(bsip, CSR_BSIP)
DECLARE_CSR(bsatp, CSR_BSATP)
DECLARE_CSR(hstatus, CSR_HSTATUS)
DECLARE_CSR(hedeleg, CSR_HEDELEG)
DECLARE_CSR(hideleg, CSR_HIDELEG)
DECLARE_CSR(hgatp, CSR_HGATP)
DECLARE_CSR(utvt, CSR_UTVT)
DECLARE_CSR(unxti, CSR_UNXTI)
DECLARE_CSR(uintstatus, CSR_UINTSTATUS)
DECLARE_CSR(uscratchcsw, CSR_USCRATCHCSW)
DECLARE_CSR(uscratchcswl, CSR_USCRATCHCSWL)
DECLARE_CSR(stvt, CSR_STVT)
DECLARE_CSR(snxti, CSR_SNXTI)
DECLARE_CSR(sintstatus, CSR_SINTSTATUS)
DECLARE_CSR(sscratchcsw, CSR_SSCRATCHCSW)
DECLARE_CSR(sscratchcswl, CSR_SSCRATCHCSWL)
DECLARE_CSR(mtvt, CSR_MTVT)
DECLARE_CSR(mnxti, CSR_MNXTI)
DECLARE_CSR(mintstatus, CSR_MINTSTATUS)
DECLARE_CSR(mscratchcsw, CSR_MSCRATCHCSW)
DECLARE_CSR(mscratchcswl, CSR_MSCRATCHCSWL)
DECLARE_CSR(mstatus, CSR_MSTATUS)
DECLARE_CSR(misa, CSR_MISA)
DECLARE_CSR(medeleg, CSR_MEDELEG)
DECLARE_CSR(mideleg, CSR_MIDELEG)
DECLARE_CSR(mie, CSR_MIE)
DECLARE_CSR(mtvec, CSR_MTVEC)
DECLARE_CSR(mcounteren, CSR_MCOUNTEREN)
DECLARE_CSR(mscratch, CSR_MSCRATCH)
DECLARE_CSR(mepc, CSR_MEPC)
DECLARE_CSR(mcause, CSR_MCAUSE)
DECLARE_CSR(mtval, CSR_MTVAL)
DECLARE_CSR(mip, CSR_MIP)
DECLARE_CSR(pmpcfg0, CSR_PMPCFG0)
DECLARE_CSR(pmpcfg1, CSR_PMPCFG1)
DECLARE_CSR(pmpcfg2, CSR_PMPCFG2)
DECLARE_CSR(pmpcfg3, CSR_PMPCFG3)
DECLARE_CSR(pmpaddr0, CSR_PMPADDR0)
DECLARE_CSR(pmpaddr1, CSR_PMPADDR1)
DECLARE_CSR(pmpaddr2, CSR_PMPADDR2)
DECLARE_CSR(pmpaddr3, CSR_PMPADDR3)
DECLARE_CSR(pmpaddr4, CSR_PMPADDR4)
DECLARE_CSR(pmpaddr5, CSR_PMPADDR5)
DECLARE_CSR(pmpaddr6, CSR_PMPADDR6)
DECLARE_CSR(pmpaddr7, CSR_PMPADDR7)
DECLARE_CSR(pmpaddr8, CSR_PMPADDR8)
DECLARE_CSR(pmpaddr9, CSR_PMPADDR9)
DECLARE_CSR(pmpaddr10, CSR_PMPADDR10)
DECLARE_CSR(pmpaddr11, CSR_PMPADDR11)
DECLARE_CSR(pmpaddr12, CSR_PMPADDR12)
DECLARE_CSR(pmpaddr13, CSR_PMPADDR13)
DECLARE_CSR(pmpaddr14, CSR_PMPADDR14)
DECLARE_CSR(pmpaddr15, CSR_PMPADDR15)
DECLARE_CSR(tselect, CSR_TSELECT)
DECLARE_CSR(tdata1, CSR_TDATA1)
DECLARE_CSR(tdata2, CSR_TDATA2)
DECLARE_CSR(tdata3, CSR_TDATA3)
DECLARE_CSR(dcsr, CSR_DCSR)
DECLARE_CSR(dpc, CSR_DPC)
DECLARE_CSR(dscratch, CSR_DSCRATCH)
DECLARE_CSR(mcycle, CSR_MCYCLE)
DECLARE_CSR(minstret, CSR_MINSTRET)
DECLARE_CSR(mhpmcounter3, CSR_MHPMCOUNTER3)
DECLARE_CSR(mhpmcounter4, CSR_MHPMCOUNTER4)
DECLARE_CSR(mhpmcounter5, CSR_MHPMCOUNTER5)
DECLARE_CSR(mhpmcounter6, CSR_MHPMCOUNTER6)
DECLARE_CSR(mhpmcounter7, CSR_MHPMCOUNTER7)
DECLARE_CSR(mhpmcounter8, CSR_MHPMCOUNTER8)
DECLARE_CSR(mhpmcounter9, CSR_MHPMCOUNTER9)
DECLARE_CSR(mhpmcounter10, CSR_MHPMCOUNTER10)
DECLARE_CSR(mhpmcounter11, CSR_MHPMCOUNTER11)
DECLARE_CSR(mhpmcounter12, CSR_MHPMCOUNTER12)
DECLARE_CSR(mhpmcounter13, CSR_MHPMCOUNTER13)
DECLARE_CSR(mhpmcounter14, CSR_MHPMCOUNTER14)
DECLARE_CSR(mhpmcounter15, CSR_MHPMCOUNTER15)
DECLARE_CSR(mhpmcounter16, CSR_MHPMCOUNTER16)
DECLARE_CSR(mhpmcounter17, CSR_MHPMCOUNTER17)
DECLARE_CSR(mhpmcounter18, CSR_MHPMCOUNTER18)
DECLARE_CSR(mhpmcounter19, CSR_MHPMCOUNTER19)
DECLARE_CSR(mhpmcounter20, CSR_MHPMCOUNTER20)
DECLARE_CSR(mhpmcounter21, CSR_MHPMCOUNTER21)
DECLARE_CSR(mhpmcounter22, CSR_MHPMCOUNTER22)
DECLARE_CSR(mhpmcounter23, CSR_MHPMCOUNTER23)
DECLARE_CSR(mhpmcounter24, CSR_MHPMCOUNTER24)
DECLARE_CSR(mhpmcounter25, CSR_MHPMCOUNTER25)
DECLARE_CSR(mhpmcounter26, CSR_MHPMCOUNTER26)
DECLARE_CSR(mhpmcounter27, CSR_MHPMCOUNTER27)
DECLARE_CSR(mhpmcounter28, CSR_MHPMCOUNTER28)
DECLARE_CSR(mhpmcounter29, CSR_MHPMCOUNTER29)
DECLARE_CSR(mhpmcounter30, CSR_MHPMCOUNTER30)
DECLARE_CSR(mhpmcounter31, CSR_MHPMCOUNTER31)
DECLARE_CSR(mhpmevent3, CSR_MHPMEVENT3)
DECLARE_CSR(mhpmevent4, CSR_MHPMEVENT4)
DECLARE_CSR(mhpmevent5, CSR_MHPMEVENT5)
DECLARE_CSR(mhpmevent6, CSR_MHPMEVENT6)
DECLARE_CSR(mhpmevent7, CSR_MHPMEVENT7)
DECLARE_CSR(mhpmevent8, CSR_MHPMEVENT8)
DECLARE_CSR(mhpmevent9, CSR_MHPMEVENT9)
DECLARE_CSR(mhpmevent10, CSR_MHPMEVENT10)
DECLARE_CSR(mhpmevent11, CSR_MHPMEVENT11)
DECLARE_CSR(mhpmevent12, CSR_MHPMEVENT12)
DECLARE_CSR(mhpmevent13, CSR_MHPMEVENT13)
DECLARE_CSR(mhpmevent14, CSR_MHPMEVENT14)
DECLARE_CSR(mhpmevent15, CSR_MHPMEVENT15)
DECLARE_CSR(mhpmevent16, CSR_MHPMEVENT16)
DECLARE_CSR(mhpmevent17, CSR_MHPMEVENT17)
DECLARE_CSR(mhpmevent18, CSR_MHPMEVENT18)
DECLARE_CSR(mhpmevent19, CSR_MHPMEVENT19)
DECLARE_CSR(mhpmevent20, CSR_MHPMEVENT20)
DECLARE_CSR(mhpmevent21, CSR_MHPMEVENT21)
DECLARE_CSR(mhpmevent22, CSR_MHPMEVENT22)
DECLARE_CSR(mhpmevent23, CSR_MHPMEVENT23)
DECLARE_CSR(mhpmevent24, CSR_MHPMEVENT24)
DECLARE_CSR(mhpmevent25, CSR_MHPMEVENT25)
DECLARE_CSR(mhpmevent26, CSR_MHPMEVENT26)
DECLARE_CSR(mhpmevent27, CSR_MHPMEVENT27)
DECLARE_CSR(mhpmevent28, CSR_MHPMEVENT28)
DECLARE_CSR(mhpmevent29, CSR_MHPMEVENT29)
DECLARE_CSR(mhpmevent30, CSR_MHPMEVENT30)
DECLARE_CSR(mhpmevent31, CSR_MHPMEVENT31)
DECLARE_CSR(mvendorid, CSR_MVENDORID)
DECLARE_CSR(marchid, CSR_MARCHID)
DECLARE_CSR(mimpid, CSR_MIMPID)
DECLARE_CSR(mhartid, CSR_MHARTID)
DECLARE_CSR(ssr, CSR_SSR)
DECLARE_CSR(fpmode, CSR_FPMODE)
DECLARE_CSR(cycleh, CSR_CYCLEH)
DECLARE_CSR(timeh, CSR_TIMEH)
DECLARE_CSR(instreth, CSR_INSTRETH)
DECLARE_CSR(hpmcounter3h, CSR_HPMCOUNTER3H)
DECLARE_CSR(hpmcounter4h, CSR_HPMCOUNTER4H)
DECLARE_CSR(hpmcounter5h, CSR_HPMCOUNTER5H)
DECLARE_CSR(hpmcounter6h, CSR_HPMCOUNTER6H)
DECLARE_CSR(hpmcounter7h, CSR_HPMCOUNTER7H)
DECLARE_CSR(hpmcounter8h, CSR_HPMCOUNTER8H)
DECLARE_CSR(hpmcounter9h, CSR_HPMCOUNTER9H)
DECLARE_CSR(hpmcounter10h, CSR_HPMCOUNTER10H)
DECLARE_CSR(hpmcounter11h, CSR_HPMCOUNTER11H)
DECLARE_CSR(hpmcounter12h, CSR_HPMCOUNTER12H)
DECLARE_CSR(hpmcounter13h, CSR_HPMCOUNTER13H)
DECLARE_CSR(hpmcounter14h, CSR_HPMCOUNTER14H)
DECLARE_CSR(hpmcounter15h, CSR_HPMCOUNTER15H)
DECLARE_CSR(hpmcounter16h, CSR_HPMCOUNTER16H)
DECLARE_CSR(hpmcounter17h, CSR_HPMCOUNTER17H)
DECLARE_CSR(hpmcounter18h, CSR_HPMCOUNTER18H)
DECLARE_CSR(hpmcounter19h, CSR_HPMCOUNTER19H)
DECLARE_CSR(hpmcounter20h, CSR_HPMCOUNTER20H)
DECLARE_CSR(hpmcounter21h, CSR_HPMCOUNTER21H)
DECLARE_CSR(hpmcounter22h, CSR_HPMCOUNTER22H)
DECLARE_CSR(hpmcounter23h, CSR_HPMCOUNTER23H)
DECLARE_CSR(hpmcounter24h, CSR_HPMCOUNTER24H)
DECLARE_CSR(hpmcounter25h, CSR_HPMCOUNTER25H)
DECLARE_CSR(hpmcounter26h, CSR_HPMCOUNTER26H)
DECLARE_CSR(hpmcounter27h, CSR_HPMCOUNTER27H)
DECLARE_CSR(hpmcounter28h, CSR_HPMCOUNTER28H)
DECLARE_CSR(hpmcounter29h, CSR_HPMCOUNTER29H)
DECLARE_CSR(hpmcounter30h, CSR_HPMCOUNTER30H)
DECLARE_CSR(hpmcounter31h, CSR_HPMCOUNTER31H)
DECLARE_CSR(mcycleh, CSR_MCYCLEH)
DECLARE_CSR(minstreth, CSR_MINSTRETH)
DECLARE_CSR(mhpmcounter3h, CSR_MHPMCOUNTER3H)
DECLARE_CSR(mhpmcounter4h, CSR_MHPMCOUNTER4H)
DECLARE_CSR(mhpmcounter5h, CSR_MHPMCOUNTER5H)
DECLARE_CSR(mhpmcounter6h, CSR_MHPMCOUNTER6H)
DECLARE_CSR(mhpmcounter7h, CSR_MHPMCOUNTER7H)
DECLARE_CSR(mhpmcounter8h, CSR_MHPMCOUNTER8H)
DECLARE_CSR(mhpmcounter9h, CSR_MHPMCOUNTER9H)
DECLARE_CSR(mhpmcounter10h, CSR_MHPMCOUNTER10H)
DECLARE_CSR(mhpmcounter11h, CSR_MHPMCOUNTER11H)
DECLARE_CSR(mhpmcounter12h, CSR_MHPMCOUNTER12H)
DECLARE_CSR(mhpmcounter13h, CSR_MHPMCOUNTER13H)
DECLARE_CSR(mhpmcounter14h, CSR_MHPMCOUNTER14H)
DECLARE_CSR(mhpmcounter15h, CSR_MHPMCOUNTER15H)
DECLARE_CSR(mhpmcounter16h, CSR_MHPMCOUNTER16H)
DECLARE_CSR(mhpmcounter17h, CSR_MHPMCOUNTER17H)
DECLARE_CSR(mhpmcounter18h, CSR_MHPMCOUNTER18H)
DECLARE_CSR(mhpmcounter19h, CSR_MHPMCOUNTER19H)
DECLARE_CSR(mhpmcounter20h, CSR_MHPMCOUNTER20H)
DECLARE_CSR(mhpmcounter21h, CSR_MHPMCOUNTER21H)
DECLARE_CSR(mhpmcounter22h, CSR_MHPMCOUNTER22H)
DECLARE_CSR(mhpmcounter23h, CSR_MHPMCOUNTER23H)
DECLARE_CSR(mhpmcounter24h, CSR_MHPMCOUNTER24H)
DECLARE_CSR(mhpmcounter25h, CSR_MHPMCOUNTER25H)
DECLARE_CSR(mhpmcounter26h, CSR_MHPMCOUNTER26H)
DECLARE_CSR(mhpmcounter27h, CSR_MHPMCOUNTER27H)
DECLARE_CSR(mhpmcounter28h, CSR_MHPMCOUNTER28H)
DECLARE_CSR(mhpmcounter29h, CSR_MHPMCOUNTER29H)
DECLARE_CSR(mhpmcounter30h, CSR_MHPMCOUNTER30H)
DECLARE_CSR(mhpmcounter31h, CSR_MHPMCOUNTER31H)
#endif
#ifdef DECLARE_CAUSE
DECLARE_CAUSE("misaligned fetch", CAUSE_MISALIGNED_FETCH)
DECLARE_CAUSE("fetch access", CAUSE_FETCH_ACCESS)
DECLARE_CAUSE("illegal instruction", CAUSE_ILLEGAL_INSTRUCTION)
DECLARE_CAUSE("breakpoint", CAUSE_BREAKPOINT)
DECLARE_CAUSE("misaligned load", CAUSE_MISALIGNED_LOAD)
DECLARE_CAUSE("load access", CAUSE_LOAD_ACCESS)
DECLARE_CAUSE("misaligned store", CAUSE_MISALIGNED_STORE)
DECLARE_CAUSE("store access", CAUSE_STORE_ACCESS)
DECLARE_CAUSE("user_ecall", CAUSE_USER_ECALL)
DECLARE_CAUSE("supervisor_ecall", CAUSE_SUPERVISOR_ECALL)
DECLARE_CAUSE("hypervisor_ecall", CAUSE_HYPERVISOR_ECALL)
DECLARE_CAUSE("machine_ecall", CAUSE_MACHINE_ECALL)
DECLARE_CAUSE("fetch page fault", CAUSE_FETCH_PAGE_FAULT)
DECLARE_CAUSE("load page fault", CAUSE_LOAD_PAGE_FAULT)
DECLARE_CAUSE("store page fault", CAUSE_STORE_PAGE_FAULT)
#endif
