// Copyright 2022 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// *Note*: to ensure that the usr_data field is at the same offset
// in the host and device (resp. 64b and 32b architectures)
// usr_data is an explicitly-sized integer field instead of a pointer
typedef struct {
    uint32_t lock;
    uint64_t usr_data_ptr;
} comm_buffer_t;
