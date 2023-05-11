// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// Use cluster interrupts behind the scenes, since we only have one cluster
inline void snrt_int_sw_clear(uint32_t hartid) {
    snrt_int_cluster_clr(1 << hartid);
}
inline void snrt_int_sw_set(uint32_t hartid) {
    snrt_int_cluster_set(1 << hartid);
}
