// Copyright 2022 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <stdint.h>

#include "occamy.h"
#include "occamyRuntime.h"
#include "uart.h"


//===============================================================
// Globals
//===============================================================

extern volatile comm_buffer_t comm_buffer;

//===============================================================
// Initialization
//===============================================================

extern void initialize_bss();

extern void enable_fpu();

extern void set_d_cache_enable(uint16_t ena);

//===============================================================
// Snitch
//===============================================================

/**
 * @brief Programs the Snitches with the Snitch binary
 *
 * @detail After boot, the Snitches are "parked" on a WFI
 *         until they receive a software interrupt. Upon
 *         wakeup, the Snitch jumps to a minimal interrupt
 *         handler in boot ROM which loads the address of the
 *         user binary from the soc_ctrl_scratch_0 register.
 *         This routine programs the soc_ctrl_scratch_0 register
 *         with the address of the user binary.
 */
extern void program_snitches();

/**
 * @brief Wake-up Snitches
 *
 * @detail All Snitches are "parked" in a WFI. A SW interrupt
 *         must be issued to "unpark" every Snitch. This function
 *         sends a SW interrupt to all Snitches.
 */
extern void wakeup_snitches();

/**
 * @brief Wake-up Snitches
 *
 * @detail All Snitches are "parked" in a WFI. A SW interrupt
 *         must be issued to "unpark" every Snitch. This function
 *         sends a SW interrupt to a given range of Snitches.
 */
extern void wakeup_snitches_selective(uint32_t base_hartid, uint32_t num_harts,
                                      uint32_t stride);

/**
 * @brief Wake-up Snitches
 *
 * @detail All Snitches are "parked" in a WFI. A SW interrupt
 *         must be issued to "unpark" every Snitch. This function
 *         sends a SW interrupt to one Snitch in every cluster,
 *         the so called "master" of the cluster. The "master" is
 *         then expected to wake-up all the other Snitches in its
 *         cluster. The "master" Snitches can use the cluster-local
 *         CLINTs without sending requests outside the cluster,
 *         avoiding congestion.
 */
extern void wakeup_master_snitches();

/**
 * @brief Waits until snitches are parked in a `wfi` instruction
 *
 * @detail delays execution to wait for the Snitch cores to be ready.
 *         After being parked, the Snitch cores can accept an interrupt
 *         and start executing its binary
 */
extern void wait_snitches_parked();

/**
 * @brief Waits until snitches are done executing
 *
 * @detail After execution the Snitch cores return a value
 *         to the communication buffer
 */
extern void wait_snitches_done();

//===============================================================
// Synchronization and mutual exclusion
//===============================================================

extern void fence();

/**
 * @brief lock a mutex, blocking
 * @details test-and-set (tas) implementation of a lock.
 *          Declare mutex with `static volatile uint32_t mtx = 0;`
 */
extern void mutex_tas_lock(volatile uint32_t *pmtx);

/**
 * @brief lock a mutex, blocking
 * @details test-and-test-and-set (ttas) implementation of a lock.
 *          Declare mutex with `static volatile uint32_t mtx = 0;`
 */
extern void mutex_ttas_lock(volatile uint32_t *pmtx);

/**
 * @brief Release the mutex
 */
extern void mutex_release(volatile uint32_t *pmtx);

//===============================================================
// Interrupts
//===============================================================

extern void wfi();

extern void enable_sw_interrupts();

extern void clear_sw_interrupt(uint32_t hartid);

extern void set_sw_interrupt(uint32_t hartid);

extern void set_cluster_interrupt(uint32_t cluster_id, uint32_t core_id);

extern void wait_sw_interrupt();

/**
 * @brief Gets SW interrupt pending status from local CSR
 *
 * @detail Use this in favour of wait_remote_sw_interrupt_pending()
 *         when polling a core's own interrupt pending
 *         status. This avoids unnecessary congestion on the
 *         interconnect and shared CLINT.
 */
extern void wait_sw_interrupt_cleared();

/**
 * @brief Gets SW interrupt pending status from shared CLINT
 *
 * @detail Use wait_sw_interrupt_cleared() in favour of this
 *         when polling a core's own interrupt pending
 *         status. That function polls a local CSR instead
 *         of the shared CLINT.
 */
extern void wait_remote_sw_interrupt_pending(uint32_t hartid);

//===============================================================
// Timers
//===============================================================

extern void delay_ns(uint64_t delay);

//===============================================================
// Clocks and FLLs
//===============================================================

typedef enum { SYSTEM_CLK = 0, PERIPH_CLK = 1, HBM2E_CLK = 2 } clk_t;

/**
 * @brief Returns the multiplier to the reference frequency of the FLL
 */
extern uint32_t get_fll_freq(clk_t clk);

/**
 * @brief Measures frequency of clock source
 *
 * @return Frequency in GHz
 */
extern float measure_frequency(clk_t clk);

/**
 * @brief Derives system frequency through RISC-V's
 *        mtime memory-mapped register and mcycle CSR
 *
 * @param rtc_cycles Number of RTC cycles to wait for measurement.
 *                   The higher it is, the more precise the measurement.
 * @return Frequency in GHz
 */
extern float measure_system_frequency(uint32_t rtc_cycles);

/**
 * @brief Reprogram the FLL in closed-loop mode with the specified divider
 * @detail Blocking function, returns after the new frequency is locked
 */
extern void program_fll(clk_t clk, uint32_t divider);

//===============================================================
// Isolation
//
// The `iso_mask` argument recurs throughout this section.
// Each bit in the mask controls a specific isolation path around
// the quadrant (e.g. wide in, narrow out etc.).
//===============================================================

extern uint32_t const ISO_MASK_ALL;
extern uint32_t const ISO_MASK_NONE;

/**
 * @brief Check quadrant isolated or not
 *
 * @param iso_mask set bit to 1 to check if path is isolated, 0 de-isolated
 * @return 1 is check passes, 0 otherwise
 */
extern uint32_t check_isolated_timeout(uint32_t max_tries,
                                       uint32_t quadrant_mask,
                                       uint32_t iso_mask);

extern void isolate_quad(uint32_t quad_idx, uint32_t iso_mask);

extern void deisolate_quad(uint32_t quad_idx, uint32_t iso_mask);

inline void deisolate_all() {
    for (uint32_t i = 0; i < N_QUADS; ++i) deisolate_quad(i, ISO_MASK_ALL);
}

//===============================================================
// Reset and clock gating
//===============================================================

extern void set_reset_n_quad(uint32_t quad_idx, uint32_t value);

extern void set_clk_ena_quad(uint32_t quad_idx, uint32_t value);

extern void reset_and_ungate_quad(uint32_t quadrant_idx);

//===============================================================
// SoC configuration
//===============================================================

extern void activate_interleaved_mode_hbm();
extern void deactivate_interleaved_mode_hbm();
