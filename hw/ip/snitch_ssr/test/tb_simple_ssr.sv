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

  // Instantiate fixture
  fixture_ssr fix();

  initial begin
    fix.wait_for_reset_start();
    fix.wait_for_reset_end();

    $readmemh(DvecFile, fix.memory);

    // Natural iteration read checks (using both launch methods)
    for (int a = 1'b0; a < 2; ++a) begin
      fix.verify_nat_job(0, a[0], 0,  0, 0,  '{0, 0, 0, 36},  '{0, 0, 0, 1});
      fix.verify_nat_job(0, a[0], 17, 0, 3,  '{0, 0, 0, 9},   '{0, 0, 0, 3});
      fix.verify_nat_job(0, a[0], 7,  1, 0,  '{0, 0, 0, 9},   '{0, 0, 4, 1});
      fix.verify_nat_job(0, a[0], 2,  2, 0,  '{0, 3, 0, 2},   '{0, 7, 4, 3});
      fix.verify_nat_job(0, a[0], 7,  2, 0,  '{0, 3, 1, 2},   '{0, 1, -4, 5});
      fix.verify_nat_job(0, a[0], 18, 3, 0,  '{3, 1, 3, 9},   '{-53, -51, -43, 5});
      fix.verify_nat_job(0, a[0], 9,  3, 5,  '{3, 1, 3, 9},   '{-53, -51, -43, 5});
    end

    // Natural iteration write checks (using both launch methods).
    // Note that overlaps with source and other destination data may lead to mismatches;
    // To this end, we use only positive strides and sufficient offsets
    for (int a = 1'b0; a < 2; ++a) begin
      automatic logic [31:0] write_base = (a[0] + 1)*'h10000;
      fix.verify_nat_job(1, a[0], 0,  0, 0,  '{0, 0, 0, 36},  '{0, 0, 0, 1},    54, write_base);
      fix.verify_nat_job(1, a[0], 17, 0, 3,  '{0, 0, 0, 9},   '{0, 0, 0, 3},    71, write_base);
      fix.verify_nat_job(1, a[0], 7,  1, 0,  '{0, 0, 0, 9},   '{0, 0, 4, 1},    83, write_base);
      fix.verify_nat_job(1, a[0], 2,  2, 0,  '{0, 3, 0, 2},   '{0, 7, 4, 3},    31, write_base);
      fix.verify_nat_job(1, a[0], 7,  2, 0,  '{0, 3, 1, 2},   '{0, 1, 17, 5},   27, write_base);
      fix.verify_nat_job(1, a[0], 18, 3, 0,  '{2, 1, 2, 3},   '{101, 17, 2, 5}, 13, write_base);
      fix.verify_nat_job(1, a[0], 9,  3, 5,  '{3, 2, 1, 1},   '{57, 19, 1, 3},  9 , write_base);
    end

    // Done, no error errors occured
    $display("SUCCESS");
    $finish;
  end

endmodule
