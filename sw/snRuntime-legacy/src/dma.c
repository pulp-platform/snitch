// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include <snrt.h>

/// Initiate an asynchronous 1D DMA transfer with wide 64-bit pointers.
snrt_dma_txid_t snrt_dma_start_1d_wideptr(uint64_t dst, uint64_t src,
                                          size_t size) {
    register uint32_t reg_dst_low asm("a0") = dst >> 0;    // 10
    register uint32_t reg_dst_high asm("a1") = dst >> 32;  // 11
    register uint32_t reg_src_low asm("a2") = src >> 0;    // 12
    register uint32_t reg_src_high asm("a3") = src >> 32;  // 13
    register uint32_t reg_size asm("a4") = size;           // 14

    // dmsrc a0, a1
    asm volatile(
        ".word (0b0000000 << 25) | \
               (     (13) << 20) | \
               (     (12) << 15) | \
               (    0b000 << 12) | \
               (0b0101011 <<  0)   \n" ::"r"(reg_src_high),
        "r"(reg_src_low));

    // dmdst a0, a1
    asm volatile(
        ".word (0b0000001 << 25) | \
               (     (11) << 20) | \
               (     (10) << 15) | \
               (    0b000 << 12) | \
               (0b0101011 <<  0)   \n" ::"r"(reg_dst_high),
        "r"(reg_dst_low));

    // dmcpyi a0, a4, 0b00
    register uint32_t reg_txid asm("a0");  // 10
    asm volatile(
        ".word (0b0000010 << 25) | \
               (  0b00000 << 20) | \
               (     (14) << 15) | \
               (    0b000 << 12) | \
               (     (10) <<  7) | \
               (0b0101011 <<  0)   \n"
        : "=r"(reg_txid)
        : "r"(reg_size));

    return reg_txid;
}

/// Initiate an asynchronous 1D DMA transfer.
snrt_dma_txid_t snrt_dma_start_1d(void *dst, const void *src, size_t size) {
    return snrt_dma_start_1d_wideptr((size_t)dst, (size_t)src, size);
}

/// Initiate an asynchronous 2D DMA transfer with wide 64-bit pointers.
snrt_dma_txid_t snrt_dma_start_2d_wideptr(uint64_t dst, uint64_t src,
                                          size_t size, size_t dst_stride,
                                          size_t src_stride, size_t repeat) {
    register uint32_t reg_dst_low asm("a0") = dst >> 0;       // 10
    register uint32_t reg_dst_high asm("a1") = dst >> 32;     // 11
    register uint32_t reg_src_low asm("a2") = src >> 0;       // 12
    register uint32_t reg_src_high asm("a3") = src >> 32;     // 13
    register uint32_t reg_size asm("a4") = size;              // 14
    register uint32_t reg_dst_stride asm("a5") = dst_stride;  // 15
    register uint32_t reg_src_stride asm("a6") = src_stride;  // 16
    register uint32_t reg_repeat asm("a7") = repeat;          // 17

    // dmsrc a0, a1
    asm volatile(
        ".word (0b0000000 << 25) | \
               (     (13) << 20) | \
               (     (12) << 15) | \
               (    0b000 << 12) | \
               (0b0101011 <<  0)   \n" ::"r"(reg_src_high),
        "r"(reg_src_low));

    // dmdst a0, a1
    asm volatile(
        ".word (0b0000001 << 25) | \
               (     (11) << 20) | \
               (     (10) << 15) | \
               (    0b000 << 12) | \
               (0b0101011 <<  0)   \n" ::"r"(reg_dst_high),
        "r"(reg_dst_low));

    // dmstr a5, a6
    asm volatile(
        ".word (0b0000110 << 25) | \
               (     (15) << 20) | \
               (     (16) << 15) | \
               (    0b000 << 12) | \
               (0b0101011 <<  0)   \n"
        :
        : "r"(reg_dst_stride), "r"(reg_src_stride));

    // dmrep a7
    asm volatile(
        ".word (0b0000111 << 25) | \
               (     (17) << 15) | \
               (    0b000 << 12) | \
               (0b0101011 <<  0)   \n"
        :
        : "r"(reg_repeat));

    // dmcpyi a0, a4, 0b10
    register uint32_t reg_txid asm("a0");  // 10
    asm volatile(
        ".word (0b0000010 << 25) | \
               (  0b00010 << 20) | \
               (     (14) << 15) | \
               (    0b000 << 12) | \
               (     (10) <<  7) | \
               (0b0101011 <<  0)   \n"
        : "=r"(reg_txid)
        : "r"(reg_size));

    return reg_txid;
}

/// Initiate an asynchronous 2D DMA transfer.
snrt_dma_txid_t snrt_dma_start_2d(void *dst, const void *src, size_t size,
                                  size_t dst_stride, size_t src_stride,
                                  size_t repeat) {
    return snrt_dma_start_2d_wideptr((size_t)dst, (size_t)src, size, dst_stride,
                                     src_stride, repeat);
}

/// Block until a transfer finishes.
void snrt_dma_wait(snrt_dma_txid_t tid) {
    // dmstati t0, 0  # 2=status.completed_id
    asm volatile(
        "1: \n"
        ".word (0b0000100 << 25) | \
               (  0b00000 << 20) | \
               (    0b000 << 12) | \
               (      (5) <<  7) | \
               (0b0101011 <<  0)   \n"
        "sub t0, t0, %0 \n"
        "blez t0, 1b \n" ::"r"(tid)
        : "t0");
}

/// Block until all operation on the DMA ceases.
void snrt_dma_wait_all() {
    // dmstati t0, 2  # 2=status.busy
    asm volatile(
        "1: \n"
        ".word (0b0000100 << 25) | \
               (  0b00010 << 20) | \
               (    0b000 << 12) | \
               (      (5) <<  7) | \
               (0b0101011 <<  0)   \n"
        "bne t0, zero, 1b \n" ::
            : "t0");
}
