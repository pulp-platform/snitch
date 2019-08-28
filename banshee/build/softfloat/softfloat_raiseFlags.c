#include "platform.h"
#include "softfloat.h"

/*----------------------------------------------------------------------------
| Raises the exceptions specified by 'flags'.  Floating-point traps can be
| defined here if desired.  It is currently not possible for such a trap
| to substitute a result value.  If traps are not implemented, this routine
| should be simply 'softfloat_exceptionFlags |= flags;'.
*----------------------------------------------------------------------------*/
void softfloat_raiseFlags( uint_fast8_t flags )
{
    softfloat_exceptionFlags |= flags;
}
