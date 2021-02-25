  snitch_const_cache #(
    .LineWidth (${line_width}),
    .LineCount (${line_count}),
    .SetCount (${set_count}),
    .AxiAddrWidth (${axi_in.aw}),
    .AxiDataWidth (${axi_in.dw}),
    .AxiIdWidth (${axi_in.iw}),
    .AxiUserWidth (1),
    .MaxTrans (MaxTransaction),
    .NrAddrRules (1),
    .slv_req_t (${axi_in.req_type()}),
    .slv_rsp_t (${axi_in.rsp_type()}),
    .mst_req_t (${axi_out.req_type()}),
    .mst_rsp_t (${axi_out.rsp_type()})
  ) ${name} (
    .clk_i (${axi_in.clk}),
    .rst_ni (${axi_in.rst}),
    // TODO(zarubaf): Fix
    .flush_valid_i (${flush_valid}),
    .flush_ready_o (${flush_ready}),
    .start_addr_i (${start_addr}),
    .end_addr_i (${end_addr}),
    .axi_slv_req_i (${axi_in.req_name()}),
    .axi_slv_rsp_o (${axi_in.rsp_name()}),
    .axi_mst_req_o (${axi_out.req_name()}),
    .axi_mst_rsp_i (${axi_out.rsp_name()})
  );
