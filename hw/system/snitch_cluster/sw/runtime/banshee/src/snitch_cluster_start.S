# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

#define SNRT_INIT_INT_REGS
#define SNRT_INIT_FP_REGS
#define SNRT_INIT_GP
#define SNRT_INIT_CORE_INFO
#define SNRT_INIT_CLS
#define SNRT_INIT_STACK
#define SNRT_INIT_TLS
#define SNRT_CRT0_PARK

#include "snitch_cluster_defs.h"
#include "start.S"
