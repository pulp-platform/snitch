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
    bit           IsectSlaveSpill;
    bit           IndirOutSpill;
    int unsigned  NumLoops;
    int unsigned  IndexWidth;
    int unsigned  PointerWidth;
    int unsigned  ShiftWidth;
    int unsigned  RptWidth;
    int unsigned  IndexCredits;
    int unsigned  IsectSlaveCredits;
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
    int unsigned  StreamctlDepth;
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

  // Indexing control flags
  typedef struct packed {
    logic merge;
  } idx_flags_t;

  // Layout of indexing control register
  typedef struct packed {
    idx_flags_t flags;
    logic [7:0] shift;
    logic [7:0] size;
  } cfg_idx_ctl_t;

endpackage
