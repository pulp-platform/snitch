// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

//================================================================================
// Data
//================================================================================

volatile uint32_t _snrt_mutex;
volatile snrt_barrier_t _snrt_barrier;

//================================================================================
// Functions
//================================================================================

extern volatile uint32_t *snrt_mutex();

extern void snrt_mutex_acquire(volatile uint32_t *pmtx);

extern void snrt_mutex_ttas_acquire(volatile uint32_t *pmtx);

extern void snrt_mutex_release(volatile uint32_t *pmtx);

extern void snrt_cluster_hw_barrier();

extern void snrt_global_barrier();

extern void snrt_partial_barrier(snrt_barrier_t *barr, uint32_t n);
