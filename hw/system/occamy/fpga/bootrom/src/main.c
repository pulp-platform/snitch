// Copyright 2021 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "uart.h"
#define SPL_SRC 0x1001000UL
#define SPL_SIZE 65536
#define SPL_DEST 0x70000000UL

#define BIG_ENDIAN(n) ( ((n >> 24)&0xFFu ) | (((n >> 16)&0xFFu) << 8) | (((n >> 8)&0xFFu) << 16) | ((n&0xFFu) << 24 ) )
// + (((n) >> 16)&0xFFu) << 8 + (((n) >>  8)&0xFFu) << 16 + ((n)&0xFFu ) << 24

extern uint32_t __spl_start;
extern uint32_t __spl_end;
uint64_t __spl_src_start = (uint64_t)(&__spl_start);
uint64_t __spl_src_end = (uint64_t)(&__spl_end);

extern uint32_t device_tree;
uint64_t __dtb_start = (uint64_t)(&device_tree);

// Boot modes.
enum boot_mode_t { JTAG, SPL_ROM, PCIE };

int main() {
    init_uart(25000000, 115200);

    print_uart("\r\nOccamy VCU128 bootrom ");
    print_uart(GIT_SHA);
    print_uart("\r\n");

    // Hardcode boot mode for now. TODO(niwis): derive e.g. from GPIO.
    enum boot_mode_t boot_mode = PCIE;

    switch (boot_mode) {
        case JTAG:
            print_uart("\r\nJTAG : Executing ebreak;");
            __asm__ volatile(
                "csrr a0, mhartid;"
                "la a1, device_tree;"
                "ebreak;");
            break;
        case SPL_ROM:
            print_uart("\r\nSPL_ROM : Loading U-Boot SPL from ROM (0x");
            print_uart_addr(__spl_src_end - __spl_src_start);
            print_uart(") bytes");
            for (uint32_t i = 0; i < (__spl_src_end - __spl_src_start);
                 i += 1) {
                // if (i % 1024 == 0) print_uart(".");
                *(uint8_t *)(SPL_DEST + i) = *(uint8_t *)(__spl_src_start + i);
            }
            print_uart("\r\ndone");
            __asm__ volatile(
                "fence.i;"
                "csrr a0, mhartid;"
                "la a1, device_tree;"
                "jr %0;" ::"r"(SPL_DEST));
            break;
        case PCIE:
            print_uart("\r\nPCIE : COPYING DTB");
            print_uart("\r\nChecking DTB magic (");
            uint32_t magic = BIG_ENDIAN(*(uint32_t *)(__dtb_start));
            print_uart_int(magic);

            if (magic != 0xd00dfeed) {
                print_uart(")\r\nERROR : Incorrect DTB magic");
                goto halt;
            }
            print_uart(")\r\nOK");

            uint32_t totalsize = BIG_ENDIAN(*((uint32_t *)(__dtb_start) + 1));
            print_uart("\r\nTotalsize = ");
            print_uart_int(totalsize);

            // DTB is copyied at SPM+1

            print_uart("\r\nCopying DTB at ");
            print_uart_addr(SPL_DEST + 1);
            for(int i = 0; i < totalsize; i++)
                *(uint8_t *)(SPL_DEST + 1 + i) = *(uint8_t *)(__dtb_start + i);

            __asm__ volatile("fence.i;");

            // MAGIC is repeated at SPM+0 to indicate end of transfert
            *(uint32_t *)(SPL_DEST) = magic;

            print_uart("\r\nDone");

            break;
        default:
            break;
    }
halt:
    print_uart("\r\nhalt");
    while (1) {
        // do nothing
    }
}

void handle_trap(void) {
    // print_uart("trap\r\n");
}
