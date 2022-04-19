  axi_lite_to_axi #(
    .AxiDataWidth ( ${bus_in.dw} ),
    .req_lite_t   ( ${bus_in.req_type()} ),
    .resp_lite_t  ( ${bus_in.rsp_type()} ),
    .axi_req_t    ( ${bus_out.req_type()} ),
    .axi_resp_t   ( ${bus_out.rsp_type()} )
  ) ${name} (
    .slv_req_lite_i  ( ${bus_in.req_name()} ),
    .slv_resp_lite_o ( ${bus_in.rsp_name()} ),
    .slv_aw_cache_i  ( axi_pkg::CACHE_MODIFIABLE ),
    .slv_ar_cache_i  ( axi_pkg::CACHE_MODIFIABLE ),
    .mst_req_o       ( ${bus_out.req_name()} ),
    .mst_resp_i      ( ${bus_out.rsp_name()} )
  );
