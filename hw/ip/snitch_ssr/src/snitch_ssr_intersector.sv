// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Paul Scheffler <paulsc@iis.ee.ethz.ch>

`include "common_cells/registers.svh"

module snitch_ssr_intersector import snitch_ssr_pkg::*; #(
  parameter int unsigned StreamctlDepth = 0,
  parameter type isect_mst_req_t = logic,
  parameter type isect_mst_rsp_t = logic,
  parameter type isect_slv_req_t = logic,
  parameter type isect_slv_rsp_t = logic
) (
  input  logic clk_i,
  input  logic rst_ni,

  input  isect_mst_req_t [1:0]  mst_req_i,
  output isect_mst_rsp_t [1:0]  mst_rsp_o,
  input  isect_slv_req_t        slv_req_i,
  output isect_slv_rsp_t        slv_rsp_o,

  output logic  streamctl_done_o,
  output logic  streamctl_valid_o,
  input  logic  streamctl_ready_i
);

  logic isect_match, isect_mslag;
  logic isect_ena, meta_ena, merge_ena, mst_slv_ena;
  logic src_valid;
  logic dst_slv_ready, dst_str_ready, dst_all_ready;
  logic isect_done, isect_msout;

  // Compare indices provided by masters
  assign isect_match  = (mst_req_i[1].idx == mst_req_i[0].idx);
  assign isect_mslag  = (mst_req_i[1].idx < mst_req_i[0].idx);

  // Enable conditions for emission and destinations
  assign isect_ena    = merge_ena | isect_match | isect_done;
  assign meta_ena     = ~isect_match & ~isect_done;
  assign merge_ena    = mst_req_i[1].merge & mst_req_i[0].merge;
  assign mst_slv_ena  = mst_req_i[1].slv_ena | mst_req_i[0].slv_ena;

  // Masters must both provide indices to proceed
  assign src_valid = mst_req_i[0].valid & mst_req_i[1].valid;

  // Destinations can stall iff enabled
  assign dst_slv_ready  = ~mst_slv_ena | (slv_req_i.ena & slv_req_i.ready);
  assign dst_all_ready  = dst_slv_ready & dst_str_ready;

  // Kill intersection as soon as no more indices can be emitted
  assign isect_done = merge_ena ?
      (mst_req_i[0].done & mst_req_i[1].done) :
      (mst_req_i[0].done | mst_req_i[1].done);

  // Outgoing index: stream that is lagging behind, unless done
  always_comb begin
    isect_msout = isect_mslag;
    if (mst_req_i[0].done) isect_msout = 1'b1;
    if (mst_req_i[1].done) isect_msout = 1'b0;
  end

  // Master responses
  assign mst_rsp_o[0] = '{
    zero:   meta_ena &  merge_ena &  isect_msout,
    skip:   meta_ena & ~merge_ena & ~isect_msout,
    done:   isect_done,
    ready:  src_valid & dst_all_ready & (isect_ena | mst_rsp_o[0].zero | mst_rsp_o[0].skip)
  };

  assign mst_rsp_o[1] = '{
    zero:   meta_ena &  merge_ena & ~isect_msout,
    skip:   meta_ena & ~merge_ena &  isect_msout,
    done:   isect_done,
    ready:  src_valid & dst_all_ready & (isect_ena | mst_rsp_o[1].zero | mst_rsp_o[1].skip)
  };

  // Slave response
  assign slv_rsp_o = '{
    idx:    mst_req_i[isect_msout].idx,
    done:   isect_done,
    valid:  src_valid & dst_str_ready & isect_ena & slv_req_i.ena
  };

  // Stream controller interface
  stream_fifo #(
    .FALL_THROUGH ( 0 ),
    .DEPTH        ( StreamctlDepth ),
    .DATA_WIDTH   ( 1 )
  ) i_fifo_streamctl (
    .clk_i,
    .rst_ni,
    .flush_i   ( 1'b0 ),
    .testmode_i( 1'b0 ),
    .usage_o   (  ),
    .data_i    ( isect_done ),
    .valid_i   ( src_valid & dst_slv_ready & isect_ena ),
    .ready_o   ( dst_str_ready      ),
    .data_o    ( streamctl_done_o   ),
    .valid_o   ( streamctl_valid_o  ),
    .ready_i   ( streamctl_ready_i  )
  );

endmodule
