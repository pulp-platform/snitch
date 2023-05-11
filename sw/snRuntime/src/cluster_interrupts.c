// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

extern void snrt_int_cluster_set(uint32_t mask);

extern void snrt_int_cluster_clr(uint32_t mask);

extern void snrt_int_clr_mcip();

extern void snrt_int_set_mcip();
