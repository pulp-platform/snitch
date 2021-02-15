// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include "snrt.h"

/// Enable SSR.
void snrt_ssr_enable() { asm volatile("csrsi 0x7C0, 1"); }

/// Disable SSR.
void snrt_ssr_disable() { asm volatile("csrci 0x7C0, 1"); }

/// Synchronize the integer and float pipelines.
void snrt_fpu_fence() { asm volatile("fmv.x.w zero, fa0"); }
