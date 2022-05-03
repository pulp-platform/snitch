#!/usr/bin/env python3

# Copyright 2020 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

# Generate a tcl script for writing a binary to a memory location in the FPGA
#
# Usage:
#   bin2jtag.py -d hw_axi_1 -b 1000 bootrom.bin > mem.tcl
#
# In vivado then `source mem.tcl` to execute
#
# Using
# - https://github.com/anishathalye/bin2coe/blob/master/src/bin2coe/convert.py

import sys
from argparse import ArgumentParser

from signal import signal, SIGPIPE, SIG_DFL
signal(SIGPIPE, SIG_DFL)


def main():
    parser = ArgumentParser()
    parser.add_argument('-d', '--device', type=str, default='hw_axi_1', help='what HW axi to use')
    parser.add_argument('-b', '--base', type=str, default='0', help='memory base address in hex')
    parser.add_argument('-c', '--chunk-size', type=int, default=32, help='number of words per burst transaction')
    parser.add_argument('binary', metavar='BIN', type=str, nargs=1, help='bin input')
    options = parser.parse_args()

    width = 32
    radix = 16
    fd_o = sys.stdout

    with open(options.binary[0], 'rb') as f:
        data = f.read()

    convert(fd_o, data, width, radix, adr=int(options.base, 16), dev=options.device, chunk_size=options.chunk_size)


def chunks(it, n):
    res = []
    for elem in it:
        res.append(elem)
        if len(res) == n:
            yield res
            res = []
    if res:
        yield res


def word_to_int(word, little_endian):
    if not little_endian:
        word = reversed(word)
    value = 0
    for i, byte in enumerate(word):
        value += byte << (8*i)
    return value


def format_int(num, base, pad_width=0):
    chars = "0123456789abcdefghijklmnopqrstuvwxyz"
    if num < 0:
        raise ValueError('negative numbers not supported')
    res = []
    res.append(chars[num % base])
    while num >= base:
        num //= base
        res.append(chars[num % base])
    while len(res) < pad_width:
        res.append('0')
    return ''.join(res[::-1])


def convert(output, data, width, radix, adr=0, little_endian=True, dev='hw_axi_1', rb=True, chunk_size=1):
    pad_width = len(format_int(2**width-1, radix))
    t = f"[get_hw_axis {dev}]"
    tpl = "create_hw_axi_txn -cache 0 -force {n} {t} -address {a} -len {l} -type write -data {d}"
    tpl_rb = "create_hw_axi_txn -cache 0 -force {n} {t} -address {a} -len {l} -type read"
    tpl_run = "run_hw_axi {txn}"
    tx_name = "txn"

    d_buf = []
    chunk_cnt = 0

    output.write("set errs 0\n")

    def dump(adr, d_buf):
        # dump
        # tx_name = f"tx{chunk_cnt:05}"
        out = tpl.format(n=tx_name, t=t, a=f"{adr:08x}", d="_".join(d_buf), l=len(d_buf)) + '\n'
        output.write(out)
        output.write(tpl_run.format(txn=tx_name) + '\n')
        # read-back
        if rb:
            out = tpl_rb.format(n="wb", t=t, a=f"{adr:08x}", l=len(d_buf)) + '\n'
            output.write(out)
            output.write(f"run_hw_axi {'wb'}\n")
            output.write("set resp [get_property DATA [get_hw_axi_txns wb]]\n")
            # output.write("puts $resp\n")
            # output.write(f"puts {''.join(d_buf)}\n")
            s = f"set exp {''.join(d_buf)}\n"
            s += "if {$exp ne $resp} { puts Error; incr errs }\n"
            # output.write(f"puts {''.join(d_buf)}\n")
            output.write(s)

    for word in chunks(data, width // 8):
        d = format_int(word_to_int(word, little_endian), radix, pad_width)
        d_buf.insert(0, d)

        if len(d_buf) == chunk_size:
            dump(adr, d_buf)
            d_buf = []
            chunk_cnt += 1
            adr += chunk_size*(width // 8)

    if len(d_buf):
        dump(adr, d_buf)
    if rb:
        output.write("puts \"Errors: $errs\"\n")


if __name__ == "__main__":
    main()
