// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Paul Scheffler <paulsc@iis.ee.ethz.ch>

module tb_simple_ssr;

  fixture_ssr fix();

  initial begin
    fix.wait_for_reset_start();
    fix.wait_for_reset_end();
    // TODO: Test basic SSR functionality here
    #1000ns;
    $finish;
  end

endmodule
