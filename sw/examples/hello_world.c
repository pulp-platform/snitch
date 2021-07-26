// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "snrt.h"
#include "printf.h"

int main(int argc, char** argv) {
	(void)argc;
	(void)argv;
	printf("Hello World!\n");
	return 0x42;
}
