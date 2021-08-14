// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "runtime.h"

#define EMPTY_COUNT_ADD 0x100000
#define FULL_COUNT_ADD 0x10000c
#define USE_QUEUE_ADD 0x100018
#define CLUSTER_ID_ADD 0x40000050
#define CLUSTER_NUM_ADD 0x40000048
#define PRODUCE_ADD 0x10000
#define CONSUME_ADD 0x0
#define FIFO_SIZE 100
#define FENCE_ADD 0x100024
#define NUMBER_DATA_PRODUCE_PER_CORE 50
#define TARGET_ADD 0x10000

#include <stdatomic.h>

typedef volatile uint32_t *sem_t;

typedef struct {
    volatile uint32_t *head;
    volatile uint32_t *tail;
    volatile uint32_t *buffer;
} fifo_t;

fifo_t fifo;

sem_t empty_count = (sem_t)EMPTY_COUNT_ADD;
sem_t full_count = (sem_t)FULL_COUNT_ADD;
sem_t use_queue = (sem_t)USE_QUEUE_ADD;

volatile uint8_t *cluster_id = (uint8_t *)CLUSTER_ID_ADD;
volatile uint8_t *cluster_num = (uint8_t *)CLUSTER_NUM_ADD;
volatile uint32_t *fence = (uint32_t *)FENCE_ADD;

void init_sem(sem_t semaphore, uint32_t val);
void wait_sem(sem_t semaphore, uint32_t val);
void signal_sem(sem_t semaphore, uint32_t val);

void produce(uint32_t core_id);
void consume(uint32_t core_id);

void set_fence(uint32_t val);
uint32_t wait_fence();

void push_fifo(uint32_t val);
uint32_t pop_fifo();

int main(uint32_t core_id, uint32_t core_num) {
    set_fence(core_num * *cluster_num);
    switch (*cluster_id) {
        case 0:
            consume(core_id);
            break;
        case 1:
            produce(core_id);
            return 0;
    }

    // Check the consumed data
    pulp_barrier();
    if (core_id) {
        return 0;
    } else {
        uint32_t res = 0;
        uint32_t *target = (uint32_t *)TARGET_ADD;
        for (unsigned int i = 0; i < core_num; i++) {
            res += target[i];
        }
        return (res == (core_num * NUMBER_DATA_PRODUCE_PER_CORE *
                        (NUMBER_DATA_PRODUCE_PER_CORE - 1)) /
                           2)
                   ? 0
                   : 1;
    }
}

void produce(uint32_t core_id) {
    fifo = (fifo_t){.head = (uint32_t *)PRODUCE_ADD + 0x4,
                    .tail = (uint32_t *)PRODUCE_ADD + 0x8,
                    .buffer = (uint32_t *)PRODUCE_ADD + 0xc};
    // Initialize the synchronization variables
    if (core_id == 0) {
        *(fifo.head) = 0;
        *(fifo.tail) = 0;
        init_sem(empty_count, FIFO_SIZE);
        init_sem(full_count, 0);
        init_sem(use_queue, 1);
    }
    wait_fence();

    // Produce the data
    for (unsigned int i = 0; i < NUMBER_DATA_PRODUCE_PER_CORE; i++) {
        wait_sem(empty_count, 1);
        wait_sem(use_queue, 1);
        push_fifo(i);
        signal_sem(use_queue, 1);
        signal_sem(full_count, 1);
    }
}

void consume(uint32_t core_id) {
    fifo = (fifo_t){.head = (uint32_t *)CONSUME_ADD + 0x4,
                    .tail = (uint32_t *)CONSUME_ADD + 0x8,
                    .buffer = (uint32_t *)CONSUME_ADD + 0xc};

    uint32_t *target = (uint32_t *)(TARGET_ADD + 4 * core_id);
    wait_fence();

    // Consume the data
    for (unsigned int i = 0; i < NUMBER_DATA_PRODUCE_PER_CORE; i++) {
        wait_sem(full_count, 1);
        wait_sem(use_queue, 1);
        *target = pop_fifo() + *target;
        signal_sem(use_queue, 1);
        signal_sem(empty_count, 1);
    }
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

void init_sem(sem_t semaphore, uint32_t val) { *semaphore = val; }

void signal_sem(sem_t semaphore, uint32_t val) { *(semaphore + 1) = val; }

void wait_sem(sem_t semaphore, uint32_t val) { *(semaphore + 2) = val; }

void set_fence(uint32_t val) { *fence = val; }

uint32_t wait_fence() { return *fence; }
