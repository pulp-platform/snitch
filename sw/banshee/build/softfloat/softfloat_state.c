// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <stdint.h>
#include "platform.h"
#include "internals.h"
#include "specialize.h"
#include "softfloat.h"

THREAD_LOCAL uint_fast8_t softfloat_roundingMode = softfloat_round_near_even;
THREAD_LOCAL uint_fast8_t softfloat_detectTininess = init_detectTininess;
THREAD_LOCAL uint_fast8_t softfloat_exceptionFlags = 0;

/*----------------------------------------------------------------------------
| Accessors for thread local storage from Rust.
| Rust support tracking issue: https://github.com/rust-lang/rust/issues/29594
*----------------------------------------------------------------------------*/

uint_fast8_t softfloat_getFlags()
{
    return softfloat_exceptionFlags;
}

void softfloat_setFlags( uint_fast8_t flags )
{
    softfloat_exceptionFlags = flags;
}

uint_fast8_t softfloat_getRoundingMode()
{
    return softfloat_roundingMode;
}

void softfloat_setRoundingMode( uint_fast8_t mode )
{
    softfloat_roundingMode = mode;
}
