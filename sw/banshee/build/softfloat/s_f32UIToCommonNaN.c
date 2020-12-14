// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <stdint.h>
#include "platform.h"
#include "specialize.h"
#include "softfloat.h"

/*----------------------------------------------------------------------------
| Assuming 'uiA' has the bit pattern of a 32-bit floating-point NaN, converts
| this NaN to the common NaN form, and stores the resulting common NaN at the
| location pointed to by 'zPtr'.  If the NaN is a signaling NaN, the invalid
| exception is raised.
*----------------------------------------------------------------------------*/
void softfloat_f32UIToCommonNaN( uint_fast32_t uiA, struct commonNaN *zPtr )
{
    if ( softfloat_isSigNaNF32UI( uiA ) ) {
        softfloat_raiseFlags( softfloat_flag_invalid );
    }
    zPtr->sign = uiA>>31;
    zPtr->v64  = (uint_fast64_t) uiA<<41;
    zPtr->v0   = 0;
}
