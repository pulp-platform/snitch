// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

/// # Clock divider
///
/// This module uses a flip-flop and an inverter to divide
/// the incoming, fast clock, by two.
///
/// An optional bypass signal (`test_mode_i`) sets a multiplexer
/// so that the clock will not be divided. Useful for DFT.
///
/// ## Behavioral Model
///
/// Unfortunately the behavioral flip-flop description will introduce an
/// additional delta cycle in the downstream logic.
/// As a matter of fact, logic which relies on the
/// constant clock-delay factor breaks.
/// We move the slow clock to the next 0 delta cycle by delaying
/// it for a whole `fast` clock period.
///
/// In-order to be independent of the clock frequency, this module
/// calculates the clock frequency of the fast clock period by
/// sampling the clock.

// Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>
// Author: Fabian Schuiki <fschuiki@iis.ee.ethz.ch>

(* no_ungroup *)
(* no_boundary_optimization *)
module snitch_clkdiv2 (
  input  logic clk_i,
  input  logic test_mode_i,
  input  logic bypass_i,
  output logic clk_o
);

  `ifndef SYNTHESIS
  // simulation work around
  bit clk_div, clk_div_del;
  time sample [2] = {0, 0};
  time fast_clk;
  // delay clock for a whole period to avoid delta cycle issue
  assign #fast_clk clk_div_del = clk_div;
  // obtain two time samples to calculate the clock frequency
  always @ (posedge clk_i) begin
    sample [1] <= sample[0];
    sample [0] <= $time;
  end
  assign fast_clk = sample[0] - sample[1];
  `else
  logic clk_div, clk_div_del;
  assign clk_div_del = clk_div;
  `endif

  always_ff @(posedge clk_i) clk_div <= ~clk_div;
  assign clk_o = (test_mode_i | bypass_i) ? clk_i : clk_div_del;

endmodule
