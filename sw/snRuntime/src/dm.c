// Copyright 2021 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "dm.h"

#include "snrt.h"

//================================================================================
// Settings
//================================================================================

/**
 * @brief Define DM_USE_GLOBAL_CLINT to use the cluster-shared CLINT based SW
 * interrupt system for synchronization. If not defined, the harts use the
 * cluster-local CLINT to syncrhonize which is faster but only works for
 * cluster-local synchronization which is sufficient at the moment since the
 * OpenMP runtime is single cluster only.
 *
 */
// #define DM_USE_GLOBAL_CLINT

/**
 * @brief Number of outstanding transactions to buffer. Each requires
 * sizeof(dm_task_t) bytes
 *
 */
#define DM_TASK_QUEUE_SIZE 4

//================================================================================
// Macros
//================================================================================

#define _dm_mtx_lock() snrt_mutex_lock(&dm_p->mutex)
#define _dm_mtx_release() snrt_mutex_release(&dm_p->mutex)

/**
 * Returns of the dm status call
 */
#define DM_STATUS_COMPLETE_ID 0
#define DM_STATUS_NEXT_ID 1
#define DM_STATUS_BUSY 2
#define DM_STATUS_WOULD_BLOCK 3

//================================================================================
// Types
//================================================================================
typedef struct {
    uint64_t src;
    uint64_t dst;
    uint32_t size;
    uint32_t sstrd;
    uint32_t dstrd;
    uint32_t nreps;
    uint32_t cfg;
    uint32_t twod;
} dm_task_t;

// used for ultra-fine grained communication
// stat_q can be used to request a command, 0 is no command
// the response is put into stat_p and is valid iff stat_pvalid is non-zero
typedef enum en_stat {
    // commands the DM core to wait until all transfers are complete
    STAT_WAIT_IDLE = 1,
    // abort and exit
    STAT_EXIT = 2,
    // poll if DM is ready
    STAT_READY = 3,
} en_stat_t;

typedef struct {
    dm_task_t queue[DM_TASK_QUEUE_SIZE];
    uint32_t queue_back;
    uint32_t queue_front;
    volatile uint32_t queue_fill;
    volatile uint32_t mutex;
    volatile en_stat_t stat_q;
    volatile uint32_t stat_p;
    volatile uint32_t stat_pvalid;
    volatile uint32_t dm_wfi;
} dm_t;

//================================================================================
// Data
//================================================================================

/**
 * @brief Pointer to the data mover struct in TCDM per thread for faster access
 *
 */
__thread volatile dm_t *dm_p;
/**
 * @brief Pointer to where the DM struct in TCDM is located
 *
 */
static volatile dm_t *volatile dm_p_global;

/**
 * @brief DM core id for wakeup is stored on TLS for performance
 *
 */
__thread uint32_t cluster_dm_core_idx;

//================================================================================
// Declarations
//================================================================================
static void wfi_dm(uint32_t cluster_core_idx);
static void wake_dm(void);

//================================================================================
// Debug
//================================================================================
// #define DM_DEBUG_LEVEL 100

#ifdef DM_DEBUG_LEVEL
#include "printf.h"
#define _DM_PRINTF(...)             \
    if (1) {                        \
        printf("[dm] "__VA_ARGS__); \
    }
#define DM_PRINTF(d, ...)        \
    if (DM_DEBUG_LEVEL >= d) {   \
        _DM_PRINTF(__VA_ARGS__); \
    }
#else
#define DM_PRINTF(d, ...)
#endif

//================================================================================
// Publics
//================================================================================
void dm_init(void) {
    cluster_dm_core_idx = snrt_cluster_dm_core_idx();
    // create a data mover instance
    if (snrt_is_dm_core()) {
#ifdef DM_USE_GLOBAL_CLINT
        snrt_interrupt_enable(IRQ_M_SOFT);
#else
        snrt_interrupt_enable(IRQ_M_CLUSTER);
#endif
        dm_p = (dm_t *)snrt_l1alloc(sizeof(dm_t));
        snrt_memset((void *)dm_p, 0, sizeof(dm_t));
        dm_p_global = dm_p;
    } else {
        while (!dm_p_global)
            ;
        dm_p = dm_p_global;
    }
}

void dm_main(void) {
    volatile dm_task_t *t;
    uint32_t do_exit = 0;
    uint32_t cluster_core_idx = snrt_cluster_core_idx();

    DM_PRINTF(10, "enter main\n");

    while (!do_exit) {
        /// New transaction to issue?
        if (dm_p->queue_fill) {
            // wait until DMA is ready
            while (__builtin_sdma_stat(DM_STATUS_WOULD_BLOCK))
                ;

            t = &dm_p->queue[dm_p->queue_back];

            if (t->twod) {
                DM_PRINTF(10, "start twod\n");
                __builtin_sdma_start_twod(t->src, t->dst, t->size, t->sstrd,
                                          t->dstrd, t->nreps, t->cfg);
            } else {
                DM_PRINTF(10, "start oned\n");
                __builtin_sdma_start_oned(t->src, t->dst, t->size, t->cfg);
            }

            // bump
            dm_p->queue_back = (dm_p->queue_back + 1) % DM_TASK_QUEUE_SIZE;
            __atomic_add_fetch(&dm_p->queue_fill, -1, __ATOMIC_RELAXED);
        }

        /// any STAT request pending?
        if (dm_p->stat_q) {
            switch (dm_p->stat_q) {
                case STAT_WAIT_IDLE:
                    // check status and set pvalid if DMA is idle and clear
                    // request
                    if (__builtin_sdma_stat(DM_STATUS_BUSY) == 0) {
                        DM_PRINTF(50, "idle\n");
                        dm_p->stat_pvalid = 1;
                        dm_p->stat_q = 0;
                    }
                    break;
                case STAT_EXIT:
                    do_exit = 1;
                    break;
                case STAT_READY:
                    DM_PRINTF(50, "ready\n");
                    dm_p->stat_pvalid = 1;
                    dm_p->stat_q = 0;
                    break;
            }
        }

        // sleep if queue is empty and no stats pending
        if (!dm_p->queue_fill && !dm_p->stat_q) {
            wfi_dm(cluster_core_idx);
        }
    }
    DM_PRINTF(10, "dm: exit\n");
#ifdef DM_USE_GLOBAL_CLINT
    snrt_interrupt_disable(IRQ_M_SOFT);
#else
    snrt_interrupt_disable(IRQ_M_CLUSTER);
#endif
    return;
}

void dm_memcpy_async(void *dest, const void *src, size_t n) {
    uint32_t s;
    volatile dm_task_t *t;

    DM_PRINTF(10, "dm_memcpy_async %#x -> %#x size %d\n", src, dest,
              (uint32_t)n);

    // poll queue size
    do {
        s = __atomic_load_n(&dm_p->queue_fill, __ATOMIC_RELAXED);
    } while (s >= DM_TASK_QUEUE_SIZE);
    _dm_mtx_lock();

    // insert
    t = &dm_p->queue[dm_p->queue_front];
    t->src = (uint64_t)src;
    t->dst = (uint64_t)dest;
    t->size = (uint32_t)n;
    t->twod = 0;
    t->cfg = 0;

    // bump
    __atomic_add_fetch(&dm_p->queue_fill, 1, __ATOMIC_RELAXED);
    dm_p->queue_front = (dm_p->queue_front + 1) % DM_TASK_QUEUE_SIZE;

    _dm_mtx_release();
}

void dm_memcpy2d_async(uint64_t src, uint64_t dst, uint32_t size,
                       uint32_t sstrd, uint32_t dstrd, uint32_t nreps,
                       uint32_t cfg) {
    uint32_t s;
    volatile dm_task_t *t;

    DM_PRINTF(10, "dm_memcpy2d_async %#x -> %#x size %d\n", src, dst,
              (uint32_t)size);

    // poll queue size
    do {
        s = __atomic_load_n(&dm_p->queue_fill, __ATOMIC_RELAXED);
    } while (s >= DM_TASK_QUEUE_SIZE);
    _dm_mtx_lock();

    // insert
    t = &dm_p->queue[dm_p->queue_front];
    t->src = src;
    t->dst = dst;
    t->size = size;
    t->sstrd = sstrd;
    t->dstrd = dstrd;
    t->nreps = nreps;
    t->twod = 1;
    t->cfg = cfg;

    // bump
    __atomic_add_fetch(&dm_p->queue_fill, 1, __ATOMIC_RELAXED);
    dm_p->queue_front = (dm_p->queue_front + 1) % DM_TASK_QUEUE_SIZE;

    _dm_mtx_release();
}

void dm_start(void) { wake_dm(); }

void dm_wait(void) {
    uint32_t s;

    // signal data mover
    wake_dm();

    // first, wait for the dm queue to be empty and no request be pending
    do {
        s = __atomic_load_n(&dm_p->queue_fill, __ATOMIC_RELAXED);
    } while (s != 0);
    while (dm_p->stat_q)
        ;

    // then, issue the STAT_WAIT_IDLE request so the DM core polls for the DMA
    // to be idle
    _dm_mtx_lock();
    dm_p->stat_pvalid = 0;
    // this is the request
    dm_p->stat_q = STAT_WAIT_IDLE;
    // signal data mover
    wake_dm();
    // whenever stat_pvalid is non-zero, the DMA has completed all transfers
    while (!dm_p->stat_pvalid)
        ;
    _dm_mtx_release();
}

void dm_exit(void) {
    dm_p->stat_q = STAT_EXIT;
    // signal data mover
    wake_dm();
}

void dm_wait_ready(void) {
    _dm_mtx_lock();
    dm_p->stat_pvalid = 0;
    dm_p->stat_q = STAT_READY;
    wake_dm();
    while (!dm_p->stat_pvalid)
        ;
    _dm_mtx_release();
}

//================================================================================
// private
//================================================================================

#ifdef DM_USE_GLOBAL_CLINT
static void wfi_dm(uint32_t cluster_core_idx) {
    (void)cluster_core_idx;
    snrt_int_sw_poll();
}
static void wake_dm(void) {
    uint32_t basehart = snrt_cluster_core_base_hartid();
    snrt_int_sw_set(basehart + cluster_dm_core_idx);
}
#else
static void wfi_dm(uint32_t cluster_core_idx) {
    __atomic_add_fetch(&dm_p->dm_wfi, 1, __ATOMIC_RELAXED);
    snrt_wfi();
    snrt_int_cluster_clr(1 << cluster_core_idx);
    __atomic_add_fetch(&dm_p->dm_wfi, -1, __ATOMIC_RELAXED);
}
static void wake_dm(void) {
    // wait for DM to sleep before sending wakeup
    while (!__atomic_load_n(&dm_p->dm_wfi, __ATOMIC_RELAXED))
        ;
    snrt_int_cluster_set(1 << snrt_cluster_dm_core_idx());
}
#endif  // #ifdef DM_USE_GLOBAL_CLINT
