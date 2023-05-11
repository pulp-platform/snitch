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
from clustergen.cluster import SnitchClusterTB
from mako.template import Template


def write_template(tpl_path, outdir, fname=None, **kwargs):

    # Compile a regex to trim trailing whitespaces on lines.
    re_trailws = re.compile(r'[ \t\r]+$', re.MULTILINE)

    if tpl_path:
        tpl_path = pathlib.Path(tpl_path).absolute()
        if tpl_path.exists():
            tpl = Template(filename=str(tpl_path))
            fname = tpl_path.with_suffix("").name if not fname else fname
            with open(outdir / fname, "w") as file:
                code = tpl.render_unicode(**kwargs)
                code = re_trailws.sub("", code)
                file.write(code)
        else:
            raise FileNotFoundError


def main():
    """Generate a Snitch cluster TB and all corresponding configuration files."""
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
    parser.add_argument("--wrapper",
                        action="store_true",
                        help="Generate Snitch cluster wrapper")
    parser.add_argument("--linker",
                        action="store_true",
                        help="Generate linker script")
    parser.add_argument("--bootdata",
                        action="store_true",
                        help="Generate bootdata")
    parser.add_argument("--memories",
                        action="store_true",
                        help="Generate memories")
    parser.add_argument("--template",
                        metavar="template",
                        help="Name of the template file")

    args = parser.parse_args()

    # Read HJSON description
    with args.clustercfg as file:
        try:
            srcfull = file.read()
            obj = hjson.loads(srcfull, use_decimal=True)
            obj = JsonRef.replace_refs(obj)
        except ValueError:
            raise SystemExit(sys.exc_info()[1])

    cluster_tb = SnitchClusterTB(obj)

    if not args.outdir.is_dir():
        exit("Out directory is not a valid path.")

    outdir = args.outdir
    outdir.mkdir(parents=True, exist_ok=True)

    ##############
    # Misc files #
    ##############

    if args.wrapper:
        with open(outdir / "snitch_cluster_wrapper.sv", "w") as f:
            f.write(cluster_tb.render_wrapper())

    if args.linker:
        with open(outdir / "link.ld", "w") as f:
            f.write(cluster_tb.render_linker_script())

    if args.bootdata:
        with open(outdir / "bootdata.cc", "w") as f:
            f.write(cluster_tb.render_bootdata())

    if args.memories:
        with open(outdir / "memories.json", "w") as f:
            f.write(cluster_tb.cluster.memory_cfg())

    ####################
    # Generic template #
    ####################

    kwargs = {
        "cfg": cluster_tb.cfg,
    }

    if args.template:
        write_template(args.template, outdir, **kwargs)


if __name__ == "__main__":
    main()
