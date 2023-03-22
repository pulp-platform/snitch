// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * @brief Clear SW interrupt in CLINT
 * @details
 *
 * @param hartid Target interrupt to clear
 */
inline void snrt_int_sw_clear(uint32_t hartid) {
    snrt_mutex_acquire(snrt_clint_mutex_ptr());
    *(snrt_clint_msip_ptr(hartid)) &= ~(1 << (hartid & 0x1f));
    snrt_mutex_release(snrt_clint_mutex_ptr());
}

/**
 * @brief Set SW interrupt in CLINT
 * @details
 *
 * @param hartid Target interrupt to set
 */
inline void snrt_int_sw_set(uint32_t hartid) {
    snrt_mutex_acquire(snrt_clint_mutex_ptr());
    *(snrt_clint_msip_ptr(hartid)) |= (1 << (hartid & 0x1f));
    snrt_mutex_release(snrt_clint_mutex_ptr());
}

/**
 * @brief Read SW interrupt for hartid in CLINT
 *
 * @param hartid hartid to poll for interrupt flag
 * @return uint32_t 0 if no SW interrupt is pending, 1 otherwise
 */
inline uint32_t snrt_int_sw_get(uint32_t hartid) {
    snrt_mutex_acquire(snrt_clint_mutex_ptr());
    uint32_t ret = *(snrt_clint_msip_ptr(hartid)) >> (hartid & 0x1f);
    snrt_mutex_release(snrt_clint_mutex_ptr());
    return ret;
}
