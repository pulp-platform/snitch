// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Nils Wistoff <nwistoff@iis.ee.ethz.ch>
//
// Macros for instantiating flattened AXI ports and assigning them to req/resp AXI structs
// Flat AXI ports are required by the Vivado IP Integrator. Vivado naming convention is followed.

`define AXI_FLAT_MASTER_PORT(pat, addr_t, id_t, data_t, strb_t, user_t) \
  output logic             m_axi_``pat``_awvalid,  \
  output id_t              m_axi_``pat``_awid,     \
  output addr_t            m_axi_``pat``_awaddr,   \
  output axi_pkg::len_t    m_axi_``pat``_awlen,    \
  output axi_pkg::size_t   m_axi_``pat``_awsize,   \
  output axi_pkg::burst_t  m_axi_``pat``_awburst,  \
  output logic             m_axi_``pat``_awlock,   \
  output axi_pkg::cache_t  m_axi_``pat``_awcache,  \
  output axi_pkg::prot_t   m_axi_``pat``_awprot,   \
  output axi_pkg::qos_t    m_axi_``pat``_awqos,    \
  output axi_pkg::region_t m_axi_``pat``_awregion, \
  // output axi_pkg::atop_t   m_axi_``pat``_awatop,   \
  output user_t            m_axi_``pat``_awuser,   \
                                                   \
  output logic             m_axi_``pat``_wvalid,   \
  output data_t            m_axi_``pat``_wdata,    \
  output strb_t            m_axi_``pat``_wstrb,    \
  output logic             m_axi_``pat``_wlast,    \
  output user_t            m_axi_``pat``_wuser,    \
                                                   \
  output logic             m_axi_``pat``_bready,   \
                                                   \
  output logic             m_axi_``pat``_arvalid,  \
  output id_t              m_axi_``pat``_arid,     \
  output addr_t            m_axi_``pat``_araddr,   \
  output axi_pkg::len_t    m_axi_``pat``_arlen,    \
  output axi_pkg::size_t   m_axi_``pat``_arsize,   \
  output axi_pkg::burst_t  m_axi_``pat``_arburst,  \
  output logic             m_axi_``pat``_arlock,   \
  output axi_pkg::cache_t  m_axi_``pat``_arcache,  \
  output axi_pkg::prot_t   m_axi_``pat``_arprot,   \
  output axi_pkg::qos_t    m_axi_``pat``_arqos,    \
  output axi_pkg::region_t m_axi_``pat``_arregion, \
  output user_t            m_axi_``pat``_aruser,   \
                                                   \
  output logic             m_axi_``pat``_rready,   \
                                                   \
  input  logic             m_axi_``pat``_awready,  \
  input  logic             m_axi_``pat``_arready,  \
  input  logic             m_axi_``pat``_wready,   \
                                                   \
  input  logic             m_axi_``pat``_bvalid,   \
  input  id_t              m_axi_``pat``_bid,      \
  input  axi_pkg::resp_t   m_axi_``pat``_bresp,    \
  input  user_t            m_axi_``pat``_buser,    \
                                                   \
  input  logic             m_axi_``pat``_rvalid,   \
  input  id_t              m_axi_``pat``_rid,      \
  input  data_t            m_axi_``pat``_rdata,    \
  input  axi_pkg::resp_t   m_axi_``pat``_rresp,    \
  input  logic             m_axi_``pat``_rlast,    \
  input  user_t            m_axi_``pat``_ruser


`define AXI_FLAT_SLAVE_PORT(pat, addr_t, id_t, data_t, strb_t, user_t) \
  input logic             s_axi_``pat``_awvalid,  \
  input id_t              s_axi_``pat``_awid,     \
  input addr_t            s_axi_``pat``_awaddr,   \
  input axi_pkg::len_t    s_axi_``pat``_awlen,    \
  input axi_pkg::size_t   s_axi_``pat``_awsize,   \
  input axi_pkg::burst_t  s_axi_``pat``_awburst,  \
  input logic             s_axi_``pat``_awlock,   \
  input axi_pkg::cache_t  s_axi_``pat``_awcache,  \
  input axi_pkg::prot_t   s_axi_``pat``_awprot,   \
  input axi_pkg::qos_t    s_axi_``pat``_awqos,    \
  input axi_pkg::region_t s_axi_``pat``_awregion, \
  // input axi_pkg::atop_t   s_axi_``pat``_awatop,   \
  input user_t            s_axi_``pat``_awuser,   \
                                                  \
  input logic             s_axi_``pat``_wvalid,   \
  input data_t            s_axi_``pat``_wdata,    \
  input strb_t            s_axi_``pat``_wstrb,    \
  input logic             s_axi_``pat``_wlast,    \
  input user_t            s_axi_``pat``_wuser,    \
                                                  \
  input logic             s_axi_``pat``_bready,   \
                                                  \
  input logic             s_axi_``pat``_arvalid,  \
  input id_t              s_axi_``pat``_arid,     \
  input addr_t            s_axi_``pat``_araddr,   \
  input axi_pkg::len_t    s_axi_``pat``_arlen,    \
  input axi_pkg::size_t   s_axi_``pat``_arsize,   \
  input axi_pkg::burst_t  s_axi_``pat``_arburst,  \
  input logic             s_axi_``pat``_arlock,   \
  input axi_pkg::cache_t  s_axi_``pat``_arcache,  \
  input axi_pkg::prot_t   s_axi_``pat``_arprot,   \
  input axi_pkg::qos_t    s_axi_``pat``_arqos,    \
  input axi_pkg::region_t s_axi_``pat``_arregion, \
  input user_t            s_axi_``pat``_aruser,   \
                                                  \
  input logic             s_axi_``pat``_rready,   \
                                                  \
  output logic            s_axi_``pat``_awready,  \
  output logic            s_axi_``pat``_arready,  \
  output logic            s_axi_``pat``_wready,   \
                                                  \
  output logic            s_axi_``pat``_bvalid,   \
  output id_t             s_axi_``pat``_bid,      \
  output axi_pkg::resp_t  s_axi_``pat``_bresp,    \
  output user_t           s_axi_``pat``_buser,    \
                                                  \
  output logic            s_axi_``pat``_rvalid,   \
  output id_t             s_axi_``pat``_rid,      \
  output data_t           s_axi_``pat``_rdata,    \
  output axi_pkg::resp_t  s_axi_``pat``_rresp,    \
  output logic            s_axi_``pat``_rlast,    \
  output user_t           s_axi_``pat``_ruser


`define AXI_FLATTEN_MASTER(pat, req, rsp)        \
  assign m_axi_``pat``_awvalid  = req.aw_valid;  \
  assign m_axi_``pat``_awid     = req.aw.id;     \
  assign m_axi_``pat``_awaddr   = req.aw.addr;   \
  assign m_axi_``pat``_awlen    = req.aw.len;    \
  assign m_axi_``pat``_awsize   = req.aw.size;   \
  assign m_axi_``pat``_awburst  = req.aw.burst;  \
  assign m_axi_``pat``_awlock   = req.aw.lock;   \
  assign m_axi_``pat``_awcache  = req.aw.cache;  \
  assign m_axi_``pat``_awprot   = req.aw.prot;   \
  assign m_axi_``pat``_awqos    = req.aw.qos;    \
  assign m_axi_``pat``_awregion = req.aw.region; \
  // assign m_axi_``pat``_awatop   = req.aw.atop;   \
  assign m_axi_``pat``_awuser   = req.aw.user;   \
                                                 \
  assign m_axi_``pat``_wvalid   = req.w_valid;   \
  assign m_axi_``pat``_wdata    = req.w.data;    \
  assign m_axi_``pat``_wstrb    = req.w.strb;    \
  assign m_axi_``pat``_wlast    = req.w.last;    \
  assign m_axi_``pat``_wuser    = req.w.user;    \
                                                 \
  assign m_axi_``pat``_bready   = req.b_ready;   \
                                                 \
  assign m_axi_``pat``_arvalid  = req.ar_valid;  \
  assign m_axi_``pat``_arid     = req.ar.id;     \
  assign m_axi_``pat``_araddr   = req.ar.addr;   \
  assign m_axi_``pat``_arlen    = req.ar.len;    \
  assign m_axi_``pat``_arsize   = req.ar.size;   \
  assign m_axi_``pat``_arburst  = req.ar.burst;  \
  assign m_axi_``pat``_arlock   = req.ar.lock;   \
  assign m_axi_``pat``_arcache  = req.ar.cache;  \
  assign m_axi_``pat``_arprot   = req.ar.prot;   \
  assign m_axi_``pat``_arqos    = req.ar.qos;    \
  assign m_axi_``pat``_arregion = req.ar.region; \
  assign m_axi_``pat``_aruser   = req.ar.user;   \
                                                 \
  assign m_axi_``pat``_rready   = req.r_ready;   \
                                                 \
  assign rsp.aw_ready = m_axi_``pat``_awready;   \
  assign rsp.ar_ready = m_axi_``pat``_arready;   \
  assign rsp.w_ready  = m_axi_``pat``_wready;    \
                                                 \
  assign rsp.b_valid  = m_axi_``pat``_bvalid;    \
  assign rsp.b.id     = m_axi_``pat``_bid;       \
  assign rsp.b.resp   = m_axi_``pat``_bresp;     \
  assign rsp.b.user   = m_axi_``pat``_buser;     \
                                                 \
  assign rsp.r_valid  = m_axi_``pat``_rvalid;    \
  assign rsp.r.id     = m_axi_``pat``_rid;       \
  assign rsp.r.data   = m_axi_``pat``_rdata;     \
  assign rsp.r.resp   = m_axi_``pat``_rresp;     \
  assign rsp.r.last   = m_axi_``pat``_rlast;     \
  assign rsp.r.user   = m_axi_``pat``_ruser


`define AXI_FLATTEN_SLAVE(pat, req, rsp)         \
  assign req.aw_valid  = s_axi_``pat``_awvalid;  \
  assign req.aw.id     = s_axi_``pat``_awid;     \
  assign req.aw.addr   = s_axi_``pat``_awaddr;   \
  assign req.aw.len    = s_axi_``pat``_awlen;    \
  assign req.aw.size   = s_axi_``pat``_awsize;   \
  assign req.aw.burst  = s_axi_``pat``_awburst;  \
  assign req.aw.lock   = s_axi_``pat``_awlock;   \
  assign req.aw.cache  = s_axi_``pat``_awcache;  \
  assign req.aw.prot   = s_axi_``pat``_awprot;   \
  assign req.aw.qos    = s_axi_``pat``_awqos;    \
  assign req.aw.region = s_axi_``pat``_awregion; \
  assign req.aw.atop   = '0;                     \
  assign req.aw.user   = s_axi_``pat``_awuser;   \
                                                 \
  assign req.w_valid   = s_axi_``pat``_wvalid;   \
  assign req.w.data    = s_axi_``pat``_wdata;    \
  assign req.w.strb    = s_axi_``pat``_wstrb;    \
  assign req.w.last    = s_axi_``pat``_wlast;    \
  assign req.w.user    = s_axi_``pat``_wuser;    \
                                                 \
  assign req.b_ready   = s_axi_``pat``_bready;   \
                                                 \
  assign req.ar_valid  = s_axi_``pat``_arvalid;  \
  assign req.ar.id     = s_axi_``pat``_arid;     \
  assign req.ar.addr   = s_axi_``pat``_araddr;   \
  assign req.ar.len    = s_axi_``pat``_arlen;    \
  assign req.ar.size   = s_axi_``pat``_arsize;   \
  assign req.ar.burst  = s_axi_``pat``_arburst;  \
  assign req.ar.lock   = s_axi_``pat``_arlock;   \
  assign req.ar.cache  = s_axi_``pat``_arcache;  \
  assign req.ar.prot   = s_axi_``pat``_arprot;   \
  assign req.ar.qos    = s_axi_``pat``_arqos;    \
  assign req.ar.region = s_axi_``pat``_arregion; \
  assign req.ar.user   = s_axi_``pat``_aruser;   \
                                                 \
  assign req.r_ready   = s_axi_``pat``_rready;   \
                                                 \
  assign s_axi_``pat``_awready = rsp.aw_ready;   \
  assign s_axi_``pat``_arready = rsp.ar_ready;   \
  assign s_axi_``pat``_wready  = rsp.w_ready;    \
                                                 \
  assign s_axi_``pat``_bvalid  = rsp.b_valid;    \
  assign s_axi_``pat``_bid     = rsp.b.id;       \
  assign s_axi_``pat``_bresp   = rsp.b.resp;     \
  assign s_axi_``pat``_buser   = rsp.b.user;     \
                                                 \
  assign s_axi_``pat``_rvalid  = rsp.r_valid;    \
  assign s_axi_``pat``_rid     = rsp.r.id;       \
  assign s_axi_``pat``_rdata   = rsp.r.data;     \
  assign s_axi_``pat``_rresp   = rsp.r.resp;     \
  assign s_axi_``pat``_rlast   = rsp.r.last;     \
  assign s_axi_``pat``_ruser   = rsp.r.user
