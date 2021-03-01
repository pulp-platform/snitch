<%
cfg_name = util.pascalize("{}_cfg".format(xbar.name))
input_enum_name = "{}_inputs_e".format(xbar.name)
output_enum_name = "{}_outputs_e".format(xbar.name)
addrmap_name = util.pascalize("{}_addrmap".format(xbar.name))

input_enums = list()
output_enums = list()
%>

/// Inputs of the `${xbar.name}` crossbar.
typedef enum int {
  % for name in xbar.inputs:
  <%
    enum = "{}_in_{}".format(xbar.name, name).upper()
    input_enums.append(enum)
  %>${enum},
  % endfor
  ${xbar.name.upper()}_NUM_INPUTS
} ${input_enum_name};

/// Outputs of the `${xbar.name}` crossbar.
typedef enum int {
  % for name in xbar.outputs:
  <%
    enum = "{}_out_{}".format(xbar.name, name).upper()
    output_enums.append(enum)
  %>${enum},
  % endfor
  ${xbar.name.upper()}_NUM_OUTPUTS
} ${output_enum_name};

/// Configuration of the `${xbar.name}` crossbar.
localparam axi_pkg::xbar_cfg_t ${cfg_name} = '{
  NoSlvPorts:         ${xbar.name.upper()}_NUM_INPUTS,
  NoMstPorts:         ${xbar.name.upper()}_NUM_OUTPUTS,
  MaxSlvTrans:        4,
  MaxMstTrans:        4,
  FallThrough:        0,
  LatencyMode:        axi_pkg::CUT_ALL_PORTS,
  AxiIdWidthSlvPorts: 0,
  AxiIdUsedSlvPorts:  0,
  AxiAddrWidth:       ${xbar.aw},
  AxiDataWidth:       ${xbar.dw},
  NoAddrRules:        ${len(xbar.addrmap)}
};

/// Address map of the `${xbar.name}` crossbar.
localparam xbar_rule_${xbar.aw}_t [${len(xbar.addrmap) - 1}:0] ${addrmap_name} = '{
% for i in range(len(xbar.addrmap)):
  ${"'{{ idx: {}, start_addr: {aw}'h{:08x}, end_addr: {aw}'h{:08x} }}{sep}".format(
    *xbar.addrmap[i],
    sep="," if i != len(xbar.addrmap) - 1 else "",
    aw=xbar.aw
  )}
% endfor
};

// AXI plugs of the `${xbar.name}` crossbar.
<% struct = AxiLiteStruct.emit(xbar.aw, xbar.dw) %>
% for tds in ["req", "rsp", "aw_chan", "w_chan", "b_chan", "ar_chan", "r_chan"]:
typedef ${struct}_${tds}_t ${xbar.name}_in_${tds}_t;
typedef ${struct}_${tds}_t ${xbar.name}_out_${tds}_t;
% endfor

// ----- 8< -----

${struct}_req_t [${len(xbar.inputs)-1}:0] ${xbar.name}_in_req;
${struct}_rsp_t [${len(xbar.inputs)-1}:0] ${xbar.name}_in_rsp;
${struct}_req_t [${len(xbar.outputs)-1}:0] ${xbar.name}_out_req;
${struct}_rsp_t [${len(xbar.outputs)-1}:0] ${xbar.name}_out_rsp;

// The `${xbar.name}` crossbar.
axi_lite_xbar #(
  .Cfg       ( ${cfg_name} ),
  .aw_chan_t ( ${struct}_aw_chan_t ),
  .w_chan_t  ( ${struct}_w_chan_t ),
  .b_chan_t  ( ${struct}_b_chan_t ),
  .ar_chan_t ( ${struct}_ar_chan_t ),
  .r_chan_t  ( ${struct}_r_chan_t ),
  .req_t     ( ${struct}_req_t ),
  .resp_t    ( ${struct}_rsp_t ),
  .rule_t    ( xbar_rule_${xbar.aw}_t )
) i_${xbar.name} (
  .clk_i  ( ${xbar.clk} ),
  .rst_ni ( ${xbar.rst} ),
  .test_i ( test_mode_i ),
  .slv_ports_req_i  ( ${xbar.name}_in_req  ),
  .slv_ports_resp_o ( ${xbar.name}_in_rsp  ),
  .mst_ports_req_o  ( ${xbar.name}_out_req ),
  .mst_ports_resp_i ( ${xbar.name}_out_rsp ),
  .addr_map_i       ( ${addrmap_name} ),
  .en_default_mst_port_i ( '1 ),
  .default_mst_port_i    ( '0 )
);

<%
for name, enum in zip(xbar.inputs, input_enums):
  bus = AxiLiteBus(
    xbar.clk,
    xbar.rst,
    xbar.aw,
    xbar.dw,
    "{}_in".format(xbar.name),
    "[{}]".format(enum),
    type_prefix=input_struct,
    declared=True,
  )
  xbar.__dict__["in_"+name] = bus

for name, enum in zip(xbar.outputs, output_enums):
  bus = AxiLiteBus(
    xbar.clk,
    xbar.rst,
    xbar.aw,
    xbar.dw,
    "{}_out".format(xbar.name),
    "[{}]".format(enum),
    type_prefix=output_struct,
    declared=True,
  )
  xbar.__dict__["out_"+name] = bus
%>
