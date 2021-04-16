// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Paul Scheffler <paulsc@iis.ee.ethz.ch>

// Types and fixed constants for SSRs.

package snitch_ssr_pkg;

  typedef struct packed {
    bit           Indirection;
    bit           IndirOutSpill;
    int unsigned  NumLoops;
    int unsigned  IndexWidth;
    int unsigned  PointerWidth;
    int unsigned  ShiftWidth;
    int unsigned  RptWidth;
    int unsigned  IndexCredits;
    int unsigned  DataCredits;
    int unsigned  MuxRespDepth;
  } ssr_cfg_t;

endpackage
