  axi_id_remap #(
    .AxiSlvPortIdWidth ( ${axi_in.iw} ),
    .AxiSlvPortMaxUniqIds ( 4 ),
    .AxiMaxTxnsPerId ( 4 ),
    .AxiMstPortIdWidth ( ${axi_out.iw} ),
    .slv_req_t ( ${axi_in.req_type()} ),
    .slv_resp_t ( ${axi_in.rsp_type()} ),
    .mst_req_t ( ${axi_out.req_type()} ),
    .mst_resp_t ( ${axi_out.rsp_type()} )
  ) ${name} (
    .clk_i ( ${axi_in.clk} ),
    .rst_ni ( ${axi_in.rst} ),
    .slv_req_i ( ${axi_in.req_name()} ),
    .slv_resp_o ( ${axi_in.rsp_name()} ),
    .mst_req_o ( ${axi_out.req_name()} ),
    .mst_resp_i ( ${axi_out.rsp_name()} )
  ); \
