// Copyright 2020 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// Authors:
// - Tim Fischer <fischeti@iis.ee.ethz.ch>

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
   input logic  mem_req_i,
   output logic mem_gnt_o,
   input        addr_t mem_addr_i,
   input        mem_data_t mem_wdata_i,
   input        mem_strb_t mem_strb_i,
   input logic  mem_we_i,
   output logic mem_rvalid_o,
   output       mem_data_t mem_rdata_o,

   // Mem-side channel
   output logic mem_req_o,
   input logic  mem_gnt_i,
   output       addr_t mem_addr_o,
   output       mem_data_t mem_wdata_o,
   output       mem_strb_t mem_strb_o,
   output logic mem_we_o,
   input logic  mem_rvalid_i,
   input        mem_data_t mem_rdata_i
   );

  typedef enum  {NORMAL, RMW_READ, RMW_MODIFY_WRITE, RMW_FINAL} state_t;

  logic [DataWidth-1:0] mask_q, mask_d;
  logic [DataWidth-1:0] masked_data_q, masked_data_d;

  state_t req_state_q, req_state_d;

  always_comb begin : mask_block
    for (int i = 0; i < DataWidth; i++) begin
      mask_d[i] = mem_strb_i[i/8];
    end

    masked_data_d = masked_data_q;
    if (mem_rvalid_i && !(&mem_strb_i)) begin
      masked_data_d = (mem_rdata_i & ~mask_q) | (mem_wdata_i & mask_q);
    end

  end

  always_comb begin : next_state_block

    req_state_d = req_state_q;

    unique case (req_state_q)
      NORMAL: begin
        req_state_d = NORMAL;

        // If partial memory access (read or write) is detected perform RMW_READ first
        if (mem_req_i && !(&mem_strb_i)) begin
          req_state_d = RMW_READ;
        end
      end

      RMW_READ: begin

        // Wait for full access read request to be granted
        if (mem_gnt_i) begin
          if (mem_we_i) begin
            req_state_d = RMW_MODIFY_WRITE;
          end else begin
            req_state_d = RMW_FINAL;
          end
        end
      end // case: RMW_READ

      RMW_MODIFY_WRITE: begin
        if (mem_gnt_i) begin
          req_state_d = RMW_FINAL;
        end
      end

      RMW_FINAL: begin
        req_state_d = NORMAL;
      end

      default: begin
        req_state_d = NORMAL;
      end

    endcase
  end

  always_comb begin : output_block

    // Mem-side
    mem_req_o = mem_req_i;
    mem_addr_o = mem_addr_i;
    mem_wdata_o = mem_wdata_i;
    mem_strb_o = '1; // always perform full access
    mem_we_o = mem_we_i;

    // Request-side
    mem_gnt_o = mem_gnt_i;
    mem_rvalid_o = mem_rvalid_i;
    mem_rdata_o = mem_rdata_i;

    unique case (req_state_q)

      NORMAL: begin

        // If access is bitwise, generate RMW_READ request
        if (mem_req_i && !(&mem_strb_i)) begin
          // Mem-side
          mem_req_o = 1'b1;
          mem_addr_o = mem_addr_i;
          mem_wdata_o = '0;
          mem_strb_o = '1;
          mem_we_o = '0;
          // Request-side
          mem_gnt_o = '0;
          mem_rvalid_o = '0;
          mem_rdata_o = '0;
        end
      end // case: NORMAL

      RMW_READ: begin

        // Wait and assert read request until granted
        // Mem-side
        mem_req_o = 1'b1;
        mem_addr_o = mem_addr_i;
        mem_wdata_o = '0;
        // Request-side
        mem_gnt_o = 1'b0;
        mem_rvalid_o = 1'b0;
        mem_rdata_o = '0;
        mem_we_o = 1'b0;

        // Once byte-wise read access is granted,
        // (READ) grant original read request and send masked data next cycle
        // (WRITE) wait for data arriving in the next cycle
        if (!mem_we_i && mem_gnt_i) begin
          mem_gnt_o = 1'b1;
        end

      end // case: RMW_READ

      RMW_MODIFY_WRITE: begin

        // Mem-side
        mem_req_o = 1'b1;
        mem_addr_o = mem_addr_i;
        mem_wdata_o = '0;
        mem_we_o = 1'b1;
        // Request-side
        mem_gnt_o = 1'b0;
        mem_rvalid_o = 1'b0;
        mem_rdata_o = '0;

        // Data should have arrived, byte-wise modify read data
        // and issue write request
        if (mem_rvalid_i) begin
          mem_wdata_o = (mem_rdata_i & ~mask_q) | (mem_wdata_i & mask_q);
        end else begin
          mem_wdata_o = masked_data_q;
        end

        // grant original request once write request is granted
        if (mem_gnt_i) begin
          mem_gnt_o = 1'b1;
        end
      end // case: RMW_MODIFY_WRITE

      RMW_FINAL: begin

        // Mem-side
        mem_req_o = 1'b0;
        mem_addr_o = '0;
        mem_wdata_o = '0;
        mem_we_o = 1'b0;
        // Request-side
        mem_gnt_o = 1'b0;
        mem_rvalid_o = mem_rvalid_i;
        mem_rdata_o = '0;

        // (READ) forward masked data to original request
        if (!mem_we_i && mem_rvalid_i) begin
          mem_rdata_o = mem_rdata_i & mask_q;
        end
      end

      default: ;
    endcase
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      req_state_q <= NORMAL;
      mask_q <= '0;
      masked_data_q <= '0;
    end else begin
      req_state_q <= req_state_d;
      mask_q <= mask_d;
      masked_data_q <= masked_data_d;
    end
  end

endmodule
