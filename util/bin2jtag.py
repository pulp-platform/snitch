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
# Requires bin2coe 
# - https://github.com/anishathalye/bin2coe/blob/master/src/bin2coe

from argparse import ArgumentParser
from io import BytesIO
from signal import signal, SIGPIPE, SIG_DFL
import sys

import bin2coe.convert

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

    # Writes jtag commands to fd_o
    convert(df_o, data, width, radix, int(options.base, 16), options.device, True, options.chunk_size)

def convert(output, data, width, radix, address, dev, rb, chunk_size):
    # License
    output.write("# Copyright 2020 ETH Zurich and University of Bologna.\n")
    output.write("# Solderpad Hardware License, Version 0.51, see LICENSE for details.\n")
    output.write("# SPDX-License-Identifier: SHL-0.51\n")

    # Pre tcl script
    output.write("set errs 0\n")

    # Templates for one data write
    t = f"[get_hw_axis {dev}]"
    tpl = "create_hw_axi_txn -cache 0 -force {n} {t} -address {a} -len {l} -type write -data {d}"
    tpl_rb = "create_hw_axi_txn -cache 0 -force {n} {t} -address {a} -len {l} -type read"
    tpl_run = "run_hw_axi {txn}"
    tx_name = "txn"

    # Get coe format from bin2coe
    temp = BytesIO()
    bin2coe.convert.convert(output=temp, data=data, width=width, depth=0, fill=0, radix=radix, little_endian=True, mem=True)
    # Split the coe format into string words
    word_list = [w for w in temp.getvalue().decode("utf-8").split("\n") if w != ""]

    # Loop over the string words
    i = 0
    while i < len(word_list):
        # Take care at for the end of the list
        k = min(len(word_list)-i, chunk_size)
        # Reorganize words
        words = word_list[i:i+k][::-1]
        # Write axi write
        out = tpl.format(n=tx_name, t=t, a=f"{address:08x}", d="_".join(words), l=len(words)) + '\n'
        output.write(out)
        output.write(tpl_run.format(txn=tx_name) + '\n')
        # Write axi readback
        if rb:
            out = tpl_rb.format(n="wb", t=t, a=f"{address:08x}", l=len(words)) + '\n'
            output.write(out)
            output.write(f"run_hw_axi {'wb'}\n")
            output.write("set resp [get_property DATA [get_hw_axi_txns wb]]\n")
            s = f"set exp {''.join(words)}\n"
            s += "if {$exp ne $resp} { puts Error; incr errs }\n"
            output.write(s)
        # Get to next chunk
        address += k * 4
        i += k

    if rb:
        output.write("puts \"Errors: $errs\"\n")


if __name__ == "__main__":
    main()
