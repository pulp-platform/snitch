// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Nils Wistoff <nwistoff@iis.ee.ethz.ch>
//
// Macros for assigning flattened APB ports to req/resp APB structs
// Flat APB ports are required by the Vivado IP Integrator. Vivado naming convention is followed.

`define APB_FLATTEN_MASTER(pat, req, rsp)     \
  assign m_apb_``pat``_paddr   = req.paddr;   \
  assign m_apb_``pat``_pprot   = req.pprot;   \
  assign m_apb_``pat``_psel    = req.psel;    \
  assign m_apb_``pat``_penable = req.penable; \
  assign m_apb_``pat``_pwrite  = req.pwrite;  \
  assign m_apb_``pat``_pwdata  = req.pwdata;  \
  assign m_apb_``pat``_pstrb   = req.pstrb;   \
                                              \
  assign rsp.pready = m_apb_``pat``_pready;   \
  assign rsp.prdata = m_apb_``pat``_prdata;   \
  assign rsp.pslverr = m_apb_``pat``_pslverr;


`define APB_FLATTEN_SLAVE(pat, req, rsp)      \
  assign req.paddr   = s_apb_``pat``_paddr;   \
  assign req.pprot   = s_apb_``pat``_pprot;   \
  assign req.penable = s_apb_``pat``_penable; \
  assign req.psel    = s_apb_``pat``_psel;    \
  assign req.pwrite  = s_apb_``pat``_pwrite;  \
  assign req.pwdata  = s_apb_``pat``_pwdata;  \
  assign req.pstrb   = s_apb_``pat``_pstrb;   \
                                              \
  assign s_apb_``pat``_pready  = rsp.pready;  \
  assign s_apb_``pat``_prdata  = rsp.prdata;  \
  assign s_apb_``pat``_pslverr = rsp.pslverr;
