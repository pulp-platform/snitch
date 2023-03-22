// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#ifdef __cplusplus
extern "C" {
#endif

#if defined(__SNRT_USE_TRACE)

#include "printf.h"

#define snrt_msg(fmt, x...)                                             \
    do {                                                                \
        printf("[\033[35mSNRT(%d,%d)\033[0m] " fmt, snrt_cluster_idx(), \
               snrt_cluster_core_idx(), ##x);                           \
    } while (0)

#define SNRT_TRACE_INIT 0
#define SNRT_TRACE_ALLOC 1

#define snrt_trace(trace, x...) \
    do {                        \
        snrt_msg(x);            \
    } while (0)

#else

#define snrt_trace(x...) \
    do {                 \
    } while (0)

#endif  // defined(__SNRT_USE_TRACE)

#ifdef __cplusplus
}
#endif
