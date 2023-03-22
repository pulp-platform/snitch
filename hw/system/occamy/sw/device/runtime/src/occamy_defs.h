// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "occamy_base_addr.h"
#include "occamy_cfg.h"
#include "snitch_cluster_peripheral.h"

// Hardware parameters
#define SNRT_BASE_HARTID 1
#define SNRT_CLUSTER_CORE_NUM N_CORES_PER_CLUSTER
#define SNRT_CLUSTER_NUM (N_QUADS * N_CLUSTERS_PER_QUAD)
#define SNRT_CLUSTER_DM_CORE_NUM 1
#define SNRT_TCDM_START_ADDR QUADRANT_0_CLUSTER_0_TCDM_BASE_ADDR
#define SNRT_TCDM_SIZE                       \
    (QUADRANT_0_CLUSTER_0_PERIPH_BASE_ADDR - \
     QUADRANT_0_CLUSTER_0_TCDM_BASE_ADDR)
#define SNRT_CLUSTER_OFFSET 0x40000  // TODO colluca: don't hardcode this
#define SNRT_CLUSTER_HW_BARRIER_ADDR         \
    (QUADRANT_0_CLUSTER_0_PERIPH_BASE_ADDR + \
     SNITCH_CLUSTER_PERIPHERAL_HW_BARRIER_REG_OFFSET)

// Software configuration
#define SNRT_LOG2_STACK_SIZE 10
