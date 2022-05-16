// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include <stdint.h>
#include <string.h>

/***********************************************************************************
 * MACROS
 ***********************************************************************************/
#define SYS_exit 60
#define SYS_write 64
#define SYS_read 63
#define SYS_wake 1235
#define SYS_cycle 1236

/***********************************************************************************
 * TYPES
 ***********************************************************************************/

/**
 * @brief Ring buffer for simple communication from accelerator to host.
 * @tail: Points to the element in `data` which is read next
 * @head: Points to the element in `data` which is written next
 * @size: Number of elements in `data`. Head and tail pointer wrap at `size`
 * @element_size: Size of each element in bytes
 * @data_p: points to the base of the data buffer in physical address
 * @data_v: points to the base of the data buffer in virtual address space
 */
struct ring_buf {
  uint32_t tail;
  uint64_t data_v;
  uint32_t element_size;
  uint32_t size;
  uint64_t data_p;
  // put accelerator data onto a new cache-line (cva6 specific: 128-bit cache lines)
  uint8_t _pad1[4];
  uint32_t head;
};

/***********************************************************************************
 * DATA
 ***********************************************************************************/
extern volatile struct ring_buf *g_a2h_rb;
extern volatile struct ring_buf *g_a2h_mbox;
extern volatile struct ring_buf *g_h2a_mbox;

/***********************************************************************************
 * INLINES
 ***********************************************************************************/
/**
 * @brief Copy data from `el` in the next free slot in the ring-buffer on the physical addresses
 *
 * @param rb pointer to the ring buffer struct
 * @param el pointer to the data to be copied into the ring buffer
 * @return int 0 on succes, -1 if the buffer is full
 */
static inline int rb_device_put(volatile struct ring_buf *rb, void *el) {
  uint32_t next_head = (rb->head + 1) % rb->size;
  // caught the tail, can't put data
  if (next_head == rb->tail)
    return -1;
  for (uint32_t i = 0; i < rb->element_size; i++)
    *((uint8_t *)rb->data_p + rb->element_size * rb->head + i) = *((uint8_t *)el + i);
  rb->head = next_head;
  return 0;
}
/**
 * @brief Pop element from ring buffer on virtual addresses
 *
 * @param rb pointer to ring buffer struct
 * @param el pointer to where element is copied to
 * @return 0 on success, -1 if no element could be popped
 */
static inline int rb_host_get(volatile struct ring_buf *rb, void *el) {
  // caught the head, can't get data
  if (rb->tail == rb->head)
    return -1;
  for (uint32_t i = 0; i < rb->element_size; i++)
    *((uint8_t *)el + i) = *((uint8_t *)rb->data_v + rb->element_size * rb->tail + i);
  rb->tail = (rb->tail + 1) % rb->size;
  return 0;
}

/**
 * @brief Copy data from `el` in the next free slot in the ring-buffer on the virtual addresses
 *
 * @param rb pointer to the ring buffer struct
 * @param el pointer to the data to be copied into the ring buffer
 * @return int 0 on succes, -1 if the buffer is full
 */
static inline int rb_host_put(volatile struct ring_buf *rb, void *el) {
  uint32_t next_head = (rb->head + 1) % rb->size;
  // caught the tail, can't put data
  if (next_head == rb->tail)
    return -1;
  for (uint32_t i = 0; i < rb->element_size; i++)
    *((uint8_t *)rb->data_v + rb->element_size * rb->head + i) = *((uint8_t *)el + i);
  rb->head = next_head;
  return 0;
}
/**
 * @brief Pop element from ring buffer on physicl addresses
 *
 * @param rb pointer to ring buffer struct
 * @param el pointer to where element is copied to
 * @return 0 on success, -1 if no element could be popped
 */
static inline int rb_device_get(volatile struct ring_buf *rb, void *el) {
  // caught the head, can't get data
  if (rb->tail == rb->head)
    return -1;
  for (uint32_t i = 0; i < rb->element_size; i++)
    *((uint8_t *)el + i) = *((uint8_t *)rb->data_p + rb->element_size * rb->tail + i);
  rb->tail = (rb->tail + 1) % rb->size;
  return 0;
}
/**
 * @brief Init the ring buffer. See `struct ring_buf` for details
 */
static inline void rb_init(volatile struct ring_buf *rb, uint64_t size, uint64_t element_size) {
  rb->tail = 0;
  rb->head = 0;
  rb->size = size;
  rb->element_size = element_size;
}

/**
 * @brief Holds physical addresses of the shared L3
 * @a2h_rb: accelerator to host ring buffer
 * @head: base of heap memory
 */
struct l3_layout {
  uint32_t a2h_rb;
  uint32_t a2h_mbox;
  uint32_t h2a_mbox;
  uint32_t heap;
};

/***********************************************************************************
 * PUBLICS
 ***********************************************************************************/
int syscall(uint64_t which, uint64_t arg0, uint64_t arg1, uint64_t arg2, uint64_t arg3,
            uint64_t arg4);
void csleep(uint32_t cycles);
void snrt_hero_exit(int code);
/**
 * @brief Blocking mailbox read access
 */
int snitch_mbox_read(uint32_t *buffer, size_t n_words);
/**
 * @brief Non-Blocking mailbox read access. Return 1 on success, 0 on fail
 */
int snitch_mbox_try_read(uint32_t *buffer);
/**
 * @brief Blocking mailbox write access
 */
int snitch_mbox_write(uint32_t word);
