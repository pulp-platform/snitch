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

        write_csr(2048, 3);

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
            "vfcpka.ab.s ft4, ft0, ft2\n"
            "vfcpkb.ab.s ft4, ft0, ft2\n"
            "vfcpkc.ab.s ft4, ft0, ft2\n"
            "vfcpkd.ab.s ft4, ft0, ft2\n"  // ft4 =
                                           // {3.14, 1.618, 3.14, 1.618, 3.14, 1.618,
                                           // 3.14, 1.618}
            "vfcpka.ab.s ft5, ft1, ft3\n"
            "vfcpkb.ab.s ft5, ft1, ft3\n"
            "vfcpkc.ab.s ft5, ft1, ft3\n"
            "vfcpkd.ab.s ft5, ft1, ft3\n"  // ft5 = {-3.14, -1.618,-3.14,
                                           // -1.618, -3.14, -1.618, -3.14,
                                           // -1.618}
            "vfcpka.ab.s ft6, ft0, ft3\n"
            "vfcpkb.ab.s ft6, ft0, ft3\n"
            "vfcpkc.ab.s ft6, ft0, ft3\n"
            "vfcpkd.ab.s ft6, ft0, ft3\n"  // ft6 = {3.14, -1.618, 3.14,
                                           // -1.618, 3.14, -1.618, 3.14,
                                           // -1.618}
            "vfcpka.ab.s ft7, ft1, ft2\n"
            "vfcpkb.ab.s ft7, ft1, ft2\n"
            "vfcpkc.ab.s ft7, ft1, ft2\n"
            "vfcpkd.ab.s ft7, ft1, ft2\n"  // ft7 = {-3.14, 1.618, -3.14, 1.618,
                                           // -3.14, 1.618, -3.14, 1.618}
            : "+r"(i_a), "+r"(i_an), "+r"(i_b), "+r"(i_bn));

        // VFSGNJ
        asm volatile(
            "vfsgnj.ab ft0, ft4, ft4\n"
            "vfeq.ab %0, ft4, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfsgnj.ab ft0, ft4, ft5\n"
            "vfeq.ab %0, ft5, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfsgnj.ab ft0, ft5, ft6\n"
            "vfeq.ab %0, ft6, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfsgnj.ab ft0, ft5, ft7\n"
            "vfeq.ab %0, ft7, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        // VFSGNJ.R
        asm volatile(
            "vfsgnj.r.ab ft0, ft4, ft4\n"
            "vfeq.ab %0, ft4, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfsgnj.r.ab ft0, ft4, ft5\n"
            "vfeq.ab %0, ft5, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfsgnj.r.ab ft0, ft5, ft6\n"
            "vfeq.ab %0, ft4, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfsgnj.r.ab ft0, ft5, ft7\n"
            "vfeq.ab %0, ft5, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        // VFSGNJN
        asm volatile(
            "vfsgnjn.ab ft0, ft4, ft4\n"
            "vfeq.ab %0, ft5, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfsgnjn.ab ft0, ft4, ft5\n"
            "vfeq.ab %0, ft4, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfsgnjn.ab ft0, ft5, ft6\n"
            "vfeq.ab %0, ft7, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfsgnjn.ab ft0, ft5, ft7\n"
            "vfeq.ab %0, ft6, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        // VFSGNJN.R
        asm volatile(
            "vfsgnjn.r.ab ft0, ft4, ft4\n"
            "vfeq.ab %0, ft5, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfsgnjn.r.ab ft0, ft4, ft5\n"
            "vfeq.ab %0, ft4, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfsgnjn.r.ab ft0, ft5, ft6\n"
            "vfeq.ab %0, ft5, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfsgnjn.r.ab ft0, ft5, ft7\n"
            "vfeq.ab %0, ft4, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        // VFSGNJX
        asm volatile(
            "vfsgnjx.ab ft0, ft4, ft4\n"
            "vfeq.ab %0, ft4, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfsgnjx.ab ft0, ft4, ft5\n"
            "vfeq.ab %0, ft5, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfsgnjx.ab ft0, ft5, ft6\n"
            "vfeq.ab %0, ft7, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfsgnjx.ab ft0, ft5, ft7\n"
            "vfeq.ab %0, ft6, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        // VFSGNJX.R
        asm volatile(
            "vfsgnjx.r.ab ft0, ft4, ft4\n"
            "vfeq.ab %0, ft4, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfsgnjx.r.ab ft0, ft4, ft5\n"
            "vfeq.ab %0, ft5, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfsgnjx.r.ab ft0, ft5, ft6\n"
            "vfeq.ab %0, ft5, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfsgnjx.r.ab ft0, ft5, ft7\n"
            "vfeq.ab %0, ft4, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        // load new data
        asm volatile(
            "fmv.s.x ft0, %0\n"  // 3.14
            "fmv.s.x ft1, %1\n"  // -1.618
            "fmv.s.x ft2, %2\n"  // 0.250244
            "fmv.s.x ft3, %3\n"  // 100.123456789
            "vfcpka.ab.s ft4, ft3, ft0\n"
            "vfcpkb.ab.s ft4, ft3, ft0\n"
            "vfcpkc.ab.s ft4, ft3, ft0\n"
            "vfcpkd.ab.s ft4, ft3, ft0\n"  // ft4 = {100.123456789, 3.14,
                                           // 100.123456789, 3.14,
                                           // 100.123456789, 3.14,
                                           // 100.123456789, 3.14}
            "vfcpka.ab.s ft5, ft2, ft1\n"
            "vfcpkb.ab.s ft5, ft2, ft1\n"
            "vfcpkc.ab.s ft5, ft2, ft1\n"
            "vfcpkd.ab.s ft5, ft2, ft1\n"  // ft5 = {0.250244, -1.618, 0.250244,
                                           // -1.618, 0.250244, -1.618,
                                           // 0.250244, -1.618}
            "vfcpka.ab.s ft6, ft1, ft3\n"
            "vfcpkb.ab.s ft6, ft1, ft3\n"
            "vfcpkc.ab.s ft6, ft1, ft3\n"
            "vfcpkd.ab.s ft6, ft1, ft3\n"  // ft6 = {-1.618, 100.123456789,
                                           // -1.618, 100.123456789, -1.618,
                                           // 100.123456789, -1.618,
                                           // 100.123456789}
            : "+r"(i_a), "+r"(i_bn), "+r"(i_d), "+r"(i_f));

        // VFADD
        // pack results
        res1 = 0x42D00000;
        res2 = 0x3FD00000;
        res3 = 0xBFB00000;
        res4 = 0x42D00000;

        asm volatile(
            "fmv.s.x ft0, %0\n"
            "fmv.s.x ft1, %1\n"
            "fmv.s.x ft2, %2\n"
            "fmv.s.x ft3, %3\n"
            // pack h values
            "vfcpka.ab.s ft7, ft0, ft1\n"
            "vfcpkb.ab.s ft7, ft0, ft1\n"
            "vfcpkc.ab.s ft7, ft0, ft1\n"
            "vfcpkd.ab.s ft7, ft0, ft1\n"
            "vfcpka.ab.s ft8, ft2, ft3\n"
            "vfcpkb.ab.s ft8, ft2, ft3\n"
            "vfcpkc.ab.s ft8, ft2, ft3\n"
            "vfcpkd.ab.s ft8, ft2, ft3\n"
            : "+r"(res1), "+r"(res2), "+r"(res3), "+r"(res4));

        asm volatile(
            "vfadd.ab ft0, ft4, ft5\n"
            "vfeq.ab %0, ft7, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfadd.ab ft0, ft5, ft6\n"
            "vfeq.ab %0, ft8, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        // VFADD.R
        // pack results
        res1 = 0x42D00000;
        res2 = 0x40600000;
        res3 = 0xBFB00000;
        res4 = 0xC0500000;

        asm volatile(
            "fmv.s.x ft0, %0\n"
            "fmv.s.x ft1, %1\n"
            "fmv.s.x ft2, %2\n"
            "fmv.s.x ft3, %3\n"
            // pack h values
            "vfcpka.ab.s ft7, ft0, ft1\n"
            "vfcpkb.ab.s ft7, ft0, ft1\n"
            "vfcpkc.ab.s ft7, ft0, ft1\n"
            "vfcpkd.ab.s ft7, ft0, ft1\n"
            "vfcpka.ab.s ft8, ft2, ft3\n"
            "vfcpkb.ab.s ft8, ft2, ft3\n"
            "vfcpkc.ab.s ft8, ft2, ft3\n"
            "vfcpkd.ab.s ft8, ft2, ft3\n"
            : "+r"(res1), "+r"(res2), "+r"(res3), "+r"(res4));

        asm volatile(
            "vfadd.r.ab ft0, ft4, ft5\n"
            "vfeq.ab %0, ft7, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfadd.r.ab ft0, ft5, ft6\n"
            "vfeq.ab %0, ft8, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        // VFSUB
        // pack results
        res1 = 0x42D00000;
        res2 = 0x40A00000;
        res3 = 0x3FF00000;
        res4 = 0xC2D00000;

        asm volatile(
            "fmv.s.x ft0, %0\n"
            "fmv.s.x ft1, %1\n"
            "fmv.s.x ft2, %2\n"
            "fmv.s.x ft3, %3\n"
            // pack h values
            "vfcpka.ab.s ft7, ft0, ft1\n"
            "vfcpkb.ab.s ft7, ft0, ft1\n"
            "vfcpkc.ab.s ft7, ft0, ft1\n"
            "vfcpkd.ab.s ft7, ft0, ft1\n"
            "vfcpka.ab.s ft8, ft2, ft3\n"
            "vfcpkb.ab.s ft8, ft2, ft3\n"
            "vfcpkc.ab.s ft8, ft2, ft3\n"
            "vfcpkd.ab.s ft8, ft2, ft3\n"
            : "+r"(res1), "+r"(res2), "+r"(res3), "+r"(res4));

        asm volatile(
            "vfsub.ab ft0, ft4, ft5\n"
            "vfeq.ab %0, ft7, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfsub.ab ft0, ft5, ft6\n"
            "vfeq.ab %0, ft8, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        // VFSUB.R
        // pack results
        res1 = 0x42D00000;
        res2 = 0x40400000;
        res3 = 0x3FF00000;
        res4 = 0x00000000;

        asm volatile(
            "fmv.s.x ft0, %0\n"
            "fmv.s.x ft1, %1\n"
            "fmv.s.x ft2, %2\n"
            "fmv.s.x ft3, %3\n"
            // pack h values
            "vfcpka.ab.s ft7, ft0, ft1\n"
            "vfcpkb.ab.s ft7, ft0, ft1\n"
            "vfcpkc.ab.s ft7, ft0, ft1\n"
            "vfcpkd.ab.s ft7, ft0, ft1\n"
            "vfcpka.ab.s ft8, ft2, ft3\n"
            "vfcpkb.ab.s ft8, ft2, ft3\n"
            "vfcpkc.ab.s ft8, ft2, ft3\n"
            "vfcpkd.ab.s ft8, ft2, ft3\n"
            : "+r"(res1), "+r"(res2), "+r"(res3), "+r"(res4));

        asm volatile(
            "vfsub.r.ab ft0, ft4, ft5\n"
            "vfeq.ab %0, ft7, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfsub.r.ab ft0, ft5, ft6\n"
            "vfeq.ab %0, ft8, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        // VFMUL
        // pack results
        res1 = 0x41D00000;
        res2 = 0xC0B00000;
        res3 = 0xBED00000;
        res4 = 0xC3300000;

        asm volatile(
            "fmv.s.x ft0, %0\n"
            "fmv.s.x ft1, %1\n"
            "fmv.s.x ft2, %2\n"
            "fmv.s.x ft3, %3\n"
            // pack h values
            "vfcpka.ab.s ft7, ft0, ft1\n"
            "vfcpkb.ab.s ft7, ft0, ft1\n"
            "vfcpkc.ab.s ft7, ft0, ft1\n"
            "vfcpkd.ab.s ft7, ft0, ft1\n"
            "vfcpka.ab.s ft8, ft2, ft3\n"
            "vfcpkb.ab.s ft8, ft2, ft3\n"
            "vfcpkc.ab.s ft8, ft2, ft3\n"
            "vfcpkd.ab.s ft8, ft2, ft3\n"
            : "+r"(res1), "+r"(res2), "+r"(res3), "+r"(res4));

        asm volatile(
            "vfmul.ab ft0, ft4, ft5\n"
            "vfeq.ab %0, ft7, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfmul.ab ft0, ft5, ft6\n"
            "vfeq.ab %0, ft8, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        // VFMUL.R
        // pack results
        res1 = 0x41D00000;
        res2 = 0x3F500000;
        res3 = 0xBED00000;
        res4 = 0x40300000;

        asm volatile(
            "fmv.s.x ft0, %0\n"
            "fmv.s.x ft1, %1\n"
            "fmv.s.x ft2, %2\n"
            "fmv.s.x ft3, %3\n"
            // pack h values
            "vfcpka.ab.s ft7, ft0, ft1\n"
            "vfcpkb.ab.s ft7, ft0, ft1\n"
            "vfcpkc.ab.s ft7, ft0, ft1\n"
            "vfcpkd.ab.s ft7, ft0, ft1\n"
            "vfcpka.ab.s ft8, ft2, ft3\n"
            "vfcpkb.ab.s ft8, ft2, ft3\n"
            "vfcpkc.ab.s ft8, ft2, ft3\n"
            "vfcpkd.ab.s ft8, ft2, ft3\n"
            : "+r"(res1), "+r"(res2), "+r"(res3), "+r"(res4));

        asm volatile(
            "vfmul.r.ab ft0, ft4, ft5\n"
            "vfeq.ab %0, ft7, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfmul.r.ab ft0, ft5, ft6\n"
            "vfeq.ab %0, ft8, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        // VFMAC
        // pack results
        res1 = 0x41D00000;
        res2 = 0xC0B00000;
        res3 = 0x41D00000;
        res4 = 0xC3300000;

        asm volatile(
            "fmv.s.x ft0, %0\n"
            "fmv.s.x ft1, %1\n"
            "fmv.s.x ft2, %2\n"
            "fmv.s.x ft3, %3\n"
            // pack h values
            "vfcpka.ab.s ft7, ft0, ft1\n"
            "vfcpkb.ab.s ft7, ft0, ft1\n"
            "vfcpkc.ab.s ft7, ft0, ft1\n"
            "vfcpkd.ab.s ft7, ft0, ft1\n"
            "vfcpka.ab.s ft8, ft2, ft3\n"
            "vfcpkb.ab.s ft8, ft2, ft3\n"
            "vfcpkc.ab.s ft8, ft2, ft3\n"
            "vfcpkd.ab.s ft8, ft2, ft3\n"
            // reset ft0
            "fcvt.d.w ft0, zero\n"
            : "+r"(res1), "+r"(res2), "+r"(res3), "+r"(res4));

        asm volatile(
            "vfmac.ab ft0, ft4, ft5\n"
            "vfeq.ab %0, ft7, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfmac.ab ft0, ft5, ft6\n"
            "vfeq.ab %0, ft8, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        // VFMAC.R
        // pack results
        res1 = 0x41D00000;
        res2 = 0x3F500000;
        res3 = 0x41D00000;
        res4 = 0x40600000;

        asm volatile(
            "fmv.s.x ft0, %0\n"
            "fmv.s.x ft1, %1\n"
            "fmv.s.x ft2, %2\n"
            "fmv.s.x ft3, %3\n"
            // pack h values
            "vfcpka.ab.s ft7, ft0, ft1\n"
            "vfcpkb.ab.s ft7, ft0, ft1\n"
            "vfcpkc.ab.s ft7, ft0, ft1\n"
            "vfcpkd.ab.s ft7, ft0, ft1\n"
            "vfcpka.ab.s ft8, ft2, ft3\n"
            "vfcpkb.ab.s ft8, ft2, ft3\n"
            "vfcpkc.ab.s ft8, ft2, ft3\n"
            "vfcpkd.ab.s ft8, ft2, ft3\n"
            // reset ft0
            "fcvt.d.w ft0, zero\n"
            : "+r"(res1), "+r"(res2), "+r"(res3), "+r"(res4));

        asm volatile(
            "vfmac.r.ab ft0, ft4, ft5\n"
            "vfeq.ab %0, ft7, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfmac.r.ab ft0, ft5, ft6\n"
            "vfeq.ab %0, ft8, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        // VFMRE
        // pack results
        res1 = 0xC1D00000;
        res2 = 0x40B00000;
        res3 = 0xC1D00000;
        res4 = 0x43300000;

        asm volatile(
            "fmv.s.x ft0, %0\n"
            "fmv.s.x ft1, %1\n"
            "fmv.s.x ft2, %2\n"
            "fmv.s.x ft3, %3\n"
            // pack h values
            "vfcpka.ab.s ft7, ft0, ft1\n"
            "vfcpkb.ab.s ft7, ft0, ft1\n"
            "vfcpkc.ab.s ft7, ft0, ft1\n"
            "vfcpkd.ab.s ft7, ft0, ft1\n"
            "vfcpka.ab.s ft8, ft2, ft3\n"
            "vfcpkb.ab.s ft8, ft2, ft3\n"
            "vfcpkc.ab.s ft8, ft2, ft3\n"
            "vfcpkd.ab.s ft8, ft2, ft3\n"
            // reset ft0
            "fcvt.d.w ft0, zero\n"
            : "+r"(res1), "+r"(res2), "+r"(res3), "+r"(res4));

        asm volatile(
            "vfmre.ab ft0, ft4, ft5\n"
            "vfeq.ab %0, ft7, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfmre.ab ft0, ft5, ft6\n"
            "vfeq.ab %0, ft8, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        // pack results
        res1 = 0x43100000;
        res2 = 0xC3200000;

        asm volatile(
            "fmv.s.x ft1, %0\n"
            "fmv.s.x ft2, %1\n"
            // pack h values
            "vfcpka.ab.s ft7, ft1, ft2\n"
            "vfcpkb.ab.s ft7, ft1, ft2\n"
            "vfcpkc.ab.s ft7, ft1, ft2\n"
            "vfcpkd.ab.s ft7, ft1, ft2\n"
            // do NOT reset ft0
            : "+r"(res1), "+r"(res2));

        asm volatile(
            "vfmre.ab ft0, ft4, ft6\n"
            "vfeq.ab %0, ft7, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        // VFMRE.R
        // pack results
        res1 = 0xC1D00000;
        res2 = 0xBF500000;
        res3 = 0xC1D00000;
        res4 = 0xC0600000;

        asm volatile(
            "fmv.s.x ft0, %0\n"
            "fmv.s.x ft1, %1\n"
            "fmv.s.x ft2, %2\n"
            "fmv.s.x ft3, %3\n"
            // pack h values
            "vfcpka.ab.s ft7, ft0, ft1\n"
            "vfcpkb.ab.s ft7, ft0, ft1\n"
            "vfcpkc.ab.s ft7, ft0, ft1\n"
            "vfcpkd.ab.s ft7, ft0, ft1\n"
            "vfcpka.ab.s ft8, ft2, ft3\n"
            "vfcpkb.ab.s ft8, ft2, ft3\n"
            "vfcpkc.ab.s ft8, ft2, ft3\n"
            "vfcpkd.ab.s ft8, ft2, ft3\n"
            // reset ft0
            "fcvt.d.w ft0, zero\n"
            : "+r"(res1), "+r"(res2), "+r"(res3), "+r"(res4));

        asm volatile(
            "vfmre.r.ab ft0, ft4, ft5\n"
            "vfeq.ab %0, ft7, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        asm volatile(
            "vfmre.r.ab ft0, ft5, ft6\n"
            "vfeq.ab %0, ft8, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);

        // pack results
        res1 = 0x43100000;
        res2 = 0x3FE00000;

        asm volatile(
            "fmv.s.x ft1, %0\n"
            "fmv.s.x ft2, %1\n"
            // pack h values
            "vfcpka.ab.s ft7, ft1, ft2\n"
            "vfcpkb.ab.s ft7, ft1, ft2\n"
            "vfcpkc.ab.s ft7, ft1, ft2\n"
            "vfcpkd.ab.s ft7, ft1, ft2\n"
            // do NOT reset ft0
            : "+r"(res1), "+r"(res2));

        asm volatile(
            "vfmre.r.ab ft0, ft4, ft6\n"
            "vfeq.ab %0, ft7, ft0\n"
            : "+r"(res0));
        errs -= (res0 == 0xff);
    }

    return errs;
}
