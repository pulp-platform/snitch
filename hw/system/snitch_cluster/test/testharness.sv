// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

module testharness (
  input  logic        clk_i,
  input  logic        rst_i,
  input  logic [8:0]  debug_req_i,
  input  logic [8:0]  meip_i,
  input  logic [8:0]  mtip_i,
  input  logic [8:0]  msip_i
);

  snitch_axi_pkg::req_t axi_slv_req;
  snitch_axi_pkg::resp_t axi_slv_res;
  snitch_axi_pkg::req_slv_t axi_mst_req;
  snitch_axi_pkg::resp_slv_t axi_mst_res;
  snitch_axi_pkg::req_dma_slv_t axi_dma_req;
  snitch_axi_pkg::resp_dma_slv_t axi_dma_resp;

  snitch_cluster #(
    .BootAddr           ( 32'h8001_0000              ),
    .NrCores            ( 9                          ),
    .NrBanks            ( 32                         ),
    .CoresPerHive       ( 9                          ),
    .ICacheLineWidth    ( 256                        ),
    .ICacheLineCount    ( 128                        ),
    .ICacheSets         ( 2                          ),
    .TCDMDepth          ( 512                        ),
    .Topology           ( tcdm_interconnect_pkg::LIC ),
    .RegisterOffload    ( 1'b1                       ),
    .RegisterOffloadRsp ( 1'b1                       ),
    .RegisterTCDMReq    ( 1'b1                       ),
    .RegisterTCDMCuts   ( 1'b0                       ),
    .RegisterExtWide    ( 1'b0                       ),
    .RegisterExtNarrow  ( 1'b0                       ),
    .RegisterSequencer  ( 1'b0                       ),
    .IsoCrossing        ( 1'b0                       )
  ) i_cluster (
    .clk_i           ( clk_i        ),
    .rst_i           ( rst_i        ),
    .debug_req_i     ( debug_req_i  ),
    .hart_base_id_i  ( '0           ),
    .meip_i          ( meip_i       ),
    .mtip_i          ( mtip_i       ),
    .msip_i          ( msip_i       ),
    .clk_d2_bypass_i ( 1'b0         ),
    .axi_slv_req_i   ( axi_slv_req  ),
    .axi_slv_res_o   ( axi_slv_res  ),
    .axi_mst_req_o   ( axi_mst_req  ),
    .axi_mst_res_i   ( axi_mst_res  ),
    .ext_dma_req_o   ( axi_dma_req  ),
    .ext_dma_resp_i  ( axi_dma_resp )
  );

endmodule
