// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "runtime.h"
#define SEM_ADD 0x100000
#include <stdatomic.h>
typedef volatile uint32_t * sem_t;

void init_sem(sem_t semaphore, uint32_t val);
void wait_sem(sem_t semaphore, uint32_t val);
void signal_sem(sem_t semaphore, uint32_t val);

int main(uint32_t core_id, uint32_t core_num) {
    sem_t sem = (sem_t)SEM_ADD;
    volatile int32_t *p = (int32_t *)0x11000;
    *p = 0;
    if (core_id == 0) {
        init_sem(sem, 1);
    }
    pulp_barrier();
    for (unsigned int i = 0; i < 4000; i++) {
        wait_sem(sem, 1);
        switch(core_id%2) {
            case 0: *p = *p + 1;
                    break;
            case 1: *p = *p - 1;
                    break;
        }
        signal_sem(sem, 1);
    }
    pulp_barrier();
    /*
    volatile uint8_t *p_cluster_id = (uint8_t *)0x40000050;
    switch(*p_cluster_id) {
        case 0: {
                    volatile uint8_t *p_tcm_1 = (uint8_t *)0x11000;
                    *p_tcm_1 = 23;
                } break;
        case 1: {
                    volatile uint8_t *p_tcm_1 = (uint8_t *)0x1000;
                    volatile uint8_t *p_tcm_2 = (uint8_t *)0x5FFFF;
                    while (*p_tcm_1 != 23 || *p_tcm_2 != 42) {}
                } break;
        default: {
                     volatile uint8_t *p_tcm_2 = (uint8_t *)0x2FFFF;
                     *p_tcm_2 = 42;
                 } break;
    }
    */
    return *p;
}

void init_sem(sem_t semaphore, uint32_t val) {
    __atomic_store_n(semaphore, val, __ATOMIC_RELAXED);
}

void signal_sem(sem_t semaphore, uint32_t val) {
    __atomic_store_n(semaphore + 1, val, __ATOMIC_RELAXED);
}

void wait_sem(sem_t semaphore, uint32_t val) {
    __atomic_store_n(semaphore + 2, val, __ATOMIC_RELAXED);
}
