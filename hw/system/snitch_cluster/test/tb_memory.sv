// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Fabian Schuiki <fschuiki@iis.ee.ethz.ch>
// Florian Zaruba <zarubaf@iis.ee.ethz.ch>

`include "axi/assign.svh"
`include "axi/typedef.svh"

module tb_memory #(
  /// AXI4+ATOP address width.
  parameter int unsigned AxiAddrWidth  = 0,
  /// AXI4+ATOP data width.
  parameter int unsigned AxiDataWidth  = 0,
  /// AXI4+ATOP ID width.
  parameter int unsigned AxiIdWidth  = 0,
  /// AXI4+ATOP User width.
  parameter int unsigned AxiUserWidth  = 0,
  parameter type req_t = logic,
  parameter type rsp_t = logic
)(
  input  logic clk_i,
  input  logic rst_ni,
  input  req_t req_i,
  output rsp_t rsp_o
);

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

  localparam int NumBytes = AxiDataWidth/8;
  localparam int BusAlign = $clog2(NumBytes);

  AXI_BUS #(
    .AXI_ADDR_WIDTH ( AxiAddrWidth ),
    .AXI_DATA_WIDTH ( AxiDataWidth ),
    .AXI_ID_WIDTH   ( AxiIdWidth   ),
    .AXI_USER_WIDTH ( AxiUserWidth )
  ) axi(),
    axi_wo_atomics(),
    axi_wo_atomics_cut();

  `AXI_ASSIGN_FROM_REQ(axi, req_i)
  `AXI_ASSIGN_TO_RESP(rsp_o, axi)

  REG_BUS #(
    .ADDR_WIDTH ( AxiAddrWidth ),
    .DATA_WIDTH ( AxiDataWidth )
  ) regb(clk_i);

  // Filter atomic operations.
  axi_riscv_atomics_wrap #(
    .AXI_ADDR_WIDTH (AxiAddrWidth),
    .AXI_DATA_WIDTH (AxiDataWidth),
    .AXI_ID_WIDTH (AxiIdWidth),
    .AXI_USER_WIDTH (AxiUserWidth),
    .AXI_MAX_WRITE_TXNS (2),
    .RISCV_WORD_WIDTH (32)
  ) i_axi_riscv_atomics_wrap (
    .clk_i (clk_i),
    .rst_ni (rst_ni),
    .slv (axi),
    .mst (axi_wo_atomics)
  );

  // Ensure the AXI interface has not feedthrough signals.
  axi_cut_intf #(
    .BYPASS     (1'b0),
    .ADDR_WIDTH (AxiAddrWidth),
    .DATA_WIDTH (AxiDataWidth),
    .ID_WIDTH   (AxiIdWidth),
    .USER_WIDTH (AxiUserWidth)
  ) i_cut (
    .clk_i (clk_i),
    .rst_ni (rst_ni),
    .in (axi_wo_atomics),
    .out (axi_wo_atomics_cut)
  );

  // Convert AXI to a trivial register interface.
  axi_to_reg_intf #(
    .ADDR_WIDTH ( AxiAddrWidth ),
    .DATA_WIDTH ( AxiDataWidth ),
    .ID_WIDTH   ( AxiIdWidth   ),
    .USER_WIDTH ( AxiUserWidth ),
    .DECOUPLE_W ( 1            )
  ) i_axi_to_reg (
    .clk_i,
    .rst_ni,
    .testmode_i ( 1'b0 ),
    .in         ( axi_wo_atomics_cut ),
    .reg_o      ( regb )
  );

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
