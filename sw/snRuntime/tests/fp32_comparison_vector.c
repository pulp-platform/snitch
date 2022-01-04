// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include <snrt.h>

#include "printf.h"

int main() {
    int errs = 0;

    if (snrt_is_compute_core()) {
        uint32_t fa32 = 0x4048F5C3;   // 0x4248 3.14
        uint32_t fa32n = 0xC048F5C3;  // 0xC248 -3.14
        uint32_t fb32 = 0x3FCF1AA0;   // 0x3E79  1.618
        uint32_t fb32n = 0xBFCF1AA0;  // 0xBE79 -1.618

        int cmp0 = 0;
        int cmp1 = 0;
        int cmp2 = 0;
        int cmp3 = 0;

        asm volatile(
            "fmv.s.x ft3, %0\n"
            "fmv.s.x ft4, %1\n"
            "vfcpka.s.s ft5, ft4, ft3\n"  // ft5 = {3.14, 1.618}
            "vfcpka.s.s ft6, ft3, ft4\n"  // ft6 = {1.618, 3.14}
            "vfcpka.s.s ft7, ft3, ft3\n"  // ft7 = {3.14, 3.14}
            "vfcpka.s.s ft8, ft4, ft4\n"  // ft8 = {1.618, 1.618}
            : "+r"(fa32), "+r"(fb32));

        // vfeq
        asm volatile(
            "vfeq.s %0, ft5, ft5\n"
            "vfeq.s %1, ft6, ft6\n"
            "vfeq.s %2, ft5, ft6\n"
            "vfeq.s %3, ft6, ft5\n"
            : "+r"(cmp0), "+r"(cmp1), "+r"(cmp2), "+r"(cmp3));

        errs += (cmp0 != 3);
        errs += (cmp1 != 3);
        errs += (cmp2 != 0);
        errs += (cmp3 != 0);

        // vfeq.R
        asm volatile(
            "vfeq.r.s %0, ft5, ft5\n"
            "vfeq.r.s %1, ft6, ft6\n"
            "vfeq.r.s %2, ft5, ft6\n"
            "vfeq.r.s %3, ft6, ft5\n"
            : "+r"(cmp0), "+r"(cmp1), "+r"(cmp2), "+r"(cmp3));

        errs += (cmp0 != 1);
        errs += (cmp1 != 1);
        errs += (cmp2 != 2);
        errs += (cmp3 != 2);

        // vfne
        asm volatile(
            "vfne.s %0, ft5, ft5\n"
            "vfne.s %1, ft6, ft6\n"
            "vfne.s %2, ft5, ft6\n"
            "vfne.s %3, ft6, ft5\n"
            : "+r"(cmp0), "+r"(cmp1), "+r"(cmp2), "+r"(cmp3));

        errs += (cmp0 != 0);
        errs += (cmp1 != 0);
        errs += (cmp2 != 3);
        errs += (cmp3 != 3);

        // vfne.R
        asm volatile(
            "vfne.r.s %0, ft5, ft5\n"
            "vfne.r.s %1, ft6, ft6\n"
            "vfne.r.s %2, ft5, ft6\n"
            "vfne.r.s %3, ft6, ft5\n"
            : "+r"(cmp0), "+r"(cmp1), "+r"(cmp2), "+r"(cmp3));

        errs += (cmp0 != 2);
        errs += (cmp1 != 2);
        errs += (cmp2 != 1);
        errs += (cmp3 != 1);

        // vflt
        asm volatile(
            "vflt.s %0, ft5, ft5\n"
            "vflt.s %1, ft6, ft6\n"
            "vflt.s %2, ft5, ft6\n"
            "vflt.s %3, ft6, ft5\n"
            : "+r"(cmp0), "+r"(cmp1), "+r"(cmp2), "+r"(cmp3));

        errs += (cmp0 != 0);
        errs += (cmp1 != 0);
        errs += (cmp2 != 1);
        errs += (cmp3 != 2);

        // vflt.R
        asm volatile(
            "vflt.r.s %0, ft5, ft5\n"
            "vflt.r.s %1, ft6, ft6\n"
            "vflt.r.s %2, ft5, ft6\n"
            "vflt.r.s %3, ft6, ft5\n"
            : "+r"(cmp0), "+r"(cmp1), "+r"(cmp2), "+r"(cmp3));

        errs += (cmp0 != 0);
        errs += (cmp1 != 2);
        errs += (cmp2 != 1);
        errs += (cmp3 != 0);

        // vfle
        asm volatile(
            "vfle.s %0, ft5, ft5\n"
            "vfle.s %1, ft6, ft6\n"
            "vfle.s %2, ft5, ft6\n"
            "vfle.s %3, ft6, ft5\n"
            : "+r"(cmp0), "+r"(cmp1), "+r"(cmp2), "+r"(cmp3));

        errs += (cmp0 != 3);
        errs += (cmp1 != 3);
        errs += (cmp2 != 1);
        errs += (cmp3 != 2);

        // vfle.R
        asm volatile(
            "vfle.r.s %0, ft5, ft5\n"
            "vfle.r.s %1, ft6, ft6\n"
            "vfle.r.s %2, ft5, ft6\n"
            "vfle.r.s %3, ft6, ft5\n"
            : "+r"(cmp0), "+r"(cmp1), "+r"(cmp2), "+r"(cmp3));

        errs += (cmp0 != 1);
        errs += (cmp1 != 3);
        errs += (cmp2 != 3);
        errs += (cmp3 != 2);

        // vfgt
        asm volatile(
            "vfgt.s %0, ft5, ft5\n"
            "vfgt.s %1, ft6, ft6\n"
            "vfgt.s %2, ft5, ft6\n"
            "vfgt.s %3, ft6, ft5\n"
            : "+r"(cmp0), "+r"(cmp1), "+r"(cmp2), "+r"(cmp3));

        errs += (cmp0 != 0);
        errs += (cmp1 != 0);
        errs += (cmp2 != 2);
        errs += (cmp3 != 1);

        // vfgt.R
        asm volatile(
            "vfgt.r.s %0, ft5, ft5\n"
            "vfgt.r.s %1, ft6, ft6\n"
            "vfgt.r.s %2, ft5, ft6\n"
            "vfgt.r.s %3, ft6, ft5\n"
            : "+r"(cmp0), "+r"(cmp1), "+r"(cmp2), "+r"(cmp3));

        errs += (cmp0 != 2);
        errs += (cmp1 != 0);
        errs += (cmp2 != 0);
        errs += (cmp3 != 1);

        // vfge
        asm volatile(
            "vfge.s %0, ft5, ft5\n"
            "vfge.s %1, ft6, ft6\n"
            "vfge.s %2, ft5, ft6\n"
            "vfge.s %3, ft6, ft5\n"
            : "+r"(cmp0), "+r"(cmp1), "+r"(cmp2), "+r"(cmp3));

        errs += (cmp0 != 3);
        errs += (cmp1 != 3);
        errs += (cmp2 != 2);
        errs += (cmp3 != 1);

        // vfge.R
        asm volatile(
            "vfge.r.s %0, ft5, ft5\n"
            "vfge.r.s %1, ft6, ft6\n"
            "vfge.r.s %2, ft5, ft6\n"
            "vfge.r.s %3, ft6, ft5\n"
            : "+r"(cmp0), "+r"(cmp1), "+r"(cmp2), "+r"(cmp3));

        errs += (cmp0 != 3);
        errs += (cmp1 != 1);
        errs += (cmp2 != 2);
        errs += (cmp3 != 3);

        // vfmax
        asm volatile(
            "vfmax.s ft0, ft5, ft5\n"
            "vfeq.s %1, ft5, ft0\n"
            : "+r"(cmp0));
        errs += (cmp0 != 3);

        asm volatile(
            "vfmax.s ft0, ft6, ft6\n"
            "vfeq.s %1, ft6, ft0\n"
            : "+r"(cmp0));
        errs += (cmp0 != 3);

        asm volatile(
            "vfmax.s ft0, ft5, ft6\n"
            "vfeq.s %1, ft7, ft0\n"
            : "+r"(cmp0));
        errs += (cmp0 != 3);

        asm volatile(
            "vfmax.s ft0, ft6, ft5\n"
            "vfeq.s %1, ft7, ft0\n"
            : "+r"(cmp0));
        errs += (cmp0 != 3);

        // vfmax.R
        asm volatile(
            "vfmax.r.s ft0, ft5, ft5\n"
            "vfeq.s %1, ft5, ft0\n"
            : "+r"(cmp0));
        errs += (cmp0 != 3);

        asm volatile(
            "vfmax.r.s ft0, ft6, ft6\n"
            "vfeq.s %1, ft7, ft0\n"
            : "+r"(cmp0));
        errs += (cmp0 != 3);

        asm volatile(
            "vfmax.r.s ft0, ft5, ft6\n"
            "vfeq.s %1, ft7, ft0\n"
            : "+r"(cmp0));
        errs += (cmp0 != 3);

        asm volatile(
            "vfmax.r.s ft0, ft6, ft5\n"
            "vfeq.s %1, ft6, ft0\n"
            : "+r"(cmp0));
        errs += (cmp0 != 3);

        // vfmin
        asm volatile(
            "vfmin.s ft0, ft5, ft5\n"
            "vfeq.s %1, ft5, ft0\n"
            : "+r"(cmp0));
        errs += (cmp0 != 3);

        asm volatile(
            "vfmin.s ft0, ft6, ft6\n"
            "vfeq.s %1, ft6, ft0\n"
            : "+r"(cmp0));
        errs += (cmp0 != 3);

        asm volatile(
            "vfmin.s ft0, ft5, ft6\n"
            "vfeq.s %1, ft8, ft0\n"
            : "+r"(cmp0));
        errs += (cmp0 != 3);

        asm volatile(
            "vfmin.s ft0, ft6, ft5\n"
            "vfeq.s %1, ft8, ft0\n"
            : "+r"(cmp0));
        errs += (cmp0 != 3);

        // vfmin.R
        asm volatile(
            "vfmin.r.s ft0, ft5, ft5\n"
            "vfeq.s %1, ft8, ft0\n"
            : "+r"(cmp0));
        errs += (cmp0 != 3);

        asm volatile(
            "vfmin.r.s ft0, ft6, ft6\n"
            "vfeq.s %1, ft6, ft0\n"
            : "+r"(cmp0));
        errs += (cmp0 != 3);

        asm volatile(
            "vfmin.r.s ft0, ft5, ft6\n"
            "vfeq.s %1, ft5, ft0\n"
            : "+r"(cmp0));
        errs += (cmp0 != 3);

        asm volatile(
            "vfmin.r.s ft0, ft6, ft5\n"
            "vfeq.s %1, ft8, ft0\n"
            : "+r"(cmp0));
        errs += (cmp0 != 3);
    }

    return errs;
}
