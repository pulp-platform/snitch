
#pragma once

#include "interface.h"

/*!
@ingroup PARALLEL
The type for a microtask which gets passed to @ref __kmpc_fork_call().
The arguments to the outlined function are
@param global_tid the global thread identity of the thread executing the
function.
@param bound_tid  the local identity of the thread executing the function
@param ... pointers to shared variables accessed by the function.
*/
typedef void (*kmpc_micro)(kmp_int32 *global_tid, kmp_int32 *bound_tid, ...);

////////////////////////////////////////////////////////////////////////////////
// debug
////////////////////////////////////////////////////////////////////////////////
#define KMP_DEBUG_LEVEL 100

#ifdef KMP_DEBUG_LEVEL
    #include "printf.h"
    #include "encoding.h"
    #define _KMP_PRINTF(...) if(1) { printf( "[kmc] "__VA_ARGS__ ); }
    #define KMP_PRINTF(d, ...)                                            \
    if (KMP_DEBUG_LEVEL >= d) {                                         \
        _KMP_PRINTF(__VA_ARGS__);                                         \
    }
#else
    #define KMP_PRINTF(d, ...)
#endif
