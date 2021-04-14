// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Paul Scheffler <paulsc@iis.ee.ethz.ch>

module tb_simple_ssr;

  // Test parameters
  localparam int unsigned AddrWidth     = 32;
  localparam int unsigned DataWidth     = 64;
  localparam bit          Indirection   = 1;
  // TODO: Indirect writes fail with one loop level. Why?
  localparam int unsigned NumLoops      = 4;

  // Test data parameters
  localparam string       DataFile = "../test/tb_simple_ssr.hex";
  localparam int unsigned ValBase   = 'h0;
  localparam int unsigned IdxBase   = 'h2000;
  localparam int unsigned IdxStride = 'h800;  // Stride of index arrays of different sizes

  // DUT parameters
  localparam snitch_ssr_pkg::ssr_cfg_t Cfg = '{
    Indirection:    Indirection,
    IndirOutSpill:  1,
    NumLoops:       NumLoops,
    IndexWidth:     16,
    PointerWidth:   18,
    ShiftWidth:     3,
    IndexCredits:   3,
    DataCredits:    4,
    MuxRespDepth:   3,
    RptWidth:       4
  };

  // Instantiate fixture
  fixture_ssr #(
    .AddrWidth ( AddrWidth  ),
    .DataWidth ( DataWidth  ),
    .Cfg       ( Cfg        )
  ) fix();

  initial begin
    fix.wait_for_reset_start();
    fix.wait_for_reset_end();

    $readmemh(DataFile, fix.memory);

    // Natural iteration read checks (using both launch methods)
    for (int a = 0; a < 2; ++a) begin
      $info("Direct tests: write 0, alias %0d", a);
      fix.verify_nat_job(0, a, ValBase + 8*0,  0, 0, '{0, 0, 0, 36}, '{0, 0, 0, 1});
      fix.verify_nat_job(0, a, ValBase + 8*17, 0, 3, '{0, 0, 0, 9},  '{0, 0, 0, 3});
      if (Cfg.NumLoops >= 2) begin
        fix.verify_nat_job(0, a, ValBase + 8*7,  1, 0, '{0, 0, 1, 9}, '{0, 0, 4, 1});
        fix.verify_nat_job(0, a, ValBase + 8*7,  1, 0, '{0, 0, 3, 9}, '{0, 0, 2, 3});
      end if (Cfg.NumLoops >= 3) begin
        fix.verify_nat_job(0, a, ValBase + 8*2,  2, 0, '{0, 3, 0, 2}, '{0, 7, 4, 3});
        fix.verify_nat_job(0, a, ValBase + 8*7,  2, 0, '{0, 3, 1, 2}, '{0, 1, -4, 5});
      end if (Cfg.NumLoops >= 4) begin
        fix.verify_nat_job(0, a, ValBase + 8*18, 3, 0, '{3, 1, 3, 9}, '{-53, -51, -43, 5});
        fix.verify_nat_job(0, a, ValBase + 8*9,  3, 5, '{3, 1, 3, 9}, '{-53, -51, -43, 5});
      end
    end

    // Natural iteration write checks (using both launch methods).
    // Note that overlaps with source and other destination data may lead to mismatches;
    // To this end, we use only positive strides and sufficient offsets.
    for (int a = 0; a < 2; ++a) begin
      automatic logic [31:0] wbase = (a + 2)*'h4000;
      $info("Direct tests: write 1, alias %0d, wbase %x", a, wbase);
      fix.verify_nat_job(1, a, ValBase + 8*0,  0, 0, '{0, 0, 0, 36}, '{0, 0, 0, 1},    8*54, wbase);
      fix.verify_nat_job(1, a, ValBase + 8*17, 0, 3, '{0, 0, 0, 9},  '{0, 0, 0, 3},    8*71, wbase);
      if (Cfg.NumLoops >= 2) begin
        fix.verify_nat_job(1, a, ValBase + 8*7,  1, 0, '{0, 0, 1, 9}, '{0, 0, 4, 1},   8*83, wbase);
        fix.verify_nat_job(1, a, ValBase + 8*7,  1, 0, '{0, 0, 3, 9}, '{0, 0, 2, 3},   8*83, wbase);
      end if (Cfg.NumLoops >= 3) begin
        fix.verify_nat_job(1, a, ValBase + 8*2,  2, 0, '{0, 3, 0, 2}, '{0, 7, 4, 3},   8*31, wbase);
        fix.verify_nat_job(1, a, ValBase + 8*7,  2, 0, '{0, 3, 1, 2}, '{0, 1, 17, 5},  8*27, wbase);
      end if (Cfg.NumLoops >= 4) begin
        fix.verify_nat_job(1, a, ValBase + 8*18, 3, 0, '{2, 1, 2, 3}, '{93, 17, 2, 5}, 8*13, wbase);
        fix.verify_nat_job(1, a, ValBase + 8*9,  3, 5, '{3, 2, 1, 1}, '{57, 19, 1, 3}, 8*9,  wbase);
      end
    end

    if (Indirection) begin
      // Indirect iteration read and write checks.
      // The notes above on writes also apply here, which is why we write to dedicated sections.
      for (int i = 1'b0; i < (1 << 4); ++i) begin
        automatic logic w = i[3];
        automatic logic a = i[2];
        automatic logic [1:0] s = i[1:0];
        automatic logic [31:0] wbase = w ? ({a, s} + 3)*'h4000 : ValBase;
        automatic logic [31:0] ibase = IdxBase + s*IdxStride;
        $info("Indirect tests: write %0d, alias %0d, size %0d, wbase %x, ibase %x",
            w, a, s, wbase, ibase);
        fix.verify_indir_job(w, a, wbase, ibase + (1<<s)*1,  0, 3,  4, s, ValBase);
        fix.verify_indir_job(w, a, wbase, ibase + (1<<s)*3,  0, 7,  3, s, ValBase);
        fix.verify_indir_job(w, a, wbase, ibase + (1<<s)*0,  0, 36, 0, s, ValBase);
        fix.verify_indir_job(w, a, wbase, ibase + (1<<s)*1,  0, 35, 2, s, ValBase);
        fix.verify_indir_job(w, a, wbase, ibase + (1<<s)*20, 2, 12, 2, s, ValBase);
        fix.verify_indir_job(w, a, wbase, ibase + (1<<s)*26, 7, 7,  2, s, ValBase);
        fix.verify_indir_job(w, a, wbase, ibase + (1<<s)*1,  0, 35, 1, s, ValBase);
        fix.verify_indir_job(w, a, wbase, ibase + (1<<s)*30, 0, 4,  2, s, ValBase);
        fix.verify_indir_job(w, a, wbase, ibase + (1<<s)*31, 0, 4,  0, s, ValBase);
        fix.verify_indir_job(w, a, wbase, ibase + (1<<s)*14, 0, 0,  0, s, ValBase);
        fix.verify_indir_job(w, a, wbase, ibase + (1<<s)*15, 0, 0,  1, s, ValBase);
        fix.verify_indir_job(w, a, wbase, ibase + (1<<s)*14, 0, 1,  2, s, ValBase);
        fix.verify_indir_job(w, a, wbase, ibase + (1<<s)*15, 0, 1,  1, s, ValBase);
      end
    end

    // Done, no error errors occured
    $display("SUCCESS");
    $finish;
  end

endmodule
