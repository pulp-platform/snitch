# Copyright 2020 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

cmake_minimum_required(VERSION 3.13)

# Allow benchmark to be built as a standalone library.
if (CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/../cmake)
    set(CMAKE_TOOLCHAIN_FILE toolchain-llvm CACHE STRING "Toolchain to use")

    project(Applications LANGUAGES C ASM)
    include(SnitchUtilities)

    add_compile_options(-O3 -g -ffunction-sections)

    # Build the runtime.
    add_subdirectory(../snRuntime snRuntime)
endif()

macro(add_snitch_application_executable name)
    add_snitch_executable(${name} src/net_${name}.c data/data_${name}.h)
    add_custom_command(
        OUTPUT data/data_${name}.h
        COMMAND ./data_gen.py -c data/${name}_params.hjson
        WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
    )
    target_link_libraries(${name} kernels layers utils)
endmacro()

enable_testing()

if (CMAKE_C_COMPILER_ID STREQUAL "Clang")
    include_directories(include data src/layers src/kernels src/utils)
    include_directories(${SNRUNTIME_INCLUDE_DIRS})

    add_library(kernels src/kernels/batchnorm.c src/kernels/maxpool.c src/kernels/gemm.c src/kernels/conv2d.c)
    add_library(layers src/layers/batchnorm_layer.c
                src/layers/maxpool_layer.c
                src/layers/conv2d_layer.c
                src/layers/nnlinear_backend_baseline.c )
    add_library(utils src/utils/utils.c)

    target_link_libraries(kernels ${SNITCH_RUNTIME})
    target_link_libraries(layers ${SNITCH_RUNTIME} kernels utils)
    target_link_libraries(utils ${SNITCH_RUNTIME})

    add_snitch_application_executable(batchnorm)
    add_snitch_application_executable(maxpool)
    add_snitch_application_executable(conv2d)
    add_snitch_application_executable(gemm)
    add_snitch_application_executable(fusedconv)
    add_snitch_application_executable(nnlinear_baseline)

    set(SNITCH_TEST_PREFIX snApplications-)

    add_snitch_raw_test_args(batchnorm batchnorm --configuration ${CMAKE_CURRENT_SOURCE_DIR}/../banshee/config/occ_multi_cluster.yaml)
    add_snitch_raw_test_args(maxpool maxpool --configuration ${CMAKE_CURRENT_SOURCE_DIR}/../banshee/config/occ_multi_cluster.yaml)
    add_snitch_raw_test_args(conv2d conv2d --configuration ${CMAKE_CURRENT_SOURCE_DIR}/../banshee/config/occ_multi_cluster.yaml)
    add_snitch_raw_test_args(gemm gemm --configuration ${CMAKE_CURRENT_SOURCE_DIR}/../banshee/config/occ_multi_cluster.yaml)
    add_snitch_raw_test_args(fusedconv fusedconv --configuration ${CMAKE_CURRENT_SOURCE_DIR}/../banshee/config/occ_multi_cluster.yaml)
    add_snitch_raw_test_args(nnlinear_baseline nnlinear_baseline --configuration ${CMAKE_CURRENT_SOURCE_DIR}/../banshee/config/multi_cluster_simple.yaml)
    
endif()