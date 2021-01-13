// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>
// Author: Fabian Schuiki <fschuiki@iis.ee.ethz.ch>

// Macros to assign MEM Interfaces and Structs

`ifndef MEM_ASSIGN_SVH_
`define MEM_ASSIGN_SVH_

// Assign an MEM handshake.
`define MEM_ASSIGN_VALID(__opt_as, __dst, __src, __chan) \
  __opt_as ``__dst``.``__chan``_valid   = ``__src``.``__chan``_valid;
`define MEM_ASSIGN_READY(__opt_as, __dst, __src, __chan) \
  __opt_as ``__dst``.``__chan``_ready   = ``__src``.``__chan``_ready;

`define MEM_ASSIGN_HANDSHAKE(__opt_as, __dst, __src, __chan) \
  `MEM_ASSIGN_VALID(__opt_as, __dst, __src, __chan)          \
  `MEM_ASSIGN_READY(__opt_as, __src, __dst, __chan)

////////////////////////////////////////////////////////////////////////////////////////////////////
// Assigning one MEM interface to another, as if you would do `assign slv =
// mst;`
//
// The channel assignments `MEM_ASSIGN_XX(dst, src)` assign all payload and
// the valid signal of the `XX` channel from the `src` to the `dst` interface
// and they assign the ready signal from the `src` to the `dst` interface. The
// interface assignment `MEM_ASSIGN(dst, src)` assigns all channels including
// handshakes as if `src` was the master of `dst`.
//
// Usage Example: `MEM_ASSIGN(slv, mst) `MEM_ASSIGN_Q(dst, src, aw)
// `MEM_ASSIGN_P(dst, src)
`define MEM_ASSIGN_Q_CHAN(__opt_as, dst, src, __sep_dst, __sep_src) \
  __opt_as dst.q``__sep_dst``addr  = src.q``__sep_src``addr;           \
  __opt_as dst.q``__sep_dst``write = src.q``__sep_src``write;          \
  __opt_as dst.q``__sep_dst``amo   = src.q``__sep_src``amo;            \
  __opt_as dst.q``__sep_dst``data  = src.q``__sep_src``data;           \
  __opt_as dst.q``__sep_dst``strb  = src.q``__sep_src``strb;           \
  __opt_as dst.q``__sep_dst``user  = src.q``__sep_src``user;
`define MEM_ASSIGN_P_CHAN(__opt_as, dst, src, __sep_dst, __sep_src) \
  __opt_as dst.p``__sep_dst``data   = src.p``__sep_src``data;
`define MEM_ASSIGN(slv, mst)                 \
  `MEM_ASSIGN_Q_CHAN(assign, slv, mst, _, _) \
  `MEM_ASSIGN_HANDSHAKE(assign, slv, mst, q) \
  `MEM_ASSIGN_P_CHAN(assign, mst, slv, _, _)
////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////
// Assigning an interface from channel or request/response structs outside a
// process.
//
// The request macro `MEM_ASSIGN_FROM_REQ(MEM_if, req_struct)` assigns the
// request channel and the request-side handshake signals of the `MEM_if`
// interface from the signals in `req_struct`. The response macro
// `MEM_ASSIGN_FROM_RESP(MEM_if, resp_struct)` assigns the response
// channel and the response-side handshake signals of the `MEM_if` interface
// from the signals in `resp_struct`.
//
// Usage Example:
// `MEM_ASSIGN_FROM_REQ(my_if, my_req_struct)
`define MEM_ASSIGN_FROM_REQ(MEM_if, req_struct)        \
  `MEM_ASSIGN_VALID(assign, MEM_if, req_struct, q)     \
  `MEM_ASSIGN_Q_CHAN(assign, MEM_if, req_struct, _, .)

`define MEM_ASSIGN_FROM_RESP(MEM_if, resp_struct)       \
  `MEM_ASSIGN_READY(assign, MEM_if, resp_struct, q)     \
  `MEM_ASSIGN_P_CHAN(assign, MEM_if, resp_struct, _, .)

////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////
// Assigning channel or request/response structs from an interface outside a
// process.
//
// The request macro `MEM_ASSIGN_TO_REQ(MEM_if, req_struct)` assigns all
// signals of `req_struct` payload and request-side handshake signals to the
// signals in the `MEM_if` interface. The response macro
// `MEM_ASSIGN_TO_RESP(MEM_if, resp_struct)` assigns all signals of
// `resp_struct` payload and response-side handshake signals to the signals in
// the `MEM_if` interface.
//
// Usage Example:
// `MEM_ASSIGN_TO_REQ(my_req_struct, my_if)
`define MEM_ASSIGN_TO_REQ(req_struct, MEM_if)          \
  `MEM_ASSIGN_VALID(assign, req_struct, MEM_if, q)     \
  `MEM_ASSIGN_Q_CHAN(assign, req_struct, MEM_if, ., _)

`define MEM_ASSIGN_TO_RESP(resp_struct, MEM_if)         \
  `MEM_ASSIGN_READY(assign, resp_struct, MEM_if, q)     \
  `MEM_ASSIGN_P_CHAN(assign, resp_struct, MEM_if, ., _)
////////////////////////////////////////////////////////////////////////////////////////////////////

`endif
