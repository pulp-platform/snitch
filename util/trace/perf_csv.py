#!/usr/bin/env python3
# Copyright 2020 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# This script takes the performance metrics from all cores, in JSON format
# as dumped by the `events.py` or `gen_trace.py` scripts, and merges them
# into a single CSV file for global inspection.
#
# Author: Luca Colagrande <colluca@iis.ee.ethz.ch>


import sys
import argparse
import re
import json
import pandas as pd


HARTID_REGEX = r'\D*(\d*)\D*'


def main():
    # Argument parsing
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '-i',
        '--inputs',
        metavar='<inputs>',
        nargs='+',
        help='Input performance metric dumps')
    parser.add_argument(
        '-o',
        '--output',
        metavar='<csv>',
        nargs='?',
        default='perf.csv',
        help='Output CSV file')
    parser.add_argument(
        '--filter',
        nargs='*',
        help='All and only performance metrics to include in the CSV')
    args = parser.parse_args()

    dumps = sorted(args.inputs)

    # Populate a list (one entry per hart) of dictionaries
    # enumerating all the performance metrics for each hart
    data = []
    index = []
    for dump in dumps:

        # Get hart id from filename and append to index
        hartid = int(re.search(HARTID_REGEX, dump).group(1))
        index.append(hartid)

        # Populate dictionary of metrics for the current hart
        hart_metrics = {}
        with open(dump, 'r') as f:
            hart_data = json.load(f)

            # Uniquefy names of performance metrics in each trace
            # region by prepending the region index, and merge
            # all region metrics in a single dictionary
            for i, region in enumerate(hart_data):

                # If filter was provided on the command-line then filter out all
                # perf metrics which were not listed
                if args.filter:
                    region = {key: val for (key, val) in region.items() if key in args.filter}

                region_metrics = {f'{i}_{key}': val for (key, val) in region.items()}
                hart_metrics.update(region_metrics)

        data.append(hart_metrics)

    # Export data
    df = pd.DataFrame.from_records(data, index)
    df.to_csv(args.output)


if __name__ == '__main__':
    sys.exit(main())
