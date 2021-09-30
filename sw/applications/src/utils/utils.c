// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "utils.h"

#include <stdint.h>

#include "../../vendor/riscv-opcodes/encoding.h"
#include "layer.h"
#include "math.h"
#include "printf.h"
#include "snrt.h"

/**
 * @brief returns cycle number and injects maker
 * to track performance
 *
 * @return uint32_t
 */
uint32_t benchmark_get_cycle() { return read_csr(mcycle); }

/**
 * @brief start tracking of dma performance region
 *
 */
void snrt_dma_start_tracking() { asm volatile ("dmstati t0, 1"); }

/**
 * @brief stop tracking of dma performance region
 *
 */
void snrt_dma_stop_tracking() { asm volatile ("dmstati t0, 3"); }

/**
 * @brief checks correctness of feature map
 *
 * @param l layer struct (Conv2d, BatchNorm, Maxpool)
 * @param checksum checksum to compare against, reduced over input channels
 * @return uint32_t
 */
uint32_t check_layer(layer l, double *checksum) {
    uint32_t errors = 0;
    double *ptr = snrt_cluster_memory().start;
    volatile double *result_buf = ptr;
    ptr += l.CO;
    volatile double *ofmap_checksums = ptr;
    uint32_t total = 0;

    // DMA Core compares result with a precomputed checksum
    if (snrt_cluster_idx() == 0) {
        if (snrt_is_dm_core()) {
            snrt_dma_txid_t ofmap_checksum_txid =
                snrt_dma_start_1d((double *)ofmap_checksums, checksum,
                                  sizeof(double) * l.OW * l.OH);
            snrt_dma_wait_all();

            for (uint32_t oh = 0; oh < l.OH; oh++) {
                for (uint32_t ow = 0; ow < l.OW; ow++) {
                    snrt_dma_txid_t result_txid = snrt_dma_start_1d(
                        (double *)result_buf, &l.ofmap[(oh * l.OW + ow) * l.CO],
                        sizeof(double) * l.CO);
                    snrt_dma_wait_all();
                    snrt_cluster_hw_barrier();
                    snrt_cluster_hw_barrier();
                }
            }
        } else {
            if (snrt_cluster_compute_core_idx() == 0) {
                snrt_ssr_repeat(SNRT_SSR_DM0, 1);

                // setup SSRs
                snrt_ssr_loop_1d(SNRT_SSR_DM0, l.CO, sizeof(double));

                for (uint32_t oh = 0; oh < l.OH; oh++) {
                    for (uint32_t ow = 0; ow < l.OW; ow++) {
                        snrt_cluster_hw_barrier();

                        double checksum_result = 0.0;
                        const uint32_t ssr = 1;

                        if (ssr) {
                            snrt_ssr_read(SNRT_SSR_DM0, SNRT_SSR_1D,
                                          result_buf);
                            snrt_ssr_enable();
                            register const uint32_t n_frep = l.CO / 8 - 1;
                            register volatile double checksum_result0 = 0.0;
                            register volatile double checksum_result1 = 0.0;
                            register volatile double checksum_result2 = 0.0;
                            register volatile double checksum_result3 = 0.0;
                            register volatile double checksum_result4 = 0.0;
                            register volatile double checksum_result5 = 0.0;
                            register volatile double checksum_result6 = 0.0;
                            register volatile double checksum_result7 = 0.0;

                            // frep over OW dimension
                            asm volatile(
                                "frep.o %[n_frep], 8, 0, 0 \n"
                                "fadd.d %[sum0], ft0, %[sum0] \n"
                                "fadd.d %[sum1], ft0, %[sum1] \n"
                                "fadd.d %[sum2], ft0, %[sum2] \n"
                                "fadd.d %[sum3], ft0, %[sum3] \n"
                                "fadd.d %[sum4], ft0, %[sum4] \n"
                                "fadd.d %[sum5], ft0, %[sum5] \n"
                                "fadd.d %[sum6], ft0, %[sum6] \n"
                                "fadd.d %[sum7], ft0, %[sum7] \n"
                                : [ sum0 ] "+f"(checksum_result0),
                                  [ sum1 ] "+f"(checksum_result1),
                                  [ sum2 ] "+f"(checksum_result2),
                                  [ sum3 ] "+f"(checksum_result3),
                                  [ sum4 ] "+f"(checksum_result4),
                                  [ sum5 ] "+f"(checksum_result5),
                                  [ sum6 ] "+f"(checksum_result6),
                                  [ sum7 ] "+f"(checksum_result7)
                                : [ n_frep ] "r"(n_frep)
                                : "ft0", "ft1", "ft2");

                            snrt_ssr_disable();

                            checksum_result =
                                checksum_result0 + checksum_result1 +
                                checksum_result2 + checksum_result3 +
                                checksum_result4 + checksum_result5 +
                                checksum_result6 + checksum_result7;
                        } else {
                            for (uint32_t co = 0; co < l.CO; co++) {
                                checksum_result += result_buf[co];
                            }
                        }
                        total++;
                        if (fabs(checksum_result - ofmap_checksums[oh * l.OW + ow]) >
                            0.001) {
                            errors++;
                        }
                        snrt_cluster_hw_barrier();
                    }
                }
                // printf("%d/%d Errors\n", errors, total);
            } else {
                for (uint32_t oh = 0; oh < l.OH; oh++) {
                    for (uint32_t ow = 0; ow < l.OW; ow++) {
                        snrt_cluster_hw_barrier();
                        snrt_cluster_hw_barrier();
                    }
                }
            }
        }
    }
    return errors;
}

/**
 * @brief fast memset function performed by DMA
 *
 * @param ptr pointer to the start of the region
 * @param value value to set
 * @param len number of bytes, must be multiple of DMA bus-width
 */
void dma_memset(void *ptr, uint8_t value, uint32_t len) {
    // set first 64bytes to value
    // memset(ptr, value, 64);
    uint8_t *p = ptr;
    uint32_t nbytes = 64;
    while (nbytes--) {
        *p++ = value;
    }

    // DMA copy the the rest
    snrt_dma_txid_t memset_txid =
        snrt_dma_start_2d(ptr, ptr, 64, 64, 0, len / 64);
    snrt_dma_wait_all();
}
