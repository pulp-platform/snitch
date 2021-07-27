/* Copyright 2020 ETH Zurich and University of Bologna. */
/* Solderpad Hardware License, Version 0.51, see LICENSE for details. */
/* SPDX-License-Identifier: SHL-0.51 */

OUTPUT_ARCH( "riscv" )
ENTRY(_start)

MEMORY
{
    L1 (rw)          : ORIGIN = 0x00000000, LENGTH = 128K
    DRAM (rwxa)      : ORIGIN = 0x80000000, LENGTH = 256M
}

SECTIONS
{
  /* The program code and other data goes into DRAM */
  .text :
  {
    . = ALIGN(4);
    *(.text.init)
    *(.text.startup)
    *(.text)
    *(.text*)
    *(.text)
    . = ALIGN(4);
    _etext = .;
  } >DRAM

  /* Constant data goes into BRAM */
  .rodata :
  {
    . = ALIGN(4);
    *(.rodata)
    *(.rodata*)
    . = ALIGN(4);
  } >DRAM

  /* used by the startup to initialize data */
  _sidata = LOADADDR(.data);
  
  /* Initialized data sections goes into L1, load LMA copy after code */
  .data : 
  {
    . = ALIGN(8);
    __global_pointer$ = . + (4K / 2);
    _sdata = .;
    *(.data .data.*)
    *(.sdata)
    *(.data*)
    . = ALIGN(4);
    _edata = .;
  } >L1 AT> DRAM

  /* Uninitialized data section */
  . = ALIGN(4);
  .bss :
  {
    /* This is used by the startup in order to initialize the .bss secion */
    _sbss = .;         /* define a global symbol at bss start */
    __bss_start__ = _sbss;
    *(.sbss .sbss*) /* sbss is for small bss for quicker addressing */
    *(.sbss2 .sbss2.* .gnu.linkonce.sb2.*)
    *(.bss .bss*)

    . = ALIGN(4);
    _ebss = .;         /* define a global symbol at bss end */
    __bss_end__ = _ebss;
  } >L1

  /* Thread Local Storage sections  */
  .tdata    :
  {
    PROVIDE_HIDDEN (__tdata_start = .);
    *(.tdata .tdata.* .gnu.linkonce.td.*)
    PROVIDE_HIDDEN (__tdata_end = .);
  }
  .tbss : 
  { 
    PROVIDE_HIDDEN (__tbss_start = .);
    *(.tbss .tbss.* .gnu.linkonce.tb.*) 
    *(.tcommon)
    PROVIDE_HIDDEN (__tbss_end = .);
  }
}
