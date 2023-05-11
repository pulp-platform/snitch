// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

extern uint32_t snrt_l1_start_addr();

extern uint32_t snrt_l1_end_addr();

extern volatile uint32_t* snrt_cluster_clint_set_ptr();

extern volatile uint32_t* snrt_cluster_clint_clr_ptr();

extern uint32_t snrt_cluster_hw_barrier_addr();
