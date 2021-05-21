// Copyright (c) 2020 ETH Zurich, University of Bologna
//
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// Author:
// Wolfgang Roenninger  <wroennin@student.ethz.ch>

// Macros to define APB4 Request/Response Structs

`ifndef APB_TYPEDEF_SVH_
`define APB_TYPEDEF_SVH_

////////////////////////////////////////////////////////////////////////////////////////////////////
// APB4 (v2.0) Request/Response Structs
//
// Usage Example:
// `APB_TYPEDEF_REQ_T  ( apb_req_t,  addr_t, data_t, strb_t )
// `APB_TYPEDEF_RESP_T ( apb_resp_t, data_t )
`define APB_TYPEDEF_REQ_T(apb_req_t, addr_t, data_t, strb_t)  \
  typedef struct packed {                                     \
    addr_t          paddr;                                    \
    apb_pkg::prot_t pprot;                                    \
    logic           psel;                                     \
    logic           penable;                                  \
    logic           pwrite;                                   \
    data_t          pwdata;                                   \
    strb_t          pstrb;                                    \
  } apb_req_t;
`define APB_TYPEDEF_RESP_T(apb_resp_t, data_t) \
  typedef struct packed {                      \
    logic  pready;                             \
    data_t prdata;                             \
    logic  pslverr;                            \
    } apb_resp_t;
////////////////////////////////////////////////////////////////////////////////////////////////////

`endif
