// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include "snrt.h"

/**
 * @brief Synchronize the integer and float pipelines by creating a dependency in the scoreboard on
 * `tmp`
 *
 */
void snrt_fpu_fence() {
  unsigned tmp;
  asm volatile("fmv.x.w %0, fa0\n"
               "mv      %0, %0"
               : "+r"(tmp)::);

}
