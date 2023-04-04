# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

proc target_01 {} {
  global occ_hw_server
  global occ_target_serial
  global occ_hw_device
  global occ_bit_stem
  set occ_hw_server bordcomputer:3231
  set occ_target_serial 091847100576A
  set occ_hw_device xcvu37p_0
  set occ_bit_stem occamy_vcu128/occamy_vcu128.runs/impl_1/occamy_vcu128_wrapper
}

proc target_02 {} {
  global occ_hw_server
  global occ_target_serial
  global occ_hw_device
  global occ_bit_stem
  set occ_hw_server bordcomputer:3232
  set occ_target_serial 091847100638A
  set occ_hw_device xcvu37p_0
  set occ_bit_stem occamy_vcu128/occamy_vcu128.runs/impl_1/occamy_vcu128_wrapper
}

proc occ_connect { } {
    global occ_hw_server
    global occ_target_serial
    global occ_hw_device
    open_hw_manager
    connect_hw_server -url ${occ_hw_server} -allow_non_jtag
    current_hw_target [get_hw_targets */xilinx_tcf/Xilinx/${occ_target_serial}]
    set_property PARAM.FREQUENCY 15000000 [get_hw_targets */xilinx_tcf/Xilinx/${occ_target_serial}]
    open_hw_target
    current_hw_device [get_hw_devices ${occ_hw_device}]
    refresh_hw_device -update_hw_probes false [lindex [get_hw_devices ${occ_hw_device}] 0]
}

proc occ_refresh {} {
  global occ_bit_stem
  global occ_hw_device
  set_property PROBES.FILE "${occ_bit_stem}.ltx" [get_hw_devices ${occ_hw_device}]
  set_property FULL_PROBES.FILE "${occ_bit_stem}.ltx" [get_hw_devices ${occ_hw_device}]
  set_property PROGRAM.FILE "${occ_bit_stem}.bit" [get_hw_devices ${occ_hw_device}]
  refresh_hw_device [lindex [get_hw_devices ${occ_hw_device}] 0]
  display_hw_ila_data
}

proc occ_print_vios {} {
    global occ_hw_device
    puts "--------------------"
    set vios [get_hw_vios -of_objects [get_hw_devices ${occ_hw_device}]]
    puts "Done programming device, found [llength $vios] VIOS: "
    foreach vio $vios {
        puts "- $vio : [get_hw_probes * -of_objects $vio]"
    }
    puts "--------------------"
}

proc occ_program { bit_stem } {
    global occ_hw_device
    puts "Programming ${bit_stem}.bit"
    set_property PROBES.FILE "${bit_stem}.ltx" [get_hw_devices ${occ_hw_device}]
    set_property FULL_PROBES.FILE "${bit_stem}.ltx" [get_hw_devices ${occ_hw_device}]
    set_property PROGRAM.FILE "${bit_stem}.bit" [get_hw_devices ${occ_hw_device}]
    current_hw_device [get_hw_devices  ${occ_hw_device}]
    program_hw_devices [get_hw_devices ${occ_hw_device}]
    refresh_hw_device [lindex [get_hw_devices ${occ_hw_device}] 0]
}

proc occ_program_bit { } {
    global occ_bit_stem
    occ_program $occ_bit_stem
    occ_print_vios
}

proc occ_write_vio {regexp_vio regexp_probe val} {
    global occ_hw_device
    puts "\[occ_write_vio $regexp_vio $regexp_probe\]"
    set vio_sys [get_hw_vios -of_objects [get_hw_devices ${occ_hw_device}] -regexp $regexp_vio]
    set_property OUTPUT_VALUE $val [get_hw_probes -of_objects $vio_sys -regexp $regexp_probe]
    commit_hw_vio [get_hw_probes -of_objects $vio_sys -regexp $regexp_probe]
}

proc occ_flash_bootrom { } {
    global occ_hw_device
    # Reset peripherals and CPU
    occ_write_vio "hw_vio_1" ".*rst.*" 1
    after 100
    # Wake up peripherals to write bootrom
    occ_write_vio "hw_vio_1" ".*glbl_rst.*" 0
    after 100
    # Overwrite bootrom
    refresh_hw_device [lindex [get_hw_devices ${occ_hw_device}] 0]
    source bootrom/bootrom.tcl
    after 100
    # Wake up CPU
    occ_write_vio "hw_vio_1" ".*rst.*" 0
}

proc occ_flash_bootrom_spl { } {
    global occ_hw_device
    # Reset peripherals and CPU
    occ_write_vio "hw_vio_1" ".*rst.*" 1
    after 100
    # Wake up peripherals to write bootrom
    occ_write_vio "hw_vio_1" ".*glbl_rst.*" 0
    after 100
    # Overwrite bootrom
    refresh_hw_device [lindex [get_hw_devices ${occ_hw_device}] 0]
    source bootrom/bootrom-spl.tcl
    after 100
    # Wake up CPU
    occ_write_vio "hw_vio_1" ".*rst.*" 0
}

proc occ_flash_spi { mcs_file flash_offset flash_file } {
    global occ_hw_device
    puts "Writing config mem file for ${flash_offset} ${flash_file}"
    # Create flash configuration file
    write_cfgmem -force -format mcs -size 256 -interface SPIx4 \
        -loaddata "up ${flash_offset} ${flash_file}" \
        -checksum \
        -file ${mcs_file}
    # Add the SPI flash as configuration memory
    set hw_device [get_hw_devices ${occ_hw_device}]
    create_hw_cfgmem -hw_device $hw_device [lindex [get_cfgmem_parts {mt25qu02g-spi-x1_x2_x4}] 0]
    set hw_cfgmem [get_property PROGRAM.HW_CFGMEM $hw_device]
    set_property PROGRAM.ADDRESS_RANGE  {use_file} $hw_cfgmem
    set_property PROGRAM.FILES [list $mcs_file ] $hw_cfgmem
    set_property PROGRAM.PRM_FILE {} $hw_cfgmem
    set_property PROGRAM.UNUSED_PIN_TERMINATION {pull-none} $hw_cfgmem
    set_property PROGRAM.BLANK_CHECK  0 $hw_cfgmem
    set_property PROGRAM.ERASE  1 $hw_cfgmem
    set_property PROGRAM.CFG_PROGRAM  1 $hw_cfgmem
    set_property PROGRAM.VERIFY  1 $hw_cfgmem
    set_property PROGRAM.CHECKSUM  0 $hw_cfgmem
    # Create bitstream to access SPI flash
    puts "Creating bitstream to access SPI flash"
    create_hw_bitstream -hw_device $hw_device [get_property PROGRAM.HW_CFGMEM_BITFILE $hw_device]; 
    program_hw_devices $hw_device; 
    refresh_hw_device $hw_device;
    # Program SPI flash
    puts "Programing SPI flash"
    program_hw_cfgmem -hw_cfgmem $hw_cfgmem
}