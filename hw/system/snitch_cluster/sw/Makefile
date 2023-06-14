# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Luca Colagrande <colluca@iis.ee.ethz.ch>

APPS := $(shell cat apps.list)

TARGET ?= all
SELECT_RUNTIME ?= rtl

ifeq ($(SELECT_RUNTIME), banshee)
RUNTIME = runtime/banshee
else
RUNTIME = runtime/rtl
endif

SUBDIRS  = runtime/banshee
SUBDIRS += runtime/rtl
SUBDIRS += $(APPS)

.PHONY: all $(SUBDIRS)

all: $(SUBDIRS)

# Explicit dependency of apps on runtime
$(APPS): $(RUNTIME)

$(SUBDIRS):
	$(MAKE) -C $@ $(TARGET)
