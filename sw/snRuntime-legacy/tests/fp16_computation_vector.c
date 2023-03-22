// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include <snrt.h>

int main() {
    int errs = 46;

    if (snrt_is_compute_core()) {
        uint32_t i_a = 0x4048F5C3;   // 3.14 0
        uint32_t i_an = 0xC048F5C3;  // -3.14
        uint32_t i_b = 0x3FCF1AA0;   // 1.618 2
        uint32_t i_bn = 0xBFCF1AA0;  // -1.618
        uint32_t i_c = 0x4018FFEB;   // 2.39062
        uint32_t i_cn = 0xC018FFEB;  // -2.39062
        uint32_t i_d = 0x3E801FFB;   // 0.250244 6
        uint32_t i_dn = 0xBE801FFB;  // -0.250244
        uint32_t i_e = 0x3F000000;   // 0.5
        uint32_t i_en = 0xBF000000;  // -0.5
        uint32_t i_f = 0x42C83F36;   // 100.123456789 10
        uint32_t i_fn = 0xC2C83F36;  // -100.123456789

        int res0 = 0;
        uint32_t res1 = 0;
        uint32_t res2 = 0;
        uint32_t res3 = 0;
        uint32_t res4 = 0;

        asm volatile(
            "fmv.s.x ft0, %0\n"
            "fmv.s.x ft1, %1\n"
            "fmv.s.x ft2, %2\n"
            "fmv.s.x ft3, %3\n"
            "vfcpka.h.s ft4, ft0, ft2\n"
            "vfcpkb.h.s ft4, ft0, ft2\n"  // ft4 = {3.14, 1.618, 3.14, 1.618}
            "vfcpka.h.s ft5, ft1, ft3\n"
            "vfcpkb.h.s ft5, ft1, ft3\n"  // ft5 = {-3.14, -1.618,-3.14, -1.618}
            "vfcpka.h.s ft6, ft0, ft3\n"
            "vfcpkb.h.s ft6, ft0, ft3\n"  // ft6 = {3.14, -1.618, 3.14, -1.618}
            "vfcpka.h.s ft7, ft1, ft2\n"
            "vfcpkb.h.s ft7, ft1, ft2\n"  // ft7 = {-3.14, 1.618, -3.14, 1.618}
            : "+r"(i_a), "+r"(i_an), "+r"(i_b), "+r"(i_bn));

        // VFSGNJ
        asm volatile(
            "vfsgnj.h ft0, ft4, ft4\n"
            "vfeq.h %0, ft4, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xf);

        asm volatile(
            "vfsgnj.h ft0, ft4, ft5\n"
            "vfeq.h %0, ft5, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xf);

        asm volatile(
            "vfsgnj.h ft0, ft5, ft6\n"
            "vfeq.h %0, ft6, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xf);

        asm volatile(
            "vfsgnj.h ft0, ft5, ft7\n"
            "vfeq.h %0, ft7, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xf);

        // VFSGNJ.R
        asm volatile(
            "vfsgnj.r.h ft0, ft4, ft4\n"
            "vfeq.h %0, ft4, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xf);

        asm volatile(
            "vfsgnj.r.h ft0, ft4, ft5\n"
            "vfeq.h %0, ft5, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xf);

        asm volatile(
            "vfsgnj.r.h ft0, ft5, ft6\n"
            "vfeq.h %0, ft4, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xf);

        asm volatile(
            "vfsgnj.r.h ft0, ft5, ft7\n"
            "vfeq.h %0, ft5, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xf);

        // VFSGNJN
        asm volatile(
            "vfsgnjn.h ft0, ft4, ft4\n"
            "vfeq.h %0, ft5, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xf);

        asm volatile(
            "vfsgnjn.h ft0, ft4, ft5\n"
            "vfeq.h %0, ft4, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xf);

        asm volatile(
            "vfsgnjn.h ft0, ft5, ft6\n"
            "vfeq.h %0, ft7, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xf);

        asm volatile(
            "vfsgnjn.h ft0, ft5, ft7\n"
            "vfeq.h %0, ft6, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xf);

        // VFSGNJN.R
        asm volatile(
            "vfsgnjn.r.h ft0, ft4, ft4\n"
            "vfeq.h %0, ft5, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xf);

        asm volatile(
            "vfsgnjn.r.h ft0, ft4, ft5\n"
            "vfeq.h %0, ft4, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xf);

        asm volatile(
            "vfsgnjn.r.h ft0, ft5, ft6\n"
            "vfeq.h %0, ft5, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xf);

        asm volatile(
            "vfsgnjn.r.h ft0, ft5, ft7\n"
            "vfeq.h %0, ft4, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xf);

        // VFSGNJX
        asm volatile(
            "vfsgnjx.h ft0, ft4, ft4\n"
            "vfeq.h %0, ft4, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xf);

        asm volatile(
            "vfsgnjx.h ft0, ft4, ft5\n"
            "vfeq.h %0, ft5, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xf);

        asm volatile(
            "vfsgnjx.h ft0, ft5, ft6\n"
            "vfeq.h %0, ft7, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xf);

        asm volatile(
            "vfsgnjx.h ft0, ft5, ft7\n"
            "vfeq.h %0, ft6, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xf);

        // VFSGNJX.R
        asm volatile(
            "vfsgnjx.r.h ft0, ft4, ft4\n"
            "vfeq.h %0, ft4, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xf);

        asm volatile(
            "vfsgnjx.r.h ft0, ft4, ft5\n"
            "vfeq.h %0, ft5, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xf);

        asm volatile(
            "vfsgnjx.r.h ft0, ft5, ft6\n"
            "vfeq.h %0, ft5, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xf);

        asm volatile(
            "vfsgnjx.r.h ft0, ft5, ft7\n"
            "vfeq.h %0, ft4, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xf);

        // load new data
        asm volatile(
            "fmv.s.x ft0, %0\n"  // 3.14
            "fmv.s.x ft1, %1\n"  // -1.618
            "fmv.s.x ft2, %2\n"  // 0.250244
            "fmv.s.x ft3, %3\n"  // 100.123456789
            "vfcpka.h.s ft4, ft3, ft0\n"
            "vfcpkb.h.s ft4, ft3, ft0\n"  // ft4 = {100.123456789, 3.14,
                                          // 100.123456789, 3.14}
            "vfcpka.h.s ft5, ft2, ft1\n"
            "vfcpkb.h.s ft5, ft2, ft1\n"  // ft5 = {0.250244, -1.618, 0.250244,
                                          // -1.618}
            "vfcpka.h.s ft6, ft1, ft3\n"
            "vfcpkb.h.s ft6, ft1, ft3\n"  // ft6 = {-1.618, 100.123456789,
                                          // -1.618, 100.123456789}
            : "+r"(i_a), "+r"(i_bn), "+r"(i_d), "+r"(i_f));

        // VFADD
        // pack results
        res1 = 0x42C8C000;
        res2 = 0x3FC2E000;
        res3 = 0xBFAF2000;
        res4 = 0x42C50000;

        asm volatile(
            "fmv.s.x ft0, %0\n"
            "fmv.s.x ft1, %1\n"
            "fmv.s.x ft2, %2\n"
            "fmv.s.x ft3, %3\n"
            // pack h values
            "vfcpka.h.s ft7, ft0, ft1\n"
            "vfcpkb.h.s ft7, ft0, ft1\n"
            "vfcpka.h.s ft8, ft2, ft3\n"
            "vfcpkb.h.s ft8, ft2, ft3\n"
            : "+r"(res1), "+r"(res2), "+r"(res3), "+r"(res4));

        asm volatile(
            "vfadd.h ft0, ft4, ft5\n"
            "vfeq.h %0, ft7, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xf);

        asm volatile(
            "vfadd.h ft0, ft5, ft6\n"
            "vfeq.h %0, ft8, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xf);

        // VFADD.R
        // pack results
        res1 = 0x42C8C000;
        res2 = 0x40590000;
        res3 = 0xBFAF2000;
        res4 = 0xC04F2000;

        asm volatile(
            "fmv.s.x ft0, %0\n"
            "fmv.s.x ft1, %1\n"
            "fmv.s.x ft2, %2\n"
            "fmv.s.x ft3, %3\n"
            // pack h values
            "vfcpka.h.s ft7, ft0, ft1\n"
            "vfcpkb.h.s ft7, ft0, ft1\n"
            "vfcpka.h.s ft8, ft2, ft3\n"
            "vfcpkb.h.s ft8, ft2, ft3\n"
            : "+r"(res1), "+r"(res2), "+r"(res3), "+r"(res4));

        asm volatile(
            "vfadd.r.h ft0, ft4, ft5\n"
            "vfeq.h %0, ft7, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xf);

        asm volatile(
            "vfadd.r.h ft0, ft5, ft6\n"
            "vfeq.h %0, ft8, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xf);

        // VFSUB
        // pack results
        res1 = 0x42C7C000;
        res2 = 0x40984000;
        res3 = 0x3FEF2000;
        res4 = 0xC2CB8000;

        asm volatile(
            "fmv.s.x ft0, %0\n"
            "fmv.s.x ft1, %1\n"
            "fmv.s.x ft2, %2\n"
            "fmv.s.x ft3, %3\n"
            // pack h values
            "vfcpka.h.s ft7, ft0, ft1\n"
            "vfcpkb.h.s ft7, ft0, ft1\n"
            "vfcpka.h.s ft8, ft2, ft3\n"
            "vfcpkb.h.s ft8, ft2, ft3\n"
            : "+r"(res1), "+r"(res2), "+r"(res3), "+r"(res4));

        asm volatile(
            "vfsub.h ft0, ft4, ft5\n"
            "vfeq.h %0, ft7, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xf);

        asm volatile(
            "vfsub.h ft0, ft5, ft6\n"
            "vfeq.h %0, ft8, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xf);

        // VFSUB.R
        // pack results
        res1 = 0x42C7C000;
        res2 = 0x40390000;
        res3 = 0x3FEF2000;
        res4 = 0x00000000;

        asm volatile(
            "fmv.s.x ft0, %0\n"
            "fmv.s.x ft1, %1\n"
            "fmv.s.x ft2, %2\n"
            "fmv.s.x ft3, %3\n"
            // pack h values
            "vfcpka.h.s ft7, ft0, ft1\n"
            "vfcpkb.h.s ft7, ft0, ft1\n"
            "vfcpka.h.s ft8, ft2, ft3\n"
            "vfcpkb.h.s ft8, ft2, ft3\n"
            : "+r"(res1), "+r"(res2), "+r"(res3), "+r"(res4));

        asm volatile(
            "vfsub.r.h ft0, ft4, ft5\n"
            "vfeq.h %0, ft7, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xf);

        asm volatile(
            "vfsub.r.h ft0, ft5, ft6\n"
            "vfeq.h %0, ft8, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xf);

        // VFMUL
        // pack results
        res1 = 0x41C88000;
        res2 = 0xC0A2A000;
        res3 = 0xBECF6000;
        res4 = 0xC3220000;

        asm volatile(
            "fmv.s.x ft0, %0\n"
            "fmv.s.x ft1, %1\n"
            "fmv.s.x ft2, %2\n"
            "fmv.s.x ft3, %3\n"
            // pack h values
            "vfcpka.h.s ft7, ft0, ft1\n"
            "vfcpkb.h.s ft7, ft0, ft1\n"
            "vfcpka.h.s ft8, ft2, ft3\n"
            "vfcpkb.h.s ft8, ft2, ft3\n"
            : "+r"(res1), "+r"(res2), "+r"(res3), "+r"(res4));

        asm volatile(
            "vfmul.h ft0, ft4, ft5\n"
            "vfeq.h %0, ft7, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xf);

        asm volatile(
            "vfmul.h ft0, ft5, ft6\n"
            "vfeq.h %0, ft8, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xf);

        // VFMUL.R
        // pack results
        res1 = 0x41C88000;
        res2 = 0x3F494000;
        res3 = 0xBECF6000;
        res4 = 0x4027A000;

        asm volatile(
            "fmv.s.x ft0, %0\n"
            "fmv.s.x ft1, %1\n"
            "fmv.s.x ft2, %2\n"
            "fmv.s.x ft3, %3\n"
            // pack h values
            "vfcpka.h.s ft7, ft0, ft1\n"
            "vfcpkb.h.s ft7, ft0, ft1\n"
            "vfcpka.h.s ft8, ft2, ft3\n"
            "vfcpkb.h.s ft8, ft2, ft3\n"
            : "+r"(res1), "+r"(res2), "+r"(res3), "+r"(res4));

        asm volatile(
            "vfmul.r.h ft0, ft4, ft5\n"
            "vfeq.h %0, ft7, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xf);

        asm volatile(
            "vfmul.r.h ft0, ft5, ft6\n"
            "vfeq.h %0, ft8, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xf);

        // VFMAC
        // pack results
        res1 = 0x41C88000;
        res2 = 0xC0A2A000;
        res3 = 0x41C54000;
        res4 = 0xC3272000;

        asm volatile(
            "fmv.s.x ft0, %0\n"
            "fmv.s.x ft1, %1\n"
            "fmv.s.x ft2, %2\n"
            "fmv.s.x ft3, %3\n"
            // pack h values
            "vfcpka.h.s ft7, ft0, ft1\n"
            "vfcpkb.h.s ft7, ft0, ft1\n"
            "vfcpka.h.s ft8, ft2, ft3\n"
            "vfcpkb.h.s ft8, ft2, ft3\n"
            // reset ft0
            "fcvt.d.w ft0, zero\n"
            : "+r"(res1), "+r"(res2), "+r"(res3), "+r"(res4));

        asm volatile(
            "vfmac.h ft0, ft4, ft5\n"
            "vfeq.h %0, ft7, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xf);

        asm volatile(
            "vfmac.h ft0, ft5, ft6\n"
            "vfeq.h %0, ft8, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xf);

        // VFMAC.R
        // pack results
        res1 = 0x41C88000;
        res2 = 0x3F494000;
        res3 = 0x41C54000;
        res4 = 0x4059E000;

        asm volatile(
            "fmv.s.x ft0, %0\n"
            "fmv.s.x ft1, %1\n"
            "fmv.s.x ft2, %2\n"
            "fmv.s.x ft3, %3\n"
            // pack h values
            "vfcpka.h.s ft7, ft0, ft1\n"
            "vfcpkb.h.s ft7, ft0, ft1\n"
            "vfcpka.h.s ft8, ft2, ft3\n"
            "vfcpkb.h.s ft8, ft2, ft3\n"
            // reset ft0
            "fcvt.d.w ft0, zero\n"
            : "+r"(res1), "+r"(res2), "+r"(res3), "+r"(res4));

        asm volatile(
            "vfmac.r.h ft0, ft4, ft5\n"
            "vfeq.h %0, ft7, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xf);

        asm volatile(
            "vfmac.r.h ft0, ft5, ft6\n"
            "vfeq.h %0, ft8, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xf);

        // VFMRE
        // pack results
        res1 = 0xC1C88000;
        res2 = 0x40A2A000;
        res3 = 0xC1C54000;
        res4 = 0x43272000;

        asm volatile(
            "fmv.s.x ft0, %0\n"
            "fmv.s.x ft1, %1\n"
            "fmv.s.x ft2, %2\n"
            "fmv.s.x ft3, %3\n"
            // pack h values
            "vfcpka.h.s ft7, ft0, ft1\n"
            "vfcpkb.h.s ft7, ft0, ft1\n"
            "vfcpka.h.s ft8, ft2, ft3\n"
            "vfcpkb.h.s ft8, ft2, ft3\n"
            // reset ft0
            "fcvt.d.w ft0, zero\n"
            : "+r"(res1), "+r"(res2), "+r"(res3), "+r"(res4));

        asm volatile(
            "vfmre.h ft0, ft4, ft5\n"
            "vfeq.h %0, ft7, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xf);

        asm volatile(
            "vfmre.h ft0, ft5, ft6\n"
            "vfeq.h %0, ft8, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xf);

        // pack results
        res1 = 0x43096000;
        res2 = 0xC3136000;

        asm volatile(
            "fmv.s.x ft1, %0\n"
            "fmv.s.x ft2, %1\n"
            // pack h values
            "vfcpka.h.s ft7, ft1, ft2\n"
            "vfcpkb.h.s ft7, ft1, ft2\n"
            // do NOT reset ft0
            : "+r"(res1), "+r"(res2));

        asm volatile(
            "vfmre.h ft0, ft4, ft6\n"
            "vfeq.h %0, ft7, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xf);

        // VFMRE.R
        // pack results
        res1 = 0xC1C88000;
        res2 = 0xBF494000;
        res3 = 0xC1C54000;
        res4 = 0xC059E000;

        asm volatile(
            "fmv.s.x ft0, %0\n"
            "fmv.s.x ft1, %1\n"
            "fmv.s.x ft2, %2\n"
            "fmv.s.x ft3, %3\n"
            // pack h values
            "vfcpka.h.s ft7, ft0, ft1\n"
            "vfcpkb.h.s ft7, ft0, ft1\n"
            "vfcpka.h.s ft8, ft2, ft3\n"
            "vfcpkb.h.s ft8, ft2, ft3\n"
            // reset ft0
            "fcvt.d.w ft0, zero\n"
            : "+r"(res1), "+r"(res2), "+r"(res3), "+r"(res4));

        asm volatile(
            "vfmre.r.h ft0, ft4, ft5\n"
            "vfeq.h %0, ft7, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xf);

        asm volatile(
            "vfmre.r.h ft0, ft5, ft6\n"
            "vfeq.h %0, ft8, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xf);

        // pack results
        res1 = 0x43096000;
        res2 = 0x3FD6C000;

        asm volatile(
            "fmv.s.x ft1, %0\n"
            "fmv.s.x ft2, %1\n"
            // pack h values
            "vfcpka.h.s ft7, ft1, ft2\n"
            "vfcpkb.h.s ft7, ft1, ft2\n"
            // do NOT reset ft0
            : "+r"(res1), "+r"(res2));

        asm volatile(
            "vfmre.r.h ft0, ft4, ft6\n"
            "vfeq.h %0, ft7, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xf);
    }

    return errs;
}
