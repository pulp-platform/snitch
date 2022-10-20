.text
    li       t0, 2
    li       t1, 5
    li       t2, 6
    fcvt.d.w ft0, t0
    fcvt.d.w ft1, t1
    fcvt.d.w ft4, t2
    fadd.d   ft3, ft0, ft1
    fmul.d   ft2, ft4, ft3
    fadd.d   ft3, ft0, ft1
    fmul.d   ft2, ft4, ft3
    fadd.d   ft3, ft0, ft1
    fmul.d   ft2, ft4, ft3
    fadd.d   ft3, ft0, ft1
    fmul.d   ft2, ft4, ft3
    # Expected result (2 + 5) * 6 = 42
    # Return exit code to host to terminate simulation
    la       t1, tohost
    li       a0, 1
    sw       a0, 0(t1) # (exit code << 1) | 1
1:
    wfi
    j        1b

# HTIF sections
.pushsection .htif,"aw",@progbits;
.align 6; .global tohost; tohost: .dword 0;
.align 6; .global fromhost; fromhost: .dword 0;
