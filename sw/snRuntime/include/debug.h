// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

extern uint32_t snrt_log_level;

static inline void snrt_debug_set_loglevel(uint32_t lvl) { snrt_log_level = lvl; };

#define LOG_ERROR 0
#define LOG_WARN 1
#define LOG_INFO 2
#define LOG_DEBUG 3
#define LOG_TRACE 4

#if defined(DEBUG)

#define snrt_error(fmt, ...)                                                                       \
  ({                                                                                               \
    if (LOG_ERROR <= snrt_log_level)                                                               \
      snrt_printf("[\033[31msnrt(%d,%d):error:%s\033[0m] " fmt, snrt_cluster_idx(),                \
                  snrt_cluster_core_idx(), __func__, ##__VA_ARGS__);                               \
  })
#define snrt_warn(fmt, ...)                                                                        \
  ({                                                                                               \
    if (LOG_WARN <= snrt_log_level)                                                                \
      snrt_printf("[\033[91msnrt(%d,%d):warn:%s\033[0m] " fmt, snrt_cluster_idx(),                 \
                  snrt_cluster_core_idx(), __func__, ##__VA_ARGS__);                               \
  })
#define snrt_info(fmt, ...)                                                                        \
  ({                                                                                               \
    if (LOG_INFO <= snrt_log_level)                                                                \
      snrt_printf("[\033[33msnrt(%d,%d):info:%s\033[0m] " fmt, snrt_cluster_idx(),                 \
                  snrt_cluster_core_idx(), __func__, ##__VA_ARGS__);                               \
  })
#define snrt_debug(fmt, ...)                                                                       \
  ({                                                                                               \
    if (LOG_DEBUG <= snrt_log_level)                                                               \
      snrt_printf("[\033[35msnrt(%d,%d):debug:%s\033[0m] " fmt, snrt_cluster_idx(),                \
                  snrt_cluster_core_idx(), __func__, ##__VA_ARGS__);                               \
  })
#define snrt_trace(fmt, ...)                                                                       \
  ({                                                                                               \
    if (LOG_TRACE <= snrt_log_level)                                                               \
      snrt_printf("[\033[96msnrt(%d,%d):trace:%s\033[0m] " fmt, snrt_cluster_idx(),                \
                  snrt_cluster_core_idx(), __func__, ##__VA_ARGS__);                               \
  })

#else // #if defined(DEBUG)

#define snrt_error(x...)                                                                           \
  do {                                                                                             \
  } while (0)
#define snrt_warn(x...)                                                                            \
  do {                                                                                             \
  } while (0)
#define snrt_info(x...)                                                                            \
  do {                                                                                             \
  } while (0)
#define snrt_debug(x...)                                                                           \
  do {                                                                                             \
  } while (0)
#define snrt_trace(x...)                                                                           \
  do {                                                                                             \
  } while (0)

#endif // defined(SNRT_DEBUG)

#ifdef __cplusplus
}
#endif
