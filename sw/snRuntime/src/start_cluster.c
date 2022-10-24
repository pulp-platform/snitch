// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include "snitch_cluster_peripheral.h"
#include "snrt.h"
#include "team.h"

extern const uint32_t _snrt_cluster_cluster_core_num;
extern const uint32_t _snrt_cluster_cluster_base_hartid;
extern const uint32_t _snrt_cluster_cluster_num;
extern const uint32_t _snrt_cluster_cluster_id;
void *const _snrt_cluster_global_offset = (void *)0x10000000;

const uint32_t snrt_stack_size __attribute__((weak, section(".rodata"))) = 10;

// The boot data generated along with the system RTL.
// See `hw/system/snitch_cluster/test/tb_lib.hh` for details.
struct snrt_cluster_bootdata {
    uint32_t boot_addr;
    uint32_t core_count;
    uint32_t hartid_base;
    uint32_t tcdm_start;
    uint32_t tcdm_size;
    uint32_t tcdm_offset;
    uint64_t global_mem_start;
    uint64_t global_mem_end;
    uint32_t cluster_count;
    uint32_t s1_quadrant_count;
    uint32_t clint_base;
};

// Rudimentary string buffer for putc calls.
extern uint32_t _edram;
#define PUTC_BUFFER_LEN (1024 - sizeof(size_t))
struct putc_buffer_header {
    size_t size;
    uint64_t syscall_mem[8];
};
static volatile struct putc_buffer {
    struct putc_buffer_header hdr;
    char data[PUTC_BUFFER_LEN];
} *const putc_buffer = (void *)&_edram;

void _snrt_init_team(uint32_t cluster_core_id, uint32_t cluster_core_num,
                     void *spm_start, void *spm_end,
                     const struct snrt_cluster_bootdata *bootdata,
                     struct snrt_team_root *team) {
    (void)cluster_core_id;
    team->base.root = team;
    team->bootdata = (void *)bootdata;
    team->global_core_base_hartid = bootdata->hartid_base;
    team->global_core_num = bootdata->core_count * bootdata->cluster_count *
                            bootdata->s1_quadrant_count;
    team->cluster_idx =
        (snrt_hartid() - bootdata->hartid_base) / bootdata->core_count;
    team->cluster_num = bootdata->cluster_count * bootdata->s1_quadrant_count;
    team->cluster_core_base_hartid = bootdata->hartid_base;
    team->cluster_core_num = cluster_core_num;
    team->global_mem.start =
        (uint64_t)(bootdata->global_mem_start + _snrt_cluster_global_offset);
    team->global_mem.end = (uint64_t)bootdata->global_mem_end;
    team->cluster_mem.start = (uint64_t)spm_start;
    team->cluster_mem.end = (uint64_t)spm_end;
    team->barrier_reg_ptr = (uint32_t)spm_start + bootdata->tcdm_size +
                            SNITCH_CLUSTER_PERIPHERAL_HW_BARRIER_REG_OFFSET;

    // Initialize cluster barrier
    team->cluster_barrier.barrier = 0;
    team->cluster_barrier.barrier_iteration = 0;

    // TLS caches of frequently used data
    _snrt_team_current = &team->base;
    _snrt_core_idx =
        (snrt_hartid() - _snrt_team_current->root->cluster_core_base_hartid) %
        _snrt_team_current->root->cluster_core_num;

    // Initialize the string buffer. This technically doesn't belong here, but
    // the _snrt_init_team function is called once per thread before main, so
    // it's as good a point as any.
    putc_buffer[snrt_hartid()].hdr.size = 0;

    // init peripherals
    team->peripherals.clint = (uint32_t *)bootdata->clint_base;
    team->peripherals.perf_counters =
        (uint32_t
             *)(spm_start + bootdata->tcdm_size +
                SNITCH_CLUSTER_PERIPHERAL_PERF_COUNTER_ENABLE_0_REG_OFFSET);
    team->peripherals.wakeup = (uint32_t *)0;  // not supported in RTL anymore
    team->peripherals.cl_clint =
        (uint32_t *)(spm_start + bootdata->tcdm_size +
                     SNITCH_CLUSTER_PERIPHERAL_CL_CLINT_SET_REG_OFFSET);

    // Init allocator
    snrt_alloc_init(team, sizeof(struct putc_buffer));
    snrt_int_init(team);
}

uint32_t _snrt_barrier_reg_ptr() {
    return _snrt_team_current->root->barrier_reg_ptr;
}

extern uintptr_t volatile tohost, fromhost;

// Provide an implementation for putchar.
void __attribute__((weak)) snrt_putchar(char character) {
    volatile struct putc_buffer *buf = &putc_buffer[snrt_hartid()];
    buf->data[buf->hdr.size++] = character;
    if (buf->hdr.size == PUTC_BUFFER_LEN || character == '\n') {
        buf->hdr.syscall_mem[0] = 64;  // sys_write
        buf->hdr.syscall_mem[1] = 1;   // file descriptor (1 = stdout)
        buf->hdr.syscall_mem[2] = (uintptr_t)&buf->data;  // buffer
        buf->hdr.syscall_mem[3] = buf->hdr.size;          // length

        tohost = (uintptr_t)buf->hdr.syscall_mem;
        while (fromhost == 0)
            ;
        fromhost = 0;

        buf->hdr.size = 0;
    }
}
