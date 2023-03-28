// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// Simply returns a return code different from 0.
// Should be used as a test to check that the simulator or whoever
// is running the program actually captures an error when it occurs.

int main() { return 1; }
