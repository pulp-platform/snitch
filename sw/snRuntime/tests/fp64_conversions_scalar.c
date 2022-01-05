// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include <snrt.h>

#include "printf.h"

typedef float v2s __attribute__((vector_size(8)));

int main() {
    int errs = 0;

    if (snrt_is_compute_core()) {
        unsigned int res_cvt0 = 0;
        unsigned int res_cvt1 = 0;

        double fvalue = 0.0;
        double fvalue_negative = 0.0;

        uint32_t i32a = 0x4048F5C3;   // 3.14
        uint32_t i32an = 0xC048F5C3;  // -3.14
        uint32_t i32b = 0x3FCF1AA0;   // 1.618
        uint32_t i32bn = 0xBFCF1AA0;  // -1.618
        uint32_t i32c = 0x4018FFEB;   // 2.39
        uint32_t i32cn = 0xC018FFEB;  // -2.39
        uint32_t i32d = 0x3E801FFB;   // 0.25
        uint32_t i32dn = 0xBE801FFB;  // -0.25
        uint32_t i32e = 0x3F000000;   // 0.5
        uint32_t i32en = 0xBF000000;  // -0.5
        uint32_t i32f = 0x42C83F36;   // 100.12345
        uint32_t i32fn = 0xC2C83F36;  // -100.12345

        uint32_t i16a = 0xFFFF4248;   // 3.14
        uint32_t i16an = 0xFFFFC248;  // -3.14
        uint32_t i16b = 0xFFFF3E79;   // 1.618
        uint32_t i16bn = 0xFFFFBE79;  // -1.618
        uint32_t i16c = 0xFFFF40C8;   // 2.39
        uint32_t i16cn = 0xFFFFC0C8;  // -2.39
        uint32_t i16d = 0xFFFF3401;   // 0.25
        uint32_t i16dn = 0xFFFFB401;  // -0.25
        uint32_t i16e = 0xFFFF3800;   // 0.5
        uint32_t i16en = 0xFFFFB800;  // -0.5
        uint32_t i16f = 0xFFFF5642;   // 100.12345
        uint32_t i16fn = 0xFFFFD642;  // -100.12345

        uint32_t ia16a = 0xFFFF4049;   // 3.14
        uint32_t ia16an = 0xFFFFC049;  // -3.14
        uint32_t ia16b = 0xFFFF3FCF;   // 1.618
        uint32_t ia16bn = 0xFFFFBFCF;  // -1.618
        uint32_t ia16c = 0xFFFF4019;   // 2.39
        uint32_t ia16cn = 0xFFFFC019;  // -2.39
        uint32_t ia16d = 0xFFFF3E80;   // 0.25
        uint32_t ia16dn = 0xFFFFBE80;  // -0.25
        uint32_t ia16e = 0xFFFF3F00;   // 0.5
        uint32_t ia16en = 0xFFFFBF00;  // -0.5
        uint32_t ia16f = 0xFFFF42C8;   // 100.12345
        uint32_t ia16fn = 0xFFFFC2C8;  // -100.12345

        uint32_t i8a = 0xFFFFFF42;   // 3.14
        uint32_t i8an = 0xFFFFFFC2;  // -3.14
        uint32_t i8b = 0xFFFFFF3E;   // 1.618
        uint32_t i8bn = 0xFFFFFFBE;  // -1.618
        uint32_t i8c = 0xFFFFFF41;   // 2.39
        uint32_t i8cn = 0xFFFFFFC1;  // -2.39
        uint32_t i8d = 0xFFFFFF34;   // 0.25
        uint32_t i8dn = 0xFFFFFFB4;  // -0.25
        uint32_t i8e = 0xFFFFFF38;   // 0.5
        uint32_t i8en = 0xFFFFFFB8;  // -0.5
        uint32_t i8f = 0xFFFFFF56;   // 100.12345
        uint32_t i8fn = 0xFFFFFFD6;  // -100.12345

        uint32_t ia8a = 0xFFFFFF45;   // 3.14
        uint32_t ia8an = 0xFFFFFFC5;  // -3.14
        uint32_t ia8b = 0xFFFFFF3D;   // 1.618
        uint32_t ia8bn = 0xFFFFFFBD;  // -1.618
        uint32_t ia8c = 0xFFFFFF42;   // 2.39
        uint32_t ia8cn = 0xFFFFFFC2;  // -2.39
        uint32_t ia8d = 0xFFFFFF28;   // 0.25
        uint32_t ia8dn = 0xFFFFFFA8;  // -0.25
        uint32_t ia8e = 0xFFFFFF30;   // 0.5
        uint32_t ia8en = 0xFFFFFFB0;  // -0.5
        uint32_t ia8f = 0xFFFFFF6D;   // 100.12345
        uint32_t ia8fn = 0xFFFFFFED;  // -100.12345

        // VALUE A
        fvalue = 3.14;
        fvalue_negative = -3.14;
        // normal formates
        write_csr(2048, 0);
        asm volatile(
            "fmv.h.x ft2, %0\n"
            "fmv.h.x ft3, %1\n"
            : "+r"(i16a), "+r"(i16an));  // fp16 values
        asm volatile(
            "fmv.b.x ft4, %0\n"
            "fmv.b.x ft5, %1\n"
            : "+r"(i8a), "+r"(i8an));  // fp8 values

        // D -> H
        asm volatile(
            "fcvt.h.d ft6, %2\n"
            "fcvt.h.d ft7, %3\n"
            "feq.h %0, ft6, ft2\n"
            "feq.h %1, ft7, ft3\n"
            : "+r"(res_cvt0), "+r"(res_cvt1), "+f"(fvalue),
              "+f"(fvalue_negative));
        errs += (res_cvt0 != 0x1);
        errs += (res_cvt1 != 0x1);

        // D -> B
        asm volatile(
            "fcvt.b.d ft6, %2\n"
            "fcvt.b.d ft7, %3\n"
            "feq.b %0, ft6, ft4\n"
            "feq.b %1, ft7, ft5\n"
            : "+r"(res_cvt0), "+r"(res_cvt1), "+f"(fvalue),
              "+f"(fvalue_negative));
        errs += (res_cvt0 != 0x1);
        errs += (res_cvt1 != 0x1);

        // alternative formates
        write_csr(2048, 3);
        asm volatile(
            "fmv.ah.x ft2, %0\n"
            "fmv.ah.x ft3, %1\n"
            : "+r"(ia16a), "+r"(ia16an));  // fp16alt values
        asm volatile(
            "fmv.ab.x ft4, %0\n"
            "fmv.ab.x ft5, %1\n"
            : "+r"(ia8a), "+r"(ia8an));  // fp8alt values

        // D -> AH
        asm volatile(
            "fcvt.ah.d ft6, %2\n"
            "fcvt.ah.d ft7, %3\n"
            "feq.ah %0, ft6, ft2\n"
            "feq.ah %1, ft7, ft3\n"
            : "+r"(res_cvt0), "+r"(res_cvt1), "+f"(fvalue),
              "+f"(fvalue_negative));
        errs += (res_cvt0 != 0x1);
        errs += (res_cvt1 != 0x1);

        // D -> AB
        asm volatile(
            "fcvt.ab.d ft6, %2\n"
            "fcvt.ab.d ft7, %3\n"
            "feq.ab %0, ft6, ft4\n"
            "feq.ab %1, ft7, ft5\n"
            : "+r"(res_cvt0), "+r"(res_cvt1), "+f"(fvalue),
              "+f"(fvalue_negative));
        errs += (res_cvt0 != 0x1);
        errs += (res_cvt1 != 0x1);

        // VALUE B
        fvalue = 1.618;
        fvalue_negative = -1.618;
        // normal formates
        write_csr(2048, 0);
        asm volatile(
            "fmv.h.x ft2, %0\n"
            "fmv.h.x ft3, %1\n"
            : "+r"(i16b), "+r"(i16bn));  // fp16 values
        asm volatile(
            "fmv.b.x ft4, %0\n"
            "fmv.b.x ft5, %1\n"
            : "+r"(i8b), "+r"(i8bn));  // fp8 values

        // D -> H
        asm volatile(
            "fcvt.h.d ft6, %2\n"
            "fcvt.h.d ft7, %3\n"
            "feq.h %0, ft6, ft2\n"
            "feq.h %1, ft7, ft3\n"
            : "+r"(res_cvt0), "+r"(res_cvt1), "+f"(fvalue),
              "+f"(fvalue_negative));
        errs += (res_cvt0 != 0x1);
        errs += (res_cvt1 != 0x1);

        // D -> B
        asm volatile(
            "fcvt.b.d ft6, %2\n"
            "fcvt.b.d ft7, %3\n"
            "feq.b %0, ft6, ft4\n"
            "feq.b %1, ft7, ft5\n"
            : "+r"(res_cvt0), "+r"(res_cvt1), "+f"(fvalue),
              "+f"(fvalue_negative));
        errs += (res_cvt0 != 0x1);
        errs += (res_cvt1 != 0x1);

        // alternative formates
        write_csr(2048, 3);
        asm volatile(
            "fmv.ah.x ft2, %0\n"
            "fmv.ah.x ft3, %1\n"
            : "+r"(ia16b), "+r"(ia16bn));  // fp16alt values
        asm volatile(
            "fmv.ab.x ft4, %0\n"
            "fmv.ab.x ft5, %1\n"
            : "+r"(ia8b), "+r"(ia8bn));  // fp8alt values

        // D -> AH
        asm volatile(
            "fcvt.ah.d ft6, %2\n"
            "fcvt.ah.d ft7, %3\n"
            "feq.ah %0, ft6, ft2\n"
            "feq.ah %1, ft7, ft3\n"
            : "+r"(res_cvt0), "+r"(res_cvt1), "+f"(fvalue),
              "+f"(fvalue_negative));
        errs += (res_cvt0 != 0x1);
        errs += (res_cvt1 != 0x1);

        // D -> AB
        asm volatile(
            "fcvt.ab.d ft6, %2\n"
            "fcvt.ab.d ft7, %3\n"
            "feq.ab %0, ft6, ft4\n"
            "feq.ab %1, ft7, ft5\n"
            : "+r"(res_cvt0), "+r"(res_cvt1), "+f"(fvalue),
              "+f"(fvalue_negative));
        errs += (res_cvt0 != 0x1);
        errs += (res_cvt1 != 0x1);

        // VALUE C
        fvalue = 2.39;
        fvalue_negative = -2.39;
        // normal formates
        write_csr(2048, 0);
        asm volatile(
            "fmv.h.x ft2, %0\n"
            "fmv.h.x ft3, %1\n"
            : "+r"(i16c), "+r"(i16cn));  // fp16 values
        asm volatile(
            "fmv.b.x ft4, %0\n"
            "fmv.b.x ft5, %1\n"
            : "+r"(i8c), "+r"(i8cn));  // fp8 values

        // D -> H
        asm volatile(
            "fcvt.h.d ft6, %2\n"
            "fcvt.h.d ft7, %3\n"
            "feq.h %0, ft6, ft2\n"
            "feq.h %1, ft7, ft3\n"
            : "+r"(res_cvt0), "+r"(res_cvt1), "+f"(fvalue),
              "+f"(fvalue_negative));
        errs += (res_cvt0 != 0x1);
        errs += (res_cvt1 != 0x1);

        // D -> B
        asm volatile(
            "fcvt.b.d ft6, %2\n"
            "fcvt.b.d ft7, %3\n"
            "feq.b %0, ft6, ft4\n"
            "feq.b %1, ft7, ft5\n"
            : "+r"(res_cvt0), "+r"(res_cvt1), "+f"(fvalue),
              "+f"(fvalue_negative));
        errs += (res_cvt0 != 0x1);
        errs += (res_cvt1 != 0x1);

        // alternative formates
        write_csr(2048, 3);
        asm volatile(
            "fmv.ah.x ft2, %0\n"
            "fmv.ah.x ft3, %1\n"
            : "+r"(ia16c), "+r"(ia16cn));  // fp16alt values
        asm volatile(
            "fmv.ab.x ft4, %0\n"
            "fmv.ab.x ft5, %1\n"
            : "+r"(ia8c), "+r"(ia8cn));  // fp8alt values

        // D -> AH
        asm volatile(
            "fcvt.ah.d ft6, %2\n"
            "fcvt.ah.d ft7, %3\n"
            "feq.ah %0, ft6, ft2\n"
            "feq.ah %1, ft7, ft3\n"
            : "+r"(res_cvt0), "+r"(res_cvt1), "+f"(fvalue),
              "+f"(fvalue_negative));
        errs += (res_cvt0 != 0x1);
        errs += (res_cvt1 != 0x1);

        // D -> AB
        asm volatile(
            "fcvt.ab.d ft6, %2\n"
            "fcvt.ab.d ft7, %3\n"
            "feq.ab %0, ft6, ft4\n"
            "feq.ab %1, ft7, ft5\n"
            : "+r"(res_cvt0), "+r"(res_cvt1), "+f"(fvalue),
              "+f"(fvalue_negative));
        errs += (res_cvt0 != 0x1);
        errs += (res_cvt1 != 0x1);

        // VALUE D
        fvalue = 0.250;
        fvalue_negative = -0.250;
        // normal formates
        write_csr(2048, 0);
        asm volatile(
            "fmv.h.x ft2, %0\n"
            "fmv.h.x ft3, %1\n"
            : "+r"(i16d), "+r"(i16dn));  // fp16 values
        asm volatile(
            "fmv.b.x ft4, %0\n"
            "fmv.b.x ft5, %1\n"
            : "+r"(i8d), "+r"(i8dn));  // fp8 values

        // D -> H
        asm volatile(
            "fcvt.h.d ft6, %2\n"
            "fcvt.h.d ft7, %3\n"
            "feq.h %0, ft6, ft2\n"
            "feq.h %1, ft7, ft3\n"
            : "+r"(res_cvt0), "+r"(res_cvt1), "+f"(fvalue),
              "+f"(fvalue_negative));
        errs += (res_cvt0 != 0x1);
        errs += (res_cvt1 != 0x1);

        // D -> B
        asm volatile(
            "fcvt.b.d ft6, %2\n"
            "fcvt.b.d ft7, %3\n"
            "feq.b %0, ft6, ft4\n"
            "feq.b %1, ft7, ft5\n"
            : "+r"(res_cvt0), "+r"(res_cvt1), "+f"(fvalue),
              "+f"(fvalue_negative));
        errs += (res_cvt0 != 0x1);
        errs += (res_cvt1 != 0x1);

        // alternative formates
        write_csr(2048, 3);
        asm volatile(
            "fmv.ah.x ft2, %0\n"
            "fmv.ah.x ft3, %1\n"
            : "+r"(ia16d), "+r"(ia16dn));  // fp16alt values
        asm volatile(
            "fmv.ab.x ft4, %0\n"
            "fmv.ab.x ft5, %1\n"
            : "+r"(ia8d), "+r"(ia8dn));  // fp8alt values

        // D -> AH
        asm volatile(
            "fcvt.ah.d ft6, %2\n"
            "fcvt.ah.d ft7, %3\n"
            "feq.ah %0, ft6, ft2\n"
            "feq.ah %1, ft7, ft3\n"
            : "+r"(res_cvt0), "+r"(res_cvt1), "+f"(fvalue),
              "+f"(fvalue_negative));
        errs += (res_cvt0 != 0x1);
        errs += (res_cvt1 != 0x1);

        // D -> AB
        asm volatile(
            "fcvt.ab.d ft6, %2\n"
            "fcvt.ab.d ft7, %3\n"
            "feq.ab %0, ft6, ft4\n"
            "feq.ab %1, ft7, ft5\n"
            : "+r"(res_cvt0), "+r"(res_cvt1), "+f"(fvalue),
              "+f"(fvalue_negative));
        errs += (res_cvt0 != 0x1);
        errs += (res_cvt1 != 0x1);

        // VALUE E
        fvalue = 0.5;
        fvalue_negative = -0.5;
        // normal formates
        write_csr(2048, 0);
        asm volatile(
            "fmv.h.x ft2, %0\n"
            "fmv.h.x ft3, %1\n"
            : "+r"(i16e), "+r"(i16en));  // fp16 values
        asm volatile(
            "fmv.b.x ft4, %0\n"
            "fmv.b.x ft5, %1\n"
            : "+r"(i8e), "+r"(i8en));  // fp8 values

        // D -> H
        asm volatile(
            "fcvt.h.d ft6, %2\n"
            "fcvt.h.d ft7, %3\n"
            "feq.h %0, ft6, ft2\n"
            "feq.h %1, ft7, ft3\n"
            : "+r"(res_cvt0), "+r"(res_cvt1), "+f"(fvalue),
              "+f"(fvalue_negative));
        errs += (res_cvt0 != 0x1);
        errs += (res_cvt1 != 0x1);

        // D -> B
        asm volatile(
            "fcvt.b.d ft6, %2\n"
            "fcvt.b.d ft7, %3\n"
            "feq.b %0, ft6, ft4\n"
            "feq.b %1, ft7, ft5\n"
            : "+r"(res_cvt0), "+r"(res_cvt1), "+f"(fvalue),
              "+f"(fvalue_negative));
        errs += (res_cvt0 != 0x1);
        errs += (res_cvt1 != 0x1);

        // alternative formates
        write_csr(2048, 3);
        asm volatile(
            "fmv.ah.x ft2, %0\n"
            "fmv.ah.x ft3, %1\n"
            : "+r"(ia16e), "+r"(ia16en));  // fp16alt values
        asm volatile(
            "fmv.ab.x ft4, %0\n"
            "fmv.ab.x ft5, %1\n"
            : "+r"(ia8e), "+r"(ia8en));  // fp8alt values

        // D -> AH
        asm volatile(
            "fcvt.ah.d ft6, %2\n"
            "fcvt.ah.d ft7, %3\n"
            "feq.ah %0, ft6, ft2\n"
            "feq.ah %1, ft7, ft3\n"
            : "+r"(res_cvt0), "+r"(res_cvt1), "+f"(fvalue),
              "+f"(fvalue_negative));
        errs += (res_cvt0 != 0x1);
        errs += (res_cvt1 != 0x1);

        // D -> AB
        asm volatile(
            "fcvt.ab.d ft6, %2\n"
            "fcvt.ab.d ft7, %3\n"
            "feq.ab %0, ft6, ft4\n"
            "feq.ab %1, ft7, ft5\n"
            : "+r"(res_cvt0), "+r"(res_cvt1), "+f"(fvalue),
              "+f"(fvalue_negative));
        errs += (res_cvt0 != 0x1);
        errs += (res_cvt1 != 0x1);

        // VALUE F
        fvalue = 100.12345;
        fvalue_negative = -100.12345;
        // normal formates
        write_csr(2048, 0);
        asm volatile(
            "fmv.h.x ft2, %0\n"
            "fmv.h.x ft3, %1\n"
            : "+r"(i16f), "+r"(i16fn));  // fp16 values
        asm volatile(
            "fmv.b.x ft4, %0\n"
            "fmv.b.x ft5, %1\n"
            : "+r"(i8f), "+r"(i8fn));  // fp8 values

        // D -> H
        asm volatile(
            "fcvt.h.d ft6, %2\n"
            "fcvt.h.d ft7, %3\n"
            "feq.h %0, ft6, ft2\n"
            "feq.h %1, ft7, ft3\n"
            : "+r"(res_cvt0), "+r"(res_cvt1), "+f"(fvalue),
              "+f"(fvalue_negative));
        errs += (res_cvt0 != 0x1);
        errs += (res_cvt1 != 0x1);

        // D -> B
        asm volatile(
            "fcvt.b.d ft6, %2\n"
            "fcvt.b.d ft7, %3\n"
            "feq.b %0, ft6, ft4\n"
            "feq.b %1, ft7, ft5\n"
            : "+r"(res_cvt0), "+r"(res_cvt1), "+f"(fvalue),
              "+f"(fvalue_negative));
        errs += (res_cvt0 != 0x1);
        errs += (res_cvt1 != 0x1);

        // alternative formates
        write_csr(2048, 3);
        asm volatile(
            "fmv.ah.x ft2, %0\n"
            "fmv.ah.x ft3, %1\n"
            : "+r"(ia16f), "+r"(ia16fn));  // fp16alt values
        asm volatile(
            "fmv.ab.x ft4, %0\n"
            "fmv.ab.x ft5, %1\n"
            : "+r"(ia8f), "+r"(ia8fn));  // fp8alt values

        // D -> AH
        asm volatile(
            "fcvt.ah.d ft6, %2\n"
            "fcvt.ah.d ft7, %3\n"
            "feq.ah %0, ft6, ft2\n"
            "feq.ah %1, ft7, ft3\n"
            : "+r"(res_cvt0), "+r"(res_cvt1), "+f"(fvalue),
              "+f"(fvalue_negative));
        errs += (res_cvt0 != 0x1);
        errs += (res_cvt1 != 0x1);

        // D -> AB
        asm volatile(
            "fcvt.ab.d ft6, %2\n"
            "fcvt.ab.d ft7, %3\n"
            "feq.ab %0, ft6, ft4\n"
            "feq.ab %1, ft7, ft5\n"
            : "+r"(res_cvt0), "+r"(res_cvt1), "+f"(fvalue),
              "+f"(fvalue_negative));
        errs += (res_cvt0 != 0x1);
        errs += (res_cvt1 != 0x1);
    }

    return 0;
}
