// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Paul Scheffler <paulsc@iis.ee.ethz.ch>

module tb_simple_ssr;

  // Testbench parameters
  localparam bit  Verbose = 1'b1;
  localparam time Timeout = 20ns;
  localparam int  ResAddr = 'h3000;

  // Test data parameters
  localparam string       DvecFile  = "../test/data/dvec.double.0x0.100_1337.hex";
  localparam int unsigned DvecLen   = 100;

  logic alias_launch = 0;

  // Instantiate fixture
  fixture_ssr fix();

  initial begin
    fix.wait_for_reset_start();
    fix.wait_for_reset_end();

    $readmemh(DvecFile, fix.memory);

    // Natural iteration read checks
    fix.verify_nat_read(alias_launch, 0,  0, 0,  '{0, 0, 0, 36}, '{0, 0, 0, 1});
    fix.verify_nat_read(alias_launch, 17, 0, 3,  '{0, 0, 0, 9}, '{0, 0, 0, 3});
    fix.verify_nat_read(alias_launch, 7,  1, 0,  '{0, 0, 0, 9}, '{0, 0, 4, 1});
    fix.verify_nat_read(alias_launch, 7,  2, 0,  '{0, 3, 0, 2}, '{0, 7, 4, 3});
    fix.verify_nat_read(alias_launch, 7,  2, 0,  '{0, 3, 1, 2}, '{0, 1, -4, 5});
    fix.verify_nat_read(alias_launch, 7,  3, 0,  '{3, 1, 3, 9}, '{-53, -51, -43, 5});
    fix.verify_nat_read(alias_launch, 7,  3, 5,  '{3, 1, 3, 9}, '{-53, -51, -43, 5});

    // Done, no error errors occured
    $display("SUCCESS");
    $finish;
  end

endmodule
