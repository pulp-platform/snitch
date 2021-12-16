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


/// Address map of the `soc_quadrant_xbar` crossbar.
xbar_rule_48_t [7:0] SocQuadrantXbarAddrmap;
assign SocQuadrantXbarAddrmap = '{
  '{ idx: 1, start_addr: s1_quadrant_base_addr[0], end_addr: s1_quadrant_base_addr[0] + S1QuadrantAddressSpace },
  '{ idx: 2, start_addr: s1_quadrant_base_addr[1], end_addr: s1_quadrant_base_addr[1] + S1QuadrantAddressSpace },
  '{ idx: 3, start_addr: s1_quadrant_base_addr[2], end_addr: s1_quadrant_base_addr[2] + S1QuadrantAddressSpace },
  '{ idx: 4, start_addr: s1_quadrant_base_addr[3], end_addr: s1_quadrant_base_addr[3] + S1QuadrantAddressSpace },
  '{ idx: 5, start_addr: s1_quadrant_base_addr[4], end_addr: s1_quadrant_base_addr[4] + S1QuadrantAddressSpace },
  '{ idx: 6, start_addr: s1_quadrant_base_addr[5], end_addr: s1_quadrant_base_addr[5] + S1QuadrantAddressSpace },
  '{ idx: 7, start_addr: s1_quadrant_base_addr[6], end_addr: s1_quadrant_base_addr[6] + S1QuadrantAddressSpace },
  '{ idx: 8, start_addr: s1_quadrant_base_addr[7], end_addr: s1_quadrant_base_addr[7] + S1QuadrantAddressSpace }
};

soc_quadrant_xbar_in_req_t [8:0] soc_quadrant_xbar_in_req;
soc_quadrant_xbar_in_resp_t [8:0] soc_quadrant_xbar_in_rsp;
soc_quadrant_xbar_out_req_t [8:0] soc_quadrant_xbar_out_req;
soc_quadrant_xbar_out_resp_t [8:0] soc_quadrant_xbar_out_rsp;

axi_xbar #(
  .Cfg           ( SocQuadrantXbarCfg ),
  .Connectivity  ( 81'b111111111111111111111111111111111111111111111111111111111111111111111111111111110 ),
  .AtopSupport   ( 1 ),
  .slv_aw_chan_t ( axi_a48_d64_i5_u0_aw_chan_t ),
  .mst_aw_chan_t ( axi_a48_d64_i9_u0_aw_chan_t ),
  .w_chan_t      ( axi_a48_d64_i5_u0_w_chan_t ),
  .slv_b_chan_t  ( axi_a48_d64_i5_u0_b_chan_t ),
  .mst_b_chan_t  ( axi_a48_d64_i9_u0_b_chan_t ),
  .slv_ar_chan_t ( axi_a48_d64_i5_u0_ar_chan_t ),
  .mst_ar_chan_t ( axi_a48_d64_i9_u0_ar_chan_t ),
  .slv_r_chan_t  ( axi_a48_d64_i5_u0_r_chan_t ),
  .mst_r_chan_t  ( axi_a48_d64_i9_u0_r_chan_t ),
  .slv_req_t     ( axi_a48_d64_i5_u0_req_t ),
  .slv_resp_t    ( axi_a48_d64_i5_u0_resp_t ),
  .mst_req_t     ( axi_a48_d64_i9_u0_req_t ),
  .mst_resp_t    ( axi_a48_d64_i9_u0_resp_t ),
  .rule_t        ( xbar_rule_48_t )
) i_soc_quadrant_xbar (
  .clk_i  ( clk_i ),
  .rst_ni ( rst_ni ),
  .test_i ( test_mode_i ),
  .slv_ports_req_i  ( soc_quadrant_xbar_in_req  ),
  .slv_ports_resp_o ( soc_quadrant_xbar_in_rsp  ),
  .mst_ports_req_o  ( soc_quadrant_xbar_out_req ),
  .mst_ports_resp_i ( soc_quadrant_xbar_out_rsp ),
  .addr_map_i       ( SocQuadrantXbarAddrmap ),
  .en_default_mst_port_i ( '1 ),
  .default_mst_port_i    ( '0 )
);


assign soc_quadrant_xbar_in_req     = soc_quadrant_xbar_in_req_i;
assign soc_quadrant_xbar_in_rsp_o   = soc_quadrant_xbar_in_rsp;
assign soc_quadrant_xbar_out_req_o  = soc_quadrant_xbar_out_req;
assign soc_quadrant_xbar_out_rsp    = soc_quadrant_xbar_out_rsp_i;

endmodule