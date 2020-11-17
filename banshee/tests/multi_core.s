.globl _start
.section .text.init;
_start:
    csrr    a0, mhartid
    slli    t0, a0, 3
    li      t1, 0x20000000
    add     t0, t0, t1
    sw      a0, 0(t0)
    wfi
