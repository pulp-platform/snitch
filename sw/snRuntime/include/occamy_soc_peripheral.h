// Generated register defines for Occamy_SoC

// Copyright information found in source file:
// Copyright 2020 ETH Zurich and University of Bologna.

// Licensing information found in source file:
// Licensed under Solderpad Hardware License, Version 0.51, see LICENSE for
// details. SPDX-License-Identifier: SHL-0.51

#ifndef _OCCAMY_SOC_REG_DEFS_
#define _OCCAMY_SOC_REG_DEFS_

#ifdef __cplusplus
extern "C" {
#endif
// Number of scratch registers
#define OCCAMY_SOC_PARAM_NUM_SCRATCH_REGS 4

// Number of GPIO pads in the chip.
#define OCCAMY_SOC_PARAM_NUM_PADS 31

// Number of S1 Quadrants.
#define OCCAMY_SOC_PARAM_NUM_S1_QUADRANTS 8

// Register width
#define OCCAMY_SOC_PARAM_REG_WIDTH 32

// Common Interrupt Offsets
#define OCCAMY_SOC_INTR_COMMON_ECC_UNCORRECTABLE_BIT 0
#define OCCAMY_SOC_INTR_COMMON_ECC_CORRECTABLE_BIT 1

// Interrupt State Register
#define OCCAMY_SOC_INTR_STATE_REG_OFFSET 0x0
#define OCCAMY_SOC_INTR_STATE_ECC_UNCORRECTABLE_BIT 0
#define OCCAMY_SOC_INTR_STATE_ECC_CORRECTABLE_BIT 1

// Interrupt Enable Register
#define OCCAMY_SOC_INTR_ENABLE_REG_OFFSET 0x4
#define OCCAMY_SOC_INTR_ENABLE_ECC_UNCORRECTABLE_BIT 0
#define OCCAMY_SOC_INTR_ENABLE_ECC_CORRECTABLE_BIT 1

// Interrupt Test Register
#define OCCAMY_SOC_INTR_TEST_REG_OFFSET 0x8
#define OCCAMY_SOC_INTR_TEST_ECC_UNCORRECTABLE_BIT 0
#define OCCAMY_SOC_INTR_TEST_ECC_CORRECTABLE_BIT 1

// Version register, should read 1.
#define OCCAMY_SOC_VERSION_REG_OFFSET 0xc
#define OCCAMY_SOC_VERSION_VERSION_MASK 0xffff
#define OCCAMY_SOC_VERSION_VERSION_OFFSET 0
#define OCCAMY_SOC_VERSION_VERSION_FIELD                           \
    ((bitfield_field32_t){.mask = OCCAMY_SOC_VERSION_VERSION_MASK, \
                          .index = OCCAMY_SOC_VERSION_VERSION_OFFSET})

// Id of chip for multi-chip systems.
#define OCCAMY_SOC_CHIP_ID_REG_OFFSET 0x10
#define OCCAMY_SOC_CHIP_ID_CHIP_ID_MASK 0x3
#define OCCAMY_SOC_CHIP_ID_CHIP_ID_OFFSET 0
#define OCCAMY_SOC_CHIP_ID_CHIP_ID_FIELD                           \
    ((bitfield_field32_t){.mask = OCCAMY_SOC_CHIP_ID_CHIP_ID_MASK, \
                          .index = OCCAMY_SOC_CHIP_ID_CHIP_ID_OFFSET})

// Scratch register for SW to write to. (common parameters)
#define OCCAMY_SOC_SCRATCH_SCRATCH_FIELD_WIDTH 32
#define OCCAMY_SOC_SCRATCH_SCRATCH_FIELDS_PER_REG 1
#define OCCAMY_SOC_SCRATCH_MULTIREG_COUNT 4

// Scratch register for SW to write to.
#define OCCAMY_SOC_SCRATCH_0_REG_OFFSET 0x14

// Scratch register for SW to write to.
#define OCCAMY_SOC_SCRATCH_1_REG_OFFSET 0x18

// Scratch register for SW to write to.
#define OCCAMY_SOC_SCRATCH_2_REG_OFFSET 0x1c

// Scratch register for SW to write to.
#define OCCAMY_SOC_SCRATCH_3_REG_OFFSET 0x20

// Selected boot mode exposed a register.
#define OCCAMY_SOC_BOOT_MODE_REG_OFFSET 0x24
#define OCCAMY_SOC_BOOT_MODE_MODE_MASK 0x3
#define OCCAMY_SOC_BOOT_MODE_MODE_OFFSET 0
#define OCCAMY_SOC_BOOT_MODE_MODE_FIELD                           \
    ((bitfield_field32_t){.mask = OCCAMY_SOC_BOOT_MODE_MODE_MASK, \
                          .index = OCCAMY_SOC_BOOT_MODE_MODE_OFFSET})
#define OCCAMY_SOC_BOOT_MODE_MODE_VALUE_IDLE 0x0
#define OCCAMY_SOC_BOOT_MODE_MODE_VALUE_SERIAL 0x1
#define OCCAMY_SOC_BOOT_MODE_MODE_VALUE_I2C 0x2

// GPIO pad configuration. (common parameters)
// GPIO pad configuration.
#define OCCAMY_SOC_PAD_0_REG_OFFSET 0x28
#define OCCAMY_SOC_PAD_0_SLW_0_BIT 0
#define OCCAMY_SOC_PAD_0_SMT_0_BIT 1
#define OCCAMY_SOC_PAD_0_DRV_0_MASK 0x3
#define OCCAMY_SOC_PAD_0_DRV_0_OFFSET 2
#define OCCAMY_SOC_PAD_0_DRV_0_FIELD                           \
    ((bitfield_field32_t){.mask = OCCAMY_SOC_PAD_0_DRV_0_MASK, \
                          .index = OCCAMY_SOC_PAD_0_DRV_0_OFFSET})

// GPIO pad configuration.
#define OCCAMY_SOC_PAD_1_REG_OFFSET 0x2c
#define OCCAMY_SOC_PAD_1_SLW_1_BIT 0
#define OCCAMY_SOC_PAD_1_SMT_1_BIT 1
#define OCCAMY_SOC_PAD_1_DRV_1_MASK 0x3
#define OCCAMY_SOC_PAD_1_DRV_1_OFFSET 2
#define OCCAMY_SOC_PAD_1_DRV_1_FIELD                           \
    ((bitfield_field32_t){.mask = OCCAMY_SOC_PAD_1_DRV_1_MASK, \
                          .index = OCCAMY_SOC_PAD_1_DRV_1_OFFSET})

// GPIO pad configuration.
#define OCCAMY_SOC_PAD_2_REG_OFFSET 0x30
#define OCCAMY_SOC_PAD_2_SLW_2_BIT 0
#define OCCAMY_SOC_PAD_2_SMT_2_BIT 1
#define OCCAMY_SOC_PAD_2_DRV_2_MASK 0x3
#define OCCAMY_SOC_PAD_2_DRV_2_OFFSET 2
#define OCCAMY_SOC_PAD_2_DRV_2_FIELD                           \
    ((bitfield_field32_t){.mask = OCCAMY_SOC_PAD_2_DRV_2_MASK, \
                          .index = OCCAMY_SOC_PAD_2_DRV_2_OFFSET})

// GPIO pad configuration.
#define OCCAMY_SOC_PAD_3_REG_OFFSET 0x34
#define OCCAMY_SOC_PAD_3_SLW_3_BIT 0
#define OCCAMY_SOC_PAD_3_SMT_3_BIT 1
#define OCCAMY_SOC_PAD_3_DRV_3_MASK 0x3
#define OCCAMY_SOC_PAD_3_DRV_3_OFFSET 2
#define OCCAMY_SOC_PAD_3_DRV_3_FIELD                           \
    ((bitfield_field32_t){.mask = OCCAMY_SOC_PAD_3_DRV_3_MASK, \
                          .index = OCCAMY_SOC_PAD_3_DRV_3_OFFSET})

// GPIO pad configuration.
#define OCCAMY_SOC_PAD_4_REG_OFFSET 0x38
#define OCCAMY_SOC_PAD_4_SLW_4_BIT 0
#define OCCAMY_SOC_PAD_4_SMT_4_BIT 1
#define OCCAMY_SOC_PAD_4_DRV_4_MASK 0x3
#define OCCAMY_SOC_PAD_4_DRV_4_OFFSET 2
#define OCCAMY_SOC_PAD_4_DRV_4_FIELD                           \
    ((bitfield_field32_t){.mask = OCCAMY_SOC_PAD_4_DRV_4_MASK, \
                          .index = OCCAMY_SOC_PAD_4_DRV_4_OFFSET})

// GPIO pad configuration.
#define OCCAMY_SOC_PAD_5_REG_OFFSET 0x3c
#define OCCAMY_SOC_PAD_5_SLW_5_BIT 0
#define OCCAMY_SOC_PAD_5_SMT_5_BIT 1
#define OCCAMY_SOC_PAD_5_DRV_5_MASK 0x3
#define OCCAMY_SOC_PAD_5_DRV_5_OFFSET 2
#define OCCAMY_SOC_PAD_5_DRV_5_FIELD                           \
    ((bitfield_field32_t){.mask = OCCAMY_SOC_PAD_5_DRV_5_MASK, \
                          .index = OCCAMY_SOC_PAD_5_DRV_5_OFFSET})

// GPIO pad configuration.
#define OCCAMY_SOC_PAD_6_REG_OFFSET 0x40
#define OCCAMY_SOC_PAD_6_SLW_6_BIT 0
#define OCCAMY_SOC_PAD_6_SMT_6_BIT 1
#define OCCAMY_SOC_PAD_6_DRV_6_MASK 0x3
#define OCCAMY_SOC_PAD_6_DRV_6_OFFSET 2
#define OCCAMY_SOC_PAD_6_DRV_6_FIELD                           \
    ((bitfield_field32_t){.mask = OCCAMY_SOC_PAD_6_DRV_6_MASK, \
                          .index = OCCAMY_SOC_PAD_6_DRV_6_OFFSET})

// GPIO pad configuration.
#define OCCAMY_SOC_PAD_7_REG_OFFSET 0x44
#define OCCAMY_SOC_PAD_7_SLW_7_BIT 0
#define OCCAMY_SOC_PAD_7_SMT_7_BIT 1
#define OCCAMY_SOC_PAD_7_DRV_7_MASK 0x3
#define OCCAMY_SOC_PAD_7_DRV_7_OFFSET 2
#define OCCAMY_SOC_PAD_7_DRV_7_FIELD                           \
    ((bitfield_field32_t){.mask = OCCAMY_SOC_PAD_7_DRV_7_MASK, \
                          .index = OCCAMY_SOC_PAD_7_DRV_7_OFFSET})

// GPIO pad configuration.
#define OCCAMY_SOC_PAD_8_REG_OFFSET 0x48
#define OCCAMY_SOC_PAD_8_SLW_8_BIT 0
#define OCCAMY_SOC_PAD_8_SMT_8_BIT 1
#define OCCAMY_SOC_PAD_8_DRV_8_MASK 0x3
#define OCCAMY_SOC_PAD_8_DRV_8_OFFSET 2
#define OCCAMY_SOC_PAD_8_DRV_8_FIELD                           \
    ((bitfield_field32_t){.mask = OCCAMY_SOC_PAD_8_DRV_8_MASK, \
                          .index = OCCAMY_SOC_PAD_8_DRV_8_OFFSET})

// GPIO pad configuration.
#define OCCAMY_SOC_PAD_9_REG_OFFSET 0x4c
#define OCCAMY_SOC_PAD_9_SLW_9_BIT 0
#define OCCAMY_SOC_PAD_9_SMT_9_BIT 1
#define OCCAMY_SOC_PAD_9_DRV_9_MASK 0x3
#define OCCAMY_SOC_PAD_9_DRV_9_OFFSET 2
#define OCCAMY_SOC_PAD_9_DRV_9_FIELD                           \
    ((bitfield_field32_t){.mask = OCCAMY_SOC_PAD_9_DRV_9_MASK, \
                          .index = OCCAMY_SOC_PAD_9_DRV_9_OFFSET})

// GPIO pad configuration.
#define OCCAMY_SOC_PAD_10_REG_OFFSET 0x50
#define OCCAMY_SOC_PAD_10_SLW_10_BIT 0
#define OCCAMY_SOC_PAD_10_SMT_10_BIT 1
#define OCCAMY_SOC_PAD_10_DRV_10_MASK 0x3
#define OCCAMY_SOC_PAD_10_DRV_10_OFFSET 2
#define OCCAMY_SOC_PAD_10_DRV_10_FIELD                           \
    ((bitfield_field32_t){.mask = OCCAMY_SOC_PAD_10_DRV_10_MASK, \
                          .index = OCCAMY_SOC_PAD_10_DRV_10_OFFSET})

// GPIO pad configuration.
#define OCCAMY_SOC_PAD_11_REG_OFFSET 0x54
#define OCCAMY_SOC_PAD_11_SLW_11_BIT 0
#define OCCAMY_SOC_PAD_11_SMT_11_BIT 1
#define OCCAMY_SOC_PAD_11_DRV_11_MASK 0x3
#define OCCAMY_SOC_PAD_11_DRV_11_OFFSET 2
#define OCCAMY_SOC_PAD_11_DRV_11_FIELD                           \
    ((bitfield_field32_t){.mask = OCCAMY_SOC_PAD_11_DRV_11_MASK, \
                          .index = OCCAMY_SOC_PAD_11_DRV_11_OFFSET})

// GPIO pad configuration.
#define OCCAMY_SOC_PAD_12_REG_OFFSET 0x58
#define OCCAMY_SOC_PAD_12_SLW_12_BIT 0
#define OCCAMY_SOC_PAD_12_SMT_12_BIT 1
#define OCCAMY_SOC_PAD_12_DRV_12_MASK 0x3
#define OCCAMY_SOC_PAD_12_DRV_12_OFFSET 2
#define OCCAMY_SOC_PAD_12_DRV_12_FIELD                           \
    ((bitfield_field32_t){.mask = OCCAMY_SOC_PAD_12_DRV_12_MASK, \
                          .index = OCCAMY_SOC_PAD_12_DRV_12_OFFSET})

// GPIO pad configuration.
#define OCCAMY_SOC_PAD_13_REG_OFFSET 0x5c
#define OCCAMY_SOC_PAD_13_SLW_13_BIT 0
#define OCCAMY_SOC_PAD_13_SMT_13_BIT 1
#define OCCAMY_SOC_PAD_13_DRV_13_MASK 0x3
#define OCCAMY_SOC_PAD_13_DRV_13_OFFSET 2
#define OCCAMY_SOC_PAD_13_DRV_13_FIELD                           \
    ((bitfield_field32_t){.mask = OCCAMY_SOC_PAD_13_DRV_13_MASK, \
                          .index = OCCAMY_SOC_PAD_13_DRV_13_OFFSET})

// GPIO pad configuration.
#define OCCAMY_SOC_PAD_14_REG_OFFSET 0x60
#define OCCAMY_SOC_PAD_14_SLW_14_BIT 0
#define OCCAMY_SOC_PAD_14_SMT_14_BIT 1
#define OCCAMY_SOC_PAD_14_DRV_14_MASK 0x3
#define OCCAMY_SOC_PAD_14_DRV_14_OFFSET 2
#define OCCAMY_SOC_PAD_14_DRV_14_FIELD                           \
    ((bitfield_field32_t){.mask = OCCAMY_SOC_PAD_14_DRV_14_MASK, \
                          .index = OCCAMY_SOC_PAD_14_DRV_14_OFFSET})

// GPIO pad configuration.
#define OCCAMY_SOC_PAD_15_REG_OFFSET 0x64
#define OCCAMY_SOC_PAD_15_SLW_15_BIT 0
#define OCCAMY_SOC_PAD_15_SMT_15_BIT 1
#define OCCAMY_SOC_PAD_15_DRV_15_MASK 0x3
#define OCCAMY_SOC_PAD_15_DRV_15_OFFSET 2
#define OCCAMY_SOC_PAD_15_DRV_15_FIELD                           \
    ((bitfield_field32_t){.mask = OCCAMY_SOC_PAD_15_DRV_15_MASK, \
                          .index = OCCAMY_SOC_PAD_15_DRV_15_OFFSET})

// GPIO pad configuration.
#define OCCAMY_SOC_PAD_16_REG_OFFSET 0x68
#define OCCAMY_SOC_PAD_16_SLW_16_BIT 0
#define OCCAMY_SOC_PAD_16_SMT_16_BIT 1
#define OCCAMY_SOC_PAD_16_DRV_16_MASK 0x3
#define OCCAMY_SOC_PAD_16_DRV_16_OFFSET 2
#define OCCAMY_SOC_PAD_16_DRV_16_FIELD                           \
    ((bitfield_field32_t){.mask = OCCAMY_SOC_PAD_16_DRV_16_MASK, \
                          .index = OCCAMY_SOC_PAD_16_DRV_16_OFFSET})

// GPIO pad configuration.
#define OCCAMY_SOC_PAD_17_REG_OFFSET 0x6c
#define OCCAMY_SOC_PAD_17_SLW_17_BIT 0
#define OCCAMY_SOC_PAD_17_SMT_17_BIT 1
#define OCCAMY_SOC_PAD_17_DRV_17_MASK 0x3
#define OCCAMY_SOC_PAD_17_DRV_17_OFFSET 2
#define OCCAMY_SOC_PAD_17_DRV_17_FIELD                           \
    ((bitfield_field32_t){.mask = OCCAMY_SOC_PAD_17_DRV_17_MASK, \
                          .index = OCCAMY_SOC_PAD_17_DRV_17_OFFSET})

// GPIO pad configuration.
#define OCCAMY_SOC_PAD_18_REG_OFFSET 0x70
#define OCCAMY_SOC_PAD_18_SLW_18_BIT 0
#define OCCAMY_SOC_PAD_18_SMT_18_BIT 1
#define OCCAMY_SOC_PAD_18_DRV_18_MASK 0x3
#define OCCAMY_SOC_PAD_18_DRV_18_OFFSET 2
#define OCCAMY_SOC_PAD_18_DRV_18_FIELD                           \
    ((bitfield_field32_t){.mask = OCCAMY_SOC_PAD_18_DRV_18_MASK, \
                          .index = OCCAMY_SOC_PAD_18_DRV_18_OFFSET})

// GPIO pad configuration.
#define OCCAMY_SOC_PAD_19_REG_OFFSET 0x74
#define OCCAMY_SOC_PAD_19_SLW_19_BIT 0
#define OCCAMY_SOC_PAD_19_SMT_19_BIT 1
#define OCCAMY_SOC_PAD_19_DRV_19_MASK 0x3
#define OCCAMY_SOC_PAD_19_DRV_19_OFFSET 2
#define OCCAMY_SOC_PAD_19_DRV_19_FIELD                           \
    ((bitfield_field32_t){.mask = OCCAMY_SOC_PAD_19_DRV_19_MASK, \
                          .index = OCCAMY_SOC_PAD_19_DRV_19_OFFSET})

// GPIO pad configuration.
#define OCCAMY_SOC_PAD_20_REG_OFFSET 0x78
#define OCCAMY_SOC_PAD_20_SLW_20_BIT 0
#define OCCAMY_SOC_PAD_20_SMT_20_BIT 1
#define OCCAMY_SOC_PAD_20_DRV_20_MASK 0x3
#define OCCAMY_SOC_PAD_20_DRV_20_OFFSET 2
#define OCCAMY_SOC_PAD_20_DRV_20_FIELD                           \
    ((bitfield_field32_t){.mask = OCCAMY_SOC_PAD_20_DRV_20_MASK, \
                          .index = OCCAMY_SOC_PAD_20_DRV_20_OFFSET})

// GPIO pad configuration.
#define OCCAMY_SOC_PAD_21_REG_OFFSET 0x7c
#define OCCAMY_SOC_PAD_21_SLW_21_BIT 0
#define OCCAMY_SOC_PAD_21_SMT_21_BIT 1
#define OCCAMY_SOC_PAD_21_DRV_21_MASK 0x3
#define OCCAMY_SOC_PAD_21_DRV_21_OFFSET 2
#define OCCAMY_SOC_PAD_21_DRV_21_FIELD                           \
    ((bitfield_field32_t){.mask = OCCAMY_SOC_PAD_21_DRV_21_MASK, \
                          .index = OCCAMY_SOC_PAD_21_DRV_21_OFFSET})

// GPIO pad configuration.
#define OCCAMY_SOC_PAD_22_REG_OFFSET 0x80
#define OCCAMY_SOC_PAD_22_SLW_22_BIT 0
#define OCCAMY_SOC_PAD_22_SMT_22_BIT 1
#define OCCAMY_SOC_PAD_22_DRV_22_MASK 0x3
#define OCCAMY_SOC_PAD_22_DRV_22_OFFSET 2
#define OCCAMY_SOC_PAD_22_DRV_22_FIELD                           \
    ((bitfield_field32_t){.mask = OCCAMY_SOC_PAD_22_DRV_22_MASK, \
                          .index = OCCAMY_SOC_PAD_22_DRV_22_OFFSET})

// GPIO pad configuration.
#define OCCAMY_SOC_PAD_23_REG_OFFSET 0x84
#define OCCAMY_SOC_PAD_23_SLW_23_BIT 0
#define OCCAMY_SOC_PAD_23_SMT_23_BIT 1
#define OCCAMY_SOC_PAD_23_DRV_23_MASK 0x3
#define OCCAMY_SOC_PAD_23_DRV_23_OFFSET 2
#define OCCAMY_SOC_PAD_23_DRV_23_FIELD                           \
    ((bitfield_field32_t){.mask = OCCAMY_SOC_PAD_23_DRV_23_MASK, \
                          .index = OCCAMY_SOC_PAD_23_DRV_23_OFFSET})

// GPIO pad configuration.
#define OCCAMY_SOC_PAD_24_REG_OFFSET 0x88
#define OCCAMY_SOC_PAD_24_SLW_24_BIT 0
#define OCCAMY_SOC_PAD_24_SMT_24_BIT 1
#define OCCAMY_SOC_PAD_24_DRV_24_MASK 0x3
#define OCCAMY_SOC_PAD_24_DRV_24_OFFSET 2
#define OCCAMY_SOC_PAD_24_DRV_24_FIELD                           \
    ((bitfield_field32_t){.mask = OCCAMY_SOC_PAD_24_DRV_24_MASK, \
                          .index = OCCAMY_SOC_PAD_24_DRV_24_OFFSET})

// GPIO pad configuration.
#define OCCAMY_SOC_PAD_25_REG_OFFSET 0x8c
#define OCCAMY_SOC_PAD_25_SLW_25_BIT 0
#define OCCAMY_SOC_PAD_25_SMT_25_BIT 1
#define OCCAMY_SOC_PAD_25_DRV_25_MASK 0x3
#define OCCAMY_SOC_PAD_25_DRV_25_OFFSET 2
#define OCCAMY_SOC_PAD_25_DRV_25_FIELD                           \
    ((bitfield_field32_t){.mask = OCCAMY_SOC_PAD_25_DRV_25_MASK, \
                          .index = OCCAMY_SOC_PAD_25_DRV_25_OFFSET})

// GPIO pad configuration.
#define OCCAMY_SOC_PAD_26_REG_OFFSET 0x90
#define OCCAMY_SOC_PAD_26_SLW_26_BIT 0
#define OCCAMY_SOC_PAD_26_SMT_26_BIT 1
#define OCCAMY_SOC_PAD_26_DRV_26_MASK 0x3
#define OCCAMY_SOC_PAD_26_DRV_26_OFFSET 2
#define OCCAMY_SOC_PAD_26_DRV_26_FIELD                           \
    ((bitfield_field32_t){.mask = OCCAMY_SOC_PAD_26_DRV_26_MASK, \
                          .index = OCCAMY_SOC_PAD_26_DRV_26_OFFSET})

// GPIO pad configuration.
#define OCCAMY_SOC_PAD_27_REG_OFFSET 0x94
#define OCCAMY_SOC_PAD_27_SLW_27_BIT 0
#define OCCAMY_SOC_PAD_27_SMT_27_BIT 1
#define OCCAMY_SOC_PAD_27_DRV_27_MASK 0x3
#define OCCAMY_SOC_PAD_27_DRV_27_OFFSET 2
#define OCCAMY_SOC_PAD_27_DRV_27_FIELD                           \
    ((bitfield_field32_t){.mask = OCCAMY_SOC_PAD_27_DRV_27_MASK, \
                          .index = OCCAMY_SOC_PAD_27_DRV_27_OFFSET})

// GPIO pad configuration.
#define OCCAMY_SOC_PAD_28_REG_OFFSET 0x98
#define OCCAMY_SOC_PAD_28_SLW_28_BIT 0
#define OCCAMY_SOC_PAD_28_SMT_28_BIT 1
#define OCCAMY_SOC_PAD_28_DRV_28_MASK 0x3
#define OCCAMY_SOC_PAD_28_DRV_28_OFFSET 2
#define OCCAMY_SOC_PAD_28_DRV_28_FIELD                           \
    ((bitfield_field32_t){.mask = OCCAMY_SOC_PAD_28_DRV_28_MASK, \
                          .index = OCCAMY_SOC_PAD_28_DRV_28_OFFSET})

// GPIO pad configuration.
#define OCCAMY_SOC_PAD_29_REG_OFFSET 0x9c
#define OCCAMY_SOC_PAD_29_SLW_29_BIT 0
#define OCCAMY_SOC_PAD_29_SMT_29_BIT 1
#define OCCAMY_SOC_PAD_29_DRV_29_MASK 0x3
#define OCCAMY_SOC_PAD_29_DRV_29_OFFSET 2
#define OCCAMY_SOC_PAD_29_DRV_29_FIELD                           \
    ((bitfield_field32_t){.mask = OCCAMY_SOC_PAD_29_DRV_29_MASK, \
                          .index = OCCAMY_SOC_PAD_29_DRV_29_OFFSET})

// GPIO pad configuration.
#define OCCAMY_SOC_PAD_30_REG_OFFSET 0xa0
#define OCCAMY_SOC_PAD_30_SLW_30_BIT 0
#define OCCAMY_SOC_PAD_30_SMT_30_BIT 1
#define OCCAMY_SOC_PAD_30_DRV_30_MASK 0x3
#define OCCAMY_SOC_PAD_30_DRV_30_OFFSET 2
#define OCCAMY_SOC_PAD_30_DRV_30_FIELD                           \
    ((bitfield_field32_t){.mask = OCCAMY_SOC_PAD_30_DRV_30_MASK, \
                          .index = OCCAMY_SOC_PAD_30_DRV_30_OFFSET})

// Isolate port of given quadrant. (common parameters)
#define OCCAMY_SOC_ISOLATE_ISOLATE_FIELD_WIDTH 4
#define OCCAMY_SOC_ISOLATE_ISOLATE_FIELDS_PER_REG 8
#define OCCAMY_SOC_ISOLATE_MULTIREG_COUNT 1

// Isolate port of given quadrant.
#define OCCAMY_SOC_ISOLATE_REG_OFFSET 0xa4
#define OCCAMY_SOC_ISOLATE_ISOLATE_0_MASK 0xf
#define OCCAMY_SOC_ISOLATE_ISOLATE_0_OFFSET 0
#define OCCAMY_SOC_ISOLATE_ISOLATE_0_FIELD                           \
    ((bitfield_field32_t){.mask = OCCAMY_SOC_ISOLATE_ISOLATE_0_MASK, \
                          .index = OCCAMY_SOC_ISOLATE_ISOLATE_0_OFFSET})
#define OCCAMY_SOC_ISOLATE_ISOLATE_1_MASK 0xf
#define OCCAMY_SOC_ISOLATE_ISOLATE_1_OFFSET 4
#define OCCAMY_SOC_ISOLATE_ISOLATE_1_FIELD                           \
    ((bitfield_field32_t){.mask = OCCAMY_SOC_ISOLATE_ISOLATE_1_MASK, \
                          .index = OCCAMY_SOC_ISOLATE_ISOLATE_1_OFFSET})
#define OCCAMY_SOC_ISOLATE_ISOLATE_2_MASK 0xf
#define OCCAMY_SOC_ISOLATE_ISOLATE_2_OFFSET 8
#define OCCAMY_SOC_ISOLATE_ISOLATE_2_FIELD                           \
    ((bitfield_field32_t){.mask = OCCAMY_SOC_ISOLATE_ISOLATE_2_MASK, \
                          .index = OCCAMY_SOC_ISOLATE_ISOLATE_2_OFFSET})
#define OCCAMY_SOC_ISOLATE_ISOLATE_3_MASK 0xf
#define OCCAMY_SOC_ISOLATE_ISOLATE_3_OFFSET 12
#define OCCAMY_SOC_ISOLATE_ISOLATE_3_FIELD                           \
    ((bitfield_field32_t){.mask = OCCAMY_SOC_ISOLATE_ISOLATE_3_MASK, \
                          .index = OCCAMY_SOC_ISOLATE_ISOLATE_3_OFFSET})
#define OCCAMY_SOC_ISOLATE_ISOLATE_4_MASK 0xf
#define OCCAMY_SOC_ISOLATE_ISOLATE_4_OFFSET 16
#define OCCAMY_SOC_ISOLATE_ISOLATE_4_FIELD                           \
    ((bitfield_field32_t){.mask = OCCAMY_SOC_ISOLATE_ISOLATE_4_MASK, \
                          .index = OCCAMY_SOC_ISOLATE_ISOLATE_4_OFFSET})
#define OCCAMY_SOC_ISOLATE_ISOLATE_5_MASK 0xf
#define OCCAMY_SOC_ISOLATE_ISOLATE_5_OFFSET 20
#define OCCAMY_SOC_ISOLATE_ISOLATE_5_FIELD                           \
    ((bitfield_field32_t){.mask = OCCAMY_SOC_ISOLATE_ISOLATE_5_MASK, \
                          .index = OCCAMY_SOC_ISOLATE_ISOLATE_5_OFFSET})
#define OCCAMY_SOC_ISOLATE_ISOLATE_6_MASK 0xf
#define OCCAMY_SOC_ISOLATE_ISOLATE_6_OFFSET 24
#define OCCAMY_SOC_ISOLATE_ISOLATE_6_FIELD                           \
    ((bitfield_field32_t){.mask = OCCAMY_SOC_ISOLATE_ISOLATE_6_MASK, \
                          .index = OCCAMY_SOC_ISOLATE_ISOLATE_6_OFFSET})
#define OCCAMY_SOC_ISOLATE_ISOLATE_7_MASK 0xf
#define OCCAMY_SOC_ISOLATE_ISOLATE_7_OFFSET 28
#define OCCAMY_SOC_ISOLATE_ISOLATE_7_FIELD                           \
    ((bitfield_field32_t){.mask = OCCAMY_SOC_ISOLATE_ISOLATE_7_MASK, \
                          .index = OCCAMY_SOC_ISOLATE_ISOLATE_7_OFFSET})

// Isolation status of S1 quadrant and port (common parameters)
#define OCCAMY_SOC_ISOLATED_ISOLATED_FIELD_WIDTH 4
#define OCCAMY_SOC_ISOLATED_ISOLATED_FIELDS_PER_REG 8
#define OCCAMY_SOC_ISOLATED_MULTIREG_COUNT 1

// Isolation status of S1 quadrant and port
#define OCCAMY_SOC_ISOLATED_REG_OFFSET 0xa8
#define OCCAMY_SOC_ISOLATED_ISOLATED_0_MASK 0xf
#define OCCAMY_SOC_ISOLATED_ISOLATED_0_OFFSET 0
#define OCCAMY_SOC_ISOLATED_ISOLATED_0_FIELD                           \
    ((bitfield_field32_t){.mask = OCCAMY_SOC_ISOLATED_ISOLATED_0_MASK, \
                          .index = OCCAMY_SOC_ISOLATED_ISOLATED_0_OFFSET})
#define OCCAMY_SOC_ISOLATED_ISOLATED_1_MASK 0xf
#define OCCAMY_SOC_ISOLATED_ISOLATED_1_OFFSET 4
#define OCCAMY_SOC_ISOLATED_ISOLATED_1_FIELD                           \
    ((bitfield_field32_t){.mask = OCCAMY_SOC_ISOLATED_ISOLATED_1_MASK, \
                          .index = OCCAMY_SOC_ISOLATED_ISOLATED_1_OFFSET})
#define OCCAMY_SOC_ISOLATED_ISOLATED_2_MASK 0xf
#define OCCAMY_SOC_ISOLATED_ISOLATED_2_OFFSET 8
#define OCCAMY_SOC_ISOLATED_ISOLATED_2_FIELD                           \
    ((bitfield_field32_t){.mask = OCCAMY_SOC_ISOLATED_ISOLATED_2_MASK, \
                          .index = OCCAMY_SOC_ISOLATED_ISOLATED_2_OFFSET})
#define OCCAMY_SOC_ISOLATED_ISOLATED_3_MASK 0xf
#define OCCAMY_SOC_ISOLATED_ISOLATED_3_OFFSET 12
#define OCCAMY_SOC_ISOLATED_ISOLATED_3_FIELD                           \
    ((bitfield_field32_t){.mask = OCCAMY_SOC_ISOLATED_ISOLATED_3_MASK, \
                          .index = OCCAMY_SOC_ISOLATED_ISOLATED_3_OFFSET})
#define OCCAMY_SOC_ISOLATED_ISOLATED_4_MASK 0xf
#define OCCAMY_SOC_ISOLATED_ISOLATED_4_OFFSET 16
#define OCCAMY_SOC_ISOLATED_ISOLATED_4_FIELD                           \
    ((bitfield_field32_t){.mask = OCCAMY_SOC_ISOLATED_ISOLATED_4_MASK, \
                          .index = OCCAMY_SOC_ISOLATED_ISOLATED_4_OFFSET})
#define OCCAMY_SOC_ISOLATED_ISOLATED_5_MASK 0xf
#define OCCAMY_SOC_ISOLATED_ISOLATED_5_OFFSET 20
#define OCCAMY_SOC_ISOLATED_ISOLATED_5_FIELD                           \
    ((bitfield_field32_t){.mask = OCCAMY_SOC_ISOLATED_ISOLATED_5_MASK, \
                          .index = OCCAMY_SOC_ISOLATED_ISOLATED_5_OFFSET})
#define OCCAMY_SOC_ISOLATED_ISOLATED_6_MASK 0xf
#define OCCAMY_SOC_ISOLATED_ISOLATED_6_OFFSET 24
#define OCCAMY_SOC_ISOLATED_ISOLATED_6_FIELD                           \
    ((bitfield_field32_t){.mask = OCCAMY_SOC_ISOLATED_ISOLATED_6_MASK, \
                          .index = OCCAMY_SOC_ISOLATED_ISOLATED_6_OFFSET})
#define OCCAMY_SOC_ISOLATED_ISOLATED_7_MASK 0xf
#define OCCAMY_SOC_ISOLATED_ISOLATED_7_OFFSET 28
#define OCCAMY_SOC_ISOLATED_ISOLATED_7_FIELD                           \
    ((bitfield_field32_t){.mask = OCCAMY_SOC_ISOLATED_ISOLATED_7_MASK, \
                          .index = OCCAMY_SOC_ISOLATED_ISOLATED_7_OFFSET})

// Enable read-only cache of quadrant. (common parameters)
#define OCCAMY_SOC_RO_CACHE_ENABLE_ENABLE_FIELD_WIDTH 1
#define OCCAMY_SOC_RO_CACHE_ENABLE_ENABLE_FIELDS_PER_REG 32
#define OCCAMY_SOC_RO_CACHE_ENABLE_MULTIREG_COUNT 1

// Enable read-only cache of quadrant.
#define OCCAMY_SOC_RO_CACHE_ENABLE_REG_OFFSET 0xac
#define OCCAMY_SOC_RO_CACHE_ENABLE_ENABLE_0_BIT 0
#define OCCAMY_SOC_RO_CACHE_ENABLE_ENABLE_1_BIT 1
#define OCCAMY_SOC_RO_CACHE_ENABLE_ENABLE_2_BIT 2
#define OCCAMY_SOC_RO_CACHE_ENABLE_ENABLE_3_BIT 3
#define OCCAMY_SOC_RO_CACHE_ENABLE_ENABLE_4_BIT 4
#define OCCAMY_SOC_RO_CACHE_ENABLE_ENABLE_5_BIT 5
#define OCCAMY_SOC_RO_CACHE_ENABLE_ENABLE_6_BIT 6
#define OCCAMY_SOC_RO_CACHE_ENABLE_ENABLE_7_BIT 7

// Flush read-only cache. (common parameters)
#define OCCAMY_SOC_RO_CACHE_FLUSH_FLUSH_FIELD_WIDTH 1
#define OCCAMY_SOC_RO_CACHE_FLUSH_FLUSH_FIELDS_PER_REG 32
#define OCCAMY_SOC_RO_CACHE_FLUSH_MULTIREG_COUNT 1

// Flush read-only cache.
#define OCCAMY_SOC_RO_CACHE_FLUSH_REG_OFFSET 0xb0
#define OCCAMY_SOC_RO_CACHE_FLUSH_FLUSH_0_BIT 0
#define OCCAMY_SOC_RO_CACHE_FLUSH_FLUSH_1_BIT 1
#define OCCAMY_SOC_RO_CACHE_FLUSH_FLUSH_2_BIT 2
#define OCCAMY_SOC_RO_CACHE_FLUSH_FLUSH_3_BIT 3
#define OCCAMY_SOC_RO_CACHE_FLUSH_FLUSH_4_BIT 4
#define OCCAMY_SOC_RO_CACHE_FLUSH_FLUSH_5_BIT 5
#define OCCAMY_SOC_RO_CACHE_FLUSH_FLUSH_6_BIT 6
#define OCCAMY_SOC_RO_CACHE_FLUSH_FLUSH_7_BIT 7

// Read-only cache start address low
#define OCCAMY_SOC_RO_START_ADDR_LOW_0_QUADRANT_0_REG_OFFSET 0x100

// Read-only cache start address high
#define OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_0_REG_OFFSET 0x104
#define OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_0_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_0_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_0_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                                 \
        .mask = OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_0_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_0_ADDR_HIGH_OFFSET})

// Read-only cache end address low
#define OCCAMY_SOC_RO_END_ADDR_LOW_0_QUADRANT_0_REG_OFFSET 0x108

// Read-only cache end address high
#define OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_0_REG_OFFSET 0x10c
#define OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_0_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_0_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_0_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                               \
        .mask = OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_0_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_0_ADDR_HIGH_OFFSET})

// Read-only cache start address low
#define OCCAMY_SOC_RO_START_ADDR_LOW_1_QUADRANT_0_REG_OFFSET 0x110

// Read-only cache start address high
#define OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_0_REG_OFFSET 0x114
#define OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_0_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_0_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_0_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                                 \
        .mask = OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_0_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_0_ADDR_HIGH_OFFSET})

// Read-only cache end address low
#define OCCAMY_SOC_RO_END_ADDR_LOW_1_QUADRANT_0_REG_OFFSET 0x118

// Read-only cache end address high
#define OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_0_REG_OFFSET 0x11c
#define OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_0_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_0_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_0_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                               \
        .mask = OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_0_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_0_ADDR_HIGH_OFFSET})

// Read-only cache start address low
#define OCCAMY_SOC_RO_START_ADDR_LOW_2_QUADRANT_0_REG_OFFSET 0x120

// Read-only cache start address high
#define OCCAMY_SOC_RO_START_ADDR_HIGH_2_QUADRANT_0_REG_OFFSET 0x124
#define OCCAMY_SOC_RO_START_ADDR_HIGH_2_QUADRANT_0_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_START_ADDR_HIGH_2_QUADRANT_0_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_START_ADDR_HIGH_2_QUADRANT_0_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                                 \
        .mask = OCCAMY_SOC_RO_START_ADDR_HIGH_2_QUADRANT_0_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_START_ADDR_HIGH_2_QUADRANT_0_ADDR_HIGH_OFFSET})

// Read-only cache end address low
#define OCCAMY_SOC_RO_END_ADDR_LOW_2_QUADRANT_0_REG_OFFSET 0x128

// Read-only cache end address high
#define OCCAMY_SOC_RO_END_ADDR_HIGH_2_QUADRANT_0_REG_OFFSET 0x12c
#define OCCAMY_SOC_RO_END_ADDR_HIGH_2_QUADRANT_0_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_END_ADDR_HIGH_2_QUADRANT_0_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_END_ADDR_HIGH_2_QUADRANT_0_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                               \
        .mask = OCCAMY_SOC_RO_END_ADDR_HIGH_2_QUADRANT_0_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_END_ADDR_HIGH_2_QUADRANT_0_ADDR_HIGH_OFFSET})

// Read-only cache start address low
#define OCCAMY_SOC_RO_START_ADDR_LOW_3_QUADRANT_0_REG_OFFSET 0x130

// Read-only cache start address high
#define OCCAMY_SOC_RO_START_ADDR_HIGH_3_QUADRANT_0_REG_OFFSET 0x134
#define OCCAMY_SOC_RO_START_ADDR_HIGH_3_QUADRANT_0_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_START_ADDR_HIGH_3_QUADRANT_0_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_START_ADDR_HIGH_3_QUADRANT_0_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                                 \
        .mask = OCCAMY_SOC_RO_START_ADDR_HIGH_3_QUADRANT_0_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_START_ADDR_HIGH_3_QUADRANT_0_ADDR_HIGH_OFFSET})

// Read-only cache end address low
#define OCCAMY_SOC_RO_END_ADDR_LOW_3_QUADRANT_0_REG_OFFSET 0x138

// Read-only cache end address high
#define OCCAMY_SOC_RO_END_ADDR_HIGH_3_QUADRANT_0_REG_OFFSET 0x13c
#define OCCAMY_SOC_RO_END_ADDR_HIGH_3_QUADRANT_0_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_END_ADDR_HIGH_3_QUADRANT_0_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_END_ADDR_HIGH_3_QUADRANT_0_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                               \
        .mask = OCCAMY_SOC_RO_END_ADDR_HIGH_3_QUADRANT_0_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_END_ADDR_HIGH_3_QUADRANT_0_ADDR_HIGH_OFFSET})

// Read-only cache start address low
#define OCCAMY_SOC_RO_START_ADDR_LOW_0_QUADRANT_1_REG_OFFSET 0x140

// Read-only cache start address high
#define OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_1_REG_OFFSET 0x144
#define OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_1_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_1_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_1_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                                 \
        .mask = OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_1_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_1_ADDR_HIGH_OFFSET})

// Read-only cache end address low
#define OCCAMY_SOC_RO_END_ADDR_LOW_0_QUADRANT_1_REG_OFFSET 0x148

// Read-only cache end address high
#define OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_1_REG_OFFSET 0x14c
#define OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_1_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_1_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_1_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                               \
        .mask = OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_1_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_1_ADDR_HIGH_OFFSET})

// Read-only cache start address low
#define OCCAMY_SOC_RO_START_ADDR_LOW_1_QUADRANT_1_REG_OFFSET 0x150

// Read-only cache start address high
#define OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_1_REG_OFFSET 0x154
#define OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_1_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_1_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_1_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                                 \
        .mask = OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_1_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_1_ADDR_HIGH_OFFSET})

// Read-only cache end address low
#define OCCAMY_SOC_RO_END_ADDR_LOW_1_QUADRANT_1_REG_OFFSET 0x158

// Read-only cache end address high
#define OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_1_REG_OFFSET 0x15c
#define OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_1_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_1_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_1_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                               \
        .mask = OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_1_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_1_ADDR_HIGH_OFFSET})

// Read-only cache start address low
#define OCCAMY_SOC_RO_START_ADDR_LOW_2_QUADRANT_1_REG_OFFSET 0x160

// Read-only cache start address high
#define OCCAMY_SOC_RO_START_ADDR_HIGH_2_QUADRANT_1_REG_OFFSET 0x164
#define OCCAMY_SOC_RO_START_ADDR_HIGH_2_QUADRANT_1_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_START_ADDR_HIGH_2_QUADRANT_1_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_START_ADDR_HIGH_2_QUADRANT_1_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                                 \
        .mask = OCCAMY_SOC_RO_START_ADDR_HIGH_2_QUADRANT_1_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_START_ADDR_HIGH_2_QUADRANT_1_ADDR_HIGH_OFFSET})

// Read-only cache end address low
#define OCCAMY_SOC_RO_END_ADDR_LOW_2_QUADRANT_1_REG_OFFSET 0x168

// Read-only cache end address high
#define OCCAMY_SOC_RO_END_ADDR_HIGH_2_QUADRANT_1_REG_OFFSET 0x16c
#define OCCAMY_SOC_RO_END_ADDR_HIGH_2_QUADRANT_1_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_END_ADDR_HIGH_2_QUADRANT_1_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_END_ADDR_HIGH_2_QUADRANT_1_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                               \
        .mask = OCCAMY_SOC_RO_END_ADDR_HIGH_2_QUADRANT_1_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_END_ADDR_HIGH_2_QUADRANT_1_ADDR_HIGH_OFFSET})

// Read-only cache start address low
#define OCCAMY_SOC_RO_START_ADDR_LOW_3_QUADRANT_1_REG_OFFSET 0x170

// Read-only cache start address high
#define OCCAMY_SOC_RO_START_ADDR_HIGH_3_QUADRANT_1_REG_OFFSET 0x174
#define OCCAMY_SOC_RO_START_ADDR_HIGH_3_QUADRANT_1_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_START_ADDR_HIGH_3_QUADRANT_1_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_START_ADDR_HIGH_3_QUADRANT_1_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                                 \
        .mask = OCCAMY_SOC_RO_START_ADDR_HIGH_3_QUADRANT_1_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_START_ADDR_HIGH_3_QUADRANT_1_ADDR_HIGH_OFFSET})

// Read-only cache end address low
#define OCCAMY_SOC_RO_END_ADDR_LOW_3_QUADRANT_1_REG_OFFSET 0x178

// Read-only cache end address high
#define OCCAMY_SOC_RO_END_ADDR_HIGH_3_QUADRANT_1_REG_OFFSET 0x17c
#define OCCAMY_SOC_RO_END_ADDR_HIGH_3_QUADRANT_1_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_END_ADDR_HIGH_3_QUADRANT_1_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_END_ADDR_HIGH_3_QUADRANT_1_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                               \
        .mask = OCCAMY_SOC_RO_END_ADDR_HIGH_3_QUADRANT_1_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_END_ADDR_HIGH_3_QUADRANT_1_ADDR_HIGH_OFFSET})

// Read-only cache start address low
#define OCCAMY_SOC_RO_START_ADDR_LOW_0_QUADRANT_2_REG_OFFSET 0x180

// Read-only cache start address high
#define OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_2_REG_OFFSET 0x184
#define OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_2_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_2_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_2_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                                 \
        .mask = OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_2_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_2_ADDR_HIGH_OFFSET})

// Read-only cache end address low
#define OCCAMY_SOC_RO_END_ADDR_LOW_0_QUADRANT_2_REG_OFFSET 0x188

// Read-only cache end address high
#define OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_2_REG_OFFSET 0x18c
#define OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_2_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_2_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_2_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                               \
        .mask = OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_2_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_2_ADDR_HIGH_OFFSET})

// Read-only cache start address low
#define OCCAMY_SOC_RO_START_ADDR_LOW_1_QUADRANT_2_REG_OFFSET 0x190

// Read-only cache start address high
#define OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_2_REG_OFFSET 0x194
#define OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_2_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_2_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_2_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                                 \
        .mask = OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_2_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_2_ADDR_HIGH_OFFSET})

// Read-only cache end address low
#define OCCAMY_SOC_RO_END_ADDR_LOW_1_QUADRANT_2_REG_OFFSET 0x198

// Read-only cache end address high
#define OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_2_REG_OFFSET 0x19c
#define OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_2_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_2_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_2_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                               \
        .mask = OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_2_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_2_ADDR_HIGH_OFFSET})

// Read-only cache start address low
#define OCCAMY_SOC_RO_START_ADDR_LOW_2_QUADRANT_2_REG_OFFSET 0x1a0

// Read-only cache start address high
#define OCCAMY_SOC_RO_START_ADDR_HIGH_2_QUADRANT_2_REG_OFFSET 0x1a4
#define OCCAMY_SOC_RO_START_ADDR_HIGH_2_QUADRANT_2_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_START_ADDR_HIGH_2_QUADRANT_2_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_START_ADDR_HIGH_2_QUADRANT_2_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                                 \
        .mask = OCCAMY_SOC_RO_START_ADDR_HIGH_2_QUADRANT_2_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_START_ADDR_HIGH_2_QUADRANT_2_ADDR_HIGH_OFFSET})

// Read-only cache end address low
#define OCCAMY_SOC_RO_END_ADDR_LOW_2_QUADRANT_2_REG_OFFSET 0x1a8

// Read-only cache end address high
#define OCCAMY_SOC_RO_END_ADDR_HIGH_2_QUADRANT_2_REG_OFFSET 0x1ac
#define OCCAMY_SOC_RO_END_ADDR_HIGH_2_QUADRANT_2_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_END_ADDR_HIGH_2_QUADRANT_2_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_END_ADDR_HIGH_2_QUADRANT_2_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                               \
        .mask = OCCAMY_SOC_RO_END_ADDR_HIGH_2_QUADRANT_2_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_END_ADDR_HIGH_2_QUADRANT_2_ADDR_HIGH_OFFSET})

// Read-only cache start address low
#define OCCAMY_SOC_RO_START_ADDR_LOW_3_QUADRANT_2_REG_OFFSET 0x1b0

// Read-only cache start address high
#define OCCAMY_SOC_RO_START_ADDR_HIGH_3_QUADRANT_2_REG_OFFSET 0x1b4
#define OCCAMY_SOC_RO_START_ADDR_HIGH_3_QUADRANT_2_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_START_ADDR_HIGH_3_QUADRANT_2_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_START_ADDR_HIGH_3_QUADRANT_2_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                                 \
        .mask = OCCAMY_SOC_RO_START_ADDR_HIGH_3_QUADRANT_2_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_START_ADDR_HIGH_3_QUADRANT_2_ADDR_HIGH_OFFSET})

// Read-only cache end address low
#define OCCAMY_SOC_RO_END_ADDR_LOW_3_QUADRANT_2_REG_OFFSET 0x1b8

// Read-only cache end address high
#define OCCAMY_SOC_RO_END_ADDR_HIGH_3_QUADRANT_2_REG_OFFSET 0x1bc
#define OCCAMY_SOC_RO_END_ADDR_HIGH_3_QUADRANT_2_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_END_ADDR_HIGH_3_QUADRANT_2_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_END_ADDR_HIGH_3_QUADRANT_2_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                               \
        .mask = OCCAMY_SOC_RO_END_ADDR_HIGH_3_QUADRANT_2_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_END_ADDR_HIGH_3_QUADRANT_2_ADDR_HIGH_OFFSET})

// Read-only cache start address low
#define OCCAMY_SOC_RO_START_ADDR_LOW_0_QUADRANT_3_REG_OFFSET 0x1c0

// Read-only cache start address high
#define OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_3_REG_OFFSET 0x1c4
#define OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_3_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_3_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_3_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                                 \
        .mask = OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_3_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_3_ADDR_HIGH_OFFSET})

// Read-only cache end address low
#define OCCAMY_SOC_RO_END_ADDR_LOW_0_QUADRANT_3_REG_OFFSET 0x1c8

// Read-only cache end address high
#define OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_3_REG_OFFSET 0x1cc
#define OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_3_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_3_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_3_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                               \
        .mask = OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_3_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_3_ADDR_HIGH_OFFSET})

// Read-only cache start address low
#define OCCAMY_SOC_RO_START_ADDR_LOW_1_QUADRANT_3_REG_OFFSET 0x1d0

// Read-only cache start address high
#define OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_3_REG_OFFSET 0x1d4
#define OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_3_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_3_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_3_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                                 \
        .mask = OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_3_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_3_ADDR_HIGH_OFFSET})

// Read-only cache end address low
#define OCCAMY_SOC_RO_END_ADDR_LOW_1_QUADRANT_3_REG_OFFSET 0x1d8

// Read-only cache end address high
#define OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_3_REG_OFFSET 0x1dc
#define OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_3_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_3_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_3_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                               \
        .mask = OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_3_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_3_ADDR_HIGH_OFFSET})

// Read-only cache start address low
#define OCCAMY_SOC_RO_START_ADDR_LOW_2_QUADRANT_3_REG_OFFSET 0x1e0

// Read-only cache start address high
#define OCCAMY_SOC_RO_START_ADDR_HIGH_2_QUADRANT_3_REG_OFFSET 0x1e4
#define OCCAMY_SOC_RO_START_ADDR_HIGH_2_QUADRANT_3_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_START_ADDR_HIGH_2_QUADRANT_3_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_START_ADDR_HIGH_2_QUADRANT_3_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                                 \
        .mask = OCCAMY_SOC_RO_START_ADDR_HIGH_2_QUADRANT_3_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_START_ADDR_HIGH_2_QUADRANT_3_ADDR_HIGH_OFFSET})

// Read-only cache end address low
#define OCCAMY_SOC_RO_END_ADDR_LOW_2_QUADRANT_3_REG_OFFSET 0x1e8

// Read-only cache end address high
#define OCCAMY_SOC_RO_END_ADDR_HIGH_2_QUADRANT_3_REG_OFFSET 0x1ec
#define OCCAMY_SOC_RO_END_ADDR_HIGH_2_QUADRANT_3_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_END_ADDR_HIGH_2_QUADRANT_3_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_END_ADDR_HIGH_2_QUADRANT_3_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                               \
        .mask = OCCAMY_SOC_RO_END_ADDR_HIGH_2_QUADRANT_3_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_END_ADDR_HIGH_2_QUADRANT_3_ADDR_HIGH_OFFSET})

// Read-only cache start address low
#define OCCAMY_SOC_RO_START_ADDR_LOW_3_QUADRANT_3_REG_OFFSET 0x1f0

// Read-only cache start address high
#define OCCAMY_SOC_RO_START_ADDR_HIGH_3_QUADRANT_3_REG_OFFSET 0x1f4
#define OCCAMY_SOC_RO_START_ADDR_HIGH_3_QUADRANT_3_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_START_ADDR_HIGH_3_QUADRANT_3_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_START_ADDR_HIGH_3_QUADRANT_3_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                                 \
        .mask = OCCAMY_SOC_RO_START_ADDR_HIGH_3_QUADRANT_3_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_START_ADDR_HIGH_3_QUADRANT_3_ADDR_HIGH_OFFSET})

// Read-only cache end address low
#define OCCAMY_SOC_RO_END_ADDR_LOW_3_QUADRANT_3_REG_OFFSET 0x1f8

// Read-only cache end address high
#define OCCAMY_SOC_RO_END_ADDR_HIGH_3_QUADRANT_3_REG_OFFSET 0x1fc
#define OCCAMY_SOC_RO_END_ADDR_HIGH_3_QUADRANT_3_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_END_ADDR_HIGH_3_QUADRANT_3_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_END_ADDR_HIGH_3_QUADRANT_3_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                               \
        .mask = OCCAMY_SOC_RO_END_ADDR_HIGH_3_QUADRANT_3_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_END_ADDR_HIGH_3_QUADRANT_3_ADDR_HIGH_OFFSET})

// Read-only cache start address low
#define OCCAMY_SOC_RO_START_ADDR_LOW_0_QUADRANT_4_REG_OFFSET 0x200

// Read-only cache start address high
#define OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_4_REG_OFFSET 0x204
#define OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_4_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_4_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_4_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                                 \
        .mask = OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_4_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_4_ADDR_HIGH_OFFSET})

// Read-only cache end address low
#define OCCAMY_SOC_RO_END_ADDR_LOW_0_QUADRANT_4_REG_OFFSET 0x208

// Read-only cache end address high
#define OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_4_REG_OFFSET 0x20c
#define OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_4_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_4_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_4_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                               \
        .mask = OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_4_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_4_ADDR_HIGH_OFFSET})

// Read-only cache start address low
#define OCCAMY_SOC_RO_START_ADDR_LOW_1_QUADRANT_4_REG_OFFSET 0x210

// Read-only cache start address high
#define OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_4_REG_OFFSET 0x214
#define OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_4_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_4_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_4_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                                 \
        .mask = OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_4_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_4_ADDR_HIGH_OFFSET})

// Read-only cache end address low
#define OCCAMY_SOC_RO_END_ADDR_LOW_1_QUADRANT_4_REG_OFFSET 0x218

// Read-only cache end address high
#define OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_4_REG_OFFSET 0x21c
#define OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_4_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_4_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_4_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                               \
        .mask = OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_4_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_4_ADDR_HIGH_OFFSET})

// Read-only cache start address low
#define OCCAMY_SOC_RO_START_ADDR_LOW_2_QUADRANT_4_REG_OFFSET 0x220

// Read-only cache start address high
#define OCCAMY_SOC_RO_START_ADDR_HIGH_2_QUADRANT_4_REG_OFFSET 0x224
#define OCCAMY_SOC_RO_START_ADDR_HIGH_2_QUADRANT_4_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_START_ADDR_HIGH_2_QUADRANT_4_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_START_ADDR_HIGH_2_QUADRANT_4_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                                 \
        .mask = OCCAMY_SOC_RO_START_ADDR_HIGH_2_QUADRANT_4_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_START_ADDR_HIGH_2_QUADRANT_4_ADDR_HIGH_OFFSET})

// Read-only cache end address low
#define OCCAMY_SOC_RO_END_ADDR_LOW_2_QUADRANT_4_REG_OFFSET 0x228

// Read-only cache end address high
#define OCCAMY_SOC_RO_END_ADDR_HIGH_2_QUADRANT_4_REG_OFFSET 0x22c
#define OCCAMY_SOC_RO_END_ADDR_HIGH_2_QUADRANT_4_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_END_ADDR_HIGH_2_QUADRANT_4_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_END_ADDR_HIGH_2_QUADRANT_4_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                               \
        .mask = OCCAMY_SOC_RO_END_ADDR_HIGH_2_QUADRANT_4_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_END_ADDR_HIGH_2_QUADRANT_4_ADDR_HIGH_OFFSET})

// Read-only cache start address low
#define OCCAMY_SOC_RO_START_ADDR_LOW_3_QUADRANT_4_REG_OFFSET 0x230

// Read-only cache start address high
#define OCCAMY_SOC_RO_START_ADDR_HIGH_3_QUADRANT_4_REG_OFFSET 0x234
#define OCCAMY_SOC_RO_START_ADDR_HIGH_3_QUADRANT_4_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_START_ADDR_HIGH_3_QUADRANT_4_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_START_ADDR_HIGH_3_QUADRANT_4_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                                 \
        .mask = OCCAMY_SOC_RO_START_ADDR_HIGH_3_QUADRANT_4_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_START_ADDR_HIGH_3_QUADRANT_4_ADDR_HIGH_OFFSET})

// Read-only cache end address low
#define OCCAMY_SOC_RO_END_ADDR_LOW_3_QUADRANT_4_REG_OFFSET 0x238

// Read-only cache end address high
#define OCCAMY_SOC_RO_END_ADDR_HIGH_3_QUADRANT_4_REG_OFFSET 0x23c
#define OCCAMY_SOC_RO_END_ADDR_HIGH_3_QUADRANT_4_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_END_ADDR_HIGH_3_QUADRANT_4_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_END_ADDR_HIGH_3_QUADRANT_4_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                               \
        .mask = OCCAMY_SOC_RO_END_ADDR_HIGH_3_QUADRANT_4_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_END_ADDR_HIGH_3_QUADRANT_4_ADDR_HIGH_OFFSET})

// Read-only cache start address low
#define OCCAMY_SOC_RO_START_ADDR_LOW_0_QUADRANT_5_REG_OFFSET 0x240

// Read-only cache start address high
#define OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_5_REG_OFFSET 0x244
#define OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_5_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_5_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_5_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                                 \
        .mask = OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_5_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_5_ADDR_HIGH_OFFSET})

// Read-only cache end address low
#define OCCAMY_SOC_RO_END_ADDR_LOW_0_QUADRANT_5_REG_OFFSET 0x248

// Read-only cache end address high
#define OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_5_REG_OFFSET 0x24c
#define OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_5_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_5_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_5_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                               \
        .mask = OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_5_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_5_ADDR_HIGH_OFFSET})

// Read-only cache start address low
#define OCCAMY_SOC_RO_START_ADDR_LOW_1_QUADRANT_5_REG_OFFSET 0x250

// Read-only cache start address high
#define OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_5_REG_OFFSET 0x254
#define OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_5_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_5_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_5_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                                 \
        .mask = OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_5_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_5_ADDR_HIGH_OFFSET})

// Read-only cache end address low
#define OCCAMY_SOC_RO_END_ADDR_LOW_1_QUADRANT_5_REG_OFFSET 0x258

// Read-only cache end address high
#define OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_5_REG_OFFSET 0x25c
#define OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_5_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_5_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_5_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                               \
        .mask = OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_5_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_5_ADDR_HIGH_OFFSET})

// Read-only cache start address low
#define OCCAMY_SOC_RO_START_ADDR_LOW_2_QUADRANT_5_REG_OFFSET 0x260

// Read-only cache start address high
#define OCCAMY_SOC_RO_START_ADDR_HIGH_2_QUADRANT_5_REG_OFFSET 0x264
#define OCCAMY_SOC_RO_START_ADDR_HIGH_2_QUADRANT_5_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_START_ADDR_HIGH_2_QUADRANT_5_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_START_ADDR_HIGH_2_QUADRANT_5_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                                 \
        .mask = OCCAMY_SOC_RO_START_ADDR_HIGH_2_QUADRANT_5_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_START_ADDR_HIGH_2_QUADRANT_5_ADDR_HIGH_OFFSET})

// Read-only cache end address low
#define OCCAMY_SOC_RO_END_ADDR_LOW_2_QUADRANT_5_REG_OFFSET 0x268

// Read-only cache end address high
#define OCCAMY_SOC_RO_END_ADDR_HIGH_2_QUADRANT_5_REG_OFFSET 0x26c
#define OCCAMY_SOC_RO_END_ADDR_HIGH_2_QUADRANT_5_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_END_ADDR_HIGH_2_QUADRANT_5_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_END_ADDR_HIGH_2_QUADRANT_5_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                               \
        .mask = OCCAMY_SOC_RO_END_ADDR_HIGH_2_QUADRANT_5_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_END_ADDR_HIGH_2_QUADRANT_5_ADDR_HIGH_OFFSET})

// Read-only cache start address low
#define OCCAMY_SOC_RO_START_ADDR_LOW_3_QUADRANT_5_REG_OFFSET 0x270

// Read-only cache start address high
#define OCCAMY_SOC_RO_START_ADDR_HIGH_3_QUADRANT_5_REG_OFFSET 0x274
#define OCCAMY_SOC_RO_START_ADDR_HIGH_3_QUADRANT_5_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_START_ADDR_HIGH_3_QUADRANT_5_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_START_ADDR_HIGH_3_QUADRANT_5_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                                 \
        .mask = OCCAMY_SOC_RO_START_ADDR_HIGH_3_QUADRANT_5_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_START_ADDR_HIGH_3_QUADRANT_5_ADDR_HIGH_OFFSET})

// Read-only cache end address low
#define OCCAMY_SOC_RO_END_ADDR_LOW_3_QUADRANT_5_REG_OFFSET 0x278

// Read-only cache end address high
#define OCCAMY_SOC_RO_END_ADDR_HIGH_3_QUADRANT_5_REG_OFFSET 0x27c
#define OCCAMY_SOC_RO_END_ADDR_HIGH_3_QUADRANT_5_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_END_ADDR_HIGH_3_QUADRANT_5_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_END_ADDR_HIGH_3_QUADRANT_5_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                               \
        .mask = OCCAMY_SOC_RO_END_ADDR_HIGH_3_QUADRANT_5_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_END_ADDR_HIGH_3_QUADRANT_5_ADDR_HIGH_OFFSET})

// Read-only cache start address low
#define OCCAMY_SOC_RO_START_ADDR_LOW_0_QUADRANT_6_REG_OFFSET 0x280

// Read-only cache start address high
#define OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_6_REG_OFFSET 0x284
#define OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_6_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_6_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_6_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                                 \
        .mask = OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_6_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_6_ADDR_HIGH_OFFSET})

// Read-only cache end address low
#define OCCAMY_SOC_RO_END_ADDR_LOW_0_QUADRANT_6_REG_OFFSET 0x288

// Read-only cache end address high
#define OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_6_REG_OFFSET 0x28c
#define OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_6_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_6_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_6_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                               \
        .mask = OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_6_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_6_ADDR_HIGH_OFFSET})

// Read-only cache start address low
#define OCCAMY_SOC_RO_START_ADDR_LOW_1_QUADRANT_6_REG_OFFSET 0x290

// Read-only cache start address high
#define OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_6_REG_OFFSET 0x294
#define OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_6_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_6_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_6_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                                 \
        .mask = OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_6_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_6_ADDR_HIGH_OFFSET})

// Read-only cache end address low
#define OCCAMY_SOC_RO_END_ADDR_LOW_1_QUADRANT_6_REG_OFFSET 0x298

// Read-only cache end address high
#define OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_6_REG_OFFSET 0x29c
#define OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_6_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_6_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_6_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                               \
        .mask = OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_6_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_6_ADDR_HIGH_OFFSET})

// Read-only cache start address low
#define OCCAMY_SOC_RO_START_ADDR_LOW_2_QUADRANT_6_REG_OFFSET 0x2a0

// Read-only cache start address high
#define OCCAMY_SOC_RO_START_ADDR_HIGH_2_QUADRANT_6_REG_OFFSET 0x2a4
#define OCCAMY_SOC_RO_START_ADDR_HIGH_2_QUADRANT_6_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_START_ADDR_HIGH_2_QUADRANT_6_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_START_ADDR_HIGH_2_QUADRANT_6_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                                 \
        .mask = OCCAMY_SOC_RO_START_ADDR_HIGH_2_QUADRANT_6_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_START_ADDR_HIGH_2_QUADRANT_6_ADDR_HIGH_OFFSET})

// Read-only cache end address low
#define OCCAMY_SOC_RO_END_ADDR_LOW_2_QUADRANT_6_REG_OFFSET 0x2a8

// Read-only cache end address high
#define OCCAMY_SOC_RO_END_ADDR_HIGH_2_QUADRANT_6_REG_OFFSET 0x2ac
#define OCCAMY_SOC_RO_END_ADDR_HIGH_2_QUADRANT_6_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_END_ADDR_HIGH_2_QUADRANT_6_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_END_ADDR_HIGH_2_QUADRANT_6_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                               \
        .mask = OCCAMY_SOC_RO_END_ADDR_HIGH_2_QUADRANT_6_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_END_ADDR_HIGH_2_QUADRANT_6_ADDR_HIGH_OFFSET})

// Read-only cache start address low
#define OCCAMY_SOC_RO_START_ADDR_LOW_3_QUADRANT_6_REG_OFFSET 0x2b0

// Read-only cache start address high
#define OCCAMY_SOC_RO_START_ADDR_HIGH_3_QUADRANT_6_REG_OFFSET 0x2b4
#define OCCAMY_SOC_RO_START_ADDR_HIGH_3_QUADRANT_6_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_START_ADDR_HIGH_3_QUADRANT_6_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_START_ADDR_HIGH_3_QUADRANT_6_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                                 \
        .mask = OCCAMY_SOC_RO_START_ADDR_HIGH_3_QUADRANT_6_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_START_ADDR_HIGH_3_QUADRANT_6_ADDR_HIGH_OFFSET})

// Read-only cache end address low
#define OCCAMY_SOC_RO_END_ADDR_LOW_3_QUADRANT_6_REG_OFFSET 0x2b8

// Read-only cache end address high
#define OCCAMY_SOC_RO_END_ADDR_HIGH_3_QUADRANT_6_REG_OFFSET 0x2bc
#define OCCAMY_SOC_RO_END_ADDR_HIGH_3_QUADRANT_6_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_END_ADDR_HIGH_3_QUADRANT_6_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_END_ADDR_HIGH_3_QUADRANT_6_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                               \
        .mask = OCCAMY_SOC_RO_END_ADDR_HIGH_3_QUADRANT_6_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_END_ADDR_HIGH_3_QUADRANT_6_ADDR_HIGH_OFFSET})

// Read-only cache start address low
#define OCCAMY_SOC_RO_START_ADDR_LOW_0_QUADRANT_7_REG_OFFSET 0x2c0

// Read-only cache start address high
#define OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_7_REG_OFFSET 0x2c4
#define OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_7_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_7_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_7_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                                 \
        .mask = OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_7_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_7_ADDR_HIGH_OFFSET})

// Read-only cache end address low
#define OCCAMY_SOC_RO_END_ADDR_LOW_0_QUADRANT_7_REG_OFFSET 0x2c8

// Read-only cache end address high
#define OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_7_REG_OFFSET 0x2cc
#define OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_7_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_7_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_7_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                               \
        .mask = OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_7_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_7_ADDR_HIGH_OFFSET})

// Read-only cache start address low
#define OCCAMY_SOC_RO_START_ADDR_LOW_1_QUADRANT_7_REG_OFFSET 0x2d0

// Read-only cache start address high
#define OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_7_REG_OFFSET 0x2d4
#define OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_7_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_7_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_7_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                                 \
        .mask = OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_7_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_7_ADDR_HIGH_OFFSET})

// Read-only cache end address low
#define OCCAMY_SOC_RO_END_ADDR_LOW_1_QUADRANT_7_REG_OFFSET 0x2d8

// Read-only cache end address high
#define OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_7_REG_OFFSET 0x2dc
#define OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_7_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_7_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_7_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                               \
        .mask = OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_7_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_7_ADDR_HIGH_OFFSET})

// Read-only cache start address low
#define OCCAMY_SOC_RO_START_ADDR_LOW_2_QUADRANT_7_REG_OFFSET 0x2e0

// Read-only cache start address high
#define OCCAMY_SOC_RO_START_ADDR_HIGH_2_QUADRANT_7_REG_OFFSET 0x2e4
#define OCCAMY_SOC_RO_START_ADDR_HIGH_2_QUADRANT_7_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_START_ADDR_HIGH_2_QUADRANT_7_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_START_ADDR_HIGH_2_QUADRANT_7_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                                 \
        .mask = OCCAMY_SOC_RO_START_ADDR_HIGH_2_QUADRANT_7_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_START_ADDR_HIGH_2_QUADRANT_7_ADDR_HIGH_OFFSET})

// Read-only cache end address low
#define OCCAMY_SOC_RO_END_ADDR_LOW_2_QUADRANT_7_REG_OFFSET 0x2e8

// Read-only cache end address high
#define OCCAMY_SOC_RO_END_ADDR_HIGH_2_QUADRANT_7_REG_OFFSET 0x2ec
#define OCCAMY_SOC_RO_END_ADDR_HIGH_2_QUADRANT_7_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_END_ADDR_HIGH_2_QUADRANT_7_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_END_ADDR_HIGH_2_QUADRANT_7_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                               \
        .mask = OCCAMY_SOC_RO_END_ADDR_HIGH_2_QUADRANT_7_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_END_ADDR_HIGH_2_QUADRANT_7_ADDR_HIGH_OFFSET})

// Read-only cache start address low
#define OCCAMY_SOC_RO_START_ADDR_LOW_3_QUADRANT_7_REG_OFFSET 0x2f0

// Read-only cache start address high
#define OCCAMY_SOC_RO_START_ADDR_HIGH_3_QUADRANT_7_REG_OFFSET 0x2f4
#define OCCAMY_SOC_RO_START_ADDR_HIGH_3_QUADRANT_7_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_START_ADDR_HIGH_3_QUADRANT_7_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_START_ADDR_HIGH_3_QUADRANT_7_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                                 \
        .mask = OCCAMY_SOC_RO_START_ADDR_HIGH_3_QUADRANT_7_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_START_ADDR_HIGH_3_QUADRANT_7_ADDR_HIGH_OFFSET})

// Read-only cache end address low
#define OCCAMY_SOC_RO_END_ADDR_LOW_3_QUADRANT_7_REG_OFFSET 0x2f8

// Read-only cache end address high
#define OCCAMY_SOC_RO_END_ADDR_HIGH_3_QUADRANT_7_REG_OFFSET 0x2fc
#define OCCAMY_SOC_RO_END_ADDR_HIGH_3_QUADRANT_7_ADDR_HIGH_MASK 0xffff
#define OCCAMY_SOC_RO_END_ADDR_HIGH_3_QUADRANT_7_ADDR_HIGH_OFFSET 0
#define OCCAMY_SOC_RO_END_ADDR_HIGH_3_QUADRANT_7_ADDR_HIGH_FIELD         \
    ((bitfield_field32_t){                                               \
        .mask = OCCAMY_SOC_RO_END_ADDR_HIGH_3_QUADRANT_7_ADDR_HIGH_MASK, \
        .index = OCCAMY_SOC_RO_END_ADDR_HIGH_3_QUADRANT_7_ADDR_HIGH_OFFSET})

#ifdef __cplusplus
}  // extern "C"
#endif
#endif  // _OCCAMY_SOC_REG_DEFS_
        // End generated register defines for Occamy_SoC