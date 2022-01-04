// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include <snrt.h>

int main() {
    int errs = 0;

    if (snrt_is_compute_core()) {
        uint32_t i_a = 0x4048F5C3;   // 3.14
        uint32_t i_an = 0xC048F5C3;  // -3.14
        uint32_t i_b = 0x3FCF1AA0;   // 1.618
        uint32_t i_bn = 0xBFCF1AA0;  // -1.618
        uint32_t i_c = 0x4018FFEB;   // 2.39062
        uint32_t i_cn = 0xC018FFEB;  // -2.39062
        uint32_t i_d = 0x3E801FFB;   // 0.250244
        uint32_t i_dn = 0xBE801FFB;  // -0.250244
        uint32_t i_e = 0x3F000000;   // 0.5
        uint32_t i_en = 0xBF000000;  // -0.5
        uint32_t i_f = 0x42C83F36;   // 100.123456789
        uint32_t i_fn = 0xC2C83F36;  // -100.123456789

        int res0 = 0;
        uint32_t res1 = 0;
        uint32_t res2 = 0;
        uint32_t res3 = 0;

        asm volatile(
            "fmv.s.x ft4, %0\n"
            "fmv.s.x ft5, %1\n"
            "fmv.s.x ft6, %2\n"
            "fmv.s.x ft7, %3\n"
            : "+r"(i_a), "+r"(i_an), "+r"(i_b), "+r"(i_bn));

        // FSGNJ
        asm volatile(
            "fsgnj.s ft0, ft4, ft4\n"
            "feq.s %0, ft4, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fsgnj.s ft0, ft4, ft5\n"
            "feq.s %0, ft5, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fsgnj.s ft0, ft5, ft6\n"
            "feq.s %0, ft4, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fsgnj.s ft0, ft5, ft7\n"
            "feq.s %0, ft5, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        // FSGNJN
        asm volatile(
            "fsgnjn.s ft0, ft4, ft4\n"
            "feq.s %0, ft5, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fsgnjn.s ft0, ft4, ft5\n"
            "feq.s %0, ft4, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fsgnjn.s ft0, ft5, ft6\n"
            "feq.s %0, ft5, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fsgnjn.s ft0, ft5, ft7\n"
            "feq.s %0, ft4, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        // FSGNJX
        asm volatile(
            "fsgnjx.s ft0, ft4, ft4\n"
            "feq.s %0, ft4, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fsgnjx.s ft0, ft4, ft5\n"
            "feq.s %0, ft5, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fsgnjx.s ft0, ft5, ft6\n"
            "feq.s %0, ft5, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fsgnjx.s ft0, ft5, ft7\n"
            "feq.s %0, ft4, ft0\n"
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
        res1 = 0x4098418A;
        res2 = 0x3FEF229F;
        res3 = 0x42C8BF56;
        asm volatile(
            "fmv.s.x ft1, %0\n"
            "fmv.s.x ft2, %1\n"
            "fmv.s.x ft3, %2\n"
            : "+r"(res1), "+r"(res2), "+r"(res3));

        asm volatile(
            "fadd.s ft0, ft4, ft5\n"
            "feq.s %0, ft1, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fadd.s ft0, ft5, ft6\n"
            "feq.s %0, ft2, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fadd.s ft0, ft6, ft7\n"
            "feq.s %0, ft3, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        // FSUB
        // get results
        res1 = 0x3FC2D0E6;
        res2 = 0x3FAF12A1;
        res3 = 0xC2C7BF16;
        asm volatile(
            "fmv.s.x ft1, %0\n"
            "fmv.s.x ft2, %1\n"
            "fmv.s.x ft3, %2\n"
            : "+r"(res1), "+r"(res2), "+r"(res3));

        asm volatile(
            "fsub.s ft0, ft4, ft5\n"
            "feq.s %0, ft1, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fsub.s ft0, ft5, ft6\n"
            "feq.s %0, ft2, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fsub.s ft0, ft6, ft7\n"
            "feq.s %0, ft3, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        // FMUL
        // get results
        res1 = 0x40A2939F;
        res2 = 0x3ECF4E5F;
        res3 = 0x41C8713E;
        asm volatile(
            "fmv.s.x ft1, %0\n"
            "fmv.s.x ft2, %1\n"
            "fmv.s.x ft3, %2\n"
            : "+r"(res1), "+r"(res2), "+r"(res3));

        asm volatile(
            "fmul.s ft0, ft4, ft5\n"
            "feq.s %0, ft1, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fmul.s ft0, ft5, ft6\n"
            "feq.s %0, ft2, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fmul.s ft0, ft6, ft7\n"
            "feq.s %0, ft3, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        // FMADD
        // get results
        res1 = 0x40AA959F;
        res2 = 0x42C90E84;
        res3 = 0x41E18FF6;
        asm volatile(
            "fmv.s.x ft1, %0\n"
            "fmv.s.x ft2, %1\n"
            "fmv.s.x ft3, %2\n"
            : "+r"(res1), "+r"(res2), "+r"(res3));

        asm volatile(
            "fmadd.s ft0, ft4, ft5, ft6\n"
            "feq.s %0, ft1, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fmadd.s ft0, ft5, ft6, ft7, dyn\n"
            "feq.s %0, ft2, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fmadd.s ft0, ft6, ft7, ft4, dyn\n"
            "feq.s %0, ft3, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        // FNMADD
        // get results
        res1 = 0xC0AA959F;
        res2 = 0xC2C90E84;
        res3 = 0xC1E18FF6;
        asm volatile(
            "fmv.s.x ft1, %0\n"
            "fmv.s.x ft2, %1\n"
            "fmv.s.x ft3, %2\n"
            : "+r"(res1), "+r"(res2), "+r"(res3));

        asm volatile(
            "fnmadd.s ft0, ft4, ft5, ft6\n"
            "feq.s %0, ft1, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fnmadd.s ft0, ft5, ft6, ft7\n"
            "feq.s %0, ft2, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fnmadd.s ft0, ft6, ft7, ft4\n"
            "feq.s %0, ft3, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        // FMSUB
        // get results
        res1 = 0x409A91A0;
        res2 = 0xC2C76FE8;
        res3 = 0x41AF5286;
        asm volatile(
            "fmv.s.x ft1, %0\n"
            "fmv.s.x ft2, %1\n"
            "fmv.s.x ft3, %2\n"
            : "+r"(res1), "+r"(res2), "+r"(res3));

        asm volatile(
            "fmsub.s ft0, ft4, ft5, ft6\n"
            "feq.s %0, ft1, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fmsub.s ft0, ft5, ft6, ft7\n"
            "feq.s %0, ft2, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fmsub.s ft0, ft6, ft7, ft4\n"
            "feq.s %0, ft3, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        // FNMSUB
        // get results
        res1 = 0xC09A91A0;
        res2 = 0x42C76FE8;
        res3 = 0xC1AF5286;
        asm volatile(
            "fmv.s.x ft1, %0\n"
            "fmv.s.x ft2, %1\n"
            "fmv.s.x ft3, %2\n"
            : "+r"(res1), "+r"(res2), "+r"(res3));

        asm volatile(
            "fnmsub.s ft0, ft4, ft5, ft6\n"
            "feq.s %0, ft1, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fnmsub.s ft0, ft5, ft6, ft7\n"
            "feq.s %0, ft2, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);

        asm volatile(
            "fnmsub.s ft0, ft6, ft7, ft4\n"
            "feq.s %0, ft3, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x1);
    }

    return errs;
}
