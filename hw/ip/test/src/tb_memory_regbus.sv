// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Fabian Schuiki <fschuiki@iis.ee.ethz.ch>
// Florian Zaruba <zarubaf@iis.ee.ethz.ch>

module tb_memory_regbus #(
  /// Regbus address width.
  parameter int unsigned AddrWidth  = 0,
  /// Regbus data width.
  parameter int unsigned DataWidth  = 0,
  parameter type req_t = logic,
  parameter type rsp_t = logic
)(
  input  logic clk_i,
  input  logic rst_ni,
  input  req_t req_i,
  output rsp_t rsp_o
);

  `include "register_interface/assign.svh"

  import "DPI-C" function void tb_memory_read(
    input longint addr,
    input int len,
    output byte data[]
  );
  import "DPI-C" function void tb_memory_write(
    input longint addr,
    input int len,
    input byte data[],
    input bit strb[]
  );

  localparam int NumBytes = DataWidth/8;
  localparam int BusAlign = $clog2(NumBytes);

  REG_BUS #(
    .ADDR_WIDTH ( AddrWidth ),
    .DATA_WIDTH ( DataWidth )
  ) regb(clk_i);

  `REG_BUS_ASSIGN_FROM_REQ(regb, req_i)
  `REG_BUS_ASSIGN_TO_RSP(rsp_o, regb)

  assign regb.error = 0;
  assign regb.ready = 1;

  // Handle write requests on the register bus.
  always_ff @(posedge clk_i) begin
    if (rst_ni && regb.valid) begin
      automatic byte data[NumBytes];
      automatic bit  strb[NumBytes];
      if (regb.write) begin
        for (int i = 0; i < NumBytes; i++) begin
          // verilog_lint: waive-start always-ff-non-blocking
          data[i] = regb.wdata[i*8+:8];
          strb[i] = regb.wstrb[i];
          // verilog_lint: waive-start always-ff-non-blocking
        end
        tb_memory_write((regb.addr >> BusAlign) << BusAlign, NumBytes, data, strb);
      end
    end
  end

  // Handle read requests combinatorial on the register bus.
  always_comb begin
    if (regb.valid) begin
      automatic byte data[NumBytes];
      tb_memory_read((regb.addr >> BusAlign) << BusAlign, NumBytes, data);
      for (int i = 0; i < NumBytes; i++) begin
        regb.rdata[i*8+:8] = data[i];
      end
    end
  end

endmodule
