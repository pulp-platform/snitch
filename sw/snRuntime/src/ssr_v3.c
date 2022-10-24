// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include "snrt.h"

// Configure an SSR data mover for a 1D loop nest.
inline void snrt_ssr_loop_1d(enum snrt_ssr_dm dm, size_t b0, size_t i0) {
    --b0;
    __builtin_ssr_setup_bound_stride_1d(dm, b0, i0 - 0);
}

// Configure an SSR data mover for a 2D loop nest.
void snrt_ssr_loop_2d(enum snrt_ssr_dm dm, size_t b0, size_t b1, size_t i0,
                      size_t i1) {
    --b0;
    --b1;
    size_t a = 0;
    __builtin_ssr_setup_bound_stride_1d(dm, b0, i0 - a);
    a += i0 * b0;
    __builtin_ssr_setup_bound_stride_2d(dm, b1, i1 - a);
}

// Configure an SSR data mover for a 3D loop nest.
void snrt_ssr_loop_3d(enum snrt_ssr_dm dm, size_t b0, size_t b1, size_t b2,
                      size_t i0, size_t i1, size_t i2) {
    --b0;
    --b1;
    --b2;
    size_t a = 0;
    __builtin_ssr_setup_bound_stride_1d(dm, b0, i0 - a);
    a += i0 * b0;
    __builtin_ssr_setup_bound_stride_2d(dm, b1, i1 - a);
    a += i1 * b1;
    __builtin_ssr_setup_bound_stride_3d(dm, b2, i2 - a);
}

// Configure an SSR data mover for a 4D loop nest.
// b0: Inner-most bound (limit of loop)
// b3: Outer-most bound (limit of loop)
// i0: increment size of inner-most loop
void snrt_ssr_loop_4d(enum snrt_ssr_dm dm, size_t b0, size_t b1, size_t b2,
                      size_t b3, size_t i0, size_t i1, size_t i2, size_t i3) {
    --b0;
    --b1;
    --b2;
    --b3;
    size_t a = 0;
    __builtin_ssr_setup_bound_stride_1d(dm, b0, i0 - a);
    a += i0 * b0;
    __builtin_ssr_setup_bound_stride_2d(dm, b1, i1 - a);
    a += i1 * b1;
    __builtin_ssr_setup_bound_stride_3d(dm, b2, i2 - a);
    a += i2 * b2;
    __builtin_ssr_setup_bound_stride_4d(dm, b3, i3 - a);
}

/// Configure the repetition count for a stream.
void snrt_ssr_repeat(enum snrt_ssr_dm dm, size_t count) {
    __builtin_ssr_setup_repetition(dm, count - 1);
}

/// Start a streaming read.
void snrt_ssr_read(enum snrt_ssr_dm dm, enum snrt_ssr_dim dim,
                   volatile void *ptr) {
    __builtin_ssr_read(dm, dim, ptr);
}

/// Start a streaming write.
void snrt_ssr_write(enum snrt_ssr_dm dm, enum snrt_ssr_dim dim,
                    volatile void *ptr) {
    __builtin_ssr_write(dm, dim, ptr);
}
