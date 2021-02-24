  axi_lite_to_axi #(
    .AxiDataWidth ( ${bus_in.dw} ),
    .req_lite_t   ( ${bus_in.req_type()} ),
    .resp_lite_t  ( ${bus_in.rsp_type()} ),
    .req_t        ( ${bus_out.req_type()} ),
    .resp_t       ( ${bus_out.rsp_type()} )
  ) ${name} (
    .slv_req_lite_i  ( ${bus_in.req_name()} ),
    .slv_resp_lite_o ( ${bus_in.rsp_name()} ),
    .mst_req_o       ( ${bus_out.req_name()} ),
    .mst_resp_i      ( ${bus_out.rsp_name()} )
  );
