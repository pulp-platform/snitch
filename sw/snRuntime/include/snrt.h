// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
#pragma once

#include <stddef.h>
#include <stdint.h>

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

static inline size_t snrt_slice_len(snrt_slice_t s) { return s.end - s.start; }

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

extern snrt_slice_t snrt_global_memory();
extern snrt_slice_t snrt_cluster_memory();

extern void snrt_bcast_send(void *data, size_t len);
extern void snrt_bcast_recv(void *data, size_t len);

extern void *snrt_memcpy(void *dst, const void *src, size_t n);
