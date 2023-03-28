// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#pragma once

#include <stddef.h>
#include <stdint.h>

// Snitch cluster specific
#include "snitch_cluster_defs.h"
#include "snitch_cluster_memory.h"

// Forward declarations
#include "alloc_decls.h"
#include "cls_decls.h"
#include "riscv_decls.h"
#include "start_decls.h"
#include "sync_decls.h"
#include "team_decls.h"

// Empty printf implementation
inline int printf(const char* format, ...) { return 0; };

// Implementation
#include "alloc.h"
#include "cls.h"
#include "cluster_interrupts.h"
#include "dm.h"
#include "dma.h"
#include "eu.h"
#include "kmp.h"
#include "omp.h"
#include "perf_cnt.h"
#include "riscv.h"
#include "snitch_cluster_global_interrupts.h"
#include "ssr.h"
#include "sync.h"
#include "team.h"
