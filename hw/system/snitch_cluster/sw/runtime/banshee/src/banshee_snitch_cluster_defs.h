// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "snitch_cluster_defs.h"
// Banshee does not use the `cluster_base_hartid` parameter
// so it must be tied to 0. We override the definition generated
// from the cluster configuration file.
#undef SNRT_BASE_HARTID
#define SNRT_BASE_HARTID 0
