// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include <snrt.h>

int main() {
    int errs = 0;

    if (snrt_is_compute_core()) {
        uint32_t i_a = 0xFFFFFF45;   // 3.14
        uint32_t i_an = 0xFFFFFFC5;  // -3.14
        uint32_t i_b = 0xFFFFFF3D;   // 1.618
        uint32_t i_bn = 0xFFFFFFBD;  // -1.618
        uint32_t i_c = 0xFFFFFF42;   // 2.39062
        uint32_t i_cn = 0xFFFFFFC2;  // -2.39062
        uint32_t i_d = 0xFFFFFF28;   // 0.250244
        uint32_t i_dn = 0xFFFFFFA8;  // -0.250244
        uint32_t i_e = 0xFFFFFF30;   // 0.5
        uint32_t i_en = 0xFFFFFFB0;  // -0.5
        uint32_t i_f = 0xFFFFFF6D;   // 100.123456789
        uint32_t i_fn = 0xFFFFFFED;  // -100.123456789

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
            "fsgnj.ab ft0, ft4, ft4\n"
            "feq.ab %0, ft4, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fsgnj.ab ft0, ft4, ft5\n"
            "feq.ab %0, ft5, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fsgnj.ab ft0, ft5, ft6\n"
            "feq.ab %0, ft4, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fsgnj.ab ft0, ft5, ft7\n"
            "feq.ab %0, ft5, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        // FSGNJN
        asm volatile(
            "fsgnjn.ab ft0, ft4, ft4\n"
            "feq.ab %0, ft5, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fsgnjn.ab ft0, ft4, ft5\n"
            "feq.ab %0, ft4, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fsgnjn.ab ft0, ft5, ft6\n"
            "feq.ab %0, ft5, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fsgnjn.ab ft0, ft5, ft7\n"
            "feq.ab %0, ft4, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        // FSGNJX
        asm volatile(
            "fsgnjx.ab ft0, ft4, ft4\n"
            "feq.ab %0, ft4, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fsgnjx.ab ft0, ft4, ft5\n"
            "feq.ab %0, ft5, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fsgnjx.ab ft0, ft5, ft6\n"
            "feq.ab %0, ft5, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fsgnjx.ab ft0, ft5, ft7\n"
            "feq.ab %0, ft4, ft0\n"
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
        res1 = 0xFFFFFF4A;
        res2 = 0xFFFFFF3F;
        res3 = 0xFFFFFF6D;
        asm volatile(
            "fmv.s.x ft1, %0\n"
            "fmv.s.x ft2, %1\n"
            "fmv.s.x ft3, %2\n"
            : "+r"(res1), "+r"(res2), "+r"(res3));

        asm volatile(
            "fadd.ab ft0, ft4, ft5\n"
            "feq.ab %0, ft1, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fadd.ab ft0, ft5, ft6\n"
            "feq.ab %0, ft2, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fadd.ab ft0, ft6, ft7\n"
            "feq.ab %0, ft3, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        // FSUB
        // get results
        res1 = 0xFFFFFF3D;
        res2 = 0xFFFFFF3B;
        res3 = 0xFFFFFFED;
        asm volatile(
            "fmv.s.x ft1, %0\n"
            "fmv.s.x ft2, %1\n"
            "fmv.s.x ft3, %2\n"
            : "+r"(res1), "+r"(res2), "+r"(res3));

        asm volatile(
            "fsub.ab ft0, ft4, ft5\n"
            "feq.ab %0, ft1, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fsub.ab ft0, ft5, ft6\n"
            "feq.ab %0, ft2, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fsub.ab ft0, ft6, ft7\n"
            "feq.ab %0, ft3, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        // FMUL
        // get results
        res1 = 0xFFFFFF4B;
        res2 = 0xFFFFFF2D;
        res3 = 0xFFFFFF5D;
        asm volatile(
            "fmv.s.x ft1, %0\n"
            "fmv.s.x ft2, %1\n"
            "fmv.s.x ft3, %2\n"
            : "+r"(res1), "+r"(res2), "+r"(res3));

        asm volatile(
            "fmul.ab ft0, ft4, ft5\n"
            "feq.ab %0, ft1, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fmul.ab ft0, ft5, ft6\n"
            "feq.ab %0, ft2, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fmul.ab ft0, ft6, ft7\n"
            "feq.ab %0, ft3, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        // FMADD
        // get results
        res1 = 0xFFFFFF4B;
        res2 = 0xFFFFFF6D;
        res3 = 0xFFFFFF5F;
        asm volatile(
            "fmv.s.x ft1, %0\n"
            "fmv.s.x ft2, %1\n"
            "fmv.s.x ft3, %2\n"
            : "+r"(res1), "+r"(res2), "+r"(res3));

        asm volatile(
            "fmadd.ab ft0, ft4, ft5, ft6\n"
            "feq.ab %0, ft1, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fmadd.ab ft0, ft5, ft6, ft7, dyn\n"
            "feq.ab %0, ft2, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fmadd.ab ft0, ft6, ft7, ft4, dyn\n"
            "feq.ab %0, ft3, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        // FNMADD
        // get results
        res1 = 0xFFFFFFCB;
        res2 = 0xFFFFFFED;
        res3 = 0xFFFFFFDF;
        asm volatile(
            "fmv.s.x ft1, %0\n"
            "fmv.s.x ft2, %1\n"
            "fmv.s.x ft3, %2\n"
            : "+r"(res1), "+r"(res2), "+r"(res3));

        asm volatile(
            "fnmadd.ab ft0, ft4, ft5, ft6\n"
            "feq.ab %0, ft1, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fnmadd.ab ft0, ft5, ft6, ft7\n"
            "feq.ab %0, ft2, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fnmadd.ab ft0, ft6, ft7, ft4\n"
            "feq.ab %0, ft3, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        // FMSUB
        // get results
        res1 = 0xFFFFFF4A;
        res2 = 0xFFFFFFED;
        res3 = 0xFFFFFF5B;
        asm volatile(
            "fmv.s.x ft1, %0\n"
            "fmv.s.x ft2, %1\n"
            "fmv.s.x ft3, %2\n"
            : "+r"(res1), "+r"(res2), "+r"(res3));

        asm volatile(
            "fmsub.ab ft0, ft4, ft5, ft6\n"
            "feq.ab %0, ft1, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fmsub.ab ft0, ft5, ft6, ft7\n"
            "feq.ab %0, ft2, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fmsub.ab ft0, ft6, ft7, ft4\n"
            "feq.ab %0, ft3, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        // FNMSUB
        // get results
        res1 = 0xFFFFFFCA;
        res2 = 0xFFFFFF6D;
        res3 = 0xFFFFFFDB;
        asm volatile(
            "fmv.s.x ft1, %0\n"
            "fmv.s.x ft2, %1\n"
            "fmv.s.x ft3, %2\n"
            : "+r"(res1), "+r"(res2), "+r"(res3));

        asm volatile(
            "fnmsub.ab ft0, ft4, ft5, ft6\n"
            "feq.ab %0, ft1, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fnmsub.ab ft0, ft5, ft6, ft7\n"
            "feq.ab %0, ft2, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fnmsub.ab ft0, ft6, ft7, ft4\n"
            "feq.ab %0, ft3, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);
    }

    return errs;
}
