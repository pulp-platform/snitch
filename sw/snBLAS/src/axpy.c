// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include "axpy.h"
#include "printf.h"
#include <snblas.h>
#include <snrt.h>

void axpy_block(uint32_t n, uint32_t tile_n, double *alpha, double *dx, double *dy,
                computeConfig_t *ccfg) {
  uint32_t compute_id = snrt_cluster_compute_core_idx();
  uint32_t compute_num = ccfg->compute_num;
  const size_t bpw = sizeof(double);
  // padding to mis-align between buffers for each hart to reduce TCDM congestion
  const size_t padding = 1;
  uint32_t ni = 0;
  uint32_t cs = 0;
  int waiter = 0;
  uint64_t t1, t2, bsel = 0;

  // allocate data
  const size_t tile_stride = tile_n / compute_num + padding;
  const size_t buf_stride = compute_num * tile_stride;
  double *ptr = (double *)snrt_cluster_memory().start;
  double *l1_dx = ptr;
  ptr += 2 * buf_stride;
  double *l1_dy = ptr;
  ptr += 2 * buf_stride;
  double *l1_alpha = ptr;
  ptr += 1;

  // Distribute vector across clusters
  const uint32_t chunk = n / ccfg->cluster_num;
  const uint32_t left_over = n - chunk * ccfg->cluster_num;
  dx += chunk * ccfg->cluster_idx;
  dy += chunk * ccfg->cluster_idx;
  n = ccfg->cluster_idx == ccfg->cluster_num ? chunk + left_over : chunk;

  // ------------------
  //   Data mover
  // ------------------

  if (snrt_is_dm_core()) {
    // initial copy-in
    snrt_dma_start_1d(l1_alpha, alpha, bpw * 1);
    if (compute_num > 1) {
      snrt_dma_start_2d(&l1_dx[bsel * buf_stride],             /* dst */
                        &dx[ni],                               /* src */
                        bpw * tile_n / compute_num,            /* size */
                        sizeof(double) * tile_stride,          /* dst_stride */
                        sizeof(double) * tile_n / compute_num, /* src_stride */
                        compute_num /* repetitions */);
      snrt_dma_start_2d(&l1_dy[bsel * buf_stride], &dy[ni], bpw * tile_n / compute_num,
                        sizeof(double) * tile_stride, sizeof(double) * tile_n / compute_num,
                        compute_num);
    } else {
      snrt_dma_start_1d(&l1_dx[bsel * buf_stride], &dx[ni], bpw * tile_n);
      snrt_dma_start_1d(&l1_dy[bsel * buf_stride], &dy[ni], bpw * tile_n);
    }

    // switch buffers
    bsel = !bsel;
    ni += tile_n;

    // signal worker and wait for complete
    snrt_dma_wait_all();
    snrt_cluster_hw_barrier();

    for (; ni < n; ni += tile_n) {

      // copy-out
      if (ni > tile_n) {
        if (compute_num > 1) {
          snrt_dma_start_2d(&dy[ni - 2 * tile_n], &l1_dy[bsel * buf_stride],
                            bpw * tile_n / compute_num, sizeof(double) * tile_n / compute_num,
                            sizeof(double) * tile_stride, compute_num);
        } else {
          snrt_dma_start_1d(&dy[ni - 2 * tile_n], &l1_dy[bsel * buf_stride], bpw * tile_n);
        }
      }

      // copy-in
      if (compute_num > 1) {
        snrt_dma_start_2d(&l1_dx[bsel * buf_stride], &dx[ni], bpw * tile_n / compute_num,
                          sizeof(double) * tile_stride, sizeof(double) * tile_n / compute_num,
                          compute_num);
        snrt_dma_start_2d(&l1_dy[bsel * buf_stride], &dy[ni], bpw * tile_n / compute_num,
                          sizeof(double) * tile_stride, sizeof(double) * tile_n / compute_num,
                          compute_num);
      } else {
        snrt_dma_start_1d(&l1_dx[bsel * buf_stride], &dx[ni], bpw * tile_n);
        snrt_dma_start_1d(&l1_dy[bsel * buf_stride], &dy[ni], bpw * tile_n);
      }

      // switch buffers
      bsel = !bsel;

      // signal worker and wait for complete
      snrt_dma_wait_all();
      snrt_cluster_hw_barrier();
    }

    // last two copy-out
    if (n / tile_n > 1) {
      if (compute_num > 1) {
        snrt_dma_start_2d(&dy[ni - 2 * tile_n], &l1_dy[bsel * buf_stride],
                          bpw * tile_n / compute_num, sizeof(double) * tile_n / compute_num,
                          sizeof(double) * tile_stride, compute_num);
        snrt_dma_start_2d(&dy[ni - 2 * tile_n], &l1_dy[bsel * buf_stride],
                          bpw * tile_n / compute_num, sizeof(double) * tile_n / compute_num,
                          sizeof(double) * tile_stride, compute_num);
      } else {
        snrt_dma_start_1d(&dy[ni - 2 * tile_n], &l1_dy[bsel * buf_stride], bpw * tile_n);
      }
    }
    bsel = !bsel;
    snrt_cluster_hw_barrier();

    if (compute_num > 1) {
      snrt_dma_start_2d(&dy[ni - 1 * tile_n], &l1_dy[bsel * buf_stride], bpw * tile_n / compute_num,
                        sizeof(double) * tile_n / compute_num, sizeof(double) * tile_stride,
                        compute_num);
      snrt_dma_start_2d(&dy[ni - 1 * tile_n], &l1_dy[bsel * buf_stride], bpw * tile_n / compute_num,
                        sizeof(double) * tile_n / compute_num, sizeof(double) * tile_stride,
                        compute_num);
    } else {
      snrt_dma_start_1d(&dy[ni - 1 * tile_n], &l1_dy[bsel * buf_stride], bpw * tile_n);
    }
    snrt_dma_wait_all();
  }

  // ------------------
  //   Compute
  // ------------------
  else {
    const uint32_t element_start = tile_stride * compute_id;
    uint32_t t_start, t_stop;
    for (ni = 0; ni < n; ni += tile_n) {
      snrt_cluster_hw_barrier();

      if (compute_id < compute_num) {
        t_start = axpy(tile_n / compute_num, l1_alpha, &l1_dx[element_start + bsel * buf_stride],
                       &l1_dy[element_start + bsel * buf_stride], ni == 0);
        t_stop = read_csr(mcycle);

        if (ccfg->cycle_start == 0)
          ccfg->cycle_start = t_start;
        if (ccfg->max_stmps)
          ccfg->stmps[--ccfg->max_stmps] = t_start;

        ccfg->cycle_end = t_stop;
        if (ccfg->max_stmps)
          ccfg->stmps[--ccfg->max_stmps] = t_stop;

        // switch buffers
        bsel = !bsel;
      }
    }
    snrt_cluster_hw_barrier();
  }

  // ------------------
  //   Cleanup
  // ------------------
  return;
}

uint32_t __attribute__((noinline))
axpy(uint32_t n, double *alpha, double *dx, double *dy, uint32_t setup_ssr) {
  double alpha_load = *alpha;

  if (setup_ssr) {
    __builtin_ssr_setup_1d_r(SNRT_SSR_DM0, 0, n - 1, sizeof(double), dx);
    __builtin_ssr_setup_1d_r(SNRT_SSR_DM1, 0, n - 1, sizeof(double), dy);
    __builtin_ssr_setup_1d_w(SNRT_SSR_DM2, 0, n - 1, sizeof(double), dy);
  } else {
    __builtin_ssr_read_imm(SNRT_SSR_DM0, 0, dx);
    __builtin_ssr_read_imm(SNRT_SSR_DM1, 0, dy);
    __builtin_ssr_write_imm(SNRT_SSR_DM2, 0, dy);
  }

  uint32_t start = read_csr(mcycle);
  snrt_ssr_enable();
  asm volatile("frep.o %[n_frep], 1, 0, 0 \n"
               "fmadd.d ft2, %[alpha], ft0, ft1\n"
               :
               : [ n_frep ] "r"(n - 1), [ alpha ] "f"(alpha_load)
               : "ft0", "ft1", "ft2", "memory");
  snrt_fpu_fence();
  snrt_ssr_disable();
  return start;
}

unsigned test_axpy(void) {
  uint32_t compute_id = snrt_cluster_compute_core_idx();
  uint32_t compute_num = snrt_cluster_compute_core_num();
  const uint32_t axpy_n = 64;

  // allocate data
  double *ptr = (double *)snrt_cluster_memory().start;
  double *dx = ptr;
  ptr += axpy_n;
  double *dy = ptr;
  ptr += axpy_n;
  double *alpha = ptr;
  ptr += 1;

  // generate data
  if (compute_id == 0) {
    *alpha = 2.0;
    for (unsigned i = 0; i < axpy_n; ++i) {
      dx[i] = (double)i * 0.5;
      dy[i] = 100.0;
    }
  }
  snrt_cluster_hw_barrier();

  // call kernel
  if (snrt_is_compute_core()) {
    uint32_t element_start = (axpy_n / compute_num) * compute_id;
    uint32_t element_num = axpy_n / compute_num;
    if (compute_id == compute_num - 1)
      element_num += axpy_n - (axpy_n / compute_num * compute_num);
    axpy(element_num, alpha, &dx[element_start], &dy[element_start], 1);
  }
  snrt_cluster_hw_barrier();

  // verify
  unsigned errors = 0;
  if (compute_id == 0) {
    for (unsigned i = 0; i < axpy_n; ++i) {
      if (dy[i] != 100.0 + (double)i) {
        printf("%3d mismatch is %.3f should %.3f\r\n", i, dy[i], 100.0 + (double)i);
        ++errors;
      }
    }
  }
  return errors;
}
