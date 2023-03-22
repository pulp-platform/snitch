// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "lto_a.h"

static signed int i = 0;

void foo2(void) { i = -1; }

static int foo3() {
    foo4();
    return 10;
}

int foo1(void) {
    int data = 0;

    if (i < 0) data = foo3();

    data = data + 42;
    return data;
}
