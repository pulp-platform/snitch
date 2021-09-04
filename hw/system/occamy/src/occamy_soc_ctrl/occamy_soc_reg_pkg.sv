// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Register Package auto-generated by `reggen` containing data structure

package occamy_soc_reg_pkg;

  // Param list
  parameter int NumScratchRegs = 4;
  parameter int NumPads = 31;
  parameter int NumS1Quadrants = 8;

  ////////////////////////////
  // Typedefs for registers //
  ////////////////////////////
  typedef struct packed {
    struct packed {
      logic        q;
    } ecc_uncorrectable;
    struct packed {
      logic        q;
    } ecc_correctable;
  } occamy_soc_reg2hw_intr_state_reg_t;

  typedef struct packed {
    struct packed {
      logic        q;
    } ecc_uncorrectable;
    struct packed {
      logic        q;
    } ecc_correctable;
  } occamy_soc_reg2hw_intr_enable_reg_t;

  typedef struct packed {
    struct packed {
      logic        q;
      logic        qe;
    } ecc_uncorrectable;
    struct packed {
      logic        q;
      logic        qe;
    } ecc_correctable;
  } occamy_soc_reg2hw_intr_test_reg_t;

  typedef struct packed {
    struct packed {
      logic        q;
    } slw;
    struct packed {
      logic        q;
    } smt;
    struct packed {
      logic [1:0]  q;
    } drv;
  } occamy_soc_reg2hw_pad_mreg_t;

  typedef struct packed {
    logic [3:0]  q;
  } occamy_soc_reg2hw_isolate_mreg_t;

  typedef struct packed {
    logic        q;
  } occamy_soc_reg2hw_ro_cache_enable_mreg_t;

  typedef struct packed {
    logic        q;
  } occamy_soc_reg2hw_ro_cache_flush_mreg_t;

  typedef struct packed {
    logic [31:0] q;
  } occamy_soc_reg2hw_ro_start_addr_low_0_quadrant_0_reg_t;

  typedef struct packed {
    logic [15:0] q;
  } occamy_soc_reg2hw_ro_start_addr_high_0_quadrant_0_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } occamy_soc_reg2hw_ro_end_addr_low_0_quadrant_0_reg_t;

  typedef struct packed {
    logic [15:0] q;
  } occamy_soc_reg2hw_ro_end_addr_high_0_quadrant_0_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } occamy_soc_reg2hw_ro_start_addr_low_1_quadrant_0_reg_t;

  typedef struct packed {
    logic [15:0] q;
  } occamy_soc_reg2hw_ro_start_addr_high_1_quadrant_0_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } occamy_soc_reg2hw_ro_end_addr_low_1_quadrant_0_reg_t;

  typedef struct packed {
    logic [15:0] q;
  } occamy_soc_reg2hw_ro_end_addr_high_1_quadrant_0_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } occamy_soc_reg2hw_ro_start_addr_low_0_quadrant_1_reg_t;

  typedef struct packed {
    logic [15:0] q;
  } occamy_soc_reg2hw_ro_start_addr_high_0_quadrant_1_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } occamy_soc_reg2hw_ro_end_addr_low_0_quadrant_1_reg_t;

  typedef struct packed {
    logic [15:0] q;
  } occamy_soc_reg2hw_ro_end_addr_high_0_quadrant_1_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } occamy_soc_reg2hw_ro_start_addr_low_1_quadrant_1_reg_t;

  typedef struct packed {
    logic [15:0] q;
  } occamy_soc_reg2hw_ro_start_addr_high_1_quadrant_1_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } occamy_soc_reg2hw_ro_end_addr_low_1_quadrant_1_reg_t;

  typedef struct packed {
    logic [15:0] q;
  } occamy_soc_reg2hw_ro_end_addr_high_1_quadrant_1_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } occamy_soc_reg2hw_ro_start_addr_low_0_quadrant_2_reg_t;

  typedef struct packed {
    logic [15:0] q;
  } occamy_soc_reg2hw_ro_start_addr_high_0_quadrant_2_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } occamy_soc_reg2hw_ro_end_addr_low_0_quadrant_2_reg_t;

  typedef struct packed {
    logic [15:0] q;
  } occamy_soc_reg2hw_ro_end_addr_high_0_quadrant_2_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } occamy_soc_reg2hw_ro_start_addr_low_1_quadrant_2_reg_t;

  typedef struct packed {
    logic [15:0] q;
  } occamy_soc_reg2hw_ro_start_addr_high_1_quadrant_2_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } occamy_soc_reg2hw_ro_end_addr_low_1_quadrant_2_reg_t;

  typedef struct packed {
    logic [15:0] q;
  } occamy_soc_reg2hw_ro_end_addr_high_1_quadrant_2_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } occamy_soc_reg2hw_ro_start_addr_low_0_quadrant_3_reg_t;

  typedef struct packed {
    logic [15:0] q;
  } occamy_soc_reg2hw_ro_start_addr_high_0_quadrant_3_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } occamy_soc_reg2hw_ro_end_addr_low_0_quadrant_3_reg_t;

  typedef struct packed {
    logic [15:0] q;
  } occamy_soc_reg2hw_ro_end_addr_high_0_quadrant_3_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } occamy_soc_reg2hw_ro_start_addr_low_1_quadrant_3_reg_t;

  typedef struct packed {
    logic [15:0] q;
  } occamy_soc_reg2hw_ro_start_addr_high_1_quadrant_3_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } occamy_soc_reg2hw_ro_end_addr_low_1_quadrant_3_reg_t;

  typedef struct packed {
    logic [15:0] q;
  } occamy_soc_reg2hw_ro_end_addr_high_1_quadrant_3_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } occamy_soc_reg2hw_ro_start_addr_low_0_quadrant_4_reg_t;

  typedef struct packed {
    logic [15:0] q;
  } occamy_soc_reg2hw_ro_start_addr_high_0_quadrant_4_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } occamy_soc_reg2hw_ro_end_addr_low_0_quadrant_4_reg_t;

  typedef struct packed {
    logic [15:0] q;
  } occamy_soc_reg2hw_ro_end_addr_high_0_quadrant_4_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } occamy_soc_reg2hw_ro_start_addr_low_1_quadrant_4_reg_t;

  typedef struct packed {
    logic [15:0] q;
  } occamy_soc_reg2hw_ro_start_addr_high_1_quadrant_4_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } occamy_soc_reg2hw_ro_end_addr_low_1_quadrant_4_reg_t;

  typedef struct packed {
    logic [15:0] q;
  } occamy_soc_reg2hw_ro_end_addr_high_1_quadrant_4_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } occamy_soc_reg2hw_ro_start_addr_low_0_quadrant_5_reg_t;

  typedef struct packed {
    logic [15:0] q;
  } occamy_soc_reg2hw_ro_start_addr_high_0_quadrant_5_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } occamy_soc_reg2hw_ro_end_addr_low_0_quadrant_5_reg_t;

  typedef struct packed {
    logic [15:0] q;
  } occamy_soc_reg2hw_ro_end_addr_high_0_quadrant_5_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } occamy_soc_reg2hw_ro_start_addr_low_1_quadrant_5_reg_t;

  typedef struct packed {
    logic [15:0] q;
  } occamy_soc_reg2hw_ro_start_addr_high_1_quadrant_5_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } occamy_soc_reg2hw_ro_end_addr_low_1_quadrant_5_reg_t;

  typedef struct packed {
    logic [15:0] q;
  } occamy_soc_reg2hw_ro_end_addr_high_1_quadrant_5_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } occamy_soc_reg2hw_ro_start_addr_low_0_quadrant_6_reg_t;

  typedef struct packed {
    logic [15:0] q;
  } occamy_soc_reg2hw_ro_start_addr_high_0_quadrant_6_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } occamy_soc_reg2hw_ro_end_addr_low_0_quadrant_6_reg_t;

  typedef struct packed {
    logic [15:0] q;
  } occamy_soc_reg2hw_ro_end_addr_high_0_quadrant_6_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } occamy_soc_reg2hw_ro_start_addr_low_1_quadrant_6_reg_t;

  typedef struct packed {
    logic [15:0] q;
  } occamy_soc_reg2hw_ro_start_addr_high_1_quadrant_6_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } occamy_soc_reg2hw_ro_end_addr_low_1_quadrant_6_reg_t;

  typedef struct packed {
    logic [15:0] q;
  } occamy_soc_reg2hw_ro_end_addr_high_1_quadrant_6_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } occamy_soc_reg2hw_ro_start_addr_low_0_quadrant_7_reg_t;

  typedef struct packed {
    logic [15:0] q;
  } occamy_soc_reg2hw_ro_start_addr_high_0_quadrant_7_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } occamy_soc_reg2hw_ro_end_addr_low_0_quadrant_7_reg_t;

  typedef struct packed {
    logic [15:0] q;
  } occamy_soc_reg2hw_ro_end_addr_high_0_quadrant_7_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } occamy_soc_reg2hw_ro_start_addr_low_1_quadrant_7_reg_t;

  typedef struct packed {
    logic [15:0] q;
  } occamy_soc_reg2hw_ro_start_addr_high_1_quadrant_7_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } occamy_soc_reg2hw_ro_end_addr_low_1_quadrant_7_reg_t;

  typedef struct packed {
    logic [15:0] q;
  } occamy_soc_reg2hw_ro_end_addr_high_1_quadrant_7_reg_t;


  typedef struct packed {
    struct packed {
      logic        d;
      logic        de;
    } ecc_uncorrectable;
    struct packed {
      logic        d;
      logic        de;
    } ecc_correctable;
  } occamy_soc_hw2reg_intr_state_reg_t;

  typedef struct packed {
    logic [1:0]  d;
  } occamy_soc_hw2reg_boot_mode_reg_t;

  typedef struct packed {
    logic [3:0]  d;
  } occamy_soc_hw2reg_isolated_mreg_t;

  typedef struct packed {
    logic        d;
    logic        de;
  } occamy_soc_hw2reg_ro_cache_flush_mreg_t;


  ///////////////////////////////////////
  // Register to internal design logic //
  ///////////////////////////////////////
  typedef struct packed {
    occamy_soc_reg2hw_intr_state_reg_t intr_state; // [1716:1715]
    occamy_soc_reg2hw_intr_enable_reg_t intr_enable; // [1714:1713]
    occamy_soc_reg2hw_intr_test_reg_t intr_test; // [1712:1709]
    occamy_soc_reg2hw_pad_mreg_t [30:0] pad; // [1708:1585]
    occamy_soc_reg2hw_isolate_mreg_t [7:0] isolate; // [1584:1553]
    occamy_soc_reg2hw_ro_cache_enable_mreg_t [7:0] ro_cache_enable; // [1552:1545]
    occamy_soc_reg2hw_ro_cache_flush_mreg_t [7:0] ro_cache_flush; // [1544:1537]
    occamy_soc_reg2hw_ro_start_addr_low_0_quadrant_0_reg_t ro_start_addr_low_0_quadrant_0; // [1536:1505]
    occamy_soc_reg2hw_ro_start_addr_high_0_quadrant_0_reg_t ro_start_addr_high_0_quadrant_0; // [1504:1489]
    occamy_soc_reg2hw_ro_end_addr_low_0_quadrant_0_reg_t ro_end_addr_low_0_quadrant_0; // [1488:1457]
    occamy_soc_reg2hw_ro_end_addr_high_0_quadrant_0_reg_t ro_end_addr_high_0_quadrant_0; // [1456:1441]
    occamy_soc_reg2hw_ro_start_addr_low_1_quadrant_0_reg_t ro_start_addr_low_1_quadrant_0; // [1440:1409]
    occamy_soc_reg2hw_ro_start_addr_high_1_quadrant_0_reg_t ro_start_addr_high_1_quadrant_0; // [1408:1393]
    occamy_soc_reg2hw_ro_end_addr_low_1_quadrant_0_reg_t ro_end_addr_low_1_quadrant_0; // [1392:1361]
    occamy_soc_reg2hw_ro_end_addr_high_1_quadrant_0_reg_t ro_end_addr_high_1_quadrant_0; // [1360:1345]
    occamy_soc_reg2hw_ro_start_addr_low_0_quadrant_1_reg_t ro_start_addr_low_0_quadrant_1; // [1344:1313]
    occamy_soc_reg2hw_ro_start_addr_high_0_quadrant_1_reg_t ro_start_addr_high_0_quadrant_1; // [1312:1297]
    occamy_soc_reg2hw_ro_end_addr_low_0_quadrant_1_reg_t ro_end_addr_low_0_quadrant_1; // [1296:1265]
    occamy_soc_reg2hw_ro_end_addr_high_0_quadrant_1_reg_t ro_end_addr_high_0_quadrant_1; // [1264:1249]
    occamy_soc_reg2hw_ro_start_addr_low_1_quadrant_1_reg_t ro_start_addr_low_1_quadrant_1; // [1248:1217]
    occamy_soc_reg2hw_ro_start_addr_high_1_quadrant_1_reg_t ro_start_addr_high_1_quadrant_1; // [1216:1201]
    occamy_soc_reg2hw_ro_end_addr_low_1_quadrant_1_reg_t ro_end_addr_low_1_quadrant_1; // [1200:1169]
    occamy_soc_reg2hw_ro_end_addr_high_1_quadrant_1_reg_t ro_end_addr_high_1_quadrant_1; // [1168:1153]
    occamy_soc_reg2hw_ro_start_addr_low_0_quadrant_2_reg_t ro_start_addr_low_0_quadrant_2; // [1152:1121]
    occamy_soc_reg2hw_ro_start_addr_high_0_quadrant_2_reg_t ro_start_addr_high_0_quadrant_2; // [1120:1105]
    occamy_soc_reg2hw_ro_end_addr_low_0_quadrant_2_reg_t ro_end_addr_low_0_quadrant_2; // [1104:1073]
    occamy_soc_reg2hw_ro_end_addr_high_0_quadrant_2_reg_t ro_end_addr_high_0_quadrant_2; // [1072:1057]
    occamy_soc_reg2hw_ro_start_addr_low_1_quadrant_2_reg_t ro_start_addr_low_1_quadrant_2; // [1056:1025]
    occamy_soc_reg2hw_ro_start_addr_high_1_quadrant_2_reg_t ro_start_addr_high_1_quadrant_2; // [1024:1009]
    occamy_soc_reg2hw_ro_end_addr_low_1_quadrant_2_reg_t ro_end_addr_low_1_quadrant_2; // [1008:977]
    occamy_soc_reg2hw_ro_end_addr_high_1_quadrant_2_reg_t ro_end_addr_high_1_quadrant_2; // [976:961]
    occamy_soc_reg2hw_ro_start_addr_low_0_quadrant_3_reg_t ro_start_addr_low_0_quadrant_3; // [960:929]
    occamy_soc_reg2hw_ro_start_addr_high_0_quadrant_3_reg_t ro_start_addr_high_0_quadrant_3; // [928:913]
    occamy_soc_reg2hw_ro_end_addr_low_0_quadrant_3_reg_t ro_end_addr_low_0_quadrant_3; // [912:881]
    occamy_soc_reg2hw_ro_end_addr_high_0_quadrant_3_reg_t ro_end_addr_high_0_quadrant_3; // [880:865]
    occamy_soc_reg2hw_ro_start_addr_low_1_quadrant_3_reg_t ro_start_addr_low_1_quadrant_3; // [864:833]
    occamy_soc_reg2hw_ro_start_addr_high_1_quadrant_3_reg_t ro_start_addr_high_1_quadrant_3; // [832:817]
    occamy_soc_reg2hw_ro_end_addr_low_1_quadrant_3_reg_t ro_end_addr_low_1_quadrant_3; // [816:785]
    occamy_soc_reg2hw_ro_end_addr_high_1_quadrant_3_reg_t ro_end_addr_high_1_quadrant_3; // [784:769]
    occamy_soc_reg2hw_ro_start_addr_low_0_quadrant_4_reg_t ro_start_addr_low_0_quadrant_4; // [768:737]
    occamy_soc_reg2hw_ro_start_addr_high_0_quadrant_4_reg_t ro_start_addr_high_0_quadrant_4; // [736:721]
    occamy_soc_reg2hw_ro_end_addr_low_0_quadrant_4_reg_t ro_end_addr_low_0_quadrant_4; // [720:689]
    occamy_soc_reg2hw_ro_end_addr_high_0_quadrant_4_reg_t ro_end_addr_high_0_quadrant_4; // [688:673]
    occamy_soc_reg2hw_ro_start_addr_low_1_quadrant_4_reg_t ro_start_addr_low_1_quadrant_4; // [672:641]
    occamy_soc_reg2hw_ro_start_addr_high_1_quadrant_4_reg_t ro_start_addr_high_1_quadrant_4; // [640:625]
    occamy_soc_reg2hw_ro_end_addr_low_1_quadrant_4_reg_t ro_end_addr_low_1_quadrant_4; // [624:593]
    occamy_soc_reg2hw_ro_end_addr_high_1_quadrant_4_reg_t ro_end_addr_high_1_quadrant_4; // [592:577]
    occamy_soc_reg2hw_ro_start_addr_low_0_quadrant_5_reg_t ro_start_addr_low_0_quadrant_5; // [576:545]
    occamy_soc_reg2hw_ro_start_addr_high_0_quadrant_5_reg_t ro_start_addr_high_0_quadrant_5; // [544:529]
    occamy_soc_reg2hw_ro_end_addr_low_0_quadrant_5_reg_t ro_end_addr_low_0_quadrant_5; // [528:497]
    occamy_soc_reg2hw_ro_end_addr_high_0_quadrant_5_reg_t ro_end_addr_high_0_quadrant_5; // [496:481]
    occamy_soc_reg2hw_ro_start_addr_low_1_quadrant_5_reg_t ro_start_addr_low_1_quadrant_5; // [480:449]
    occamy_soc_reg2hw_ro_start_addr_high_1_quadrant_5_reg_t ro_start_addr_high_1_quadrant_5; // [448:433]
    occamy_soc_reg2hw_ro_end_addr_low_1_quadrant_5_reg_t ro_end_addr_low_1_quadrant_5; // [432:401]
    occamy_soc_reg2hw_ro_end_addr_high_1_quadrant_5_reg_t ro_end_addr_high_1_quadrant_5; // [400:385]
    occamy_soc_reg2hw_ro_start_addr_low_0_quadrant_6_reg_t ro_start_addr_low_0_quadrant_6; // [384:353]
    occamy_soc_reg2hw_ro_start_addr_high_0_quadrant_6_reg_t ro_start_addr_high_0_quadrant_6; // [352:337]
    occamy_soc_reg2hw_ro_end_addr_low_0_quadrant_6_reg_t ro_end_addr_low_0_quadrant_6; // [336:305]
    occamy_soc_reg2hw_ro_end_addr_high_0_quadrant_6_reg_t ro_end_addr_high_0_quadrant_6; // [304:289]
    occamy_soc_reg2hw_ro_start_addr_low_1_quadrant_6_reg_t ro_start_addr_low_1_quadrant_6; // [288:257]
    occamy_soc_reg2hw_ro_start_addr_high_1_quadrant_6_reg_t ro_start_addr_high_1_quadrant_6; // [256:241]
    occamy_soc_reg2hw_ro_end_addr_low_1_quadrant_6_reg_t ro_end_addr_low_1_quadrant_6; // [240:209]
    occamy_soc_reg2hw_ro_end_addr_high_1_quadrant_6_reg_t ro_end_addr_high_1_quadrant_6; // [208:193]
    occamy_soc_reg2hw_ro_start_addr_low_0_quadrant_7_reg_t ro_start_addr_low_0_quadrant_7; // [192:161]
    occamy_soc_reg2hw_ro_start_addr_high_0_quadrant_7_reg_t ro_start_addr_high_0_quadrant_7; // [160:145]
    occamy_soc_reg2hw_ro_end_addr_low_0_quadrant_7_reg_t ro_end_addr_low_0_quadrant_7; // [144:113]
    occamy_soc_reg2hw_ro_end_addr_high_0_quadrant_7_reg_t ro_end_addr_high_0_quadrant_7; // [112:97]
    occamy_soc_reg2hw_ro_start_addr_low_1_quadrant_7_reg_t ro_start_addr_low_1_quadrant_7; // [96:65]
    occamy_soc_reg2hw_ro_start_addr_high_1_quadrant_7_reg_t ro_start_addr_high_1_quadrant_7; // [64:49]
    occamy_soc_reg2hw_ro_end_addr_low_1_quadrant_7_reg_t ro_end_addr_low_1_quadrant_7; // [48:17]
    occamy_soc_reg2hw_ro_end_addr_high_1_quadrant_7_reg_t ro_end_addr_high_1_quadrant_7; // [16:1]
  } occamy_soc_reg2hw_t;

  ///////////////////////////////////////
  // Internal design logic to register //
  ///////////////////////////////////////
  typedef struct packed {
    occamy_soc_hw2reg_intr_state_reg_t intr_state; // [54:53]
    occamy_soc_hw2reg_boot_mode_reg_t boot_mode; // [52:53]
    occamy_soc_hw2reg_isolated_mreg_t [7:0] isolated; // [52:21]
    occamy_soc_hw2reg_ro_cache_flush_mreg_t [7:0] ro_cache_flush; // [20:5]
  } occamy_soc_hw2reg_t;

  // Register Address
  parameter logic [8:0] OCCAMY_SOC_INTR_STATE_OFFSET = 9'h 0;
  parameter logic [8:0] OCCAMY_SOC_INTR_ENABLE_OFFSET = 9'h 4;
  parameter logic [8:0] OCCAMY_SOC_INTR_TEST_OFFSET = 9'h 8;
  parameter logic [8:0] OCCAMY_SOC_VERSION_OFFSET = 9'h c;
  parameter logic [8:0] OCCAMY_SOC_SCRATCH_0_OFFSET = 9'h 10;
  parameter logic [8:0] OCCAMY_SOC_SCRATCH_1_OFFSET = 9'h 14;
  parameter logic [8:0] OCCAMY_SOC_SCRATCH_2_OFFSET = 9'h 18;
  parameter logic [8:0] OCCAMY_SOC_SCRATCH_3_OFFSET = 9'h 1c;
  parameter logic [8:0] OCCAMY_SOC_BOOT_MODE_OFFSET = 9'h 20;
  parameter logic [8:0] OCCAMY_SOC_PAD_0_OFFSET = 9'h 24;
  parameter logic [8:0] OCCAMY_SOC_PAD_1_OFFSET = 9'h 28;
  parameter logic [8:0] OCCAMY_SOC_PAD_2_OFFSET = 9'h 2c;
  parameter logic [8:0] OCCAMY_SOC_PAD_3_OFFSET = 9'h 30;
  parameter logic [8:0] OCCAMY_SOC_PAD_4_OFFSET = 9'h 34;
  parameter logic [8:0] OCCAMY_SOC_PAD_5_OFFSET = 9'h 38;
  parameter logic [8:0] OCCAMY_SOC_PAD_6_OFFSET = 9'h 3c;
  parameter logic [8:0] OCCAMY_SOC_PAD_7_OFFSET = 9'h 40;
  parameter logic [8:0] OCCAMY_SOC_PAD_8_OFFSET = 9'h 44;
  parameter logic [8:0] OCCAMY_SOC_PAD_9_OFFSET = 9'h 48;
  parameter logic [8:0] OCCAMY_SOC_PAD_10_OFFSET = 9'h 4c;
  parameter logic [8:0] OCCAMY_SOC_PAD_11_OFFSET = 9'h 50;
  parameter logic [8:0] OCCAMY_SOC_PAD_12_OFFSET = 9'h 54;
  parameter logic [8:0] OCCAMY_SOC_PAD_13_OFFSET = 9'h 58;
  parameter logic [8:0] OCCAMY_SOC_PAD_14_OFFSET = 9'h 5c;
  parameter logic [8:0] OCCAMY_SOC_PAD_15_OFFSET = 9'h 60;
  parameter logic [8:0] OCCAMY_SOC_PAD_16_OFFSET = 9'h 64;
  parameter logic [8:0] OCCAMY_SOC_PAD_17_OFFSET = 9'h 68;
  parameter logic [8:0] OCCAMY_SOC_PAD_18_OFFSET = 9'h 6c;
  parameter logic [8:0] OCCAMY_SOC_PAD_19_OFFSET = 9'h 70;
  parameter logic [8:0] OCCAMY_SOC_PAD_20_OFFSET = 9'h 74;
  parameter logic [8:0] OCCAMY_SOC_PAD_21_OFFSET = 9'h 78;
  parameter logic [8:0] OCCAMY_SOC_PAD_22_OFFSET = 9'h 7c;
  parameter logic [8:0] OCCAMY_SOC_PAD_23_OFFSET = 9'h 80;
  parameter logic [8:0] OCCAMY_SOC_PAD_24_OFFSET = 9'h 84;
  parameter logic [8:0] OCCAMY_SOC_PAD_25_OFFSET = 9'h 88;
  parameter logic [8:0] OCCAMY_SOC_PAD_26_OFFSET = 9'h 8c;
  parameter logic [8:0] OCCAMY_SOC_PAD_27_OFFSET = 9'h 90;
  parameter logic [8:0] OCCAMY_SOC_PAD_28_OFFSET = 9'h 94;
  parameter logic [8:0] OCCAMY_SOC_PAD_29_OFFSET = 9'h 98;
  parameter logic [8:0] OCCAMY_SOC_PAD_30_OFFSET = 9'h 9c;
  parameter logic [8:0] OCCAMY_SOC_ISOLATE_OFFSET = 9'h a0;
  parameter logic [8:0] OCCAMY_SOC_ISOLATED_OFFSET = 9'h a4;
  parameter logic [8:0] OCCAMY_SOC_RO_CACHE_ENABLE_OFFSET = 9'h a8;
  parameter logic [8:0] OCCAMY_SOC_RO_CACHE_FLUSH_OFFSET = 9'h ac;
  parameter logic [8:0] OCCAMY_SOC_RO_START_ADDR_LOW_0_QUADRANT_0_OFFSET = 9'h 100;
  parameter logic [8:0] OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_0_OFFSET = 9'h 104;
  parameter logic [8:0] OCCAMY_SOC_RO_END_ADDR_LOW_0_QUADRANT_0_OFFSET = 9'h 108;
  parameter logic [8:0] OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_0_OFFSET = 9'h 10c;
  parameter logic [8:0] OCCAMY_SOC_RO_START_ADDR_LOW_1_QUADRANT_0_OFFSET = 9'h 110;
  parameter logic [8:0] OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_0_OFFSET = 9'h 114;
  parameter logic [8:0] OCCAMY_SOC_RO_END_ADDR_LOW_1_QUADRANT_0_OFFSET = 9'h 118;
  parameter logic [8:0] OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_0_OFFSET = 9'h 11c;
  parameter logic [8:0] OCCAMY_SOC_RO_START_ADDR_LOW_0_QUADRANT_1_OFFSET = 9'h 120;
  parameter logic [8:0] OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_1_OFFSET = 9'h 124;
  parameter logic [8:0] OCCAMY_SOC_RO_END_ADDR_LOW_0_QUADRANT_1_OFFSET = 9'h 128;
  parameter logic [8:0] OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_1_OFFSET = 9'h 12c;
  parameter logic [8:0] OCCAMY_SOC_RO_START_ADDR_LOW_1_QUADRANT_1_OFFSET = 9'h 130;
  parameter logic [8:0] OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_1_OFFSET = 9'h 134;
  parameter logic [8:0] OCCAMY_SOC_RO_END_ADDR_LOW_1_QUADRANT_1_OFFSET = 9'h 138;
  parameter logic [8:0] OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_1_OFFSET = 9'h 13c;
  parameter logic [8:0] OCCAMY_SOC_RO_START_ADDR_LOW_0_QUADRANT_2_OFFSET = 9'h 140;
  parameter logic [8:0] OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_2_OFFSET = 9'h 144;
  parameter logic [8:0] OCCAMY_SOC_RO_END_ADDR_LOW_0_QUADRANT_2_OFFSET = 9'h 148;
  parameter logic [8:0] OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_2_OFFSET = 9'h 14c;
  parameter logic [8:0] OCCAMY_SOC_RO_START_ADDR_LOW_1_QUADRANT_2_OFFSET = 9'h 150;
  parameter logic [8:0] OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_2_OFFSET = 9'h 154;
  parameter logic [8:0] OCCAMY_SOC_RO_END_ADDR_LOW_1_QUADRANT_2_OFFSET = 9'h 158;
  parameter logic [8:0] OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_2_OFFSET = 9'h 15c;
  parameter logic [8:0] OCCAMY_SOC_RO_START_ADDR_LOW_0_QUADRANT_3_OFFSET = 9'h 160;
  parameter logic [8:0] OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_3_OFFSET = 9'h 164;
  parameter logic [8:0] OCCAMY_SOC_RO_END_ADDR_LOW_0_QUADRANT_3_OFFSET = 9'h 168;
  parameter logic [8:0] OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_3_OFFSET = 9'h 16c;
  parameter logic [8:0] OCCAMY_SOC_RO_START_ADDR_LOW_1_QUADRANT_3_OFFSET = 9'h 170;
  parameter logic [8:0] OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_3_OFFSET = 9'h 174;
  parameter logic [8:0] OCCAMY_SOC_RO_END_ADDR_LOW_1_QUADRANT_3_OFFSET = 9'h 178;
  parameter logic [8:0] OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_3_OFFSET = 9'h 17c;
  parameter logic [8:0] OCCAMY_SOC_RO_START_ADDR_LOW_0_QUADRANT_4_OFFSET = 9'h 180;
  parameter logic [8:0] OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_4_OFFSET = 9'h 184;
  parameter logic [8:0] OCCAMY_SOC_RO_END_ADDR_LOW_0_QUADRANT_4_OFFSET = 9'h 188;
  parameter logic [8:0] OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_4_OFFSET = 9'h 18c;
  parameter logic [8:0] OCCAMY_SOC_RO_START_ADDR_LOW_1_QUADRANT_4_OFFSET = 9'h 190;
  parameter logic [8:0] OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_4_OFFSET = 9'h 194;
  parameter logic [8:0] OCCAMY_SOC_RO_END_ADDR_LOW_1_QUADRANT_4_OFFSET = 9'h 198;
  parameter logic [8:0] OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_4_OFFSET = 9'h 19c;
  parameter logic [8:0] OCCAMY_SOC_RO_START_ADDR_LOW_0_QUADRANT_5_OFFSET = 9'h 1a0;
  parameter logic [8:0] OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_5_OFFSET = 9'h 1a4;
  parameter logic [8:0] OCCAMY_SOC_RO_END_ADDR_LOW_0_QUADRANT_5_OFFSET = 9'h 1a8;
  parameter logic [8:0] OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_5_OFFSET = 9'h 1ac;
  parameter logic [8:0] OCCAMY_SOC_RO_START_ADDR_LOW_1_QUADRANT_5_OFFSET = 9'h 1b0;
  parameter logic [8:0] OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_5_OFFSET = 9'h 1b4;
  parameter logic [8:0] OCCAMY_SOC_RO_END_ADDR_LOW_1_QUADRANT_5_OFFSET = 9'h 1b8;
  parameter logic [8:0] OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_5_OFFSET = 9'h 1bc;
  parameter logic [8:0] OCCAMY_SOC_RO_START_ADDR_LOW_0_QUADRANT_6_OFFSET = 9'h 1c0;
  parameter logic [8:0] OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_6_OFFSET = 9'h 1c4;
  parameter logic [8:0] OCCAMY_SOC_RO_END_ADDR_LOW_0_QUADRANT_6_OFFSET = 9'h 1c8;
  parameter logic [8:0] OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_6_OFFSET = 9'h 1cc;
  parameter logic [8:0] OCCAMY_SOC_RO_START_ADDR_LOW_1_QUADRANT_6_OFFSET = 9'h 1d0;
  parameter logic [8:0] OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_6_OFFSET = 9'h 1d4;
  parameter logic [8:0] OCCAMY_SOC_RO_END_ADDR_LOW_1_QUADRANT_6_OFFSET = 9'h 1d8;
  parameter logic [8:0] OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_6_OFFSET = 9'h 1dc;
  parameter logic [8:0] OCCAMY_SOC_RO_START_ADDR_LOW_0_QUADRANT_7_OFFSET = 9'h 1e0;
  parameter logic [8:0] OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_7_OFFSET = 9'h 1e4;
  parameter logic [8:0] OCCAMY_SOC_RO_END_ADDR_LOW_0_QUADRANT_7_OFFSET = 9'h 1e8;
  parameter logic [8:0] OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_7_OFFSET = 9'h 1ec;
  parameter logic [8:0] OCCAMY_SOC_RO_START_ADDR_LOW_1_QUADRANT_7_OFFSET = 9'h 1f0;
  parameter logic [8:0] OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_7_OFFSET = 9'h 1f4;
  parameter logic [8:0] OCCAMY_SOC_RO_END_ADDR_LOW_1_QUADRANT_7_OFFSET = 9'h 1f8;
  parameter logic [8:0] OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_7_OFFSET = 9'h 1fc;


  // Register Index
  typedef enum int {
    OCCAMY_SOC_INTR_STATE,
    OCCAMY_SOC_INTR_ENABLE,
    OCCAMY_SOC_INTR_TEST,
    OCCAMY_SOC_VERSION,
    OCCAMY_SOC_SCRATCH_0,
    OCCAMY_SOC_SCRATCH_1,
    OCCAMY_SOC_SCRATCH_2,
    OCCAMY_SOC_SCRATCH_3,
    OCCAMY_SOC_BOOT_MODE,
    OCCAMY_SOC_PAD_0,
    OCCAMY_SOC_PAD_1,
    OCCAMY_SOC_PAD_2,
    OCCAMY_SOC_PAD_3,
    OCCAMY_SOC_PAD_4,
    OCCAMY_SOC_PAD_5,
    OCCAMY_SOC_PAD_6,
    OCCAMY_SOC_PAD_7,
    OCCAMY_SOC_PAD_8,
    OCCAMY_SOC_PAD_9,
    OCCAMY_SOC_PAD_10,
    OCCAMY_SOC_PAD_11,
    OCCAMY_SOC_PAD_12,
    OCCAMY_SOC_PAD_13,
    OCCAMY_SOC_PAD_14,
    OCCAMY_SOC_PAD_15,
    OCCAMY_SOC_PAD_16,
    OCCAMY_SOC_PAD_17,
    OCCAMY_SOC_PAD_18,
    OCCAMY_SOC_PAD_19,
    OCCAMY_SOC_PAD_20,
    OCCAMY_SOC_PAD_21,
    OCCAMY_SOC_PAD_22,
    OCCAMY_SOC_PAD_23,
    OCCAMY_SOC_PAD_24,
    OCCAMY_SOC_PAD_25,
    OCCAMY_SOC_PAD_26,
    OCCAMY_SOC_PAD_27,
    OCCAMY_SOC_PAD_28,
    OCCAMY_SOC_PAD_29,
    OCCAMY_SOC_PAD_30,
    OCCAMY_SOC_ISOLATE,
    OCCAMY_SOC_ISOLATED,
    OCCAMY_SOC_RO_CACHE_ENABLE,
    OCCAMY_SOC_RO_CACHE_FLUSH,
    OCCAMY_SOC_RO_START_ADDR_LOW_0_QUADRANT_0,
    OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_0,
    OCCAMY_SOC_RO_END_ADDR_LOW_0_QUADRANT_0,
    OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_0,
    OCCAMY_SOC_RO_START_ADDR_LOW_1_QUADRANT_0,
    OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_0,
    OCCAMY_SOC_RO_END_ADDR_LOW_1_QUADRANT_0,
    OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_0,
    OCCAMY_SOC_RO_START_ADDR_LOW_0_QUADRANT_1,
    OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_1,
    OCCAMY_SOC_RO_END_ADDR_LOW_0_QUADRANT_1,
    OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_1,
    OCCAMY_SOC_RO_START_ADDR_LOW_1_QUADRANT_1,
    OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_1,
    OCCAMY_SOC_RO_END_ADDR_LOW_1_QUADRANT_1,
    OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_1,
    OCCAMY_SOC_RO_START_ADDR_LOW_0_QUADRANT_2,
    OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_2,
    OCCAMY_SOC_RO_END_ADDR_LOW_0_QUADRANT_2,
    OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_2,
    OCCAMY_SOC_RO_START_ADDR_LOW_1_QUADRANT_2,
    OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_2,
    OCCAMY_SOC_RO_END_ADDR_LOW_1_QUADRANT_2,
    OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_2,
    OCCAMY_SOC_RO_START_ADDR_LOW_0_QUADRANT_3,
    OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_3,
    OCCAMY_SOC_RO_END_ADDR_LOW_0_QUADRANT_3,
    OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_3,
    OCCAMY_SOC_RO_START_ADDR_LOW_1_QUADRANT_3,
    OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_3,
    OCCAMY_SOC_RO_END_ADDR_LOW_1_QUADRANT_3,
    OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_3,
    OCCAMY_SOC_RO_START_ADDR_LOW_0_QUADRANT_4,
    OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_4,
    OCCAMY_SOC_RO_END_ADDR_LOW_0_QUADRANT_4,
    OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_4,
    OCCAMY_SOC_RO_START_ADDR_LOW_1_QUADRANT_4,
    OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_4,
    OCCAMY_SOC_RO_END_ADDR_LOW_1_QUADRANT_4,
    OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_4,
    OCCAMY_SOC_RO_START_ADDR_LOW_0_QUADRANT_5,
    OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_5,
    OCCAMY_SOC_RO_END_ADDR_LOW_0_QUADRANT_5,
    OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_5,
    OCCAMY_SOC_RO_START_ADDR_LOW_1_QUADRANT_5,
    OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_5,
    OCCAMY_SOC_RO_END_ADDR_LOW_1_QUADRANT_5,
    OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_5,
    OCCAMY_SOC_RO_START_ADDR_LOW_0_QUADRANT_6,
    OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_6,
    OCCAMY_SOC_RO_END_ADDR_LOW_0_QUADRANT_6,
    OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_6,
    OCCAMY_SOC_RO_START_ADDR_LOW_1_QUADRANT_6,
    OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_6,
    OCCAMY_SOC_RO_END_ADDR_LOW_1_QUADRANT_6,
    OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_6,
    OCCAMY_SOC_RO_START_ADDR_LOW_0_QUADRANT_7,
    OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_7,
    OCCAMY_SOC_RO_END_ADDR_LOW_0_QUADRANT_7,
    OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_7,
    OCCAMY_SOC_RO_START_ADDR_LOW_1_QUADRANT_7,
    OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_7,
    OCCAMY_SOC_RO_END_ADDR_LOW_1_QUADRANT_7,
    OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_7
  } occamy_soc_id_e;

  // Register width information to check illegal writes
  parameter logic [3:0] OCCAMY_SOC_PERMIT [108] = '{
    4'b 0001, // index[  0] OCCAMY_SOC_INTR_STATE
    4'b 0001, // index[  1] OCCAMY_SOC_INTR_ENABLE
    4'b 0001, // index[  2] OCCAMY_SOC_INTR_TEST
    4'b 0011, // index[  3] OCCAMY_SOC_VERSION
    4'b 1111, // index[  4] OCCAMY_SOC_SCRATCH_0
    4'b 1111, // index[  5] OCCAMY_SOC_SCRATCH_1
    4'b 1111, // index[  6] OCCAMY_SOC_SCRATCH_2
    4'b 1111, // index[  7] OCCAMY_SOC_SCRATCH_3
    4'b 0001, // index[  8] OCCAMY_SOC_BOOT_MODE
    4'b 0001, // index[  9] OCCAMY_SOC_PAD_0
    4'b 0001, // index[ 10] OCCAMY_SOC_PAD_1
    4'b 0001, // index[ 11] OCCAMY_SOC_PAD_2
    4'b 0001, // index[ 12] OCCAMY_SOC_PAD_3
    4'b 0001, // index[ 13] OCCAMY_SOC_PAD_4
    4'b 0001, // index[ 14] OCCAMY_SOC_PAD_5
    4'b 0001, // index[ 15] OCCAMY_SOC_PAD_6
    4'b 0001, // index[ 16] OCCAMY_SOC_PAD_7
    4'b 0001, // index[ 17] OCCAMY_SOC_PAD_8
    4'b 0001, // index[ 18] OCCAMY_SOC_PAD_9
    4'b 0001, // index[ 19] OCCAMY_SOC_PAD_10
    4'b 0001, // index[ 20] OCCAMY_SOC_PAD_11
    4'b 0001, // index[ 21] OCCAMY_SOC_PAD_12
    4'b 0001, // index[ 22] OCCAMY_SOC_PAD_13
    4'b 0001, // index[ 23] OCCAMY_SOC_PAD_14
    4'b 0001, // index[ 24] OCCAMY_SOC_PAD_15
    4'b 0001, // index[ 25] OCCAMY_SOC_PAD_16
    4'b 0001, // index[ 26] OCCAMY_SOC_PAD_17
    4'b 0001, // index[ 27] OCCAMY_SOC_PAD_18
    4'b 0001, // index[ 28] OCCAMY_SOC_PAD_19
    4'b 0001, // index[ 29] OCCAMY_SOC_PAD_20
    4'b 0001, // index[ 30] OCCAMY_SOC_PAD_21
    4'b 0001, // index[ 31] OCCAMY_SOC_PAD_22
    4'b 0001, // index[ 32] OCCAMY_SOC_PAD_23
    4'b 0001, // index[ 33] OCCAMY_SOC_PAD_24
    4'b 0001, // index[ 34] OCCAMY_SOC_PAD_25
    4'b 0001, // index[ 35] OCCAMY_SOC_PAD_26
    4'b 0001, // index[ 36] OCCAMY_SOC_PAD_27
    4'b 0001, // index[ 37] OCCAMY_SOC_PAD_28
    4'b 0001, // index[ 38] OCCAMY_SOC_PAD_29
    4'b 0001, // index[ 39] OCCAMY_SOC_PAD_30
    4'b 1111, // index[ 40] OCCAMY_SOC_ISOLATE
    4'b 1111, // index[ 41] OCCAMY_SOC_ISOLATED
    4'b 0001, // index[ 42] OCCAMY_SOC_RO_CACHE_ENABLE
    4'b 0001, // index[ 43] OCCAMY_SOC_RO_CACHE_FLUSH
    4'b 1111, // index[ 44] OCCAMY_SOC_RO_START_ADDR_LOW_0_QUADRANT_0
    4'b 0011, // index[ 45] OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_0
    4'b 1111, // index[ 46] OCCAMY_SOC_RO_END_ADDR_LOW_0_QUADRANT_0
    4'b 0011, // index[ 47] OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_0
    4'b 1111, // index[ 48] OCCAMY_SOC_RO_START_ADDR_LOW_1_QUADRANT_0
    4'b 0011, // index[ 49] OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_0
    4'b 1111, // index[ 50] OCCAMY_SOC_RO_END_ADDR_LOW_1_QUADRANT_0
    4'b 0011, // index[ 51] OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_0
    4'b 1111, // index[ 52] OCCAMY_SOC_RO_START_ADDR_LOW_0_QUADRANT_1
    4'b 0011, // index[ 53] OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_1
    4'b 1111, // index[ 54] OCCAMY_SOC_RO_END_ADDR_LOW_0_QUADRANT_1
    4'b 0011, // index[ 55] OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_1
    4'b 1111, // index[ 56] OCCAMY_SOC_RO_START_ADDR_LOW_1_QUADRANT_1
    4'b 0011, // index[ 57] OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_1
    4'b 1111, // index[ 58] OCCAMY_SOC_RO_END_ADDR_LOW_1_QUADRANT_1
    4'b 0011, // index[ 59] OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_1
    4'b 1111, // index[ 60] OCCAMY_SOC_RO_START_ADDR_LOW_0_QUADRANT_2
    4'b 0011, // index[ 61] OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_2
    4'b 1111, // index[ 62] OCCAMY_SOC_RO_END_ADDR_LOW_0_QUADRANT_2
    4'b 0011, // index[ 63] OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_2
    4'b 1111, // index[ 64] OCCAMY_SOC_RO_START_ADDR_LOW_1_QUADRANT_2
    4'b 0011, // index[ 65] OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_2
    4'b 1111, // index[ 66] OCCAMY_SOC_RO_END_ADDR_LOW_1_QUADRANT_2
    4'b 0011, // index[ 67] OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_2
    4'b 1111, // index[ 68] OCCAMY_SOC_RO_START_ADDR_LOW_0_QUADRANT_3
    4'b 0011, // index[ 69] OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_3
    4'b 1111, // index[ 70] OCCAMY_SOC_RO_END_ADDR_LOW_0_QUADRANT_3
    4'b 0011, // index[ 71] OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_3
    4'b 1111, // index[ 72] OCCAMY_SOC_RO_START_ADDR_LOW_1_QUADRANT_3
    4'b 0011, // index[ 73] OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_3
    4'b 1111, // index[ 74] OCCAMY_SOC_RO_END_ADDR_LOW_1_QUADRANT_3
    4'b 0011, // index[ 75] OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_3
    4'b 1111, // index[ 76] OCCAMY_SOC_RO_START_ADDR_LOW_0_QUADRANT_4
    4'b 0011, // index[ 77] OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_4
    4'b 1111, // index[ 78] OCCAMY_SOC_RO_END_ADDR_LOW_0_QUADRANT_4
    4'b 0011, // index[ 79] OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_4
    4'b 1111, // index[ 80] OCCAMY_SOC_RO_START_ADDR_LOW_1_QUADRANT_4
    4'b 0011, // index[ 81] OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_4
    4'b 1111, // index[ 82] OCCAMY_SOC_RO_END_ADDR_LOW_1_QUADRANT_4
    4'b 0011, // index[ 83] OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_4
    4'b 1111, // index[ 84] OCCAMY_SOC_RO_START_ADDR_LOW_0_QUADRANT_5
    4'b 0011, // index[ 85] OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_5
    4'b 1111, // index[ 86] OCCAMY_SOC_RO_END_ADDR_LOW_0_QUADRANT_5
    4'b 0011, // index[ 87] OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_5
    4'b 1111, // index[ 88] OCCAMY_SOC_RO_START_ADDR_LOW_1_QUADRANT_5
    4'b 0011, // index[ 89] OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_5
    4'b 1111, // index[ 90] OCCAMY_SOC_RO_END_ADDR_LOW_1_QUADRANT_5
    4'b 0011, // index[ 91] OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_5
    4'b 1111, // index[ 92] OCCAMY_SOC_RO_START_ADDR_LOW_0_QUADRANT_6
    4'b 0011, // index[ 93] OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_6
    4'b 1111, // index[ 94] OCCAMY_SOC_RO_END_ADDR_LOW_0_QUADRANT_6
    4'b 0011, // index[ 95] OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_6
    4'b 1111, // index[ 96] OCCAMY_SOC_RO_START_ADDR_LOW_1_QUADRANT_6
    4'b 0011, // index[ 97] OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_6
    4'b 1111, // index[ 98] OCCAMY_SOC_RO_END_ADDR_LOW_1_QUADRANT_6
    4'b 0011, // index[ 99] OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_6
    4'b 1111, // index[100] OCCAMY_SOC_RO_START_ADDR_LOW_0_QUADRANT_7
    4'b 0011, // index[101] OCCAMY_SOC_RO_START_ADDR_HIGH_0_QUADRANT_7
    4'b 1111, // index[102] OCCAMY_SOC_RO_END_ADDR_LOW_0_QUADRANT_7
    4'b 0011, // index[103] OCCAMY_SOC_RO_END_ADDR_HIGH_0_QUADRANT_7
    4'b 1111, // index[104] OCCAMY_SOC_RO_START_ADDR_LOW_1_QUADRANT_7
    4'b 0011, // index[105] OCCAMY_SOC_RO_START_ADDR_HIGH_1_QUADRANT_7
    4'b 1111, // index[106] OCCAMY_SOC_RO_END_ADDR_LOW_1_QUADRANT_7
    4'b 0011  // index[107] OCCAMY_SOC_RO_END_ADDR_HIGH_1_QUADRANT_7
  };
endpackage

