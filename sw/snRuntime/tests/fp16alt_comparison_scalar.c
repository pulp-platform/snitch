// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include <snrt.h>

#include "printf.h"

int main() {
    int errs = 0;

    if (snrt_is_compute_core()) {
        uint32_t i8a = 0xFFFF4049;   // 3.14
        uint32_t i8an = 0xFFFFC049;  // -3.14
        uint32_t i8b = 0xFFFF3FCF;   // 1.618
        uint32_t i8bn = 0xFFFFBFCF;  // -1.618

        int cmp0 = 0;
        int cmp1 = 0;
        int cmp2 = 0;
        int cmp3 = 0;

        float fcmp0 = 0;
        float fcmp1 = 0;

        write_csr(2048, 3);

        asm volatile(
            "fmv.s.x ft3, %0\n"
            "fmv.s.x ft4, %1\n"
            "fmv.s.x ft5, %2\n"
            "fmv.s.x ft6, %3\n"
            : "+r"(i8a), "+r"(i8an), "+r"(i8b), "+r"(i8bn));

        // FEQ
        asm volatile(
            "feq.ah %0, ft3, ft3\n"
            "feq.ah %1, ft4, ft4\n"
            "feq.ah %2, ft5, ft5\n"
            "feq.ah %3, ft6, ft6\n"
            : "+r"(cmp0), "+r"(cmp1), "+r"(cmp2), "+r"(cmp3));

        errs += (cmp0 != 0x1);
        errs += (cmp1 != 0x1);
        errs += (cmp2 != 0x1);
        errs += (cmp3 != 0x1);

        asm volatile(
            "feq.ah %0, ft3, ft4\n"
            "feq.ah %1, ft4, ft5\n"
            "feq.ah %2, ft5, ft6\n"
            "feq.ah %3, ft3, ft6\n"
            : "+r"(cmp0), "+r"(cmp1), "+r"(cmp2), "+r"(cmp3));

        errs += (cmp0 != 0x0);
        errs += (cmp1 != 0x0);
        errs += (cmp2 != 0x0);
        errs += (cmp3 != 0x0);

        // FLE
        asm volatile(
            "fle.ah %0, ft3, ft3\n"
            "fle.ah %1, ft4, ft4\n"
            "fle.ah %2, ft5, ft5\n"
            "fle.ah %3, ft6, ft6\n"
            : "+r"(cmp0), "+r"(cmp1), "+r"(cmp2), "+r"(cmp3));

        errs += (cmp0 != 0x1);
        errs += (cmp1 != 0x1);
        errs += (cmp2 != 0x1);
        errs += (cmp3 != 0x1);

        asm volatile(
            "fle.ah %0, ft3, ft4\n"
            "fle.ah %1, ft4, ft5\n"
            "fle.ah %2, ft5, ft6\n"
            "fle.ah %3, ft3, ft6\n"
            : "+r"(cmp0), "+r"(cmp1), "+r"(cmp2), "+r"(cmp3));

        errs += (cmp0 != 0x0);
        errs += (cmp1 != 0x1);
        errs += (cmp2 != 0x0);
        errs += (cmp3 != 0x0);

        // FLT
        asm volatile(
            "flt.ah %0, ft3, ft3\n"
            "flt.ah %1, ft4, ft4\n"
            "flt.ah %2, ft5, ft5\n"
            "flt.ah %3, ft6, ft6\n"
            : "+r"(cmp0), "+r"(cmp1), "+r"(cmp2), "+r"(cmp3));

        errs += (cmp0 != 0x0);
        errs += (cmp1 != 0x0);
        errs += (cmp2 != 0x0);
        errs += (cmp3 != 0x0);

        asm volatile(
            "flt.ah %0, ft3, ft4\n"
            "flt.ah %1, ft4, ft5\n"
            "flt.ah %2, ft5, ft6\n"
            "flt.ah %3, ft3, ft6\n"
            : "+r"(cmp0), "+r"(cmp1), "+r"(cmp2), "+r"(cmp3));

        errs += (cmp0 != 0x0);
        errs += (cmp1 != 0x1);
        errs += (cmp2 != 0x0);
        errs += (cmp3 != 0x0);

        // FMIN
        asm volatile(
            "fmin.ah %0, ft3, ft3\n"
            "fmin.ah %1, ft4, ft4\n"
            : "+f"(fcmp0), "+f"(fcmp1));

        asm volatile(
            "feq.ah %0, %2, ft3\n"
            "feq.ah %1, %3, ft4\n"
            : "+r"(cmp0), "+r"(cmp1), "+f"(fcmp0), "+f"(fcmp1));

        errs += (cmp0 != 0x1);
        errs += (cmp1 != 0x1);
        // printf("[INFO] fres %f \n", fcmp0)

        asm volatile(
            "fmin.ah %0, ft5, ft5\n"
            "fmin.ah %1, ft6, ft6\n"
            : "+f"(fcmp0), "+f"(fcmp1));

        asm volatile(
            "feq.ah %0, %2, ft5\n"
            "feq.ah %1, %3, ft6\n"
            : "+r"(cmp0), "+r"(cmp1), "+f"(fcmp0), "+f"(fcmp1));

        errs += (cmp0 != 0x1);
        errs += (cmp1 != 0x1);

        asm volatile(
            "fmin.ah %0, ft3, ft4\n"
            "fmin.ah %1, ft4, ft5\n"
            : "+f"(fcmp0), "+f"(fcmp1));

        asm volatile(
            "feq.ah %0, %2, ft4\n"
            "feq.ah %1, %3, ft4\n"
            : "+r"(cmp0), "+r"(cmp1), "+f"(fcmp0), "+f"(fcmp1));

        errs += (cmp0 != 0x1);
        errs += (cmp1 != 0x1);

        asm volatile(
            "fmin.ah %0, ft5, ft6\n"
            "fmin.ah %1, ft3, ft6\n"
            : "+f"(fcmp0), "+f"(fcmp1));

        asm volatile(
            "feq.ah %0, %2, ft6\n"
            "feq.ah %1, %3, ft6\n"
            : "+r"(cmp0), "+r"(cmp1), "+f"(fcmp0), "+f"(fcmp1));

        errs += (cmp0 != 0x1);
        errs += (cmp1 != 0x1);

        // FMAX
        asm volatile(
            "fmax.ah %0, ft3, ft3\n"
            "fmax.ah %1, ft4, ft4\n"
            : "+f"(fcmp0), "+f"(fcmp1));

        asm volatile(
            "feq.ah %0, %2, ft3\n"
            "feq.ah %1, %3, ft4\n"
            : "+r"(cmp0), "+r"(cmp1), "+f"(fcmp0), "+f"(fcmp1));

        errs += (cmp0 != 0x1);
        errs += (cmp1 != 0x1);

        asm volatile(
            "fmax.ah %0, ft5, ft5\n"
            "fmax.ah %1, ft6, ft6\n"
            : "+f"(fcmp0), "+f"(fcmp1));

        asm volatile(
            "feq.ah %0, %2, ft5\n"
            "feq.ah %1, %3, ft6\n"
            : "+r"(cmp0), "+r"(cmp1), "+f"(fcmp0), "+f"(fcmp1));

        errs += (cmp0 != 0x1);
        errs += (cmp1 != 0x1);

        asm volatile(
            "fmax.ah %0, ft3, ft4\n"
            "fmax.ah %1, ft4, ft5\n"
            : "+f"(fcmp0), "+f"(fcmp1));

        asm volatile(
            "feq.ah %0, %2, ft3\n"
            "feq.ah %1, %3, ft5\n"
            : "+r"(cmp0), "+r"(cmp1), "+f"(fcmp0), "+f"(fcmp1));

        errs += (cmp0 != 0x1);
        errs += (cmp1 != 0x1);

        asm volatile(
            "fmax.ah %0, ft5, ft6\n"
            "fmax.ah %1, ft3, ft6\n"
            : "+f"(fcmp0), "+f"(fcmp1));

        asm volatile(
            "feq.ah %0, %2, ft5\n"
            "feq.ah %1, %3, ft3\n"
            : "+r"(cmp0), "+r"(cmp1), "+f"(fcmp0), "+f"(fcmp1));

        errs += (cmp0 != 0x1);
        errs += (cmp1 != 0x1);
    }

    return errs;
}
