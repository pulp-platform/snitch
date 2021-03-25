// Copyright 2021 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

module occamy_cva6 (
  input  logic              clk_i,
  input  logic              rst_ni,
  input  logic [63:0]       boot_addr_i,
  input  logic [63:0]       hart_id_i,
  input  logic [1:0]        irq_i,
  input  logic              ipi_i,
  input  logic              time_irq_i,
  input  logic              debug_req_i,
  output ariane_axi::req_t  axi_req_o,
  input  ariane_axi::resp_t axi_resp_i
);

  ariane #(
    .ArianeCfg (ariane_pkg::ArianeDefaultConfig)
  ) i_cva6 (
    .clk_i,
    .rst_ni,
    .boot_addr_i,
    .hart_id_i,
    .irq_i,
    .ipi_i,
    .time_irq_i,
    .debug_req_i,
    .axi_req_o,
    .axi_resp_i
  );

endmodule
