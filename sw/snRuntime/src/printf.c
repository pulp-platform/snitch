// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
#include "snrt.h"

// Provide an implementation for putchar.
void snrt_putchar(char character) {
    *(volatile uint32_t *)0xF00B8000 = character;
}

// Generator symbols with the proper names.
#define printf_ printf
#define sprintf_ sprintf
#define snprintf_ snprintf
#define vsnprintf_ vsnprintf
#define vprintf_ vprintf
#define _putchar snrt_putchar

// Include the vendorized tiny printf implementation.
#define _PRINTF_H_
#define PRINTF_DISABLE_SUPPORT_FLOAT
#include <stdarg.h>
#include <stddef.h>

#include "../vendor/printf.c"
