// Copyright 2021 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

__thread volatile dm_t *dm_p;
volatile dm_t *volatile dm_p_global;

extern void dm_init(void);

extern void dm_main(void);

extern void dm_memcpy_async(void *dest, const void *src, size_t n);

extern void dm_memcpy2d_async(uint64_t src, uint64_t dst, uint32_t size,
                              uint32_t sstrd, uint32_t dstrd, uint32_t nreps,
                              uint32_t cfg);

extern void dm_start(void);

extern void dm_wait(void);

extern void dm_exit(void);

extern void dm_wait_ready(void);