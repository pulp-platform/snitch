// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include <snrt.h>
#include "printf.h"


int main() {

    int errs = 0;

    if (snrt_is_compute_core()) {

        uint32_t fa16  = 0x4048F5C3; // 0x4248 3.14
        uint32_t fa16n = 0xC048F5C3; // 0xC248 -3.14
        uint32_t fb16  = 0x3FCF1AA0; // 0x3E79  1.618
        uint32_t fb16n = 0xBFCF1AA0; // 0xBE79 -1.618
        
        int cmp0 = 0;
        int cmp1 = 0;
        int cmp2 = 0;
        int cmp3 = 0;

        asm volatile(
            "fmv.s.x ft3, %0\n"
            "fmv.s.x ft4, %1\n"
            "vfcpka.h.s ft5, ft4, ft3\n"
            "vfcpkb.h.s ft5, ft4, ft3\n" // ft5 = {3.14, 1.618, 3.14, 1.618}
            "vfcpka.h.s ft6, ft3, ft4\n"
            "vfcpkb.h.s ft6, ft3, ft4\n" // ft6 = {1.618, 3.14, 1.618, 3.14}
            : "+r"(fa16), "+r"(fb16)
        );

        // vfeq
        asm volatile(
            "vfeq.h %0, ft5, ft5\n"
            "vfeq.h %1, ft6, ft6\n"
            "vfeq.h %2, ft5, ft6\n"
            "vfeq.h %3, ft6, ft5\n"
            : "+r"(cmp0), "+r"(cmp1),
            "+r"(cmp2), "+r"(cmp3)
        );

        errs += (cmp0!=0xf); // 1111
        errs += (cmp1!=0xf); // 1111
        errs += (cmp2!=0);
        errs += (cmp3!=0);

        // vfeq.R
        asm volatile(
            "vfeq.r.h %0, ft5, ft5\n"
            "vfeq.r.h %1, ft6, ft6\n"
            "vfeq.r.h %2, ft5, ft6\n"
            "vfeq.r.h %3, ft6, ft5\n"
            : "+r"(cmp0), "+r"(cmp1),
            "+r"(cmp2), "+r"(cmp3)
        );

        errs += (cmp0!=0x5);
        errs += (cmp1!=0x5);
        errs += (cmp2!=0xa);
        errs += (cmp3!=0xa);

        // vfne
        asm volatile(
            "vfne.h %0, ft5, ft5\n"
            "vfne.h %1, ft6, ft6\n"
            "vfne.h %2, ft5, ft6\n"
            "vfne.h %3, ft6, ft5\n"
            : "+r"(cmp0), "+r"(cmp1),
            "+r"(cmp2), "+r"(cmp3)
        );

        errs += (cmp0!=0);
        errs += (cmp1!=0);
        errs += (cmp2!=0xf);
        errs += (cmp3!=0xf);

        // vfne.R
        asm volatile(
            "vfne.r.h %0, ft5, ft5\n"
            "vfne.r.h %1, ft6, ft6\n"
            "vfne.r.h %2, ft5, ft6\n"
            "vfne.r.h %3, ft6, ft5\n"
            : "+r"(cmp0), "+r"(cmp1),
            "+r"(cmp2), "+r"(cmp3)
        );

        errs += (cmp0!=0xa);
        errs += (cmp1!=0xa);
        errs += (cmp2!=0x5);
        errs += (cmp3!=0x5);

        // vflt
        asm volatile(
            "vflt.h %0, ft5, ft5\n"
            "vflt.h %1, ft6, ft6\n"
            "vflt.h %2, ft5, ft6\n"
            "vflt.h %3, ft6, ft5\n"
            : "+r"(cmp0), "+r"(cmp1),
            "+r"(cmp2), "+r"(cmp3)
        );

        errs += (cmp0!=0);
        errs += (cmp1!=0);
        errs += (cmp2!=0x5);
        errs += (cmp3!=0xa);

        // vflt.R
        asm volatile(
            "vflt.r.h %0, ft5, ft5\n"
            "vflt.r.h %1, ft6, ft6\n"
            "vflt.r.h %2, ft5, ft6\n"
            "vflt.r.h %3, ft6, ft5\n"
            : "+r"(cmp0), "+r"(cmp1),
            "+r"(cmp2), "+r"(cmp3)
        );

        errs += (cmp0!=0);
        errs += (cmp1!=0xa);
        errs += (cmp2!=0x5);
        errs += (cmp3!=0);

        // vfle
        asm volatile(
            "vfle.h %0, ft5, ft5\n"
            "vfle.h %1, ft6, ft6\n"
            "vfle.h %2, ft5, ft6\n"
            "vfle.h %3, ft6, ft5\n"
            : "+r"(cmp0), "+r"(cmp1),
            "+r"(cmp2), "+r"(cmp3)
        );

        errs += (cmp0!=0xf);
        errs += (cmp1!=0xf);
        errs += (cmp2!=0x5);
        errs += (cmp3!=0xa);

        // vfle.R
        asm volatile(
            "vfle.r.h %0, ft5, ft5\n"
            "vfle.r.h %1, ft6, ft6\n"
            "vfle.r.h %2, ft5, ft6\n"
            "vfle.r.h %3, ft6, ft5\n"
            : "+r"(cmp0), "+r"(cmp1),
            "+r"(cmp2), "+r"(cmp3)
        );

        errs += (cmp0!=0x5);
        errs += (cmp1!=0xf);
        errs += (cmp2!=0xf);
        errs += (cmp3!=0xa);

        // vfgt
        asm volatile(
            "vfgt.h %0, ft5, ft5\n"
            "vfgt.h %1, ft6, ft6\n"
            "vfgt.h %2, ft5, ft6\n"
            "vfgt.h %3, ft6, ft5\n"
            : "+r"(cmp0), "+r"(cmp1),
            "+r"(cmp2), "+r"(cmp3)
        );

        errs += (cmp0!=0);
        errs += (cmp1!=0);
        errs += (cmp2!=0xa);
        errs += (cmp3!=0x5);

        // vfgt.R
        asm volatile(
            "vfgt.r.h %0, ft5, ft5\n"
            "vfgt.r.h %1, ft6, ft6\n"
            "vfgt.r.h %2, ft5, ft6\n"
            "vfgt.r.h %3, ft6, ft5\n"
            : "+r"(cmp0), "+r"(cmp1),
            "+r"(cmp2), "+r"(cmp3)
        );

        errs += (cmp0!=0xa);
        errs += (cmp1!=0);
        errs += (cmp2!=0);
        errs += (cmp3!=0x5);

        // vfge
        asm volatile(
            "vfge.h %0, ft5, ft5\n"
            "vfge.h %1, ft6, ft6\n"
            "vfge.h %2, ft5, ft6\n"
            "vfge.h %3, ft6, ft5\n"
            : "+r"(cmp0), "+r"(cmp1),
            "+r"(cmp2), "+r"(cmp3)
        );

        errs += (cmp0!=0xf);
        errs += (cmp1!=0xf);
        errs += (cmp2!=0xa);
        errs += (cmp3!=0x5);

        // vfge.R
        asm volatile(
            "vfge.r.h %0, ft5, ft5\n"
            "vfge.r.h %1, ft6, ft6\n"
            "vfge.r.h %2, ft5, ft6\n"
            "vfge.r.h %3, ft6, ft5\n"
            : "+r"(cmp0), "+r"(cmp1),
            "+r"(cmp2), "+r"(cmp3)
        );

        errs += (cmp0!=0xf);
        errs += (cmp1!=0x5);
        errs += (cmp2!=0xa);
        errs += (cmp3!=0xf);

    }

    return 0;

}
