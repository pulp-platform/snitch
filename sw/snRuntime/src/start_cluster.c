// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include "snrt.h"
#include "team.h"

extern const uint32_t _snrt_cluster_cluster_core_num;
extern const uint32_t _snrt_cluster_cluster_base_hartid;
extern const uint32_t _snrt_cluster_cluster_num;
extern const uint32_t _snrt_cluster_cluster_id;
void *const _snrt_cluster_global_start = (void *)0x90000000;
void *const _snrt_cluster_global_end = (void *)0x100000000;

const uint32_t snrt_stack_size __attribute__((weak)) = 10;

// The boot data generated along with the system RTL.
// See `hw/system/snitch_cluster/test/tb_lib.hh` for details.
struct snrt_cluster_bootdata {
    uint32_t boot_addr;
    uint32_t core_count;
    uint32_t hartid_base;
    uint32_t tcdm_start;
    uint32_t tcdm_end;
};

// Rudimentary string buffer for putc calls.
extern uint32_t _end;
#define PUTC_BUFFER_LEN (1024 - sizeof(size_t))
struct putc_buffer_header {
    size_t size;
    uint64_t syscall_mem[8];
};
static volatile struct putc_buffer {
    struct putc_buffer_header hdr;
    char data[PUTC_BUFFER_LEN];
} *const putc_buffer = (void *)&_end;

void _snrt_init_team(uint32_t cluster_core_id, uint32_t cluster_core_num,
                     void *spm_start, void *spm_end,
                     const struct snrt_cluster_bootdata *bootdata,
                     struct snrt_team_root *team) {
    team->base.root = team;
    team->device_tree = (void *)bootdata;
    team->global_core_base_hartid = bootdata->hartid_base;
    team->global_core_num = bootdata->core_count;
    team->cluster_idx = 0;
    team->cluster_num = 1;
    team->cluster_core_base_hartid = bootdata->hartid_base;
    team->cluster_core_num = bootdata->core_count;
    team->global_mem.start =
        (void *)0x90000000;  // TODO: Read this from bootdata
    team->global_mem.end =
        (void *)0x100000000;  // TODO: Read this from bootdata
    team->cluster_mem.start = spm_start;
    team->cluster_mem.end = spm_end;

    // Allocate memory for a global mailbox.
    team->global_mailbox = team->global_mem.start;
    team->global_mem.start += sizeof(struct snrt_mailbox);

    // Allocate memory for a cluster mailbox.
    team->cluster_mem.end -= sizeof(struct snrt_mailbox);
    team->cluster_mailbox = team->cluster_mem.end;

    _snrt_team_current = &team->base;

    // Initialize the string buffer. This technically doesn't belong here, but
    // the _snrt_init_team function is called once per thread before main, so
    // it's as good a point as any.
    putc_buffer[snrt_hartid()].hdr.size = 0;
}

uint32_t _snrt_barrier_reg_ptr() {
    const struct snrt_cluster_bootdata *bd =
        _snrt_team_current->root->device_tree;
    return bd->tcdm_end + 0x30;
}

extern uintptr_t volatile tohost, fromhost;

// Provide an implementation for putchar.
void snrt_putchar(char character) {
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
