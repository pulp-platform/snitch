// Copyright 2022 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#define MAX_JOB_ARGS_SIZE 60 // Bytes

typedef enum {J_AXPY=0} job_id_t;

typedef struct {
    uint32_t l;
    uint64_t x_ptr;
    uint64_t y_ptr;
    double   a;
    uint64_t z_ptr;
} axpy_args_t;

typedef union {
    axpy_args_t axpy;
} job_args_t;

typedef struct {
    job_id_t   id;
    job_args_t argv;
} job_t;

typedef struct {
    uint32_t job_ptr;
} user_data_t;
