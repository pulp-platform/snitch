// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Noah Huetter <noahhuetter@gmail.com>

`ifdef VERILATOR
`define REPACK_SNITCH_CC
`endif

// -- default case
// parameter type type_t = dflt,
// inout type_t type_io,
// module name #(
//   .type_t(type_t)
// ) (
//   .type_io(type_io)
// );

// -- verilator case
// parameter int unsigned type_t = dflt,
// inout logic[type_t-1:0] type_io,
// module name #(
//   .type_t($bits(type_t))
// ) (
//   .type_io(type_io)
// );

// -- verilator case
// parameter type type_t = dflt,
// inout type_t type_io,

`define TYPE_PARAMETER(type_t, dflt)  \
`ifndef REPACK_SNITCH_CC              \
  parameter type         type_t             = dflt                     \
`else \
  parameter int unsigned type_t          = $bits(dflt) \
`endif

`define TYPE_PORT(type_t)  \
`ifndef REPACK_SNITCH_CC              \
  type_t  \
`else \
  logic[type_t-1:0]  \
`endif

`define TYPE_PARAMETER_INST(type_t)  \
`ifndef REPACK_SNITCH_CC              \
  type_t \
`else \
  $bits(type_t) \
`endif

`define TYPE_PARAMETER_INST_W(type_t, lcl_type_t)  \
`ifndef REPACK_SNITCH_CC              \
  type_t \
`else \
  lcl_type_t \
`endif

`define STRUCT_PORT(struct_t)  \
`ifndef REPACK_SNITCH_CC              \
  struct_t                     \
`else                          \
  logic[$bits(struct_t)-1:0]   \
`endif

// explode

// typedef logic [AddrWidth-1:0] addr_t;
// typedef logic [DataWidth-1:0] data_t;
// typedef logic [DataWidth/8-1:0] strb_t;

// `REQRSP_TYPEDEF_REQ_CHAN_T(req_chan_t, addr_t, data_t, strb_t)

// `define REQRSP_TYPEDEF_ALL(__name, __addr_t, __data_t, __strb_t) \
//   `REQRSP_TYPEDEF_REQ_CHAN_T(__name``_req_chan_t, __addr_t, __data_t, __strb_t) \
//   `REQRSP_TYPEDEF_RSP_CHAN_T(__name``_rsp_chan_t, __data_t) \
//   `REQRSP_TYPEDEF_REQ_T(__name``_req_t, __name``_req_chan_t) \
//   `REQRSP_TYPEDEF_RSP_T(__name``_rsp_t, __name``_rsp_chan_t)

// `define REQRSP_TYPEDEF_REQ_CHAN_T(__req_chan_t, __addr_t, __data_t, __strb_t) \
//   typedef struct packed { \
//     __addr_t             addr;  \
//     logic                write; \
//     reqrsp_pkg::amo_op_e amo;   \
//     __data_t             data;  \
//     __strb_t             strb;  \
//     reqrsp_pkg::size_t   size;  \
//   } __req_chan_t;

// `define REQRSP_TYPEDEF_RSP_CHAN_T(__rsp_chan_t, __data_t) \
//   typedef struct packed { \
//     __data_t data;        \
//      logic  error;       \
//   } __rsp_chan_t;

// `define REQRSP_TYPEDEF_REQ_T(__req_t, __req_chan_t) \
//   typedef struct packed { \
//     __req_chan_t q;       \
//     logic      q_valid; \
//     logic      p_ready; \
//   } __req_t;

// `define REQRSP_TYPEDEF_RSP_T(__rsp_t, __rsp_chan_t) \
//   typedef struct packed { \
//     __rsp_chan_t p;       \
//     logic      p_valid; \
//     logic      q_ready; \
//   } __rsp_t;
