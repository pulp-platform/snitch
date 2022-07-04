// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include "snrt.h"

/// Enable SSR.
void snrt_ssr_enable() {
#ifdef __TOOLCHAIN_LLVM__
    __builtin_ssr_enable();
#else
    asm volatile("csrsi 0x7C0, 1");
#endif
}

/// Disable SSR.
void snrt_ssr_disable() {
#ifdef __TOOLCHAIN_LLVM__
    __builtin_ssr_disable();
#else
    asm volatile("csrci 0x7C0, 1");
#endif
}

/// Synchronize the integer and float pipelines.
void snrt_fpu_fence() {
    unsigned tmp;
    asm volatile(
        "fmv.x.w %0, fa0\n"
        "mv      %0, %0"
        : "+r"(tmp)::);
}
