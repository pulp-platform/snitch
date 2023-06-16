// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "snitch_cluster_addrmap.h"
#include "snitch_cluster_cfg.h"
#include "snitch_cluster_peripheral.h"

// Hardware parameters
#define SNRT_BASE_HARTID CFG_CLUSTER_BASE_HARTID
#define SNRT_CLUSTER_CORE_NUM CFG_CLUSTER_NR_CORES
#define SNRT_CLUSTER_NUM 1
#define SNRT_CLUSTER_DM_CORE_NUM 1
#define SNRT_TCDM_START_ADDR CLUSTER_TCDM_BASE_ADDR
#define SNRT_TCDM_SIZE (CLUSTER_PERIPH_BASE_ADDR - CLUSTER_TCDM_BASE_ADDR)
#define SNRT_CLUSTER_OFFSET 0
#define SNRT_CLUSTER_HW_BARRIER_ADDR \
    (CLUSTER_PERIPH_BASE_ADDR + SNITCH_CLUSTER_PERIPHERAL_HW_BARRIER_REG_OFFSET)

// Software configuration
#define SNRT_LOG2_STACK_SIZE 10
