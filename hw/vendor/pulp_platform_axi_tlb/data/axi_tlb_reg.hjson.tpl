// Copyright 2018-2021 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Paul Scheffler <paulsc@iis.ee.ethz.ch>

<%def name="reg64(field_name, field_desc)">
    { name: "${tlb_name.upper()}_${field_name.upper()}_LOW",
      desc: "${field_desc} (lower 32 bit)",
      swaccess: "rw",
      hwaccess: "hro",
      fields: [
        {bits: "31:0", name: "low", desc: "lower 32 bit"}
      ]
    },
  % if addr_width > 32:
    { name: "${tlb_name.upper()}_${field_name.upper()}_HIGH",
      desc: "${field_desc} (upper 32 bit)",
      swaccess: "rw",
      hwaccess: "hro",
      fields: [
        {bits: "${addr_width-32-1}:0", name: "high", desc: "upper 32 bit"}
      ]
    },
  % else:
    { reserved: 1 },
  % endif
</%def>

{
  name: "axi_${tlb_name}",
  clock_primary: "clk_i",
  bus_interfaces: [
    { protocol: "reg_iface", direction: "device" }
  ],
  regwidth: 32,
  registers: [

    // Control registers for ${tlb_name.upper()} (aligned to entry size of 32 bytes)

    { name: "${tlb_name.upper()}_ENABLE",
      desc: "Enable ${tlb_name.upper()}",
      swaccess: "rw",
      hwaccess: "hro",
      fields: [
        { bits: "0:0", resval: 0, name: "enable", desc: "Enable ${tlb_name.upper()}"}
      ]
    },
    { reserved: 7 }

    % for e in range(num_entries):
    // ${tlb_name} entry ${e}
    ${reg64(f"entry_{e}_pagein_first",  f"First page number of input range of {tlb_name} entry {e}")}\
    ${reg64(f"entry_{e}_pagein_last",  f"Last page number of input range of {tlb_name} entry {e}")}\
    ${reg64(f"entry_{e}_pageout", f"Number of output base page of {tlb_name} entry {e}")}
    { name: "${tlb_name.upper()}_ENTRY_${e}_FLAGS",
      desc: "Flags for ${tlb_name} entry ${e}",
      swaccess: "rw",
      hwaccess: "hro",
      fields: [
        {bits: "0:0", name: "valid",  resval: 0, desc: "Whether ${tlb_name} entry ${e} is valid and should be mapped"},
        {bits: "1:1", name: "read_only", resval: 0, desc: "Whether ${tlb_name} entry ${e} maps read-only range"},
      ]
    },
    { reserved: 1 }

    % endfor
  ]
}
