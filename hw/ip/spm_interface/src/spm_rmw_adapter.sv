// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Authors:
// - Tim Fischer <fischeti@iis.ee.ethz.ch>

`include "common_cells/registers.svh"

module spm_rmw_adapter
#(
  parameter int unsigned AddrWidth = 0,
  parameter int unsigned DataWidth = 0,
  parameter int unsigned StrbWidth = AddrWidth / 8,

  localparam type addr_t = logic [AddrWidth-1:0],
  localparam type mem_data_t = logic [DataWidth-1:0],
  localparam type mem_strb_t = logic [StrbWidth-1:0]
) (
   input logic  clk_i,
   input logic  rst_ni,

   // Request-side channel
   input logic  mem_valid_i,
   output logic mem_ready_o,
   input        addr_t mem_addr_i,
   input        mem_data_t mem_wdata_i,
   input        mem_strb_t mem_strb_i,
   input logic  mem_we_i,
   output logic mem_rvalid_o,
   output       mem_data_t mem_rdata_o,

   // Mem-side channel
   output logic mem_valid_o,
   input logic  mem_ready_i,
   output       addr_t mem_addr_o,
   output       mem_data_t mem_wdata_o,
   output       mem_strb_t mem_strb_o,
   output logic mem_we_o,
   input logic  mem_rvalid_i,
   input        mem_data_t mem_rdata_i
   );

  typedef enum  {NORMAL, RMW_READ, RMW_MODIFY_WRITE} state_e;

  mem_data_t mask_q, mask_d;
  mem_data_t masked_wdata_q, masked_wdata_d, masked_data;
  assign masked_data = (mem_wdata_i & mask_q) | (mem_rdata_i & ~mask_q);

  logic         partial_write;
  assign partial_write = mem_valid_i & mem_we_i & ~(&mem_strb_i);

  state_e req_state_q, req_state_d;

  always_comb begin
    for (int i = 0; i < DataWidth; i++) begin
      mask_d[i] = mem_strb_i[i/8];
    end

    masked_wdata_d = (mem_rvalid_i)? masked_data : masked_wdata_q;
  end

  always_comb begin

    req_state_d = req_state_q;

    unique case (req_state_q)
      NORMAL: begin
        // If partial memory access is detected perform RMW_READ
        if (partial_write) begin
          req_state_d = RMW_READ;
        end
      end

      RMW_READ: begin
        // Wait for full access read request to be granted
        if (mem_rvalid_i) begin
          req_state_d = RMW_MODIFY_WRITE;
        end
      end // case: RMW_READ

      RMW_MODIFY_WRITE: begin
        if (mem_rvalid_i) begin
          req_state_d = NORMAL;
        end
      end

      default: ;

    endcase
  end

  always_comb begin

    // Mem-side
    mem_valid_o = mem_valid_i;
    mem_addr_o = mem_addr_i;
    mem_wdata_o = mem_wdata_i;
    mem_strb_o = '1; // always perform full access
    mem_we_o = mem_we_i;

    // Request-side
    mem_ready_o = mem_ready_i;
    mem_rvalid_o = mem_rvalid_i;
    mem_rdata_o = mem_rdata_i;

    unique case (req_state_q)

      NORMAL: begin

        // If access is bitwise, generate RMW_READ request
        if (partial_write) begin
          mem_we_o = '0;
        end
      end // case: NORMAL

      RMW_READ: begin

        mem_rvalid_o = 1'b0;
        mem_rdata_o = '0;
        mem_we_o = 1'b0;

        if (mem_rvalid_i) begin
          mem_valid_o = 1'b1;
          mem_we_o = 1'b1;
          mem_wdata_o = masked_wdata_d;
        end

      end // case: RMW_READ

      RMW_MODIFY_WRITE: begin

        mem_wdata_o = masked_wdata_q;
        mem_we_o = 1'b1;

      end // case: RMW_MODIFY_WRITE

      default: ;
    endcase
  end

  `FF(req_state_q, req_state_d, state_e'('0))
  `FF(mask_q, mask_d, '0)
  `FF(masked_wdata_q, masked_wdata_d, '0)


endmodule
