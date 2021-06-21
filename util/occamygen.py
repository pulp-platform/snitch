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
from mako.template import Template

from solder import solder, device_tree, util

# Compile a regex to trim trailing whitespaces on lines.
re_trailws = re.compile(r'[ \t\r]+$', re.MULTILINE)


def write_template(tpl_path, outdir, **kwargs):
    if tpl_path:
        tpl_path = pathlib.Path(tpl_path).absolute()
        if tpl_path.exists():
            tpl = Template(filename=str(tpl_path))
            with open(outdir / tpl_path.with_suffix("").name, "w") as file:
                code = tpl.render_unicode(**kwargs)
                code = re_trailws.sub("", code)
                file.write(code)
        else:
            raise FileNotFoundError


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
    parser.add_argument("--top-sv",
                        metavar="TOP_SV",
                        help="Name of top-level file (output).")
    parser.add_argument("--pkg-sv",
                        metavar="PKG_SV",
                        help="Name of top-level package file (output)")
    parser.add_argument("--quadrant-s1",
                        metavar="QUADRANT_S1",
                        help="Name of S1 quadrant template file (output)")
    parser.add_argument("--xilinx-sv",
                        metavar="XILINX_SV",
                        help="Name of the Xilinx wrapper file (output).")
    parser.add_argument("--testharness-sv",
                        metavar="TESTHARNESS_SV",
                        help="Name of the testharness wrapper file (output).")
    parser.add_argument("--cva6-sv",
                        metavar="CVA6_SV",
                        help="Name of the CVA6 wrapper file (output).")
    parser.add_argument("--chip",
                        metavar="CHIP_TOP",
                        help="(Optional) Chip Top-level")
    parser.add_argument("--graph", "-g", metavar="DOT")
    parser.add_argument("--memories", "-m", action="store_true")
    parser.add_argument("--wrapper", "-w", action="store_true")
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

    outdir = args.outdir
    outdir.mkdir(parents=True, exist_ok=True)

    if args.wrapper:
        with open(outdir / "occamy_cluster_wrapper.sv", "w") as f:
            f.write(occamy.render_wrapper())

    if args.memories:
        with open(outdir / "memories.json", "w") as f:
            f.write(occamy.cluster.memory_cfg())

    # Create the address map.
    am = solder.AddrMap()
    # Create a device tree object.
    dts = device_tree.DeviceTree()

    am_soc_narrow_xbar = am.new_node("soc_narrow_xbar")
    am_soc_wide_xbar = am.new_node("soc_wide_xbar")
    am_wide_xbar_quadrant_s1 = am.new_node("wide_xbar_quadrant_s1")

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

    am_chip_ctrl = am.new_leaf("chip_ctrl", 0x1000,
                               0x02005000).attach_to(am_soc_regbus_periph_xbar)

    am_spim = am.new_leaf("spim", 0x20000,
                          0x03000000).attach_to(am_soc_regbus_periph_xbar)

    am_clint = am.new_leaf("clint", 0x0100000,
                           0x04000000).attach_to(am_soc_regbus_periph_xbar)
    dts.add_clint([0], am_clint)

    am_pcie_cfg = am.new_leaf("pcie_cfg", 0x20000,
                              0x05000000).attach_to(am_soc_regbus_periph_xbar)

    # TODO: Revise address map for HBI config and APB control
    am_hbi_cfg = am.new_leaf("hbi_cfg", 0x10000,
                             0x06000000).attach_to(am_soc_regbus_periph_xbar)

    am_hbi_ctl = am.new_leaf("hbi_ctl", 0x10000,
                             0x07000000).attach_to(am_soc_regbus_periph_xbar)

    am_plic = am.new_leaf("plic", 0x4000000,
                          0x0C000000).attach_to(am_soc_regbus_periph_xbar)

    dts.add_plic([0], am_plic)

    am_pcie = am.new_leaf("pcie", 0x28000000, 0x20000000,
                          0x48000000).attach_to(am_soc_wide_xbar)

    am_spm = am.new_leaf("spm", 0x10000000, 0x70000000)

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
    am_soc_narrow_xbar.attach(am_spm)

    # HBI
    am_hbi = am.new_leaf("hbi", 0x10000000000,
                         0x10000000000).attach_to(am_wide_xbar_quadrant_s1)

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

    soc_regbus_periph_xbar.add_output_entry("clint", am_clint)
    soc_regbus_periph_xbar.add_output_entry("soc_ctrl", am_soc_ctrl)
    soc_regbus_periph_xbar.add_output_entry("chip_ctrl", am_chip_ctrl)
    soc_regbus_periph_xbar.add_output_entry("clk_mgr", am_clk_mgr)
    soc_regbus_periph_xbar.add_output_entry("bootrom", am_bootrom)
    soc_regbus_periph_xbar.add_output_entry("plic", am_plic)
    soc_regbus_periph_xbar.add_output_entry("uart", am_uart)
    soc_regbus_periph_xbar.add_output_entry("gpio", am_gpio)
    soc_regbus_periph_xbar.add_output_entry("i2c", am_i2c)
    soc_regbus_periph_xbar.add_output_entry("spim", am_spim)
    soc_regbus_periph_xbar.add_output_entry("pcie_cfg", am_pcie_cfg)
    soc_regbus_periph_xbar.add_output_entry("hbi_cfg", am_hbi_cfg)
    soc_regbus_periph_xbar.add_output_entry("hbi_ctl", am_hbi_ctl)

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
                                   atop_support=False,
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
    soc_narrow_xbar.add_output_entry("spm", am_spm)
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
        atop_support=False,
        context="quadrant_s1",
        node=am_wide_xbar_quadrant_s1)

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
    wide_xbar_quadrant_s1.add_output_entry("hbi", am_hbi)
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

    ###############
    # HBI APB CTL #
    ###############
    apb_hbi_ctl = solder.ApbBus(clk=soc_regbus_periph_xbar.clk,
                                rst=soc_regbus_periph_xbar.rst,
                                aw=soc_regbus_periph_xbar.aw,
                                dw=soc_regbus_periph_xbar.dw,
                                name="apb_hbi_ctl")

    kwargs = {
        "solder": solder,
        "util": util,
        "soc_narrow_xbar": soc_narrow_xbar,
        "soc_wide_xbar": soc_wide_xbar,
        "wide_xbar_quadrant_s1": wide_xbar_quadrant_s1,
        "narrow_xbar_quadrant_s1": narrow_xbar_quadrant_s1,
        "soc_regbus_periph_xbar": soc_regbus_periph_xbar,
        "apb_hbi_ctl": apb_hbi_ctl,
        "nr_s1_quadrants": nr_s1_quadrants,
        "cfg": occamy.cfg
    }

    # Emit the code.
    #############
    # Top-Level #
    #############
    write_template(args.top_sv,
                   outdir,
                   module=solder.code_module['default'],
                   soc_periph_xbar=soc_axi_lite_periph_xbar,
                   **kwargs)

    ###############
    # S1 Quadrant #
    ###############
    write_template(args.quadrant_s1,
                   outdir,
                   module=solder.code_module['quadrant_s1'],
                   **kwargs)

    ###########
    # Package #
    ###########
    write_template(args.pkg_sv, outdir, **kwargs, package=solder.code_package)

    ##################
    # Xilinx Wrapper #
    ##################
    write_template(args.xilinx_sv, outdir, **kwargs)

    ###############
    # Testharness #
    ###############
    write_template(args.testharness_sv, outdir, **kwargs)

    ################
    # CVA6 Wrapper #
    ################
    write_template(args.cva6_sv, outdir, **kwargs)

    ###########
    # CHEADER #
    ###########
    if args.cheader:
        with open(args.cheader, "w") as file:
            file.write(am.print_cheader())

    ############
    # CHIP TOP #
    ############
    write_template(args.chip, outdir, **kwargs)

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
