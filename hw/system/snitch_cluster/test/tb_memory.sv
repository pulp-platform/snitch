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

  typedef logic [AxiAddrWidth-1:0] axi_addr_t;
  typedef logic [AxiDataWidth-1:0] axi_data_t;
  typedef logic [AxiDataWidth/8-1:0] axi_strb_t;
  typedef logic [AxiIdWidth-1:0] axi_id_t;
  typedef logic [AxiUserWidth-1:0] axi_user_t;

  `AXI_TYPEDEF_AW_CHAN_T(axi_aw_t, axi_addr_t, axi_id_t, axi_user_t)
  `AXI_TYPEDEF_W_CHAN_T(axi_w_t, axi_data_t, axi_strb_t, axi_user_t)
  `AXI_TYPEDEF_B_CHAN_T(axi_b_t, axi_id_t, axi_user_t)
  `AXI_TYPEDEF_AR_CHAN_T(axi_ar_t, axi_addr_t, axi_id_t, axi_user_t)
  `AXI_TYPEDEF_R_CHAN_T(axi_r_t, axi_data_t, axi_id_t, axi_user_t)

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

  localparam int NumBytes = $bits(axi_strb_t);
  localparam int BusAlign = $clog2(NumBytes);

  // Ensure the AXI interface has not feedthrough signals.
  req_t req_cut;
  rsp_t rsp_cut;

  axi_cut #(
    .aw_chan_t ( axi_aw_t ),
    .w_chan_t  ( axi_w_t  ),
    .b_chan_t  ( axi_b_t  ),
    .ar_chan_t ( axi_ar_t ),
    .r_chan_t  ( axi_r_t  ),
    .req_t     ( req_t    ),
    .resp_t    ( rsp_t    )
  ) i_cut (
    .clk_i,
    .rst_ni,
    .slv_req_i  ( req_i   ),
    .slv_resp_o ( rsp_o   ),
    .mst_req_o  ( req_cut ),
    .mst_resp_i ( rsp_cut )
  );

  // Convert AXI to a trivial register interface.
  AXI_BUS #(
    .AXI_ADDR_WIDTH ( AxiAddrWidth ),
    .AXI_DATA_WIDTH ( AxiDataWidth ),
    .AXI_ID_WIDTH   ( AxiIdWidth   ),
    .AXI_USER_WIDTH ( AxiUserWidth )
  ) axi();

  `AXI_ASSIGN_FROM_REQ(axi, req_cut)
  `AXI_ASSIGN_TO_RESP(rsp_cut, axi)

  REG_BUS #(
    .ADDR_WIDTH ( AxiAddrWidth ),
    .DATA_WIDTH ( AxiDataWidth )
  ) regb(clk_i);

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
    .in         ( axi  ),
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
