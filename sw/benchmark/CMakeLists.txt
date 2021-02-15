# Copyright 2020 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

cmake_minimum_required(VERSION 3.13)

# Allow benchmark to be built as a standalone library.
if (CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/../cmake)
    set(CMAKE_TOOLCHAIN_FILE toolchain-gcc CACHE STRING "Toolchain to use")

    project(Benchmarks LANGUAGES C ASM)
    include(SnitchUtilities)

    add_compile_options(-O3 -g -ffunction-sections)

    # Build the runtime.
    add_subdirectory(../snRuntime snRuntime)
endif()

include_directories(include)
include_directories(${SNRUNTIME_INCLUDE_DIRS})

add_library(
    benchmark
    src/benchmark.c
)

add_library(benchmark-matmul src/matmul/matmul.c src/matmul/data.S)
add_snitch_executable(benchmark-matmul-baseline src/matmul/main_baseline.c)
add_snitch_executable(benchmark-matmul-ssr src/matmul/main_ssr.c)
add_snitch_executable(benchmark-matmul-ssr_frep src/matmul/main_ssr_frep.c)
add_snitch_executable(benchmark-matmul-all src/matmul/main_all.c)

target_link_libraries(benchmark-matmul benchmark ${SNITCH_RUNTIME})
target_link_libraries(benchmark-matmul-baseline benchmark-matmul)
target_link_libraries(benchmark-matmul-ssr benchmark-matmul)
target_link_libraries(benchmark-matmul-ssr_frep benchmark-matmul)
target_link_libraries(benchmark-matmul-all benchmark-matmul)
