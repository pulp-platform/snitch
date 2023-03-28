// Copyright 2021 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

__thread volatile eu_t *eu_p;
volatile eu_t *volatile eu_p_global;

extern void eu_init(void);
extern void eu_exit(uint32_t core_idx);
extern uint32_t eu_get_workers_in_loop();
extern uint32_t eu_get_workers_in_wfi();
extern void eu_print_status();
extern void eu_event_loop(uint32_t cluster_core_idx);
extern int eu_dispatch_push(void (*fn)(void *, uint32_t), uint32_t argc,
                            void *data, uint32_t nthreads);
extern void eu_run_empty(uint32_t core_idx);
extern void eu_mutex_lock();
extern void eu_mutex_release();
