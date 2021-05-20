// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>

{
  name: "CLINT",
  clock_primary: "clk_i",
  bus_device: "reg",
  regwidth: "32",
  registers: [
% for i in range(cores):
    {   name: "MSIP${i}",
        desc: "Machine Software Interrupt Pending Core ${i}",
        swaccess: "rw",
        hwaccess: "hro",
        fields: [
          { bits: "0", name: "MSIP", desc: "Machine Software Interrupt Pending of Core ${i}" },
        ]
    },
% endfor
    { skipto: "0x4000" },
% for i in range(cores):
    {   name: "MTIMECMP_LOW${i}",
        desc: "Machine Timer Compare",
        swaccess: "rw",
        hwaccess: "hro",
        fields: [
          { bits: "31:0", name: "MTIMECMP_LOW", desc: "Machine Time Compare (Low) Core ${i}" }
        ]
    },
    {
        name: "MTIMECMP_HIGH${i}",
        desc: "Machine Timer Compare",
        swaccess: "rw",
        hwaccess: "hro",
        fields: [
          { bits: "31:0", name: "MTIMECMP_HIGH", desc: "Machine Time Compare (High) Core ${i}" }
        ]
    },
% endfor
    { skipto: "0xBFF8" },
    {
        name: "MTIME_LOW",
        desc: "Timer Register Low",
        swaccess: "rw",
        hwaccess: "hrw",
        fields: [
          { bits: "31:0", name: "MTIME_LOW", desc: "Machine Time (Low)" }
        ]
    },
    {
        name: "MTIME_HIGH",
        desc: "Timer Register High",
        swaccess: "rw",
        hwaccess: "hrw",
        fields: [
          { bits: "31:0", name: "MTIME_HIGH", desc: "Machine Time (High)" }
        ]
    },
  ]
}
