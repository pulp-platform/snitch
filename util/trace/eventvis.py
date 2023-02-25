#!/usr/bin/env python3
# Copyright 2020 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# This script takes a CSV of events, compatible with the CSV format produced by
# `perf_csv.py`, and creates a JSON file that can be visualized by
# [Trace-Viewer](https://github.com/catapult-project/catapult/tree/master/tracing)
# In Chrome, open `about:tracing` and load the JSON file to view it.
#
# Following is an example CSV containing two regions (as would be defined by the
# presence of one mcycle CSR read in the traces):
#
#  , prepare data,      , send interrupt,
# 0, 32906,        32911, 32911,          33662
#
# The first line is used to assign a name to each region.
# Each of the following lines starts with the hartid, followed by the start and
# end timestamps of each region.
# While the alignment of the region names in the first line w.r.t. the following
# lines does not matter, we suggest to align them with the columns containing the
# start times of the respective regions (as in the example above).
#
# This script can be compared to `tracevis.py`, but instead of visualizing individual
# instructions, it visualizes coarser grained regions as delimited by events
# in the traces.
#
# Author: Luca Colagrande <colluca@iis.ee.ethz.ch>

import sys
import argparse
import csv
import json


def pairwise(iterable):
    "s -> (s0, s1), (s2, s3), (s4, s5), ..."
    a = iter(iterable)
    return zip(a, a)


# Converts nanoseconds to microseconds
def us(ns):
    return ns / 1000


def main():
    # Argument parsing
    parser = argparse.ArgumentParser()
    parser.add_argument(
        'csv',
        metavar='<csv>',
        help='Input CSV file')
    parser.add_argument(
        '-o',
        '--output',
        metavar='<json>',
        nargs='?',
        default='events.json',
        help='Output JSON file')
    args = parser.parse_args()

    # Read CSV to collect TraceViewer events
    events = []
    with open(args.csv) as f:
        reader = csv.reader(f, delimiter=',')

        # Get region names
        regions = [name for name in next(reader) if name]

        # Process lines
        for row in reader:

            # First entry in row is the hart ID
            tid = row[0]

            # Start and end times of each region follow
            for i, (start, end) in enumerate(pairwise(row[1:])):

                # Filter regions this hart does not take part in
                if start:

                    # Create TraceViewer event
                    ts = int(start)
                    dur = int(end) - ts
                    event = {'name': regions[i],
                             'ph': "X",  # Complete event type
                             'ts': us(ts),
                             'dur': us(dur),
                             'pid': 0,
                             'tid': tid
                             }
                    events.append(event)

    # Create TraceViewer JSON object
    tvobj = {}
    tvobj['traceEvents'] = events
    tvobj['displayTimeUnit'] = "ns"

    # Dump TraceViewer events to JSON file
    with open(args.output, 'w') as f:
        json.dump(tvobj, f, indent=4)


if __name__ == '__main__':
    sys.exit(main())
