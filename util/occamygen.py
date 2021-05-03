#!/usr/bin/env python3

# Copyright 2020 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

import argparse
import hjson
import pathlib
import sys
import re
import logging
from subprocess import run

from jsonref import JsonRef
from clustergen.occamy import Occamy
from mako.lookup import TemplateLookup

from solder import solder, device_tree

templates = TemplateLookup(
    directories=[pathlib.Path(__file__).parent / "../hw/system/occamy"],
    output_encoding="utf-8")


def main():
    """Generate the Occamy system and all corresponding configuration files."""
    parser = argparse.ArgumentParser(prog="clustergen")
    parser.add_argument("--cfg",
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
    parser.add_argument("PKG_SV",
                        help="Name of top-level package file (output)")
    parser.add_argument("QUADRANT_S1",
                        help="Name of S1 quadrant file (output)")
    parser.add_argument("XILINX_SV",
                        help="Name of the Xilinx wrapper file (output).")
    parser.add_argument("TESTHARNESS_SV",
                        help="Name of the testharness wrapper file (output).")
    parser.add_argument("CVA6_SV",
                        help="Name of the CVA6 wrapper file (output).")
    parser.add_argument("--graph", "-g", metavar="DOT")
    parser.add_argument("--cheader", "-D", metavar="CHEADER")
    parser.add_argument("--dts", metavar="DTS", help="System's device tree.")

    parser.add_argument("-v",
                        "--verbose",
                        help="increase output verbosity",
                        action="store_true")

    args = parser.parse_args()

    if args.verbose:
        logging.basicConfig(level=logging.DEBUG)

    # Read HJSON description of System.
    with args.cfg as file:
        try:
            srcfull = file.read()
            obj = hjson.loads(srcfull, use_decimal=True)
            obj = JsonRef.replace_refs(obj)
        except ValueError:
            raise SystemExit(sys.exc_info()[1])

    occamy = Occamy(obj)

    # Arguments.
    nr_s1_quadrants = occamy.cfg["nr_s1_quadrant"]
    nr_s1_clusters = occamy.cfg["s1_quadrant"]["nr_clusters"]

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

    # Create the address map.
    am = solder.AddrMap()
    # Create a device tree object.
    dts = device_tree.DeviceTree()

    am_soc_narrow_xbar = am.new_node("soc_narrow_xbar")
    am_soc_wide_xbar = am.new_node("soc_wide_xbar")

    am_soc_axi_lite_periph_xbar = am.new_node("soc_axi_lite_periph_xbar")
    am_soc_regbus_periph_xbar = am.new_node("soc_periph_regbus_xbar")

    am_debug = am.new_leaf("debug", 0x1000,
                           0x00000000).attach_to(am_soc_axi_lite_periph_xbar)
    dts.add_device("debug", "riscv,debug-013", am_debug, [
        "interrupts-extended = <&CPU0_intc 65535>", "reg-names = \"control\""
    ])

    am_bootrom = am.new_leaf(
        "bootrom", occamy.cfg["rom"]["length"],
        occamy.cfg["rom"]["address"]).attach_to(am_soc_regbus_periph_xbar)

    am_soc_ctrl = am.new_leaf("soc_ctrl", 0x1000,
                              0x02000000).attach_to(am_soc_regbus_periph_xbar)
    am_clk_mgr = am.new_leaf("clk_mgr", 0x1000,
                             0x02001000).attach_to(am_soc_regbus_periph_xbar)

    am_uart = am.new_leaf("uart", 0x1000,
                          0x02002000).attach_to(am_soc_regbus_periph_xbar)
    dts.add_device("serial", "lowrisc,serial", am_uart, [
        "clock-frequency = <50000000>", "current-speed = <115200>",
        "interrupt-parent = <&PLIC0>", "interrupts = <1>"
    ])

    am_gpio = am.new_leaf("gpio", 0x1000,
                          0x02003000).attach_to(am_soc_regbus_periph_xbar)
    am_i2c = am.new_leaf("i2c", 0x1000,
                         0x02004000).attach_to(am_soc_regbus_periph_xbar)

    am_spim = am.new_leaf("spim", 0x20000,
                          0x03000000).attach_to(am_soc_regbus_periph_xbar)

    am_clint = am.new_leaf("clint", 0x0100000,
                           0x04000000).attach_to(am_soc_axi_lite_periph_xbar)
    dts.add_clint([0], am_clint)

    am_plic = am.new_leaf("plic", 0x4000000,
                          0x0C000000).attach_to(am_soc_regbus_periph_xbar)

    dts.add_plic([0], am_plic)

    am_pcie = am.new_leaf("pcie", 0x30000000, 0x20000000,
                          0x50000000).attach_to(am_soc_wide_xbar)

    # HBM
    am_hbm = list()
    HBM_CHANNEL_SIZE = 0x40000000  # 1 GB channel size
    HBM_BASE = 0x80000000

    for i in range(8):
        bases = list()
        if i < 2:
            bases.append(HBM_BASE + i * HBM_CHANNEL_SIZE)
        bases.append(0x1000000000 + i * HBM_CHANNEL_SIZE)
        am_hbm.append(
            am.new_leaf("hbm_{}".format(i), HBM_CHANNEL_SIZE,
                        *bases).attach_to(am_soc_wide_xbar))

    dts.add_memory(am_hbm[0])

    am_soc_narrow_xbar.attach(am_soc_axi_lite_periph_xbar)
    am_soc_narrow_xbar.attach(am_soc_regbus_periph_xbar)
    am_soc_narrow_xbar.attach(am_soc_wide_xbar)

    # Generate crossbars.

    #######################
    # SoC Peripheral Xbar #
    #######################
    # AXI-Lite
    soc_axi_lite_periph_xbar = solder.AxiLiteXbar(
        48,
        64,
        name="soc_axi_lite_periph_xbar",
        clk="clk_periph_i",
        rst="rst_periph_ni",
        node=am_soc_axi_lite_periph_xbar)

    soc_axi_lite_periph_xbar.add_input("soc")
    soc_axi_lite_periph_xbar.add_input("debug")
    soc_axi_lite_periph_xbar.add_output_entry("clint", am_clint)
    soc_axi_lite_periph_xbar.add_output_entry("debug", am_debug)

    ##########
    # RegBus #
    ##########
    soc_regbus_periph_xbar = solder.RegBusXbar(48,
                                               32,
                                               name="soc_regbus_periph_xbar",
                                               clk="clk_periph_i",
                                               rst="rst_periph_ni",
                                               node=am_soc_regbus_periph_xbar)

    soc_regbus_periph_xbar.add_input("soc")

    soc_regbus_periph_xbar.add_output_entry("soc_ctrl", am_soc_ctrl)
    soc_regbus_periph_xbar.add_output_entry("clk_mgr", am_clk_mgr)
    soc_regbus_periph_xbar.add_output_entry("bootrom", am_bootrom)
    soc_regbus_periph_xbar.add_output_entry("plic", am_plic)
    soc_regbus_periph_xbar.add_output_entry("uart", am_uart)
    soc_regbus_periph_xbar.add_output_entry("gpio", am_gpio)
    soc_regbus_periph_xbar.add_output_entry("i2c", am_i2c)
    soc_regbus_periph_xbar.add_output_entry("spim", am_spim)

    #################
    # SoC Wide Xbar #
    #################
    soc_wide_xbar = solder.AxiXbar(48,
                                   512,
                                   3,
                                   name="soc_wide_xbar",
                                   clk="clk_i",
                                   rst="rst_ni",
                                   no_loopback=True,
                                   node=am_soc_wide_xbar)

    for i in range(nr_s1_quadrants):
        soc_wide_xbar.add_output_symbolic("s1_quadrant_{}".format(i),
                                          "s1_quadrant_base_addr",
                                          "S1QuadrantAddressSpace")
        soc_wide_xbar.add_input("s1_quadrant_{}".format(i))

    for i in range(8):
        soc_wide_xbar.add_output_entry("hbm_{}".format(i), am_hbm[i])

    for i in range(nr_s1_quadrants):
        soc_wide_xbar.add_input("hbi_{}".format(i))

    soc_wide_xbar.add_input("soc_narrow")

    # TODO(zarubaf): PCIe should probably go into the small crossbar.
    soc_wide_xbar.add_input("pcie")
    soc_wide_xbar.add_output_entry("pcie", am_pcie)

    ###################
    # SoC Narrow Xbar #
    ###################
    soc_narrow_xbar = solder.AxiXbar(48,
                                     64,
                                     4,
                                     name="soc_narrow_xbar",
                                     clk="clk_i",
                                     rst="rst_ni",
                                     no_loopback=True,
                                     node=am_soc_narrow_xbar)

    for i in range(nr_s1_quadrants):
        soc_narrow_xbar.add_output_symbolic("s1_quadrant_{}".format(i),
                                            "s1_quadrant_base_addr",
                                            "S1QuadrantAddressSpace")
        soc_narrow_xbar.add_input("s1_quadrant_{}".format(i))

    soc_narrow_xbar.add_input("cva6")
    dts.add_cpu("eth,ariane")

    soc_narrow_xbar.add_output_entry("periph", am_soc_axi_lite_periph_xbar)
    soc_narrow_xbar.add_output_entry("soc_wide", am_soc_wide_xbar)
    soc_narrow_xbar.add_output_entry("regbus_periph",
                                     am_soc_regbus_periph_xbar)

    ################
    # S1 Quadrants #
    ################
    # Dummy entries to generate associated types.
    wide_xbar_quadrant_s1 = solder.AxiXbar(
        48,
        512,
        3,  # TODO: Source from JSON description
        name="wide_xbar_quadrant_s1",
        clk="clk_i",
        rst="rst_ni",
        no_loopback=True,
        context="quadrant_s1")

    narrow_xbar_quadrant_s1 = solder.AxiXbar(
        48,
        64,
        4,  # TODO: Source from JSON description
        name="narrow_xbar_quadrant_s1",
        clk="clk_i",
        rst="rst_ni",
        no_loopback=True,
        context="quadrant_s1")

    wide_xbar_quadrant_s1.add_output("top", [])
    wide_xbar_quadrant_s1.add_input("top")
    narrow_xbar_quadrant_s1.add_output("top", [])
    narrow_xbar_quadrant_s1.add_input("top")

    for i in range(nr_s1_clusters):
        wide_xbar_quadrant_s1.add_output_symbolic("cluster_{}".format(i),
                                                  "cluster_base_addr",
                                                  "ClusterAddressSpace")

        wide_xbar_quadrant_s1.add_input("cluster_{}".format(i))
        narrow_xbar_quadrant_s1.add_output_symbolic("cluster_{}".format(i),
                                                    "cluster_base_addr",
                                                    "ClusterAddressSpace")
        narrow_xbar_quadrant_s1.add_input("cluster_{}".format(i))

    # Generate the Verilog code.
    solder.render()

    # Emit the code.
    #############
    # Top-Level #
    #############
    tpl_top = templates.get_template("src/occamy_top.sv.tpl")

    with open(args.TOP_SV, "w") as file:
        code = tpl_top.render_unicode(
            module=solder.code_module['default'].replace("\n", "\n  "),
            solder=solder,
            soc_periph_xbar=soc_axi_lite_periph_xbar,
            soc_regbus_periph_xbar=soc_regbus_periph_xbar,
            soc_wide_xbar=soc_wide_xbar,
            soc_narrow_xbar=soc_narrow_xbar,
            nr_s1_quadrants=nr_s1_quadrants)
        code = re_trailws.sub("", code)
        file.write(code)

    ###############
    # S1 Quadrant #
    ###############
    tpl_quadrant_s1 = templates.get_template("src/occamy_quadrant_s1.sv.tpl")

    with open(args.QUADRANT_S1, "w") as file:
        code = tpl_quadrant_s1.render_unicode(
            module=solder.code_module['quadrant_s1'].replace("\n", "\n  "),
            solder=solder,
            soc_wide_xbar=soc_wide_xbar,
            soc_narrow_xbar=soc_narrow_xbar,
            wide_xbar_quadrant_s1=wide_xbar_quadrant_s1,
            narrow_xbar_quadrant_s1=narrow_xbar_quadrant_s1,
            nr_clusters=nr_s1_clusters,
            const_cache_cfg=occamy.cfg["s1_quadrant"].get("const_cache"))
        code = re_trailws.sub("", code)
        file.write(code)

    ###########
    # Package #
    ###########
    tpl_pkg = templates.get_template("src/occamy_pkg.sv.tpl")

    with open(args.PKG_SV, "w") as file:
        code = tpl_pkg.render_unicode(
            package=solder.code_package.replace("\n", "\n  "),
            solder=solder,
        )
        code = re_trailws.sub("", code)
        file.write(code)

    ##################
    # Xilinx Wrapper #
    ##################
    tpl_xilinx = templates.get_template("src/occamy_xilinx.sv.tpl")

    with open(args.XILINX_SV, "w") as file:
        code = tpl_xilinx.render_unicode(
            solder=solder,
            soc_wide_xbar=soc_wide_xbar,
            soc_regbus_periph_xbar=soc_regbus_periph_xbar)
        code = re_trailws.sub("", code)
        file.write(code)

    ###############
    # Testharness #
    ###############
    tpl_testharness = templates.get_template("test/testharness.sv.tpl")

    with open(args.TESTHARNESS_SV, "w") as file:
        code = tpl_testharness.render_unicode(
            solder=solder,
            soc_wide_xbar=soc_wide_xbar,
            soc_regbus_periph_xbar=soc_regbus_periph_xbar,
            nr_s1_quadrants=nr_s1_quadrants)
        code = re_trailws.sub("", code)
        file.write(code)

    ################
    # CVA6 Wrapper #
    ################
    tpl_cva6 = templates.get_template("src/occamy_cva6.sv.tpl")

    with open(args.CVA6_SV, "w") as file:
        code = tpl_cva6.render_unicode(solder=solder,
                                       soc_narrow_xbar=soc_narrow_xbar,
                                       cfg=occamy.cfg)
        code = re_trailws.sub("", code)
        file.write(code)

    ###########
    # CHEADER #
    ###########
    if args.cheader:
        with open(args.cheader, "w") as file:
            file.write(am.print_cheader())

    #######
    # DTS #
    #######
    # TODO(niwis, zarubaf): We probably need to think about genrating a couple
    # of different systems here. I can at least think about two in that context:
    # 1. RTL sim
    # 2. FPGA
    # 3. (ASIC) in the private wrapper repo
    # I think we have all the necessary ingredients for this. What is missing is:
    # - Create a second(/third) configuration file.
    # - Generate the RTL into dedicated directories
    # - (Manually) adapt the `Bender.yml` to include the appropriate files.
    htif = dts.add_node("htif", "ucb,htif0")
    dts.add_chosen("stdout-path = \"{}\";".format(htif))

    if args.dts:
        # TODO(zarubaf): Figure out whether there are any requirements on the
        # model and compatability.
        dts_str = dts.emit("eth,occamy-dev", "eth,occamy")
        with open(args.dts, "w") as file:
            file.write(dts_str)
        # Compile to DTB and save to a file with `.dtb` extension.
        with open(pathlib.Path(args.dts).with_suffix(".dtb"), "wb") as file:
            run(["dtc", args.dts],
                input=dts_str,
                stdout=file,
                shell=True,
                text=True)

    # Emit the address map as a dot file if requested.
    if args.graph:
        with open(args.graph, "w") as file:
            file.write(am.render_graphviz())


if __name__ == "__main__":
    main()
