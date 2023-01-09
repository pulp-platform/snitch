# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

set(SNITCH_LLVM_BIN /home/paulsc/dev/llvm-ssr/llvm-iis/install/bin/)

set(CMAKE_C_COMPILER "${SNITCH_LLVM_BIN}/clang")
set(CMAKE_CXX_COMPILER "${SNITCH_LLVM_BIN}/clang++")
set(CMAKE_OBJCOPY "${SNITCH_LLVM_BIN}/llvm-objcopy")
set(CMAKE_OBJDUMP "${SNITCH_LLVM_BIN}/llvm-objdump" --mcpu=snitch)
set(CMAKE_AR "${SNITCH_LLVM_BIN}/llvm-ar")
set(CMAKE_STRIP "${SNITCH_LLVM_BIN}/llvm-strip")
set(CMAKE_RANLIB "${SNITCH_LLVM_BIN}/llvm-ranlib")

# LTO
set(CMAKE_INTERPROCEDURAL_OPTIMIZATION true)
set(CMAKE_C_COMPILER_AR "${CMAKE_AR}")
set(CMAKE_CXX_COMPILER_AR "${CMAKE_AR}")
set(CMAKE_C_COMPILER_RANLIB "${CMAKE_RANLIB}")
set(CMAKE_CXX_COMPILER_RANLIB "${CMAKE_RANLIB}")

##
## Compile options
##
add_compile_options(-mcpu=snitch -mcmodel=medany -ffast-math -fno-builtin-printf -fno-common)

# TODO: Add march manually due to Zfh arch issue
add_compile_options(-march=rv32imafd_zfh_xfrep_xssr_xdma_xfalthalf_xfquarter_xfaltquarter_xfvecsingle_xfvechalf_xfvecalthalf_xfvecquarter_xfvecaltquarter_xfauxhalf_xfauxalthalf_xfauxquarter_xfauxaltquarter_xfauxvecsingle_xfauxvechalf_xfauxvecalthalf_xfauxvecquarter_xfauxvecaltquarter_xfexpauxvechalf_xfexpauxvecalthalf_xfexpauxvecquarter_xfexpauxvecaltquarter)

add_compile_options(-ffunction-sections)
add_compile_options(-Wextra)
add_compile_options(-static)
# For SSR register merge we need to disable the scheduler
add_compile_options(-mllvm -enable-misched=false)
# LLD doesn't support relaxation for RISC-V yet
add_compile_options(-mno-relax)
add_compile_options(-fopenmp)
# For smallfloat we need experimental extensions enabled (Zfh)
add_compile_options(-menable-experimental-extensions)

##
## Link options
##

add_link_options(-mcpu=snitch -nostartfiles -fuse-ld=lld -Wl,--image-base=0x80000000)
add_link_options(-static)
# LLD defaults to -z relro which we don't want in a static ELF
add_link_options(-Wl,-z,norelro)
add_link_options(-Wl,--gc-sections)
add_link_options(-Wl,--no-relax)
# add_link_options(-Wl,--verbose)

# Libraries
link_libraries(-lm)

# Add preprocessor definition to indicate LLD is used
add_compile_definitions(__LINK_LLD)
add_compile_definitions(__TOOLCHAIN_LLVM__)
