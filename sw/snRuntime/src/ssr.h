// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/// Synchronize the integer and float pipelines.
inline void snrt_fpu_fence() {
    unsigned tmp;
    asm volatile(
        "fmv.x.w %0, fa0\n"
        "mv      %0, %0"
        : "+r"(tmp)::"memory");
}
