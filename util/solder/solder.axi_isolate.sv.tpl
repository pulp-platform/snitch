  axi_isolate #(
    .NumPending ( ${num_pending} ),
    .TerminateTransaction ( ${int(terminated)} ),
    .AtopSupport ( ${int(atop_support)} ),
    .AxiIdWidth ( ${axi_in.iw} ),
    .AxiAddrWidth ( ${axi_in.aw} ),
    .AxiDataWidth ( ${axi_in.dw} ),
    .AxiUserWidth ( ${max(1, axi_in.uw)} ),
    .axi_req_t ( ${axi_in.req_type()} ),
    .axi_resp_t ( ${axi_in.rsp_type()} )
  ) ${name} (
    .clk_i ( ${axi_in.clk} ),
    .rst_ni ( ${axi_in.rst} ),
    .slv_req_i ( ${axi_in.req_name()} ),
    .slv_resp_o ( ${axi_in.rsp_name()} ),
    .mst_req_o ( ${axi_out.req_name()} ),
    .mst_resp_i ( ${axi_out.rsp_name()} ),
    .isolate_i ( ${isolate} ),
    .isolated_o ( ${isolated} )
  );
