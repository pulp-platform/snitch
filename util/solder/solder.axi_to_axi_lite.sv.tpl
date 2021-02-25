  axi_to_axi_lite #(
    .AxiAddrWidth ( ${bus_in.aw} ),
    .AxiDataWidth ( ${bus_in.dw} ),
    .AxiIdWidth ( ${bus_in.iw} ),
    .AxiUserWidth ( ${max(bus_in.uw, 1)} ),
    .AxiMaxWriteTxns ( 4  ),
    .AxiMaxReadTxns ( 4  ),
    .FallThrough ( 0  ),
    .full_req_t ( ${bus_in.req_type()} ),
    .full_resp_t ( ${bus_in.rsp_type()} ),
    .lite_req_t ( ${bus_out.req_type()} ),
    .lite_resp_t ( ${bus_out.rsp_type()} )
  ) ${name} (
    .clk_i (${bus_in.clk}),
    .rst_ni (${bus_in.rst}),
    .test_i (test_mode_i),
    .slv_req_i (${bus_in.req_name()}),
    .slv_resp_o (${bus_in.rsp_name()}),
    .mst_req_o (${bus_out.req_name()}),
    .mst_resp_i (${bus_out.rsp_name()})
  );
