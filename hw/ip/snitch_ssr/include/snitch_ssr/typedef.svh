// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Paul Scheffler <paulsc@iis.ee.ethz.ch>

`ifndef SSR_TYPEDEF_SVH_
`define SSR_TYPEDEF_SVH_

`define SSR_ISECT_TYPEDEF_MST_REQ_T(__req_t, __index_t) \
  typedef struct packed { \
    logic     merge;  \
    logic     slv_ena;  \
    __index_t idx;    \
    logic     done;   \
    logic     valid;  \
  } __req_t;

`define SSR_ISECT_TYPEDEF_MST_RSP_T(__rsp_t) \
  typedef struct packed { \
    logic     zero;   \
    logic     skip;   \
    logic     done;   \
    logic     ready;  \
  } __rsp_t;

`define SSR_ISECT_TYPEDEF_SLV_REQ_T(__req_t) \
  typedef struct packed { \
    logic     ena;    \
    logic     ready;  \
  } __req_t;


`define SSR_ISECT_TYPEDEF_SLV_RSP_T(__rsp_t, __index_t) \
  typedef struct packed { \
    __index_t idx;    \
    logic     done;   \
    logic     valid;  \
  } __rsp_t;

`define SSR_ISECT_TYPEDEF_ALL(__name, __index_t) \
  `SSR_ISECT_TYPEDEF_MST_REQ_T(__name``_mst_req_t, __index_t)  \
  `SSR_ISECT_TYPEDEF_MST_RSP_T(__name``_mst_rsp_t)             \
  `SSR_ISECT_TYPEDEF_SLV_REQ_T(__name``_slv_req_t)             \
  `SSR_ISECT_TYPEDEF_SLV_RSP_T(__name``_slv_rsp_t, __index_t)

`endif
