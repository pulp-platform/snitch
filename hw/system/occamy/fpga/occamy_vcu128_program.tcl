# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

# Parse arguments
if {$argc < 1} {
    error "usage: occamy_vcu_138_program.tcl [01|02]"
}

source occamy_vcu128_procs.tcl

switch [lindex $argv 0] {
   01 {
      target_01
   }
   02 {
      target_02
   }
}

occ_connect
occ_program_bit

if [file exists bootrom/bootrom-spl.tcl] {
  occ_flash_bootrom_spl
}

close_hw_manager
