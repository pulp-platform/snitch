// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Paul Scheffler <paulsc@iis.ee.ethz.ch>

// Types and fixed constants for SSRs.

package snitch_ssr_pkg;

  // Passed parameters for individual SSRs
  typedef struct packed {
    bit           Indirection;
    bit           IsectMaster;
    bit           IsectMasterIdx;
    bit           IsectSlave;
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

  // Derived parameters for intersection
  typedef struct packed {
    int unsigned  IndexWidth;
    int unsigned  NumMaster0;
    int unsigned  NumMaster1;
    int unsigned  NumSlave;
    int unsigned  IdxMaster0;
    int unsigned  IdxMaster1;
    int unsigned  IdxSlave;
  } isect_cfg_t;

  // Fields used in addresses of upper alias registers
  // *Not* the same order as alias address, but as in upper status fields
  typedef struct packed {
    logic no_indir;
    logic write;
    logic [1:0] dims;
  } cfg_alias_fields_t;

  // Upper fields accessible on status register
  typedef struct packed {
    logic done;
    logic write;
    logic [1:0] dims;
    logic indir;
  } cfg_status_upper_t;

endpackage
