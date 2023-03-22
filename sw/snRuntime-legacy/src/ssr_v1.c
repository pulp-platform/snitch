// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include "snrt.h"

/// The SSR configuration registers.
typedef union {
    uint32_t value __attribute__((aligned(8)));
} ssr_reg32_t;
typedef struct {
    ssr_reg32_t status;
    ssr_reg32_t repeat;
    ssr_reg32_t bounds[4];
    ssr_reg32_t stride[4];
    ssr_reg32_t _reserved4[14];
    ssr_reg32_t rptr[4];
    ssr_reg32_t wptr[4];
} ssr_cfg_t;
static volatile ssr_cfg_t *const ssr_config_reg = (void *)0x204800;

// Configure an SSR data mover for a 1D loop nest.
void snrt_ssr_loop_1d(enum snrt_ssr_dm dm, size_t b0, size_t i0) {
    --b0;
    ssr_config_reg[dm].bounds[0].value = b0;
    size_t a = 0;
    ssr_config_reg[dm].stride[0].value = i0 - a;
    a += i0 * b0;
}

// Configure an SSR data mover for a 2D loop nest.
void snrt_ssr_loop_2d(enum snrt_ssr_dm dm, size_t b0, size_t b1, size_t i0,
                      size_t i1) {
    --b0;
    --b1;
    ssr_config_reg[dm].bounds[0].value = b0;
    ssr_config_reg[dm].bounds[1].value = b1;
    size_t a = 0;
    ssr_config_reg[dm].stride[0].value = i0 - a;
    a += i0 * b0;
    ssr_config_reg[dm].stride[1].value = i1 - a;
    a += i1 * b1;
}

// Configure an SSR data mover for a 3D loop nest.
void snrt_ssr_loop_3d(enum snrt_ssr_dm dm, size_t b0, size_t b1, size_t b2,
                      size_t i0, size_t i1, size_t i2) {
    --b0;
    --b1;
    --b2;
    ssr_config_reg[dm].bounds[0].value = b0;
    ssr_config_reg[dm].bounds[1].value = b1;
    ssr_config_reg[dm].bounds[2].value = b2;
    size_t a = 0;
    ssr_config_reg[dm].stride[0].value = i0 - a;
    a += i0 * b0;
    ssr_config_reg[dm].stride[1].value = i1 - a;
    a += i1 * b1;
    ssr_config_reg[dm].stride[2].value = i2 - a;
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
    ssr_config_reg[dm].bounds[0].value = b0;
    ssr_config_reg[dm].bounds[1].value = b1;
    ssr_config_reg[dm].bounds[2].value = b2;
    ssr_config_reg[dm].bounds[3].value = b3;
    size_t a = 0;
    ssr_config_reg[dm].stride[0].value = i0 - a;
    a += i0 * b0;
    ssr_config_reg[dm].stride[1].value = i1 - a;
    a += i1 * b1;
    ssr_config_reg[dm].stride[2].value = i2 - a;
    a += i2 * b2;
    ssr_config_reg[dm].stride[3].value = i3 - a;
    a += i3 * b3;
}

/// Configure the repetition count for a stream.
void snrt_ssr_repeat(enum snrt_ssr_dm dm, size_t count) {
    ssr_config_reg[dm].repeat.value = count - 1;
}

/// Start a streaming read.
void snrt_ssr_read(enum snrt_ssr_dm dm, enum snrt_ssr_dim dim,
                   volatile void *ptr) {
    ssr_config_reg[dm].rptr[dim].value = (size_t)ptr;
}

/// Start a streaming write.
void snrt_ssr_write(enum snrt_ssr_dm dm, enum snrt_ssr_dim dim,
                    volatile void *ptr) {
    ssr_config_reg[dm].wptr[dim].value = (size_t)ptr;
}
