.globl _start
.section .text.init;
_start:
    mv      a0, zero

    # Byte Signed
    lb      s0, magic+0
    lb      s1, magic+1
    lb      s2, magic+2
    lb      s3, magic+3

    li      t0, 0xffffff80
    sub     t0, t0, s0
    snez    t0, t0
    add     a0, a0, t0
    li      t0, 0xffffff81
    sub     t0, t0, s1
    snez    t0, t0
    add     a0, a0, t0
    li      t0, 0xffffff82
    sub     t0, t0, s2
    snez    t0, t0
    add     a0, a0, t0
    li      t0, 0xffffff83
    sub     t0, t0, s3
    snez    t0, t0
    add     a0, a0, t0

    # Byte Unsigned
    lbu      s0, magic+0
    lbu      s1, magic+1
    lbu      s2, magic+2
    lbu      s3, magic+3

    li      t0, 0x80
    sub     t0, t0, s0
    snez    t0, t0
    add     a0, a0, t0
    li      t0, 0x81
    sub     t0, t0, s1
    snez    t0, t0
    add     a0, a0, t0
    li      t0, 0x82
    sub     t0, t0, s2
    snez    t0, t0
    add     a0, a0, t0
    li      t0, 0x83
    sub     t0, t0, s3
    snez    t0, t0
    add     a0, a0, t0

    # Half-Word Signed
    lh      s0, magic+0
    lh      s1, magic+2

    li      t0, 0xffff8180
    sub     t0, t0, s0
    snez    t0, t0
    add     a0, a0, t0
    li      t0, 0xffff8382
    sub     t0, t0, s1
    snez    t0, t0
    add     a0, a0, t0

    # Half-Word Unsigned
    lhu      s0, magic+0
    lhu      s1, magic+2

    li      t0, 0x8180
    sub     t0, t0, s0
    snez    t0, t0
    add     a0, a0, t0
    li      t0, 0x8382
    sub     t0, t0, s1
    snez    t0, t0
    add     a0, a0, t0

    slli    a0, a0, 1
    ori     a0, a0, 1
    la      t0, scratch_reg
    sw      a0, 0(t0)
    wfi

.align 3
magic: .word 0x83828180
