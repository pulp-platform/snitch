// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
// Licensed under Solderpad Hardware License, Version 0.51, see LICENSE for details.
{
  name: "Occamy_quadrant_s1",
  clock_primary: "clk_i",
  bus_interfaces: [
    { protocol: "reg_iface", direction: "device" }
  ],
  regwidth: 32,
  registers: [

    { name: "CLK_ENA",
      desc: "Quadrant-internal clock gate enable",
      swaccess: "rw",
      hwaccess: "hro",
      // Clock disabled (i.e. gated) by default
      fields: [
        {bits: "0:0", name: "clk_ena", resval: 0, desc: "Clock gate enable"}
      ],
    },
    { name: "RESET_N",
      desc: "Quadrant-internal asynchronous active-low reset",
      swaccess: "rw",
      hwaccess: "hro",
      // Held in reset (i.e. signal high) by default
      fields: [
        {bits: "0:0", name: "reset_n", resval: 1, desc: "Asynchronous active-low reset"}
      ]
    },
    { name: "ISOLATE",
      desc: "Isolate ports of given quadrant.",
      swaccess: "rw",
      hwaccess: "hro",
      // All channels isolated by default
      fields: [
        {bits: "0:0", name: "narrow_in",  resval: 1, desc: "narrow slave in isolate"},
        {bits: "1:1", name: "narrow_out", resval: 1, desc: "narrow master out isolate"},
        {bits: "2:2", name: "wide_in",    resval: 1, desc: "wide slave in isolate"},
        {bits: "3:3", name: "wide_out",   resval: 1, desc: "wide master out isolate"},
        {bits: "4:4", name: "hbi_out",    resval: 1, desc: "HBI master out isolate"}
      ]
    },
    { name: "ISOLATED"
      desc: "Isolation status of S1 quadrant and port"
      swaccess: "ro"
      hwaccess: "hwo"
      hwqe: "true",
      hwext: "true",
      // All channels isolated by default
      fields: [
        {bits: "0:0", name: "narrow_in",  resval: 1, desc: "narrow slave in isolation status"},
        {bits: "1:1", name: "narrow_out", resval: 1, desc: "narrow master out isolation status"},
        {bits: "2:2", name: "wide_in",    resval: 1, desc: "wide slave in isolation status"},
        {bits: "3:3", name: "wide_out",   resval: 1, desc: "wide master out isolation status"},
        {bits: "4:4", name: "hbi_out",    resval: 1, desc: "HBI master out isolation status"}
      ]
    },
    { name: "RO_CACHE_ENABLE",
      desc: "Enable read-only cache of quadrant.",
      swaccess: "rw",
      hwaccess: "hro",
      fields: [
        { bits: "0:0", resval: 0, name: "enable", desc: "Enable RO cache of S1 quadrant."}
      ]
    },

    // Start RO cache region fields at regular offset
    { skipto: "0x100" }
% for r in range(cfg["s1_quadrant"].get("ro_cache_cfg", {}).get("address_regions", 1)):
    { name: "RO_START_ADDR_LOW_${r}",
      desc: "Read-only cache start address low",
      swaccess: "rw",
      hwaccess: "hro",
      fields: [
        {bits: "31:0", name: "ADDR_LOW", desc: "Lower 32-bit of read-only region."}
      ]
    },
    { name: "RO_START_ADDR_HIGH_${r}",
      desc: "Read-only cache start address high",
      swaccess: "rw",
      hwaccess: "hro",
      fields: [
        {bits: "${soc_wide_xbar.aw-33}:0", name: "ADDR_HIGH", resval: ${r}, desc: "Higher 32-bit of read-only region."}
      ]
    }
    { name: "RO_END_ADDR_LOW_${r}",
      desc: "Read-only cache end address low",
      swaccess: "rw",
      hwaccess: "hro",
      fields: [
        {bits: "31:0", name: "ADDR_LOW", desc: "Lower 32-bit of read-only region."}
      ]
    },
    { name: "RO_END_ADDR_HIGH_${r}",
      desc: "Read-only cache end address high",
      swaccess: "rw",
      hwaccess: "hro",
      fields: [
        {bits: "${soc_wide_xbar.aw-33}:0", name: "ADDR_HIGH", resval: ${r + 1}, desc: "Higher 32-bit of read-only region."}
      ]
    }
% endfor

  ]
}
