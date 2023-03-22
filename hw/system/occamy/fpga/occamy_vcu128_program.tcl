# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

# Parse arguments
if {$argc < 2} {
    error "usage: occamy_vcu_128_program.tcl [01|02] [uboot_offset] [uboot_itb]"
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

set mcs_file "flash.mcs"
set flash_offset [lindex $argv 1]
set flash_file [lindex $argv 2]

occ_connect

#occ_flash_spi $mcs_file $flash_offset $flash_file

occ_program_bit

if [file exists bootrom/bootrom-spl.tcl] {
  occ_flash_bootrom_spl
}

close_hw_manager
