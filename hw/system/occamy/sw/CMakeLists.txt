# Copyright 2020 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

cmake_minimum_required(VERSION 3.13)

set(SNITCH_SOFTWARE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../../../../sw)
list(APPEND CMAKE_MODULE_PATH ${SNITCH_SOFTWARE_DIR}/cmake)
set(CMAKE_TOOLCHAIN_FILE toolchain-llvm)
set(SNITCH_RUNTIME snRuntime-cluster CACHE PATH "")
set(SNITCH_SIMULATOR ${CMAKE_CURRENT_SOURCE_DIR}/../bin/snitch_cluster.vlt CACHE PATH "")

project(snitch_cluster LANGUAGES C ASM)
include(SnitchUtilities)

add_compile_options(-O3 -g -ffunction-sections)

enable_testing()
add_subdirectory(${SNITCH_SOFTWARE_DIR}/snRuntime snRuntime)
add_subdirectory(${SNITCH_SOFTWARE_DIR}/snBLAS snBLAS)
add_subdirectory(${SNITCH_SOFTWARE_DIR}/benchmark benchmark)
add_subdirectory(${SNITCH_SOFTWARE_DIR}/applications applications)

