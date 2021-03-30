// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// Requires LLVM toolchain with builtins support for the Xdma extension

#include <stdint.h>

#define NELEM 1024

static volatile uint8_t src_buf[NELEM];
static volatile uint8_t dst_buf[NELEM];

int main(void) {
    uint64_t src, dst;
    uint32_t size = 10, cfg = 0, tid;
    unsigned errs = 0;

    for (int i = 0; i < NELEM; ++i) src_buf[i] = (uint8_t)i;

    src = (uint64_t)src_buf;
    dst = (uint64_t)dst_buf;
    size = sizeof(src_buf);
    cfg = 0;
    tid = __builtin_sdma_start_oned(src, dst, size, cfg);

    for (int i = 0; i < sizeof(src_buf); ++i) {
        errs = src_buf[i] != dst_buf[i] ? errs + 1 : errs;
        dst_buf[i] -= 1;
    }

    src = (uint64_t)dst_buf;
    dst = (uint64_t)src_buf;
    size = sizeof(src_buf);
    cfg = 0;
    tid = __builtin_sdma_start_oned(src, dst, size, cfg);

    for (int i = 0; i < sizeof(src_buf); ++i) {
        errs = src_buf[i] != dst_buf[i] ? errs + 1 : errs;
    }

    return errs;
}
