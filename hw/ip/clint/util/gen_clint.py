#!/usr/bin/env python3
# Copyright 2020 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
r"""Mako template to Hjson register description
"""
import sys
import argparse
from io import StringIO

from mako.template import Template


def main():
    parser = argparse.ArgumentParser(prog="reg_rv_plic")
    parser.add_argument('input',
                        nargs='?',
                        metavar='file',
                        type=argparse.FileType('r'),
                        default=sys.stdin,
                        help='input template file')
    parser.add_argument('--cores', '-c', type=int, help='Number of cores', required=True)

    args = parser.parse_args()

    # Determine output: if stdin then stdout if not then ??
    out = StringIO()

    reg_tpl = Template(args.input.read())
    out.write(reg_tpl.render(cores=args.cores))

    print(out.getvalue())

    out.close()


if __name__ == "__main__":
    main()
