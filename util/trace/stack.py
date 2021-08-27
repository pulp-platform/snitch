#!/usr/bin/env python3
# Copyright 2020 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

# Analyze set of trace files for stack pointer location
# Usage: ./stack.py trace_hart_*.txt

import sys
import re

files = sys.argv[1:]
sps = {}
# Skip the first 6 occurences that relate to setting up sp and where it might
# have a value outside the TCDM
first_skip = 6

# Parse
for fn in files:
    hartid = int(re.match(r'.*trace_hart_(\d+)\.txt', fn).groups()[0])
    sps[hartid] = []
    i = 0
    first_skip_p = first_skip
    with open(fn) as f:
        pre_main = True
        for lino, line in enumerate(f.readlines()):
            z = re.match(r'.*sp  <-- 0x([a-fA-F0-9]+)', line)
            if z and first_skip_p != 0:
                first_skip_p -= 1
            elif z:
                sp = int(z.groups()[0], base=16)
                sps[hartid].append(sp)
                i += 1
    print(f'hart {hartid} records: {len(sps[hartid])} i: {i}')

# for each hart, calculate sp range
sp_ranges = []
for hartid, sp in sps.items():
    if len(sp):
        sp_ranges.append((min(sp), max(sp)))
    else:
        sp_ranges.append((0, 0))


def in_any_range(vals, lst):
    ret = []
    for i, l in enumerate(lst):
        # print(f'test: {vals} {l[0]} {l[1]} {[val <= l[1] and val >= l[0] for val in vals]}')
        if any([val <= l[1] and val >= l[0] for val in vals]):
            ret.append(i)
    return ret


for i, spr in enumerate(sp_ranges):
    print(f'hartid: {i} sp_min: {spr[0]:08x} sp_max: {spr[1]:08x} collides: {in_any_range(spr,sp_ranges).remove(i)}')
