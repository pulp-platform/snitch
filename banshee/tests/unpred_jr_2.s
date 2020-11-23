.globl _start
.section .text.init;
_start:
    li      a0, 1
    lw      t0, magic
    jr      t0
    j       end
fix:
    li      a0, 0
end:
    slli    a0, a0, 1
    ori     a0, a0, 1
    la      t0, scratch_reg
    sw      a0, 0(t0)
    wfi

.align 3
magic: .word fix
