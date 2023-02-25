// Copyright 2022 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <stdint.h>

static inline void set_sw_interrupt(uint32_t hartid);

void delay_ns(uint64_t delay);

static inline volatile uint32_t* get_shared_lock();

static inline void wait_sw_interrupt();

static inline void clear_sw_interrupt(uint32_t hartid);
