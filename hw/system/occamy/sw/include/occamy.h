// Copyright 2022 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#pragma once

#include "occamy_addrmap.h"
#include "occamy_cfg.h"

#define N_CLOCKS 3
#define CVA6_HARTID 0

#define N_CLUSTERS (N_QUADS * N_CLUSTERS_PER_QUAD)
#define N_SNITCHES (N_CLUSTERS * N_CORES_PER_CLUSTER)
#define N_HARTS (N_SNITCHES + 1)

static const float rtc_period = 30517.58;      // ns
static const float rtc_freq = 1 / rtc_period;  // GHz

static const float freq_meter_ref_freqs[N_CLOCKS] = {
    rtc_freq,  // 0.1,
    rtc_freq,  // 0.05,
    rtc_freq   // 0.5
};             // GHz
