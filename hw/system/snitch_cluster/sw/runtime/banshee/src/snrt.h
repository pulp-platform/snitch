// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#pragma once

#include <stddef.h>
#include <stdint.h>

// Snitch cluster specific
#include "banshee_snitch_cluster_defs.h"
#include "snitch_cluster_memory.h"

// Forward declarations
#include "alloc_decls.h"
#include "cls_decls.h"
#include "riscv_decls.h"
#include "sync_decls.h"
#include "team_decls.h"

// Implementation
#include "alloc.h"
#include "cls.h"
#include "cluster_interrupts.h"
#include "dm.h"
#include "dma.h"
#include "eu.h"
#include "perf_cnt.h"
#include "printf.h"
#include "riscv.h"
#include "ssr.h"
#include "sync.h"
#include "team.h"
