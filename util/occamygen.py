#!/usr/bin/env python3

# Copyright 2020 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

import argparse
import hjson
import pathlib
import sys
import re

from jsonref import JsonRef
from clustergen.occamy import Occamy
from mako.lookup import TemplateLookup

from solder import solder

templates = TemplateLookup(
    directories=[pathlib.Path(__file__).parent / "../hw/system/occamy/src"],
    output_encoding="utf-8")


def main():
    """Generate the Occamy system and all corresponding configuration files."""
    parser = argparse.ArgumentParser(prog="clustergen")
    parser.add_argument("--clustercfg",
                        "-c",
                        metavar="file",
                        type=argparse.FileType('r'),
                        required=True,
                        help="A cluster configuration file")
    parser.add_argument("--outdir",
                        "-o",
                        type=pathlib.Path,
                        required=True,
                        help="Target directory.")

    # Parse arguments.
    parser.add_argument("TOP_SV", help="Name of top-level file (output).")
    parser.add_argument("PKG_SV", help="Name of top-level package file (output)")
    parser.add_argument("--graph", "-g", metavar="DOT")
    parser.add_argument("--cheader", "-D", metavar="CHEADER")

    args = parser.parse_args()

    # Read HJSON description
    with args.clustercfg as file:
        try:
            srcfull = file.read()
            obj = hjson.loads(srcfull, use_decimal=True)
            obj = JsonRef.replace_refs(obj)
        except ValueError:
            raise SystemExit(sys.exc_info()[1])

    occamy = Occamy(obj)

    if not args.outdir.is_dir():
        exit("Out directory is not a valid path.")

    outdir = args.outdir / "src"
    outdir.mkdir(parents=True, exist_ok=True)

    with open(outdir / "occamy_cluster_wrapper.sv", "w") as f:
        f.write(occamy.render_wrapper())

    with open(outdir / "memories.json", "w") as f:
        f.write(occamy.cluster.memory_cfg())

    # Compile a regex to trim trailing whitespaces on lines.
    re_trailws = re.compile(r'[ \t\r]+$', re.MULTILINE)

    # Setup the templating engine.
    tpl_top = templates.get_template("occamy_top.sv.tpl")
    tpl_pkg = templates.get_template("occamy_pkg.sv.tpl")

    # Create the address map.
    am = solder.AddrMap()

    am_soc_periph_regbus_xbar = am.new_node("soc_periph_regbus_xbar")

    am_debug = am.new_leaf("debug", 0x1000,
                           0x00000000).attach_to(am_soc_periph_regbus_xbar)
    am_bootrom = am.new_leaf("bootrom", 0x10000,
                             0x00010000).attach_to(am_soc_periph_regbus_xbar)
    am_soc_ctrl = am.new_leaf("soc_ctrl", 0x1000,
                              0x00020000).attach_to(am_soc_periph_regbus_xbar)
    am_plic = am.new_leaf("plic", 0x1000,
                          0x00024000).attach_to(am_soc_periph_regbus_xbar)
    am_uart = am.new_leaf("uart", 0x1000,
                          0x00030000).attach_to(am_soc_periph_regbus_xbar)
    am_gpio = am.new_leaf("gpio", 0x1000,
                          0x00031000).attach_to(am_soc_periph_regbus_xbar)
    am_i2c = am.new_leaf("i2c", 0x1000,
                         0x00033000).attach_to(am_soc_periph_regbus_xbar)
    am_clint = am.new_leaf("clint", 0x10000,
                           0x00040000).attach_to(am_soc_periph_regbus_xbar)

    # Generate crossbars.
    # Peripherals crossbar (peripheral clock domain).
    io_periph_xbar = solder.AxiLiteXbar(34,
                                        32,
                                        name="io_periph_xbar",
                                        clk="clk_periph",
                                        rst="rst_periph_n",
                                        node=am_soc_periph_regbus_xbar)
    io_periph_xbar.add_input("soc")
    io_periph_xbar.add_output_entry("soc_ctrl", am_soc_ctrl)
    io_periph_xbar.add_output_entry("debug", am_debug)
    io_periph_xbar.add_output_entry("bootrom", am_bootrom)
    io_periph_xbar.add_output_entry("clint", am_clint)
    io_periph_xbar.add_output_entry("plic", am_plic)
    io_periph_xbar.add_output_entry("uart", am_uart)
    io_periph_xbar.add_output_entry("gpio", am_gpio)
    io_periph_xbar.add_output_entry("i2c", am_i2c)

    # Generate the Verilog code.
    solder.render()

    # Emit the code.
    with open(args.TOP_SV, "w") as file:
        code = tpl_top.render_unicode(
            module=solder.code_module.replace("\n", "\n  "),
            solder=solder,
            io_periph_xbar=io_periph_xbar
        )
        code = re_trailws.sub("", code)
        file.write(code)

    with open(args.PKG_SV, "w") as file:
        code = tpl_pkg.render_unicode(
            package=solder.code_package.replace("\n", "\n  "),
            solder=solder,
        )
        code = re_trailws.sub("", code)
        file.write(code)

    if args.cheader:
        with open(args.cheader, "w") as file:
            file.write(am.print_cheader())

    # Emit the address map as a dot file if requested.
    if args.graph:
        with open(args.graph, "w") as file:
            file.write(am.render_graphviz())


if __name__ == "__main__":
    main()
