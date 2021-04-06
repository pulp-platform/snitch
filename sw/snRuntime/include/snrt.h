// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include <stddef.h>
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif

#ifndef snrt_min
#define snrt_min(a, b) ((a) < (b) ? (a) : (b))
#endif

#ifndef snrt_max
#define snrt_max(a, b) ((a) > (b) ? (a) : (b))
#endif

/// A slice of memory.
typedef struct snrt_slice {
    void *start;
    void *end;
} snrt_slice_t;

static inline size_t snrt_slice_len(snrt_slice_t s) {
    return (char *)s.end - (char *)s.start;
}

extern void snrt_barrier();

extern uint32_t __attribute__((pure)) snrt_hartid();
extern uint32_t snrt_global_core_idx();
extern uint32_t snrt_global_core_num();
extern uint32_t snrt_global_compute_core_idx();
extern uint32_t snrt_global_compute_core_num();
extern uint32_t snrt_global_dm_core_idx();
extern uint32_t snrt_global_dm_core_num();
extern uint32_t snrt_cluster_core_idx();
extern uint32_t snrt_cluster_core_num();
extern uint32_t snrt_cluster_compute_core_idx();
extern uint32_t snrt_cluster_compute_core_num();
extern uint32_t snrt_cluster_dm_core_idx();
extern uint32_t snrt_cluster_dm_core_num();
extern uint32_t snrt_cluster_idx();
extern uint32_t snrt_cluster_num();
extern int snrt_is_compute_core();
extern int snrt_is_dm_core();

extern snrt_slice_t snrt_global_memory();
extern snrt_slice_t snrt_cluster_memory();

extern void snrt_bcast_send(void *data, size_t len);
extern void snrt_bcast_recv(void *data, size_t len);

extern void *snrt_memcpy(void *dst, const void *src, size_t n);

/// DMA runtime functions.
/// A DMA transfer identifier.
typedef uint32_t snrt_dma_txid_t;
/// Initiate an asynchronous 1D DMA transfer with wide 64-bit pointers.
extern snrt_dma_txid_t snrt_dma_start_1d_wideptr(uint64_t dst, uint64_t src,
                                                 size_t size);
/// Initiate an asynchronous 1D DMA transfer.
extern snrt_dma_txid_t snrt_dma_start_1d(void *dst, const void *src,
                                         size_t size);
/// Initiate an asynchronous 2D DMA transfer with wide 64-bit pointers.
extern snrt_dma_txid_t snrt_dma_start_2d_wideptr(uint64_t dst, uint64_t src,
                                                 size_t size, size_t dst_stride,
                                                 size_t src_stride,
                                                 size_t repeat);
/// Initiate an asynchronous 2D DMA transfer.
extern snrt_dma_txid_t snrt_dma_start_2d(void *dst, const void *src,
                                         size_t size, size_t src_stride,
                                         size_t dst_stride, size_t repeat);
/// Block until a transfer finishes.
extern void snrt_dma_wait(snrt_dma_txid_t tid);
/// Block until all operation on the DMA ceases.
extern void snrt_dma_wait_all();

/// The different SSR data movers.
enum snrt_ssr_dm {
    SNRT_SSR_DM0 = 0,
    SNRT_SSR_DM1 = 1,
    SNRT_SSR_DM2 = 2,
};

/// The different dimensions.
enum snrt_ssr_dim {
    SNRT_SSR_1D = 0,
    SNRT_SSR_2D = 1,
    SNRT_SSR_3D = 2,
    SNRT_SSR_4D = 3,
};

extern void snrt_ssr_loop_1d(enum snrt_ssr_dm dm, size_t b0, size_t i0);
extern void snrt_ssr_loop_2d(enum snrt_ssr_dm dm, size_t b0, size_t b1,
                             size_t i0, size_t i1);
extern void snrt_ssr_loop_3d(enum snrt_ssr_dm dm, size_t b0, size_t b1,
                             size_t b2, size_t i0, size_t i1, size_t i2);
extern void snrt_ssr_loop_4d(enum snrt_ssr_dm dm, size_t b0, size_t b1,
                             size_t b2, size_t b3, size_t i0, size_t i1,
                             size_t i2, size_t i3);
extern void snrt_ssr_repeat(enum snrt_ssr_dm dm, size_t count);
extern void snrt_ssr_enable();
extern void snrt_ssr_disable();
extern void snrt_ssr_read(enum snrt_ssr_dm dm, enum snrt_ssr_dim dim,
                          volatile void *ptr);
extern void snrt_ssr_write(enum snrt_ssr_dm dm, enum snrt_ssr_dim dim,
                           volatile void *ptr);
extern void snrt_fpu_fence();

#ifdef __cplusplus
}
#endif
