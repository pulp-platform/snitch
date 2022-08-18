# Copyright 2022 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

# Author: Paul Scheffler <paulsc@iis.ee.ethz.ch>

# Import this GNU Make fragment in your project's makefile to regenerate and
# reconfigure these IPs. You can modify the original RTL, configuration, and
# templates from your project without entering this dependency repo by adding
# build targets for them. To build the IPs, `make otp`.

# You may need to adapt these environment variables to your configuration.
BENDER   ?= bender
REGTOOL  ?= $(shell $(BENDER) path register_interface)/vendor/lowrisc_opentitan/util/regtool.py
PLICOPT  ?= -s 32 -t 1 -p 7

OTPROOT  ?= $(shell $(BENDER) path opentitan_peripherals)
PLICTOOL ?= $(OTPROOT)/src/rv_plic/util/reg_rv_plic.py

_otp: otp_rv_plic
_otp: otp_gpio
_otp: otp_i2c
_otp: otp_spi_host

$(OTPROOT)/src/rv_plic/rtl/rv_plic.sv: $(OTPROOT)/src/rv_plic/data/rv_plic.sv.tpl
	$(PLICTOOL) $(PLICOPT) $< > $@

$(OTPROOT)/src/rv_plic/data/rv_plic.hjson: $(OTPROOT)/src/rv_plic/data/rv_plic.hjson.tpl
	$(PLICTOOL) $(PLICOPT) $< > $@

otp_rv_plic: $(OTPROOT)/src/rv_plic/data/rv_plic.hjson $(OTPROOT)/src/rv_plic/rtl/rv_plic.sv $(REGTOOL)
	$(REGTOOL) -r -t $(OTPROOT)/src/rv_plic/rtl $<

otp_gpio: $(OTPROOT)/src/gpio/data/gpio.hjson $(REGTOOL)
	$(REGTOOL) -r -t $(OTPROOT)/src/gpio/rtl $<

otp_i2c: $(OTPROOT)/src/i2c/data/i2c.hjson $(REGTOOL)
	$(REGTOOL) -r -t $(OTPROOT)/src/i2c/rtl $<

otp_spi_host: $(OTPROOT)/src/spi_host/data/spi_host.hjson $(REGTOOL)
	$(REGTOOL) -r -t $(OTPROOT)/src/spi_host/rtl $<

otp:
	@echo '[PULP] Generate OpenTitan peripherals (PLICOPT=`$(PLICOPT)`)'
	@$(MAKE) -B _otp
