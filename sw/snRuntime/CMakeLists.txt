# Copyright 2020 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

cmake_minimum_required(VERSION 3.13)

# Allow snRuntime to be built as a standalone library.
if (CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/../cmake)
    set(CMAKE_TOOLCHAIN_FILE toolchain-gcc CACHE STRING "Toolchain to use")

    project(snRuntime LANGUAGES C ASM)
    include(SnitchUtilities)

    add_compile_options(-O3 -g -ffunction-sections)
else()
    # Export package information to includer.
    set(SNRUNTIME_DIR ${CMAKE_CURRENT_BINARY_DIR} PARENT_SCOPE)
    set(SNRUNTIME_INCLUDE_DIRS ${CMAKE_CURRENT_SOURCE_DIR}/include PARENT_SCOPE)
endif()

include_directories(include)

# Common sources
set(sources
    src/barrier.c
    src/team.c
    src/printf.c
    src/memcpy.c
)

# Generic Runtime (requiring bootloader/OS)
add_snitch_library(snRuntime src/start.S ${sources})

# Bare Runtimes (with startup code)
add_snitch_library(snRuntime-banshee src/start_banshee.S src/start_banshee.c ${sources})
add_snitch_library(snRuntime-cluster src/start_cluster.S src/start_cluster.c ${sources})
add_snitch_library(snRuntime-billywig src/start_billywig.S ${sources})
add_snitch_library(snRuntime-bowtruckle src/start_bowtruckle.S ${sources})
add_snitch_library(snRuntime-lethifold src/start_lethifold.S ${sources})
add_snitch_library(snRuntime-thestral src/start_thestral.S ${sources})

# Tests
enable_testing()
set(SNITCH_TEST_PREFIX snRuntime-)
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
