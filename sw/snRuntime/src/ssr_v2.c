// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include "snrt.h"

static uint32_t read_ssr_cfg(uint32_t reg, uint32_t dm) {
    // scfgr t0, t0
    register uint32_t t0 asm("t0") = reg << 5 | dm;
    asm volatile(
        ".word (0b0000000 << 25) | \
               (      (5) << 20) | \
               (  0b00001 << 15) | \
               (    0b001 << 12) | \
               (      (5) <<  7) | \
               (0b0101011 <<  0)   \n"
        : "+r"(t0));
    return t0;
}

static void write_ssr_cfg(uint32_t reg, uint32_t dm, uint32_t value) {
    register uint32_t t0 asm("t0") = reg << 5 | dm;
    register uint32_t t1 asm("t1") = value;
    // scfgw t1, t0
    asm volatile(
        ".word (0b0000000 << 25) | \
               (      (5) << 20) | \
               (      (6) << 15) | \
               (    0b010 << 12) | \
               (  0b00001 <<  7) | \
               (0b0101011 <<  0)   \n" ::"r"(t0),
        "r"(t1));
}

/// The SSR configuration registers.
enum {
    REG_STATUS = 0,
    REG_REPEAT = 1,
    REG_BOUNDS = 2,   // + loop index
    REG_STRIDES = 6,  // + loop index
    REG_RPTR = 24,    // + snrt_ssr_dim
    REG_WPTR = 28,    // + snrt_ssr_dim
};

// Configure an SSR data mover for a 1D loop nest.
void snrt_ssr_loop_1d(enum snrt_ssr_dm dm, size_t b0, size_t i0) {
    --b0;
    write_ssr_cfg(REG_BOUNDS + 0, dm, b0);
    size_t a = 0;
    write_ssr_cfg(REG_STRIDES + 0, dm, i0 - a);
    a += i0 * b0;
}

// Configure an SSR data mover for a 2D loop nest.
void snrt_ssr_loop_2d(enum snrt_ssr_dm dm, size_t b0, size_t b1, size_t i0,
                      size_t i1) {
    --b0;
    --b1;
    write_ssr_cfg(REG_BOUNDS + 0, dm, b0);
    write_ssr_cfg(REG_BOUNDS + 1, dm, b1);
    size_t a = 0;
    write_ssr_cfg(REG_STRIDES + 0, dm, i0 - a);
    a += i0 * b0;
    write_ssr_cfg(REG_STRIDES + 1, dm, i1 - a);
    a += i1 * b1;
}

// Configure an SSR data mover for a 3D loop nest.
void snrt_ssr_loop_3d(enum snrt_ssr_dm dm, size_t b0, size_t b1, size_t b2,
                      size_t i0, size_t i1, size_t i2) {
    --b0;
    --b1;
    --b2;
    write_ssr_cfg(REG_BOUNDS + 0, dm, b0);
    write_ssr_cfg(REG_BOUNDS + 1, dm, b1);
    write_ssr_cfg(REG_BOUNDS + 2, dm, b2);
    size_t a = 0;
    write_ssr_cfg(REG_STRIDES + 0, dm, i0 - a);
    a += i0 * b0;
    write_ssr_cfg(REG_STRIDES + 1, dm, i1 - a);
    a += i1 * b1;
    write_ssr_cfg(REG_STRIDES + 2, dm, i2 - a);
    a += i2 * b2;
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
    write_ssr_cfg(REG_BOUNDS + 0, dm, b0);
    write_ssr_cfg(REG_BOUNDS + 1, dm, b1);
    write_ssr_cfg(REG_BOUNDS + 2, dm, b2);
    write_ssr_cfg(REG_BOUNDS + 3, dm, b3);
    size_t a = 0;
    write_ssr_cfg(REG_STRIDES + 0, dm, i0 - a);
    a += i0 * b0;
    write_ssr_cfg(REG_STRIDES + 1, dm, i1 - a);
    a += i1 * b1;
    write_ssr_cfg(REG_STRIDES + 2, dm, i2 - a);
    a += i2 * b2;
    write_ssr_cfg(REG_STRIDES + 3, dm, i3 - a);
    a += i3 * b3;
}

/// Configure the repetition count for a stream.
void snrt_ssr_repeat(enum snrt_ssr_dm dm, size_t count) {
    write_ssr_cfg(REG_REPEAT, dm, count - 1);
}

/// Start a streaming read.
void snrt_ssr_read(enum snrt_ssr_dm dm, enum snrt_ssr_dim dim,
                   volatile void *ptr) {
    write_ssr_cfg(REG_RPTR + dim, dm, (uintptr_t)ptr);
}

/// Start a streaming write.
void snrt_ssr_write(enum snrt_ssr_dm dm, enum snrt_ssr_dim dim,
                    volatile void *ptr) {
    write_ssr_cfg(REG_WPTR + dim, dm, (uintptr_t)ptr);
}
