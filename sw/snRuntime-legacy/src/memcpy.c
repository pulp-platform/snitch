// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <string.h>

#include "snrt.h"

// TODO: Implement using cluster DMA for a faster `memcpy`.
void *snrt_memcpy(void *dst, const void *src, size_t n) {
    return memcpy(dst, src, n);
}
