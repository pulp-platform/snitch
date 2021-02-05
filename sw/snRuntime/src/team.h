// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#pragma once
#include "snrt.h"

extern __thread struct snrt_team *_snrt_team_current;
extern const uint32_t _snrt_team_size;

struct snrt_team {
    /// Pointer to the root team description of this cluster.
    struct snrt_team_root *root;
};

struct snrt_mailbox {
    /// A common location to perform an atomic barrier on.
    size_t barrier;
    /// Pointer to the data being exchanged.
    void *ptr;
    /// Length of the data being exchanged.
    size_t len;
};

struct snrt_team_root {
    struct snrt_team base;
    const void *device_tree;
    uint32_t global_core_base_hartid;
    uint32_t global_core_num;
    uint32_t cluster_idx;
    uint32_t cluster_num;
    uint32_t cluster_core_base_hartid;
    uint32_t cluster_core_num;
    snrt_slice_t global_mem;
    snrt_slice_t cluster_mem;
    struct snrt_mailbox *global_mailbox;
    struct snrt_mailbox *cluster_mailbox;
};
