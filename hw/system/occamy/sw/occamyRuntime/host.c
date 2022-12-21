// Copyright 2022 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "host.h"

#include "clint.h"
#include "occamy_addrmap.h"
#include "occamy_soc_ctrl.h"
#include "snitch_cluster_peripheral.h"
#include "snitch_hbm_xbar_peripheral.h"
#include "snitch_quad_peripheral.h"

// Handle multireg degeneration to single register
#if OCCAMY_SOC_ISOLATE_MULTIREG_COUNT == 1
#define OCCAMY_SOC_ISOLATE_0_REG_OFFSET OCCAMY_SOC_ISOLATE_REG_OFFSET
#define OCCAMY_SOC_ISOLATE_0_ISOLATE_0_MASK OCCAMY_SOC_ISOLATE_ISOLATE_0_MASK
#endif
#if OCCAMY_SOC_ISOLATED_MULTIREG_COUNT == 1
#define OCCAMY_SOC_ISOLATED_0_REG_OFFSET OCCAMY_SOC_ISOLATED_REG_OFFSET
#endif
#if OCCAMY_SOC_SCRATCH_MULTIREG_COUNT == 1
#define OCCAMY_SOC_SCRATCH_0_REG_OFFSET OCCAMY_SOC_SCRATCH_0_REG_OFFSET
#endif
#if CLINT_MSIP_MULTIREG_COUNT == 1
#define CLINT_MSIP_0_REG_OFFSET CLINT_MSIP_REG_OFFSET
#endif
#if OCCAMY_SOC_SCRATCH_MULTIREG_COUNT == 1
#define OCCAMY_SOC_SCRATCH_0_REG_OFFSET OCCAMY_SOC_SCRATCH_REG_OFFSET
#endif

//===============================================================
// RISC-V
//===============================================================

#define MIP_MTIP_OFFSET 7
#define MIP_MSIP_OFFSET 3
#define MIE_MSIE_OFFSET 3
#define MIE_MTIE_OFFSET 7
#define MSTATUS_MIE_OFFSET 3
#define MSTATUS_FS_OFFSET 13

//===============================================================
// Globals
//===============================================================

volatile comm_buffer_t comm_buffer __attribute__ ((aligned (8)));

//===============================================================
// Memory map pointers
//===============================================================

#if SELECT_FLL == 0  // ETH FLL
volatile uint32_t* const fll_system_base =
    (volatile uint32_t*)FLL_SYSTEM_BASE_ADDR;
volatile uint32_t* const fll_periph_base =
    (volatile uint32_t*)FLL_PERIPH_BASE_ADDR;
volatile uint32_t* const fll_hbm2e_base =
    (volatile uint32_t*)FLL_HBM2E_BASE_ADDR;
#elif SELECT_FLL == 1  // GF FLL
volatile uint32_t* const fll_system_base =
    (volatile uint32_t*)FLL_SYSTEM_BASE_ADDR + (0x200 >> 2);
volatile uint32_t* const fll_periph_base =
    (volatile uint32_t*)FLL_PERIPH_BASE_ADDR + (0x200 >> 2);
volatile uint32_t* const fll_hbm2e_base =
    (volatile uint32_t*)FLL_HBM2E_BASE_ADDR + (0x200 >> 2);
#endif

volatile uint32_t* const fll_base[N_CLOCKS] = {fll_system_base, fll_periph_base,
                                               fll_hbm2e_base};

volatile uint32_t* const clint_msip_base =
    (volatile uint32_t*)(CLINT_BASE_ADDR + CLINT_MSIP_0_REG_OFFSET);
volatile uint64_t* const clint_mtime_ptr =
    (volatile uint64_t*)(CLINT_BASE_ADDR + CLINT_MTIME_LOW_REG_OFFSET);
volatile uint64_t* const clint_mtimecmp0_ptr =
    (volatile uint64_t*)(CLINT_BASE_ADDR + CLINT_MTIMECMP_LOW0_REG_OFFSET);

volatile uint32_t* const soc_ctrl_scratch_base =
    (volatile uint32_t*)(SOC_CTRL_BASE_ADDR + OCCAMY_SOC_SCRATCH_0_REG_OFFSET);

// TODO remove hardcoded addresses
volatile uint32_t* const snitch_cluster_clint_set_base =
    (volatile uint32_t*)(0x10020000 +
                         SNITCH_CLUSTER_PERIPHERAL_CL_CLINT_SET_REG_OFFSET);
uint32_t const cluster_offset = 0x40000;

volatile void* const quadrant_cfg_base = (volatile void*)0x0b000000;
uint32_t const quadrant_cfg_offset = 0x10000;

//===============================================================
// Anticipated function declarations
//===============================================================

static inline void set_sw_interrupts_unsafe(uint32_t base_hartid,
                                            uint32_t num_harts,
                                            uint32_t stride);

//===============================================================
// Initialization
//===============================================================

void initialize_bss() {
    extern volatile uint64_t __bss_start, __bss_end;

    for (uint64_t* p = (uint64_t*)(&__bss_start); p < (uint64_t*)(&__bss_end);
         p++) {
        *p = 0;
    }
}

void enable_fpu() {
    uint64_t mstatus;

    asm volatile("csrr %[mstatus], mstatus" : [ mstatus ] "=r"(mstatus));
    mstatus |= (1 << MSTATUS_FS_OFFSET);
    asm volatile("csrw mstatus, %[mstatus]" : : [ mstatus ] "r"(mstatus));
}

void set_d_cache_enable(uint16_t ena) {
    asm volatile("csrw 0x701, %0" ::"r"(ena));
}

//===============================================================
// Synchronization and mutual exclusion
//===============================================================

void fence() { asm volatile("fence" : : : "memory"); }

void mutex_tas_lock(volatile uint32_t* pmtx) {
    asm volatile(
        "li            x5,1          # x5 = 1\n"
        "1:\n"
        "  amoswap.w.aq  x5,x5,(%0)   # x5 = oldlock & lock = 1\n"
        "  bnez          x5,1b      # Retry if previously set)\n"
        : "+r"(pmtx)
        :
        : "x5");
}

void mutex_ttas_lock(volatile uint32_t* pmtx) {
    asm volatile(
        "1:\n"
        "  lw x5, 0(%0)\n"
        "  bnez x5, 1b\n"
        "  li x5,1          # x5 = 1\n"
        "2:\n"
        "  amoswap.w.aq  x5,x5,(%0)   # x5 = oldlock & lock = 1\n"
        "  bnez          x5,2b      # Retry if previously set)\n"
        : "+r"(pmtx)
        :
        : "x5");
}

void mutex_release(volatile uint32_t* pmtx) {
    asm volatile("amoswap.w.rl  x0,x0,(%0)   # Release lock by storing 0\n"
                 : "+r"(pmtx));
}

//===============================================================
// Snitch
//===============================================================

extern void snitch_main();

static inline volatile uint32_t* soc_ctrl_scratch_ptr(uint32_t idx) {
    return soc_ctrl_scratch_base +
           (idx / OCCAMY_SOC_SCRATCH_SCRATCH_FIELDS_PER_REG);
}

void program_snitches() {
    *soc_ctrl_scratch_ptr(1) = (uintptr_t)snitch_main;
    *soc_ctrl_scratch_ptr(2) = (uintptr_t)&comm_buffer;
}

static inline volatile uint32_t* get_shared_lock() { return &(comm_buffer.lock); }

static inline void wakeup_snitch(uint32_t hartid) { set_sw_interrupt(hartid); }

// TODO: implement in a more robust manner
void wait_snitches_parked(uint32_t timeout) { delay_ns(100000); }

void wakeup_snitches() {
    volatile uint32_t* lock = get_shared_lock();

    mutex_ttas_lock(lock);
    set_sw_interrupts_unsafe(1, N_SNITCHES, 1);
    mutex_release(lock);
}

void wakeup_snitches_selective(uint32_t base_hartid, uint32_t num_harts,
                               uint32_t stride) {
    volatile uint32_t* lock = get_shared_lock();

    mutex_ttas_lock(lock);
    set_sw_interrupts_unsafe(base_hartid, num_harts, stride);
    mutex_release(lock);
}

void wakeup_master_snitches() {
    volatile uint32_t* lock = get_shared_lock();

    mutex_ttas_lock(lock);
    set_sw_interrupts_unsafe(1, N_CLUSTERS, N_CORES_PER_CLUSTER);
    mutex_release(lock);
}

void wait_snitches_done() {
    wait_sw_interrupt();
    clear_sw_interrupt(0);
}

//===============================================================
// Interrupts
//===============================================================

static inline volatile uint32_t* clint_msip_hart_ptr(uint32_t hartid) {
    return clint_msip_base + (hartid / CLINT_MSIP_P_FIELDS_PER_REG);
}

static inline uint32_t get_clint_msip_hart(uint32_t hartid) {
    uint32_t field_offset = hartid % CLINT_MSIP_P_FIELDS_PER_REG;
    uint32_t lsb_offset = field_offset * CLINT_MSIP_P_FIELD_WIDTH;
    return (*clint_msip_hart_ptr(hartid) >> lsb_offset) & 1;
}

static inline volatile uint32_t* cluster_clint_set_ptr(uint32_t cluster_id) {
    return snitch_cluster_clint_set_base + ((cluster_offset / 4) * cluster_id);
}

/**
 * @brief Gets SW interrupt pending status from CLINT
 *
 * @detail Use sw_interrupt_pending() in favour of this
 *         when polling a core's own interrupt pending
 *         status. That function interrogates a local CSR
 *         instead of the shared CLINT.
 */
static inline uint32_t remote_sw_interrupt_pending(uint32_t hartid) {
    return get_clint_msip_hart(hartid);
}

/**
 * @brief Gets SW interrupt pending status from local CSR
 *
 * @detail Use this in favour of remote_sw_interrupt_pending()
 *         when polling a core's own interrupt pending
 *         status. This avoids unnecessary congestion on the
 *         interconnect and shared CLINT.
 */
static inline uint32_t sw_interrupt_pending() {
    uint64_t mip;

    asm volatile("csrr %[mip], mip" : [ mip ] "=r"(mip));
    return mip & (1 << MIP_MSIP_OFFSET);
}

static inline uint32_t timer_interrupts_enabled() {
    uint64_t mie;
    asm volatile("csrr %[mie], mie" : [ mie ] "=r"(mie));
    return (mie >> MIE_MTIE_OFFSET) & 1;
}

static inline void clear_sw_interrupt_unsafe(uint32_t hartid) {
    uint32_t field_offset = hartid % CLINT_MSIP_P_FIELDS_PER_REG;
    uint32_t lsb_offset = field_offset * CLINT_MSIP_P_FIELD_WIDTH;

    *clint_msip_hart_ptr(hartid) &= ~(1 << lsb_offset);
}

static inline void set_sw_interrupt_unsafe(uint32_t hartid) {
    uint32_t field_offset = hartid % CLINT_MSIP_P_FIELDS_PER_REG;
    uint32_t lsb_offset = field_offset * CLINT_MSIP_P_FIELD_WIDTH;

    *clint_msip_hart_ptr(hartid) |= (1 << lsb_offset);
}

void clear_sw_interrupt(uint32_t hartid) {
    volatile uint32_t* shared_lock = get_shared_lock();

    mutex_ttas_lock(shared_lock);
    clear_sw_interrupt_unsafe(hartid);
    mutex_release(shared_lock);
}

void set_sw_interrupt(uint32_t hartid) {
    volatile uint32_t* shared_lock = get_shared_lock();

    mutex_ttas_lock(shared_lock);
    set_sw_interrupt_unsafe(hartid);
    mutex_release(shared_lock);
}

static inline void set_sw_interrupts_unsafe(uint32_t base_hartid,
                                            uint32_t num_harts,
                                            uint32_t stride) {
    volatile uint32_t* ptr = clint_msip_hart_ptr(base_hartid);

    uint32_t num_fields = num_harts;
    uint32_t field_idx = base_hartid;
    uint32_t field_offset = field_idx % CLINT_MSIP_P_FIELDS_PER_REG;
    uint32_t reg_idx = field_idx / CLINT_MSIP_P_FIELDS_PER_REG;
    uint32_t prev_reg_idx = reg_idx;
    uint32_t mask = 0;
    uint32_t reg_jump;
    uint32_t last_field = num_fields - 1;

    for (uint32_t i = 0; i < num_fields; i++) {
        // put field in mask
        mask |= 1 << field_offset;

        // calculate next field info
        field_idx += stride;
        field_offset = field_idx % CLINT_MSIP_P_FIELDS_PER_REG;
        reg_idx = field_idx / CLINT_MSIP_P_FIELDS_PER_REG;
        reg_jump = reg_idx - prev_reg_idx;

        // if next value is in another register
        if (i != last_field && reg_jump) {
            // store mask
            if (mask == (uint32_t)(-1))
                *ptr = mask;
            else
                *ptr |= mask;
            // update pointer and reset mask
            ptr += reg_jump;
            prev_reg_idx = reg_idx;
            mask = 0;
        }
    }

    // store last mask
    *ptr |= mask;
}

void set_cluster_interrupt(uint32_t cluster_id, uint32_t core_id) {
    *(cluster_clint_set_ptr(cluster_id)) |= (1 << core_id);
}

static inline uint32_t timer_interrupt_pending() {
    uint64_t mip;

    asm volatile("csrr %[mip], mip" : [ mip ] "=r"(mip));
    return mip & (1 << MIP_MTIP_OFFSET);
}

void wfi() { asm volatile("wfi"); }

// TODO: for portability to architectures where WFI is implemented as a NOP
//       also sw_interrupts_enabled() should be checked
void wait_sw_interrupt() {
    do
        wfi();
    while (!sw_interrupt_pending());
}

void wait_timer_interrupt() {
    do
        wfi();
    while (!timer_interrupt_pending() && timer_interrupts_enabled());
}

void enable_global_interrupts() {
    uint64_t mstatus;

    asm volatile("csrr %[mstatus], mstatus" : [ mstatus ] "=r"(mstatus));
    mstatus |= (1 << MSTATUS_MIE_OFFSET);
    asm volatile("csrw mstatus, %[mstatus]" : : [ mstatus ] "r"(mstatus));
}

void enable_timer_interrupts() {
    uint64_t mie;

    asm volatile("csrr %[mie], mie" : [ mie ] "=r"(mie));
    mie |= (1 << MIE_MTIE_OFFSET);
    asm volatile("csrw mie, %[mie]" : : [ mie ] "r"(mie));
}

void disable_timer_interrupts() {
    uint64_t mie;

    asm volatile("csrr %[mie], mie" : [ mie ] "=r"(mie));
    mie &= ~(1 << MIE_MTIE_OFFSET);
    asm volatile("csrw mie, %[mie]" : : [ mie ] "r"(mie));
}

void enable_sw_interrupts() {
    uint64_t mie;

    asm volatile("csrr %[mie], mie" : [ mie ] "=r"(mie));
    mie |= (1 << MIE_MSIE_OFFSET);
    asm volatile("csrw mie, %[mie]" : : [ mie ] "r"(mie));
}

void disable_sw_interrupts() {
    uint64_t mie;

    asm volatile("csrr %[mie], mie" : [ mie ] "=r"(mie));
    mie &= ~(1 << MIE_MSIE_OFFSET);
    asm volatile("csrw mie, %[mie]" : : [ mie ] "r"(mie));
}

void wait_sw_interrupt_cleared() {
    while (sw_interrupt_pending())
        ;
}

void wait_remote_sw_interrupt_pending(uint32_t hartid) {
    while (remote_sw_interrupt_pending(hartid))
        ;
}

//===============================================================
// Timers
//===============================================================

static inline uint64_t mtime() { return *clint_mtime_ptr; }

static inline uint64_t mcycle() {
    uint64_t mcycle;
    asm volatile("csrr %[sc], mcycle" : [ sc ] "=r"(mcycle));
    return mcycle;
}

void set_timer_interrupt(uint64_t interval_ns) {
    // Convert ns to RTC unit
    uint64_t rtc_interval = interval_ns / (int64_t)rtc_period;

    // Offset interval by current time
    *clint_mtimecmp0_ptr = mtime() + rtc_interval;
}

/**
 * @brief Clears timer interrupt
 *
 * @detail Pending timer interrupts are cleared in HW when
 *         writing to the mtimecmp register. Note that
 *         eventually the mtime register is going to be greater
 *         than the newly programmed mtimecmp register, reasserting
 *         the pending bit. If this is not desired, it is safer
 *         to disable the timer interrupt before clearing it.
 */
void clear_timer_interrupt() { *clint_mtimecmp0_ptr = mtime() + 1; }

// Minimum delay is of one RTC period
void delay_ns(uint64_t delay) {
    set_timer_interrupt(delay);

    // Wait for set_timer_interrupt() to have effect
    fence();
    enable_timer_interrupts();

    wait_timer_interrupt();
    disable_timer_interrupts();
    clear_timer_interrupt();
}

//===============================================================
// Clocks and FLLs
//===============================================================

// #define N_LOCK_CYCLES 10

// static inline void fll_reg_write_u32(clk_t clk, uint32_t byte_offset,
// uint32_t val) {
//     *(fll_base[clk] + (byte_offset / 4)) = val;
// }

// static inline uint32_t fll_reg_read_u32(clk_t clk, uint32_t byte_offset) {
//     return *(fll_base[clk] + (byte_offset / 4));
// }

// uint32_t get_fll_freq(clk_t clk) {
// #if SELECT_FLL==0 // ETH FLL
//     return fll_reg_read_u32(clk, ETH_FLL_STATUS_I_REG_OFFSET) &
//     ETH_FLL_STATUS_I_MULTIPLIER_MASK;
// #elif SELECT_FLL==1 // GF FLL
//     return fll_reg_read_u32(clk, FLL_FREQ_REG_OFFSET);
// #endif
// }

// uint32_t fll_locked(clk_t clk) {
// #if SELECT_FLL==0 // ETH FLL
//     return fll_reg_read_u32(clk, ETH_FLL_LOCK_REG_OFFSET) &
//     ETH_FLL_LOCK_LOCKED_MASK;
// #elif SELECT_FLL==1 // GF FLL
//     return fll_reg_read_u32(clk, FLL_STATE_REG_OFFSET) == 3;
// #endif
// }

// float measure_frequency(clk_t clk) {
//     return freq_meter_ref_freqs[clk] * get_fll_freq(clk);
// }

// float measure_system_frequency(uint32_t rtc_cycles) {
//     uint64_t start_cycle;
//     uint64_t end_cycle;
//     float time_delta;
//     uint64_t cycle_delta;

//     // Compute time delta
//     time_delta = rtc_cycles * rtc_period;

//     // Measure cycle delta
//     start_cycle = mcycle();
//     delay_ns(time_delta);
//     end_cycle = mcycle();
//     cycle_delta = end_cycle - start_cycle;

//     // Return frequency
//     return cycle_delta / time_delta;
// }

// void program_fll(clk_t clk, uint32_t divider) {
// #if SELECT_FLL==0 // ETH FLL
//     // Reconfigure FLL
//     uint32_t val = 0;
//     val |= 1 << 31;     // Select closed loop mode
//     val |= 1 << 30;     // Gate output by LOCK signal
//     val |= 1 << 26;     // Set post-clock divider to 1 (neutral)
//     val |= divider - 1; // Set refclk multiplier to specified value
//     fll_reg_write_u32(clk, ETH_FLL_CONFIG_I_REG_OFFSET, val);
//     // Wait new frequency locked
//     while (!fll_locked(clk));
// #elif SELECT_FLL==1 // GF FLL
//     // Fallback to reference clock during reconfiguration
//     fll_reg_write_u32(clk, FLL_BYPASS_REG_OFFSET,      1);
//     // Disable DFG IP clock generation during reconfiguration
//     fll_reg_write_u32(clk, FLL_CLKGENEN_REG_OFFSET,    0);
//     // Reconfigure DFG IP input signals
//     fll_reg_write_u32(clk, FLL_FIXLENMODE_REG_OFFSET,  0); // Closed-loop
//     mode fll_reg_write_u32(clk, FLL_FBDIV_REG_OFFSET,       divider - 1);
//     fll_reg_write_u32(clk, FLL_CLKDIV_REG_OFFSET,      0);
//     fll_reg_write_u32(clk, FLL_CLKSRCSEL_REG_OFFSET,   1);
//     // Reconfigure lock settings
//     fll_reg_write_u32(clk, FLL_UPPERTHRESH_REG_OFFSET, divider + 1);
//     fll_reg_write_u32(clk, FLL_LOWERTHRESH_REG_OFFSET, divider - 1);
//     fll_reg_write_u32(clk, FLL_LOCKCYCLES_REG_OFFSET,  N_LOCK_CYCLES);
//     // Enable DFG IP clock generation after new settings are applied
//     fll_reg_write_u32(clk, FLL_CLKGENEN_REG_OFFSET,    1);
//     // Wait new frequency locked
//     while (!fll_locked(clk));
//     // Disable bypass of DFG clock
//     fll_reg_write_u32(clk, FLL_BYPASS_REG_OFFSET,      0);
// #endif
// }

//===============================================================
// Isolation
//===============================================================

uint32_t const ISO_MASK_ALL = 0b1111;
uint32_t const ISO_MASK_NONE = 0;

static inline volatile uint32_t* soc_regs_isolate_quad_ptr(uint32_t quad_idx) {
    return quadrant_cfg_base + (quad_idx * quadrant_cfg_offset) +
           OCCAMY_QUADRANT_S1_ISOLATE_REG_OFFSET;
}

static inline volatile uint32_t* soc_regs_isolated_quad_ptr(uint32_t quad_idx) {
    return quadrant_cfg_base + (quad_idx * quadrant_cfg_offset) +
           OCCAMY_QUADRANT_S1_ISOLATED_REG_OFFSET;
}

/**
 * @brief Loads the "isolated" register field for the quadrant requested
 *
 * @return Masked register field realigned to start at LSB
 */
static inline uint32_t get_soc_regs_isolated_quad(uint32_t quad_idx) {
    return *soc_regs_isolated_quad_ptr(quad_idx) & ISO_MASK_ALL;
}

void isolate_quad(uint32_t quad_idx, uint32_t iso_mask) {
    *soc_regs_isolate_quad_ptr(quad_idx) |= iso_mask;
    fence();
}

void deisolate_quad(uint32_t quad_idx, uint32_t iso_mask) {
    *soc_regs_isolate_quad_ptr(quad_idx) &= ~iso_mask;
    fence();
}

extern void deisolate_all();

uint32_t check_isolated_timeout(uint32_t max_tries, uint32_t quadrant_idx,
                                uint32_t iso_mask) {
    for (uint32_t i = 0; i < max_tries; ++i)
        if (get_soc_regs_isolated_quad(quadrant_idx) == iso_mask) return 1;
    return 0;
}

//===============================================================
// Reset and clock gating
//===============================================================

static inline volatile uint32_t* soc_regs_reset_n_quad_ptr(uint32_t quad_idx) {
    return quadrant_cfg_base + (quad_idx * quadrant_cfg_offset) +
           OCCAMY_QUADRANT_S1_RESET_N_REG_OFFSET;
}

static inline volatile uint32_t* soc_regs_clk_ena_quad_ptr(uint32_t quad_idx) {
    return quadrant_cfg_base + (quad_idx * quadrant_cfg_offset) +
           OCCAMY_QUADRANT_S1_CLK_ENA_REG_OFFSET;
}

void set_reset_n_quad(uint32_t quad_idx, uint32_t value) {
    *soc_regs_reset_n_quad_ptr(quad_idx) = value & 0x1;
    fence();
}

void set_clk_ena_quad(uint32_t quad_idx, uint32_t value) {
    *soc_regs_clk_ena_quad_ptr(quad_idx) = value & 0x1;
    fence();
}

void reset_and_ungate_quad(uint32_t quadrant_idx) {
    set_clk_ena_quad(quadrant_idx, 0);
    set_reset_n_quad(quadrant_idx, 0);
    set_reset_n_quad(quadrant_idx, 1);
    set_clk_ena_quad(quadrant_idx, 1);
}

//===============================================================
// SoC configuration
//===============================================================

void activate_interleaved_mode_hbm() {
    uint64_t addr =
        OCCAMY_HBM_XBAR_INTERLEAVED_ENA_REG_OFFSET + HBM_XBAR_CFG_BASE_ADDR;
    *((volatile uint32_t*)addr) = 1;
}

void deactivate_interleaved_mode_hbm() {
    uint64_t addr =
        OCCAMY_HBM_XBAR_INTERLEAVED_ENA_REG_OFFSET + HBM_XBAR_CFG_BASE_ADDR;
    *((volatile uint32_t*)addr) = 1;
}
