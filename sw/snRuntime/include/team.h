// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#pragma once
#include "snrt.h"

extern __thread struct snrt_team *_snrt_team_current;
extern __thread uint32_t _snrt_core_idx;
extern const uint32_t _snrt_team_size;
