# Copyright 2020 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

cmake_minimum_required(VERSION 3.13)

# Allow snRuntime to be built as a standalone library.
if (CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/../cmake)
    set(CMAKE_TOOLCHAIN_FILE toolchain-gcc CACHE STRING "Toolchain to use")

    project(snBLAS LANGUAGES C ASM)
    include(SnitchUtilities)

    add_compile_options(-O3 -g -ffunction-sections)

    # Build the runtime.
    add_subdirectory(../snRuntime snRuntime)
else()
    # Export package information to includer.
    set(SNBLAS_DIR ${CMAKE_CURRENT_BINARY_DIR} PARENT_SCOPE)
    set(SNBLAS_SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR} PARENT_SCOPE)
    set(SNBLAS_INCLUDE_DIRS
        ${CMAKE_CURRENT_SOURCE_DIR}/include
        PARENT_SCOPE)
endif()

include_directories(include)
include_directories(${SNRUNTIME_INCLUDE_DIRS})

add_snitch_library(snBLAS src/axpy.c src/knn.c)

# Tests
enable_testing()
set(SNITCH_TEST_PREFIX snBLAS-)
link_libraries(snBLAS)
add_snitch_test_executable(simple tests/simple.c)
add_snitch_test_args(simple simple --no-opt-llvm)
