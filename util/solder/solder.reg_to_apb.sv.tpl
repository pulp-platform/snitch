  reg_to_apb #(
    .reg_req_t ( ${bus_in.req_type()} ),
    .reg_rsp_t ( ${bus_in.rsp_type()} ),
    .apb_req_t ( ${bus_out.req_type()} ),
    .apb_rsp_t ( ${bus_out.rsp_type()} )
  ) ${name} (
    .clk_i (${bus_in.clk}),
    .rst_ni (${bus_in.rst}),
    .reg_req_i (${bus_in.req_name()}),
    .reg_rsp_o (${bus_in.rsp_name()}),
    .apb_req_o (${bus_out.req_name()}),
    .apb_rsp_i (${bus_out.rsp_name()})
  );