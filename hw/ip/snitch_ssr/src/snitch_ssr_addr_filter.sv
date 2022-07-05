`include "common_cells/registers.svh"

module snitch_ssr_addr_filter import snitch_ssr_pkg::*; #(
  parameter type tcdm_addr_t = logic [16:0]                            
) (
   input logic         clk_i,
   input logic         rst_ni,
   // receiving address from the AGU
   input  tcdm_addr_t  gen_addr_i,
   input  logic        agen_stream_last_i,
   input  logic        agen_valid_i,
   output logic        agen_ready_o,
   // interface for memory request
   output tcdm_addr_t  gen_addr_o,
   output logic        mem_req_valid_o,
   input  logic        mem_rsp_ready_i,
   // interface for downstream fifo
   output meta_data_t  meta_data_o,
   output logic        meta_valid_o,
   input  logic        meta_ready_i
);

  tcdm_addr_t gen_addr_q;
  meta_data_t meta_data;
  logic agen_hs;

  assign agen_hs = agen_valid_i & agen_ready_o;

  `FFLARN(gen_addr_q, gen_addr_i, agen_hs, '0, clk_i, rst_ni)
  assign gen_addr_o = gen_addr_i;
  assign agen_ready_o =  mem_rsp_ready_i & meta_ready_i;

  assign meta_data.stream_last = agen_stream_last_i;
  assign meta_data.offset = gen_addr_i[2];
  assign meta_data.fetch = (gen_addr_q[16:3] ^ gen_addr_i[16:3]) ? 1'b1 : 1'b0;

  assign meta_data_o = meta_data;
  assign meta_valid_o = agen_hs ;
  assign mem_req_valid_o = agen_hs & meta_data.fetch;  

endmodule

   
   
