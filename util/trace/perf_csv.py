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
import glob
import re
import json
import pandas as pd


FILES_GLOB_STRING = 'hart_*_perf.json'
HARTID_REGEX_STRING = r'hart_(\d+)_perf\.json'


def main():
    # Argument parsing and iterator creation
    parser = argparse.ArgumentParser()
    parser.add_argument(
        'in_dir',
        type=str,
        help='Input directory')
    parser.add_argument(
        'csv',
        type=str,
        help='CSV output file')
    args = parser.parse_args()

    files = sorted(glob.glob(args.in_dir + '/' + FILES_GLOB_STRING))

    # Populate a list (one entry per hart) of dictionaries
    # enumerating all the performance metrics for each hart
    data = []
    index = []
    for file in files:

        # Get hart id from filename and append to index
        hartid = int(re.search(HARTID_REGEX_STRING, file).group(1))
        index.append(hartid)

        # Populate dictionary of metrics for the current hart
        hart_metrics = {}
        with open(file, 'r') as f:
            hart_data = json.load(f)

            # Uniquefy names of performance metrics in each trace
            # region by prepending the region index, and merge
            # all region metrics in a single dictionary
            for i, region in enumerate(hart_data):
                region_metrics = {f'{i}_{key}': val for (key, val) in region.items()}
                hart_metrics.update(region_metrics)

        data.append(hart_metrics)

    # Export data
    df = pd.DataFrame.from_records(data, index)
    df.to_csv(args.csv)


if __name__ == '__main__':
    sys.exit(main())
