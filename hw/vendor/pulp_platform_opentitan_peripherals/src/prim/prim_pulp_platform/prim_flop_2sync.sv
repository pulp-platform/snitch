// Copyright 2021 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Double-synchronizer flop implementation for opentitan primitive cells
// using cells from pulp_platform common_cells.

module prim_flop_2sync #(
  parameter int               Width      = 16,
  parameter logic [Width-1:0] ResetValue = '0
) (
  input  logic clk_i,
  input  logic rst_ni,
  input  logic [Width-1:0] d_i,
  output logic [Width-1:0] q_o
);

  // Note that multi-bit syncs are *almost always* a bad idea.
  for (genvar i = 0; i < Width; ++i) begin : gen_syncs
    sync #(
      .STAGES     (2),
      .ResetValue (ResetValue[i])
    ) i_sync (
      .clk_i,
      .rst_ni,
      .serial_i (d_i[i]),
      .serial_o (q_o[i])
    );
  end

endmodule
