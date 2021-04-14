// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <stdint.h>

int main() {
    // volatile register double freg;
    // volatile register unsigned int ireg;

    // ireg = 0x42298a3d;  // = 42.384998321533203125
    unsigned ret = -1;

    asm volatile(
        // unsigned MSB(0x80000003 * 2) = 0x1
        "li t0, 0x80000003\n"
        "li t1, 2\n"
        "li t2, 0x1\n"

        "mulhu t3, t0, t1\n"
        "bne   t2, t3, 1f\n"

        // unsigned MSB(0xdeadbeef*0xdeadbeef) = 0xC1B1CD12
        "li t0, 0xdeadbeef\n"
        "li t1, 0xdeadbeef\n"
        "li t2, 0xC1B1CD12\n"

        "mulhu t3, t0, t1\n"
        "bne   t2, t3, 1f\n"

        // unsigned MSB(0xffffffff * 0xffffffff) = 0xFFFFFFFE
        "li t0, 0xffffffff\n"
        "li t1, 0xffffffff\n"
        "li t2, 0xFFFFFFFE\n"

        "mulhu  t3, t0, t1\n"
        "bne   t2, t3, 1f\n"

        // signed MSB(-1 * -1) = 0x0
        "li t0, 0xffffffff\n"
        "li t1, 0xffffffff\n"
        "li t2, 0x0\n"

        "mulh  t3, t0, t1\n"
        "bne   t2, t3, 1f\n"

        // signed MSB(-2147483648 * 2) = 0xffffffff
        // signed MSB(0x80000000  * 2) = 0xffffffff
        "li t0, 0x80000000\n"
        "li t1, 0x2\n"
        "li t2, 0xffffffff\n"

        "mulh  t3, t0, t1\n"
        "bne   t2, t3, 1f\n"

        // signed MSB(0xdeadbeef*0xdeadbeef) = 0x4564f34
        "li t0, 0xdeadbeef\n"
        "li t1, 0xdeadbeef\n"
        "li t2, 0x04564f34\n"

        "mulh  t3, t0, t1\n"
        "bne   t2, t3, 1f\n"

        // signed(0x80000000) * unsigned(0xffff8000) = 0x80004000
        "li t0, 0x80000000\n"
        "li t1, 0xffff8000\n"
        "li t2, 0x80004000\n"

        "mulhsu t3, t0, t1\n"
        "bne    t2, t3, 1f\n"

        // signed(0x0002fe7d) * unsigned(0xaaaaaaab) = 0x0001fefe
        "li t0, 0x0002fe7d\n"
        "li t1, 0xaaaaaaab\n"
        "li t2, 0x0001fefe\n"

        "mulhsu t3, t0, t1\n"
        "bne    t2, t3, 1f\n"

        // signed(0xffffffff) * unsigned(0xffffffff) = 0xffffffff
        "li t0, 0xffffffff\n"
        "li t1, 0xffffffff\n"
        "li t2, 0xffffffff\n"

        "mulhsu t3, t0, t1\n"
        "bne    t2, t3, 1f\n"

        "2:\n"  // no error
        "li %[ret], 0\n"
        "j  exit\n"

        "1:\n"  // error
        "li %[ret], 1\n"
        "j  exit\n"

        "exit:\n"

        : [ ret ] "=r"(ret)::"t0", "t1", "t2", "t3");

    return ret;
}
