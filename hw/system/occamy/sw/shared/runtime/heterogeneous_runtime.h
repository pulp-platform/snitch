// Copyright 2022 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <stdint.h>

#include "occamy_memory_map.h"

// *Note*: to ensure that the usr_data field is at the same offset
// in the host and device (resp. 64b and 32b architectures)
// usr_data is an explicitly-sized integer field instead of a pointer
typedef struct {
    volatile uint32_t lock;
    volatile uint32_t usr_data_ptr;
} comm_buffer_t;

/**************************/
/* Quadrant configuration */
/**************************/

// Configure RO cache address range
inline void configure_read_only_cache_addr_rule(uint32_t quad_idx,
                                                uint32_t rule_idx,
                                                uint64_t start_addr,
                                                uint64_t end_addr) {
    volatile uint64_t* rule_ptr =
        quad_cfg_ro_cache_addr_rule_ptr(quad_idx, rule_idx);
    *(rule_ptr) = start_addr;
    *(rule_ptr + 1) = end_addr;
}

// Enable RO cache
inline void enable_read_only_cache(uint32_t quad_idx) {
    *(quad_cfg_ro_cache_enable_ptr(quad_idx)) = 1;
}
