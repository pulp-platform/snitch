module snitch_ssr_mux #(
  parameter int unsigned AddrWidth = 32,
  parameter int unsigned DataWidth = 32,
  /// Derived parameter *Do not override*
  parameter type addr_t = logic [AddrWidth-1:0],
  parameter type data_t = logic [DataWidth-1:0],
  parameter type data_t_core = logic [31:0]                      
) (
  input logic             clk_i,
  input logic             rst_ni,
  // SSR Interface for FP datapath
  input  logic  [2:0][4:0] ssr_fp_raddr_i,
  output data_t [2:0]      ssr_fp_rdata_o,
  input  logic  [2:0]      ssr_fp_rvalid_i,
  output logic  [2:0]      ssr_fp_rready_o,
  input  logic  [2:0]      ssr_fp_rdone_i,
  input  logic  [0:0][4:0] ssr_fp_waddr_i,
  input  data_t [0:0]      ssr_fp_wdata_i,
  input  logic  [0:0]      ssr_fp_wvalid_i,
  output logic  [0:0]      ssr_fp_wready_o,
  input  logic  [0:0]      ssr_fp_wdone_i,
  // SSR Interface for integer datapath
  input  logic       [1:0][4:0] ssr_int_raddr_i,
  output data_t_core [1:0]      ssr_int_rdata_o,
  input  logic       [1:0]      ssr_int_rvalid_i,
  output logic       [1:0]      ssr_int_rready_o,
  input  logic       [1:0]      ssr_int_rdone_i,
  input  logic       [0:0][4:0] ssr_int_waddr_i,
  input  data_t_core [0:0]      ssr_int_wdata_i,
  input  logic       [0:0]      ssr_int_wvalid_i,
  output logic       [0:0]      ssr_int_wready_o,
  input  logic       [0:0]      ssr_int_wdone_i,
  input  logic                  ssr_sel_i,
  // SSR Interface for the ssr streamer
  output logic  [2:0][4:0] ssr_raddr_o,
  input  data_t [2:0]      ssr_rdata_i,
  output logic  [2:0]      ssr_rvalid_o,
  input  logic  [2:0]      ssr_rready_i,
  output logic  [2:0]      ssr_rdone_o,
  output logic  [0:0][4:0] ssr_waddr_o,
  output data_t [0:0]      ssr_wdata_o,
  output logic  [0:0]      ssr_wvalid_o,
  input  logic  [0:0]      ssr_wready_i,
  output logic  [0:0]      ssr_wdone_o
);

   logic [1:0][31:0]       rdata;
   for (genvar i = 0; i < 2; i++) assign rdata[i][31:0] = ssr_rdata_i[i][31:0];
   
   //assign rdata[0][31:0] = ssr_rdata_i[0][31:0];
   //assign rdata[1][31:0] = ssr_rdata_i[1][31:0];
/*
   always_comb begin
      if (ssr_sel_i) begin
         ssr_raddr_o = ssr_fp_raddr_i;
         ssr_fp_rdata_o = ssr_rdata_i;
         ssr_rvalid_o = ssr_fp_rvalid_i;
         ssr_rdone_o = ssr_fp_rdone_i;
         ssr_waddr_o = ssr_fp_waddr_i;
         ssr_wdata_o = ssr_fp_wdata_i;
         ssr_wvalid_o = ssr_fp_wvalid_i;
         ssr_wdone_o = ssr_fp_wdone_i;
         ssr_fp_rready_o = ssr_rready_i;
         ssr_fp_wready_o = ssr_wready_i;
      end
      else begin
        ssr_raddr_o = {'0, ssr_int_raddr_i};
        ssr_int_rdata_o = rdata;
        ssr_rvalid_o = {'0, ssr_int_rvalid_i};
        ssr_rdone_o  = {'0, ssr_int_rdone_i};
        ssr_waddr_o = ssr_int_waddr_i;
        ssr_wdata_o = ssr_int_wdata_i;
        ssr_wvalid_o = ssr_int_wvalid_i;
        ssr_wdone_o = ssr_int_wdone_i;
        ssr_int_rready_o = ssr_rready_i[1:0];
        ssr_int_wready_o = ssr_wready_i;
      end
   end
*/   
   
   assign ssr_raddr_o = {'0, ssr_int_raddr_i};
   assign ssr_int_rdata_o = rdata;
   assign ssr_rvalid_o = {'0, ssr_int_rvalid_i};
   assign ssr_rdone_o  = {'0, ssr_int_rdone_i};
   assign ssr_waddr_o = ssr_int_waddr_i;
   assign ssr_wdata_o = ssr_int_wdata_i;
   assign ssr_wvalid_o = ssr_int_wvalid_i;
   assign ssr_wdone_o = ssr_int_wdone_i;
   assign ssr_int_rready_o = ssr_rready_i[1:0];
   assign ssr_int_wready_o = ssr_wready_i;
  
endmodule


   
   
  
                        
