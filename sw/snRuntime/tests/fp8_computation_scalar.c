// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include <snrt.h>

int main() {

    int errs = 0;

    if (snrt_is_compute_core()) {

        uint32_t i_a  = 0xFFFFFF42; // 3.14
        uint32_t i_an = 0xFFFFFFC2; // -3.14
        uint32_t i_b  = 0xFFFFFF3E; // 1.618
        uint32_t i_bn = 0xFFFFFFBE; // -1.618
        uint32_t i_c  = 0xFFFFFF41; // 2.39062
        uint32_t i_cn = 0xFFFFFFC1; // -2.39062
        uint32_t i_d  = 0xFFFFFF34; // 0.250244
        uint32_t i_dn = 0xFFFFFFB4; // -0.250244
        uint32_t i_e  = 0xFFFFFF38; // 0.5
        uint32_t i_en = 0xFFFFFFB8; // -0.5
        uint32_t i_f  = 0xFFFFFF56; // 100.123456789
        uint32_t i_fn = 0xFFFFFFD6; // -100.123456789

        int res0 = 0;
        uint32_t res1 = 0;
        uint32_t res2 = 0;
        uint32_t res3 = 0;

        asm volatile(
            "fmv.s.x ft4, %0\n"
            "fmv.s.x ft5, %1\n"
            "fmv.s.x ft6, %2\n"
            "fmv.s.x ft7, %3\n"
            : "+r"(i_a), "+r"(i_an), "+r"(i_b), "+r"(i_bn)
        );

        // FSGNJ
        asm volatile(
            "fsgnj.b ft0, ft4, ft4\n"
            "feq.b %0, ft4, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        asm volatile(
            "fsgnj.b ft0, ft4, ft5\n"
            "feq.b %0, ft5, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        asm volatile(
            "fsgnj.b ft0, ft5, ft6\n"
            "feq.b %0, ft4, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        asm volatile(
            "fsgnj.b ft0, ft5, ft7\n"
            "feq.b %0, ft5, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        // FSGNJN
        asm volatile(
            "fsgnjn.b ft0, ft4, ft4\n"
            "feq.b %0, ft5, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        asm volatile(
            "fsgnjn.b ft0, ft4, ft5\n"
            "feq.b %0, ft4, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        asm volatile(
            "fsgnjn.b ft0, ft5, ft6\n"
            "feq.b %0, ft5, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        asm volatile(
            "fsgnjn.b ft0, ft5, ft7\n"
            "feq.b %0, ft4, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        // FSGNJX
        asm volatile(
            "fsgnjx.b ft0, ft4, ft4\n"
            "feq.b %0, ft4, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        asm volatile(
            "fsgnjx.b ft0, ft4, ft5\n"
            "feq.b %0, ft5, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        asm volatile(
            "fsgnjx.b ft0, ft5, ft6\n"
            "feq.b %0, ft5, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        asm volatile(
            "fsgnjx.b ft0, ft5, ft7\n"
            "feq.b %0, ft4, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);


        // load new data
        asm volatile(
            "fmv.s.x ft4, %0\n"
            "fmv.s.x ft5, %1\n"
            "fmv.s.x ft6, %2\n"
            "fmv.s.x ft7, %3\n"
            : "+r"(i_a), "+r"(i_b), "+r"(i_d), "+r"(i_f)
        );

        // FADD
        // get results
        res1  = 0xFFFFFF44;
        res2  = 0xFFFFFF3F;
        res3  = 0xFFFFFF56;
        asm volatile(
            "fmv.s.x ft1, %0\n"
            "fmv.s.x ft2, %1\n"
            "fmv.s.x ft3, %2\n"
            : "+r"(res1), "+r"(res2), "+r"(res3)
        );

        asm volatile(
            "fadd.b ft0, ft4, ft5\n"
            "feq.b %0, ft1, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        asm volatile(
            "fadd.b ft0, ft5, ft6\n"
            "feq.b %0, ft2, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        asm volatile(
            "fadd.b ft0, ft6, ft7\n"
            "feq.b %0, ft3, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        // FSUB
        // get results
        res1  = 0xFFFFFF3E;
        res2  = 0xFFFFFF3D;
        res3  = 0xFFFFFFD6;
        asm volatile(
            "fmv.s.x ft1, %0\n"
            "fmv.s.x ft2, %1\n"
            "fmv.s.x ft3, %2\n"
            : "+r"(res1), "+r"(res2), "+r"(res3)
        );

        asm volatile(
            "fsub.b ft0, ft4, ft5\n"
            "feq.b %0, ft1, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        asm volatile(
            "fsub.b ft0, ft5, ft6\n"
            "feq.b %0, ft2, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        asm volatile(
            "fsub.b ft0, ft6, ft7\n"
            "feq.b %0, ft3, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        // FMUL
        // get results
        res1  = 0xFFFFFF44;
        res2  = 0xFFFFFF36;
        res3  = 0xFFFFFF4E;
        asm volatile(
            "fmv.s.x ft1, %0\n"
            "fmv.s.x ft2, %1\n"
            "fmv.s.x ft3, %2\n"
            : "+r"(res1), "+r"(res2), "+r"(res3)
        );

        asm volatile(
            "fmul.b ft0, ft4, ft5\n"
            "feq.b %0, ft1, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        asm volatile(
            "fmul.b ft0, ft5, ft6\n"
            "feq.b %0, ft2, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        asm volatile(
            "fmul.b ft0, ft6, ft7\n"
            "feq.b %0, ft3, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        // FMADD
        // get results
        res1  = 0xFFFFFF45;
        res2  = 0xFFFFFF56;
        res3  = 0xFFFFFF4F;
        asm volatile(
            "fmv.s.x ft1, %0\n"
            "fmv.s.x ft2, %1\n"
            "fmv.s.x ft3, %2\n"
            : "+r"(res1), "+r"(res2), "+r"(res3)
        );

        asm volatile(
            "fmadd.b ft0, ft4, ft5, ft6\n"
            "feq.b %0, ft1, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        asm volatile(
            "fmadd.b ft0, ft5, ft6, ft7, dyn\n"
            "feq.b %0, ft2, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        asm volatile(
            "fmadd.b ft0, ft6, ft7, ft4, dyn\n"
            "feq.b %0, ft3, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        // FNMADD
        // get results
        res1  = 0xFFFFFFC5;
        res2  = 0xFFFFFFD6;
        res3  = 0xFFFFFFCF;
        asm volatile(
            "fmv.s.x ft1, %0\n"
            "fmv.s.x ft2, %1\n"
            "fmv.s.x ft3, %2\n"
            : "+r"(res1), "+r"(res2), "+r"(res3)
        );

        asm volatile(
            "fnmadd.b ft0, ft4, ft5, ft6\n"
            "feq.b %0, ft1, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        asm volatile(
            "fnmadd.b ft0, ft5, ft6, ft7\n"
            "feq.b %0, ft2, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        asm volatile(
            "fnmadd.b ft0, ft6, ft7, ft4\n"
            "feq.b %0, ft3, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        // FMSUB
        // get results
        res1  = 0xFFFFFF44;
        res2  = 0xFFFFFFD6;
        res3  = 0xFFFFFF4D;
        asm volatile(
            "fmv.s.x ft1, %0\n"
            "fmv.s.x ft2, %1\n"
            "fmv.s.x ft3, %2\n"
            : "+r"(res1), "+r"(res2), "+r"(res3)
        );

        asm volatile(
            "fmsub.b ft0, ft4, ft5, ft6\n"
            "feq.b %0, ft1, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        asm volatile(
            "fmsub.b ft0, ft5, ft6, ft7\n"
            "feq.b %0, ft2, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        asm volatile(
            "fmsub.b ft0, ft6, ft7, ft4\n"
            "feq.b %0, ft3, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        // FNMSUB
        // get results
        res1  = 0xFFFFFFC4;
        res2  = 0xFFFFFF56;
        res3  = 0xFFFFFFCD;
        asm volatile(
            "fmv.s.x ft1, %0\n"
            "fmv.s.x ft2, %1\n"
            "fmv.s.x ft3, %2\n"
            : "+r"(res1), "+r"(res2), "+r"(res3)
        );

        asm volatile(
            "fnmsub.b ft0, ft4, ft5, ft6\n"
            "feq.b %0, ft1, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        asm volatile(
            "fnmsub.b ft0, ft5, ft6, ft7\n"
            "feq.b %0, ft2, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        asm volatile(
            "fnmsub.b ft0, ft6, ft7, ft4\n"
            "feq.b %0, ft3, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

    }

    return errs;

}
