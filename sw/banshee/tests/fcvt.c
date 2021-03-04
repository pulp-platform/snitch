// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <stdint.h>

int main() {
    float f32 = 3.14;
    double f64 = 1.618;
    uint32_t ui32 = 42;
    int32_t si32 = -42;
    uint64_t ui64 = 42;
    int64_t si64 = -42;

    unsigned int errs = 0;

    // fcvt.w.s
    errs += (int)f32 != 3;
    // fcvt.w.d
    errs += (int)f64 != 1;
    // fcvt.w.s
    errs += (int)(-f32) != -3;
    // fcvt.w.d
    errs += (int)(-f64) != -1;
    // fcvt.wu.s
    errs += (unsigned int)f32 != 3;
    // fcvt.wu.d
    errs += (unsigned int)f64 != 1;
    // fcvt.d.w
    errs += (double)si32 != (double)-42.0;
    // fcvt.d.wu
    errs += (double)ui32 != (double)42.0;
    // fcvt.s.w
    errs += (float)si32 != (float)-42.0;
    // fcvt.s.wu
    errs += (float)ui32 != (float)42.0;

    // fcvt.l.s
    errs += (int64_t)f32 != (int64_t)3;
    // fcvt.lu.s
    errs += (uint64_t)f32 != (uint64_t)3;
    // fcvt.s.l
    errs += (float)si64 != (float)-42.0;
    // fcvt.s.lu
    errs += (float)ui64 != (float)42.0;

    // fcvt.l.d
    errs += (int64_t)f64 != (int64_t)1;
    // fcvt.lu.d
    errs += (uint64_t)f64 != (uint64_t)1;
    // fcvt.d.l
    errs += (double)si64 != (double)-42.0;
    // fcvt.d.lu
    errs += (double)ui64 != (double)42.0;

    // fcvt.d.s
    errs += (uint32_t)(double)f32 != 3;
    // fcvt.s.d
    errs += (float)f64 != (float)1.618;

    return errs;
}
