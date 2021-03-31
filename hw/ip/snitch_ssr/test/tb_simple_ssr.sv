// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Paul Scheffler <paulsc@iis.ee.ethz.ch>

module tb_simple_ssr;

  // Test data parameters
  localparam string DvecFile    = "../test/data/dvec.double.0x0.100_1337.hex";
  localparam string Svec32File  = "../test/data/svec.double_int.0x1000.100_37_1337.hex";
  localparam string Svec16File  = "../test/data/svec.double_short.0x2000.100_37_1337.hex";

  localparam int unsigned SvecValsLen   = 37;
  localparam int unsigned DvecBase      = 0;
  localparam int unsigned Svec32ValBase = 'h1000;
  localparam int unsigned Svec32IdxBase = Svec32ValBase + 8*SvecValsLen;
  localparam int unsigned Svec16ValBase = 'h2000;
  localparam int unsigned Svec16IdxBase = Svec16ValBase + 8*SvecValsLen;

  // TODO: DUT parameters, forward through fixture
  localparam bit Indirection = 1;

  // Instantiate fixture
  fixture_ssr fix();

  initial begin
    fix.wait_for_reset_start();
    fix.wait_for_reset_end();

    $readmemh(DvecFile, fix.memory);
    $readmemh(Svec32File, fix.memory);
    $readmemh(Svec16File, fix.memory);

    // Natural iteration read checks (using both launch methods)
    for (int a = 1'b0; a < 2; ++a) begin
      fix.verify_nat_job(0, a[0], DvecBase + 8*0,  0, 0, '{0, 0, 0, 36}, '{0, 0, 0, 1});
      fix.verify_nat_job(0, a[0], DvecBase + 8*17, 0, 3, '{0, 0, 0, 9},  '{0, 0, 0, 3});
      fix.verify_nat_job(0, a[0], DvecBase + 8*7,  1, 0, '{0, 0, 0, 9},  '{0, 0, 4, 1});
      fix.verify_nat_job(0, a[0], DvecBase + 8*2,  2, 0, '{0, 3, 0, 2},  '{0, 7, 4, 3});
      fix.verify_nat_job(0, a[0], DvecBase + 8*7,  2, 0, '{0, 3, 1, 2},  '{0, 1, -4, 5});
      fix.verify_nat_job(0, a[0], DvecBase + 8*18, 3, 0, '{3, 1, 3, 9},  '{-53, -51, -43, 5});
      fix.verify_nat_job(0, a[0], DvecBase + 8*9,  3, 5, '{3, 1, 3, 9},  '{-53, -51, -43, 5});
    end

    // Natural iteration write checks (using both launch methods).
    // Note that overlaps with source and other destination data may lead to mismatches;
    // To this end, we use only positive strides and sufficient offsets.
    for (int a = 1'b0; a < 2; ++a) begin
      automatic logic [31:0] wbase = (a[0] + 1)*'h4000;
      fix.verify_nat_job(1, a[0], DvecBase + 8*0,  0, 0, '{0, 0, 0, 36}, '{0, 0, 0, 1},    8*54, wbase);
      fix.verify_nat_job(1, a[0], DvecBase + 8*17, 0, 3, '{0, 0, 0, 9},  '{0, 0, 0, 3},    8*71, wbase);
      fix.verify_nat_job(1, a[0], DvecBase + 8*7,  1, 0, '{0, 0, 0, 9},  '{0, 0, 4, 1},    8*83, wbase);
      fix.verify_nat_job(1, a[0], DvecBase + 8*2,  2, 0, '{0, 3, 0, 2},  '{0, 7, 4, 3},    8*31, wbase);
      fix.verify_nat_job(1, a[0], DvecBase + 8*7,  2, 0, '{0, 3, 1, 2},  '{0, 1, 17, 5},   8*27, wbase);
      fix.verify_nat_job(1, a[0], DvecBase + 8*18, 3, 0, '{2, 1, 2, 3},  '{101, 17, 2, 5}, 8*13, wbase);
      fix.verify_nat_job(1, a[0], DvecBase + 8*9,  3, 5, '{3, 2, 1, 1},  '{57, 19, 1, 3},  8*9,  wbase);
    end

    if (Indirection) begin
      // Indirect 32-bit iteration read checks
      for (int a = 1'b0; a < 2; ++a) begin
        automatic logic [31:0] wbase = (a[0] + 1)*'h4000;
        fix.verify_indir_job(0, a[0], DvecBase, Svec32IdxBase + 4*0,  0, 36, 3, 2, Svec32ValBase, wbase);
        fix.verify_indir_job(0, a[0], DvecBase, Svec32IdxBase + 4*1,  0, 35, 3, 2, Svec32ValBase, wbase);
        //fix.verify_indir_job(0, a[0], DvecBase, Svec32IdxBase + 4*20, 2, 12, 3, 2, Svec32ValBase, wbase);
        //fix.verify_indir_job(0, a[0], DvecBase, Svec32IdxBase + 4*26, 7, 7,  3, 2, Svec32ValBase, wbase);
        //fix.verify_indir_job(0, a[0], DvecBase, Svec32IdxBase + 4*1,  0, 35, 3, 2, Svec32ValBase, wbase);
        //fix.verify_indir_job(0, a[0], DvecBase, Svec32IdxBase + 4*30, 0, 4,  3, 2, Svec32ValBase, wbase);
        //fix.verify_indir_job(0, a[0], DvecBase, Svec32IdxBase + 4*31, 0, 4,  3, 2, Svec32ValBase, wbase);
        //fix.verify_indir_job(0, a[0], DvecBase, Svec32IdxBase + 4*14, 0, 0,  3, 2, Svec32ValBase, wbase);
        //fix.verify_indir_job(0, a[0], DvecBase, Svec32IdxBase + 4*15, 0, 0,  3, 2, Svec32ValBase, wbase);
        //fix.verify_indir_job(0, a[0], DvecBase, Svec32IdxBase + 4*14, 0, 1,  3, 2, Svec32ValBase, wbase);
        //fix.verify_indir_job(0, a[0], DvecBase, Svec32IdxBase + 4*15, 0, 1,  3, 2, Svec32ValBase, wbase);
      end

      // Indirect 16-bit iteration read, interspersed write checks
      /*
      fix.check_indir_job(0, 0, 0, Svec32IdxBase + 8*0,  DvecBase, 36, 0, 2, Svec16IdxBase, Svec32ValBase + , DvecBase, wbase);
      fix.check_indir_job(0, 0, 0, Svec32IdxBase + 8*1,  DvecBase, 35, 0, 2, Svec16IdxBase, Svec32ValBase + , DvecBase, wbase);
      fix.check_indir_job(0, 0, 2, Svec32IdxBase + 8*20, DvecBase, 12, 0, 2, Svec16IdxBase, Svec32ValBase + , DvecBase, wbase);
      fix.check_indir_job(0, 0, 7, Svec32IdxBase + 8*26, DvecBase, 7,  0, 2, Svec16IdxBase, Svec32ValBase + , DvecBase, wbase);
        //check_indir_write(0, 36);
      fix.check_indir_job(0, 0, 0, Svec32IdxBase + 8*1,  DvecBase, 35, 0, 2, Svec16IdxBase, Svec32ValBase + , DvecBase, wbase);
      fix.check_indir_job(0, 0, 0, Svec32IdxBase + 8*30, DvecBase, 4,  0, 2, Svec16IdxBase, Svec32ValBase + , DvecBase, wbase);
        //check_indir_write(3, 7);
      fix.check_indir_job(0, 0, 0, Svec32IdxBase + 8*31, DvecBase, 4,  0, 2, Svec16IdxBase, Svec32ValBase + , DvecBase, wbase);
      fix.check_indir_job(0, 0, 0, Svec32IdxBase + 8*14, DvecBase, 0,  0, 2, Svec16IdxBase, Svec32ValBase + , DvecBase, wbase);
      fix.check_indir_job(0, 0, 0, Svec32IdxBase + 8*15, DvecBase, 0,  0, 2, Svec16IdxBase, Svec32ValBase + , DvecBase, wbase);
      fix.check_indir_job(0, 0, 0, Svec32IdxBase + 8*14, DvecBase, 1,  0, 2, Svec16IdxBase, Svec32ValBase + , DvecBase, wbase);
      fix.check_indir_job(0, 0, 0, Svec32IdxBase + 8*15, DvecBase, 1,  0, 2, Svec16IdxBase, Svec32ValBase + , DvecBase, wbase);
      */
    end

    // Done, no error errors occured
    $display("SUCCESS");
    $finish;
  end

endmodule
