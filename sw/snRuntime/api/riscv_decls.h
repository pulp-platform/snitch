// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "encoding.h"

static inline void snrt_wfi();

static inline uint32_t mcycle();

inline void snrt_interrupt_enable(uint32_t irq);

inline void snrt_interrupt_disable(uint32_t irq);

inline void snrt_interrupt_global_enable(void);

inline void snrt_interrupt_global_disable(void);
