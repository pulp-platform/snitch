// Copyright 2021 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// AUTOMATICALLY GENERATED by clustergen.py; edit the script or configuration
// instead.







`include "axi/typedef.svh"

// verilog_lint: waive-start package-filename
package occamy_cluster_pkg;

  localparam int unsigned NrCores = 9;
  localparam int unsigned NrHives = 1;

  localparam int unsigned AddrWidth = 48;
  localparam int unsigned NarrowDataWidth = 64;
  localparam int unsigned WideDataWidth = 512;

  localparam int unsigned NarrowIdWidthIn = 2;
  localparam int unsigned NrMasters = 3;
  localparam int unsigned NarrowIdWidthOut = $clog2(NrMasters) + NarrowIdWidthIn;

  localparam int unsigned NrDmaMasters = 2 + 1;
  localparam int unsigned WideIdWidthIn = 2;
  localparam int unsigned WideIdWidthOut = $clog2(NrDmaMasters) + WideIdWidthIn;

  localparam int unsigned UserWidth = 1;

  localparam int unsigned ICacheLineWidth [NrHives] = '{
    256
};
  localparam int unsigned ICacheLineCount [NrHives] = '{
    128
};
  localparam int unsigned ICacheSets [NrHives] = '{
    2
};

  localparam int unsigned Hive [NrCores] = '{0, 0, 0, 0, 0, 0, 0, 0, 0};

  typedef logic [AddrWidth-1:0]         addr_t;
  typedef logic [NarrowDataWidth-1:0]   data_t;
  typedef logic [NarrowDataWidth/8-1:0] strb_t;
  typedef logic [WideDataWidth-1:0]     data_dma_t;
  typedef logic [WideDataWidth/8-1:0]   strb_dma_t;
  typedef logic [NarrowIdWidthIn-1:0]   narrow_in_id_t;
  typedef logic [NarrowIdWidthOut-1:0]  narrow_out_id_t;
  typedef logic [WideIdWidthIn-1:0]     wide_in_id_t;
  typedef logic [WideIdWidthOut-1:0]    wide_out_id_t;
  typedef logic [UserWidth-1:0]         user_t;

  `AXI_TYPEDEF_ALL(narrow_in, addr_t, narrow_in_id_t, data_t, strb_t, user_t)
  `AXI_TYPEDEF_ALL(narrow_out, addr_t, narrow_out_id_t, data_t, strb_t, user_t)
  `AXI_TYPEDEF_ALL(wide_in, addr_t, wide_in_id_t, data_dma_t, strb_dma_t, user_t)
  `AXI_TYPEDEF_ALL(wide_out, addr_t, wide_out_id_t, data_dma_t, strb_dma_t, user_t)

  localparam snitch_pma_pkg::snitch_pma_t SnitchPMACfg = '{
      NrCachedRegionRules: 1,
      CachedRegion: '{
          '{base: 48'h80000000, mask: 48'h80000000}
      },
      default: 0
  };

  localparam fpnew_pkg::fpu_implementation_t FPUImplementation [9] = '{
    '{
        PipeRegs: // FMA Block
                  '{
                    '{  3, // FP32
                        3, // FP64
                        1, // FP16
                        1, // FP8
                        2, // FP16alt
                        1  // FP8alt
                      },
                    '{default: 1},   // DIVSQRT
                    '{default: 1},   // NONCOMP
                    '{default: 1},   // CONV
                    '{default: 1}},  // DOTP
        UnitTypes: '{'{default: fpnew_pkg::MERGED},  // FMA
                    '{default: fpnew_pkg::DISABLED}, // DIVSQRT
                    '{default: fpnew_pkg::PARALLEL}, // NONCOMP
                    '{default: fpnew_pkg::MERGED},   // CONV
                    '{default: fpnew_pkg::MERGED}},  // DOTP
        PipeConfig: fpnew_pkg::BEFORE
    },
    '{
        PipeRegs: // FMA Block
                  '{
                    '{  3, // FP32
                        3, // FP64
                        1, // FP16
                        1, // FP8
                        2  // FP16alt
                      },
                    '{default: 1},   // DIVSQRT
                    '{default: 1},   // NONCOMP
                    '{default: 1}},   // CONV
        UnitTypes: '{'{default: fpnew_pkg::MERGED},
                    '{default: fpnew_pkg::DISABLED}, // DIVSQRT
                    '{default: fpnew_pkg::PARALLEL}, // NONCOMP
                    '{default: fpnew_pkg::MERGED}},  // CONV
        PipeConfig: fpnew_pkg::BEFORE
    },
    '{
        PipeRegs: // FMA Block
                  '{
                    '{  3, // FP32
                        3, // FP64
                        1, // FP16
                        1, // FP8
                        2  // FP16alt
                      },
                    '{default: 1},   // DIVSQRT
                    '{default: 1},   // NONCOMP
                    '{default: 1}},   // CONV
        UnitTypes: '{'{default: fpnew_pkg::MERGED},
                    '{default: fpnew_pkg::DISABLED}, // DIVSQRT
                    '{default: fpnew_pkg::PARALLEL}, // NONCOMP
                    '{default: fpnew_pkg::MERGED}},  // CONV
        PipeConfig: fpnew_pkg::BEFORE
    },
    '{
        PipeRegs: // FMA Block
                  '{
                    '{  3, // FP32
                        3, // FP64
                        1, // FP16
                        1, // FP8
                        2  // FP16alt
                      },
                    '{default: 1},   // DIVSQRT
                    '{default: 1},   // NONCOMP
                    '{default: 1}},   // CONV
        UnitTypes: '{'{default: fpnew_pkg::MERGED},
                    '{default: fpnew_pkg::DISABLED}, // DIVSQRT
                    '{default: fpnew_pkg::PARALLEL}, // NONCOMP
                    '{default: fpnew_pkg::MERGED}},  // CONV
        PipeConfig: fpnew_pkg::BEFORE
    },
    '{
        PipeRegs: // FMA Block
                  '{
                    '{  3, // FP32
                        3, // FP64
                        1, // FP16
                        1, // FP8
                        2  // FP16alt
                      },
                    '{default: 1},   // DIVSQRT
                    '{default: 1},   // NONCOMP
                    '{default: 1}},   // CONV
        UnitTypes: '{'{default: fpnew_pkg::MERGED},
                    '{default: fpnew_pkg::DISABLED}, // DIVSQRT
                    '{default: fpnew_pkg::PARALLEL}, // NONCOMP
                    '{default: fpnew_pkg::MERGED}},  // CONV
        PipeConfig: fpnew_pkg::BEFORE
    },
    '{
        PipeRegs: // FMA Block
                  '{
                    '{  3, // FP32
                        3, // FP64
                        1, // FP16
                        1, // FP8
                        2  // FP16alt
                      },
                    '{default: 1},   // DIVSQRT
                    '{default: 1},   // NONCOMP
                    '{default: 1}},   // CONV
        UnitTypes: '{'{default: fpnew_pkg::MERGED},
                    '{default: fpnew_pkg::DISABLED}, // DIVSQRT
                    '{default: fpnew_pkg::PARALLEL}, // NONCOMP
                    '{default: fpnew_pkg::MERGED}},  // CONV
        PipeConfig: fpnew_pkg::BEFORE
    },
    '{
        PipeRegs: // FMA Block
                  '{
                    '{  3, // FP32
                        3, // FP64
                        1, // FP16
                        1, // FP8
                        2  // FP16alt
                      },
                    '{default: 1},   // DIVSQRT
                    '{default: 1},   // NONCOMP
                    '{default: 1}},   // CONV
        UnitTypes: '{'{default: fpnew_pkg::MERGED},
                    '{default: fpnew_pkg::DISABLED}, // DIVSQRT
                    '{default: fpnew_pkg::PARALLEL}, // NONCOMP
                    '{default: fpnew_pkg::MERGED}},  // CONV
        PipeConfig: fpnew_pkg::BEFORE
    },
    '{
        PipeRegs: // FMA Block
                  '{
                    '{  3, // FP32
                        3, // FP64
                        1, // FP16
                        1, // FP8
                        2  // FP16alt
                      },
                    '{default: 1},   // DIVSQRT
                    '{default: 1},   // NONCOMP
                    '{default: 1}},   // CONV
        UnitTypes: '{'{default: fpnew_pkg::MERGED},
                    '{default: fpnew_pkg::DISABLED}, // DIVSQRT
                    '{default: fpnew_pkg::PARALLEL}, // NONCOMP
                    '{default: fpnew_pkg::MERGED}},  // CONV
        PipeConfig: fpnew_pkg::BEFORE
    },
    '{
        PipeRegs: // FMA Block
                  '{
                    '{  3, // FP32
                        3, // FP64
                        1, // FP16
                        1, // FP8
                        2  // FP16alt
                      },
                    '{default: 1},   // DIVSQRT
                    '{default: 1},   // NONCOMP
                    '{default: 1}},   // CONV
        UnitTypes: '{'{default: fpnew_pkg::MERGED},
                    '{default: fpnew_pkg::DISABLED}, // DIVSQRT
                    '{default: fpnew_pkg::PARALLEL}, // NONCOMP
                    '{default: fpnew_pkg::MERGED}},  // CONV
        PipeConfig: fpnew_pkg::BEFORE
    }
  };

  localparam snitch_ssr_pkg::ssr_cfg_t [3-1:0] SsrCfgs [9] = '{
    '{'{1, 0, 0, 1, 1, 1, 4, 16, 18, 3, 4, 3, 8, 4, 3},
      '{1, 1, 1, 0, 1, 1, 4, 16, 18, 3, 4, 3, 8, 4, 3},
      '{1, 1, 0, 0, 1, 1, 4, 16, 18, 3, 4, 3, 8, 4, 3}},
    '{'{1, 0, 0, 1, 1, 1, 4, 16, 18, 3, 4, 3, 8, 4, 3},
      '{1, 1, 1, 0, 1, 1, 4, 16, 18, 3, 4, 3, 8, 4, 3},
      '{1, 1, 0, 0, 1, 1, 4, 16, 18, 3, 4, 3, 8, 4, 3}},
    '{'{1, 0, 0, 1, 1, 1, 4, 16, 18, 3, 4, 3, 8, 4, 3},
      '{1, 1, 1, 0, 1, 1, 4, 16, 18, 3, 4, 3, 8, 4, 3},
      '{1, 1, 0, 0, 1, 1, 4, 16, 18, 3, 4, 3, 8, 4, 3}},
    '{'{1, 0, 0, 1, 1, 1, 4, 16, 18, 3, 4, 3, 8, 4, 3},
      '{1, 1, 1, 0, 1, 1, 4, 16, 18, 3, 4, 3, 8, 4, 3},
      '{1, 1, 0, 0, 1, 1, 4, 16, 18, 3, 4, 3, 8, 4, 3}},
    '{'{1, 0, 0, 1, 1, 1, 4, 16, 18, 3, 4, 3, 8, 4, 3},
      '{1, 1, 1, 0, 1, 1, 4, 16, 18, 3, 4, 3, 8, 4, 3},
      '{1, 1, 0, 0, 1, 1, 4, 16, 18, 3, 4, 3, 8, 4, 3}},
    '{'{1, 0, 0, 1, 1, 1, 4, 16, 18, 3, 4, 3, 8, 4, 3},
      '{1, 1, 1, 0, 1, 1, 4, 16, 18, 3, 4, 3, 8, 4, 3},
      '{1, 1, 0, 0, 1, 1, 4, 16, 18, 3, 4, 3, 8, 4, 3}},
    '{'{1, 0, 0, 1, 1, 1, 4, 16, 18, 3, 4, 3, 8, 4, 3},
      '{1, 1, 1, 0, 1, 1, 4, 16, 18, 3, 4, 3, 8, 4, 3},
      '{1, 1, 0, 0, 1, 1, 4, 16, 18, 3, 4, 3, 8, 4, 3}},
    '{'{1, 0, 0, 1, 1, 1, 4, 16, 18, 3, 4, 3, 8, 4, 3},
      '{1, 1, 1, 0, 1, 1, 4, 16, 18, 3, 4, 3, 8, 4, 3},
      '{1, 1, 0, 0, 1, 1, 4, 16, 18, 3, 4, 3, 8, 4, 3}},
    '{/*None*/ '0,
      /*None*/ '0,
      /*None*/ '0}
  };

  localparam logic [3-1:0][4:0] SsrRegs [9] = '{
    '{2, 1, 0},
    '{2, 1, 0},
    '{2, 1, 0},
    '{2, 1, 0},
    '{2, 1, 0},
    '{2, 1, 0},
    '{2, 1, 0},
    '{2, 1, 0},
    '{/*None*/ 0, /*None*/ 0, /*None*/ 0}
  };

endpackage
// verilog_lint: waive-stop package-filename

module occamy_cluster_wrapper (
  input  logic                                   clk_i,
  input  logic                                   rst_ni,
  input  logic [occamy_cluster_pkg::NrCores-1:0] debug_req_i,
  input  logic [occamy_cluster_pkg::NrCores-1:0] meip_i,
  input  logic [occamy_cluster_pkg::NrCores-1:0] mtip_i,
  input  logic [occamy_cluster_pkg::NrCores-1:0] msip_i,
  input  logic [9:0]                             hart_base_id_i,
  input  logic [47:0]                            cluster_base_addr_i,
  input  logic                                   clk_d2_bypass_i,
  input  occamy_cluster_pkg::narrow_in_req_t     narrow_in_req_i,
  output occamy_cluster_pkg::narrow_in_resp_t    narrow_in_resp_o,
  output occamy_cluster_pkg::narrow_out_req_t    narrow_out_req_o,
  input  occamy_cluster_pkg::narrow_out_resp_t   narrow_out_resp_i,
  output occamy_cluster_pkg::wide_out_req_t      wide_out_req_o,
  input  occamy_cluster_pkg::wide_out_resp_t     wide_out_resp_i,
  input  occamy_cluster_pkg::wide_in_req_t       wide_in_req_i,
  output occamy_cluster_pkg::wide_in_resp_t      wide_in_resp_o
);

  localparam int unsigned NumIntOutstandingLoads [9] = '{1, 1, 1, 1, 1, 1, 1, 1, 1};
  localparam int unsigned NumIntOutstandingMem [9] = '{4, 4, 4, 4, 4, 4, 4, 4, 4};
  localparam int unsigned NumFPOutstandingLoads [9] = '{4, 4, 4, 4, 4, 4, 4, 4, 4};
  localparam int unsigned NumFPOutstandingMem [9] = '{4, 4, 4, 4, 4, 4, 4, 4, 4};
  localparam int unsigned NumDTLBEntries [9] = '{1, 1, 1, 1, 1, 1, 1, 1, 1};
  localparam int unsigned NumITLBEntries [9] = '{1, 1, 1, 1, 1, 1, 1, 1, 1};
  localparam int unsigned NumSequencerInstr [9] = '{16, 16, 16, 16, 16, 16, 16, 16, 16};
  localparam int unsigned NumSsrs [9] = '{3, 3, 3, 3, 3, 3, 3, 3, 1};
  localparam int unsigned SsrMuxRespDepth [9] = '{4, 4, 4, 4, 4, 4, 4, 4, 4};

  // Snitch cluster under test.
  snitch_cluster #(
    .PhysicalAddrWidth (48),
    .NarrowDataWidth (64),
    .WideDataWidth (512),
    .NarrowIdWidthIn (occamy_cluster_pkg::NarrowIdWidthIn),
    .WideIdWidthIn (occamy_cluster_pkg::WideIdWidthIn),
    .UserWidth (occamy_cluster_pkg::UserWidth),
    .BootAddr (32'h1000000),
    .narrow_in_req_t (occamy_cluster_pkg::narrow_in_req_t),
    .narrow_in_resp_t (occamy_cluster_pkg::narrow_in_resp_t),
    .narrow_out_req_t (occamy_cluster_pkg::narrow_out_req_t),
    .narrow_out_resp_t (occamy_cluster_pkg::narrow_out_resp_t),
    .wide_out_req_t (occamy_cluster_pkg::wide_out_req_t),
    .wide_out_resp_t (occamy_cluster_pkg::wide_out_resp_t),
    .wide_in_req_t (occamy_cluster_pkg::wide_in_req_t),
    .wide_in_resp_t (occamy_cluster_pkg::wide_in_resp_t),
    .NrHives (1),
    .NrCores (9),
    .TCDMDepth (512),
    .NrBanks (32),
    .DMAAxiReqFifoDepth (3),
    .DMAReqFifoDepth (3),
    .ICacheLineWidth (occamy_cluster_pkg::ICacheLineWidth),
    .ICacheLineCount (occamy_cluster_pkg::ICacheLineCount),
    .ICacheSets (occamy_cluster_pkg::ICacheSets),
    .RVE (9'b000000000),
    .RVF (9'b011111111),
    .RVD (9'b011111111),
    .XDivSqrt (9'b000000000),
    .XF16 (9'b011111111),
    .XF16ALT (9'b011111111),
    .XF8 (9'b011111111),
    .XF8ALT (9'b011111111),
    .XFVEC (9'b011111111),
    .XFDOTP (9'b011111111),
    .Xdma (9'b100000000),
    .Xssr (9'b011111111),
    .Xfrep (9'b011111111),
    .FPUImplementation (occamy_cluster_pkg::FPUImplementation),
    .SnitchPMACfg (occamy_cluster_pkg::SnitchPMACfg),
    .NumIntOutstandingLoads (NumIntOutstandingLoads),
    .NumIntOutstandingMem (NumIntOutstandingMem),
    .NumFPOutstandingLoads (NumFPOutstandingLoads),
    .NumFPOutstandingMem (NumFPOutstandingMem),
    .NumDTLBEntries (NumDTLBEntries),
    .NumITLBEntries (NumITLBEntries),
    .NumSsrsMax (3),
    .NumSsrs (NumSsrs),
    .SsrMuxRespDepth (SsrMuxRespDepth),
    .SsrRegs (occamy_cluster_pkg::SsrRegs),
    .SsrCfgs (occamy_cluster_pkg::SsrCfgs),
    .NumSequencerInstr (NumSequencerInstr),
    .Hive (occamy_cluster_pkg::Hive),
    .Topology (snitch_pkg::LogarithmicInterconnect),
    .Radix (2),
    .RegisterOffloadReq (1),
    .RegisterOffloadRsp (1),
    .RegisterCoreReq (1),
    .RegisterCoreRsp (1),
    .RegisterTCDMCuts (0),
    .RegisterExtWide (1),
    .RegisterExtNarrow (1),
    .RegisterFPUReq (1),
    .RegisterSequencer (0),
    .IsoCrossing (0),
    .NarrowXbarLatency (axi_pkg::CUT_ALL_PORTS),
    .WideXbarLatency (axi_pkg::CUT_ALL_PORTS)
  ) i_cluster (
    .clk_i,
    .rst_ni,
    .debug_req_i,
    .meip_i,
    .mtip_i,
    .msip_i,
    .hart_base_id_i,
    .cluster_base_addr_i,
    .clk_d2_bypass_i,
    .narrow_in_req_i,
    .narrow_in_resp_o,
    .narrow_out_req_o,
    .narrow_out_resp_i,
    .wide_out_req_o,
    .wide_out_resp_i,
    .wide_in_req_i,
    .wide_in_resp_o
  );
endmodule
