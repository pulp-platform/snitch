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

// ----- 8< -----

<%
  reg_bus = RegBus(
    xbar.clk,
    xbar.rst,
    xbar.aw,
    xbar.dw,
    "in",
    declared=True,
  )
%>

${reg_bus.req_type()} [${len(xbar.inputs)-1}:0] ${xbar.name}_in_req;
${reg_bus.rsp_type()} [${len(xbar.inputs)-1}:0] ${xbar.name}_in_rsp;
${reg_bus.req_type()} [${len(xbar.outputs)-1}:0] ${xbar.name}_out_req;
${reg_bus.rsp_type()} [${len(xbar.outputs)-1}:0] ${xbar.name}_out_rsp;

logic [cf_math_pkg::idx_width(${xbar.name.upper()}_NUM_OUTPUTS)-1:0] ${xbar.name}_select;

// The `${xbar.name}` crossbar.
reg_demux #(
  .NoPorts ( ${xbar.name.upper()}_NUM_OUTPUTS ),
  .req_t ( ${reg_bus.req_type()} ),
  .rsp_t ( ${reg_bus.rsp_type()} )
) i_${xbar.name} (
  .clk_i  ( ${xbar.clk} ),
  .rst_ni ( ${xbar.rst} ),
  .in_select_i (${xbar.name}_select),
  .in_req_i (${xbar.name}_in_req),
  .in_rsp_o (${xbar.name}_in_rsp),
  .out_req_o (${xbar.name}_out_req),
  .out_rsp_i (${xbar.name}_out_rsp)
);

addr_decode #(
  .NoIndices (${xbar.name.upper()}_NUM_OUTPUTS),
  .NoRules (${len(xbar.addrmap)}),
  .addr_t (logic [${xbar.aw-1}:0]),
  .rule_t (xbar_rule_${xbar.aw}_t)
) i_addr_decode_${xbar.name}(
  .addr_i (${xbar.name}_in_req[0].addr),
  .addr_map_i (${addrmap_name}),
  .idx_o (${xbar.name}_select),
  .dec_valid_o (),
  .dec_error_o (),
  .en_default_idx_i ('0),
  .default_idx_i ('0)
);

<%
for name, enum in zip(xbar.inputs, input_enums):
  bus = RegBus(
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
  bus = RegBus(
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

