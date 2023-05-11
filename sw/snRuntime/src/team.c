// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

extern uint32_t snrt_hartid();

extern uint32_t snrt_global_core_base_hartid();

extern uint32_t snrt_global_core_idx();

extern uint32_t snrt_global_core_num();

extern uint32_t snrt_cluster_idx();

extern uint32_t snrt_cluster_num();

extern uint32_t snrt_cluster_core_idx();

extern uint32_t snrt_cluster_core_num();

extern uint32_t snrt_cluster_compute_core_num();

extern int snrt_is_compute_core();

extern int snrt_is_dm_core();

extern uint32_t snrt_cluster_dm_core_num();
