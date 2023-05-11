# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Luca Colagrande <colluca@iis.ee.ethz.ch>

.PHONY: all clean

all:
	$(MAKE) -C host TARGET=partial-build
	$(MAKE) -C device
	$(MAKE) -C host TARGET=finalize-build

clean:
	$(MAKE) -C device TARGET=clean
	$(MAKE) -C host TARGET=clean
