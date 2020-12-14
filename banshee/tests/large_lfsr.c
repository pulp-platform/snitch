// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <stdint.h>

int main() {
    uint32_t lfsr = *(uint32_t *)0x40000008 | 1;
    for (int i = 0; i < 100000000; i++) {
        uint32_t lsb = lfsr & 1;  // extract LSB
        lsb = -lsb;               // map 0 to 0 and 1 to 0xFFFFFFFF
        lfsr >>= 1;
        lfsr ^= 0xd0000001 & lsb;
    }
    *(uint32_t *)0x40000028 = lfsr;
    return 0;
}
