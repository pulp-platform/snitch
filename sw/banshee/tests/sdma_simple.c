// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// Requires LLVM toolchain with builtins support for the Xdma extension

#include <stdint.h>

#define NELEM 128

static volatile uint8_t src_buf[NELEM];
static volatile uint8_t dst_buf[NELEM];

int main(int hartid) {
    uint64_t src, dst;
    uint32_t size = 10, cfg = 0, tid, sstrd, dstrd, nreps;
    unsigned errs = 0;

#ifdef VSIM
    // but non-dma cores to sleep
    if (hartid != 8) asm("wfi");
#endif

    for (int i = 0; i < NELEM; ++i) src_buf[i] = (uint8_t)i;

    /// Copy src -> dst
    src = (uint64_t)src_buf;
    dst = (uint64_t)dst_buf;
    size = sizeof(src_buf);
    cfg = 0;
    tid = __builtin_sdma_start_oned(src, dst, size, cfg);
    __builtin_sdma_wait_for_idle();

    /// verify
    for (int i = 0; i < sizeof(src_buf); ++i) {
        if (src_buf[i] != dst_buf[i]) ++errs;
        dst_buf[i] -= 1;
    }

    /// Copy dst -> src
    src = (uint64_t)dst_buf;
    dst = (uint64_t)src_buf;
    size = sizeof(src_buf);
    cfg = 0;
    tid = __builtin_sdma_start_oned(src, dst, size, cfg);
    __builtin_sdma_wait_for_idle();

    // verify
    for (int i = 0; i < sizeof(src_buf); ++i) {
        errs = src_buf[i] != dst_buf[i] ? errs + 1 : errs;
        src_buf[i] = i;
    }

    /// 2D transfer of 8 bytes, 4 times with zero relative strides
    sstrd = 8;
    dstrd = 8;
    nreps = 4;
    src = (uint64_t)src_buf;
    dst = (uint64_t)dst_buf;
    size = 8;
    cfg = 0;
    tid = __builtin_sdma_start_twod(src, dst, size, sstrd, dstrd, nreps, cfg);
    __builtin_sdma_wait_for_idle();

    // verify
    for (int i = 0; i < size * nreps; ++i) {
        errs = src_buf[i] != dst_buf[i] ? errs + 1 : errs;
    }

    /// 2D transfer of 8 bytes, 4 times with custom byte strides
    sstrd = 0x10;
    dstrd = 0x20;
    nreps = 4;
    src = (uint64_t)src_buf;
    dst = (uint64_t)dst_buf;
    size = 8;
    cfg = 0;
    tid = __builtin_sdma_start_twod(src, dst, size, sstrd, dstrd, nreps, cfg);
    __builtin_sdma_wait_for_idle();

    // verify
    for (int n = 0; n < nreps; ++n) {
        for (int b = 0; b < size; ++b) {
            errs = src_buf[n * sstrd + b] != dst_buf[n * dstrd + b] ? errs + 1
                                                                    : errs;
        }
    }

#ifdef VSIM
    // because this is not core 0, report exit code
    asm volatile(
        "la        t0, eoc_address\n"
        "mv        t2, %[errs]\n"
        "sw        t2, 0(t0)\n"
        // write exit code and done bit
        "la        t1, tohost\n"
        "slli      t2, t2, 1\n"
        "ori       t2, t2, 1\n"
        "sw        t2, 0(t1)\n"
        // write exit code for banshee
        "li        t0, 0x40000020\n"
        "sw        t2, 0(t0)\n"
        :
        : [ errs ] "r"(errs)
        : "t0", "t1", "t2");
#endif

    return errs;
}
