// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Fabian Schuiki <fschuiki@iis.ee.ethz.ch>
// Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>

module snitch_ssr_switch #(
  parameter int unsigned DataWidth  = 0,
  parameter int unsigned NumSsrs    = 0,
  parameter int unsigned RPorts     = 0,
  parameter int unsigned WPorts     = 0,
  parameter logic [NumSsrs:0][4:0] SsrRegs = '0,
  /// Derived parameter *Do not override*
  parameter int unsigned Ports = RPorts + WPorts,
  parameter type data_t = logic [DataWidth-1:0]
) (
  input  logic             clk_i,
  input  logic             rst_ni,
  // Read and write streams coming from the processor.
  input  logic  [RPorts-1:0][4:0] ssr_raddr_i,
  output data_t [RPorts-1:0]      ssr_rdata_o,
  input  logic  [RPorts-1:0]      ssr_rvalid_i,
  output logic  [RPorts-1:0]      ssr_rready_o,
  input  logic  [RPorts-1:0]      ssr_rdone_i,

  input  logic  [WPorts-1:0][4:0] ssr_waddr_i,
  input  data_t [WPorts-1:0]      ssr_wdata_i,
  input  logic  [WPorts-1:0]      ssr_wvalid_i,
  output logic  [WPorts-1:0]      ssr_wready_o,
  input  logic  [WPorts-1:0]      ssr_wdone_i,
  // Ports into memory.
  input  data_t [NumSsrs-1:0]     lane_rdata_i,
  output data_t [NumSsrs-1:0]     lane_wdata_o,
  output logic  [NumSsrs-1:0]     lane_write_o,
  input  logic  [NumSsrs-1:0]     lane_valid_i,
  output logic  [NumSsrs-1:0]     lane_ready_o
);

  logic   [Ports-1:0][4:0] ssr_addr;
  data_t  [Ports-1:0]      ssr_rdata;
  data_t  [Ports-1:0]      ssr_wdata;
  logic   [Ports-1:0]      ssr_valid;
  logic   [Ports-1:0]      ssr_ready;
  logic   [Ports-1:0]      ssr_done;
  logic   [Ports-1:0]      ssr_write;

  // Unify the read and write ports into one structure that we can easily
  // switch.
  always_comb begin
    for (int i = 0; i < RPorts; i++) begin
      ssr_addr[i] = ssr_raddr_i[i];
      ssr_rdata_o[i] = ssr_rdata[i];
      ssr_rready_o[i] = ssr_ready[i];
      ssr_wdata[i] = '0;
      ssr_valid[i] = ssr_rvalid_i[i];
      ssr_done[i] = ssr_rdone_i[i];
      ssr_write[i] = 0;
    end
    for (int i = 0; i < WPorts; i++) begin
      ssr_addr[i+RPorts]  = ssr_waddr_i[i];
      ssr_wdata[i+RPorts] = ssr_wdata_i[i];
      ssr_valid[i+RPorts] = ssr_wvalid_i[i];
      ssr_done[i+RPorts]  = ssr_wdone_i[i];
      ssr_write[i+RPorts] = 1;
      ssr_wready_o[i] = ssr_ready[i+RPorts];
    end
  end

  always_comb begin
    lane_ready_o = '0;
    lane_wdata_o = '0;
    lane_write_o = '0;
    ssr_rdata = '0;
    ssr_ready = '0;

    for (int o = 0; o < NumSsrs; o++) begin
      for (int i = 0; i < Ports; i++) begin
        if (ssr_valid[i] && ssr_addr[i] == SsrRegs[o]) begin
          lane_wdata_o[o] = ssr_wdata[i];
          lane_ready_o[o] = ssr_done[i];
          lane_wdata_o[o] = ssr_wdata[i];
          lane_write_o[o] = ssr_write[i];
          ssr_rdata[i] = lane_rdata_i[o];
          ssr_ready[i] = lane_valid_i[o];
        end
      end
    end
  end
endmodule
