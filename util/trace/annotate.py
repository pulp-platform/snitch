#!/usr/bin/env python3

# Copyright 2021 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

# This script parses the traces generated by Snitch and creates an annotated
# trace that includes code sources
# Example output:
#     ; snrt_hartid (team.c:14)
#     ;  in snrt_cluster_core_idx (team.c:47)
#     ;  in main (event_unit.c:21)
#     ;  asm("csrr %0, mhartid" : "=r"(hartid));
#           80000048  x13=0000000a                            # csrr    a3, mhartid

import sys
import os
from functools import lru_cache
import argparse

# Argument parsing
parser = argparse.ArgumentParser('annotate', allow_abbrev=True)
parser.add_argument(
    'elf',
    metavar='<elf>',
    help='The binary executed to generate the annotation',
)
parser.add_argument(
    'trace',
    metavar='<trace>',
    help='The trace file to annotate')
parser.add_argument(
    '-o',
    '--output',
    metavar='<annotated>',
    nargs='?',
    default='annotated.s',
    help='Output annotated trace')
parser.add_argument(
    '--addr2line',
    metavar='<path>',
    nargs='?',
    default='llvm-addr2line',
    help='`addr2line` binary to use for parsing')
parser.add_argument(
    '-s',
    '--start',
    metavar='<line>',
    nargs='?',
    type=int,
    default=0,
    help='First line to parse')
parser.add_argument(
    '-e',
    '--end',
    metavar='<line>',
    nargs='?',
    type=int,
    default=-1,
    help='Last line to parse')

args = parser.parse_args()

elf = args.elf
trace = args.trace
output = args.output
addr2line = args.addr2line

print('elf:', elf, file=sys.stderr)
print('trace:', trace, file=sys.stderr)
print('output:', output, file=sys.stderr)
print('addr2line:', addr2line, file=sys.stderr)

of = open(output, 'w')

print(f' annotating: {output}    ', end='')

# buffer source files
src_files = {}


@lru_cache(maxsize=1024)
def adr2line(addr):
    cmd = f'{addr2line} -e {elf} -f -i {addr:x}'
    return os.popen(cmd).read().split('\n')


with open(trace, 'r') as f:

    last = ''
    # print(addr)
    # print(fun)

    tot_lines = len(open(trace).readlines()[args.start:args.end])
    last_prog = 0
    for lino, line in enumerate(f.readlines()):

        addr = int(line.split(' ')[3], base=16)
        addr_hex = f'{addr:x}'
        cmd = f'llvm-addr2line -e {elf} -f -i {addr_hex}'

        # ret = os.popen(cmd).read().split('\n')
        ret = adr2line(addr)

        funs = ret[::2]
        files = [x.split('/')[-1] for x in ret[1::2]]
        files_abs = [x for x in ret[1::2]]
        # Assemble annotation string
        if len(funs):
            annot = f'; {funs[0]} ({files[0]})'
            for fun, file in zip(funs[1:], files[1:]):
                annot = f'{annot}\n;  in {fun} ({file})'

        # Get source of last file and print the line
        src_fname = files_abs[0].split(':')[0]
        if src_fname not in src_files.keys():
            try:
                src_files[src_fname] = [x.strip()
                                        for x in open(src_fname, 'r').readlines()]
            except OSError as e:
                src_files[src_fname] = None
        if src_files[src_fname] is not None:
            srf_f_line = int(files_abs[0].split(':')[-1])
            src_line = src_files[src_fname][srf_f_line-1]
            annot = f'{annot}\n;  {src_line}'

        if len(annot) and annot != last:
            of.write(annot+'\n')
        of.write(f'      {line[line.find(addr_hex):]}')
        last = annot

        # very simple progress
        prog = int(100.0 / tot_lines * lino)
        if prog > last_prog:
            last_prog = prog
            sys.stdout.write(f'\b\b\b\b{prog:3d}%')
            sys.stdout.flush()
print(' done')
print(adr2line.cache_info())
