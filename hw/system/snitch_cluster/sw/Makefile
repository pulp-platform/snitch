# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Luca Colagrande <colluca@iis.ee.ethz.ch>

# Add user applications to APPS variable
APPS  = apps/nop

TARGET ?= all

SUBDIRS  = runtime
SUBDIRS += $(APPS)

.PHONY: all $(SUBDIRS)

all: $(SUBDIRS)

# Explicit dependency of apps on runtime
$(APPS): runtime

$(SUBDIRS):
	$(MAKE) -C $@ $(TARGET)
