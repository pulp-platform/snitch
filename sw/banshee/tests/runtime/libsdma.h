// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <stdint.h>

// 1D transfer
inline volatile static uint32_t sdma__start_oned(volatile uint32_t src_low,
                                                 volatile uint32_t src_high,
                                                 volatile uint32_t dst_low,
                                                 volatile uint32_t dst_high,
                                                 volatile uint32_t num_bytes) {
    volatile register uint32_t reg_src_high asm("s2");   // 19
    volatile register uint32_t reg_src_low asm("s3");    // 18
    volatile register uint32_t reg_dst_high asm("s4");   // 21
    volatile register uint32_t reg_dst_low asm("s5");    // 20
    volatile register uint32_t reg_tf_id asm("s6");      // 22
    volatile register uint32_t reg_num_bytes asm("s7");  // 23

    reg_src_low = src_low;
    reg_src_high = src_high;
    reg_dst_low = dst_low;
    reg_dst_high = dst_high;
    reg_num_bytes = num_bytes;

    // set source
    asm volatile(
        ".word (0b0000000 << 25) | \
               (     (18) << 20) | \
               (     (19) << 15) | \
               (    0b000 << 12) | \
               (0b0101011 <<  0)   \n"
        :
        : "r"(reg_src_high), "r"(reg_src_low));

    // set dest
    asm volatile(
        ".word (0b0000001 << 25) | \
               (     (20) << 20) | \
               (     (21) << 15) | \
               (    0b000 << 12) | \
               (0b0101011 <<  0)   \n"
        :
        : "r"(reg_dst_high), "r"(reg_dst_low));

    // start immediate
    asm volatile(
        ".word (0b0010100 << 25) | \
               (     (23) << 15) | \
               (    0b001 << 12) | \
               (     (22) <<  7) | \
               (0b0101011 <<  0)   \n"
        : "=r"(reg_tf_id)
        : "r"(reg_num_bytes));

    return reg_tf_id;
}

// 2D transfer
inline volatile static uint32_t sdma__start_twod(
    volatile uint32_t src_low, volatile uint32_t src_high,
    volatile uint32_t dst_low, volatile uint32_t dst_high,
    volatile uint32_t num_bytes, volatile uint32_t src_strd,
    volatile uint32_t dst_strd, volatile uint32_t num_reps) {
    volatile register uint32_t reg_src_high asm("s2");   // 19
    volatile register uint32_t reg_src_low asm("s3");    // 18
    volatile register uint32_t reg_dst_high asm("s4");   // 21
    volatile register uint32_t reg_dst_low asm("s5");    // 20
    volatile register uint32_t reg_tf_id asm("s6");      // 22
    volatile register uint32_t reg_num_bytes asm("s7");  // 23
    volatile register uint32_t reg_src_strd asm("s8");   // 24
    volatile register uint32_t reg_dst_strd asm("s9");   // 25
    volatile register uint32_t reg_num_reps asm("s10");  // 26

    reg_src_low = src_low;
    reg_src_high = src_high;
    reg_dst_low = dst_low;
    reg_dst_high = dst_high;
    reg_num_bytes = num_bytes;
    reg_src_strd = src_strd;
    reg_dst_strd = dst_strd;
    reg_num_reps = num_reps;

    // set source
    asm volatile(
        ".word (0b0000000 << 25) | \
               (     (18) << 20) | \
               (     (19) << 15) | \
               (    0b000 << 12) | \
               (0b0101011 <<  0)   \n"
        :
        : "r"(reg_src_high), "r"(reg_src_low));

    // set dest
    asm volatile(
        ".word (0b0000001 << 25) | \
               (     (20) << 20) | \
               (     (21) << 15) | \
               (    0b000 << 12) | \
               (0b0101011 <<  0)   \n"
        :
        : "r"(reg_dst_high), "r"(reg_dst_low));

    // strides
    asm volatile(
        ".word (0b0000101 << 25) | \
               (     (25) << 20) | \
               (     (24) << 15) | \
               (    0b000 << 12) | \
               (0b0101011 <<  0)   \n"
        :
        : "r"(reg_dst_strd), "r"(reg_src_strd));

    // num repetitions
    asm volatile(
        ".word (0b0000110 << 25) | \
               (     (26) << 15) | \
               (    0b000 << 12) | \
               (0b0101011 <<  0)   \n"
        :
        : "r"(reg_num_reps));

    // start immediate
    asm volatile(
        ".word (0b0010110 << 25) | \
               (     (23) << 15) | \
               (    0b001 << 12) | \
               (     (22) <<  7) | \
               (0b0101011 <<  0)   \n"
        : "=r"(reg_tf_id)
        : "r"(reg_num_bytes));

    return reg_tf_id;
}

// poll until DMA is idle
static inline void sdma__wait_for_idle() {
    volatile register uint32_t arg0 asm("a0");  // x10
    asm volatile(
        "0:"
        "nop \n nop \n nop \n nop \n"
        "li t0, 1 \n"
        ".word (0b0010110 << 25) | \
               (     (10) << 15) | \
               (    0b010 << 12) | \
               (      (5) <<  7) | \
               (0b0101011 <<  0)   \n"
        "nop \n nop \n nop \n nop \n"
        "bne t0, zero, 0b \n" ::"r"(arg0)
        : "t0", "memory");
}
