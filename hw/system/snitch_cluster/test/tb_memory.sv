// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Fabian Schuiki <fschuiki@iis.ee.ethz.ch>
// Florian Zaruba <zarubaf@iis.ee.ethz.ch>

`include "axi/assign.svh"

module tb_memory #(
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

  localparam int NumBytes = $bits(req_i.w.data)/8;
  localparam int BusAlign = $clog2(NumBytes);

  // Ensure the AXI interface has not feedthrough signals.
  req_t req_cut;
  rsp_t rsp_cut;

  axi_cut #(
    .aw_chan_t ( type(req_i.aw) ),
    .w_chan_t  ( type(req_i.w)  ),
    .b_chan_t  ( type(rsp_o.b)  ),
    .ar_chan_t ( type(req_i.ar) ),
    .r_chan_t  ( type(rsp_o.r)  ),
    .req_t     ( req_t          ),
    .resp_t    ( rsp_t          )
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
    .AXI_ADDR_WIDTH ( $bits(req_i.aw.addr) ),
    .AXI_DATA_WIDTH ( $bits(req_i.w.data)  ),
    .AXI_ID_WIDTH   ( $bits(req_i.aw.id)   ),
    .AXI_USER_WIDTH ( $bits(req_i.aw.user) )
  ) axi();

  `AXI_ASSIGN_FROM_REQ(axi, req_cut)
  `AXI_ASSIGN_TO_RESP(rsp_cut, axi)

  REG_BUS #(
    .ADDR_WIDTH ( $bits(req_i.aw.addr) ),
    .DATA_WIDTH ( $bits(req_i.w.data)  )
  ) regb(clk_i);

  axi_to_reg_intf #(
    .ADDR_WIDTH ( $bits(req_i.aw.addr) ),
    .DATA_WIDTH ( $bits(req_i.w.data)  ),
    .ID_WIDTH   ( $bits(req_i.aw.id)   ),
    .USER_WIDTH ( $bits(req_i.aw.user) ),
    .DECOUPLE_W ( 1                    )
  ) i_axi_to_reg (
    .clk_i,
    .rst_ni,
    .testmode_i ( 1'b0 ),
    .in         ( axi  ),
    .reg_o      ( regb )
  );

  // Handle requests on the register bus.
  always_comb begin
    regb.error = 0;
    regb.ready = 1;
    if (regb.valid) begin
      automatic byte data[NumBytes];
      automatic byte strb[NumBytes];
      if (regb.write) begin
        if (regb.addr == 32'hFFFFFF00) begin
          automatic int retval = regb.wdata;
          $display("Binary exited with code %0d", retval);
          if (retval > 0) begin
            $stop;
          end else begin
            $finish;
          end
        end
        // $display("Write [%h] = %h (%b)", regb.addr, regb.wdata, regb.wstrb);
        regb.rdata = 0;
        for (int i = 0; i < NumBytes; i++) begin
          data[i] = regb.wdata[i*8+:8];
          strb[i] = regb.wstrb[i];
        end
        tb_memory_write((regb.addr >> BusAlign) << BusAlign, NumBytes, data, strb);
      end else begin
        // $display("Read [%h]", regb.addr);
        tb_memory_read((regb.addr >> BusAlign) << BusAlign, NumBytes, data);
        for (int i = 0; i < NumBytes; i++) begin
          regb.rdata[i*8+:8] = data[i];
        end
      end
    end
  end

endmodule
