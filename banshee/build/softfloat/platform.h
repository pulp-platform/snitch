#define LITTLEENDIAN 1

#define INLINE inline __attribute__((always_inline))
#define THREAD_LOCAL _Thread_local

#define SOFTFLOAT_BUILTIN_CLZ 1
#define SOFTFLOAT_INTRINSIC_INT128 1
#include "opts-GCC.h"
