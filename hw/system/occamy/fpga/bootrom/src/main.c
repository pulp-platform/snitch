// Copyright 2021 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "uart.h"
#define SPL_SRC 0x1001000UL
#define SPL_SIZE 65536
#define SPL_DEST 0x70000000UL

extern uint32_t __spl_start;
extern uint32_t __spl_end;
uint64_t __spl_src_start = (uint64_t)(&__spl_start);
uint64_t __spl_src_end = (uint64_t)(&__spl_end);

// Boot modes.
enum boot_mode_t { JTAG, SPL_ROM };

int main() {
    init_uart(50000000, 115200);

    print_uart("\r\nOccamy VCU128 bootrom ");
    print_uart(__DATE__);
    print_uart(" ");
    print_uart(__TIME__);
    print_uart(" ");
    print_uart(GIT_SHA);
    print_uart("\r\n");

    // Hardcode boot mode for now. TODO(niwis): derive e.g. from GPIO.
    enum boot_mode_t boot_mode = SPL_ROM;

    switch (boot_mode) {
        case JTAG:
            __asm__ volatile(
                "csrr a0, mhartid;"
                "la a1, device_tree;"
                "ebreak;");
            break;
        case SPL_ROM:
            print_uart("Loading U-Boot SPL from ROM ");
            for (uint32_t i = 0; i < (__spl_src_end - __spl_src_start); i += 1) {
                if(i % 1024 == 0)
                  print_uart(".");
                *(uint8_t *)(SPL_DEST + i) = *(uint8_t *)(__spl_src_start + i);
            }
            print_uart("done\r\n");
            __asm__ volatile(
                "fence.i;"
                "csrr a0, mhartid;"
                "la a1, device_tree;"
                "jr %0;" ::"r"(SPL_DEST));
            break;
        default:
            break;
    }

    print_uart("halt\r\n");
    while (1) {
        // do nothing
    }
}

void handle_trap(void) {
    // print_uart("trap\r\n");
}
