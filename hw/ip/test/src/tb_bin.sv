// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

/// RTL Top-level for `fesvr` simulation.
module tb_bin;
  import "DPI-C" function int fesvr_tick();

  // This can't have a unit otherwise the simulation will not advance, for
  // whatever reason.
  // verilog_lint: waive explicit-parameter-storage-type
  localparam TCK = 1ns;

  logic rst_ni, clk_i;

  testharness i_dut (
    .clk_i,
    .rst_ni
  );

  initial begin
    rst_ni = 0;
    #10ns;
    rst_ni = 1;
    #10ns;
    rst_ni = 0;
    #10ns;
    rst_ni = 1;
  end

  // Generate reset and clock.
  initial begin
    forever begin
      clk_i = 1;
      #(TCK/2);
      clk_i = 0;
      #(TCK/2);
    end
  end

  // Start `fesvr`.
  initial begin
    automatic int exit_code;
    while ((exit_code = fesvr_tick()) == 0) #200ns;
    exit_code >>= 1;
    if (exit_code > 0) begin
      $error("[FAILURE] Finished with exit code %2d", exit_code);
    end else begin
      $info("[SUCCESS] Program finished successfully");
    end
    $finish;
  end

endmodule
