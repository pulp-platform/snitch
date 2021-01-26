// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

__thread int a = 42;
__thread int b = 0;
__thread int c = 99;

int main() { return (a != 42) + (b != 0) + (c != 99); }
