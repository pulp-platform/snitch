#!/usr/bin/env python3
# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Paul Scheffler <paulsc@iis.ee.ethz.ch>
#
# This class implements a minimal wrapping IPC server for `tb_lib`.
# `__main__` shows a demonstrator for it, running a simulation and accessing its memory.

import os
import sys
import tempfile
import subprocess
import struct


class SnitchSim:

    def __init__(self, sim_bin: str, snitch_bin: str):
        self.sim_bin = sim_bin
        self.snitch_bin = snitch_bin
        self.sim = None
        self.tmpdir = None

    def start(self):
        # Create FIFOs
        self.tmpdir = tempfile.TemporaryDirectory()
        tx_fd = os.path.join(self.tmpdir.name, 'tx')
        os.mkfifo(tx_fd)
        rx_fd = os.path.join(self.tmpdir.name, 'rx')
        os.mkfifo(rx_fd)
        # Start simulator process
        ipc_arg = f'--ipc,{tx_fd},{rx_fd}'
        self.sim = subprocess.Popen([self.sim_bin, self.snitch_bin, ipc_arg])
        # Open FIFOs
        self.tx = open(tx_fd, 'wb')
        self.rx = open(rx_fd, 'rb')

    def __sim_active(func):
        def inner(self, *args, **kwargs):
            if self.sim is None:
                raise RuntimeError(f'Snitch is not running (simulation `{self.sim_bin}`, binary `{self.snitch_bin}`)')
            return func(self, *args, **kwargs)
        return inner

    @__sim_active
    def read(self, addr: int, length: int) -> bytes:
        op = struct.pack('QQQ', 0, addr, length)
        self.tx.write(op)
        self.tx.flush()
        return self.rx.read(length)

    @__sim_active
    def write(self, addr: int, data: bytes):
        op = struct.pack('QQQ', 1, addr, len(data))
        self.tx.write(op)
        self.tx.write(data)
        self.tx.flush()

    @__sim_active
    def poll(self, addr: int, mask32: int, exp32: int):
        # TODO: check endiannesses
        op = struct.pack('QQLL', 2, addr, mask32, exp32)
        self.tx.write(op)
        self.tx.flush()
        return int.from_bytes(self.rx.read(4))

    # Simulator can exit only once TX FIFO closes
    @__sim_active
    def finish(self, wait_for_sim: bool = True):
        self.rx.close()
        self.tx.close()
        if (wait_for_sim):
            self.sim.wait()
        else:
            self.sim.terminate()
        self.tmpdir.cleanup()
        self.sim = None


if __name__ == "__main__":
    sim = SnitchSim(*sys.argv[1:])
    sim.start()

    wstr = b'This is a test string to be written to testbench memory.'
    sim.write(0xdeadbeef, wstr)
    rstr = sim.read(0xdeadbeef, len(wstr)+5)
    print(f'Read back string: `{rstr}`')

    sim.finish(wait_for_sim=False)
