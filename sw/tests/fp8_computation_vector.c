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
            "vfcpka.b.s ft4, ft0, ft2\n"
            "vfcpkb.b.s ft4, ft0, ft2\n"
            "vfcpkc.b.s ft4, ft0, ft2\n"
            "vfcpkd.b.s ft4, ft0, ft2\n"  // ft4 =
                                          // {3.14, 1.618, 3.14, 1.618, 3.14, 1.618,
                                          // 3.14, 1.618}
            "vfcpka.b.s ft5, ft1, ft3\n"
            "vfcpkb.b.s ft5, ft1, ft3\n"
            "vfcpkc.b.s ft5, ft1, ft3\n"
            "vfcpkd.b.s ft5, ft1, ft3\n"  // ft5 = {-3.14, -1.618,-3.14, -1.618,
                                          // -3.14, -1.618, -3.14, -1.618}
            "vfcpka.b.s ft6, ft0, ft3\n"
            "vfcpkb.b.s ft6, ft0, ft3\n"
            "vfcpkc.b.s ft6, ft0, ft3\n"
            "vfcpkd.b.s ft6, ft0, ft3\n"  // ft6 = {3.14, -1.618, 3.14,
                                          // -1.618, 3.14, -1.618, 3.14, -1.618}
            "vfcpka.b.s ft7, ft1, ft2\n"
            "vfcpkb.b.s ft7, ft1, ft2\n"
            "vfcpkc.b.s ft7, ft1, ft2\n"
            "vfcpkd.b.s ft7, ft1, ft2\n"  // ft7 = {-3.14, 1.618, -3.14, 1.618,
                                          // -3.14, 1.618, -3.14, 1.618}
            : "+r"(i_a), "+r"(i_an), "+r"(i_b), "+r"(i_bn));

        // VFSGNJ
        asm volatile(
            "vfsgnj.b ft0, ft4, ft4\n"
            "vfeq.b %0, ft4, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfsgnj.b ft0, ft4, ft5\n"
            "vfeq.b %0, ft5, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfsgnj.b ft0, ft5, ft6\n"
            "vfeq.b %0, ft6, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfsgnj.b ft0, ft5, ft7\n"
            "vfeq.b %0, ft7, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        // VFSGNJ.R
        asm volatile(
            "vfsgnj.r.b ft0, ft4, ft4\n"
            "vfeq.b %0, ft4, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfsgnj.r.b ft0, ft4, ft5\n"
            "vfeq.b %0, ft5, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfsgnj.r.b ft0, ft5, ft6\n"
            "vfeq.b %0, ft4, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfsgnj.r.b ft0, ft5, ft7\n"
            "vfeq.b %0, ft5, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        // VFSGNJN
        asm volatile(
            "vfsgnjn.b ft0, ft4, ft4\n"
            "vfeq.b %0, ft5, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfsgnjn.b ft0, ft4, ft5\n"
            "vfeq.b %0, ft4, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfsgnjn.b ft0, ft5, ft6\n"
            "vfeq.b %0, ft7, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfsgnjn.b ft0, ft5, ft7\n"
            "vfeq.b %0, ft6, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        // VFSGNJN.R
        asm volatile(
            "vfsgnjn.r.b ft0, ft4, ft4\n"
            "vfeq.b %0, ft5, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfsgnjn.r.b ft0, ft4, ft5\n"
            "vfeq.b %0, ft4, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfsgnjn.r.b ft0, ft5, ft6\n"
            "vfeq.b %0, ft5, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfsgnjn.r.b ft0, ft5, ft7\n"
            "vfeq.b %0, ft4, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        // VFSGNJX
        asm volatile(
            "vfsgnjx.b ft0, ft4, ft4\n"
            "vfeq.b %0, ft4, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfsgnjx.b ft0, ft4, ft5\n"
            "vfeq.b %0, ft5, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfsgnjx.b ft0, ft5, ft6\n"
            "vfeq.b %0, ft7, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfsgnjx.b ft0, ft5, ft7\n"
            "vfeq.b %0, ft6, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        // VFSGNJX.R
        asm volatile(
            "vfsgnjx.r.b ft0, ft4, ft4\n"
            "vfeq.b %0, ft4, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfsgnjx.r.b ft0, ft4, ft5\n"
            "vfeq.b %0, ft5, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfsgnjx.r.b ft0, ft5, ft6\n"
            "vfeq.b %0, ft5, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfsgnjx.r.b ft0, ft5, ft7\n"
            "vfeq.b %0, ft4, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        // load new data
        asm volatile(
            "fmv.s.x ft0, %0\n"  // 3.14
            "fmv.s.x ft1, %1\n"  // -1.618
            "fmv.s.x ft2, %2\n"  // 0.250244
            "fmv.s.x ft3, %3\n"  // 100.123456789
            "vfcpka.b.s ft4, ft3, ft0\n"
            "vfcpkb.b.s ft4, ft3, ft0\n"
            "vfcpkc.b.s ft4, ft3, ft0\n"
            "vfcpkd.b.s ft4, ft3, ft0\n"  // ft4 = {100.123456789, 3.14,
                                          // 100.123456789, 3.14,
                                          // 100.123456789, 3.14,
                                          // 100.123456789, 3.14}
            "vfcpka.b.s ft5, ft2, ft1\n"
            "vfcpkb.b.s ft5, ft2, ft1\n"
            "vfcpkc.b.s ft5, ft2, ft1\n"
            "vfcpkd.b.s ft5, ft2, ft1\n"  // ft5 = {0.250244, -1.618, 0.250244,
                                          // -1.618, 0.250244, -1.618, 0.250244,
                                          // -1.618}
            "vfcpka.b.s ft6, ft1, ft3\n"
            "vfcpkb.b.s ft6, ft1, ft3\n"
            "vfcpkc.b.s ft6, ft1, ft3\n"
            "vfcpkd.b.s ft6, ft1, ft3\n"  // ft6 = {-1.618, 100.123456789,
                                          // -1.618, 100.123456789, -1.618,
                                          // 100.123456789, -1.618,
                                          // 100.123456789}
            : "+r"(i_a), "+r"(i_bn), "+r"(i_d), "+r"(i_f));

        // VFADD
        // pack results
        res1 = 0x42C00000;
        res2 = 0x3FC00000;
        res3 = 0xBFA00000;
        res4 = 0x42C00000;

        asm volatile(
            "fmv.s.x ft0, %0\n"
            "fmv.s.x ft1, %1\n"
            "fmv.s.x ft2, %2\n"
            "fmv.s.x ft3, %3\n"
            // pack h values
            "vfcpka.b.s ft7, ft0, ft1\n"
            "vfcpkb.b.s ft7, ft0, ft1\n"
            "vfcpkc.b.s ft7, ft0, ft1\n"
            "vfcpkd.b.s ft7, ft0, ft1\n"
            "vfcpka.b.s ft8, ft2, ft3\n"
            "vfcpkb.b.s ft8, ft2, ft3\n"
            "vfcpkc.b.s ft8, ft2, ft3\n"
            "vfcpkd.b.s ft8, ft2, ft3\n"
            : "+r"(res1), "+r"(res2), "+r"(res3), "+r"(res4));

        asm volatile(
            "vfadd.b ft0, ft4, ft5\n"
            "vfeq.b %0, ft7, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfadd.b ft0, ft5, ft6\n"
            "vfeq.b %0, ft8, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        // VFADD.R
        // pack results
        res1 = 0x42C00000;
        res2 = 0x40400000;
        res3 = 0xBFA00000;
        res4 = 0xC0400000;

        asm volatile(
            "fmv.s.x ft0, %0\n"
            "fmv.s.x ft1, %1\n"
            "fmv.s.x ft2, %2\n"
            "fmv.s.x ft3, %3\n"
            // pack h values
            "vfcpka.b.s ft7, ft0, ft1\n"
            "vfcpkb.b.s ft7, ft0, ft1\n"
            "vfcpkc.b.s ft7, ft0, ft1\n"
            "vfcpkd.b.s ft7, ft0, ft1\n"
            "vfcpka.b.s ft8, ft2, ft3\n"
            "vfcpkb.b.s ft8, ft2, ft3\n"
            "vfcpkc.b.s ft8, ft2, ft3\n"
            "vfcpkd.b.s ft8, ft2, ft3\n"
            : "+r"(res1), "+r"(res2), "+r"(res3), "+r"(res4));

        asm volatile(
            "vfadd.r.b ft0, ft4, ft5\n"
            "vfeq.b %0, ft7, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfadd.r.b ft0, ft5, ft6\n"
            "vfeq.b %0, ft8, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        // VFSUB
        // pack results
        res1 = 0x42C00000;
        res2 = 0x40800000;
        res3 = 0x3FE00000;
        res4 = 0xC2C00000;

        asm volatile(
            "fmv.s.x ft0, %0\n"
            "fmv.s.x ft1, %1\n"
            "fmv.s.x ft2, %2\n"
            "fmv.s.x ft3, %3\n"
            // pack h values
            "vfcpka.b.s ft7, ft0, ft1\n"
            "vfcpkb.b.s ft7, ft0, ft1\n"
            "vfcpkc.b.s ft7, ft0, ft1\n"
            "vfcpkd.b.s ft7, ft0, ft1\n"
            "vfcpka.b.s ft8, ft2, ft3\n"
            "vfcpkb.b.s ft8, ft2, ft3\n"
            "vfcpkc.b.s ft8, ft2, ft3\n"
            "vfcpkd.b.s ft8, ft2, ft3\n"
            : "+r"(res1), "+r"(res2), "+r"(res3), "+r"(res4));

        asm volatile(
            "vfsub.b ft0, ft4, ft5\n"
            "vfeq.b %0, ft7, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfsub.b ft0, ft5, ft6\n"
            "vfeq.b %0, ft8, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        // VFSUB.R
        // pack results
        res1 = 0x42C00000;
        res2 = 0x40400000;
        res3 = 0x3FE00000;
        res4 = 0x00000000;

        asm volatile(
            "fmv.s.x ft0, %0\n"
            "fmv.s.x ft1, %1\n"
            "fmv.s.x ft2, %2\n"
            "fmv.s.x ft3, %3\n"
            // pack h values
            "vfcpka.b.s ft7, ft0, ft1\n"
            "vfcpkb.b.s ft7, ft0, ft1\n"
            "vfcpkc.b.s ft7, ft0, ft1\n"
            "vfcpkd.b.s ft7, ft0, ft1\n"
            "vfcpka.b.s ft8, ft2, ft3\n"
            "vfcpkb.b.s ft8, ft2, ft3\n"
            "vfcpkc.b.s ft8, ft2, ft3\n"
            "vfcpkd.b.s ft8, ft2, ft3\n"
            : "+r"(res1), "+r"(res2), "+r"(res3), "+r"(res4));

        asm volatile(
            "vfsub.r.b ft0, ft4, ft5\n"
            "vfeq.b %0, ft7, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfsub.r.b ft0, ft5, ft6\n"
            "vfeq.b %0, ft8, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        // VFMUL
        // pack results
        res1 = 0x41C00000;
        res2 = 0xC0800000;
        res3 = 0xBEC00000;
        res4 = 0xC3000000;

        asm volatile(
            "fmv.s.x ft0, %0\n"
            "fmv.s.x ft1, %1\n"
            "fmv.s.x ft2, %2\n"
            "fmv.s.x ft3, %3\n"
            // pack h values
            "vfcpka.b.s ft7, ft0, ft1\n"
            "vfcpkb.b.s ft7, ft0, ft1\n"
            "vfcpkc.b.s ft7, ft0, ft1\n"
            "vfcpkd.b.s ft7, ft0, ft1\n"
            "vfcpka.b.s ft8, ft2, ft3\n"
            "vfcpkb.b.s ft8, ft2, ft3\n"
            "vfcpkc.b.s ft8, ft2, ft3\n"
            "vfcpkd.b.s ft8, ft2, ft3\n"
            : "+r"(res1), "+r"(res2), "+r"(res3), "+r"(res4));

        asm volatile(
            "vfmul.b ft0, ft4, ft5\n"
            "vfeq.b %0, ft7, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfmul.b ft0, ft5, ft6\n"
            "vfeq.b %0, ft8, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        // VFMUL.R
        // pack results
        res1 = 0x41C00000;
        res2 = 0x3F400000;
        res3 = 0xBEC00000;
        res4 = 0x40000000;

        asm volatile(
            "fmv.s.x ft0, %0\n"
            "fmv.s.x ft1, %1\n"
            "fmv.s.x ft2, %2\n"
            "fmv.s.x ft3, %3\n"
            // pack h values
            "vfcpka.b.s ft7, ft0, ft1\n"
            "vfcpkb.b.s ft7, ft0, ft1\n"
            "vfcpkc.b.s ft7, ft0, ft1\n"
            "vfcpkd.b.s ft7, ft0, ft1\n"
            "vfcpka.b.s ft8, ft2, ft3\n"
            "vfcpkb.b.s ft8, ft2, ft3\n"
            "vfcpkc.b.s ft8, ft2, ft3\n"
            "vfcpkd.b.s ft8, ft2, ft3\n"
            : "+r"(res1), "+r"(res2), "+r"(res3), "+r"(res4));

        asm volatile(
            "vfmul.r.b ft0, ft4, ft5\n"
            "vfeq.b %0, ft7, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfmul.r.b ft0, ft5, ft6\n"
            "vfeq.b %0, ft8, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        // VFMAC
        // pack results
        res1 = 0x41C00000;
        res2 = 0xC0800000;
        res3 = 0x41C00000;
        res4 = 0xC3200000;

        asm volatile(
            "fmv.s.x ft0, %0\n"
            "fmv.s.x ft1, %1\n"
            "fmv.s.x ft2, %2\n"
            "fmv.s.x ft3, %3\n"
            // pack h values
            "vfcpka.b.s ft7, ft0, ft1\n"
            "vfcpkb.b.s ft7, ft0, ft1\n"
            "vfcpkc.b.s ft7, ft0, ft1\n"
            "vfcpkd.b.s ft7, ft0, ft1\n"
            "vfcpka.b.s ft8, ft2, ft3\n"
            "vfcpkb.b.s ft8, ft2, ft3\n"
            "vfcpkc.b.s ft8, ft2, ft3\n"
            "vfcpkd.b.s ft8, ft2, ft3\n"
            // reset ft0
            "fcvt.d.w ft0, zero\n"
            : "+r"(res1), "+r"(res2), "+r"(res3), "+r"(res4));

        asm volatile(
            "vfmac.b ft0, ft4, ft5\n"
            "vfeq.b %0, ft7, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfmac.b ft0, ft5, ft6\n"
            "vfeq.b %0, ft8, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        // VFMAC.R
        // pack results
        res1 = 0x41C00000;
        res2 = 0x3F400000;
        res3 = 0x41C00000;
        res4 = 0x40400000;

        asm volatile(
            "fmv.s.x ft0, %0\n"
            "fmv.s.x ft1, %1\n"
            "fmv.s.x ft2, %2\n"
            "fmv.s.x ft3, %3\n"
            // pack h values
            "vfcpka.b.s ft7, ft0, ft1\n"
            "vfcpkb.b.s ft7, ft0, ft1\n"
            "vfcpkc.b.s ft7, ft0, ft1\n"
            "vfcpkd.b.s ft7, ft0, ft1\n"
            "vfcpka.b.s ft8, ft2, ft3\n"
            "vfcpkb.b.s ft8, ft2, ft3\n"
            "vfcpkc.b.s ft8, ft2, ft3\n"
            "vfcpkd.b.s ft8, ft2, ft3\n"
            // reset ft0
            "fcvt.d.w ft0, zero\n"
            : "+r"(res1), "+r"(res2), "+r"(res3), "+r"(res4));

        asm volatile(
            "vfmac.r.b ft0, ft4, ft5\n"
            "vfeq.b %0, ft7, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfmac.r.b ft0, ft5, ft6\n"
            "vfeq.b %0, ft8, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        // VFMRE
        // pack results
        res1 = 0xC1C00000;
        res2 = 0x40800000;
        res3 = 0xC1C00000;
        res4 = 0x43200000;

        asm volatile(
            "fmv.s.x ft0, %0\n"
            "fmv.s.x ft1, %1\n"
            "fmv.s.x ft2, %2\n"
            "fmv.s.x ft3, %3\n"
            // pack h values
            "vfcpka.b.s ft7, ft0, ft1\n"
            "vfcpkb.b.s ft7, ft0, ft1\n"
            "vfcpkc.b.s ft7, ft0, ft1\n"
            "vfcpkd.b.s ft7, ft0, ft1\n"
            "vfcpka.b.s ft8, ft2, ft3\n"
            "vfcpkb.b.s ft8, ft2, ft3\n"
            "vfcpkc.b.s ft8, ft2, ft3\n"
            "vfcpkd.b.s ft8, ft2, ft3\n"
            // reset ft0
            "fcvt.d.w ft0, zero\n"
            : "+r"(res1), "+r"(res2), "+r"(res3), "+r"(res4));

        asm volatile(
            "vfmre.b ft0, ft4, ft5\n"
            "vfeq.b %0, ft7, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfmre.b ft0, ft5, ft6\n"
            "vfeq.b %0, ft8, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        // pack results
        res1 = 0x43000000;
        res2 = 0xC3000000;

        asm volatile(
            "fmv.s.x ft1, %0\n"
            "fmv.s.x ft2, %1\n"
            // pack h values
            "vfcpka.b.s ft7, ft1, ft2\n"
            "vfcpkb.b.s ft7, ft1, ft2\n"
            "vfcpkc.b.s ft7, ft1, ft2\n"
            "vfcpkd.b.s ft7, ft1, ft2\n"
            // do NOT reset ft0
            : "+r"(res1), "+r"(res2));

        asm volatile(
            "vfmre.b ft0, ft4, ft6\n"
            "vfeq.b %0, ft7, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        // VFMRE.R
        // pack results
        res1 = 0xC1C00000;
        res2 = 0xBF400000;
        res3 = 0xC1C00000;
        res4 = 0xC0400000;

        asm volatile(
            "fmv.s.x ft0, %0\n"
            "fmv.s.x ft1, %1\n"
            "fmv.s.x ft2, %2\n"
            "fmv.s.x ft3, %3\n"
            // pack h values
            "vfcpka.b.s ft7, ft0, ft1\n"
            "vfcpkb.b.s ft7, ft0, ft1\n"
            "vfcpkc.b.s ft7, ft0, ft1\n"
            "vfcpkd.b.s ft7, ft0, ft1\n"
            "vfcpka.b.s ft8, ft2, ft3\n"
            "vfcpkb.b.s ft8, ft2, ft3\n"
            "vfcpkc.b.s ft8, ft2, ft3\n"
            "vfcpkd.b.s ft8, ft2, ft3\n"
            // reset ft0
            "fcvt.d.w ft0, zero\n"
            : "+r"(res1), "+r"(res2), "+r"(res3), "+r"(res4));

        asm volatile(
            "vfmre.r.b ft0, ft4, ft5\n"
            "vfeq.b %0, ft7, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfmre.r.b ft0, ft5, ft6\n"
            "vfeq.b %0, ft8, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        // pack results
        res1 = 0x43000000;
        res2 = 0x3FC00000;

        asm volatile(
            "fmv.s.x ft1, %0\n"
            "fmv.s.x ft2, %1\n"
            // pack h values
            "vfcpka.b.s ft7, ft1, ft2\n"
            "vfcpkb.b.s ft7, ft1, ft2\n"
            "vfcpkc.b.s ft7, ft1, ft2\n"
            "vfcpkd.b.s ft7, ft1, ft2\n"
            // do NOT reset ft0
            : "+r"(res1), "+r"(res2));

        asm volatile(
            "vfmre.r.b ft0, ft4, ft6\n"
            "vfeq.b %0, ft7, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);
    }

    return errs;
}
