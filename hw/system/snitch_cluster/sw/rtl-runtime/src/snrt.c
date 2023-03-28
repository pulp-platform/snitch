// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "snrt.h"

// Empty printf implementation
extern int printf(const char* format, ...);

#include "alloc.c"
#include "cls.c"
#include "cluster_interrupts.c"
#include "dm.c"
#include "dma.c"
#include "eu.c"
#include "kmp.c"
#include "omp.c"
#include "snitch_cluster_start.c"
#include "sync.c"
#include "team.c"
