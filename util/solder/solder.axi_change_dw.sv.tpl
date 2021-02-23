  axi_dw_converter #(
    .AxiSlvPortDataWidth ( ${axi_in.dw} ),
    .AxiMstPortDataWidth ( ${axi_out.dw} ),
    .AxiAddrWidth        ( ${axi_in.aw} ),
    .AxiIdWidth          ( ${axi_in.iw} ),
    .aw_chan_t           ( ${axi_out.type_prefix}_aw_t ),
    .mst_w_chan_t        ( ${axi_out.type_prefix}_w_t ),
    .slv_w_chan_t        ( ${axi_in.type_prefix}_w_t ),
    .b_chan_t            ( ${axi_out.type_prefix}_b_t ),
    .ar_chan_t           ( ${axi_out.type_prefix}_ar_t ),
    .mst_r_chan_t        ( ${axi_out.type_prefix}_r_t ),
    .slv_r_chan_t        ( ${axi_in.type_prefix}_r_t ),
    .axi_mst_req_t       ( ${axi_out.type_prefix}_req_t ),
    .axi_mst_resp_t      ( ${axi_out.type_prefix}_rsp_t ),
    .axi_slv_req_t       ( ${axi_in.type_prefix}_req_t ),
    .axi_slv_resp_t      ( ${axi_in.type_prefix}_rsp_t )
  ) ${name} (
    .clk_i      ( ${axi_in.clk} ),
    .rst_ni     ( ${axi_in.rst} ),
    .slv_req_i  ( ${axi_in.req_name()} ),
    .slv_resp_o ( ${axi_in.rsp_name()} ),
    .mst_req_o  ( ${axi_out.req_name()} ),
    .mst_resp_i ( ${axi_out.rsp_name()} )
  );
