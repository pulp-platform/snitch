`include "common_cells/registers.svh"

module snitch_ssr_addr_filter import snitch_ssr_pkg::*; #(
  parameter type tcdm_addr_t = logic [16:0]                            
) (
   input logic  clk_i,
   input logic  rst_ni,
   // interface for agu
   input logic  agen_valid_i,
   output logic agen_ready_o,
   input        tcdm_addr_t gen_addr_i,
   input logic  agen_stream_last_i,
   output tcdm_addr_t gen_addr_o,
   // interface for mem request
   output logic mem_req_valid_o,
   input logic  mem_rsp_ready_i,
   // interface for downstream fifo
   output       meta_data_t meta_data_o,
   output logic meta_valid_o,
   input logic  meta_ready_i
  );

  tcdm_addr_t gen_addr_d, gen_addr_q;
  logic addr_valid, addr_ready;
  logic agen_in_ready;
  meta_data_t meta_data;
 
  stream_register #(
    .T(tcdm_addr_t)
  ) i_addr_stream_register(
    .clk_i,
    .rst_ni,
    .clr_i ('0),
    .testmode_i (1'b0),
    .valid_i ( agen_valid_i      ),
    .ready_o ( agen_in_ready     ),
    .data_i  ( gen_addr_i        ),
    .valid_o ( addr_valid        ),
    .ready_i ( addr_ready        ),
    .data_o  ( gen_addr_d        )
  );
  assign agen_ready_o = agen_in_ready;
  assign addr_ready = meta_ready_i;
  `FFARN(gen_addr_q, gen_addr_d, '0, clk_i, rst_ni)
   assign gen_addr_o = gen_addr_d;
   
  assign meta_data.stream_last = agen_stream_last_i;
  assign meta_data.offset = gen_addr_d[2];
  assign meta_data.fetch = (gen_addr_q[16:3] ^ gen_addr_d[16:3]) ? 1'b1 : 1'b0;

  assign mem_req_valid_o = (meta_data.fetch | meta_data.stream_last) & addr_valid;

  assign meta_data_o = meta_data;
  assign meta_valid_o = addr_valid;
 
endmodule

   
   
