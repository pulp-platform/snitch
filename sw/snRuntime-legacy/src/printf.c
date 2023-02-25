// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include "snrt.h"

void snrt_putchar(char character);

// Use snrt_putchar for printf
#define _putchar snrt_putchar

/// vendor printf settings

#if defined(__TOOLCHAIN_GCC__)
// the gcc toolchain doesn't support this
#define PRINTF_DISABLE_SUPPORT_FLOAT
#endif

// Include the vendorized tiny printf implementation.
#include "../vendor/printf.c"
