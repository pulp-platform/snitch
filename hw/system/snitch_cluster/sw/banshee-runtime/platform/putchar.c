// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// Provide an implementation for putchar.
void snrt_putchar(char character) {
    *(volatile uint32_t *)0xF00B8000 = character;
}
