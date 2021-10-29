  axi_modify_address #(
    .slv_req_t (${axi_in.req_type()}),
    .mst_addr_t (${axi_out.addr_type()}),
    .mst_req_t (${axi_out.req_type()}),
    .axi_resp_t (${axi_in.rsp_type()})
  ) ${name} (
    .slv_req_i (${axi_in.req_name()}),
    .slv_resp_o (${axi_in.rsp_name()}),
    .mst_aw_addr_i ({${axi_in.aw-target_aw}'b0, ${axi_in.req_name()}.aw.addr[${target_aw-1}:0]}),
    .mst_ar_addr_i ({${axi_in.aw-target_aw}'b0, ${axi_in.req_name()}.ar.addr[${target_aw-1}:0]}),
    .mst_req_o (${axi_out.req_name()}),
    .mst_resp_i (${axi_out.rsp_name()})
  );
