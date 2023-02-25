// Copyright 2022 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "snrt.h"

// Wraps statically linked `snrt_global_core_idx()` function
// as external linkage is required to call it from `start_snitch.S`
uint32_t _snrt_global_core_idx() {
    return snrt_global_core_idx();
}
