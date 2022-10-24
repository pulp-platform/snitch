// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include "knn.h"
#include "printf.h"
#include <snblas.h>
#include <snrt.h>
#include <stdint.h>

// Shell sort
// Shamelessly copied from: https://www.programiz.com/dsa/shell-sort
static void __attribute__((noinline)) shell_sort(struct knn_aux array[], int n) {
  // Rearrange elements at each n/2, n/4, n/8, ... intervals
  for (int interval = n / 2; interval > 0; interval /= 2) {
    for (int i = interval; i < n; i += 1) {
      struct knn_aux temp = array[i];
      int j;
      for (j = i; j >= interval && array[j - interval].dist > temp.dist; j -= interval) {
        array[j] = array[j - interval];
      }
      array[j] = temp;
    }
  }
}

static void __attribute__((noinline))
knn_seq(uint32_t K, uint32_t query_size, uint32_t data_size, double *query, double *data,
        struct knn_aux *output, computeConfig_t *ccfg) {
  uint32_t compute_id = snrt_cluster_compute_core_idx();

  if (snrt_is_dm_core())
    return;

  snrt_ssr_loop_1d(SNRT_SSR_DM0, data_size, sizeof(double));
  snrt_ssr_loop_1d(SNRT_SSR_DM1, data_size, sizeof(struct knn_aux));
  snrt_ssr_read(SNRT_SSR_DM0, SNRT_SSR_1D, data);
  snrt_ssr_write(SNRT_SSR_DM1, SNRT_SSR_1D, output);

  snrt_ssr_enable();

  register double tmp;
  uint32_t dsize = data_size;
  double qry = *query;

  if (ccfg->cycle_start == 0)
    ccfg->cycle_start = read_csr(mcycle);

  // For each example in the data calculate the euclidean distance between the query example and the
  // data first loop unrolled by 8
  if (dsize > 8) {
    asm volatile("frep.o %[n_frep], 16, 0, 0 \n"
                 "fsub.d ft3, ft0, %[query] \n"
                 "fsub.d ft4, ft0, %[query] \n"
                 "fsub.d ft5, ft0, %[query] \n"
                 "fsub.d ft6, ft0, %[query] \n"
                 "fsub.d ft7, ft0, %[query] \n"
                 "fsub.d ft8, ft0, %[query] \n"
                 "fsub.d ft9, ft0, %[query] \n"
                 "fsub.d ft10, ft0, %[query] \n"
                 "fmul.d ft1, ft3, ft3 \n"
                 "fmul.d ft1, ft4, ft4 \n"
                 "fmul.d ft1, ft5, ft5 \n"
                 "fmul.d ft1, ft6, ft6 \n"
                 "fmul.d ft1, ft7, ft7 \n"
                 "fmul.d ft1, ft8, ft8 \n"
                 "fmul.d ft1, ft9, ft9 \n"
                 "fmul.d ft1, ft10, ft10 \n"
                 :
                 : [ query ] "f"(qry), [ n_frep ] "r"(dsize / 8 - 1)
                 : "ft0", "ft1", "ft3", "ft4", "ft5", "ft6", "ft7", "ft8", "ft9", "ft10", "memory");
    dsize -= 8 * (dsize / 8);
  }
  // Reminder
  if (dsize) {
    asm volatile("frep.o %[n_frep], 2, 0, 0 \n"
                 "fsub.d ft3, ft0, %[query] \n"
                 "fmul.d ft1, ft3, ft3 \n"
                 :
                 : [ query ] "f"(qry), [ n_frep ] "r"(dsize - 1)
                 : "ft0", "ft1", "ft3", "memory");
  }

  snrt_fpu_fence();
  snrt_ssr_disable();

  if (ccfg->cycle_end == 0)
    ccfg->cycle_end = read_csr(mcycle);
  if (ccfg->max_stmps)
    ccfg->stmps[--ccfg->max_stmps] = read_csr(mcycle);

  // Sort
  for (int i = 0; i < data_size; i++) {
    output[i].index = i;
  }
  shell_sort(output, data_size);

  if (ccfg->max_stmps)
    ccfg->stmps[--ccfg->max_stmps] = read_csr(mcycle);
}

void knn_1d(uint32_t K, uint32_t query_size, uint32_t data_size, double *query, double *data,
            struct knn_aux *output, computeConfig_t *ccfg) {
  uint32_t compute_id = snrt_cluster_compute_core_idx();
  uint32_t compute_num = snrt_cluster_compute_core_num();

  if (snrt_is_dm_core()) {
    /** COPY **/

  } else {
    /** COMPUTE **/
    // Each hart computes one sample
    for (unsigned s = compute_id; s < query_size; s += compute_num) {
      knn_seq(K, 1, data_size, &query[s], data, &output[data_size * s], ccfg);
    }
  }
}
