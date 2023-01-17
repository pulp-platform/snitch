// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "snrt.h"
#include "snitch_hero_support.h"

/***********************************************************************************
 * MACROS
 ***********************************************************************************/
#define SYS_exit 60
#define SYS_write 64
#define SYS_read 63
#define SYS_wake 1235
#define SYS_cycle 1236

/***********************************************************************************
 * DATA
 ***********************************************************************************/
volatile struct ring_buf *g_a2h_rb;
volatile struct ring_buf *g_a2h_mbox;
volatile struct ring_buf *g_h2a_mbox;

/***********************************************************************************
 * FUNCTIONS
 ***********************************************************************************/
void csleep(uint32_t cycles) {
  uint32_t start = read_csr(mcycle);
  while ((read_csr(mcycle) - start) < cycles)
    ;
}

int syscall(uint64_t which, uint64_t arg0, uint64_t arg1, uint64_t arg2, uint64_t arg3,
            uint64_t arg4) {
  uint64_t magic_mem[6];
  int ret;
  uint32_t retries = 0;

  volatile struct ring_buf *rb = g_a2h_rb;

  magic_mem[0] = which;
  magic_mem[1] = arg0;
  magic_mem[2] = arg1;
  magic_mem[3] = arg2;
  magic_mem[4] = arg3;
  magic_mem[5] = arg4;

  do {
    ret = rb_device_put(rb, (void *)magic_mem);
    if (ret) {
      ++retries;
      csleep(1000000);
    }
  } while (ret != 0);
  return retries;
}

void snrt_putchar(char c) { syscall(SYS_write, 1, c, 1, 0, 0); }

void snrt_hero_exit(int code) { syscall(SYS_exit, code, 0, 0, 0, 0); }

/***********************************************************************************
 * MAILBOX
 ***********************************************************************************/
int snitch_mbox_try_read(uint32_t *buffer) {
  return rb_device_get(g_h2a_mbox, buffer) == 0 ? 1 : 0;
}
int snitch_mbox_read(uint32_t *buffer, size_t n_words) {
  int ret;
  while (n_words--) {
    do {
      ret = rb_device_get(g_h2a_mbox, &buffer[n_words]);
      if (ret) {
        csleep(10000);
      }
    } while (ret);
  }
  return 0;
}
int snitch_mbox_write(uint32_t word) {
  int ret;
  do {
    ret = rb_device_put(g_a2h_mbox, &word);
    if (ret) {
      csleep(10000);
    }
  } while (ret);
  return ret;
}
