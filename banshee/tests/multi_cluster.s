.globl _start
.section .text.init;
_start:
    csrr    a0, mhartid
    li      a1, 0x40000040  # cluster_base_hartid
    lw      a1, 0(a1)
    slli    t0, a0, 4
    li      t1, 0x20000000
    add     t0, t0, t1
    sw      a0, 0(t0)
    sw      a1, 8(t0)
    wfi
