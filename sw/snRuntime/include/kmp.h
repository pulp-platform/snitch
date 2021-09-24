// Copyright 2021 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#pragma once

#include "interface.h"
#include "snrt.h"

typedef void (*kmpc_micro)(kmp_int32 *global_tid, kmp_int32 *bound_tid, ...);

extern _kmp_ptr32 *kmpc_args;

////////////////////////////////////////////////////////////////////////////////
// debug
////////////////////////////////////////////////////////////////////////////////

#ifdef KMP_DEBUG_LEVEL
#include "encoding.h"
#include "printf.h"
#define _KMP_PRINTF(...)             \
    if (1) {                         \
        printf("[kmc] "__VA_ARGS__); \
    }
#define KMP_PRINTF(d, ...)        \
    if (KMP_DEBUG_LEVEL >= d) {   \
        _KMP_PRINTF(__VA_ARGS__); \
    }
#else
#define KMP_PRINTF(d, ...)
#endif
