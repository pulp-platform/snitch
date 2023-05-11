// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

static inline void snrt_crt0_callback3() {
    _snrt_cluster_hw_barrier = cluster_hw_barrier_addr(snrt_cluster_idx());
}

#define SNRT_INIT_TLS
#define SNRT_INIT_BSS
#define SNRT_INIT_CLS
#define SNRT_CRT0_CALLBACK3
#define SNRT_INIT_LIBS
#define SNRT_CRT0_PRE_BARRIER
#define SNRT_INVOKE_MAIN
#define SNRT_CRT0_POST_BARRIER

#include "start.c"
