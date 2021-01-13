// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>
// Author: Fabian Schuiki <fschuiki@iis.ee.ethz.ch>

`ifndef TCDM_INTERFACE_TYPEDEF_SVH_
`define TCDM_INTERFACE_TYPEDEF_SVH_

`define TCDM_TYPEDEF_REQ_CHAN_T(__req_chan_t, __addr_t, __data_t, __strb_t, __user_t) \
  typedef struct packed { \
    __addr_t             addr;  \
    logic                write; \
    reqrsp_pkg::amo_op_e amo;   \
    __data_t             data;  \
    __strb_t             strb;  \
    __user_t             user;  \
  } __req_chan_t;

`define TCDM_TYPEDEF_RSP_CHAN_T(__rsp_chan_t, __data_t) \
  typedef struct packed { \
    __data_t data;        \
  } __rsp_chan_t;

`define TCDM_TYPEDEF_REQ_T(__req_t, __req_chan_t) \
  typedef struct packed { \
    __req_chan_t q;       \
    logic        q_valid; \
  } __req_t;

`define TCDM_TYPEDEF_RSP_T(__rsp_t, __rsp_chan_t) \
  typedef struct packed { \
    __rsp_chan_t p;       \
    logic        p_valid; \
    logic        q_ready; \
  } __rsp_t;

`define TCDM_TYPEDEF_ALL(__name, __addr_t, __data_t, __strb_t, __user_t) \
  `TCDM_TYPEDEF_REQ_CHAN_T(__name``_req_chan_t, __addr_t, __data_t, __strb_t, __user_t) \
  `TCDM_TYPEDEF_RSP_CHAN_T(__name``_rsp_chan_t, __data_t) \
  `TCDM_TYPEDEF_REQ_T(__name``_req_t, __name``_req_chan_t) \
  `TCDM_TYPEDEF_RSP_T(__name``_rsp_t, __name``_rsp_chan_t)

`endif
