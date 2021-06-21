  axi_serializer #(
    .MaxReadTxns ( 4 ),
    .MaxWriteTxns ( 4 ),
    .AxiIdWidth ( ${axi_in.iw} ),
    .req_t ( ${axi_in.req_type()} ),
    .resp_t ( ${axi_in.rsp_type()} )
  ) ${name} (
    .clk_i ( ${axi_in.clk} ),
    .rst_ni ( ${axi_in.rst} ),
    .slv_req_i ( ${axi_in.req_name()} ),
    .slv_resp_o ( ${axi_in.rsp_name()} ),
    .mst_req_o ( ${axi_out.req_name()} ),
    .mst_resp_i ( ${axi_out.rsp_name()} )
  ); \
