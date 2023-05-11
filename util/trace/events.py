#!/usr/bin/env python3
# Copyright 2020 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# This script takes a CVA6 or Snitch trace and it exports the simulation time
# of all mcycle CSR reads in a format compatible with the gen_trace.py
# script's JSON output.
#
# Author: Luca Colagrande <colluca@iis.ee.ethz.ch>


import sys
import argparse
from pathlib import Path
import json
import re


# Filters mcycle CSR reads
EVENT_REGEX = r'.*csrr.*mcycle'
# Captures the simulation time and cycle of an instruction
TIME_REGEX = r'(\d+)[a-z\s]*(\d+)'
# Normalizes the time unit to that of the Snitch traces
NORM_FACTOR = {
    'snitch': 1 / 1000,
    'cva6': 1
}


def main():
    # Argument parsing
    parser = argparse.ArgumentParser()
    parser.add_argument(
        'input',
        help='Input trace file'
    )
    parser.add_argument(
        '-o',
        '--output',
        default='',
        help='JSON output file (by default the extension of the input is replaced with .json)'
    )
    parser.add_argument(
        '-f',
        '--format',
        default='snitch',
        choices=['cva6', 'snitch'],
        help='Trace format'
    )
    args = parser.parse_args()

    input_file = Path(args.input)
    output_file = Path(args.output) if args.output else input_file.with_suffix('.json')

    # Compatible with region size calculation in gen_trace.py
    def region_size(start, end):
        return (end - 1) - (start + 1) + 1

    # Process trace file
    regions = []
    with input_file.open('r') as f:

        # State
        ptime = 0
        # Iterate lines
        for line in f.readlines():
            # Update time on every line (if found)
            # Note: not all lines in a Snitch trace have time information
            results = re.search(TIME_REGEX, line)
            if results:
                time = int(results.groups()[0] * NORM_FACTOR[args.format])
            else:
                time = ptime

            # The first line in the file starts the first region
            if not regions:
                regions.append({'tstart': time})
            # mcycle CSR reads close the previous region (in the previous cycle)
            # and start a region (in the next cycle)
            elif re.search(EVENT_REGEX, line):
                regions[-1]['tend'] = time
                regions.append({'tstart': time})

            # Stop early if we hit an empty line
            # (filters performance metrics at the end of Snitch traces)
            if not line.strip():
                break
            # Save the time for lines without time info and to close the last region
            else:
                ptime = time

        # Last line in file closes last region
        regions[-1]['tend'] = ptime

    # Dump regions to file
    with output_file.open('w') as f:
        json.dump(regions, f, indent=4)


if __name__ == '__main__':
    sys.exit(main())
