// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include <snblas.h>
#include <snrt.h>

#include "printf.h"

struct data {
    size_t n;
    double *x;
    double *y;
    double *yo;
};

/// Decide on the test data size and allocate buffers for it.
static struct data allocate_data(snrt_slice_t mem) {
    // Compute how long the vector should be to give the available number of
    // cores and clusters enough work (around 1000 elements per core).
    size_t n_ideal = snrt_global_core_num() * 1000;

    // Compute how much space we actually have available.
    size_t n_avail = snrt_slice_len(mem) / sizeof(double) / 3;

    // Pick the smaller number and populate the memory with some garbage.
    printf("n_ideal = %d, n_avail = %d\n", n_ideal, n_avail);
    size_t n = snrt_min(n_ideal, n_avail);
    printf("Allocating %d elements\n", n);

    return (struct data){.n = n,
                         .x = (double *)mem.start + 0 * n,
                         .y = (double *)mem.start + 1 * n,
                         .yo = (double *)mem.start + 2 * n};
}

/// Generate the test data.
static void generate_data(const struct data *data) {
    // Compute the range of the data that should be populated by this core.
    size_t lo = (snrt_global_core_idx() + 0) * data->n / snrt_global_core_num();
    size_t hi = (snrt_global_core_idx() + 1) * data->n / snrt_global_core_num();
    printf("Core %d/%d populating from %d to %d\n", snrt_global_core_idx(),
           snrt_global_core_num(), lo, hi);

    // Populate the range with data.
    for (size_t i = lo; i < hi; i++) {
        data->x[i] = i;
        data->y[i] = i * 3;
    }
}

int main() {
    // Allocate some memory to operate on and distribute the information across
    // the cores.
    struct data data;
    if (snrt_global_core_idx() == 0) {
        size_t size_cluster = snrt_slice_len(snrt_cluster_memory());
        size_t size_global = snrt_slice_len(snrt_global_memory());
        printf("Available memory: %d KiB cluster, %d KiB global\n",
               size_cluster / 1024, size_global / 1024);
        if (snrt_cluster_num() > 1) {
            printf("Preparing data in global memory\n");
            data = allocate_data(snrt_global_memory());
        } else {
            printf("Preparing data in cluster memory\n");
            data = allocate_data(snrt_cluster_memory());
        }

        // Distribute the data descriptor to the other cores.
        snrt_bcast_send(&data, sizeof(data));
    } else {
        // Receive the data descriptor from the main core.
        snrt_bcast_recv(&data, sizeof(data));
    }

    printf("Core %d/%d (cluster %d/%d) works on %d items in %p, %p, %p\n",
           snrt_global_core_idx(), snrt_global_core_num(), snrt_cluster_idx(),
           snrt_cluster_num(), data.n, data.x, data.y, data.yo);

    // Generate the test data.
    generate_data(&data);

    return 0;
}
