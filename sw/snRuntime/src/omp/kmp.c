// Copyright 2021 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "kmp.h"

#include <inttypes.h>  // for PRIx##
#include <stdio.h>
#include <stdlib.h>

#include "encoding.h"
#include "omp.h"

typedef void (*__task_type32)(_kmp_ptr32, _kmp_ptr32, _kmp_ptr32);
typedef void (*__task_type64)(_kmp_ptr64, _kmp_ptr64, _kmp_ptr64);

/**
 * @brief Usually the arguments passed to __kmpc_fork_call would do a malloc
 * with the amount of arguments passed. This is too slow for our case and thus
 * we reserve a chunk of arguments in TCDM and use it. This limits the maximum
 * number of arguments
 *
 */
_kmp_ptr32 *kmpc_args;

static void __microtask_wrapper(void *arg, uint32_t argc) {
    kmp_int32 id = omp_get_thread_num();
    kmp_int32 *id_addr = (kmp_int32 *)(&id);

    // first element in args is the function pointer
    kmpc_micro fn = (kmpc_micro)((_kmp_ptr32 *)arg)[0];
    // second element in args is the pointer to the argument vector
    _kmp_ptr32 *p_argv = &((_kmp_ptr32 *)arg)[1];
    kmp_int32 gtid = id;

    uint32_t cycle = read_csr(mcycle);
    OMP_PROF(if (snrt_hartid() == 1) omp_prof->fork_oh =
                 cycle - omp_prof->fork_oh);

    switch (argc) {
        default:
            // printf("Too many args to __microtask_wrapper: %d!\n", argc);
            snrt_exit(-1);
        case 0:
            fn(&gtid, id_addr);
            break;
        case 1:
            fn(&gtid, id_addr, p_argv[0]);
            break;
        case 2:
            fn(&gtid, id_addr, p_argv[0], p_argv[1]);
            break;
        case 3:
            fn(&gtid, id_addr, p_argv[0], p_argv[1], p_argv[2]);
            break;
        case 4:
            fn(&gtid, id_addr, p_argv[0], p_argv[1], p_argv[2], p_argv[3]);
            break;
        case 5:
            fn(&gtid, id_addr, p_argv[0], p_argv[1], p_argv[2], p_argv[3],
               p_argv[4]);
            break;
        case 6:
            fn(&gtid, id_addr, p_argv[0], p_argv[1], p_argv[2], p_argv[3],
               p_argv[4], p_argv[5]);
            break;
        case 7:
            fn(&gtid, id_addr, p_argv[0], p_argv[1], p_argv[2], p_argv[3],
               p_argv[4], p_argv[5], p_argv[6]);
            break;
        case 8:
            fn(&gtid, id_addr, p_argv[0], p_argv[1], p_argv[2], p_argv[3],
               p_argv[4], p_argv[5], p_argv[6], p_argv[7]);
        case 9:
            fn(&gtid, id_addr, p_argv[0], p_argv[1], p_argv[2], p_argv[3],
               p_argv[4], p_argv[5], p_argv[6], p_argv[7], p_argv[8]);
        case 10:
            fn(&gtid, id_addr, p_argv[0], p_argv[1], p_argv[2], p_argv[3],
               p_argv[4], p_argv[5], p_argv[6], p_argv[7], p_argv[8],
               p_argv[9]);
        case 11:
            fn(&gtid, id_addr, p_argv[0], p_argv[1], p_argv[2], p_argv[3],
               p_argv[4], p_argv[5], p_argv[6], p_argv[7], p_argv[8], p_argv[9],
               p_argv[10]);
        case 12:
            fn(&gtid, id_addr, p_argv[0], p_argv[1], p_argv[2], p_argv[3],
               p_argv[4], p_argv[5], p_argv[6], p_argv[7], p_argv[8], p_argv[9],
               p_argv[10], p_argv[11]);
            break;
    }
    // for performance tracking in traces
    cycle = read_csr(mcycle);
}

/*!
@ingroup THREAD_STATES
@param loc Source location information.
@return The global thread index of the active thread.

This function can be called in any context.

If the runtime has ony been entered at the outermost level from a
single (necessarily non-OpenMP<sup>*</sup>) thread, then the thread number is
that which would be returned by omp_get_thread_num() in the outermost
active parallel construct. (Or zero if there is no active parallel
construct, since the master thread is necessarily thread zero).

If multiple non-OpenMP threads all enter an OpenMP construct then this
will be a unique thread identifier among all the threads created by
the OpenMP runtime (but the value cannot be defined in terms of
OpenMP thread ids returned by omp_get_thread_num()).
*/
kmp_int32 __kmpc_global_thread_num(ident_t *loc) {
    (void)loc;
    // return csr value of hartware thread ID
    kmp_int32 gtid = read_csr(mhartid);
    KMP_PRINTF(10, "__kmpc_global_thread_num: T#%d\n", gtid);
    return gtid;
}

void __kmpc_barrier(ident_t *loc, kmp_int32 tid) {
    (void)loc;
    (void)tid;
    _OMP_T *_this = omp_getData();
    uint32_t ret;
    KMP_PRINTF(50, "barrier numThreads: %d\n", (uint32_t)_this->numThreads);
    snrt_barrier(_this->kmpc_barrier, (uint32_t)_this->numThreads);
}

/*!
@ingroup PARALLEL
@param loc source location information
@param global_tid global thread number
@param num_threads number of threads requested for this parallel construct

Set the number of threads to be used by the next fork spawned by this thread.
This call is only required if the parallel construct has a `num_threads` clause.
*/
void __kmpc_push_num_threads(ident_t *loc, kmp_int32 global_tid,
                             kmp_int32 num_threads) {
    (void)loc;
    (void)global_tid;
    (void)num_threads;
    KMP_PRINTF(20, "__kmpc_push_num_threads: enter T#%d num_threads=%d\n",
               global_tid, num_threads);
#ifndef OMPSTATIC_NUMTHREADS
    omp_t *omp = omp_getData();
    omp->numThreads = num_threads;
    if (omp->numThreads > omp->maxThreads) {
        omp->numThreads = omp->maxThreads;
    }
#endif
}

/*!
@ingroup PARALLEL
@param loc  source location information
@param argc  total number of arguments in the ellipsis
@param microtask  pointer to callback routine consisting of outlined parallel
construct
@param ...  pointers to shared variables that aren't global

Do the actual fork and call the microtask in the relevant number of threads.
*/
void __kmpc_fork_call(ident_t *loc, kmp_int32 argc, kmpc_micro microtask, ...) {
    (void)loc;
    _OMP_T *omp = omp_getData();

    OMP_PROF(omp_prof->fork_oh = read_csr(mcycle));

    va_list vl;
    int arg_size = 0;
    arg_size = (argc + 1) * sizeof(_kmp_ptr32);

    // Do not alloc for argument pointers but use the statically alllocated
    // kmpc_args
    // void *args = rt_malloc(arg_size); for(int i = 0; i < arg_size;
    // i ++) ((uint8_t*)args)[i]=0;
    // first element holds pointer to the microtask
    kmpc_args[0] = (_kmp_ptr32)microtask;
    // copy remaining varargs
    va_start(vl, microtask);
    for (int i = 1; i <= argc; ++i) {
        kmpc_args[i] = (_kmp_ptr32)va_arg(vl, _kmp_ptr32);
    }
    va_end(vl);

    KMP_PRINTF(10,
               "__kmpc_fork_call: argc=%d numthreads=%d omp->numThreads=%d "
               "microtask @%#x\n",
               argc, omp->numThreads, omp->numThreads, (uint32_t)microtask);

    /// a worker enters this fork call: this means nested parallelism
    if (snrt_cluster_core_idx() != 0) {
        KMP_PRINTF(0, "error: nested parallelism\n");
        snrt_exit(-1);
        /// TODO: This almost works. The problem is, that the current task in
        /// the EU is not yet completed (due to this thread forking). Correctly,
        /// this thread woul re-enter the event queue, run the newly dispatched
        /// thread and then return to this thread. If this is not done, the
        /// nested parallelism is not executed in the correct order
        (void)eu_dispatch_push(__microtask_wrapper, argc, kmpc_args,
                               omp->numThreads);
    } else {
        parallelRegion(argc, kmpc_args, __microtask_wrapper, omp->numThreads);
    }

    // rt_free(args);
}

/*!
@ingroup WORK_SHARING
@param    loc       Source code location
@param    gtid      Global thread id of this thread
@param    schedtype  Scheduling type
@param    plastiter Pointer to the "last iteration" flag
@param    plower    Pointer to the lower bound
@param    pupper    Pointer to the upper bound
@param    pstride   Pointer to the stride
@param    incr      Loop increment
@param    chunk     The chunk size

Each of the four functions here are identical apart from the argument types.

The functions compute the upper and lower bounds and stride to be used for the
set of iterations to be executed by the current thread from the statically
scheduled loop that is described by the initial values of the bounds, stride,
increment and chunk size.

@{
*/
void __kmpc_for_static_init_4(ident_t *loc, kmp_int32 gtid,
                              enum sched_type sched, kmp_int32 *plastiter,
                              kmp_int32 *plower, kmp_int32 *pupper,
                              kmp_int32 *pstride, kmp_int32 incr,
                              kmp_int32 chunk) {
    (void)loc;
    (void)gtid;
    _OMP_T *omp = omp_getData();
    _OMP_TEAM_T *team = omp_get_team(omp);
    unsigned threadNum = omp_get_thread_num();
    kmp_uint32 loopSize = (*pupper - *plower) / incr + 1;
    kmp_int32 globalUpper = *pupper;

    KMP_PRINTF(50,
               "__kmpc_for_static_init_4 gtid %d schedtype %d plast %#x p[%#x, "
               "%#x, %#x] incr %d chunk %d\n",
               gtid, sched, (uint32_t)plastiter, (uint32_t)plower,
               (uint32_t)pupper, (uint32_t)pstride, incr, chunk);
    KMP_PRINTF(50, "    plast %4d p[%4d, %4d, %4d]\n", *plastiter, *plower,
               *pupper, *pstride);
    KMP_PRINTF(50, "    loopsize %d\n", loopSize);

    // chunk size is specified
    if (sched == kmp_sch_static_chunked) {
        KMP_PRINTF(50, "    sched: static_chunked\n");
        int span = incr * chunk;
        *pstride = span * team->nbThreads;
        *plower = *plower + span * threadNum;
        *pupper = *plower + span - incr;
        int beginLastChunk = globalUpper - (globalUpper % span);
        *plastiter = ((beginLastChunk - *plower) % *pstride) == 0;
    }

    // no specified chunk size
    else if (sched == kmp_sch_static) {
        KMP_PRINTF(50, "    sched: static\n");
        chunk = loopSize / team->nbThreads;
        int leftOver = loopSize - chunk * team->nbThreads;

        // calculate precise chunk size and lower and upper bound
        if ((int)threadNum < leftOver) {
            chunk++;
            *plower = *plower + threadNum * chunk * incr;
        } else
            *plower = *plower + threadNum * chunk * incr + leftOver;
        *pupper = *plower + chunk * incr - incr;

        if (plastiter != NULL)
            *plastiter = (*pupper == globalUpper && *plower <= globalUpper);
        *pstride = loopSize;

        KMP_PRINTF(50, "    team thds: %d chunk: %d leftOver: %d\n",
                   team->nbThreads, chunk, leftOver);
    }

    KMP_PRINTF(10,
               "__kmpc_for_static_init_4 plast %4d p[l %4d, u %4d, i %4d, str "
               "%4d] chunk %d\n",
               *plastiter, *plower, *pupper, incr, *pstride, chunk);
}

/*!
 See @ref __kmpc_for_static_init_4
 */
void __kmpc_for_static_init_4u(ident_t *loc, kmp_int32 gtid,
                               kmp_int32 schedtype, kmp_int32 *plastiter,
                               kmp_uint32 *plower, kmp_uint32 *pupper,
                               kmp_int32 *pstride, kmp_int32 incr,
                               kmp_int32 chunk) {
    kmp_int32 ilower = *plower;
    kmp_int32 iupper = *pupper;
    __kmpc_for_static_init_4(loc, gtid, schedtype, plastiter, &ilower, &iupper,
                             pstride, incr, chunk);
    *plower = ilower;
    *pupper = iupper;
}

void __kmpc_for_static_fini(ident_t *loc, kmp_int32 globaltid) {
    (void)loc;
    (void)globaltid;
    KMP_PRINTF(10, "__kmpc_for_static_fini\n");
    // TODO: Implement
    // omp_t *omp = omp_getData();
    // doBarrier(getTeam(omp));
}

void __kmpc_for_static_init_8u(ident_t *loc, kmp_int32 gtid, kmp_int32 sched,
                               kmp_int32 *plastiter, kmp_uint64 *plower,
                               kmp_uint64 *pupper, kmp_int64 *pstride,
                               kmp_int64 incr, kmp_int64 chunk) {
    (void)loc;
    (void)gtid;
    _OMP_T *omp = omp_getData();
    _OMP_TEAM_T *team = omp_get_team(omp);
    unsigned threadNum = omp_get_thread_num();
    kmp_uint64 loopSize = (*pupper - *plower) / incr + 1;
    kmp_uint64 globalUpper = *pupper;

    KMP_PRINTF(50,
               "__kmpc_for_static_init_8u gtid %d schedtype %d incr %" PRId64
               " chunk %" PRId64 "\n",
               gtid, sched, incr, chunk);
    KMP_PRINTF(50,
               "    plast %" PRIu32 " lo,up,strd = [%" PRIu64 ", %" PRIu64
               ", %" PRId64 "]\n",
               *plastiter, *plower, *pupper, *pstride);
    KMP_PRINTF(50, "    loopsize %" PRIu64 "\n", loopSize);

    // chunk size is specified
    if (sched == kmp_sch_static_chunked) {
        KMP_PRINTF(50, "    sched: static_chunked\n");
        kmp_int64 span = incr * chunk;
        *pstride = span * team->nbThreads;
        *plower = *plower + span * threadNum;
        *pupper = *plower + span - incr;
        kmp_int64 beginLastChunk = globalUpper - (globalUpper % span);
        *plastiter = ((beginLastChunk - *plower) % *pstride) == 0;
    }

    // no specified chunk size
    else if (sched == kmp_sch_static) {
        KMP_PRINTF(50, "    sched: static\n");
        chunk = loopSize / team->nbThreads;
        kmp_int64 leftOver = loopSize - chunk * team->nbThreads;

        // calculate precise chunk size and lower and upper bound
        if (threadNum < leftOver) {
            chunk++;
            *plower = *plower + threadNum * chunk * incr;
        } else
            *plower = *plower + threadNum * chunk * incr + leftOver;
        *pupper = *plower + chunk * incr - incr;

        if (plastiter != NULL)
            *plastiter = (*pupper == globalUpper && *plower <= globalUpper);
        *pstride = loopSize;

        KMP_PRINTF(
            50, "    team thds: %d chunk: %" PRId64 " leftOver: %" PRId64 "\n",
            team->nbThreads, chunk, leftOver);
    }

    KMP_PRINTF(10,
               "__kmpc_for_static_init_8u plast %4" PRId32 "p[l %4" PRIu64
               ", u %4" PRIu64 ", i %4" PRId64 ", str %4" PRId64
               "] chunk %" PRId64 "\n",
               *plastiter, *plower, *pupper, incr, *pstride, chunk);
}

//================================================================================
// Dynamic scheduling
// Only available if not OMPSTATIC_NUMTHREADS
//================================================================================
#ifndef OMPSTATIC_NUMTHREADS

/*!
@ingroup WORK_SHARING
@{
@param loc Source location
@param gtid Global thread id
@param schedule Schedule type
@param lb  Lower bound
@param ub  Upper bound
@param st  Step (or increment if you prefer)
@param chunk The chunk size to block with

This function prepares the runtime to start a dynamically scheduled for loop,
saving the loop arguments.
These functions are all identical apart from the types of the arguments.
*/
void __kmpc_dispatch_init_4(ident_t *loc, kmp_int32 gtid,
                            enum sched_type schedule, kmp_int32 lb,
                            kmp_int32 ub, kmp_int32 st, kmp_int32 chunk) {
    (void)loc;
    (void)gtid;
    (void)schedule;
    omp_team_t *team = omp_get_team(omp_getData());
    // dynLoopInitNoIter(team, lb, ub, st, chunk);
    // int core_id = omp_get_thread_num();
    eu_mutex_lock();
    // if (team->loop_epoch - team->core_epoch[core_id] != 0)
    // {
    //   eu_mutex_release();
    //   team->core_epoch[core_id]++;
    //   KMP_PRINTF(10, "__kmpc_dispatch_init_4 core_epoch[%d] =
    //   %d\n",core_id,team->core_epoch[core_id]); return;
    // }

    if (!team->loop_is_setup) {
        team->loop_is_setup = 1;
        team->loop_start = lb;
        team->loop_end = ub;
        team->loop_incr = st;
        team->loop_chunk = chunk;
        KMP_PRINTF(
            10,
            "__kmpc_dispatch_init_4 setup: start %d end %d incr %d chunk %d\n",
            team->loop_start, team->loop_end, team->loop_incr,
            team->loop_chunk);
    }
    eu_mutex_release();
}

/*!
See @ref __kmpc_dispatch_init_4
*/
void __kmpc_dispatch_init_4u(ident_t *loc, kmp_int32 gtid,
                             enum sched_type schedule, kmp_uint32 lb,
                             kmp_uint32 ub, kmp_int32 st, kmp_int32 chunk) {
    kmp_int32 ilb = (kmp_int32)lb;
    kmp_int32 iub = (kmp_int32)ub;
    __kmpc_dispatch_init_4(loc, gtid, schedule, ilb, iub, st, chunk);
}

/*!
@param loc Source code location
@param gtid Global thread id
@param p_last Pointer to a flag set to one if this is the last chunk or zero
otherwise
@param p_lb   Pointer to the lower bound for the next chunk of work
@param p_ub   Pointer to the upper bound for the next chunk of work
@param p_st   Pointer to the stride for the next chunk of work
@return one if there is work to be done, zero otherwise

Get the next dynamically allocated chunk of work for this thread.
If there is no more work, then the lb,ub and stride need not be modified.
*/
int __kmpc_dispatch_next_4(ident_t *loc, kmp_int32 gtid, kmp_int32 *p_last,
                           kmp_int32 *p_lb, kmp_int32 *p_ub, kmp_int32 *p_st) {
    (void)loc;
    (void)gtid;

    omp_team_t *team = omp_get_team(omp_getData());

    // The stride is actually always 1
    *p_st = 1;

    // int result = dynLoopIter(team, (int*) p_lb, (int*) p_ub, (int*) p_last);
    eu_mutex_lock();

    // have already iterated over all the iterations(no more work), return 0
    if (team->loop_start > team->loop_end) {
        team->loop_is_setup = 0;
        KMP_PRINTF(
            10, "__kmpc_dispatch_next_4 start > end: team->loop_is_setup %d\n",
            team->loop_is_setup);
        eu_mutex_release();
        return 0;
    }

    *p_lb = team->loop_start;
    *p_ub = *p_lb + team->loop_chunk - 1;
    if (*p_ub >= team->loop_end) {
        *p_ub = team->loop_end;
        *p_last = 1;
    }

    team->loop_start += team->loop_chunk;
    KMP_PRINTF(10,
               "__kmpc_dispatch_next_4 : last: %d [l %4d u %4d s %4d] "
               "team->loop_start %d\n",
               *p_last, *p_lb, *p_ub, *p_st, team->loop_start);
    eu_mutex_release();
    return 1;
}

/*!
See @ref __kmpc_dispatch_next_4
*/
int __kmpc_dispatch_next_4u(ident_t *loc, kmp_int32 gtid, kmp_int32 *p_last,
                            kmp_uint32 *p_lb, kmp_uint32 *p_ub,
                            kmp_int32 *p_st) {
    kmp_int32 p_lbi = *p_lb;
    kmp_int32 p_ubi = *p_ub;
    int ret = __kmpc_dispatch_next_4(loc, gtid, p_last, &p_lbi, &p_ubi, p_st);
    *p_lb = p_lbi;
    *p_ub = p_ubi;
    return ret;
}

#endif  // #ifndef OMPSTATIC_NUMTHREADS
