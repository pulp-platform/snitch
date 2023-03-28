// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#define SNRT_INIT_TLS
#define SNRT_INIT_BSS
#define SNRT_INIT_CLS
#define SNRT_INIT_LIBS
#define SNRT_CRT0_PRE_BARRIER
#define SNRT_INVOKE_MAIN
#define SNRT_CRT0_POST_BARRIER
#define SNRT_CRT0_CALLBACK8

static inline void snrt_crt0_callback8(int exit_code) {
    volatile uint32_t *scratch_reg = (volatile uint32_t *)0x02000014;

    if (snrt_global_core_idx() == 0) *(scratch_reg) = (exit_code << 1) | 1;
}

#include "start.c"
