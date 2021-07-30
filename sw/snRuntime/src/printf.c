// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include "snrt.h"

void snrt_putchar(char character);

// Use snrt_putchar for printf
#define _putchar snrt_putchar

// vendor printf settings
// #define PRINTF_DISABLE_SUPPORT_FLOAT
// #define PRINTF_DISABLE_SUPPORT_EXPONENTIAL

// Include the vendorized tiny printf implementation.
#include "../vendor/printf.c"
