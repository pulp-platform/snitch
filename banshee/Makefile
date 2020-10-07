# Copyright 2020 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

RISCV_OPCODES ?= ../sw/vendor/riscv-opcodes
PARSE_OPCODES ?= $(RISCV_OPCODES)/parse-opcodes
OPCODES := opcodes opcodes-pseudo
OPCODES_PATH := $(patsubst %, $(RISCV_OPCODES)/%, $(OPCODES))

src/riscv.rs: $(OPCODES_PATH) $(PARSE_OPCODES)
	echo "// Copyright 2020 ETH Zurich and University of Bologna." > $@
	echo "// Licensed under the Apache License, Version 2.0, see LICENSE for details." >> $@
	echo "// SPDX-License-Identifier: Apache-2.0" >> $@
	echo >> $@
	cat $(OPCODES_PATH) | $(PARSE_OPCODES) -rust >> $@
	rustfmt $@
