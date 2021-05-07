// Copyright 2021 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "uart.h"

int main() {
    init_uart(50000000, 115200);
    print_uart("Hello World!\r\n");

    __asm__ volatile(
        "csrr a0, mhartid;"
        "la a1, device_tree;"
        "ebreak;");

    while (1) {
        // do nothing
    }
}

void handle_trap(void) {
    // print_uart("trap\r\n");
}