// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// To be included by specific main_*.c files.

extern uint32_t input_size;
extern double output_checksum[];

static void populate(double *ptr, uint32_t N, uint32_t M, uint32_t ld, uint32_t seed) {
    for (uint32_t n = 0; n < N; n++) {
        for (uint32_t m = 0; m < M; m++) {
            ptr[n*ld+m] = (double)seed * 3.141;
            ++seed;
        }
    }
}

int main(uint32_t core_id, uint32_t core_num) {
    pulp_timer_t start_time, stop_time;
    uint32_t compute_core_num = core_num;
    if (input_size < compute_core_num)
        compute_core_num = input_size;

    // Generate input data in the TCDM.
    double *ptr = (void *)&l1_alloc_base;
    double *input_A = ptr;
    ptr += input_size * (input_size + 1) + 1;
    double *input_B = ptr;
    ptr += input_size * (input_size + 1) + 1;
    double *input_C = ptr;
    ptr += input_size * (input_size + 1) + 1;
    if (core_id == (0 % compute_core_num))
        populate(input_A, input_size, input_size, input_size + 1, 1);
    if (core_id == (1 % compute_core_num))
        populate(input_B, input_size, input_size, input_size + 1, 2);
    if (core_id == (2 % compute_core_num))
        populate(input_C, input_size, input_size, input_size + 1, 3);

    // Distribute work across the available cores.
    uint32_t N = input_size / compute_core_num;
    uint32_t M = input_size;
    uint32_t K = input_size;
    double *argA = input_A + core_id * (input_size + 1);
    double *argB = input_B;
    double *argC = input_C + core_id * (input_size + 1);
    uint32_t ldA = (input_size + 1) * compute_core_num;
    uint32_t ldB = (input_size + 1);
    uint32_t ldC = (input_size + 1) * compute_core_num;

    // Execute sequential kernel on each core.
    pulp_barrier();
    start_time = pulp_get_timer();
    if (core_id < compute_core_num)
        gemm_seq(N, M, K, argA, ldA, argB, ldB, argC, ldC);
    stop_time = pulp_get_timer();
    pulp_barrier();

    // Check results.
    if (core_id == 0) {
        uint32_t diffs = 0;
        for (uint32_t i = 0; i < input_size; i++) {
            double sum = 0;
            for (uint32_t n = 0; n < input_size; n++) {
                sum += input_C[i * (input_size + 1) + n];
            }
            double d = sum - output_checksum[i];
            asm volatile("fabs.d %[d], %[d]"
                         : [d] "+f"(d));
            // if (d < 0)
            //     d = -d;
            // int b;
            // asm volatile ("fle.d %[b], %[eps], %[d]" : [b]"=r"(b) : [eps]"f"(0.001), [d]"f"(d));
            // diffs += b;
            diffs += d > 0.001;
            // diffs += d > 0.001;
            // diffs += (d != 0);
        }
        return diffs;
    }
    return 0;
}
