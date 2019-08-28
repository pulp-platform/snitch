#include <stdbool.h>
#include <stdint.h>
#include "platform.h"
#include "internals.h"
#include "specialize.h"
#include "softfloat.h"

/*----------------------------------------------------------------------------
| Interpreting 'uiA' and 'uiB' as the bit patterns of two 64-bit floating-
| point values, at least one of which is a NaN, returns the bit pattern of
| the combined NaN result.  If either 'uiA' or 'uiB' has the pattern of a
| signaling NaN, the invalid exception is raised.
*----------------------------------------------------------------------------*/
uint_fast64_t softfloat_propagateNaNF64UI( uint_fast64_t uiA, uint_fast64_t uiB )
{
    if ( softfloat_isSigNaNF64UI( uiA ) || softfloat_isSigNaNF64UI( uiB ) ) {
        softfloat_raiseFlags( softfloat_flag_invalid );
    }
    return defaultNaNF64UI;
}
