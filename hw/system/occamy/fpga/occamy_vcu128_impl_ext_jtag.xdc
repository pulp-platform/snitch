# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Cyril Koenig <cykoenig@iis.ee.ethz.ch>

# This constraint file is written for VCU128 + FMC XM105 Debug Card and is included only when EXT_JTAG = 1

# 5 MHz max JTAG
create_clock -period 200 -name jtag_tck_i [get_pins occamy_vcu128_i/occamy/jtag_tck_i]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_pins jtag_tck_i_IBUF_inst/O]
set_property CLOCK_BUFFER_TYPE NONE [get_nets -of [get_pins jtag_tck_i_IBUF_inst/O]]
set_input_jitter jtag_tck_i 1.000

# JTAG clock is asynchronous with every other clocks.
set_clock_groups -asynchronous -group [get_clocks jtag_tck_i]

# Minimize routing delay
set_input_delay  -clock jtag_tck_i -clock_fall 5 [get_ports jtag_tdi_i]
set_input_delay  -clock jtag_tck_i -clock_fall 5 [get_ports jtag_tms_i]
set_output_delay -clock jtag_tck_i             5 [get_ports jtag_tdo_o]

set_max_delay -to   [get_ports { jtag_tdo_o }] 20
set_max_delay -from [get_ports { jtag_tms_i }] 20
set_max_delay -from [get_ports { jtag_tdi_i }] 20

# B23 - C14 (FMCP_HSPC_LA10_P) - J1.02 - VDD
set_property PACKAGE_PIN B23     [get_ports jtag_vdd_o]
set_property IOSTANDARD LVCMOS18 [get_ports jtag_vdd_o]
# A23 - C15 (FMCP_HSPC_LA10_N) - J1.04 - GND
set_property PACKAGE_PIN A23     [get_ports jtag_gnd_o]
set_property IOSTANDARD LVCMOS18 [get_ports jtag_gnd_o]
# B26 - H16 (FMCP_HSPC_LA11_P) - J1.06 - TCK
set_property PACKAGE_PIN B26     [get_ports jtag_tck_i]
set_property IOSTANDARD LVCMOS18 [get_ports jtag_tck_i]
# B25 - H17 (FMCP_HSPC_LA11_N) - J1.08 - TDO
set_property PACKAGE_PIN B25     [get_ports jtag_tdo_o]
set_property IOSTANDARD LVCMOS18 [get_ports jtag_tdo_o]
# J22 - G15 (FMCP_HSPC_LA12_P) - J1.10 - TDI
set_property PACKAGE_PIN J22     [get_ports jtag_tdi_i]
set_property IOSTANDARD LVCMOS18 [get_ports jtag_tdi_i]
# H22 - G16 (FMCP_HSPC_LA12_N) - J1.12 - TNS
set_property PACKAGE_PIN H22     [get_ports jtag_tms_i]
set_property IOSTANDARD LVCMOS18 [get_ports jtag_tms_i]
