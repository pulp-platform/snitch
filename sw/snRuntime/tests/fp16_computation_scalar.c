// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include <snrt.h>

int main() {

    int errs = 0;

    if (snrt_is_compute_core()) {

        uint32_t i_a  = 0xFFFF4248; // 3.14
        uint32_t i_an = 0xFFFFC248; // -3.14
        uint32_t i_b  = 0xFFFF3E79; // 1.618
        uint32_t i_bn = 0xFFFFBE79; // -1.618
        uint32_t i_c  = 0xFFFF40C8; // 2.39062
        uint32_t i_cn = 0xFFFFC0C8; // -2.39062
        uint32_t i_d  = 0xFFFF3401; // 0.250244
        uint32_t i_dn = 0xFFFFB401; // -0.250244
        uint32_t i_e  = 0xFFFF3800; // 0.5
        uint32_t i_en = 0xFFFFB800; // -0.5
        uint32_t i_f  = 0xFFFF5642; // 100.123456789
        uint32_t i_fn = 0xFFFFD642; // -100.123456789

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
            "fsgnj.h ft0, ft4, ft4\n"
            "feq.h %0, ft4, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        asm volatile(
            "fsgnj.h ft0, ft4, ft5\n"
            "feq.h %0, ft5, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        asm volatile(
            "fsgnj.h ft0, ft5, ft6\n"
            "feq.h %0, ft4, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        asm volatile(
            "fsgnj.h ft0, ft5, ft7\n"
            "feq.h %0, ft5, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        // FSGNJN
        asm volatile(
            "fsgnjn.h ft0, ft4, ft4\n"
            "feq.h %0, ft5, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        asm volatile(
            "fsgnjn.h ft0, ft4, ft5\n"
            "feq.h %0, ft4, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        asm volatile(
            "fsgnjn.h ft0, ft5, ft6\n"
            "feq.h %0, ft5, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        asm volatile(
            "fsgnjn.h ft0, ft5, ft7\n"
            "feq.h %0, ft4, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        // FSGNJX
        asm volatile(
            "fsgnjx.h ft0, ft4, ft4\n"
            "feq.h %0, ft4, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        asm volatile(
            "fsgnjx.h ft0, ft4, ft5\n"
            "feq.h %0, ft5, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        asm volatile(
            "fsgnjx.h ft0, ft5, ft6\n"
            "feq.h %0, ft5, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        asm volatile(
            "fsgnjx.h ft0, ft5, ft7\n"
            "feq.h %0, ft4, ft0\n"
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
        res1  = 0xFFFF44C2;
        res2  = 0xFFFF3F79;
        res3  = 0xFFFF5646;
        asm volatile(
            "fmv.s.x ft1, %0\n"
            "fmv.s.x ft2, %1\n"
            "fmv.s.x ft3, %2\n"
            : "+r"(res1), "+r"(res2), "+r"(res3)
        );

        asm volatile(
            "fadd.h ft0, ft4, ft5\n"
            "feq.h %0, ft1, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        asm volatile(
            "fadd.h ft0, ft5, ft6\n"
            "feq.h %0, ft2, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        asm volatile(
            "fadd.h ft0, ft6, ft7\n"
            "feq.h %0, ft3, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        // FSUB
        // get results
        res1  = 0xFFFF3E17;
        res2  = 0xFFFF3D79;
        res3  = 0xFFFFD63E;
        asm volatile(
            "fmv.s.x ft1, %0\n"
            "fmv.s.x ft2, %1\n"
            "fmv.s.x ft3, %2\n"
            : "+r"(res1), "+r"(res2), "+r"(res3)
        );

        asm volatile(
            "fsub.h ft0, ft4, ft5\n"
            "feq.h %0, ft1, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        asm volatile(
            "fsub.h ft0, ft5, ft6\n"
            "feq.h %0, ft2, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        asm volatile(
            "fsub.h ft0, ft6, ft7\n"
            "feq.h %0, ft3, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        // FMUL
        // get results
        res1  = 0xFFFF4515;
        res2  = 0xFFFF367B;
        res3  = 0xFFFF4E44;
        asm volatile(
            "fmv.s.x ft1, %0\n"
            "fmv.s.x ft2, %1\n"
            "fmv.s.x ft3, %2\n"
            : "+r"(res1), "+r"(res2), "+r"(res3)
        );

        asm volatile(
            "fmul.h ft0, ft4, ft5\n"
            "feq.h %0, ft1, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        asm volatile(
            "fmul.h ft0, ft5, ft6\n"
            "feq.h %0, ft2, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        asm volatile(
            "fmul.h ft0, ft6, ft7\n"
            "feq.h %0, ft3, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        // FMADD
        // get results
        res1  = 0xFFFF4555;
        res2  = 0xFFFF5648;
        res3  = 0xFFFF4F0D;
        asm volatile(
            "fmv.s.x ft1, %0\n"
            "fmv.s.x ft2, %1\n"
            "fmv.s.x ft3, %2\n"
            : "+r"(res1), "+r"(res2), "+r"(res3)
        );

        asm volatile(
            "fmadd.h ft0, ft4, ft5, ft6\n"
            "feq.h %0, ft1, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        asm volatile(
            "fmadd.h ft0, ft5, ft6, ft7, dyn\n"
            "feq.h %0, ft2, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        asm volatile(
            "fmadd.h ft0, ft6, ft7, ft4, dyn\n"
            "feq.h %0, ft3, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        // FNMADD
        // get results
        res1  = 0xFFFFC555;
        res2  = 0xFFFFD648;
        res3  = 0xFFFFCF0D;
        asm volatile(
            "fmv.s.x ft1, %0\n"
            "fmv.s.x ft2, %1\n"
            "fmv.s.x ft3, %2\n"
            : "+r"(res1), "+r"(res2), "+r"(res3)
        );

        asm volatile(
            "fnmadd.h ft0, ft4, ft5, ft6\n"
            "feq.h %0, ft1, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        asm volatile(
            "fnmadd.h ft0, ft5, ft6, ft7\n"
            "feq.h %0, ft2, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        asm volatile(
            "fnmadd.h ft0, ft6, ft7, ft4\n"
            "feq.h %0, ft3, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        // FMSUB
        // get results
        res1  = 0xFFFF44D5;
        res2  = 0xFFFFD63C;
        res3  = 0xFFFF4D7B;
        asm volatile(
            "fmv.s.x ft1, %0\n"
            "fmv.s.x ft2, %1\n"
            "fmv.s.x ft3, %2\n"
            : "+r"(res1), "+r"(res2), "+r"(res3)
        );

        asm volatile(
            "fmsub.h ft0, ft4, ft5, ft6\n"
            "feq.h %0, ft1, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        asm volatile(
            "fmsub.h ft0, ft5, ft6, ft7\n"
            "feq.h %0, ft2, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        asm volatile(
            "fmsub.h ft0, ft6, ft7, ft4\n"
            "feq.h %0, ft3, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        // FNMSUB
        // get results
        res1  = 0xFFFFC4D5;
        res2  = 0xFFFF563C;
        res3  = 0xFFFFCD7B;
        asm volatile(
            "fmv.s.x ft1, %0\n"
            "fmv.s.x ft2, %1\n"
            "fmv.s.x ft3, %2\n"
            : "+r"(res1), "+r"(res2), "+r"(res3)
        );

        asm volatile(
            "fnmsub.h ft0, ft4, ft5, ft6\n"
            "feq.h %0, ft1, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        asm volatile(
            "fnmsub.h ft0, ft5, ft6, ft7\n"
            "feq.h %0, ft2, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

        asm volatile(
            "fnmsub.h ft0, ft6, ft7, ft4\n"
            "feq.h %0, ft3, ft0\n"
            : "+r"(res0)
        );
        errs += (res0!=0x1);

    }

    return errs;

}
