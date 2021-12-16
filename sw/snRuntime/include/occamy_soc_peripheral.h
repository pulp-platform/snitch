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

#ifdef __cplusplus
}  // extern "C"
#endif
#endif  // _OCCAMY_SOC_REG_DEFS_
        // End generated register defines for Occamy_SoC