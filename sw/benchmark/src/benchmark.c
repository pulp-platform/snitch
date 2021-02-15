// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include "benchmark.h"

#include "../../vendor/riscv-opcodes/encoding.h"

size_t benchmark_get_cycle() { return read_csr(mcycle); }
