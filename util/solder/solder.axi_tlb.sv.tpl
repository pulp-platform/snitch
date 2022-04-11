axi_tlb #(
  .AxiSlvPortAddrWidth(${axi_in.aw}),
  .AxiMstPortAddrWidth(${axi_out.aw}),
  .AxiDataWidth(${axi_in.dw}),
  .AxiIdWidth(${axi_in.iw}),
  .AxiUserWidth (${max(axi_in.uw, 1)}),
  .AxiSlvPortMaxTxns(${cfg["max_trans"]}),
  .CfgAxiAddrWidth(${axi_lite.aw}),
  .CfgAxiDataWidth(${axi_lite.dw}),
  .L1NumEntries(${cfg["l1_num_entries"]}),
  .L1CutAx(${"1'b1" if cfg["l1_cut_ax"] else "1'b0"}),
  .slv_req_t(${axi_in.req_type()}),
  .mst_req_t(${axi_out.req_type()}),
  .axi_resp_t(${axi_in.rsp_type()}),
  .lite_req_t(${axi_lite.req_type()}),
  .lite_resp_t(${axi_lite.rsp_type()})
) ${name} (
  .clk_i (${axi_in.clk}),
  .rst_ni (${axi_in.rst}),
  .test_en_i(test_mode_i),
  .slv_req_i (${axi_in.req_name()}),
  .slv_resp_o (${axi_in.rsp_name()}),
  .mst_req_o (${axi_out.req_name()}),
  .mst_resp_i (${axi_out.rsp_name()}),
  .cfg_req_i (${axi_lite.req_name()}),
  .cfg_resp_o (${axi_lite.rsp_name()})
);
