.globl _start
.section .text.init;
_start:
    mv      s0, zero

    # Check TCDM
    la      a0, buffer_tcdm
    call    check
    add     s0, s0, a0

    # Check Global
    la      a0, buffer_global
    call    check
    add     s0, s0, a0

    slli    s0, s0, 1
    ori     s0, s0, 1
    la      t0, scratch_reg
    sw      s0, 0(t0)
    wfi

check:
    mv      a1, a0
    li      a0, 0

    # Byte
    li      t0, 0xffffff80
    li      t1, 0xffffff81
    li      t2, 0xffffff82
    li      t3, 0xffffff83
    sb      t0, 0(a1)
    sb      t1, 1(a1)
    sb      t2, 2(a1)
    sb      t3, 3(a1)

    lw      t0, 0(a1)
    li      t1, 0x83828180
    sub     t0, t0, t1
    snez    t0, t0
    add     a0, a0, t0

    # Half-Word
    li      t0, 0xffff8584
    li      t1, 0xffff8786
    sh      t0, 0(a1)
    sh      t1, 2(a1)

    lw      t0, 0(a1)
    li      t1, 0x87868584
    sub     t0, t0, t1
    snez    t0, t0
    add     a0, a0, t0

    ret

.align 3
buffer_global: .word 0

.section .l1,"aw",@progbits
.align 3
buffer_tcdm: .word 0
