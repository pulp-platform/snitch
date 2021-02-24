  axi_lite_to_reg #(
    .ADDR_WIDTH     ( ${bus_in.aw} ),
    .DATA_WIDTH     ( ${bus_in.dw} ),
    .axi_lite_req_t ( ${bus_in.req_type()} ),
    .axi_lite_rsp_t ( ${bus_in.rsp_type()} ),
    .reg_req_t      ( ${bus_out.req_type()} ),
    .reg_rsp_t      ( ${bus_out.rsp_type()} )
  ) ${name} (
    .clk_i          ( ${bus_in.clk} ),
    .rst_ni         ( ${bus_in.rst} ),
    .axi_lite_req_i ( ${bus_in.req_name()} ),
    .axi_lite_rsp_o ( ${bus_in.rsp_name()} ),
    .reg_req_o      ( ${bus_out.req_name()} ),
    .reg_rsp_i      ( ${bus_out.rsp_name()} )
  );
