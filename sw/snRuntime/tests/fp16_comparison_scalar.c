// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include <snrt.h>

#include "printf.h"

int main() {
    int errs = 0;

    if (snrt_is_compute_core()) {
        uint32_t i8a = 0xFFFF4248;   // 3.14
        uint32_t i8an = 0xFFFFC248;  // -3.14
        uint32_t i8b = 0xFFFF3E79;   // 1.618
        uint32_t i8bn = 0xFFFFBE79;  // -1.618

        int cmp0 = 0;
        int cmp1 = 0;
        int cmp2 = 0;
        int cmp3 = 0;

        float fcmp0 = 0;
        float fcmp1 = 0;

        asm volatile(
            "fmv.s.x ft3, %0\n"
            "fmv.s.x ft4, %1\n"
            "fmv.s.x ft5, %2\n"
            "fmv.s.x ft6, %3\n"
            : "+r"(i8a), "+r"(i8an), "+r"(i8b), "+r"(i8bn));

        // FEQ
        asm volatile(
            "feq.h %0, ft3, ft3\n"
            "feq.h %1, ft4, ft4\n"
            "feq.h %2, ft5, ft5\n"
            "feq.h %3, ft6, ft6\n"
            : "+r"(cmp0), "+r"(cmp1), "+r"(cmp2), "+r"(cmp3));

        errs += (cmp0 != 0x1);
        errs += (cmp1 != 0x1);
        errs += (cmp2 != 0x1);
        errs += (cmp3 != 0x1);

        asm volatile(
            "feq.h %0, ft3, ft4\n"
            "feq.h %1, ft4, ft5\n"
            "feq.h %2, ft5, ft6\n"
            "feq.h %3, ft3, ft6\n"
            : "+r"(cmp0), "+r"(cmp1), "+r"(cmp2), "+r"(cmp3));

        errs += (cmp0 != 0x0);
        errs += (cmp1 != 0x0);
        errs += (cmp2 != 0x0);
        errs += (cmp3 != 0x0);

        // FLE
        asm volatile(
            "fle.h %0, ft3, ft3\n"
            "fle.h %1, ft4, ft4\n"
            "fle.h %2, ft5, ft5\n"
            "fle.h %3, ft6, ft6\n"
            : "+r"(cmp0), "+r"(cmp1), "+r"(cmp2), "+r"(cmp3));

        errs += (cmp0 != 0x1);
        errs += (cmp1 != 0x1);
        errs += (cmp2 != 0x1);
        errs += (cmp3 != 0x1);

        asm volatile(
            "fle.h %0, ft3, ft4\n"
            "fle.h %1, ft4, ft5\n"
            "fle.h %2, ft5, ft6\n"
            "fle.h %3, ft3, ft6\n"
            : "+r"(cmp0), "+r"(cmp1), "+r"(cmp2), "+r"(cmp3));

        errs += (cmp0 != 0x0);
        errs += (cmp1 != 0x1);
        errs += (cmp2 != 0x0);
        errs += (cmp3 != 0x0);

        // FLT
        asm volatile(
            "flt.h %0, ft3, ft3\n"
            "flt.h %1, ft4, ft4\n"
            "flt.h %2, ft5, ft5\n"
            "flt.h %3, ft6, ft6\n"
            : "+r"(cmp0), "+r"(cmp1), "+r"(cmp2), "+r"(cmp3));

        errs += (cmp0 != 0x0);
        errs += (cmp1 != 0x0);
        errs += (cmp2 != 0x0);
        errs += (cmp3 != 0x0);

        asm volatile(
            "flt.h %0, ft3, ft4\n"
            "flt.h %1, ft4, ft5\n"
            "flt.h %2, ft5, ft6\n"
            "flt.h %3, ft3, ft6\n"
            : "+r"(cmp0), "+r"(cmp1), "+r"(cmp2), "+r"(cmp3));

        errs += (cmp0 != 0x0);
        errs += (cmp1 != 0x1);
        errs += (cmp2 != 0x0);
        errs += (cmp3 != 0x0);

        // FMIN
        asm volatile(
            "fmin.h %0, ft3, ft3\n"
            "fmin.h %1, ft4, ft4\n"
            : "+f"(fcmp0), "+f"(fcmp1));

        asm volatile(
            "feq.h %0, %2, ft3\n"
            "feq.h %1, %3, ft4\n"
            : "+r"(cmp0), "+r"(cmp1), "+f"(fcmp0), "+f"(fcmp1));

        errs += (cmp0 != 0x1);
        errs += (cmp1 != 0x1);
        // printf("[INFO] fres %f \n", fcmp0)

        asm volatile(
            "fmin.h %0, ft5, ft5\n"
            "fmin.h %1, ft6, ft6\n"
            : "+f"(fcmp0), "+f"(fcmp1));

        asm volatile(
            "feq.h %0, %2, ft5\n"
            "feq.h %1, %3, ft6\n"
            : "+r"(cmp0), "+r"(cmp1), "+f"(fcmp0), "+f"(fcmp1));

        errs += (cmp0 != 0x1);
        errs += (cmp1 != 0x1);

        asm volatile(
            "fmin.h %0, ft3, ft4\n"
            "fmin.h %1, ft4, ft5\n"
            : "+f"(fcmp0), "+f"(fcmp1));

        asm volatile(
            "feq.h %0, %2, ft4\n"
            "feq.h %1, %3, ft4\n"
            : "+r"(cmp0), "+r"(cmp1), "+f"(fcmp0), "+f"(fcmp1));

        errs += (cmp0 != 0x1);
        errs += (cmp1 != 0x1);

        asm volatile(
            "fmin.h %0, ft5, ft6\n"
            "fmin.h %1, ft3, ft6\n"
            : "+f"(fcmp0), "+f"(fcmp1));

        asm volatile(
            "feq.h %0, %2, ft6\n"
            "feq.h %1, %3, ft6\n"
            : "+r"(cmp0), "+r"(cmp1), "+f"(fcmp0), "+f"(fcmp1));

        errs += (cmp0 != 0x1);
        errs += (cmp1 != 0x1);

        // FMAX
        asm volatile(
            "fmax.h %0, ft3, ft3\n"
            "fmax.h %1, ft4, ft4\n"
            : "+f"(fcmp0), "+f"(fcmp1));

        asm volatile(
            "feq.h %0, %2, ft3\n"
            "feq.h %1, %3, ft4\n"
            : "+r"(cmp0), "+r"(cmp1), "+f"(fcmp0), "+f"(fcmp1));

        errs += (cmp0 != 0x1);
        errs += (cmp1 != 0x1);

        asm volatile(
            "fmax.h %0, ft5, ft5\n"
            "fmax.h %1, ft6, ft6\n"
            : "+f"(fcmp0), "+f"(fcmp1));

        asm volatile(
            "feq.h %0, %2, ft5\n"
            "feq.h %1, %3, ft6\n"
            : "+r"(cmp0), "+r"(cmp1), "+f"(fcmp0), "+f"(fcmp1));

        errs += (cmp0 != 0x1);
        errs += (cmp1 != 0x1);

        asm volatile(
            "fmax.h %0, ft3, ft4\n"
            "fmax.h %1, ft4, ft5\n"
            : "+f"(fcmp0), "+f"(fcmp1));

        asm volatile(
            "feq.h %0, %2, ft3\n"
            "feq.h %1, %3, ft5\n"
            : "+r"(cmp0), "+r"(cmp1), "+f"(fcmp0), "+f"(fcmp1));

        errs += (cmp0 != 0x1);
        errs += (cmp1 != 0x1);

        asm volatile(
            "fmax.h %0, ft5, ft6\n"
            "fmax.h %1, ft3, ft6\n"
            : "+f"(fcmp0), "+f"(fcmp1));

        asm volatile(
            "feq.h %0, %2, ft5\n"
            "feq.h %1, %3, ft3\n"
            : "+r"(cmp0), "+r"(cmp1), "+f"(fcmp0), "+f"(fcmp1));

        errs += (cmp0 != 0x1);
        errs += (cmp1 != 0x1);
    }

    return errs;
}
