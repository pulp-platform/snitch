// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Paul Scheffler <paulsc@iis.ee.ethz.ch>

module tb_simple_ssr_streamer;

  import snitch_ssr_pkg::*;

  // Test parameters
  localparam int unsigned AddrWidth = 17;
  localparam int unsigned DataWidth = 64;
  localparam int unsigned NumSsrs   = 3;
  localparam int unsigned RPorts    = 3;
  localparam int unsigned WPorts    = 1;

  // Test data parameters
  localparam string       DataFile = "../test/tb_simple_ssr_streamer.hex";
  localparam int unsigned ValBase   = 'h0;
  localparam int unsigned IdxBase   = 'h2000;
  localparam int unsigned IdxStride = 'h800;  // Stride of index arrays of different sizes

  // DUT parameters
  function automatic ssr_cfg_t [NumSsrs-1:0] gen_cfg_ssr();
    ssr_cfg_t CfgSsrDefault = '{
      Indirection:    1,
      IndirOutSpill:  1,
      NumLoops:       4,
      IndexWidth:     AddrWidth - $clog2(DataWidth/8),
      PointerWidth:   AddrWidth,
      ShiftWidth:     3,
      IndexCredits:   3,
      DataCredits:    4,
      MuxRespDepth:   3,
      RptWidth:       4,
      IsectSlaveSpill:    1,
      IsectSlaveCredits:  8,
      default:        '0    // Isect parameters below
    };
    ssr_cfg_t [NumSsrs-1:0] ret = '{CfgSsrDefault, CfgSsrDefault, CfgSsrDefault};
    ret[0].IsectMaster    = 1'b1;
    ret[1].IsectMaster    = 1'b1;
    ret[1].IsectMasterIdx = 1'b1;
    ret[2].IsectSlave     = 1'b1;
    return ret;
  endfunction

  localparam ssr_cfg_t [NumSsrs-1:0]  SsrCfgs  = gen_cfg_ssr();
  localparam logic [NumSsrs-1:0][4:0] SsrRegs  = '{2, 1, 0};

  fixture_ssr_streamer #(
    .NumSsrs    ( NumSsrs   ),
    .RPorts     ( RPorts    ),
    .WPorts     ( WPorts    ),
    .AddrWidth  ( AddrWidth ),
    .DataWidth  ( DataWidth ),
    .SsrCfgs    ( SsrCfgs   ),
    .SsrRegs    ( SsrRegs   )
  ) fix ();

  initial begin
    fix.wait_for_reset_start();
    fix.wait_for_reset_end();

    // Preload memory
    $readmemh(DataFile, fix.memory);

    // Test intersection applications
    // TODO: extend further
    repeat (2) begin
      repeat(2) begin
        fix.verify_isect_inout (
          /* data_base */     '{'h1000*8, 'h400*8, 'h0},
          /* idx_base */      '{'h1200*8, 'h580*8, 'h180*8},
          /* idx_bound */     '{92-1, 67-1},
          /* merge */         1'b1,
          /* idx_size */      '{1, 1, 1},
          /* alias_launch */  1'b1,
          /* idx_gold_base */ 'h800*8,
          /* len_gold */      128
        );
      end repeat (2) begin
        fix.verify_isect_inout (
          /* data_base */     '{'h1000*8, 'h400*8, 'h0},
          /* idx_base */      '{'h1200*8, 'h580*8, 'h180*8},
          /* idx_bound */     '{92-1, 67-1},
          /* merge */         1'b0,
          /* idx_size */      '{1, 1, 1},
          /* alias_launch */  1'b1,
          /* idx_gold_base */ 'ha00*8,
          /* len_gold */      31

        );
      end
    end

    // Done, no fatal errors occured
    $display("SUCCESS");
    $finish;
  end

endmodule
