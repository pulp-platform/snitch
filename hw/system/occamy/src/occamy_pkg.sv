// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Fabian Schuiki <fschuiki@iis.ee.ethz.ch>
// Florian Zaruba <zarubaf@iis.ee.ethz.ch>
//
// AUTOMATICALLY GENERATED by occamygen.py; edit the script instead.
// verilog_lint: waive-start line-length

`include "axi/typedef.svh"
`include "register_interface/typedef.svh"
`include "apb/typedef.svh"

package occamy_pkg;
  localparam int unsigned MaxTransaction = 16;

  // Re-exports
  localparam int unsigned AddrWidth = occamy_cluster_pkg::AddrWidth;
  localparam int unsigned UserWidth = occamy_cluster_pkg::UserWidth;

  localparam int unsigned NrClustersS1Quadrant = 4;
  localparam int unsigned NrCoresCluster = occamy_cluster_pkg::NrCores;
  localparam int unsigned NrCoresS1Quadrant = NrClustersS1Quadrant * NrCoresCluster;

  typedef struct packed {
    logic [3:0] timer;
    logic [31:0] gpio;
    logic uart;
    logic spim_error;
    logic spim_spi_event;
    logic i2c_fmt_watermark;
    logic i2c_rx_watermark;
    logic i2c_fmt_overflow;
    logic i2c_rx_overflow;
    logic i2c_nak;
    logic i2c_scl_interference;
    logic i2c_sda_interference;
    logic i2c_stretch_timeout;
    logic i2c_sda_unstable;
    logic i2c_trans_complete;
    logic i2c_tx_empty;
    logic i2c_tx_nonempty;
    logic i2c_tx_overflow;
    logic i2c_acq_overflow;
    logic i2c_ack_stop;
    logic i2c_host_timeout;
    logic ecc_uncorrectable;
    logic ecc_correctable;
    // 4 programmable, 8 HBM (1x per channel)
    logic [11:0] ext_irq;
    logic zero;
  } occamy_interrupt_t;

  localparam logic [15:0] PartNum = 2;
  localparam logic [31:0] IDCode = (dm::DbgVersion013 << 28) | (PartNum << 12) | 32'h1;

  typedef logic [5:0] tile_id_t;

  typedef logic [AddrWidth-1:0] addr_t;
  typedef logic [UserWidth-1:0] user_t;

  typedef struct packed {
    logic [31:0] idx;
    logic [47:0] start_addr;
    logic [47:0] end_addr;
  } xbar_rule_48_t;


  typedef xbar_rule_48_t xbar_rule_t;

  /// We reserve hartid `0` for CVA6.
  localparam logic [9:0] HartIdOffset = 1;
  /// The base offset for each cluster.
  localparam addr_t ClusterBaseOffset = 'h1000_0000;
  /// The address space set aside for each slave.
  localparam addr_t ClusterAddressSpace = 'h4_0000;  // 256 kiB
  /// The address space of a single S1 quadrant.
  localparam addr_t S1QuadrantAddressSpace = ClusterAddressSpace * NrClustersS1Quadrant;

  // AXI-Lite bus with 48 bit address and 64 bit data.
  `AXI_LITE_TYPEDEF_ALL(axi_lite_a48_d64, logic [47:0], logic [63:0], logic [7:0])

  /// Inputs of the `soc_axi_lite_periph_xbar` crossbar.
  typedef enum int {
    SOC_AXI_LITE_PERIPH_XBAR_IN_SOC,
    SOC_AXI_LITE_PERIPH_XBAR_IN_DEBUG,
    SOC_AXI_LITE_PERIPH_XBAR_NUM_INPUTS
  } soc_axi_lite_periph_xbar_inputs_e;

  /// Outputs of the `soc_axi_lite_periph_xbar` crossbar.
  typedef enum int {
    SOC_AXI_LITE_PERIPH_XBAR_OUT_DEBUG,
    SOC_AXI_LITE_PERIPH_XBAR_OUT_SOC,
    SOC_AXI_LITE_PERIPH_XBAR_NUM_OUTPUTS
  } soc_axi_lite_periph_xbar_outputs_e;

  /// Configuration of the `soc_axi_lite_periph_xbar` crossbar.
  localparam axi_pkg::xbar_cfg_t SocAxiLitePeriphXbarCfg = '{
  NoSlvPorts:         SOC_AXI_LITE_PERIPH_XBAR_NUM_INPUTS,
  NoMstPorts:         SOC_AXI_LITE_PERIPH_XBAR_NUM_OUTPUTS,
  MaxSlvTrans:        4,
  MaxMstTrans:        4,
  FallThrough:        0,
  LatencyMode:        axi_pkg::CUT_ALL_PORTS,
  AxiIdWidthSlvPorts: 0,
  AxiIdUsedSlvPorts:  0,
  AxiAddrWidth:       48,
  AxiDataWidth:       64,
  NoAddrRules:        2
};

  /// Address map of the `soc_axi_lite_periph_xbar` crossbar.
  localparam xbar_rule_48_t [1:0] SocAxiLitePeriphXbarAddrmap = '{
  '{ idx: 0, start_addr: 48'h00000000, end_addr: 48'h00001000 },
  '{ idx: 1, start_addr: 48'h01000000, end_addr: 48'h20000000000 }
};

  // AXI plugs of the `soc_axi_lite_periph_xbar` crossbar.

  typedef axi_lite_a48_d64_req_t soc_axi_lite_periph_xbar_in_req_t;
  typedef axi_lite_a48_d64_req_t soc_axi_lite_periph_xbar_out_req_t;
  typedef axi_lite_a48_d64_rsp_t soc_axi_lite_periph_xbar_in_rsp_t;
  typedef axi_lite_a48_d64_rsp_t soc_axi_lite_periph_xbar_out_rsp_t;
  typedef axi_lite_a48_d64_aw_chan_t soc_axi_lite_periph_xbar_in_aw_chan_t;
  typedef axi_lite_a48_d64_aw_chan_t soc_axi_lite_periph_xbar_out_aw_chan_t;
  typedef axi_lite_a48_d64_w_chan_t soc_axi_lite_periph_xbar_in_w_chan_t;
  typedef axi_lite_a48_d64_w_chan_t soc_axi_lite_periph_xbar_out_w_chan_t;
  typedef axi_lite_a48_d64_b_chan_t soc_axi_lite_periph_xbar_in_b_chan_t;
  typedef axi_lite_a48_d64_b_chan_t soc_axi_lite_periph_xbar_out_b_chan_t;
  typedef axi_lite_a48_d64_ar_chan_t soc_axi_lite_periph_xbar_in_ar_chan_t;
  typedef axi_lite_a48_d64_ar_chan_t soc_axi_lite_periph_xbar_out_ar_chan_t;
  typedef axi_lite_a48_d64_r_chan_t soc_axi_lite_periph_xbar_in_r_chan_t;
  typedef axi_lite_a48_d64_r_chan_t soc_axi_lite_periph_xbar_out_r_chan_t;

  // Register bus with 48 bit address and 32 bit data.
  `REG_BUS_TYPEDEF_ALL(reg_a48_d32, logic [47:0], logic [31:0], logic [3:0])

  /// Inputs of the `soc_regbus_periph_xbar` crossbar.
  typedef enum int {
    SOC_REGBUS_PERIPH_XBAR_IN_SOC,
    SOC_REGBUS_PERIPH_XBAR_NUM_INPUTS
  } soc_regbus_periph_xbar_inputs_e;

  /// Outputs of the `soc_regbus_periph_xbar` crossbar.
  typedef enum int {
    SOC_REGBUS_PERIPH_XBAR_OUT_CLINT,
    SOC_REGBUS_PERIPH_XBAR_OUT_SOC_CTRL,
    SOC_REGBUS_PERIPH_XBAR_OUT_CHIP_CTRL,
    SOC_REGBUS_PERIPH_XBAR_OUT_CLK_MGR,
    SOC_REGBUS_PERIPH_XBAR_OUT_BOOTROM,
    SOC_REGBUS_PERIPH_XBAR_OUT_PLIC,
    SOC_REGBUS_PERIPH_XBAR_OUT_UART,
    SOC_REGBUS_PERIPH_XBAR_OUT_GPIO,
    SOC_REGBUS_PERIPH_XBAR_OUT_I2C,
    SOC_REGBUS_PERIPH_XBAR_OUT_SPIM,
    SOC_REGBUS_PERIPH_XBAR_OUT_TIMER,
    SOC_REGBUS_PERIPH_XBAR_OUT_PCIE_CFG,
    SOC_REGBUS_PERIPH_XBAR_OUT_HBI_CFG,
    SOC_REGBUS_PERIPH_XBAR_OUT_HBI_CTL,
    SOC_REGBUS_PERIPH_XBAR_OUT_HBM_CFG,
    SOC_REGBUS_PERIPH_XBAR_OUT_HBM_PHY_CFG,
    SOC_REGBUS_PERIPH_XBAR_OUT_HBM_SEQ,
    SOC_REGBUS_PERIPH_XBAR_NUM_OUTPUTS
  } soc_regbus_periph_xbar_outputs_e;

  /// Address map of the `soc_regbus_periph_xbar` crossbar.
  localparam xbar_rule_48_t [16:0] SocRegbusPeriphXbarAddrmap = '{
  '{ idx: 0, start_addr: 48'h04000000, end_addr: 48'h04100000 },
  '{ idx: 1, start_addr: 48'h02000000, end_addr: 48'h02001000 },
  '{ idx: 2, start_addr: 48'h02005000, end_addr: 48'h02006000 },
  '{ idx: 3, start_addr: 48'h02001000, end_addr: 48'h02002000 },
  '{ idx: 4, start_addr: 48'h01000000, end_addr: 48'h01020000 },
  '{ idx: 5, start_addr: 48'h0c000000, end_addr: 48'h10000000 },
  '{ idx: 6, start_addr: 48'h02002000, end_addr: 48'h02003000 },
  '{ idx: 7, start_addr: 48'h02003000, end_addr: 48'h02004000 },
  '{ idx: 8, start_addr: 48'h02004000, end_addr: 48'h02005000 },
  '{ idx: 9, start_addr: 48'h03000000, end_addr: 48'h03020000 },
  '{ idx: 10, start_addr: 48'h02006000, end_addr: 48'h02007000 },
  '{ idx: 11, start_addr: 48'h05000000, end_addr: 48'h05020000 },
  '{ idx: 12, start_addr: 48'h06000000, end_addr: 48'h06010000 },
  '{ idx: 13, start_addr: 48'h07000000, end_addr: 48'h07010000 },
  '{ idx: 14, start_addr: 48'h08000000, end_addr: 48'h08400000 },
  '{ idx: 15, start_addr: 48'h09000000, end_addr: 48'h09100000 },
  '{ idx: 16, start_addr: 48'h0a000000, end_addr: 48'h0a010000 }
};

  /// Inputs of the `soc_wide_xbar` crossbar.
  typedef enum int {
    SOC_WIDE_XBAR_IN_S1_QUADRANT_0,
    SOC_WIDE_XBAR_IN_S1_QUADRANT_1,
    SOC_WIDE_XBAR_IN_S1_QUADRANT_2,
    SOC_WIDE_XBAR_IN_S1_QUADRANT_3,
    SOC_WIDE_XBAR_IN_S1_QUADRANT_4,
    SOC_WIDE_XBAR_IN_S1_QUADRANT_5,
    SOC_WIDE_XBAR_IN_S1_QUADRANT_6,
    SOC_WIDE_XBAR_IN_S1_QUADRANT_7,
    SOC_WIDE_XBAR_IN_HBI_0,
    SOC_WIDE_XBAR_IN_HBI_1,
    SOC_WIDE_XBAR_IN_HBI_2,
    SOC_WIDE_XBAR_IN_HBI_3,
    SOC_WIDE_XBAR_IN_HBI_4,
    SOC_WIDE_XBAR_IN_HBI_5,
    SOC_WIDE_XBAR_IN_HBI_6,
    SOC_WIDE_XBAR_IN_HBI_7,
    SOC_WIDE_XBAR_IN_HBI_8,
    SOC_WIDE_XBAR_IN_SOC_NARROW,
    SOC_WIDE_XBAR_IN_PCIE,
    SOC_WIDE_XBAR_NUM_INPUTS
  } soc_wide_xbar_inputs_e;

  /// Outputs of the `soc_wide_xbar` crossbar.
  typedef enum int {
    SOC_WIDE_XBAR_OUT_S1_QUADRANT_0,
    SOC_WIDE_XBAR_OUT_S1_QUADRANT_1,
    SOC_WIDE_XBAR_OUT_S1_QUADRANT_2,
    SOC_WIDE_XBAR_OUT_S1_QUADRANT_3,
    SOC_WIDE_XBAR_OUT_S1_QUADRANT_4,
    SOC_WIDE_XBAR_OUT_S1_QUADRANT_5,
    SOC_WIDE_XBAR_OUT_S1_QUADRANT_6,
    SOC_WIDE_XBAR_OUT_S1_QUADRANT_7,
    SOC_WIDE_XBAR_OUT_HBM_0,
    SOC_WIDE_XBAR_OUT_HBM_1,
    SOC_WIDE_XBAR_OUT_HBM_2,
    SOC_WIDE_XBAR_OUT_HBM_3,
    SOC_WIDE_XBAR_OUT_HBM_4,
    SOC_WIDE_XBAR_OUT_HBM_5,
    SOC_WIDE_XBAR_OUT_HBM_6,
    SOC_WIDE_XBAR_OUT_HBM_7,
    SOC_WIDE_XBAR_OUT_SOC_NARROW,
    SOC_WIDE_XBAR_OUT_PCIE,
    SOC_WIDE_XBAR_NUM_OUTPUTS
  } soc_wide_xbar_outputs_e;

  /// Configuration of the `soc_wide_xbar` crossbar.
  localparam axi_pkg::xbar_cfg_t SocWideXbarCfg = '{
  NoSlvPorts:         SOC_WIDE_XBAR_NUM_INPUTS,
  NoMstPorts:         SOC_WIDE_XBAR_NUM_OUTPUTS,
  MaxSlvTrans:        4,
  MaxMstTrans:        4,
  FallThrough:        0,
  LatencyMode:        axi_pkg::CUT_ALL_PORTS,
  AxiIdWidthSlvPorts: 4,
  AxiIdUsedSlvPorts:  4,
  AxiAddrWidth:       48,
  AxiDataWidth:       512,
  NoAddrRules:        21
};

  // AXI bus with 48 bit address, 512 bit data, 4 bit IDs, and 0 bit user data.
  `AXI_TYPEDEF_ALL(axi_a48_d512_i4_u0, logic [47:0], logic [3:0], logic [511:0], logic [63:0],
                   logic [0:0])

  // AXI bus with 48 bit address, 512 bit data, 9 bit IDs, and 0 bit user data.
  `AXI_TYPEDEF_ALL(axi_a48_d512_i9_u0, logic [47:0], logic [8:0], logic [511:0], logic [63:0],
                   logic [0:0])

  typedef axi_a48_d512_i4_u0_req_t soc_wide_xbar_in_req_t;
  typedef axi_a48_d512_i9_u0_req_t soc_wide_xbar_out_req_t;
  typedef axi_a48_d512_i4_u0_resp_t soc_wide_xbar_in_resp_t;
  typedef axi_a48_d512_i9_u0_resp_t soc_wide_xbar_out_resp_t;
  typedef axi_a48_d512_i4_u0_aw_chan_t soc_wide_xbar_in_aw_chan_t;
  typedef axi_a48_d512_i9_u0_aw_chan_t soc_wide_xbar_out_aw_chan_t;
  typedef axi_a48_d512_i4_u0_w_chan_t soc_wide_xbar_in_w_chan_t;
  typedef axi_a48_d512_i9_u0_w_chan_t soc_wide_xbar_out_w_chan_t;
  typedef axi_a48_d512_i4_u0_b_chan_t soc_wide_xbar_in_b_chan_t;
  typedef axi_a48_d512_i9_u0_b_chan_t soc_wide_xbar_out_b_chan_t;
  typedef axi_a48_d512_i4_u0_ar_chan_t soc_wide_xbar_in_ar_chan_t;
  typedef axi_a48_d512_i9_u0_ar_chan_t soc_wide_xbar_out_ar_chan_t;
  typedef axi_a48_d512_i4_u0_r_chan_t soc_wide_xbar_in_r_chan_t;
  typedef axi_a48_d512_i9_u0_r_chan_t soc_wide_xbar_out_r_chan_t;

  // verilog_lint: waive parameter-name-style
  localparam int SOC_WIDE_XBAR_IW_IN = 4;
  // verilog_lint: waive parameter-name-style
  localparam int SOC_WIDE_XBAR_IW_OUT = 9;

  /// Inputs of the `soc_narrow_xbar` crossbar.
  typedef enum int {
    SOC_NARROW_XBAR_IN_S1_QUADRANT_0,
    SOC_NARROW_XBAR_IN_S1_QUADRANT_1,
    SOC_NARROW_XBAR_IN_S1_QUADRANT_2,
    SOC_NARROW_XBAR_IN_S1_QUADRANT_3,
    SOC_NARROW_XBAR_IN_S1_QUADRANT_4,
    SOC_NARROW_XBAR_IN_S1_QUADRANT_5,
    SOC_NARROW_XBAR_IN_S1_QUADRANT_6,
    SOC_NARROW_XBAR_IN_S1_QUADRANT_7,
    SOC_NARROW_XBAR_IN_CVA6,
    SOC_NARROW_XBAR_IN_SOC_WIDE,
    SOC_NARROW_XBAR_IN_PERIPH,
    SOC_NARROW_XBAR_NUM_INPUTS
  } soc_narrow_xbar_inputs_e;

  /// Outputs of the `soc_narrow_xbar` crossbar.
  typedef enum int {
    SOC_NARROW_XBAR_OUT_S1_QUADRANT_0,
    SOC_NARROW_XBAR_OUT_S1_QUADRANT_1,
    SOC_NARROW_XBAR_OUT_S1_QUADRANT_2,
    SOC_NARROW_XBAR_OUT_S1_QUADRANT_3,
    SOC_NARROW_XBAR_OUT_S1_QUADRANT_4,
    SOC_NARROW_XBAR_OUT_S1_QUADRANT_5,
    SOC_NARROW_XBAR_OUT_S1_QUADRANT_6,
    SOC_NARROW_XBAR_OUT_S1_QUADRANT_7,
    SOC_NARROW_XBAR_OUT_PERIPH,
    SOC_NARROW_XBAR_OUT_SPM,
    SOC_NARROW_XBAR_OUT_SOC_WIDE,
    SOC_NARROW_XBAR_OUT_REGBUS_PERIPH,
    SOC_NARROW_XBAR_OUT_HBI,
    SOC_NARROW_XBAR_NUM_OUTPUTS
  } soc_narrow_xbar_outputs_e;

  /// Configuration of the `soc_narrow_xbar` crossbar.
  localparam axi_pkg::xbar_cfg_t SocNarrowXbarCfg = '{
  NoSlvPorts:         SOC_NARROW_XBAR_NUM_INPUTS,
  NoMstPorts:         SOC_NARROW_XBAR_NUM_OUTPUTS,
  MaxSlvTrans:        4,
  MaxMstTrans:        4,
  FallThrough:        0,
  LatencyMode:        axi_pkg::CUT_ALL_PORTS,
  AxiIdWidthSlvPorts: 4,
  AxiIdUsedSlvPorts:  4,
  AxiAddrWidth:       48,
  AxiDataWidth:       64,
  NoAddrRules:        13
};

  // AXI bus with 48 bit address, 64 bit data, 4 bit IDs, and 0 bit user data.
  `AXI_TYPEDEF_ALL(axi_a48_d64_i4_u0, logic [47:0], logic [3:0], logic [63:0], logic [7:0],
                   logic [0:0])

  // AXI bus with 48 bit address, 64 bit data, 8 bit IDs, and 0 bit user data.
  `AXI_TYPEDEF_ALL(axi_a48_d64_i8_u0, logic [47:0], logic [7:0], logic [63:0], logic [7:0],
                   logic [0:0])

  typedef axi_a48_d64_i4_u0_req_t soc_narrow_xbar_in_req_t;
  typedef axi_a48_d64_i8_u0_req_t soc_narrow_xbar_out_req_t;
  typedef axi_a48_d64_i4_u0_resp_t soc_narrow_xbar_in_resp_t;
  typedef axi_a48_d64_i8_u0_resp_t soc_narrow_xbar_out_resp_t;
  typedef axi_a48_d64_i4_u0_aw_chan_t soc_narrow_xbar_in_aw_chan_t;
  typedef axi_a48_d64_i8_u0_aw_chan_t soc_narrow_xbar_out_aw_chan_t;
  typedef axi_a48_d64_i4_u0_w_chan_t soc_narrow_xbar_in_w_chan_t;
  typedef axi_a48_d64_i8_u0_w_chan_t soc_narrow_xbar_out_w_chan_t;
  typedef axi_a48_d64_i4_u0_b_chan_t soc_narrow_xbar_in_b_chan_t;
  typedef axi_a48_d64_i8_u0_b_chan_t soc_narrow_xbar_out_b_chan_t;
  typedef axi_a48_d64_i4_u0_ar_chan_t soc_narrow_xbar_in_ar_chan_t;
  typedef axi_a48_d64_i8_u0_ar_chan_t soc_narrow_xbar_out_ar_chan_t;
  typedef axi_a48_d64_i4_u0_r_chan_t soc_narrow_xbar_in_r_chan_t;
  typedef axi_a48_d64_i8_u0_r_chan_t soc_narrow_xbar_out_r_chan_t;

  // verilog_lint: waive parameter-name-style
  localparam int SOC_NARROW_XBAR_IW_IN = 4;
  // verilog_lint: waive parameter-name-style
  localparam int SOC_NARROW_XBAR_IW_OUT = 8;

  /// Inputs of the `wide_xbar_quadrant_s1` crossbar.
  typedef enum int {
    WIDE_XBAR_QUADRANT_S1_IN_TOP,
    WIDE_XBAR_QUADRANT_S1_IN_CLUSTER_0,
    WIDE_XBAR_QUADRANT_S1_IN_CLUSTER_1,
    WIDE_XBAR_QUADRANT_S1_IN_CLUSTER_2,
    WIDE_XBAR_QUADRANT_S1_IN_CLUSTER_3,
    WIDE_XBAR_QUADRANT_S1_NUM_INPUTS
  } wide_xbar_quadrant_s1_inputs_e;

  /// Outputs of the `wide_xbar_quadrant_s1` crossbar.
  typedef enum int {
    WIDE_XBAR_QUADRANT_S1_OUT_TOP,
    WIDE_XBAR_QUADRANT_S1_OUT_HBI,
    WIDE_XBAR_QUADRANT_S1_OUT_CLUSTER_0,
    WIDE_XBAR_QUADRANT_S1_OUT_CLUSTER_1,
    WIDE_XBAR_QUADRANT_S1_OUT_CLUSTER_2,
    WIDE_XBAR_QUADRANT_S1_OUT_CLUSTER_3,
    WIDE_XBAR_QUADRANT_S1_NUM_OUTPUTS
  } wide_xbar_quadrant_s1_outputs_e;

  /// Configuration of the `wide_xbar_quadrant_s1` crossbar.
  localparam axi_pkg::xbar_cfg_t WideXbarQuadrantS1Cfg = '{
  NoSlvPorts:         WIDE_XBAR_QUADRANT_S1_NUM_INPUTS,
  NoMstPorts:         WIDE_XBAR_QUADRANT_S1_NUM_OUTPUTS,
  MaxSlvTrans:        4,
  MaxMstTrans:        4,
  FallThrough:        0,
  LatencyMode:        axi_pkg::CUT_ALL_PORTS,
  AxiIdWidthSlvPorts: 4,
  AxiIdUsedSlvPorts:  4,
  AxiAddrWidth:       48,
  AxiDataWidth:       512,
  NoAddrRules:        5
};

  // AXI bus with 48 bit address, 512 bit data, 7 bit IDs, and 0 bit user data.
  `AXI_TYPEDEF_ALL(axi_a48_d512_i7_u0, logic [47:0], logic [6:0], logic [511:0], logic [63:0],
                   logic [0:0])

  typedef axi_a48_d512_i4_u0_req_t wide_xbar_quadrant_s1_in_req_t;
  typedef axi_a48_d512_i7_u0_req_t wide_xbar_quadrant_s1_out_req_t;
  typedef axi_a48_d512_i4_u0_resp_t wide_xbar_quadrant_s1_in_resp_t;
  typedef axi_a48_d512_i7_u0_resp_t wide_xbar_quadrant_s1_out_resp_t;
  typedef axi_a48_d512_i4_u0_aw_chan_t wide_xbar_quadrant_s1_in_aw_chan_t;
  typedef axi_a48_d512_i7_u0_aw_chan_t wide_xbar_quadrant_s1_out_aw_chan_t;
  typedef axi_a48_d512_i4_u0_w_chan_t wide_xbar_quadrant_s1_in_w_chan_t;
  typedef axi_a48_d512_i7_u0_w_chan_t wide_xbar_quadrant_s1_out_w_chan_t;
  typedef axi_a48_d512_i4_u0_b_chan_t wide_xbar_quadrant_s1_in_b_chan_t;
  typedef axi_a48_d512_i7_u0_b_chan_t wide_xbar_quadrant_s1_out_b_chan_t;
  typedef axi_a48_d512_i4_u0_ar_chan_t wide_xbar_quadrant_s1_in_ar_chan_t;
  typedef axi_a48_d512_i7_u0_ar_chan_t wide_xbar_quadrant_s1_out_ar_chan_t;
  typedef axi_a48_d512_i4_u0_r_chan_t wide_xbar_quadrant_s1_in_r_chan_t;
  typedef axi_a48_d512_i7_u0_r_chan_t wide_xbar_quadrant_s1_out_r_chan_t;

  // verilog_lint: waive parameter-name-style
  localparam int WIDE_XBAR_QUADRANT_S1_IW_IN = 4;
  // verilog_lint: waive parameter-name-style
  localparam int WIDE_XBAR_QUADRANT_S1_IW_OUT = 7;

  /// Inputs of the `narrow_xbar_quadrant_s1` crossbar.
  typedef enum int {
    NARROW_XBAR_QUADRANT_S1_IN_TOP,
    NARROW_XBAR_QUADRANT_S1_IN_CLUSTER_0,
    NARROW_XBAR_QUADRANT_S1_IN_CLUSTER_1,
    NARROW_XBAR_QUADRANT_S1_IN_CLUSTER_2,
    NARROW_XBAR_QUADRANT_S1_IN_CLUSTER_3,
    NARROW_XBAR_QUADRANT_S1_NUM_INPUTS
  } narrow_xbar_quadrant_s1_inputs_e;

  /// Outputs of the `narrow_xbar_quadrant_s1` crossbar.
  typedef enum int {
    NARROW_XBAR_QUADRANT_S1_OUT_TOP,
    NARROW_XBAR_QUADRANT_S1_OUT_CLUSTER_0,
    NARROW_XBAR_QUADRANT_S1_OUT_CLUSTER_1,
    NARROW_XBAR_QUADRANT_S1_OUT_CLUSTER_2,
    NARROW_XBAR_QUADRANT_S1_OUT_CLUSTER_3,
    NARROW_XBAR_QUADRANT_S1_NUM_OUTPUTS
  } narrow_xbar_quadrant_s1_outputs_e;

  /// Configuration of the `narrow_xbar_quadrant_s1` crossbar.
  localparam axi_pkg::xbar_cfg_t NarrowXbarQuadrantS1Cfg = '{
  NoSlvPorts:         NARROW_XBAR_QUADRANT_S1_NUM_INPUTS,
  NoMstPorts:         NARROW_XBAR_QUADRANT_S1_NUM_OUTPUTS,
  MaxSlvTrans:        4,
  MaxMstTrans:        4,
  FallThrough:        0,
  LatencyMode:        axi_pkg::CUT_ALL_PORTS,
  AxiIdWidthSlvPorts: 4,
  AxiIdUsedSlvPorts:  4,
  AxiAddrWidth:       48,
  AxiDataWidth:       64,
  NoAddrRules:        4
};

  // AXI bus with 48 bit address, 64 bit data, 7 bit IDs, and 0 bit user data.
  `AXI_TYPEDEF_ALL(axi_a48_d64_i7_u0, logic [47:0], logic [6:0], logic [63:0], logic [7:0],
                   logic [0:0])

  typedef axi_a48_d64_i4_u0_req_t narrow_xbar_quadrant_s1_in_req_t;
  typedef axi_a48_d64_i7_u0_req_t narrow_xbar_quadrant_s1_out_req_t;
  typedef axi_a48_d64_i4_u0_resp_t narrow_xbar_quadrant_s1_in_resp_t;
  typedef axi_a48_d64_i7_u0_resp_t narrow_xbar_quadrant_s1_out_resp_t;
  typedef axi_a48_d64_i4_u0_aw_chan_t narrow_xbar_quadrant_s1_in_aw_chan_t;
  typedef axi_a48_d64_i7_u0_aw_chan_t narrow_xbar_quadrant_s1_out_aw_chan_t;
  typedef axi_a48_d64_i4_u0_w_chan_t narrow_xbar_quadrant_s1_in_w_chan_t;
  typedef axi_a48_d64_i7_u0_w_chan_t narrow_xbar_quadrant_s1_out_w_chan_t;
  typedef axi_a48_d64_i4_u0_b_chan_t narrow_xbar_quadrant_s1_in_b_chan_t;
  typedef axi_a48_d64_i7_u0_b_chan_t narrow_xbar_quadrant_s1_out_b_chan_t;
  typedef axi_a48_d64_i4_u0_ar_chan_t narrow_xbar_quadrant_s1_in_ar_chan_t;
  typedef axi_a48_d64_i7_u0_ar_chan_t narrow_xbar_quadrant_s1_out_ar_chan_t;
  typedef axi_a48_d64_i4_u0_r_chan_t narrow_xbar_quadrant_s1_in_r_chan_t;
  typedef axi_a48_d64_i7_u0_r_chan_t narrow_xbar_quadrant_s1_out_r_chan_t;

  // verilog_lint: waive parameter-name-style
  localparam int NARROW_XBAR_QUADRANT_S1_IW_IN = 4;
  // verilog_lint: waive parameter-name-style
  localparam int NARROW_XBAR_QUADRANT_S1_IW_OUT = 7;

  // APB bus with 48 bit address, 32 bit data.
  `APB_TYPEDEF_REQ_T(apb_a48_d32_req_t, logic [47:0], logic [31:0], logic [3:0])
  `APB_TYPEDEF_RESP_T(apb_a48_d32_rsp_t, logic [31:0])

  // AXI bus with 48 bit address, 64 bit data, 1 bit IDs, and 0 bit user data.
  `AXI_TYPEDEF_ALL(axi_a48_d64_i1_u0, logic [47:0], logic [0:0], logic [63:0], logic [7:0],
                   logic [0:0])

  // AXI bus with 48 bit address, 32 bit data, 8 bit IDs, and 0 bit user data.
  `AXI_TYPEDEF_ALL(axi_a48_d32_i8_u0, logic [47:0], logic [7:0], logic [31:0], logic [3:0],
                   logic [0:0])

  // AXI-Lite bus with 48 bit address and 32 bit data.
  `AXI_LITE_TYPEDEF_ALL(axi_lite_a48_d32, logic [47:0], logic [31:0], logic [3:0])

  // Register bus with 48 bit address and 64 bit data.
  `REG_BUS_TYPEDEF_ALL(reg_a48_d64, logic [47:0], logic [63:0], logic [7:0])

  // AXI bus with 48 bit address, 512 bit data, 3 bit IDs, and 0 bit user data.
  `AXI_TYPEDEF_ALL(axi_a48_d512_i3_u0, logic [47:0], logic [2:0], logic [511:0], logic [63:0],
                   logic [0:0])

  // AXI bus with 48 bit address, 64 bit data, 2 bit IDs, and 0 bit user data.
  `AXI_TYPEDEF_ALL(axi_a48_d64_i2_u0, logic [47:0], logic [1:0], logic [63:0], logic [7:0],
                   logic [0:0])

  // AXI bus with 48 bit address, 512 bit data, 2 bit IDs, and 0 bit user data.
  `AXI_TYPEDEF_ALL(axi_a48_d512_i2_u0, logic [47:0], logic [1:0], logic [511:0], logic [63:0],
                   logic [0:0])


endpackage
// verilog_lint: waive-off line-length
