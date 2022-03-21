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

# Default name for all generated sources
DEFAULT_NAME = "occamy"


def write_template(tpl_path, outdir, fname=None, **kwargs):
    if tpl_path:
        tpl_path = pathlib.Path(tpl_path).absolute()
        if tpl_path.exists():
            tpl = Template(filename=str(tpl_path))
            fname = tpl_path.with_suffix("").name.replace("occamy", kwargs['args'].name) if not fname else fname
            with open(outdir / fname, "w") as file:
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
    parser.add_argument("--hbm-ctrl",
                        metavar="HBM_CTRL",
                        help="(Optional) HBM controller")
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
    parser.add_argument("--name", metavar="NAME", default=DEFAULT_NAME, help="System's name.")

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

    # If name argument provided, change config
    if args.name != DEFAULT_NAME:
        obj["cluster"]["name"] = args.name+"_cluster"
        # occamy.cfg["cluster"]["name"] = args.name

    occamy = Occamy(obj)

    # Arguments.
    nr_s1_quadrants = occamy.cfg["nr_s1_quadrant"]
    nr_s1_clusters = occamy.cfg["s1_quadrant"]["nr_clusters"]
    is_remote_quadrant = occamy.cfg["is_remote_quadrant"]
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
        with open(outdir / f"{args.name}_cluster_wrapper.sv", "w") as f:
            f.write(occamy.render_wrapper())

    if args.memories:
        with open(outdir / f"{args.name}_memories.json", "w") as f:
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

    # Quadrant pre-crossbar address map
    am_quadrant_pre_xbar = list()
    for i in range(nr_s1_quadrants):
        am_quadrant_pre_xbar.append(am.new_node("am_quadrant_pre_xbar_{}".format(i)))

    # Quadrant inter crossbar address map:
    am_quadrant_inter_xbar = am.new_node("am_quadrant_inter_xbar")

    # HBM crossbar address map
    am_hbm_xbar = am.new_node("am_hbm_xbar")

    # Quadrant crossbar address map
    am_wide_xbar_quadrant_s1 = list()
    am_narrow_xbar_quadrant_s1 = list()
    for i in range(nr_s1_quadrants):
        am_wide_xbar_quadrant_s1.append(am.new_node("wide_xbar_quadrant_s1_{}".format(i)))
        am_narrow_xbar_quadrant_s1.append(am.new_node("narrow_xbar_quadrant_s1_{}".format(i)))

    # Peripheral crossbar address map
    am_soc_axi_lite_periph_xbar = am.new_node("soc_axi_lite_periph_xbar")
    am_soc_regbus_periph_xbar = am.new_node("soc_periph_regbus_xbar")
    am_hbm_cfg_xbar = am.new_node("hbm_cfg_xbar")

    ############################
    # AM: Periph AXI Lite XBar #
    ############################
    nr_axi_lite_peripherals = len(occamy.cfg["peripherals"]["axi_lite_peripherals"])
    am_axi_lite_peripherals = []

    for p in range(nr_axi_lite_peripherals):
        am_axi_lite_peripherals.append(
            am.new_leaf(
                occamy.cfg["peripherals"]["axi_lite_peripherals"][p]["name"],
                occamy.cfg["peripherals"]["axi_lite_peripherals"][p]["length"],
                occamy.cfg["peripherals"]["axi_lite_peripherals"][p]["address"]
            ).attach_to(am_soc_axi_lite_periph_xbar)
        )
        # add debug module to devicetree
        if occamy.cfg["peripherals"]["axi_lite_peripherals"][p]["name"] == "debug":
            dts.add_device("debug", "riscv,debug-013", am_axi_lite_peripherals[p], [
                "interrupts-extended = <&CPU0_intc 65535>", "reg-names = \"control\""
            ])

    ##########################
    # AM: Periph Regbus XBar #
    ##########################
    nr_regbus_peripherals = len(occamy.cfg["peripherals"]["regbus_peripherals"])
    am_regbus_peripherals = []

    for p in range(nr_regbus_peripherals):
        am_regbus_peripherals.append(
            am.new_leaf(
                occamy.cfg["peripherals"]["regbus_peripherals"][p]["name"],
                occamy.cfg["peripherals"]["regbus_peripherals"][p]["length"],
                occamy.cfg["peripherals"]["regbus_peripherals"][p]["address"]
            ).attach_to(am_soc_regbus_periph_xbar)
        )
        # add uart to devicetree
        if occamy.cfg["peripherals"]["regbus_peripherals"][p]["name"] == "uart":
            dts.add_device("serial", "lowrisc,serial", am_regbus_peripherals[p], [
                "clock-frequency = <50000000>", "current-speed = <115200>",
                "interrupt-parent = <&PLIC0>", "interrupts = <1>"
            ])
        # add plic to devicetree
        elif occamy.cfg["peripherals"]["regbus_peripherals"][p]["name"] == "plic":
            dts.add_plic([0], am_regbus_peripherals[p])

    # add bootrom seperately
    am_bootrom = am.new_leaf(
        "bootrom",
        occamy.cfg["peripherals"]["rom"]["length"],
        occamy.cfg["peripherals"]["rom"]["address"]).attach_to(am_soc_regbus_periph_xbar)

    # add clint seperately
    am_clint = am.new_leaf(
        "clint",
        occamy.cfg["peripherals"]["clint"]["length"],
        occamy.cfg["peripherals"]["clint"]["address"]).attach_to(am_soc_regbus_periph_xbar)

    # add clint to devicetree
    dts.add_clint([0], am_clint)

    ##################
    # AM: SPM / PCIE #
    ##################
    # Connect PCIE to Wide AXI
    am_pcie = am.new_leaf(
        "pcie",
        occamy.cfg["pcie"]["length"],
        occamy.cfg["pcie"]["address_io"],
        occamy.cfg["pcie"]["address_mm"]).attach_to(am_soc_narrow_xbar)

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

    ###########
    # AM: RMQ #
    ###########
    # Add a remote quadrant port
    nr_remote_quadrants = len(occamy.cfg["remote_quadrants"])
    nr_remote_cores = 0
    rmq_cluster_cnt = 0
    am_remote_quadrants = list()
    for i, rq in enumerate(occamy.cfg["remote_quadrants"]):
        node = am.new_node("rmq_{}".format(i))
        am_remote_quadrants.append(node)
        alen = rq["nr_clusters"]*0x40000
        addr = 0x10000000 + (nr_s1_clusters*nr_s1_quadrants+rmq_cluster_cnt)*0x40000
        leaf = am.new_leaf("rmq_{}".format(i), alen, addr)
        node.attach(leaf)
        node.attach_to(am_soc_narrow_xbar)
        node.attach_to(am_quadrant_inter_xbar)
        nr_remote_cores += rq["nr_clusters"] * rq["nr_cluster_cores"]
        rmq_cluster_cnt += rq["nr_clusters"]
        # remote quadrant control
        alen = occamy.cfg["s1_quadrant"]["cfg_base_offset"]
        addr = occamy.cfg["s1_quadrant"]["cfg_base_addr"] + (i + nr_s1_quadrants) * alen
        leaf = am.new_leaf("rmq_{}_cfg".format(i), alen, addr)
        node.attach(leaf)
        node.attach_to(am_soc_narrow_xbar)

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
                *bases).attach_to(am_hbm_xbar))

    dts.add_memory(am_hbm[0])

    ##############################
    # AM: Quadrants and Clusters #
    ##############################
    cluster_base_offset = occamy.cfg["cluster"]["cluster_base_offset"]
    cluster_tcdm_size = occamy.cfg["cluster"]["tcdm"]["size"] * 1024  # config is in KiB
    cluster_periph_size = occamy.cfg["cluster"]["cluster_periph_size"] * 1024
    cluster_zero_mem_size = occamy.cfg["cluster"]["zero_mem_size"] * 1024

    # assert memory region allocation
    error_str = "ERROR: cluster peripherals, zero memory and tcdm do not fit into the allocated memory region!!!"
    assert (cluster_tcdm_size + cluster_periph_size + cluster_zero_mem_size) <= cluster_base_offset, error_str

    cluster_base_addr = occamy.cfg["cluster"]["cluster_base_addr"]
    quadrant_size = cluster_base_offset * nr_s1_clusters

    for i in range(nr_s1_quadrants):
        cluster_i_start_addr = cluster_base_addr + i * quadrant_size

        am_clusters = list()
        for j in range(nr_s1_clusters):
            bases_cluster = list()
            bases_cluster.append(cluster_i_start_addr + j * cluster_base_offset + 0)
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
            bases_cluster.append(cluster_i_start_addr + j * cluster_base_offset
                                 + cluster_tcdm_size)
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

            bases_cluster = list()
            bases_cluster.append(cluster_i_start_addr + j * cluster_base_offset +
                                 cluster_tcdm_size + cluster_periph_size)
            am_clusters.append(
                am.new_leaf(
                    "quadrant_{}_cluster_{}_zero_mem".format(i, j),
                    cluster_zero_mem_size,
                    *bases_cluster
                ).attach_to(
                    am_wide_xbar_quadrant_s1[i]
                ).attach_to(
                    am_narrow_xbar_quadrant_s1[i]
                )
            )

        am.new_leaf(
                "quad_{}_cfg".format(i),
                occamy.cfg["s1_quadrant"]["cfg_base_offset"],
                occamy.cfg["s1_quadrant"]["cfg_base_addr"] + i * occamy.cfg["s1_quadrant"]["cfg_base_offset"]
            ).attach_to(
                am_narrow_xbar_quadrant_s1[i]
            ).attach_to(
                am_soc_narrow_xbar
            )

    #################
    # AM: Crossbars #
    #################
    # Connect quadrants AXI xbar
    for i in range(nr_s1_quadrants):
        am_narrow_xbar_quadrant_s1[i].attach(am_wide_xbar_quadrant_s1[i])
        am_wide_xbar_quadrant_s1[i].attach(am_quadrant_pre_xbar[i])
        am_soc_narrow_xbar.attach(am_narrow_xbar_quadrant_s1[i])
        am_quadrant_inter_xbar.attach(am_wide_xbar_quadrant_s1[i])

    # Connect quadrant inter xbar
    am_soc_wide_xbar.attach(am_quadrant_inter_xbar)
    am_quadrant_inter_xbar.attach(am_soc_wide_xbar)
    for i in range(nr_s1_quadrants):
        am_quadrant_pre_xbar[i].attach(am_quadrant_inter_xbar)

    # Connect HBM xbar masters (memory slaves already attached)
    am_soc_wide_xbar.attach(am_hbm_xbar)
    for i in range(nr_s1_quadrants):
        am_quadrant_pre_xbar[i].attach(am_hbm_xbar)

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
    soc_axi_lite_periph_xbar.add_output_entry("soc", am_soc_narrow_xbar)

    # connect AXI lite peripherals
    for p in range(nr_axi_lite_peripherals):
        soc_axi_lite_periph_xbar.add_input(
            occamy.cfg["peripherals"]["axi_lite_peripherals"][p]["name"]
        )
        soc_axi_lite_periph_xbar.add_output_entry(
            occamy.cfg["peripherals"]["axi_lite_peripherals"][p]["name"],
            am_axi_lite_peripherals[p]
        )

    ###############
    # HBM control #
    ###############
    hbm_cfg_xbar = solder.RegBusXbar(48,
                                     32,
                                     context="hbm_ctrl",
                                     name="hbm_cfg_xbar",
                                     # Use internal clock and reset
                                     clk="cfg_clk",
                                     rst="cfg_rst_n",
                                     node=am_hbm_cfg_xbar)

    for name, region in occamy.cfg["hbm"]["cfg_regions"].items():
        leaf = am.new_leaf(f"hbm_cfg_{name}",
                           region["length"],
                           region["address"]
                           ).attach_to(am_hbm_cfg_xbar)
        hbm_cfg_xbar.add_output_entry(name, leaf)

    hbm_cfg_xbar.add_input("cfg")

    am_soc_regbus_periph_xbar.attach(am_hbm_cfg_xbar)

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

    # connect Regbus peripherals
    for p in range(nr_regbus_peripherals):
        soc_regbus_periph_xbar.add_output_entry(
            occamy.cfg["peripherals"]["regbus_peripherals"][p]["name"],
            am_regbus_peripherals[p]
        )

    # add bootrom and clint seperately
    soc_regbus_periph_xbar.add_output_entry("bootrom", am_bootrom)
    soc_regbus_periph_xbar.add_output_entry("clint", am_clint)

    # add hbm cfg xbar separately
    soc_regbus_periph_xbar.add_output_entry("hbm_cfg", am_hbm_cfg_xbar)

    ##################
    # SoC Wide Xbars #
    ##################

    # Quadrant pre xbars
    # Each connects one quadrant master to the HBM and quadrant xbars
    quadrant_pre_xbars = list()
    for i in range(nr_s1_quadrants):
        quadrant_pre_xbar = solder.AxiXbar(
            48,
            512,
            occamy.cfg["pre_xbar_slv_id_width_no_rocache"] + (
                1 if occamy.cfg["s1_quadrant"].get("ro_cache_cfg") else 0),
            name="quadrant_pre_xbar_{}".format(i),
            clk="clk_i",
            rst="rst_ni",
            max_slv_trans=occamy.cfg["quadrant_pre_xbar"]["max_slv_trans"],
            max_mst_trans=occamy.cfg["quadrant_pre_xbar"]["max_mst_trans"],
            fall_through=occamy.cfg["quadrant_pre_xbar"]["fall_through"],
            no_loopback=True,
            atop_support=False,
            context="soc",
            node=am_quadrant_pre_xbar[i])

        # Default port:
        quadrant_pre_xbar.add_output_entry("quadrant_inter_xbar", am_quadrant_inter_xbar)
        quadrant_pre_xbar.add_output_entry("hbm_xbar", am_hbm_xbar)
        quadrant_pre_xbar.add_input("quadrant")

        quadrant_pre_xbars.append(quadrant_pre_xbar)

    # Quadrant inter xbar
    # Connects all quadrant pre xbars to all quadrants, with additional wide xbar M/S pair
    quadrant_inter_xbar = solder.AxiXbar(
        48,
        512,
        quadrant_pre_xbars[0].iw_out(),
        name="quadrant_inter_xbar",
        clk="clk_i",
        rst="rst_ni",
        max_slv_trans=occamy.cfg["quadrant_inter_xbar"]["max_slv_trans"],
        max_mst_trans=occamy.cfg["quadrant_inter_xbar"]["max_mst_trans"],
        fall_through=occamy.cfg["quadrant_inter_xbar"]["fall_through"],
        no_loopback=True,
        atop_support=False,
        context="soc",
        node=am_quadrant_inter_xbar)

    # Default port: soc wide xbar
    quadrant_inter_xbar.add_output_entry("wide_xbar", am_soc_wide_xbar)
    quadrant_inter_xbar.add_input("wide_xbar")
    for i in range(nr_s1_quadrants):
        # Default route passes HBI through quadrant 0
        # --> mask this route, forcing it through default wide xbar
        quadrant_inter_xbar.add_output_entry("quadrant_{}".format(i),
                                             am_wide_xbar_quadrant_s1[i])
        quadrant_inter_xbar.add_input("quadrant_{}".format(i))
    for i, rq in enumerate(occamy.cfg["remote_quadrants"]):
        quadrant_inter_xbar.add_input("rmq_{}".format(i))
        quadrant_inter_xbar.add_output_entry("rmq_{}".format(i), am_remote_quadrants[i])
    # Connectrion from remote
    if is_remote_quadrant:
        quadrant_inter_xbar.add_output("remote", [])
        quadrant_inter_xbar.add_input("remote")

    hbm_xbar = solder.AxiXbar(
        48,
        512,
        quadrant_pre_xbars[0].iw_out(),
        name="hbm_xbar",
        clk="clk_i",
        rst="rst_ni",
        max_slv_trans=occamy.cfg["hbm_xbar"]["max_slv_trans"],
        max_mst_trans=occamy.cfg["hbm_xbar"]["max_mst_trans"],
        fall_through=occamy.cfg["hbm_xbar"]["fall_through"],
        no_loopback=True,
        atop_support=False,
        context="soc",
        node=am_hbm_xbar)

    # Default port: HBM 0
    for i in range(nr_hbm_channels):
        hbm_xbar.add_output_entry("hbm_{}".format(i), am_hbm[i])
    for i in range(nr_s1_quadrants):
        hbm_xbar.add_input("quadrant_{}".format(i))
    hbm_xbar.add_input("wide_xbar")

    soc_wide_xbar = solder.AxiXbar(
        48,
        512,
        # This is the cleanest solution minimizing ID width conversions
        quadrant_pre_xbars[0].iw,
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

    # Default port: HBI (always escalate "upwards" in hierarchy -> off-chip)
    if not is_remote_quadrant:
        soc_wide_xbar.add_output_entry("hbi", am_hbi)
    soc_wide_xbar.add_output_entry("hbm_xbar", am_hbm_xbar)
    soc_wide_xbar.add_output_entry("quadrant_inter_xbar", am_quadrant_inter_xbar)
    soc_wide_xbar.add_output_entry("soc_narrow", am_soc_narrow_xbar)
    soc_wide_xbar.add_input("hbi")
    soc_wide_xbar.add_input("quadrant_inter_xbar")
    soc_wide_xbar.add_input("soc_narrow")

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
        soc_narrow_xbar.add_output_symbolic_multi("s1_quadrant_{}".format(i),
                                                  [("s1_quadrant_base_addr",
                                                    "S1QuadrantAddressSpace"),
                                                   ("s1_quadrant_cfg_base_addr",
                                                    "S1QuadrantCfgAddressSpace")])
        soc_narrow_xbar.add_input("s1_quadrant_{}".format(i))

    soc_narrow_xbar.add_input("cva6")
    soc_narrow_xbar.add_input("soc_wide")
    soc_narrow_xbar.add_input("periph")
    soc_narrow_xbar.add_input("pcie")
    soc_narrow_xbar.add_input("hbi")
    dts.add_cpu("eth,ariane")

    # Default port: wide xbar
    soc_narrow_xbar.add_output_entry("soc_wide", am_soc_wide_xbar)
    if not is_remote_quadrant:
        soc_narrow_xbar.add_output_entry("hbi", am_hbi)
    soc_narrow_xbar.add_output_entry("periph", am_soc_axi_lite_periph_xbar)
    soc_narrow_xbar.add_output_entry("spm", am_spm)
    soc_narrow_xbar.add_output_entry("regbus_periph",
                                     am_soc_regbus_periph_xbar)
    soc_narrow_xbar.add_output_entry("pcie", am_pcie)
    for i, rq in enumerate(occamy.cfg["remote_quadrants"]):
        soc_narrow_xbar.add_input("rmq_{}".format(i))
        soc_narrow_xbar.add_output_entry("rmq_{}".format(i), am_remote_quadrants[i])
    # Connectrion from remote
    if is_remote_quadrant:
        soc_narrow_xbar.add_output("remote", [])
        soc_narrow_xbar.add_input("remote")

    ##########################
    # S1 Quadrant controller #
    ##########################

    # We need 3 "crossbars", which are really simple muxes and demuxes
    quadrant_s1_ctrl_xbars = dict()
    for name, (iw, lm) in {
        'soc_to_quad': (soc_narrow_xbar.iw_out(), "axi_pkg::CUT_SLV_PORTS"),
        'quad_to_soc': (soc_narrow_xbar.iw, "axi_pkg::CUT_MST_PORTS"),
    }.items():
        # Reuse (preserve) narrow Xbar IDs and max transactions
        quadrant_s1_ctrl_xbars[name] = solder.AxiXbar(
            48,
            64,
            iw,
            name="quadrant_s1_ctrl_{}_xbar".format(name),
            clk="clk_i",
            rst="rst_ni",
            max_slv_trans=occamy.cfg["narrow_xbar"]["max_slv_trans"],
            max_mst_trans=occamy.cfg["narrow_xbar"]["max_mst_trans"],
            fall_through=occamy.cfg["narrow_xbar"]["fall_through"],
            latency_mode=lm,
            context="quadrant_s1_ctrl")

    for name in ['soc_to_quad', 'quad_to_soc']:
        quadrant_s1_ctrl_xbars[name].add_output("out", [])
        quadrant_s1_ctrl_xbars[name].add_input("in")
        quadrant_s1_ctrl_xbars[name].add_output_symbolic("internal",
                                                         "internal_xbar_base_addr",
                                                         "S1QuadrantCfgAddressSpace")

    # AXI Lite mux to combine register requests
    quadrant_s1_ctrl_mux = solder.AxiLiteXbar(
        48,
        32,
        name="quadrant_s1_ctrl_mux",
        clk="clk_i",
        rst="rst_ni",
        max_slv_trans=occamy.cfg["narrow_xbar"]["max_slv_trans"],
        max_mst_trans=occamy.cfg["narrow_xbar"]["max_mst_trans"],
        fall_through=False,
        latency_mode="axi_pkg::CUT_MST_PORTS",
        context="quadrant_s1_ctrl")

    quadrant_s1_ctrl_mux.add_output("out", [(0, (1 << 48) - 1)])
    quadrant_s1_ctrl_mux.add_input("soc")
    quadrant_s1_ctrl_mux.add_input("quad")

    ################
    # S1 Quadrants #
    ################
    # Dummy entries to generate associated types.
    wide_xbar_quadrant_s1 = solder.AxiXbar(
        48,
        512,
        occamy.cfg["s1_quadrant"]["wide_xbar_slv_id_width"],
        name="wide_xbar_quadrant_s1",
        clk="clk_quadrant",
        rst="rst_quadrant_n",
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
        clk="clk_quadrant",
        rst="rst_quadrant_n",
        max_slv_trans=occamy.cfg["s1_quadrant"]["narrow_xbar"]
        ["max_slv_trans"],
        max_mst_trans=occamy.cfg["s1_quadrant"]["narrow_xbar"]
        ["max_mst_trans"],
        fall_through=occamy.cfg["s1_quadrant"]["narrow_xbar"]["fall_through"],
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

    # remote downstream mux
    rmq_mux = [None]*max(nr_remote_quadrants, 1 if is_remote_quadrant else 0)
    rmq_demux = [None]*max(nr_remote_quadrants, 1 if is_remote_quadrant else 0)
    for i in range(max(nr_remote_quadrants, 1 if is_remote_quadrant else 0)):
        rmq_mux[i] = solder.AxiMux(
            48,
            512,
            4,
            max_w_trans=occamy.cfg["txns"]["rmq"],
            context="xilinx_wrapper",
            name="rmq_mux_{}".format(i),
            clk="clk_i",
            rst="rst_ni")
        rmq_mux[i].add_input("narrow")
        rmq_mux[i].add_input("wide")
        rmq_demux[i] = solder.AxiDemux(
            48,
            512,
            5,
            "rmq_demux_awsel[{}]".format(i),
            "rmq_demux_arsel[{}]".format(i),
            max_trans=occamy.cfg["txns"]["rmq"],
            look_bits=3,
            context="xilinx_wrapper",
            name="rmq_demux_{}".format(i),
            clk="clk_i",
            rst="rst_ni")
        rmq_demux[i].add_output("narrow")
        rmq_demux[i].add_output("wide")

    # Generate the Verilog code.
    solder.render()

    ###############
    # HBM APB CTL #
    ###############
    if is_remote_quadrant:
        apb_hbm_cfg = None
    else:
        apb_hbm_cfg = solder.ApbBus(clk=soc_regbus_periph_xbar.clk,
                                    rst=soc_regbus_periph_xbar.rst,
                                    aw=soc_regbus_periph_xbar.aw,
                                    dw=soc_regbus_periph_xbar.dw,
                                    name="apb_hbm_cfg")

    kwargs = {
        "solder": solder,
        "util": util,
        "args": args,
        "name": args.name,
        "soc_narrow_xbar": soc_narrow_xbar,
        "soc_wide_xbar": soc_wide_xbar,
        "quadrant_pre_xbars": quadrant_pre_xbars,
        "hbm_xbar": hbm_xbar,
        "quadrant_inter_xbar": quadrant_inter_xbar,
        "quadrant_s1_ctrl_xbars": quadrant_s1_ctrl_xbars,
        "quadrant_s1_ctrl_mux": quadrant_s1_ctrl_mux,
        "wide_xbar_quadrant_s1": wide_xbar_quadrant_s1,
        "narrow_xbar_quadrant_s1": narrow_xbar_quadrant_s1,
        "soc_regbus_periph_xbar": soc_regbus_periph_xbar,
        "hbm_cfg_xbar": hbm_cfg_xbar,
        "apb_hbm_cfg": apb_hbm_cfg,
        "cfg": occamy.cfg,
        "cores": nr_s1_quadrants * nr_s1_clusters * nr_cluster_cores + nr_remote_cores + 1,
        "lcl_cores": nr_s1_quadrants * nr_s1_clusters * nr_cluster_cores + (0 if is_remote_quadrant else 1),
        "remote_quadrants": occamy.cfg["remote_quadrants"],
        "is_remote_quadrant": occamy.cfg["is_remote_quadrant"],
        "nr_s1_quadrants": nr_s1_quadrants,
        "nr_remote_quadrants": nr_remote_quadrants,
        "nr_s1_clusters": nr_s1_clusters,
        "nr_cluster_cores": nr_cluster_cores,
        "hbm_channel_size": hbm_channel_size,
        "nr_hbm_channels": nr_hbm_channels,
        "rmq_mux": rmq_mux,
        "rmq_demux": rmq_demux
    }

    # Emit the code.
    #############
    # Top-Level #
    #############
    write_template(args.top_sv,
                   outdir,
                   fname="{}_top.sv".format(args.name),
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
    if nr_s1_quadrants > 0:
        write_template(args.quadrant_s1,
                       outdir,
                       fname="{}_quadrant_s1.sv".format(args.name),
                       module=solder.code_module['quadrant_s1'],
                       **kwargs)
    else:
        tpl_path = args.quadrant_s1
        if tpl_path:
            tpl_path = pathlib.Path(tpl_path).absolute()
            if tpl_path.exists():
                print(outdir, args.name)
                with open("{}/{}_quadrant_s1.sv".format(outdir, args.name), 'w') as f:
                    f.write("// no quadrants in this design")

    ##################
    # Xilinx Wrapper #
    ##################
    has_rmq_code = nr_remote_quadrants > 0 or is_remote_quadrant
    write_template(args.xilinx_sv,
                   outdir,
                   fname="{}_xilinx.sv".format(args.name),
                   module=solder.code_module['xilinx_wrapper'] if has_rmq_code else "",
                   **kwargs)
    ###########
    # Package #
    ###########
    write_template(args.pkg_sv, outdir, **kwargs, package=solder.code_package)

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

    ###############
    # HBM control #
    ###############
    write_template(args.hbm_ctrl,
                   outdir,
                   module=solder.code_module['hbm_ctrl'],
                   **kwargs)

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
