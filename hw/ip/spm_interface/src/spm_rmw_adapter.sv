// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Authors:
// - Tim Fischer <fischeti@iis.ee.ethz.ch>

/// This module breaks up sub-word accesses into read-modify-write accesses
/// to support things like block ECC.

`include "common_cells/registers.svh"
module spm_rmw_adapter
#(
  parameter int unsigned  AddrWidth = 0,
  parameter int unsigned  DataWidth = 0,
  parameter int unsigned  StrbWidth = AddrWidth / 8,
  parameter int unsigned  MaxTxns = 32'd3,

  localparam type addr_t = logic [AddrWidth-1:0],
  localparam type mem_data_t = logic [DataWidth-1:0],
  localparam type mem_strb_t = logic [StrbWidth-1:0],
  localparam type cnt_t = logic [$clog2(MaxTxns)-1:0]

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
   output logic mem_we_o,
   input logic  mem_rvalid_i,
   input        mem_data_t mem_rdata_i
   );

  typedef enum  {NORMAL, RMW_READ, RMW_MODIFY_WRITE, RMW_FINALIZE} state_e;
  state_e req_state_q, req_state_d;

  mem_data_t mask;
  mem_data_t masked_wdata_q, masked_wdata_d;
  logic masked_wdata_en;

  // The RMW_READ state generates a full-word read request
  // which is then masked with the pending byte-wise write request
  assign masked_wdata_d = (mem_wdata_i & mask) | (mem_rdata_i & ~mask);
  assign masked_wdata_en = mem_rvalid_i & (req_state_q == RMW_READ);

  logic partial_write;
  assign partial_write = mem_valid_i & mem_we_i & ~(&mem_strb_i);

  cnt_t cnt_q, cnt_d;
  logic rmw_ready, txns_ready;

  // Wait until we do not have any outstanding transactions anymore
  // since we are blocking the response channel with our `rmw` operation.
  assign rmw_ready = (cnt_q == '0);

  // Only allow `MaxTxns` number of oustanding transactions
  assign txns_ready = cnt_q < MaxTxns;

  // Count number of outstanding requests
  always_comb begin
    cnt_d = cnt_q;
    if (mem_valid_i & mem_ready_o) begin
      cnt_d++;
    end
     if (mem_rvalid_o) begin
       cnt_d--;
     end
  end

  always_comb begin
    for (int i = 0; i < DataWidth; i++) begin
      mask[i] = mem_strb_i[i/8];
    end
  end

  always_comb begin

    // Mem-side
    mem_valid_o = mem_valid_i & txns_ready;
    mem_addr_o = mem_addr_i;
    mem_wdata_o = mem_wdata_i;
    mem_we_o = mem_we_i;

    // Request-side
    mem_ready_o = mem_ready_i & txns_ready & !partial_write;
    mem_rvalid_o = mem_rvalid_i;
    mem_rdata_o = mem_rdata_i;

    req_state_d = req_state_q;

    unique case (req_state_q)

      NORMAL: begin

        // If access is byte-wise, generate full-width read request
        if (partial_write) begin
          mem_we_o = 1'b0;

          // RMW transaction can start as soon as mem is ready
          // and doesn't have any outstanding transactions anymore
          if (mem_ready_i & rmw_ready) begin
            req_state_d = RMW_READ;
          end
        end
      end // case: NORMAL

      RMW_READ: begin

        // stall requests
        mem_rvalid_o = 1'b0;

        // wait for data to arrive
        mem_valid_o = 1'b0;
        mem_we_o = 1'b0;

        if (mem_rvalid_i) begin
          req_state_d = RMW_MODIFY_WRITE;
        end

      end // case: RMW_READ

      RMW_MODIFY_WRITE: begin

        // stall requests
        mem_rvalid_o = 1'b0;
        mem_ready_o = mem_ready_i;

        // issue write request with masked data
        mem_valid_o = 1'b1;
        mem_we_o = 1'b1;
        mem_wdata_o = masked_wdata_q;

        if (mem_ready_i) begin
          req_state_d = RMW_FINALIZE;
        end

      end // case: RMW_MODIFY_WRITE

      RMW_FINALIZE: begin

        // stall requests
        mem_rvalid_o = mem_rvalid_i;
        mem_ready_o = 1'b0;

        mem_valid_o = 1'b0;
        mem_wdata_o = masked_wdata_q;

        // finalize and grant RMW request
        if (mem_rvalid_i) begin
          req_state_d = NORMAL;
        end

      end // case: RMW_FINALIZE

      default: ;
    endcase
  end

  `FF(req_state_q, req_state_d, state_e'('0))
  `FFL(masked_wdata_q, masked_wdata_d, masked_wdata_en, '0)
  `FF(cnt_q, cnt_d, '0)

endmodule
