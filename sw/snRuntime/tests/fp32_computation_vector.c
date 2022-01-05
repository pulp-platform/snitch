// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include <snrt.h>

int main() {
    int errs = 0;

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
            "vfcpka.s.s ft4, ft0, ft2\n"  // ft4 = {3.14, 1.618}
            "vfcpka.s.s ft5, ft1, ft3\n"  // ft5 = {-3.14, -1.618}
            "vfcpka.s.s ft6, ft0, ft3\n"  // ft6 = {3.14, -1.618}
            "vfcpka.s.s ft7, ft1, ft2\n"  // ft7 = {-3.14, 1.618}
            : "+r"(i_a), "+r"(i_an), "+r"(i_b), "+r"(i_bn));

        // VFSGNJ
        asm volatile(
            "vfsgnj.s ft0, ft4, ft4\n"
            "vfeq.s %0, ft4, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x3);

        asm volatile(
            "vfsgnj.s ft0, ft4, ft5\n"
            "vfeq.s %0, ft5, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x3);

        asm volatile(
            "vfsgnj.s ft0, ft5, ft6\n"
            "vfeq.s %0, ft6, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x3);

        asm volatile(
            "vfsgnj.s ft0, ft5, ft7\n"
            "vfeq.s %0, ft7, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x3);

        // VFSGNJ.R
        asm volatile(
            "vfsgnj.r.s ft0, ft4, ft4\n"
            "vfeq.s %0, ft4, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x3);

        asm volatile(
            "vfsgnj.r.s ft0, ft4, ft5\n"
            "vfeq.s %0, ft5, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x3);

        asm volatile(
            "vfsgnj.r.s ft0, ft5, ft6\n"
            "vfeq.s %0, ft4, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x3);

        asm volatile(
            "vfsgnj.r.s ft0, ft5, ft7\n"
            "vfeq.s %0, ft5, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x3);

        // VFSGNJN
        asm volatile(
            "vfsgnjn.s ft0, ft4, ft4\n"
            "vfeq.s %0, ft5, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x3);

        asm volatile(
            "vfsgnjn.s ft0, ft4, ft5\n"
            "vfeq.s %0, ft4, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x3);

        asm volatile(
            "vfsgnjn.s ft0, ft5, ft6\n"
            "vfeq.s %0, ft7, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x3);

        asm volatile(
            "vfsgnjn.s ft0, ft5, ft7\n"
            "vfeq.s %0, ft6, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x3);

        // VFSGNJN.R
        asm volatile(
            "vfsgnjn.r.s ft0, ft4, ft4\n"
            "vfeq.s %0, ft5, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x3);

        asm volatile(
            "vfsgnjn.r.s ft0, ft4, ft5\n"
            "vfeq.s %0, ft4, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x3);

        asm volatile(
            "vfsgnjn.r.s ft0, ft5, ft6\n"
            "vfeq.s %0, ft5, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x3);

        asm volatile(
            "vfsgnjn.r.s ft0, ft5, ft7\n"
            "vfeq.s %0, ft4, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x3);

        // VFSGNJX
        asm volatile(
            "vfsgnjx.s ft0, ft4, ft4\n"
            "vfeq.s %0, ft4, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x3);

        asm volatile(
            "vfsgnjx.s ft0, ft4, ft5\n"
            "vfeq.s %0, ft5, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x3);

        asm volatile(
            "vfsgnjx.s ft0, ft5, ft6\n"
            "vfeq.s %0, ft7, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x3);

        asm volatile(
            "vfsgnjx.s ft0, ft5, ft7\n"
            "vfeq.s %0, ft6, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x3);

        // VFSGNJX.R
        asm volatile(
            "vfsgnjx.r.s ft0, ft4, ft4\n"
            "vfeq.s %0, ft4, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x3);

        asm volatile(
            "vfsgnjx.r.s ft0, ft4, ft5\n"
            "vfeq.s %0, ft5, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x3);

        asm volatile(
            "vfsgnjx.r.s ft0, ft5, ft6\n"
            "vfeq.s %0, ft5, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x3);

        asm volatile(
            "vfsgnjx.r.s ft0, ft5, ft7\n"
            "vfeq.s %0, ft4, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x3);

        // load new data
        asm volatile(
            "fmv.s.x ft0, %0\n"           // 3.14
            "fmv.s.x ft1, %1\n"           // -1.618
            "fmv.s.x ft2, %2\n"           // 0.250244
            "fmv.s.x ft3, %3\n"           // 100.123456789
            "vfcpka.s.s ft4, ft3, ft0\n"  // ft4 = {100.123456789, 3.14}
            "vfcpka.s.s ft5, ft2, ft1\n"  // ft5 = {0.250244, -1.618}
            "vfcpka.s.s ft6, ft1, ft3\n"  // ft6 = {-1.618, 100.123456789}
            : "+r"(i_a), "+r"(i_bn), "+r"(i_d), "+r"(i_f));

        // VFADD
        // pack results
        res1 = 0x42C8BF56;
        res2 = 0x3FC2D0E6;
        res3 = 0xBFAF12A1;
        res4 = 0x42C502CC;

        asm volatile(
            "fmv.s.x ft0, %0\n"
            "fmv.s.x ft1, %1\n"
            "fmv.s.x ft2, %2\n"
            "fmv.s.x ft3, %3\n"
            // pack h values
            "vfcpka.s.s ft7, ft0, ft1\n"
            "vfcpka.s.s ft8, ft2, ft3\n"
            : "+r"(res1), "+r"(res2), "+r"(res3), "+r"(res4));

        asm volatile(
            "vfadd.s ft0, ft4, ft5\n"
            "vfeq.s %0, ft7, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x3);

        asm volatile(
            "vfadd.s ft0, ft5, ft6\n"
            "vfeq.s %0, ft8, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x3);

        // VFADD.R
        // pack results
        res1 = 0x42C8BF56;
        res2 = 0x4058F9C2;
        res3 = 0xBFAF12A1;
        res4 = 0xC04F1AA0;

        asm volatile(
            "fmv.s.x ft0, %0\n"
            "fmv.s.x ft1, %1\n"
            "fmv.s.x ft2, %2\n"
            "fmv.s.x ft3, %3\n"
            // pack h values
            "vfcpka.s.s ft7, ft0, ft1\n"
            "vfcpka.s.s ft8, ft2, ft3\n"
            : "+r"(res1), "+r"(res2), "+r"(res3), "+r"(res4));

        asm volatile(
            "vfadd.r.s ft0, ft4, ft5\n"
            "vfeq.s %0, ft7, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x3);

        asm volatile(
            "vfadd.r.s ft0, ft5, ft6\n"
            "vfeq.s %0, ft8, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x3);

        // VFSUB
        // pack results
        res1 = 0x42C7BF16;
        res2 = 0x4098418A;
        res3 = 0x3FEF229F;
        res4 = 0xC2CB7BA0;

        asm volatile(
            "fmv.s.x ft0, %0\n"
            "fmv.s.x ft1, %1\n"
            "fmv.s.x ft2, %2\n"
            "fmv.s.x ft3, %3\n"
            // pack h values
            "vfcpka.s.s ft7, ft0, ft1\n"
            "vfcpka.s.s ft8, ft2, ft3\n"
            : "+r"(res1), "+r"(res2), "+r"(res3), "+r"(res4));

        asm volatile(
            "vfsub.s ft0, ft4, ft5\n"
            "vfeq.s %0, ft7, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x3);

        asm volatile(
            "vfsub.s ft0, ft5, ft6\n"
            "vfeq.s %0, ft8, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x3);

        // VFSUB.R
        // pack results
        res1 = 0x42C7BF16;
        res2 = 0x4038F1C4;
        res3 = 0x3FEF229F;
        res4 = 0x00000000;

        asm volatile(
            "fmv.s.x ft0, %0\n"
            "fmv.s.x ft1, %1\n"
            "fmv.s.x ft2, %2\n"
            "fmv.s.x ft3, %3\n"
            // pack h values
            "vfcpka.s.s ft7, ft0, ft1\n"
            "vfcpka.s.s ft8, ft2, ft3\n"
            : "+r"(res1), "+r"(res2), "+r"(res3), "+r"(res4));

        asm volatile(
            "vfsub.r.s ft0, ft4, ft5\n"
            "vfeq.s %0, ft7, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x3);

        asm volatile(
            "vfsub.r.s ft0, ft5, ft6\n"
            "vfeq.s %0, ft8, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x3);

        // VFMUL
        // pack results
        res1 = 0x41C8713E;
        res2 = 0xC0A2939F;
        res3 = 0xBECF4E5F;
        res4 = 0xC321FFF0;

        asm volatile(
            "fmv.s.x ft0, %0\n"
            "fmv.s.x ft1, %1\n"
            "fmv.s.x ft2, %2\n"
            "fmv.s.x ft3, %3\n"
            // pack h values
            "vfcpka.s.s ft7, ft0, ft1\n"
            "vfcpka.s.s ft8, ft2, ft3\n"
            : "+r"(res1), "+r"(res2), "+r"(res3), "+r"(res4));

        asm volatile(
            "vfmul.s ft0, ft4, ft5\n"
            "vfeq.s %0, ft7, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x3);

        asm volatile(
            "vfmul.s ft0, ft5, ft6\n"
            "vfeq.s %0, ft8, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x3);

        // VFMUL.R
        // pack results
        res1 = 0x41C8713E;
        res2 = 0x3F4927F9;
        res3 = 0xBECF4E5F;
        res4 = 0x40278C12;

        asm volatile(
            "fmv.s.x ft0, %0\n"
            "fmv.s.x ft1, %1\n"
            "fmv.s.x ft2, %2\n"
            "fmv.s.x ft3, %3\n"
            // pack h values
            "vfcpka.s.s ft7, ft0, ft1\n"
            "vfcpka.s.s ft8, ft2, ft3\n"
            : "+r"(res1), "+r"(res2), "+r"(res3), "+r"(res4));

        asm volatile(
            "vfmul.r.s ft0, ft4, ft5\n"
            "vfeq.s %0, ft7, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x3);

        asm volatile(
            "vfmul.r.s ft0, ft5, ft6\n"
            "vfeq.s %0, ft8, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x3);

        // VFMAC
        // pack results
        res1 = 0x41C8713E;
        res2 = 0xC0A2939F;
        res3 = 0x41C53405;
        res4 = 0xC327148D;

        asm volatile(
            "fmv.s.x ft0, %0\n"
            "fmv.s.x ft1, %1\n"
            "fmv.s.x ft2, %2\n"
            "fmv.s.x ft3, %3\n"
            // pack h values
            "vfcpka.s.s ft7, ft0, ft1\n"
            "vfcpka.s.s ft8, ft2, ft3\n"
            // reset ft0
            "fcvt.d.w ft0, zero\n"
            : "+r"(res1), "+r"(res2), "+r"(res3), "+r"(res4));

        asm volatile(
            "vfmac.s ft0, ft4, ft5\n"
            "vfeq.s %0, ft7, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x3);

        asm volatile(
            "vfmac.s ft0, ft5, ft6\n"
            "vfeq.s %0, ft8, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x3);

        // VFMAC.R
        // pack results
        res1 = 0x41C8713E;
        res2 = 0x3F4927F9;
        res3 = 0x41C53405;
        res4 = 0x4059D610;

        asm volatile(
            "fmv.s.x ft0, %0\n"
            "fmv.s.x ft1, %1\n"
            "fmv.s.x ft2, %2\n"
            "fmv.s.x ft3, %3\n"
            // pack h values
            "vfcpka.s.s ft7, ft0, ft1\n"
            "vfcpka.s.s ft8, ft2, ft3\n"
            // reset ft0
            "fcvt.d.w ft0, zero\n"
            : "+r"(res1), "+r"(res2), "+r"(res3), "+r"(res4));

        asm volatile(
            "vfmac.r.s ft0, ft4, ft5\n"
            "vfeq.s %0, ft7, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x3);

        asm volatile(
            "vfmac.r.s ft0, ft5, ft6\n"
            "vfeq.s %0, ft8, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x3);

        // VFMRE
        // pack results
        res1 = 0xC1C8713E;
        res2 = 0x40A2939F;
        res3 = 0xC1C53405;
        res4 = 0x4327148D;

        asm volatile(
            "fmv.s.x ft0, %0\n"
            "fmv.s.x ft1, %1\n"
            "fmv.s.x ft2, %2\n"
            "fmv.s.x ft3, %3\n"
            // pack h values
            "vfcpka.s.s ft7, ft0, ft1\n"
            "vfcpka.s.s ft8, ft2, ft3\n"
            // reset ft0
            "fcvt.d.w ft0, zero\n"
            : "+r"(res1), "+r"(res2), "+r"(res3), "+r"(res4));

        asm volatile(
            "vfmre.s ft0, ft4, ft5\n"
            "vfeq.s %0, ft7, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x3);

        asm volatile(
            "vfmre.s ft0, ft5, ft6\n"
            "vfeq.s %0, ft8, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x3);

        // pack results
        res1 = 0x43095970;
        res2 = 0xC3134EB1;

        asm volatile(
            "fmv.s.x ft1, %0\n"
            "fmv.s.x ft2, %1\n"
            // pack h values
            "vfcpka.s.s ft7, ft1, ft2\n"
            // do NOT reset ft0
            : "+r"(res1), "+r"(res2));

        asm volatile(
            "vfmre.s ft0, ft4, ft6\n"
            "vfeq.s %0, ft7, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x3);

        // VFMRE.R
        // pack results
        res1 = 0xC1C8713E;
        res2 = 0xBF4927F9;
        res3 = 0xC1C53405;
        res4 = 0xC059D610;

        asm volatile(
            "fmv.s.x ft0, %0\n"
            "fmv.s.x ft1, %1\n"
            "fmv.s.x ft2, %2\n"
            "fmv.s.x ft3, %3\n"
            // pack h values
            "vfcpka.s.s ft7, ft0, ft1\n"
            "vfcpka.s.s ft8, ft2, ft3\n"
            // reset ft0
            "fcvt.d.w ft0, zero\n"
            : "+r"(res1), "+r"(res2), "+r"(res3), "+r"(res4));

        asm volatile(
            "vfmre.r.s ft0, ft4, ft5\n"
            "vfeq.s %0, ft7, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x3);

        asm volatile(
            "vfmre.r.s ft0, ft5, ft6\n"
            "vfeq.s %0, ft8, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x3);

        // pack results
        res1 = 0x43095970;
        res2 = 0x3FD6A25D;

        asm volatile(
            "fmv.s.x ft1, %0\n"
            "fmv.s.x ft2, %1\n"
            // pack h values
            "vfcpka.s.s ft7, ft1, ft2\n"
            // do NOT reset ft0
            : "+r"(res1), "+r"(res2));

        asm volatile(
            "vfmre.r.s ft0, ft4, ft6\n"
            "vfeq.s %0, ft7, ft0\n"
            : "+r"(res0));
        errs += (res0 != 0x3);
    }

    return errs;
}
