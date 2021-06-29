// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

// Macros to assign SPM Interfaces

`ifndef SPM_ASSIGN_SVH_
`define SPM_ASSIGN_SVH_

`define SPM_ASSIGN_REQ_CHAN(dst, src) \
  assign dst.addr  = src.addr;        \
  assign dst.we    = src.we  ;        \
  assign dst.wdata = src.wdata;       \
  assign dst.strb  = src.strb;        \
  assign dst.valid = src.valid;

`define SPM_ASSIGN_RSP_CHAN(dst, src) \
  assign dst.ready  = src.ready;        \
  assign dst.rvalid = src.rvalid;     \
  assign dst.rdata  = src.rdata;

`define SPM_ASSIGN(slv, mst)         \
  `SPM_ASSIGN_REQ_CHAN(slv, mst)     \
  `SPM_ASSIGN_RSP_CHAN(mst, slv)

`endif
