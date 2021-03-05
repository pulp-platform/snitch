# Copyright 2020 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

SHELL := /bin/bash

###########################
###  INTEGRATION TESTS  ###
###########################

TESTS_DIR ?= tests/bin
TESTS_BLACKLIST += dma_simple matmul_ssr_frep
TESTS += $(patsubst $(TESTS_DIR)/%,%,$(wildcard $(TESTS_DIR)/*))
TEST_TARGETS = $(patsubst %,test-%,$(TESTS))
LOG_FAILED ?= /tmp/banshee_tests_failed
LOG_TOTAL ?= /tmp/banshee_tests_total

TARGET_DIR ?= $(shell cargo metadata --format-version 1 | sed -n 's/.*"target_directory":"\([^"]*\)".*/\1/p')
BANSHEE ?= $(TARGET_DIR)/debug/banshee

SNITCH_LOG ?= info

test: test-info $(TEST_TARGETS)
	@echo
	@echo -n "test result: `tput bold`"
	@if [ -s $(LOG_FAILED) ]; then \
		echo -n "`tput setaf 1`FAILED"; \
	else \
		echo -n "`tput setaf 2`PASSED"; \
	fi
	@echo "`tput sgr0`. $$(wc -l $(LOG_FAILED) | cut -f1 -d" ") tests failed, $$(wc -l $(LOG_TOTAL) | cut -f1 -d" ") executed."
	@[ ! -s $(LOG_FAILED) ]

.PHONY: test test-info

test-info:
	@cargo build
	@echo "# using TARGET_DIR = $(TARGET_DIR)"
	@echo "# using BANSHEE = $(BANSHEE)"
	@echo "# using TESTS = $(TESTS)"
	@echo
	@truncate -s0 $(LOG_FAILED)
	@truncate -s0 $(LOG_TOTAL)

define test_template
	@ \
	ARGS=$(patsubst $(TESTS_DIR)/%,$(TESTS_DIR)/../args/%,$(3)); \
	(cat $$ARGS 2>/dev/null || echo) | while read ARG; do \
		CMD=`echo $(2) $(3) $(4) $$ARG`; \
		LOGFILE=`mktemp`; \
		echo -n "$$CMD ... "; \
		if [ ! -z $(filter $(1),$(TESTS_BLACKLIST)) ]; then \
			echo "`tput setaf 3`ignored`tput sgr0`"; \
		elif ! env SNITCH_LOG=$(SNITCH_LOG) $$CMD &> $$LOGFILE; then \
			echo "`tput setaf 1`FAILED`tput sgr0`"; \
			cat $$LOGFILE; \
			echo $$CMD >>$(LOG_FAILED); \
		else \
			echo "`tput setaf 2`passed`tput sgr0`"; \
		fi; \
		echo $$CMD >>$(LOG_TOTAL); \
	done
endef

test-%: $(TESTS_DIR)/% $(TESTS_DIR)/../trace/%.txt test-info
	$(call test_template,$*,$(BANSHEE) $(TEST_ARGS) --trace, $<, | diff - $(word 2,$^))

test-%: $(TESTS_DIR)/% test-info
	$(call test_template,$*,$(BANSHEE) $(TEST_ARGS), $<,)

debug-%: $(TESTS_DIR)/% test-info
	gdb --args $(BANSHEE) $<
