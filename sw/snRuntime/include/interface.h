// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#ifndef INTERFACE_H
#define INTERFACE_H

#include <stdint.h>

////////////////////////////////////////////////////////////////////////////////
// kmp specific types
// Code taken from
//     https://github.com/llvm/llvm-project/blob/main/openmp/runtime/src/kmp.h
////////////////////////////////////////////////////////////////////////////////

/*!
 * The ident structure that describes a source location.
 * The struct is identical to the one in the kmp.h file.
 * We maintain the same data structure for compatibility.
 */
typedef int32_t kmp_int32;
typedef uint32_t kmp_uint32;
typedef int64_t kmp_int64;
typedef uint64_t kmp_uint64;
typedef kmp_uint64 _kmp_ptr64;
typedef kmp_uint32 _kmp_ptr32;

typedef struct ident {
    kmp_int32 reserved_1; /**<  might be used in Fortran; see above  */
    kmp_int32 flags; /**<  also f.flags; KMP_IDENT_xxx flags; KMP_IDENT_KMPC
                        identifies this union member  */
    kmp_int32
        reserved_2; /**<  not really used in Fortran any more; see above */
    kmp_int32 reserved_3; /**<  source[4] in Fortran, do not use for C++  */
    char const *psource;  /**<  String describing the source location.
                          The string is composed of semi-colon separated fields
                          which describe the source file, the function and a pair
                          of line numbers that delimit the construct. */
} ident_t;

/*!
 @ingroup WORK_SHARING
 * Describes the loop schedule to be used for a parallel for loop.
 */
enum sched_type : kmp_int32 {
    kmp_sch_lower = 32, /**< lower bound for unordered values */
    kmp_sch_static_chunked = 33,
    kmp_sch_static = 34, /**< static unspecialized */
    kmp_sch_dynamic_chunked = 35,
    kmp_sch_guided_chunked = 36, /**< guided unspecialized */
    kmp_sch_runtime = 37,
    kmp_sch_auto = 38, /**< auto */
    kmp_sch_trapezoidal = 39,

    /* accessible only through KMP_SCHEDULE environment variable */
    kmp_sch_static_greedy = 40,
    kmp_sch_static_balanced = 41,
    /* accessible only through KMP_SCHEDULE environment variable */
    kmp_sch_guided_iterative_chunked = 42,
    kmp_sch_guided_analytical_chunked = 43,
    /* accessible only through KMP_SCHEDULE environment variable */
    kmp_sch_static_steal = 44,

    /* static with chunk adjustment (e.g., simd) */
    kmp_sch_static_balanced_chunked = 45,
    kmp_sch_guided_simd = 46,  /**< guided with chunk adjustment */
    kmp_sch_runtime_simd = 47, /**< runtime with chunk adjustment */

    /* accessible only through KMP_SCHEDULE environment variable */
    kmp_sch_upper, /**< upper bound for unordered values */

    kmp_ord_lower =
        64, /**< lower bound for ordered values, must be power of 2 */
    kmp_ord_static_chunked = 65,
    kmp_ord_static = 66, /**< ordered static unspecialized */
    kmp_ord_dynamic_chunked = 67,
    kmp_ord_guided_chunked = 68,
    kmp_ord_runtime = 69,
    kmp_ord_auto = 70, /**< ordered auto */
    kmp_ord_trapezoidal = 71,
    kmp_ord_upper, /**< upper bound for ordered values */

    /* Schedules for Distribute construct */
    kmp_distribute_static_chunked = 91, /**< distribute static chunked */
    kmp_distribute_static = 92,         /**< distribute static unspecialized */

    /* For the "nomerge" versions, kmp_dispatch_next*() will always return a
       single iteration/chunk, even if the loop is serialized. For the schedule
       types listed above, the entire iteration vector is returned if the loop
       is serialized. This doesn't work for gcc/gcomp sections. */
    kmp_nm_lower = 160, /**< lower bound for nomerge values */

    kmp_nm_static_chunked =
        (kmp_sch_static_chunked - kmp_sch_lower + kmp_nm_lower),
    kmp_nm_static = 162, /**< static unspecialized */
    kmp_nm_dynamic_chunked = 163,
    kmp_nm_guided_chunked = 164, /**< guided unspecialized */
    kmp_nm_runtime = 165,
    kmp_nm_auto = 166, /**< auto */
    kmp_nm_trapezoidal = 167,

    /* accessible only through KMP_SCHEDULE environment variable */
    kmp_nm_static_greedy = 168,
    kmp_nm_static_balanced = 169,
    /* accessible only through KMP_SCHEDULE environment variable */
    kmp_nm_guided_iterative_chunked = 170,
    kmp_nm_guided_analytical_chunked = 171,
    kmp_nm_static_steal =
        172, /* accessible only through OMP_SCHEDULE environment variable */

    kmp_nm_ord_static_chunked = 193,
    kmp_nm_ord_static = 194, /**< ordered static unspecialized */
    kmp_nm_ord_dynamic_chunked = 195,
    kmp_nm_ord_guided_chunked = 196,
    kmp_nm_ord_runtime = 197,
    kmp_nm_ord_auto = 198, /**< auto */
    kmp_nm_ord_trapezoidal = 199,
    kmp_nm_upper, /**< upper bound for nomerge values */

    /* Support for OpenMP 4.5 monotonic and nonmonotonic schedule modifiers.
       Since we need to distinguish the three possible cases (no modifier,
       monotonic modifier, nonmonotonic modifier), we need separate bits for
       each modifier. The absence of monotonic does not imply nonmonotonic,
       especially since 4.5 says that the behaviour of the "no modifier" case is
       implementation defined in 4.5, but will become "nonmonotonic" in 5.0.

       Since we're passing a full 32 bit value, we can use a couple of high bits
       for these flags; out of paranoia we avoid the sign bit.

       These modifiers can be or-ed into non-static schedules by the compiler to
       pass the additional information. They will be stripped early in the
       processing in __kmp_dispatch_init when setting up schedules, so most of
       the code won't ever see schedules with these bits set.  */
    kmp_sch_modifier_monotonic =
        (1 << 29), /**< Set if the monotonic schedule modifier was present */
    kmp_sch_modifier_nonmonotonic =
        (1 << 30), /**< Set if the nonmonotonic schedule modifier was present */

#define SCHEDULE_WITHOUT_MODIFIERS(s) \
    (enum sched_type)(                \
        (s) & ~(kmp_sch_modifier_nonmonotonic | kmp_sch_modifier_monotonic))
#define SCHEDULE_HAS_MONOTONIC(s) (((s)&kmp_sch_modifier_monotonic) != 0)
#define SCHEDULE_HAS_NONMONOTONIC(s) (((s)&kmp_sch_modifier_nonmonotonic) != 0)
#define SCHEDULE_HAS_NO_MODIFIERS(s) \
    (((s) & (kmp_sch_modifier_nonmonotonic | kmp_sch_modifier_monotonic)) == 0)
#define SCHEDULE_GET_MODIFIERS(s) \
    ((enum sched_type)(           \
        (s) & (kmp_sch_modifier_nonmonotonic | kmp_sch_modifier_monotonic)))
#define SCHEDULE_SET_MODIFIERS(s, m) \
    (s = (enum sched_type)((kmp_int32)s | (kmp_int32)m))
#define SCHEDULE_NONMONOTONIC 0
#define SCHEDULE_MONOTONIC 1

    kmp_sch_default = kmp_sch_static /**< default scheduling algorithm */
};

#endif
