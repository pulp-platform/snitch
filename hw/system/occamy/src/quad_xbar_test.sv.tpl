module quad_xbar_test
  import quad_xbar_test_pkg::*;
(
  input  clk_i,
  input  rst_ni,
  input  test_mode_i,

  input  soc_quadrant_xbar_in_req_t [8:0]    soc_quadrant_xbar_in_req_i,
  output soc_quadrant_xbar_in_resp_t [8:0]   soc_quadrant_xbar_in_rsp_o,
  output soc_quadrant_xbar_out_req_t [8:0]   soc_quadrant_xbar_out_req_o,
  input  soc_quadrant_xbar_out_resp_t [8:0]  soc_quadrant_xbar_out_rsp_i
);

${module}

assign soc_quadrant_xbar_in_req     = soc_quadrant_xbar_in_req_i;
assign soc_quadrant_xbar_in_rsp_o   = soc_quadrant_xbar_in_rsp;
assign soc_quadrant_xbar_out_req_o  = soc_quadrant_xbar_out_req;
assign soc_quadrant_xbar_out_rsp    = soc_quadrant_xbar_out_rsp_i;

endmodule