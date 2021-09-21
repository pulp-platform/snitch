// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Register Package auto-generated by `reggen` containing data structure

package snitch_cluster_peripheral_reg_pkg;

  // Param list
  parameter int NumPerfCounters = 2;

  // Address widths within the block
  parameter int BlockAw = 7;

  ////////////////////////////
  // Typedefs for registers //
  ////////////////////////////

  typedef struct packed {
    struct packed {
      logic        q;
    } cycle;
    struct packed {
      logic        q;
    } tcdm_accessed;
    struct packed {
      logic        q;
    } tcdm_congested;
    struct packed {
      logic        q;
    } issue_fpu;
    struct packed {
      logic        q;
    } issue_fpu_seq;
    struct packed {
      logic        q;
    } issue_core_to_fpu;
    struct packed {
      logic        q;
    } dma_aw_stall;
    struct packed {
      logic        q;
    } dma_ar_stall;
    struct packed {
      logic        q;
    } dma_r_stall;
    struct packed {
      logic        q;
    } dma_w_stall;
    struct packed {
      logic        q;
    } dma_buf_w_stall;
    struct packed {
      logic        q;
    } dma_buf_r_stall;
    struct packed {
      logic        q;
    } dma_aw_done;
    struct packed {
      logic        q;
    } dma_aw_bw;
    struct packed {
      logic        q;
    } dma_ar_done;
    struct packed {
      logic        q;
    } dma_ar_bw;
    struct packed {
      logic        q;
    } dma_r_done;
    struct packed {
      logic        q;
    } dma_r_bw;
    struct packed {
      logic        q;
    } dma_w_done;
    struct packed {
      logic        q;
    } dma_w_bw;
    struct packed {
      logic        q;
    } dma_b_done;
    struct packed {
      logic        q;
    } dma_busy;
    struct packed {
      logic        q;
    } icache_miss;
    struct packed {
      logic        q;
    } icache_hit;
    struct packed {
      logic        q;
    } icache_prefetch;
    struct packed {
      logic        q;
    } icache_double_hit;
    struct packed {
      logic        q;
    } icache_stall;
  } snitch_cluster_peripheral_reg2hw_perf_counter_enable_mreg_t;

  typedef struct packed {
    logic [9:0] q;
  } snitch_cluster_peripheral_reg2hw_hart_select_mreg_t;

  typedef struct packed {
    logic [47:0] q;
    logic        qe;
  } snitch_cluster_peripheral_reg2hw_perf_counter_mreg_t;

  typedef struct packed {
    logic [31:0] q;
    logic        qe;
  } snitch_cluster_peripheral_reg2hw_cl_clint_set_reg_t;

  typedef struct packed {
    logic [31:0] q;
    logic        qe;
  } snitch_cluster_peripheral_reg2hw_cl_clint_clear_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } snitch_cluster_peripheral_reg2hw_hw_barrier_reg_t;

  typedef struct packed {
    logic        q;
  } snitch_cluster_peripheral_reg2hw_icache_prefetch_enable_reg_t;

  typedef struct packed {
    logic [47:0] d;
  } snitch_cluster_peripheral_hw2reg_perf_counter_mreg_t;

  typedef struct packed {
    logic [31:0] d;
  } snitch_cluster_peripheral_hw2reg_hw_barrier_reg_t;

  // Register -> HW type
  typedef struct packed {
    snitch_cluster_peripheral_reg2hw_perf_counter_enable_mreg_t [1:0] perf_counter_enable; // [270:217]
    snitch_cluster_peripheral_reg2hw_hart_select_mreg_t [1:0] hart_select; // [216:197]
    snitch_cluster_peripheral_reg2hw_perf_counter_mreg_t [1:0] perf_counter; // [196:99]
    snitch_cluster_peripheral_reg2hw_cl_clint_set_reg_t cl_clint_set; // [98:66]
    snitch_cluster_peripheral_reg2hw_cl_clint_clear_reg_t cl_clint_clear; // [65:33]
    snitch_cluster_peripheral_reg2hw_hw_barrier_reg_t hw_barrier; // [32:1]
    snitch_cluster_peripheral_reg2hw_icache_prefetch_enable_reg_t icache_prefetch_enable; // [0:0]
  } snitch_cluster_peripheral_reg2hw_t;

  // HW -> register type
  typedef struct packed {
    snitch_cluster_peripheral_hw2reg_perf_counter_mreg_t [1:0] perf_counter; // [127:32]
    snitch_cluster_peripheral_hw2reg_hw_barrier_reg_t hw_barrier; // [31:0]
  } snitch_cluster_peripheral_hw2reg_t;

  // Register offsets
  parameter logic [BlockAw-1:0] SNITCH_CLUSTER_PERIPHERAL_PERF_COUNTER_ENABLE_0_OFFSET = 7'h 0;
  parameter logic [BlockAw-1:0] SNITCH_CLUSTER_PERIPHERAL_PERF_COUNTER_ENABLE_1_OFFSET = 7'h 8;
  parameter logic [BlockAw-1:0] SNITCH_CLUSTER_PERIPHERAL_HART_SELECT_0_OFFSET = 7'h 10;
  parameter logic [BlockAw-1:0] SNITCH_CLUSTER_PERIPHERAL_HART_SELECT_1_OFFSET = 7'h 18;
  parameter logic [BlockAw-1:0] SNITCH_CLUSTER_PERIPHERAL_PERF_COUNTER_0_OFFSET = 7'h 20;
  parameter logic [BlockAw-1:0] SNITCH_CLUSTER_PERIPHERAL_PERF_COUNTER_1_OFFSET = 7'h 28;
  parameter logic [BlockAw-1:0] SNITCH_CLUSTER_PERIPHERAL_CL_CLINT_SET_OFFSET = 7'h 30;
  parameter logic [BlockAw-1:0] SNITCH_CLUSTER_PERIPHERAL_CL_CLINT_CLEAR_OFFSET = 7'h 38;
  parameter logic [BlockAw-1:0] SNITCH_CLUSTER_PERIPHERAL_HW_BARRIER_OFFSET = 7'h 40;
  parameter logic [BlockAw-1:0] SNITCH_CLUSTER_PERIPHERAL_ICACHE_PREFETCH_ENABLE_OFFSET = 7'h 48;

  // Reset values for hwext registers and their fields
  parameter logic [47:0] SNITCH_CLUSTER_PERIPHERAL_PERF_COUNTER_0_RESVAL = 48'h 0;
  parameter logic [47:0] SNITCH_CLUSTER_PERIPHERAL_PERF_COUNTER_1_RESVAL = 48'h 0;
  parameter logic [31:0] SNITCH_CLUSTER_PERIPHERAL_CL_CLINT_SET_RESVAL = 32'h 0;
  parameter logic [31:0] SNITCH_CLUSTER_PERIPHERAL_CL_CLINT_CLEAR_RESVAL = 32'h 0;
  parameter logic [31:0] SNITCH_CLUSTER_PERIPHERAL_HW_BARRIER_RESVAL = 32'h 0;

  // Register index
  typedef enum int {
    SNITCH_CLUSTER_PERIPHERAL_PERF_COUNTER_ENABLE_0,
    SNITCH_CLUSTER_PERIPHERAL_PERF_COUNTER_ENABLE_1,
    SNITCH_CLUSTER_PERIPHERAL_HART_SELECT_0,
    SNITCH_CLUSTER_PERIPHERAL_HART_SELECT_1,
    SNITCH_CLUSTER_PERIPHERAL_PERF_COUNTER_0,
    SNITCH_CLUSTER_PERIPHERAL_PERF_COUNTER_1,
    SNITCH_CLUSTER_PERIPHERAL_CL_CLINT_SET,
    SNITCH_CLUSTER_PERIPHERAL_CL_CLINT_CLEAR,
    SNITCH_CLUSTER_PERIPHERAL_HW_BARRIER,
    SNITCH_CLUSTER_PERIPHERAL_ICACHE_PREFETCH_ENABLE
  } snitch_cluster_peripheral_id_e;

  // Register width information to check illegal writes
  parameter logic [3:0] SNITCH_CLUSTER_PERIPHERAL_PERMIT [10] = '{
    4'b 1111, // index[0] SNITCH_CLUSTER_PERIPHERAL_PERF_COUNTER_ENABLE_0
    4'b 1111, // index[1] SNITCH_CLUSTER_PERIPHERAL_PERF_COUNTER_ENABLE_1
    4'b 0011, // index[2] SNITCH_CLUSTER_PERIPHERAL_HART_SELECT_0
    4'b 0011, // index[3] SNITCH_CLUSTER_PERIPHERAL_HART_SELECT_1
    4'b 1111, // index[4] SNITCH_CLUSTER_PERIPHERAL_PERF_COUNTER_0
    4'b 1111, // index[5] SNITCH_CLUSTER_PERIPHERAL_PERF_COUNTER_1
    4'b 1111, // index[6] SNITCH_CLUSTER_PERIPHERAL_CL_CLINT_SET
    4'b 1111, // index[7] SNITCH_CLUSTER_PERIPHERAL_CL_CLINT_CLEAR
    4'b 1111, // index[8] SNITCH_CLUSTER_PERIPHERAL_HW_BARRIER
    4'b 0001  // index[9] SNITCH_CLUSTER_PERIPHERAL_ICACHE_PREFETCH_ENABLE
  };

endpackage

