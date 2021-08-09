// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include "snrt.h"

extern void _snrt_cluster_barrier();
extern void snrt_cluster_barrier();
extern void snrt_global_barrier();

void snrt_barrier() { _snrt_cluster_barrier(); }
