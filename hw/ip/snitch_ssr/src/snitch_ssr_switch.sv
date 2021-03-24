// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Fabian Schuiki <fschuiki@iis.ee.ethz.ch>
// Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>

module snitch_ssr_switch #(
    parameter int unsigned DataWidth = 0,
    /// Derived parameter *Do not override*
    parameter type data_t = logic [DataWidth-1:0]
) (
    input  logic             clk_i,
    input  logic             rst_ni,
    // Read and write streams coming from the processor.
    input  logic  [2:0][4:0] ssr_raddr_i,
    output data_t [2:0]      ssr_rdata_o,
    input  logic  [2:0]      ssr_rvalid_i,
    output logic  [2:0]      ssr_rready_o,
    input  logic  [2:0]      ssr_rdone_i,

    input  logic  [0:0][4:0] ssr_waddr_i,
    input  data_t [0:0]      ssr_wdata_i,
    input  logic  [0:0]      ssr_wvalid_i,
    output logic  [0:0]      ssr_wready_o,
    input  logic  [0:0]      ssr_wdone_i,
    // Ports into memory.
    input  data_t [2:0]      lane_rdata_i,
    output data_t [2:0]      lane_wdata_o,
    output logic  [2:0]      lane_write_o,
    input  logic  [2:0]      lane_valid_i,
    output logic  [2:0]      lane_ready_o
);

  localparam int unsigned NR = 3;  // number of read ports
  localparam int unsigned NW = 1;  // number of write ports
  localparam int unsigned NI = NR + NW;  // total number of input ports
  localparam int unsigned NO = 3;  // number of output ports

  logic    [NI-1:0]      [4:0]  ssr_addr;
  data_t [         NI-1:0     ] ssr_rdata;
  data_t [         NI-1:0     ] ssr_wdata;
  logic    [NI-1:0]             ssr_valid;
  logic    [NI-1:0]             ssr_ready;
  logic    [NI-1:0]             ssr_done;
  logic    [NI-1:0]             ssr_write;

  // Unify the read and write ports into one structure that we can easily
  // switch.
  always_comb begin
    for (int i = 0; i < NR; i++) begin
      ssr_addr[i] = ssr_raddr_i[i];
      ssr_rdata_o[i] = ssr_rdata[i];
      ssr_rready_o[i] = ssr_ready[i];
      ssr_wdata[i] = '0;
      ssr_valid[i] = ssr_rvalid_i[i];
      ssr_done[i] = ssr_rdone_i[i];
      ssr_write[i] = 0;
    end
    for (int i = 0; i < NW; i++) begin
      ssr_addr[i+NR]  = ssr_waddr_i[i];
      ssr_wdata[i+NR] = ssr_wdata_i[i];
      ssr_valid[i+NR] = ssr_wvalid_i[i];
      ssr_done[i+NR]  = ssr_wdone_i[i];
      ssr_write[i+NR] = 1;
      ssr_wready_o[i] = ssr_ready[i+NR];
    end
  end

  always_comb begin
    lane_ready_o = '0;
    lane_wdata_o = '0;
    lane_write_o = '0;
    ssr_rdata = '0;
    ssr_ready = '0;

    for (int o = 0; o < NO; o++) begin
      for (int i = 0; i < NI; i++) begin
        if (ssr_valid[i] && ssr_addr[i] == snitch_pkg::SSRRegs[o]) begin
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
