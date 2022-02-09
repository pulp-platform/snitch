// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include <snrt.h>

#include "printf.h"

int main() {
    int errs = 64;

    if (snrt_is_compute_core()) {
        uint32_t fa8 = 0x4048F5C3;   // 0x4248 3.14
        uint32_t fa8n = 0xC048F5C3;  // 0xC248 -3.14
        uint32_t fb8 = 0x3FCF1AA0;   // 0x3E79  1.618
        uint32_t fb8n = 0xBFCF1AA0;  // 0xBE79 -1.618

        int cmp0 = 0;
        int cmp1 = 0;
        int cmp2 = 0;
        int cmp3 = 0;

        asm volatile(
            "fmv.s.x ft3, %0\n"
            "fmv.s.x ft4, %1\n"
            "vfcpka.b.s ft5, ft4, ft3\n"
            "vfcpkb.b.s ft5, ft4, ft3\n"
            "vfcpkc.b.s ft5, ft4, ft3\n"
            "vfcpkd.b.s ft5, ft4, ft3\n"
            "vfcpka.b.s ft6, ft3, ft4\n"
            "vfcpkb.b.s ft6, ft3, ft4\n"
            "vfcpkc.b.s ft6, ft3, ft4\n"
            "vfcpkd.b.s ft6, ft3, ft4\n"
            "vfcpka.b.s ft7, ft3, ft3\n"
            "vfcpkb.b.s ft7, ft3, ft3\n"
            "vfcpkc.b.s ft7, ft3, ft3\n"
            "vfcpkd.b.s ft7, ft3, ft3\n"
            "vfcpka.b.s ft8, ft4, ft4\n"
            "vfcpkb.b.s ft8, ft4, ft4\n"
            "vfcpkc.b.s ft8, ft4, ft4\n"
            "vfcpkd.b.s ft8, ft4, ft4\n"
            : "+r"(fa8), "+r"(fb8));

        // vfeq
        asm volatile(
            "vfeq.b %0, ft5, ft5\n"
            "vfeq.b %1, ft6, ft6\n"
            "vfeq.b %2, ft5, ft6\n"
            "vfeq.b %3, ft6, ft5\n"
            : "+r"(cmp0), "+r"(cmp1), "+r"(cmp2), "+r"(cmp3));

        errs -= (cmp0 == 0xff);  // 1111
        errs -= (cmp1 == 0xff);  // 1111
        errs -= (cmp2 == 0);
        errs -= (cmp3 == 0);

        // vfeq.R
        asm volatile(
            "vfeq.r.b %0, ft5, ft5\n"
            "vfeq.r.b %1, ft6, ft6\n"
            "vfeq.r.b %2, ft5, ft6\n"
            "vfeq.r.b %3, ft6, ft5\n"
            : "+r"(cmp0), "+r"(cmp1), "+r"(cmp2), "+r"(cmp3));

        errs -= (cmp0 == 0x55);
        errs -= (cmp1 == 0x55);
        errs -= (cmp2 == 0xaa);
        errs -= (cmp3 == 0xaa);

        // vfne
        asm volatile(
            "vfne.b %0, ft5, ft5\n"
            "vfne.b %1, ft6, ft6\n"
            "vfne.b %2, ft5, ft6\n"
            "vfne.b %3, ft6, ft5\n"
            : "+r"(cmp0), "+r"(cmp1), "+r"(cmp2), "+r"(cmp3));

        errs -= (cmp0 == 0);
        errs -= (cmp1 == 0);
        errs -= (cmp2 == 0xff);
        errs -= (cmp3 == 0xff);

        // vfne.R
        asm volatile(
            "vfne.r.b %0, ft5, ft5\n"
            "vfne.r.b %1, ft6, ft6\n"
            "vfne.r.b %2, ft5, ft6\n"
            "vfne.r.b %3, ft6, ft5\n"
            : "+r"(cmp0), "+r"(cmp1), "+r"(cmp2), "+r"(cmp3));

        errs -= (cmp0 == 0xaa);
        errs -= (cmp1 == 0xaa);
        errs -= (cmp2 == 0x55);
        errs -= (cmp3 == 0x55);

        // vflt
        asm volatile(
            "vflt.b %0, ft5, ft5\n"
            "vflt.b %1, ft6, ft6\n"
            "vflt.b %2, ft5, ft6\n"
            "vflt.b %3, ft6, ft5\n"
            : "+r"(cmp0), "+r"(cmp1), "+r"(cmp2), "+r"(cmp3));

        errs -= (cmp0 == 0);
        errs -= (cmp1 == 0);
        errs -= (cmp2 == 0x55);
        errs -= (cmp3 == 0xaa);

        // vflt.R
        asm volatile(
            "vflt.r.b %0, ft5, ft5\n"
            "vflt.r.b %1, ft6, ft6\n"
            "vflt.r.b %2, ft5, ft6\n"
            "vflt.r.b %3, ft6, ft5\n"
            : "+r"(cmp0), "+r"(cmp1), "+r"(cmp2), "+r"(cmp3));

        errs -= (cmp0 == 0);
        errs -= (cmp1 == 0xaa);
        errs -= (cmp2 == 0x55);
        errs -= (cmp3 == 0);

        // vfle
        asm volatile(
            "vfle.b %0, ft5, ft5\n"
            "vfle.b %1, ft6, ft6\n"
            "vfle.b %2, ft5, ft6\n"
            "vfle.b %3, ft6, ft5\n"
            : "+r"(cmp0), "+r"(cmp1), "+r"(cmp2), "+r"(cmp3));

        errs -= (cmp0 == 0xff);
        errs -= (cmp1 == 0xff);
        errs -= (cmp2 == 0x55);
        errs -= (cmp3 == 0xaa);

        // vfle.R
        asm volatile(
            "vfle.r.b %0, ft5, ft5\n"
            "vfle.r.b %1, ft6, ft6\n"
            "vfle.r.b %2, ft5, ft6\n"
            "vfle.r.b %3, ft6, ft5\n"
            : "+r"(cmp0), "+r"(cmp1), "+r"(cmp2), "+r"(cmp3));

        errs -= (cmp0 == 0x55);
        errs -= (cmp1 == 0xff);
        errs -= (cmp2 == 0xff);
        errs -= (cmp3 == 0xaa);

        // vfgt
        asm volatile(
            "vfgt.b %0, ft5, ft5\n"
            "vfgt.b %1, ft6, ft6\n"
            "vfgt.b %2, ft5, ft6\n"
            "vfgt.b %3, ft6, ft5\n"
            : "+r"(cmp0), "+r"(cmp1), "+r"(cmp2), "+r"(cmp3));

        errs -= (cmp0 == 0);
        errs -= (cmp1 == 0);
        errs -= (cmp2 == 0xaa);
        errs -= (cmp3 == 0x55);

        // vfgt.R
        asm volatile(
            "vfgt.r.b %0, ft5, ft5\n"
            "vfgt.r.b %1, ft6, ft6\n"
            "vfgt.r.b %2, ft5, ft6\n"
            "vfgt.r.b %3, ft6, ft5\n"
            : "+r"(cmp0), "+r"(cmp1), "+r"(cmp2), "+r"(cmp3));

        errs -= (cmp0 == 0xaa);
        errs -= (cmp1 == 0);
        errs -= (cmp2 == 0);
        errs -= (cmp3 == 0x55);

        // vfge
        asm volatile(
            "vfge.b %0, ft5, ft5\n"
            "vfge.b %1, ft6, ft6\n"
            "vfge.b %2, ft5, ft6\n"
            "vfge.b %3, ft6, ft5\n"
            : "+r"(cmp0), "+r"(cmp1), "+r"(cmp2), "+r"(cmp3));

        errs -= (cmp0 == 0xff);
        errs -= (cmp1 == 0xff);
        errs -= (cmp2 == 0xaa);
        errs -= (cmp3 == 0x55);

        // vfge.R
        asm volatile(
            "vfge.r.b %0, ft5, ft5\n"
            "vfge.r.b %1, ft6, ft6\n"
            "vfge.r.b %2, ft5, ft6\n"
            "vfge.r.b %3, ft6, ft5\n"
            : "+r"(cmp0), "+r"(cmp1), "+r"(cmp2), "+r"(cmp3));

        errs -= (cmp0 == 0xff);
        errs -= (cmp1 == 0x55);
        errs -= (cmp2 == 0xaa);
        errs -= (cmp3 == 0xff);

        // vfmax
        asm volatile(
            "vfmax.b ft0, ft5, ft5\n"
            "vfeq.b %1, ft5, ft0\n"
            : "+r"(cmp0));
        errs -= (cmp0 == 0xff);

        asm volatile(
            "vfmax.b ft0, ft6, ft6\n"
            "vfeq.b %1, ft6, ft0\n"
            : "+r"(cmp0));
        errs -= (cmp0 == 0xff);

        asm volatile(
            "vfmax.b ft0, ft5, ft6\n"
            "vfeq.b %1, ft7, ft0\n"
            : "+r"(cmp0));
        errs -= (cmp0 == 0xff);

        asm volatile(
            "vfmax.b ft0, ft6, ft5\n"
            "vfeq.b %1, ft7, ft0\n"
            : "+r"(cmp0));
        errs -= (cmp0 == 0xff);

        // vfmax.R
        asm volatile(
            "vfmax.r.b ft0, ft5, ft5\n"
            "vfeq.b %1, ft5, ft0\n"
            : "+r"(cmp0));
        errs -= (cmp0 == 0xff);

        asm volatile(
            "vfmax.r.b ft0, ft6, ft6\n"
            "vfeq.b %1, ft7, ft0\n"
            : "+r"(cmp0));
        errs -= (cmp0 == 0xff);

        asm volatile(
            "vfmax.r.b ft0, ft5, ft6\n"
            "vfeq.b %1, ft7, ft0\n"
            : "+r"(cmp0));
        errs -= (cmp0 == 0xff);

        asm volatile(
            "vfmax.r.b ft0, ft6, ft5\n"
            "vfeq.b %1, ft6, ft0\n"
            : "+r"(cmp0));
        errs -= (cmp0 == 0xff);

        // vfmin
        asm volatile(
            "vfmin.b ft0, ft5, ft5\n"
            "vfeq.b %1, ft5, ft0\n"
            : "+r"(cmp0));
        errs -= (cmp0 == 0xff);

        asm volatile(
            "vfmin.b ft0, ft6, ft6\n"
            "vfeq.b %1, ft6, ft0\n"
            : "+r"(cmp0));
        errs -= (cmp0 == 0xff);

        asm volatile(
            "vfmin.b ft0, ft5, ft6\n"
            "vfeq.b %1, ft8, ft0\n"
            : "+r"(cmp0));
        errs -= (cmp0 == 0xff);

        asm volatile(
            "vfmin.b ft0, ft6, ft5\n"
            "vfeq.b %1, ft8, ft0\n"
            : "+r"(cmp0));
        errs -= (cmp0 == 0xff);

        // vfmin.R
        asm volatile(
            "vfmin.r.b ft0, ft5, ft5\n"
            "vfeq.b %1, ft8, ft0\n"
            : "+r"(cmp0));
        errs -= (cmp0 == 0xff);

        asm volatile(
            "vfmin.r.b ft0, ft6, ft6\n"
            "vfeq.b %1, ft6, ft0\n"
            : "+r"(cmp0));
        errs -= (cmp0 == 0xff);

        asm volatile(
            "vfmin.r.b ft0, ft5, ft6\n"
            "vfeq.b %1, ft5, ft0\n"
            : "+r"(cmp0));
        errs -= (cmp0 == 0xff);

        asm volatile(
            "vfmin.r.b ft0, ft6, ft5\n"
            "vfeq.b %1, ft8, ft0\n"
            : "+r"(cmp0));
        errs -= (cmp0 == 0xff);
    }

    return errs;
}
