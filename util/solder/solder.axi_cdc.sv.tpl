  axi_cdc #(
    .aw_chan_t  ( ${bus_in.type_prefix}_aw_t ),
    .w_chan_t   ( ${bus_in.type_prefix}_w_t ),
    .b_chan_t   ( ${bus_in.type_prefix}_b_t ),
    .ar_chan_t  ( ${bus_in.type_prefix}_ar_t ),
    .r_chan_t   ( ${bus_in.type_prefix}_r_t ),
    .axi_req_t  ( ${bus_in.req_type()} ),
    .axi_resp_t ( ${bus_in.rsp_type()} ),
    .LogDepth   ( ${log_depth} )
  ) ${name} (
    .src_clk_i ( ${bus_in.clk} ),
    .src_rst_ni ( ${bus_in.rst} ),
    .src_req_i ( ${bus_in.req_name()} ),
    .src_resp_o ( ${bus_in.rsp_name()} ),
    .dst_clk_i ( ${bus_out.clk} ),
    .dst_rst_ni ( ${bus_out.rst} ),
    .dst_req_o ( ${bus_out.req_name()} ),
    .dst_resp_i ( ${bus_out.rsp_name()} )
  );
