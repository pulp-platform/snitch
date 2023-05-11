// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

static inline uint32_t snrt_cls_base_addr() {
    extern volatile uint32_t __cdata_start, __cdata_end;
    extern volatile uint32_t __cbss_start, __cbss_end;
    uint32_t cdata_size = ((uint32_t)&__cdata_end) - ((uint32_t)&__cdata_start);
    uint32_t cbss_size = ((uint32_t)&__cbss_end) - ((uint32_t)&__cbss_start);
    uint32_t l1_end_addr = SNRT_TCDM_START_ADDR +
                           snrt_cluster_idx() * SNRT_CLUSTER_OFFSET +
                           SNRT_TCDM_SIZE;
    return l1_end_addr - cdata_size - cbss_size;
}

static inline void snrt_crt0_cluster_hw_barrier() {
    uint32_t register r;
    uint32_t hw_barrier =
        SNRT_CLUSTER_HW_BARRIER_ADDR + snrt_cluster_idx() * SNRT_CLUSTER_OFFSET;
    asm volatile("lw %0, 0(%1)" : "=r"(r) : "r"(hw_barrier) : "memory");
}

static inline void snrt_init_tls() {
    extern volatile uint32_t __tdata_start, __tdata_end;
    extern volatile uint32_t __tbss_start, __tbss_end;

    volatile uint32_t* p;
    volatile uint32_t* tls_ptr;

    asm volatile("mv %0, tp" : "=r"(tls_ptr) : :);

    // Copy tdata section
    for (p = (uint32_t*)(&__tdata_start); p < (uint32_t*)(&__tdata_end); p++) {
        *tls_ptr = *p;
        tls_ptr++;
    }

    // Clear tbss section
    for (p = (uint32_t*)(&__tbss_start); p < (uint32_t*)(&__tbss_end); p++) {
        *tls_ptr = 0;
        tls_ptr++;
    }
}

static inline void snrt_init_bss() {
    extern volatile uint32_t __bss_start, __bss_end;

    // Only one core needs to perform the initialization
    if (snrt_cluster_idx() == 0 && snrt_is_dm_core()) {
        volatile uint32_t* p;

        for (p = (uint32_t*)(&__bss_start); p < (uint32_t*)(&__bss_end); p++) {
            *p = 0;
        }
    }
}

static inline void snrt_init_cls() {
    extern volatile uint32_t __cdata_start, __cdata_end;
    extern volatile uint32_t __cbss_start, __cbss_end;

    _cls_ptr = (cls_t*)snrt_cls_base_addr();

    // Only one core per cluster has to do this
    if (snrt_is_dm_core()) {
        volatile uint32_t* p;
        volatile uint32_t* cls_ptr = (volatile uint32_t*)snrt_cls_base_addr();

        // Copy cdata section to base of the TCDM
        for (p = (uint32_t*)(&__cdata_start); p < (uint32_t*)(&__cdata_end);
             p++) {
            *cls_ptr = *p;
            cls_ptr++;
        }

        // Clear cbss section
        for (p = (uint32_t*)(&__cbss_start); p < (uint32_t*)(&__cbss_end);
             p++) {
            *cls_ptr = 0;
            cls_ptr++;
        }
    }
}

static inline void snrt_init_libs() { snrt_alloc_init(); }

static inline void snrt_exit(int exit_code) {
    extern volatile uint32_t tohost;

    if (snrt_global_core_idx() == 0) tohost = (exit_code << 1) | 1;
}

void snrt_main() {
    int exit_code = 0;

#ifdef SNRT_CRT0_CALLBACK0

    snrt_crt0_callback0();
#endif

#ifdef SNRT_INIT_TLS
    snrt_init_tls();
#endif

#ifdef SNRT_CRT0_CALLBACK1
    snrt_crt0_callback1();
#endif

#ifdef SNRT_INIT_BSS
    snrt_init_bss();
#endif

#ifdef SNRT_CRT0_CALLBACK2
    snrt_crt0_callback2();
#endif

#ifdef SNRT_INIT_CLS
    snrt_init_cls();
#endif

#ifdef SNRT_CRT0_CALLBACK3
    snrt_crt0_callback3();
#endif

#ifdef SNRT_INIT_LIBS
    snrt_init_libs();
#endif

#ifdef SNRT_CRT0_CALLBACK4
    snrt_crt0_callback4();
#endif

#ifdef SNRT_CRT0_PRE_BARRIER
    snrt_crt0_cluster_hw_barrier();
#endif

#ifdef SNRT_CRT0_CALLBACK5
    snrt_crt0_callback5();
#endif

#ifdef SNRT_INVOKE_MAIN
    extern int main();
    exit_code = main();
#endif

#ifdef SNRT_CRT0_CALLBACK6
    snrt_crt0_callback6();
#endif

#ifdef SNRT_CRT0_POST_BARRIER
    snrt_crt0_cluster_hw_barrier();
#endif

#ifdef SNRT_CRT0_CALLBACK7
    snrt_crt0_callback7();
#endif

#ifdef SNRT_CRT0_EXIT
    snrt_exit(exit_code);
#endif

#ifdef SNRT_CRT0_CALLBACK8
    snrt_crt0_callback8(exit_code);
#endif
}
