// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "offload.h"

#include "snrt.h"

#define N_JOBS 1

// Job function type
typedef void (*job_func_t)(job_t* job);

// Job function declarations
void axpy_job_dm_core(job_t* job);
void axpy_job_compute_core(job_t* job);

// Job function arrays
__thread job_func_t jobs_dm_core[N_JOBS] = {axpy_job_dm_core};
__thread job_func_t jobs_compute_core[N_JOBS] = {axpy_job_compute_core};

// Other variables
__thread volatile comm_buffer_t* comm_buffer;

static inline void axpy(uint32_t l, double a, double* x, double* y, double* z) {
    int core_idx = snrt_cluster_core_idx();
    int offset = core_idx * l;

    for (int i = 0; i < l; i++) {
        z[offset] = a * x[offset] + y[offset];
        offset++;
    }
    snrt_fpu_fence();
}

void axpy_job_dm_core(job_t* job) {
    // Get local job pointer as next free slot in l1 alloc
    axpy_local_job_t* axpy_job = (axpy_local_job_t*)snrt_l1_next();

    mcycle();

    // Copy job info
    snrt_dma_start_1d(axpy_job, job, sizeof(axpy_job_t));

    // Get pointer to next free slot in l1 alloc
    double* x = (double*)((uint32_t)axpy_job + sizeof(axpy_local_job_t));

    // Wait for job info transfer to complete
    snrt_dma_wait_all();

    mcycle();

    // Copy operand x
    size_t size = axpy_job->args.l * 8 * 8;
    snrt_dma_start_1d(x, (void*)(uint32_t)axpy_job->args.x_l3_ptr, size);

    // Synchronize with compute cores before updating the l1 alloc pointer
    // such that they can retrieve the local job pointer.
    // Also ensures compute cores see the transferred job information.
    snrt_cluster_hw_barrier();

    // Copy operand y
    double* y = (double*)((uint32_t)x + size);
    snrt_dma_start_1d(y, (void*)(uint32_t)axpy_job->args.y_l3_ptr, size);

    // Set pointers to local job operands
    axpy_job->args.x = x;
    axpy_job->args.y = y;
    axpy_job->args.z = (double*)((uint32_t)y + size);

    // Now we can update the L1 alloc pointer
    void* next = (void*)((uint32_t)(axpy_job->args.z) + size);
    snrt_l1_update_next(next);

    // Wait for DMA transfers to complete
    snrt_dma_wait_all();

    mcycle();

    // Synchronize with compute cores to make sure the data
    // is available before they can start computing on it
    snrt_cluster_hw_barrier();

    mcycle();

    // Synchronize cores to make sure results are available before
    // DMA starts transfer to L3
    snrt_cluster_hw_barrier();

    mcycle();

    // Transfer data out
    snrt_dma_start_1d((void*)(uint32_t)axpy_job->args.z_l3_ptr,
                      axpy_job->args.z, size);
    snrt_dma_wait_all();

    mcycle();
}

void axpy_job_compute_core(job_t* job) {
    // Cast local job
    axpy_local_job_t* axpy_job = (axpy_local_job_t*)job;

    // Get args
    axpy_local_args_t args = axpy_job->args;
    uint32_t l = args.l;
    double a = args.a;
    double* x = args.x;
    double* y = args.y;
    double* z = args.z;

    mcycle();

    // Synchronize with DM core to wait for operands
    // to be fully transferred in L1
    snrt_cluster_hw_barrier();

    mcycle();

    // Run kernel
    axpy(l, a, x, y, z);

    mcycle();

    // Synchronize with DM core to make sure results are available
    // before DMA starts transfer to L3
    snrt_cluster_hw_barrier();

    mcycle();
}

static inline void run_job() {
    // Force compiler to assign fallthrough path of the branch to
    // the DM core. This way the cache miss latency due to the branch
    // is incurred by the compute cores, and overlaps with the data
    // movement performed by the DM core.
    asm goto("bnez %0, %l[run_job_compute_core]"
             :
             : "r"(snrt_is_compute_core())
             :
             : run_job_compute_core);

    // Retrieve remote job data pointer
    job_t* job_remote = ((job_t*)comm_buffer->usr_data_ptr);

    // Invoke job
    jobs_dm_core[job_remote->id](job_remote);

    // Synchronize clusters and return
    return_to_cva6(SYNC_CLUSTERS);

    goto run_job_end;

run_job_compute_core:;

    // Get pointer to local copy of job
    job_t* job_local = (job_t*)(snrt_l1_next());

    mcycle();

    // Synchronize with DM core such that it knows
    // it can update the l1 alloc pointer, and we know
    // job information is locally available
    snrt_cluster_hw_barrier();

    mcycle();

    // Invoke job
    jobs_compute_core[job_local->id](job_local);

run_job_end:;
}

int main() {
    // Enable RO cache on whole HBM address space
    // if (snrt_is_dm_core()) {
    //     configure_read_only_cache_addr_rule(snrt_quadrant_idx(), 0,
    //                                         HBM_00_BASE_ADDR,
    //                                         HBM_10_BASE_ADDR);
    //     enable_read_only_cache(snrt_quadrant_idx());
    // }

    // Initialize pointers
    comm_buffer = (volatile comm_buffer_t*)get_communication_buffer();

    // Notify CVA6 when snRuntime initialization is done
    post_wakeup_cl();
    return_to_cva6(SYNC_ALL);
    snrt_wfi();

    // Job loop
    while (1) {
        // Reset state after wakeup
        mcycle();
        post_wakeup_cl();

        // Execute job
        mcycle();
        run_job();

        // Go to sleep until next job
        mcycle();
        snrt_wfi();
    }
}
