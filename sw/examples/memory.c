// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "printf.h"
#include "snrt.h"

__thread uint32_t private_int;

int main() {
    uint32_t core_idx = snrt_global_core_idx();
    uint32_t core_num = snrt_global_core_num();

    // Thread-private memory can be used with the __thread specifier. It makes
    // use of TLS and buts initialized and non-initialized data in the TCDM
    // memory region reserved for the stack. __thread variable must have global
    // storage
    private_int = 1000 + core_idx;
    for (uint32_t i = 0; i < core_num; i++) {
        if (i == core_idx)
            printf("thread-private: %d at %#x\n", private_int, &private_int);
        snrt_barrier();
    }

    // local storage is allocated on stack and also thread-private
    uint32_t private_int_stack = 2000 + core_idx;
    for (uint32_t i = 0; i < core_num; i++) {
        if (i == core_idx)
            printf("thread-private on stack: %d at %#x\n", private_int_stack,
                   &private_int_stack);
        snrt_barrier();
    }

    // Use snrt_l1alloc() to allocate a chunk of memory in the cluster-private
    // TCMD L1 scratchpad memory. Free is currently not possible. Store the
    // pointer in a static variable that is shared amongst the cluster cores
    static void* p;
    if (core_idx == 0) {
        p = snrt_l1alloc(1024);
        printf("Allocated at %#x\n", p);
    }
    for (uint32_t i = 0; i < core_num; i++) {
        if (i == core_idx) printf("  %#x pointer location: %#x\n", p, &p);
        snrt_barrier();
    }

    return 0;
}
