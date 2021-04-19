// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <stdint.h>

int main() {
    volatile uint32_t x0 = 42;
    volatile uint32_t x1 = 9001;

    void *ptr_src = (void *)&x0;
    void *ptr_dst = (void *)&x1;

    register uint32_t reg_src_high asm("s2") = 0;                 // 19
    register uint32_t reg_src_low asm("s3") = (uint32_t)ptr_src;  // 18
    register uint32_t reg_dst_high asm("s4") = 0;                 // 21
    register uint32_t reg_dst_low asm("s5") = (uint32_t)ptr_dst;  // 20
    register uint32_t reg_tf_id asm("s6");                        // 22
    register uint32_t reg_num_bytes asm("s7") = 4;                // 23

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
        ".word (0b0000010 << 25) | \
               (     (23) << 15) | \
               (    0b000 << 12) | \
               (     (22) <<  7) | \
               (0b0101011 <<  0)   \n"
        : "=r"(reg_tf_id)
        : "r"(reg_num_bytes));

    // check done
    volatile register uint32_t busy asm("t0");  // x10
    asm volatile(
        ".word (0b0000100 << 25) | \
               (    0b010 << 20) | \
               (      (5) <<  7) | \
               (0b0101011 <<  0)   \n"
        : "=r"(busy)::"memory");

    return (x0 != x1) | (busy << 1);
}
