// Copyright 2022 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <stdint.h>

typedef enum { J_AXPY = 0 } job_id_t;

//////////
// AXPY //
//////////

typedef struct {
    uint32_t l;
    double a;
    uint64_t x_ptr;
    uint64_t y_ptr;
    uint64_t z_ptr;
} axpy_args_t;

typedef struct {
    uint32_t l;
    double a;
    uint64_t x_l3_ptr;
    uint64_t y_l3_ptr;
    uint64_t z_l3_ptr;
    double* x;
    double* y;
    double* z;
} axpy_local_args_t;

typedef struct {
    job_id_t id;
    axpy_args_t args;
} axpy_job_t;

typedef struct {
    job_id_t id;
    axpy_local_args_t args;
} axpy_local_job_t;

/////////////
// Generic //
/////////////

typedef struct {
    uint64_t job_ptr;
} user_data_t;

typedef union {
    axpy_args_t axpy;
} job_args_t;

typedef struct {
    job_id_t id;
    job_args_t args;
} job_t;
