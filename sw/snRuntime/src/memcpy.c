// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// A simple implementation of memcpy.

#include "snrt.h"

void *snrt_memcpy(void *dst, const void *src, size_t n) {
    const void *end = dst + n;

    size_t dst_align = (size_t)dst % sizeof(size_t);
    size_t src_align = (size_t)src % sizeof(size_t);

    if (dst_align == src_align) {
        size_t a = dst_align;
        while (a++ != 0 && dst != end) {
            *(char *)dst++ = *(char *)src++;
        }
        while (dst + sizeof(size_t) <= end) {
            *(size_t *)dst++ = *(size_t *)src++;
        }
        while (dst != end) {
            *(char *)dst++ = *(char *)src++;
        }
    } else {
        while (dst != end) {
            *(char *)dst++ = *(char *)src++;
        }
    }

    return dst;
}
