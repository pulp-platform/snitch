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
import csv

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
    parser.add_argument("--soc-sv",
                        metavar="TOP_SYNC_SV",
                        help="Name of synchronous SoC file (output).")
    parser.add_argument("--pkg-sv",
                        metavar="PKG_SV",
                        help="Name of top-level package file (output)")
    parser.add_argument("--quadrant-s1",
                        metavar="QUADRANT_S1",
                        help="Name of S1 quadrant template file (output)")
    parser.add_argument("--quadrant-s1-ctrl",
                        metavar="QUADRANT_S1_CTL",
                        help="Name of S1 quadrant controller template file (output)")
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
    parser.add_argument("--bootdata",
                        metavar="BOOTDATA",
                        help="Name of the bootdata file (output)")
    parser.add_argument("--cheader",
                        metavar="CHEADER",
                        help="Name of the cheader file (output)")
    parser.add_argument("--csv",
                        metavar="CSV",
                        help="Name of the csv file (output)")

    parser.add_argument("--graph", "-g", metavar="DOT")
    parser.add_argument("--memories", "-m", action="store_true")
    parser.add_argument("--wrapper", "-w", action="store_true")
    parser.add_argument("--am-cheader", "-D", metavar="ADDRMAP_CHEADER")
    parser.add_argument("--am-csv", "-aml", metavar="ADDRMAP_CSV")
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
    # Iterate over Hives to get the number of cores.
    nr_cluster_cores = len([
        core for hive in occamy.cfg["cluster"]["hives"]
        for core in hive["cores"]
    ])

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

    ####################
    # Address Map (AM) #
    ####################
    # Create the address map.
    am = solder.AddrMap()
    # Create a device tree object.
    dts = device_tree.DeviceTree()

    # Toplevel crossbar address map
    am_soc_narrow_xbar = am.new_node("soc_narrow_xbar")
    am_soc_wide_xbar = am.new_node("soc_wide_xbar")

    # Quadrant crossbar address map
    am_wide_xbar_quadrant_s1 = list()
    am_narrow_xbar_quadrant_s1 = list()
    for i in range(nr_s1_quadrants):
        am_wide_xbar_quadrant_s1.append(am.new_node("wide_xbar_quadrant_s1_{}".format(i)))
        am_narrow_xbar_quadrant_s1.append(am.new_node("narrow_xbar_quadrant_s1_{}".format(i)))

    # Peripheral crossbar address map
    am_soc_axi_lite_periph_xbar = am.new_node("soc_axi_lite_periph_xbar")
    am_soc_regbus_periph_xbar = am.new_node("soc_periph_regbus_xbar")

    ############################
    # AM: Periph AXI Lite XBar #
    ############################
    am_debug = am.new_leaf(
        "debug",
        occamy.cfg["debug"]["length"],
        occamy.cfg["debug"]["address"]).attach_to(am_soc_axi_lite_periph_xbar)

    dts.add_device("debug", "riscv,debug-013", am_debug, [
        "interrupts-extended = <&CPU0_intc 65535>", "reg-names = \"control\""
    ])

    ##########################
    # AM: Periph Regbus XBar #
    ##########################
    am_bootrom = am.new_leaf(
        "bootrom",
        occamy.cfg["rom"]["length"],
        occamy.cfg["rom"]["address"]).attach_to(am_soc_regbus_periph_xbar)

    am_soc_ctrl = am.new_leaf(
        "soc_ctrl",
        occamy.cfg["soc_ctrl"]["length"],
        occamy.cfg["soc_ctrl"]["address"]).attach_to(am_soc_regbus_periph_xbar)

    am_clk_mgr = am.new_leaf(
        "clk_mgr",
        occamy.cfg["clk_mgr"]["length"],
        occamy.cfg["clk_mgr"]["address"]).attach_to(am_soc_regbus_periph_xbar)

    am_uart = am.new_leaf(
        "uart",
        occamy.cfg["uart"]["length"],
        occamy.cfg["uart"]["address"]).attach_to(am_soc_regbus_periph_xbar)

    dts.add_device("serial", "lowrisc,serial", am_uart, [
        "clock-frequency = <50000000>", "current-speed = <115200>",
        "interrupt-parent = <&PLIC0>", "interrupts = <1>"
    ])

    am_gpio = am.new_leaf(
        "gpio",
        occamy.cfg["gpio"]["length"],
        occamy.cfg["gpio"]["address"]).attach_to(am_soc_regbus_periph_xbar)

    am_i2c = am.new_leaf(
        "i2c",
        occamy.cfg["i2c"]["length"],
        occamy.cfg["i2c"]["address"]).attach_to(am_soc_regbus_periph_xbar)

    am_chip_ctrl = am.new_leaf(
        "chip_ctrl",
        occamy.cfg["chip_ctrl"]["length"],
        occamy.cfg["chip_ctrl"]["address"]).attach_to(am_soc_regbus_periph_xbar)

    am_timer = am.new_leaf(
        "timer",
        occamy.cfg["timer"]["length"],
        occamy.cfg["timer"]["address"]).attach_to(am_soc_regbus_periph_xbar)

    am_spim = am.new_leaf(
        "spim",
        occamy.cfg["spim"]["length"],
        occamy.cfg["spim"]["address"]).attach_to(am_soc_regbus_periph_xbar)

    am_clint = am.new_leaf(
        "clint",
        occamy.cfg["clint"]["length"],
        occamy.cfg["clint"]["address"]).attach_to(am_soc_regbus_periph_xbar)
    dts.add_clint([0], am_clint)

    am_pcie_cfg = am.new_leaf(
        "pcie_cfg",
        occamy.cfg["pcie_cfg"]["length"],
        occamy.cfg["pcie_cfg"]["address"]).attach_to(am_soc_regbus_periph_xbar)

    # TODO: Revise address map for HBI config and APB control
    am_hbi_cfg = am.new_leaf(
        "hbi_cfg",
        occamy.cfg["hbi_cfg"]["length"],
        occamy.cfg["hbi_cfg"]["address"]).attach_to(am_soc_regbus_periph_xbar)

    am_hbi_ctl = am.new_leaf(
        "hbi_ctl",
        occamy.cfg["hbi_ctl"]["length"],
        occamy.cfg["hbi_ctl"]["address"]).attach_to(am_soc_regbus_periph_xbar)

    am_hbm_cfg = am.new_leaf(
        "hbm_cfg",
        occamy.cfg["hbm_cfg"]["length"],
        occamy.cfg["hbm_cfg"]["address"]).attach_to(am_soc_regbus_periph_xbar)

    am_hbm_phy_cfg = am.new_leaf(
        "hbm_phy_cfg",
        occamy.cfg["hbm_phy_cfg"]["length"],
        occamy.cfg["hbm_phy_cfg"]["address"]).attach_to(am_soc_regbus_periph_xbar)

    am_hbm_seq = am.new_leaf(
        "hbm_seq",
        occamy.cfg["hbm_seq"]["length"],
        occamy.cfg["hbm_seq"]["address"]).attach_to(am_soc_regbus_periph_xbar)

    am_plic = am.new_leaf(
        "plic",
        occamy.cfg["plic"]["length"],
        occamy.cfg["plic"]["address"]).attach_to(am_soc_regbus_periph_xbar)

    dts.add_plic([0], am_plic)

    ##################
    # AM: SPM / PCIE #
    ##################
    # Connect PCIE to Wide AXI
    am_pcie = am.new_leaf(
        "pcie",
        occamy.cfg["pcie"]["length"],
        occamy.cfg["pcie"]["address_io"],
        occamy.cfg["pcie"]["address_mm"]).attach_to(am_soc_wide_xbar)

    # Connect SPM to Narrow AXI
    am_spm = am.new_leaf(
        "spm",
        occamy.cfg["spm"]["length"],
        occamy.cfg["spm"]["address"]).attach_to(am_soc_narrow_xbar)

    ###########
    # AM: HBI #
    ###########
    am_hbi = am.new_leaf(
        "hbi",
        occamy.cfg["hbi"]["length"],
        occamy.cfg["hbi"]["address"])
    am_soc_wide_xbar.attach(am_hbi)

    # Add connection from quadrants AXI xbar to HBI
    for i in range(nr_s1_quadrants):
        am_wide_xbar_quadrant_s1[i].attach(am_hbi)

    ###########
    # AM: HBM #
    ###########
    am_hbm = list()

    hbm_base_address_0 = occamy.cfg["hbm"]["address_0"]
    hbm_base_address_1 = occamy.cfg["hbm"]["address_1"]

    nr_hbm_channels = occamy.cfg["hbm"]["nr_channels_total"]
    nr_channels_base_0 = occamy.cfg["hbm"]["nr_channels_address_0"]

    hbm_channel_size = occamy.cfg["hbm"]["channel_size"]

    for i in range(nr_hbm_channels):
        bases = list()
        # Map first channels on both base addresses
        if i < nr_channels_base_0:
            bases.append(hbm_base_address_0 + i * hbm_channel_size)
        # Map all channels on second base address
        bases.append(hbm_base_address_1 + i * hbm_channel_size)
        # create address map
        am_hbm.append(
            am.new_leaf(
                "hbm_{}".format(i),
                hbm_channel_size,
                *bases).attach_to(am_soc_wide_xbar))

    dts.add_memory(am_hbm[0])

    ##############################
    # AM: Quadrants and Clusters #
    ##############################
    cluster_size = occamy.cfg["cluster"]["cluster_base_offset"]
    cluster_tcdm_size = occamy.cfg["cluster"]["tcdm"]["size"] * 1024
    cluster_periph_size = cluster_tcdm_size

    quadrants_base_addr = occamy.cfg["cluster"]["cluster_base_addr"]
    quadrant_size = cluster_size * nr_s1_clusters

    for i in range(nr_s1_quadrants):
        cluster_base_addr = quadrants_base_addr + i * quadrant_size

        am_clusters = list()
        for j in range(nr_s1_clusters):
            bases_cluster = list()
            bases_cluster.append(cluster_base_addr + j * cluster_size + 0)
            am_clusters.append(
                am.new_leaf(
                    "quadrant_{}_cluster_{}_tcdm".format(i, j),
                    cluster_tcdm_size,
                    *bases_cluster
                ).attach_to(
                    am_wide_xbar_quadrant_s1[i]
                ).attach_to(
                    am_narrow_xbar_quadrant_s1[i]
                )
            )

            bases_cluster = list()
            bases_cluster.append(cluster_base_addr + j * cluster_size + cluster_tcdm_size)
            am_clusters.append(
                am.new_leaf(
                    "quadrant_{}_cluster_{}_periph".format(i, j),
                    cluster_periph_size,
                    *bases_cluster
                ).attach_to(
                    am_wide_xbar_quadrant_s1[i]
                ).attach_to(
                    am_narrow_xbar_quadrant_s1[i]
                )
            )

    ##############################
    # AM: Crossbars #
    ##############################
    # Connect quadrants AXI xbar
    for i in range(nr_s1_quadrants):
        am_narrow_xbar_quadrant_s1[i].attach(am_wide_xbar_quadrant_s1[i])
        am_soc_narrow_xbar.attach(am_narrow_xbar_quadrant_s1[i])
        am_soc_wide_xbar.attach(am_wide_xbar_quadrant_s1[i])

    # Connect narrow xbar
    am_soc_narrow_xbar.attach(am_soc_axi_lite_periph_xbar)
    am_soc_narrow_xbar.attach(am_soc_regbus_periph_xbar)
    am_soc_narrow_xbar.attach(am_soc_wide_xbar)

    am_soc_axi_lite_periph_xbar.attach(am_soc_narrow_xbar)

    # Connect wide xbar
    am_soc_wide_xbar.attach(am_soc_narrow_xbar)

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
    soc_axi_lite_periph_xbar.add_output_entry("soc", am_soc_narrow_xbar)

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
    soc_regbus_periph_xbar.add_output_entry("timer", am_timer)
    soc_regbus_periph_xbar.add_output_entry("pcie_cfg", am_pcie_cfg)
    soc_regbus_periph_xbar.add_output_entry("hbi_cfg", am_hbi_cfg)
    soc_regbus_periph_xbar.add_output_entry("hbi_ctl", am_hbi_ctl)
    soc_regbus_periph_xbar.add_output_entry("hbm_cfg", am_hbm_cfg)
    soc_regbus_periph_xbar.add_output_entry("hbm_phy_cfg", am_hbm_phy_cfg)
    soc_regbus_periph_xbar.add_output_entry("hbm_seq", am_hbm_seq)

    #################
    # SoC Wide Xbar #
    #################
    soc_wide_xbar = solder.AxiXbar(
        48,
        512,
        occamy.cfg["wide_xbar_slv_id_width_no_rocache"] +
            (1 if occamy.cfg["s1_quadrant"].get("ro_cache_cfg") else 0),
        name="soc_wide_xbar",
        clk="clk_i",
        rst="rst_ni",
        max_slv_trans=occamy.cfg["wide_xbar"]["max_slv_trans"],
        max_mst_trans=occamy.cfg["wide_xbar"]["max_mst_trans"],
        fall_through=occamy.cfg["wide_xbar"]["fall_through"],
        no_loopback=True,
        atop_support=False,
        context="soc",
        node=am_soc_wide_xbar)

    for i in range(nr_s1_quadrants):
        soc_wide_xbar.add_output_symbolic("s1_quadrant_{}".format(i),
                                          "s1_quadrant_base_addr",
                                          "S1QuadrantAddressSpace")
        soc_wide_xbar.add_input("s1_quadrant_{}".format(i))

    for i in range(8):
        soc_wide_xbar.add_output_entry("hbm_{}".format(i), am_hbm[i])

    for i in range(nr_s1_quadrants+1):
        soc_wide_xbar.add_input("hbi_{}".format(i))
    soc_wide_xbar.add_output_entry("hbi_{}".format(nr_s1_quadrants), am_hbi)

    soc_wide_xbar.add_input("soc_narrow")
    soc_wide_xbar.add_output_entry("soc_narrow", am_soc_narrow_xbar)

    # TODO(zarubaf): PCIe should probably go into the small crossbar.
    soc_wide_xbar.add_input("pcie")
    soc_wide_xbar.add_output_entry("pcie", am_pcie)

    ###################
    # SoC Narrow Xbar #
    ###################
    soc_narrow_xbar = solder.AxiXbar(
        48,
        64,
        occamy.cfg["narrow_xbar_slv_id_width"],
        name="soc_narrow_xbar",
        clk="clk_i",
        rst="rst_ni",
        max_slv_trans=occamy.cfg["narrow_xbar"]["max_slv_trans"],
        max_mst_trans=occamy.cfg["narrow_xbar"]["max_mst_trans"],
        fall_through=occamy.cfg["narrow_xbar"]["fall_through"],
        no_loopback=True,
        context="soc",
        node=am_soc_narrow_xbar)

    for i in range(nr_s1_quadrants):
        soc_narrow_xbar.add_output_symbolic("s1_quadrant_{}".format(i),
                                            "s1_quadrant_base_addr",
                                            "S1QuadrantAddressSpace")
        soc_narrow_xbar.add_input("s1_quadrant_{}".format(i))

    soc_narrow_xbar.add_input("cva6")
    soc_narrow_xbar.add_input("soc_wide")
    soc_narrow_xbar.add_input("periph")
    dts.add_cpu("eth,ariane")

    soc_narrow_xbar.add_output_entry("periph", am_soc_axi_lite_periph_xbar)
    soc_narrow_xbar.add_output_entry("spm", am_spm)
    soc_narrow_xbar.add_output_entry("soc_wide", am_soc_wide_xbar)
    soc_narrow_xbar.add_output_entry("regbus_periph",
                                     am_soc_regbus_periph_xbar)

    ##########################
    # S1 Quadrant controller #
    ##########################
    # Non-loopback crossbar shims off both narrow master and slave for internal resources
    quadrant_s1_ctrl_xbar = solder.AxiXbar(
        48,
        64,
        4,  # TODO: Source from JSON description
        name="quadrant_s1_ctrl_xbar",
        clk="clk_i",
        rst="rst_ni",
        max_slv_trans=4,        # TODO: Source from JSON description
        max_mst_trans=4,        # TODO: Source from JSON description
        fall_through=False,     # TODO: Source from JSON description
        no_loopback=True,
        context="quadrant_s1_ctrl")

    # TODO: Define appropriate default routes for each port! (not correct as-is!)
    quadrant_s1_ctrl_xbar.add_output("soc", [])
    quadrant_s1_ctrl_xbar.add_output("quadrant", [])
    quadrant_s1_ctrl_xbar.add_input("soc")
    quadrant_s1_ctrl_xbar.add_input("quadrant")

    quadrant_s1_ctrl_xbar.add_output_symbolic("internal",
                                              "InternalBaseAddress",
                                              "QuadrantAddressSpace")

    ################
    # S1 Quadrants #
    ################
    # Dummy entries to generate associated types.
    wide_xbar_quadrant_s1 = solder.AxiXbar(
        48,
        512,
        occamy.cfg["s1_quadrant"]["wide_xbar_slv_id_width"],
        name="wide_xbar_quadrant_s1",
        clk="clk_i",
        rst="rst_ni",
        max_slv_trans=occamy.cfg["s1_quadrant"]["wide_xbar"]["max_slv_trans"],
        max_mst_trans=occamy.cfg["s1_quadrant"]["wide_xbar"]["max_mst_trans"],
        fall_through=occamy.cfg["s1_quadrant"]["wide_xbar"]["fall_through"],
        no_loopback=True,
        atop_support=False,
        context="quadrant_s1",
        node=am_wide_xbar_quadrant_s1[0])

    narrow_xbar_quadrant_s1 = solder.AxiXbar(
        48,
        64,
        occamy.cfg["s1_quadrant"]["narrow_xbar_slv_id_width"],
        name="narrow_xbar_quadrant_s1",
        clk="clk_i",
        rst="rst_ni",
        max_slv_trans=occamy.cfg["s1_quadrant"]["narrow_xbar"]
        ["max_slv_trans"],
        max_mst_trans=occamy.cfg["s1_quadrant"]["narrow_xbar"]
        ["max_mst_trans"],
        fall_through=occamy.cfg["s1_quadrant"]["narrow_xbar"]["fall_through"],
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

    apb_hbm_cfg = solder.ApbBus(clk=soc_regbus_periph_xbar.clk,
                                rst=soc_regbus_periph_xbar.rst,
                                aw=soc_regbus_periph_xbar.aw,
                                dw=soc_regbus_periph_xbar.dw,
                                name="apb_hbm_cfg")

    kwargs = {
        "solder": solder,
        "util": util,
        "soc_narrow_xbar": soc_narrow_xbar,
        "soc_wide_xbar": soc_wide_xbar,
        "quadrant_s1_ctrl_xbar": quadrant_s1_ctrl_xbar,
        "wide_xbar_quadrant_s1": wide_xbar_quadrant_s1,
        "narrow_xbar_quadrant_s1": narrow_xbar_quadrant_s1,
        "soc_regbus_periph_xbar": soc_regbus_periph_xbar,
        "apb_hbi_ctl": apb_hbi_ctl,
        "apb_hbm_cfg": apb_hbm_cfg,
        "cfg": occamy.cfg,
        "cores": nr_s1_quadrants * nr_s1_clusters * nr_cluster_cores + 1,
        "nr_s1_quadrants": nr_s1_quadrants,
        "nr_s1_clusters": nr_s1_clusters,
        "nr_cluster_cores": nr_cluster_cores,
        "hbm_channel_size": hbm_channel_size
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

    ###########################
    # SoC (fully synchronous) #
    ###########################
    write_template(args.soc_sv,
                   outdir,
                   module=solder.code_module['soc'],
                   soc_periph_xbar=soc_axi_lite_periph_xbar,
                   **kwargs)

    ##########################
    # S1 Quadrant controller #
    ##########################
    write_template(args.quadrant_s1_ctrl,
                   outdir,
                   module=solder.code_module['quadrant_s1_ctrl'],
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

    ###################
    # Generic CHEADER #
    ###################
    write_template(args.cheader, outdir, **kwargs)

    ###################
    # ADDRMAP CHEADER #
    ###################
    if args.am_cheader:
        with open(args.am_cheader, "w") as file:
            file.write(am.print_cheader())

    ###############
    # ADDRMAP CSV #
    ###############
    if args.am_csv:
        with open(args.am_csv, 'w', newline='') as csvfile:
            csv_writer = csv.writer(csvfile, delimiter=',')
            am.print_csv(csv_writer)

    ############
    # CHIP TOP #
    ############
    write_template(args.chip, outdir, **kwargs)

    ############
    # BOOTDATA #
    ############
    write_template(args.bootdata, outdir, **kwargs)

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
