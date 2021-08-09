# Copyright 2020 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

cmake_minimum_required(VERSION 3.13)

# Read SnitchUtilities
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/../cmake)
include(SnitchUtilities)

# Link simulator
set(SNITCH_SIMULATOR ../../../hw/system/snitch_cluster/bin/snitch_cluster.vlt)

# Create project
project(Examples LANGUAGES C ASM)

# Compile options
add_compile_options(-O3 -g -ffunction-sections)

# Build the runtime
add_subdirectory(../snRuntime snRuntime)

# Includes
include_directories(${SNRUNTIME_INCLUDE_DIRS})

# Programs
add_snitch_executable(hello_world hello_world.c)
add_snitch_executable(memory memory.c)

