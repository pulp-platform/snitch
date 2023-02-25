// Copyright 2021 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#pragma once

#include <stdint.h>

#include "occamy_base_addr.h"

#define UART_RBR UART_BASE_ADDR + 0
#define UART_THR UART_BASE_ADDR + 0
#define UART_INTERRUPT_ENABLE UART_BASE_ADDR + 4
#define UART_INTERRUPT_IDENT UART_BASE_ADDR + 8
#define UART_FIFO_CONTROL UART_BASE_ADDR + 8
#define UART_LINE_CONTROL UART_BASE_ADDR + 12
#define UART_MODEM_CONTROL UART_BASE_ADDR + 16
#define UART_LINE_STATUS UART_BASE_ADDR + 20
#define UART_MODEM_STATUS UART_BASE_ADDR + 24
#define UART_DLAB_LSB UART_BASE_ADDR + 0
#define UART_DLAB_MSB UART_BASE_ADDR + 4

inline static void write_reg_u8(uintptr_t addr, uint8_t value) {
    volatile uint8_t *loc_addr = (volatile uint8_t *)addr;
    *loc_addr = value;
}

inline static uint8_t read_reg_u8(uintptr_t addr) {
    return *(volatile uint8_t *)addr;
}

inline static int is_transmit_empty() {
    return read_reg_u8(UART_LINE_STATUS) & 0x20;
}

inline static int is_transmit_done() {
    return read_reg_u8(UART_LINE_STATUS) & 0x40;
}

inline static void write_serial(char a) {
    while (is_transmit_empty() == 0) {
    };

    write_reg_u8(UART_THR, a);
}

inline static void init_uart(uint32_t freq, uint32_t baud) {
    uint32_t divisor = freq / (baud << 4);

    write_reg_u8(UART_INTERRUPT_ENABLE, 0x00);  // Disable all interrupts
    write_reg_u8(UART_LINE_CONTROL,
                 0x80);  // Enable DLAB (set baud rate divisor)
    write_reg_u8(UART_DLAB_LSB, divisor);                // divisor (lo byte)
    write_reg_u8(UART_DLAB_MSB, (divisor >> 8) & 0xFF);  // divisor (hi byte)
    write_reg_u8(UART_LINE_CONTROL, 0x03);  // 8 bits, no parity, one stop bit
    write_reg_u8(UART_FIFO_CONTROL,
                 0xC7);  // Enable FIFO, clear them, with 14-byte threshold
    write_reg_u8(UART_MODEM_CONTROL, 0x20);  // Autoflow mode
}

inline static void print_uart(const char *str) {
    const char *cur = &str[0];
    while (*cur != '\0') {
        write_serial((uint8_t)*cur);
        ++cur;
    }
    while (!is_transmit_done())
        ;
}

static uint8_t bin_to_hex_table[16] = {'0', '1', '2', '3', '4', '5', '6', '7',
                                       '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'};

inline static void bin_to_hex(uint8_t inp, uint8_t res[2]) {
    res[1] = bin_to_hex_table[inp & 0xf];
    res[0] = bin_to_hex_table[(inp >> 4) & 0xf];
    return;
}

inline static void print_uart_int(uint32_t addr) {
    int i;
    for (i = 3; i > -1; i--) {
        uint8_t cur = (addr >> (i * 8)) & 0xff;
        uint8_t hex[2];
        bin_to_hex(cur, hex);
        write_serial(hex[0]);
        write_serial(hex[1]);
    }
}

inline static void print_uart_addr(uint64_t addr) {
    int i;
    for (i = 7; i > -1; i--) {
        uint8_t cur = (addr >> (i * 8)) & 0xff;
        uint8_t hex[2];
        bin_to_hex(cur, hex);
        write_serial(hex[0]);
        write_serial(hex[1]);
    }
}

inline static void print_uart_byte(uint8_t byte) {
    uint8_t hex[2];
    bin_to_hex(byte, hex);
    write_serial(hex[0]);
    write_serial(hex[1]);
}
