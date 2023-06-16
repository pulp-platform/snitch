// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/// Synchronize the integer and float pipelines.
inline void snrt_fpu_fence() {
    unsigned tmp;
    asm volatile(
        "fmv.x.w %0, fa0\n"
        "mv      %0, %0\n"
        : "+r"(tmp)::"memory");
}

/// The different SSR data movers.
enum snrt_ssr_dm {
    SNRT_SSR_DM0 = 0,
    SNRT_SSR_DM1 = 1,
    SNRT_SSR_DM2 = 2,
    // To write to all SSRs, use index 31
    SNRT_SSR_DM_ALL = 31,
};

/// The different dimensions.
enum snrt_ssr_dim {
    SNRT_SSR_1D = 0,
    SNRT_SSR_2D = 1,
    SNRT_SSR_3D = 2,
    SNRT_SSR_4D = 3,
};

/// The SSR configuration registers.
enum {
    REG_STATUS = 0,
    REG_REPEAT = 1,
    REG_BOUNDS = 2,   // + loop index
    REG_STRIDES = 6,  // + loop index
    REG_RPTR = 24,    // + snrt_ssr_dim
    REG_WPTR = 28,    // + snrt_ssr_dim
};

/// Enable SSR.
inline void snrt_ssr_enable() {
#ifdef __TOOLCHAIN_LLVM__
    __builtin_ssr_enable();
#else
    asm volatile("csrsi 0x7C0, 1\n");
#endif
}

/// Disable SSR.
inline void snrt_ssr_disable() {
#ifdef __TOOLCHAIN_LLVM__
    __builtin_ssr_disable();
#else
    asm volatile("csrci 0x7C0, 1\n");
#endif
}

inline uint32_t read_ssr_cfg(uint32_t reg, uint32_t dm) {
    uint32_t value;
    asm volatile("scfgri %[value], %[dm] | %[reg]<<5\n"
                 : [ value ] "=r"(value)
                 : [ dm ] "i"(dm), [ reg ] "i"(reg));
    return value;
}

inline void write_ssr_cfg(uint32_t reg, uint32_t dm, uint32_t value) {
    asm volatile("scfgwi %[value], %[dm] | %[reg]<<5\n" ::[value] "r"(value),
                 [ dm ] "i"(dm), [ reg ] "i"(reg));
}

// Configure an SSR data mover for a 1D loop nest.
inline void snrt_ssr_loop_1d(enum snrt_ssr_dm dm, size_t b0, size_t s0) {
    --b0;
    write_ssr_cfg(REG_BOUNDS + 0, dm, b0);
    size_t a = 0;
    write_ssr_cfg(REG_STRIDES + 0, dm, s0 - a);
    a += s0 * b0;
}

// Configure an SSR data mover for a 2D loop nest.
inline void snrt_ssr_loop_2d(enum snrt_ssr_dm dm, size_t b0, size_t b1,
                             size_t s0, size_t s1) {
    --b0;
    --b1;
    write_ssr_cfg(REG_BOUNDS + 0, dm, b0);
    write_ssr_cfg(REG_BOUNDS + 1, dm, b1);
    size_t a = 0;
    write_ssr_cfg(REG_STRIDES + 0, dm, s0 - a);
    a += s0 * b0;
    write_ssr_cfg(REG_STRIDES + 1, dm, s1 - a);
    a += s1 * b1;
}

// Configure an SSR data mover for a 3D loop nest.
inline void snrt_ssr_loop_3d(enum snrt_ssr_dm dm, size_t b0, size_t b1,
                             size_t b2, size_t s0, size_t s1, size_t s2) {
    --b0;
    --b1;
    --b2;
    write_ssr_cfg(REG_BOUNDS + 0, dm, b0);
    write_ssr_cfg(REG_BOUNDS + 1, dm, b1);
    write_ssr_cfg(REG_BOUNDS + 2, dm, b2);
    size_t a = 0;
    write_ssr_cfg(REG_STRIDES + 0, dm, s0 - a);
    a += s0 * b0;
    write_ssr_cfg(REG_STRIDES + 1, dm, s1 - a);
    a += s1 * b1;
    write_ssr_cfg(REG_STRIDES + 2, dm, s2 - a);
    a += s2 * b2;
}

// Configure an SSR data mover for a 4D loop nest.
// b0: Inner-most bound (limit of loop)
// b3: Outer-most bound (limit of loop)
// s0: increment size of inner-most loop
inline void snrt_ssr_loop_4d(enum snrt_ssr_dm dm, size_t b0, size_t b1,
                             size_t b2, size_t b3, size_t s0, size_t s1,
                             size_t s2, size_t s3) {
    --b0;
    --b1;
    --b2;
    --b3;
    write_ssr_cfg(REG_BOUNDS + 0, dm, b0);
    write_ssr_cfg(REG_BOUNDS + 1, dm, b1);
    write_ssr_cfg(REG_BOUNDS + 2, dm, b2);
    write_ssr_cfg(REG_BOUNDS + 3, dm, b3);
    size_t a = 0;
    write_ssr_cfg(REG_STRIDES + 0, dm, s0 - a);
    a += s0 * b0;
    write_ssr_cfg(REG_STRIDES + 1, dm, s1 - a);
    a += s1 * b1;
    write_ssr_cfg(REG_STRIDES + 2, dm, s2 - a);
    a += s2 * b2;
    write_ssr_cfg(REG_STRIDES + 3, dm, s3 - a);
    a += s3 * b3;
}

/// Configure the repetition count for a stream.
inline void snrt_ssr_repeat(enum snrt_ssr_dm dm, size_t count) {
    write_ssr_cfg(REG_REPEAT, dm, count - 1);
}

/// Start a streaming read.
inline void snrt_ssr_read(enum snrt_ssr_dm dm, enum snrt_ssr_dim dim,
                          volatile void *ptr) {
    write_ssr_cfg(REG_RPTR + dim, dm, (uintptr_t)ptr);
}

/// Start a streaming write.
inline void snrt_ssr_write(enum snrt_ssr_dm dm, enum snrt_ssr_dim dim,
                           volatile void *ptr) {
    write_ssr_cfg(REG_WPTR + dim, dm, (uintptr_t)ptr);
}
