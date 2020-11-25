# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

cmake_minimum_required(VERSION 3.10)
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/../cmake)

set(CMAKE_TOOLCHAIN_FILE toolchain-gcc) # select which toolchain to use
project(snRuntime LANGUAGES C ASM)

include(SnitchUtilities)

add_compile_options(-O3 -g -ffunction-sections)
include_directories(include)

# Common sources
set(sources
    src/barrier.c
    src/team.c
    src/printf.c
)

# Generic Runtime (requiring bootloader/OS)
add_snitch_library(snRuntime src/start.S ${sources})

# Bare Runtimes (with startup code)
add_snitch_library(snRuntime-banshee src/start_banshee.S src/start_banshee.c ${sources})
add_snitch_library(snRuntime-billywig src/start_billywig.S ${sources})
add_snitch_library(snRuntime-bowtruckle src/start_bowtruckle.S ${sources})
add_snitch_library(snRuntime-lethifold src/start_lethifold.S ${sources})
add_snitch_library(snRuntime-thestral src/start_thestral.S ${sources})

# Unit tests
enable_testing()
add_snitch_test(tls tests/tls.c)
add_snitch_test(simple tests/simple.c)
add_snitch_test(varargs_1 tests/varargs_1.c)
add_snitch_test(varargs_2 tests/varargs_2.c)
add_snitch_test(barrier tests/barrier.c)

add_snitch_test_executable(printf_simple tests/printf_simple.c)
add_snitch_test_executable(printf_fmtint tests/printf_fmtint.c)
add_snitch_test_args(printf_simple printf_simple --no-opt-llvm --base-hartid=3)
add_snitch_test_args(printf_fmtint printf_fmtint-core --no-opt-llvm --base-hartid=3)
add_snitch_test_args(printf_fmtint printf_fmtint-cluster --no-opt-llvm --base-hartid=3 --num-cores=8)
add_snitch_test_args(printf_fmtint printf_fmtint-system --no-opt-llvm --base-hartid=3 --num-cores=8 --num-clusters=4)

add_snitch_test_executable(team_global tests/team_global.c)
add_snitch_test_args(team_global team_global --base-hartid=3 --num-cores=4 --num-clusters=2)
