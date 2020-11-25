// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Thomas Benz <tbenz@ethz.ch>

`include "axi/typedef.svh"

// for now this is an extended copy of the axi_pkg
// eventually the DMA specific parts should be moved in axi_pkg aswell
package axi_dma_pkg;

  localparam int unsigned IdWidth   = snitch_pkg::IdWidthDma;
  localparam int unsigned UserWidth = snitch_axi_pkg::DMAUserWidth;
  localparam int unsigned AddrWidth = snitch_axi_pkg::DMAAddrWidth;
  localparam int unsigned DataWidth = snitch_axi_pkg::DMADataWidth;
  localparam int unsigned StrbWidth = snitch_axi_pkg::DMAStrbWidth;

  typedef logic [IdWidth-1:0]   id_t;
  typedef logic [AddrWidth-1:0] addr_t;
  typedef logic [DataWidth-1:0] data_t;
  typedef logic [StrbWidth-1:0] strb_t;
  typedef logic [UserWidth-1:0] user_t;

  // DMA
  localparam int unsigned OffsetWidth = $clog2(StrbWidth);
  typedef logic [OffsetWidth-1:0] offset_t;
  typedef logic [            7:0] beatlen_t;

  // DMA
  typedef struct packed {
      id_t             id;
      logic            last;
      addr_t           addr;
      axi_pkg::len_t   len;
      axi_pkg::size_t  size;
      axi_pkg::burst_t burst;
      axi_pkg::cache_t cache;
  } desc_ax_t;

  typedef struct packed {
      offset_t offset;
      offset_t tailer;
      offset_t shift;
  } desc_r_t;

  typedef struct packed {
      offset_t  offset;
      offset_t  tailer;
      beatlen_t num_beats;
      logic     is_single;
  } desc_w_t;

  typedef struct packed {
      desc_ax_t aw;
      desc_w_t  w;
  } write_req_t;

  typedef struct packed {
      desc_ax_t ar;
      desc_r_t  r;
  } read_req_t;

  typedef struct packed {
      id_t              id;
      addr_t            addr;
      addr_t            num_bytes;
      axi_pkg::cache_t  cache;
      axi_pkg::burst_t  burst;
      logic             valid;
  } burst_chan_t;

  typedef struct packed {
      burst_chan_t src;
      burst_chan_t dst;
      offset_t     shift;
      logic        decouple_rw;
      logic        deburst;
  } burst_decoupled_t;

  typedef struct packed {
      id_t              id;
      addr_t            src, dst, num_bytes;
      axi_pkg::cache_t  cache_src, cache_dst;
      axi_pkg::burst_t  burst_src, burst_dst;
      logic             decouple_rw;
      logic             deburst;
  } burst_req_t;

  typedef struct packed {
      id_t              id;
      addr_t            src, dst, num_bytes;
      axi_pkg::cache_t  cache_src, cache_dst;
      addr_t            stride_src, stride_dst, num_repetitions;
      axi_pkg::burst_t  burst_src, burst_dst;
      logic             decouple_rw;
      logic             deburst;
      logic             is_twod;
  } twod_req_t;

  typedef struct packed {
      logic [63:0] aw_stall_cnt, ar_stall_cnt, r_stall_cnt, w_stall_cnt,
                   buf_w_stall_cnt, buf_r_stall_cnt;
      logic [63:0] aw_valid_cnt, aw_ready_cnt, aw_done_cnt, aw_bw;
      logic [63:0] ar_valid_cnt, ar_ready_cnt, ar_done_cnt, ar_bw;
      logic [63:0]  r_valid_cnt,  r_ready_cnt,  r_done_cnt,  r_bw;
      logic [63:0]  w_valid_cnt,  w_ready_cnt,  w_done_cnt,  w_bw;
      logic [63:0]  b_valid_cnt,  b_ready_cnt,  b_done_cnt;
      logic [63:0] next_id,       completed_id;
      logic [63:0] dma_busy_cnt;
  } dma_perf_t;

endpackage
