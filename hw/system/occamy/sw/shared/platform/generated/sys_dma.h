// Copyright 2022 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// Generated register defines for idma_reg64_frontend

#ifndef _IDMA_REG64_FRONTEND_REG_DEFS_
#define _IDMA_REG64_FRONTEND_REG_DEFS_

#ifdef __cplusplus
extern "C" {
#endif
// Register width
#define IDMA_REG64_FRONTEND_PARAM_REG_WIDTH 64

// Source Address
#define IDMA_REG64_FRONTEND_SRC_ADDR_REG_OFFSET 0x0

// Destination Address
#define IDMA_REG64_FRONTEND_DST_ADDR_REG_OFFSET 0x8

// Number of bytes
#define IDMA_REG64_FRONTEND_NUM_BYTES_REG_OFFSET 0x10

// Configuration Register for DMA settings
#define IDMA_REG64_FRONTEND_CONF_REG_OFFSET 0x18
#define IDMA_REG64_FRONTEND_CONF_DECOUPLE_BIT 0
#define IDMA_REG64_FRONTEND_CONF_DEBURST_BIT 1
#define IDMA_REG64_FRONTEND_CONF_SERIALIZE_BIT 2

// DMA Status
#define IDMA_REG64_FRONTEND_STATUS_REG_OFFSET 0x20
#define IDMA_REG64_FRONTEND_STATUS_BUSY_BIT 0

// Next ID, launches transfer, returns 0 if transfer not set up properly.
#define IDMA_REG64_FRONTEND_NEXT_ID_REG_OFFSET 0x28

// Get ID of finished transactions.
#define IDMA_REG64_FRONTEND_DONE_REG_OFFSET 0x30

#ifdef __cplusplus
}  // extern "C"
#endif
#endif  // _IDMA_REG64_FRONTEND_REG_DEFS_
// End generated register defines for idma_reg64_frontend

#include <stdint.h>

#include "occamy_addrmap.h"

#define IDMA_SRC_ADDR \
    (SYS_IDMA_CFG_BASE_ADDR + IDMA_REG64_FRONTEND_SRC_ADDR_REG_OFFSET)
#define IDMA_DST_ADDR \
    (SYS_IDMA_CFG_BASE_ADDR + IDMA_REG64_FRONTEND_DST_ADDR_REG_OFFSET)
#define IDMA_NUMBYTES_ADDR \
    (SYS_IDMA_CFG_BASE_ADDR + IDMA_REG64_FRONTEND_NUM_BYTES_REG_OFFSET)
#define IDMA_CONF_ADDR \
    (SYS_IDMA_CFG_BASE_ADDR + IDMA_REG64_FRONTEND_CONF_REG_OFFSET)
#define IDMA_STATUS_ADDR \
    (SYS_IDMA_CFG_BASE_ADDR + IDMA_REG64_FRONTEND_STATUS_REG_OFFSET)
#define IDMA_NEXTID_ADDR \
    (SYS_IDMA_CFG_BASE_ADDR + IDMA_REG64_FRONTEND_NEXT_ID_REG_OFFSET)
#define IDMA_DONE_ADDR \
    (SYS_IDMA_CFG_BASE_ADDR + IDMA_REG64_FRONTEND_DONE_REG_OFFSET)

#define IDMA_CONF_DECOUPLE 0
#define IDMA_CONF_DEBURST 0
#define IDMA_CONF_SERIALIZE 0

volatile uint64_t *dma_src = (volatile uint64_t *)IDMA_SRC_ADDR;
volatile uint64_t *dma_dst = (volatile uint64_t *)IDMA_DST_ADDR;
volatile uint64_t *dma_num_bytes = (volatile uint64_t *)IDMA_NUMBYTES_ADDR;
volatile uint64_t *dma_conf = (volatile uint64_t *)IDMA_CONF_ADDR;
volatile uint64_t *dma_status = (volatile uint64_t *)IDMA_STATUS_ADDR;
volatile uint64_t *dma_nextid = (volatile uint64_t *)IDMA_NEXTID_ADDR;
volatile uint64_t *dma_done = (volatile uint64_t *)IDMA_DONE_ADDR;

static inline uint64_t sys_dma_memcpy(uint64_t dst, uint64_t src,
                                      uint64_t size) {
    *dma_src = (uint64_t)src;
    *dma_dst = (uint64_t)dst;
    *dma_num_bytes = size;
    *dma_conf = (IDMA_CONF_DECOUPLE << IDMA_REG64_FRONTEND_CONF_DECOUPLE_BIT) |
                (IDMA_CONF_DEBURST << IDMA_REG64_FRONTEND_CONF_DEBURST_BIT) |
                (IDMA_CONF_SERIALIZE << IDMA_REG64_FRONTEND_CONF_SERIALIZE_BIT);
    return *dma_nextid;
}

static inline void sys_dma_blk_memcpy(uint64_t dst, uint64_t src,
                                      uint64_t size) {
    volatile uint64_t tf_id = sys_dma_memcpy(dst, src, size);

    while (*dma_done != tf_id) {
        asm volatile("nop");
    }
}
