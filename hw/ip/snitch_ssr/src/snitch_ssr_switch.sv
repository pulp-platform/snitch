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
  parameter logic [NumSsrs-1:0][4:0] SsrRegs = '0,
  parameter logic [NumSsrs-1:0][4:0] IntSsrRegs = '0,
  /// Derived parameter *Do not override*
  parameter int unsigned Ports = RPorts + WPorts,
  parameter type data_t = logic [DataWidth-1:0],
  parameter type data_core_t = logic [31:0]                         
) (
  // Read and write streams coming from the fpu
  input  logic  [RPorts-1:0][4:0] ssr_fp_raddr_i,
  output data_t [RPorts-1:0]      ssr_fp_rdata_o,
  input  logic  [RPorts-1:0]      ssr_fp_rvalid_i,
  output logic  [RPorts-1:0]      ssr_fp_rready_o,
  input  logic  [RPorts-1:0]      ssr_fp_rdone_i,

  input  logic  [WPorts-1:0][4:0] ssr_fp_waddr_i,
  input  data_t [WPorts-1:0]      ssr_fp_wdata_i,
  input  logic  [WPorts-1:0]      ssr_fp_wvalid_i,
  output logic  [WPorts-1:0]      ssr_fp_wready_o,
  input  logic  [WPorts-1:0]      ssr_fp_wdone_i,
  // Read and write streams coming from the core
  input  logic       [RPorts-2:0][4:0]   ssr_int_raddr_i,
  output data_core_t [RPorts-2:0]        ssr_int_rdata_o,
  input  logic       [RPorts-2:0]        ssr_int_rvalid_i,
  output logic       [RPorts-2:0]        ssr_int_rready_o,
  input  logic       [RPorts-2:0]        ssr_int_rdone_i,
  input  logic       [WPorts-1:0][4:0]   ssr_int_waddr_i,
  input  data_core_t [WPorts-1:0]        ssr_int_wdata_i,
  input  logic       [WPorts-1:0]        ssr_int_wvalid_i,
  output logic       [WPorts-1:0]        ssr_int_wready_o,
  input  logic       [WPorts-1:0]        ssr_int_wdone_i,
  input  logic                           ssr_sel_i,
  // Ports into memory.
  input  data_t [NumSsrs-1:0]     lane_rdata_i,
  output data_t [NumSsrs-1:0]     lane_wdata_o,
  output logic  [NumSsrs-1:0]     lane_write_o,
  input  logic  [NumSsrs-1:0]     lane_valid_i,
  output logic  [NumSsrs-1:0]     lane_ready_o,
  input  logic  [NumSsrs-1:0]     meta_valid_i,
  output logic  [NumSsrs-1:0]     meta_ready_o,
  input  logic  [NumSsrs-1:0]     meta_data_i
);

  logic   [Ports-1:0][4:0] ssr_addr;
  data_t  [Ports-1:0]      ssr_rdata;
  data_t  [Ports-1:0]      ssr_wdata;
  logic   [Ports-1:0]      ssr_valid;
  logic   [Ports-1:0]      ssr_ready;
  logic   [Ports-1:0]      ssr_done;
  logic   [Ports-1:0]      ssr_write;
  data_t  [1:0]            rdata;

  // Unify the read and write ports into one structure that we can easily
  // switch.
  always_comb begin
    if (ssr_sel_i) begin
      for (int i = 0; i < RPorts; i++) begin
        ssr_addr[i] = ssr_fp_raddr_i[i];
        ssr_fp_rdata_o[i] = ssr_rdata[i];
        ssr_fp_rready_o[i] = ssr_ready[i];
        ssr_wdata[i] = '0;
        ssr_valid[i] = ssr_fp_rvalid_i[i];
        ssr_done[i] = ssr_fp_rdone_i[i];
        ssr_write[i] = 0;
      end
      for (int i = 0; i < WPorts; i++) begin
        ssr_addr[i+RPorts]  = ssr_fp_waddr_i[i];
        ssr_wdata[i+RPorts] = ssr_fp_wdata_i[i];
        ssr_valid[i+RPorts] = ssr_fp_wvalid_i[i];
        ssr_done[i+RPorts]  = ssr_fp_wdone_i[i];
        ssr_write[i+RPorts] = 1;
        ssr_fp_wready_o[i] = ssr_ready[i+RPorts];
      end
    end else begin
      for (int i = 0; i < RPorts-1; i++) begin
        ssr_addr[i] = ssr_int_raddr_i[i];
        ssr_int_rdata_o[i] = rdata[i];
        ssr_int_rready_o[i] = ssr_ready[i];
        ssr_wdata[i] = '0;
        ssr_valid[i] = ssr_int_rvalid_i[i];
        ssr_done[i] = ssr_int_rdone_i[i];
        ssr_write[i] = 0;
        ssr_addr[2] = 0;
        ssr_valid[2] = 0;
        ssr_done[2] = 0;
        ssr_write[2] = 0;
        ssr_wdata[2] = '0;
      end
      for (int i = 0; i < RPorts; i++) begin
        ssr_fp_rdata_o[i] = '0;
        ssr_fp_rready_o[i] = '0;
      end
      for (int i = 0; i < WPorts; i++) begin
        ssr_addr[i+RPorts]  = ssr_int_waddr_i[i];
        ssr_wdata[i+RPorts] = ssr_int_wdata_i[i];
        ssr_valid[i+RPorts] = ssr_int_wvalid_i[i];
        ssr_done[i+RPorts]  = ssr_int_wdone_i[i];
        ssr_write[i+RPorts] = 1;
        ssr_int_wready_o[i] = ssr_ready[i+RPorts];
        ssr_fp_wready_o[i] = 0;
      end 
    end
  end

  always_comb begin
    lane_ready_o = '0;
    lane_wdata_o = '0;
    lane_write_o = '0;
    ssr_rdata = '0;
    ssr_ready = '0;
    meta_ready_o = '0;
    rdata = '0;

    for (int o = 0; o < NumSsrs; o++) begin
      for (int i = 0; i < Ports; i++) begin
        if (ssr_valid[i] && ssr_addr[i] == SsrRegs[o]) begin
          lane_wdata_o[o] = ssr_wdata[i];
          lane_ready_o[o] = ssr_done[i];
          lane_wdata_o[o] = ssr_wdata[i];
          lane_write_o[o] = ssr_write[i];
          ssr_rdata[i] = lane_rdata_i[o];
          ssr_ready[i] = lane_valid_i[o];
          meta_ready_o[o] = ssr_done[i];
       end else if (ssr_valid[i] && ssr_addr[i] == IntSsrRegs[o]) begin
          lane_wdata_o[o] = ssr_wdata[i];
          lane_ready_o[o] = ssr_done[i] & meta_valid_i;
          lane_wdata_o[o] = ssr_wdata[i];
          lane_write_o[o] = ssr_write[i];
          ssr_rdata[i] = lane_rdata_i[o];
          ssr_ready[i] = lane_valid_i[o] & meta_valid_i[o];
          meta_ready_o[o] = ssr_done[i] & lane_valid_i[o];
          rdata[i] = meta_data_i[o] ? lane_rdata_i[o][63:32] : lane_rdata_i[o][31:0];      
        end
      end
    end
  end
endmodule
