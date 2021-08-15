// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "runtime.h"

#define EMPTY_COUNT_ADD 0x100000
#define FULL_COUNT_ADD 0x10000c
#define USE_QUEUE_ADD 0x100018
#define CLUSTER_ID_ADD 0x40000050
#define PRODUCE_ADD 0x10000
#define CONSUME_ADD 0x0
#define FIFO_SIZE 2
#define FENCE_ADD 0x100024

#include <stdatomic.h>

typedef volatile uint32_t * sem_t;

typedef struct
{
    volatile uint32_t * head;
    volatile uint32_t * tail;
    volatile uint32_t * buffer;
} fifo_t;

fifo_t fifo;

sem_t empty_count = (sem_t)EMPTY_COUNT_ADD;
sem_t full_count = (sem_t)FULL_COUNT_ADD;
sem_t use_queue = (sem_t)USE_QUEUE_ADD;

volatile uint8_t *cluster_id = (uint8_t *)CLUSTER_ID_ADD;
volatile uint32_t * fence = (uint32_t *)FENCE_ADD;

void init_sem(sem_t semaphore, uint32_t val);
void wait_sem(sem_t semaphore, uint32_t val);
void signal_sem(sem_t semaphore, uint32_t val);

void produce();
void consume();

void set_fence(uint32_t val);
uint32_t wait_fence();

void push_fifo(uint32_t val);
uint32_t pop_fifo();

int main(uint32_t core_id, uint32_t core_num) {
    set_fence(20);
    switch(*cluster_id) {
        case 0: produce(core_id);
                break;
        case 1: consume();
                break;
    }
    return 0;
}

void produce(uint32_t core_id) {
    fifo = (fifo_t){
        .head = (uint32_t *)PRODUCE_ADD + 0x4,
        .tail = (uint32_t *)PRODUCE_ADD + 0x8,
        .buffer = (uint32_t *)PRODUCE_ADD + 0xc
    };

    if(core_id == 0) {
        *(fifo.head) = 0;
        *(fifo.tail) = 0;
        init_sem(empty_count, FIFO_SIZE);
        init_sem(full_count, 0);
        init_sem(use_queue, 1);
    }
    wait_fence();
    wait_sem(empty_count, 1);
    wait_sem(use_queue, 1);
    push_fifo(0);
    signal_sem(use_queue, 1);
    signal_sem(full_count, 1);
}

void consume() {
    fifo = (fifo_t){
        .head = (uint32_t *)CONSUME_ADD + 0x4,
        .tail = (uint32_t *)CONSUME_ADD + 0x8,
        .buffer = (uint32_t *)CONSUME_ADD + 0xc
    };
    wait_fence();
    wait_sem(full_count, 1);
    wait_sem(use_queue, 1);
    pop_fifo();
    signal_sem(use_queue, 1);
    signal_sem(empty_count, 1);
}

void push_fifo(uint32_t val) {
    uint32_t head = *(fifo.head);
    fifo.buffer[head] = val;
    *(fifo.head) = (head == FIFO_SIZE - 1) ? 0 : head + 1;
}

uint32_t pop_fifo() {
    uint32_t tail = *(fifo.tail);
    *(fifo.tail) = (tail == FIFO_SIZE - 1) ? 0 : tail + 1;
    return fifo.buffer[tail];
}
/*

    volatile int32_t *p = (int32_t *)0x11000;
    *p = 0;
    if (core_id == 0 & *p_cluster_id == 0) {
        init_sem(sem, 1);
    }

    volatile int x;
    for (int i = 0; i<100000; i++) {
        x = x + 1;
    }

    pulp_barrier();
    for (unsigned int i = 0; i < 400; i++) {
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
    */
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

    /*
    int t = 1;
    while(t != 0) {
        wait_sem(sem, 1);
        t = *p;
        signal_sem(sem, 1);
    }
    for (int i = 0; i<100000; i++) {
        x = x + 1;
    }
    return *p;
}
    */

void init_sem(sem_t semaphore, uint32_t val) {
    *semaphore = val;
}

void signal_sem(sem_t semaphore, uint32_t val) {
    *(semaphore + 1) = val;
}

void wait_sem(sem_t semaphore, uint32_t val) {
    *(semaphore + 2) = val;
}

void set_fence(uint32_t val) {
    *fence = val;
}

uint32_t wait_fence() {
    return *fence;
}
