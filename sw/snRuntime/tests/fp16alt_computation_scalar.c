// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include <snrt.h>

int main() {
    int errs = 0;

    if (snrt_is_compute_core()) {
        uint32_t i_a = 0xFFFF4049;   // 3.14
        uint32_t i_an = 0xFFFFC049;  // -3.14
        uint32_t i_b = 0xFFFF3FCF;   // 1.618
        uint32_t i_bn = 0xFFFFBFCF;  // -1.618
        uint32_t i_c = 0xFFFF4019;   // 2.39062
        uint32_t i_cn = 0xFFFFC019;  // -2.39062
        uint32_t i_d = 0xFFFF3E80;   // 0.250244
        uint32_t i_dn = 0xFFFFBE80;  // -0.250244
        uint32_t i_e = 0xFFFF3F00;   // 0.5
        uint32_t i_en = 0xFFFFBF00;  // -0.5
        uint32_t i_f = 0xFFFF42C8;   // 100.123456789
        uint32_t i_fn = 0xFFFFC2C8;  // -100.123456789

        int res0 = 0;
        uint32_t res1 = 0;
        uint32_t res2 = 0;
        uint32_t res3 = 0;

        write_csr(2048, 3);

        asm volatile(
            "fmv.s.x ft4, %0\n"
            "fmv.s.x ft5, %1\n"
            "fmv.s.x ft6, %2\n"
            "fmv.s.x ft7, %3\n"
            : "+r"(i_a), "+r"(i_an), "+r"(i_b), "+r"(i_bn));

        // FSGNJ
        asm volatile(
            "fsgnj.ah ft0, ft4, ft4\n"
            "feq.ah %0, ft4, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fsgnj.ah ft0, ft4, ft5\n"
            "feq.ah %0, ft5, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fsgnj.ah ft0, ft5, ft6\n"
            "feq.ah %0, ft4, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fsgnj.ah ft0, ft5, ft7\n"
            "feq.ah %0, ft5, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        // FSGNJN
        asm volatile(
            "fsgnjn.ah ft0, ft4, ft4\n"
            "feq.ah %0, ft5, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fsgnjn.ah ft0, ft4, ft5\n"
            "feq.ah %0, ft4, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fsgnjn.ah ft0, ft5, ft6\n"
            "feq.ah %0, ft5, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fsgnjn.ah ft0, ft5, ft7\n"
            "feq.ah %0, ft4, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        // FSGNJX
        asm volatile(
            "fsgnjx.ah ft0, ft4, ft4\n"
            "feq.ah %0, ft4, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fsgnjx.ah ft0, ft4, ft5\n"
            "feq.ah %0, ft5, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fsgnjx.ah ft0, ft5, ft6\n"
            "feq.ah %0, ft5, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fsgnjx.ah ft0, ft5, ft7\n"
            "feq.ah %0, ft4, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        // load new data
        asm volatile(
            "fmv.s.x ft4, %0\n"
            "fmv.s.x ft5, %1\n"
            "fmv.s.x ft6, %2\n"
            "fmv.s.x ft7, %3\n"
            : "+r"(i_a), "+r"(i_b), "+r"(i_d), "+r"(i_f));

        // FADD
        // get results
        res1 = 0xFFFF4098;
        res2 = 0xFFFF3FEF;
        res3 = 0xFFFF42C8;
        asm volatile(
            "fmv.s.x ft1, %0\n"
            "fmv.s.x ft2, %1\n"
            "fmv.s.x ft3, %2\n"
            : "+r"(res1), "+r"(res2), "+r"(res3));

        asm volatile(
            "fadd.ah ft0, ft4, ft5\n"
            "feq.ah %0, ft1, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fadd.ah ft0, ft5, ft6\n"
            "feq.ah %0, ft2, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fadd.ah ft0, ft6, ft7\n"
            "feq.ah %0, ft3, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        // FSUB
        // get results
        res1 = 0xFFFF3FC3;
        res2 = 0xFFFF3FAF;
        res3 = 0xFFFFC2C8;
        asm volatile(
            "fmv.s.x ft1, %0\n"
            "fmv.s.x ft2, %1\n"
            "fmv.s.x ft3, %2\n"
            : "+r"(res1), "+r"(res2), "+r"(res3));

        asm volatile(
            "fsub.ah ft0, ft4, ft5\n"
            "feq.ah %0, ft1, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fsub.ah ft0, ft5, ft6\n"
            "feq.ah %0, ft2, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fsub.ah ft0, ft6, ft7\n"
            "feq.ah %0, ft3, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        // FMUL
        // get results
        res1 = 0xFFFF40A3;
        res2 = 0xFFFF3ECF;
        res3 = 0xFFFF41C8;
        asm volatile(
            "fmv.s.x ft1, %0\n"
            "fmv.s.x ft2, %1\n"
            "fmv.s.x ft3, %2\n"
            : "+r"(res1), "+r"(res2), "+r"(res3));

        asm volatile(
            "fmul.ah ft0, ft4, ft5\n"
            "feq.ah %0, ft1, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fmul.ah ft0, ft5, ft6\n"
            "feq.ah %0, ft2, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fmul.ah ft0, ft6, ft7\n"
            "feq.ah %0, ft3, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        // FMADD
        // get results
        res1 = 0xFFFF40AB;
        res2 = 0xFFFF42C9;
        res3 = 0xFFFF41E1;
        asm volatile(
            "fmv.s.x ft1, %0\n"
            "fmv.s.x ft2, %1\n"
            "fmv.s.x ft3, %2\n"
            : "+r"(res1), "+r"(res2), "+r"(res3));

        asm volatile(
            "fmadd.ah ft0, ft4, ft5, ft6\n"
            "feq.ah %0, ft1, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fmadd.ah ft0, ft5, ft6, ft7, dyn\n"
            "feq.ah %0, ft2, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fmadd.ah ft0, ft6, ft7, ft4, dyn\n"
            "feq.ah %0, ft3, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        // FNMADD
        // get results
        res1 = 0xFFFFC0AB;
        res2 = 0xFFFFC2C9;
        res3 = 0xFFFFC1E1;
        asm volatile(
            "fmv.s.x ft1, %0\n"
            "fmv.s.x ft2, %1\n"
            "fmv.s.x ft3, %2\n"
            : "+r"(res1), "+r"(res2), "+r"(res3));

        asm volatile(
            "fnmadd.ah ft0, ft4, ft5, ft6\n"
            "feq.ah %0, ft1, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fnmadd.ah ft0, ft5, ft6, ft7\n"
            "feq.ah %0, ft2, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fnmadd.ah ft0, ft6, ft7, ft4\n"
            "feq.ah %0, ft3, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        // FMSUB
        // get results
        res1 = 0xFFFF409B;
        res2 = 0xFFFFC2C7;
        res3 = 0xFFFF41AF;
        asm volatile(
            "fmv.s.x ft1, %0\n"
            "fmv.s.x ft2, %1\n"
            "fmv.s.x ft3, %2\n"
            : "+r"(res1), "+r"(res2), "+r"(res3));

        asm volatile(
            "fmsub.ah ft0, ft4, ft5, ft6\n"
            "feq.ah %0, ft1, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fmsub.ah ft0, ft5, ft6, ft7\n"
            "feq.ah %0, ft2, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fmsub.ah ft0, ft6, ft7, ft4\n"
            "feq.ah %0, ft3, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        // FNMSUB
        // get results
        res1 = 0xFFFFC09B;
        res2 = 0xFFFF42C7;
        res3 = 0xFFFFC1AF;
        asm volatile(
            "fmv.s.x ft1, %0\n"
            "fmv.s.x ft2, %1\n"
            "fmv.s.x ft3, %2\n"
            : "+r"(res1), "+r"(res2), "+r"(res3));

        asm volatile(
            "fnmsub.ah ft0, ft4, ft5, ft6\n"
            "feq.ah %0, ft1, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fnmsub.ah ft0, ft5, ft6, ft7\n"
            "feq.ah %0, ft2, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fnmsub.ah ft0, ft6, ft7, ft4\n"
            "feq.ah %0, ft3, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);
    }

    return errs;
}
