  axi_atop_filter #(
    .AxiIdWidth (${bus_in.iw}),
    .AxiMaxWriteTxns (${max_trans}),
    .axi_req_t (${bus_in.req_type()}),
    .axi_resp_t (${bus_in.rsp_type()})
  ) ${name} (
    .clk_i     (${bus_in.clk}),
    .rst_ni    (${bus_in.rst}),
    .slv_req_i (${bus_in.req_name()}),
    .slv_resp_o(${bus_in.rsp_name()}),
    .mst_req_o (${bus_out.req_name()}),
    .mst_resp_i(${bus_out.rsp_name()})
  );
