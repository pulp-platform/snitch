axi_multicut #(
  .NoCuts (${nr_cuts}),
  .aw_chan_t (${bus_in.type_prefix}_aw_chan_t),
  .w_chan_t (${bus_in.type_prefix}_w_chan_t),
  .b_chan_t (${bus_in.type_prefix}_b_chan_t),
  .ar_chan_t (${bus_in.type_prefix}_ar_chan_t),
  .r_chan_t (${bus_in.type_prefix}_r_chan_t),
  .req_t (${bus_in.req_type()}),
  .resp_t (${bus_in.rsp_type()})
) ${name} (
  .clk_i (${bus_in.clk}),
  .rst_ni (${bus_in.rst}),
  .slv_req_i (${bus_in.req_name()}),
  .slv_resp_o (${bus_in.rsp_name()}),
  .mst_req_o (${bus_out.req_name()}),
  .mst_resp_i (${bus_out.rsp_name()})
);\
