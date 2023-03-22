// Copyright 2018-2021 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Paul Scheffler <paulsc@iis.ee.ethz.ch>

// Macros to define AXI TLB types and structs

`ifndef AXI_TLB_TYPEDEF_SVH_
`define AXI_TLB_TYPEDEF_SVH_

////////////////////////////////////////////////////////////////////////////////////////////////////
// AXI4 TLB type definitions
//
// Fields
// * read_only: Defines whether this entry can only be used for read accesses.
// * valid:     Defines whether this entry is valid.
// * base:      Number of first page in output address segment; that is,
//              the output address segment starts at this `base` page.
// * last:      Number of last page (inclusive) in input address segment
// * first:     Number of first page in input address segment
`define AXI_TLB_TYPEDEF_ENTRY_T(entry_t, oup_page_t, inp_page_t)  \
  typedef struct packed {                                         \
    logic       read_only;                                        \
    logic       valid;                                            \
    oup_page_t  base;                                             \
    inp_page_t  last;                                             \
    inp_page_t  first;                                            \
  } entry_t;
////////////////////////////////////////////////////////////////////////////////////////////////////

`define AXI_TLB_TYPEDEF_ALL(__name, __oup_page_t, __inp_page_t) \
  `AXI_TLB_TYPEDEF_ENTRY_T(__name``_entry_t, __oup_page_t, __inp_page_t)

`endif
