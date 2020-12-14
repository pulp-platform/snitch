// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <stdint.h>
#include "platform.h"
#include "specialize.h"

/*----------------------------------------------------------------------------
| Converts the common NaN pointed to by 'aPtr' into a 64-bit floating-point
| NaN, and returns the bit pattern of this value as an unsigned integer.
*----------------------------------------------------------------------------*/
uint_fast64_t softfloat_commonNaNToF64UI( const struct commonNaN *aPtr )
{
    return
        (uint_fast64_t) aPtr->sign<<63 | UINT64_C( 0x7FF8000000000000 )
            | aPtr->v64>>12;
}
