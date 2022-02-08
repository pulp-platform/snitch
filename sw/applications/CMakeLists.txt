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

add_custom_target(application-update-data
    COMMAND python ${CMAKE_CURRENT_LIST_DIR}/data_gen.py -c ${CMAKE_CURRENT_LIST_DIR}/data/fusedconv_params.hjson
    COMMAND python ${CMAKE_CURRENT_LIST_DIR}/data_gen.py -c ${CMAKE_CURRENT_LIST_DIR}/data/batchnorm_params.hjson
    COMMAND python ${CMAKE_CURRENT_LIST_DIR}/data_gen.py -c ${CMAKE_CURRENT_LIST_DIR}/data/conv2d_params.hjson
    COMMAND python ${CMAKE_CURRENT_LIST_DIR}/data_gen.py -c ${CMAKE_CURRENT_LIST_DIR}/data/gemm_params.hjson
    COMMAND python ${CMAKE_CURRENT_LIST_DIR}/data_gen.py -c ${CMAKE_CURRENT_LIST_DIR}/data/maxpool_params.hjson
    COMMAND clang-format -style=file -i ${CMAKE_CURRENT_LIST_DIR}/data/data_fusedconv.h
    COMMAND clang-format -style=file -i ${CMAKE_CURRENT_LIST_DIR}/data/data_batchnorm.h
    COMMAND clang-format -style=file -i ${CMAKE_CURRENT_LIST_DIR}/data/data_conv2d.h
    COMMAND clang-format -style=file -i ${CMAKE_CURRENT_LIST_DIR}/data/data_gemm.h
    COMMAND clang-format -style=file -i ${CMAKE_CURRENT_LIST_DIR}/data/data_maxpool.h
)



if (CMAKE_C_COMPILER_ID STREQUAL "Clang")
    include_directories(include data src/layers src/kernels src/utils)
    include_directories(${SNRUNTIME_INCLUDE_DIRS})

    add_library(kernels src/kernels/batchnorm.c src/kernels/maxpool.c src/kernels/gemm.c src/kernels/conv2d.c)
    add_library(layers src/layers/batchnorm_layer.c src/layers/maxpool_layer.c src/layers/conv2d_layer.c)
    add_library(utils src/utils/utils.c)

    target_link_libraries(kernels ${SNITCH_RUNTIME})
    target_link_libraries(layers ${SNITCH_RUNTIME} kernels utils)
    target_link_libraries(utils ${SNITCH_RUNTIME})

    add_snitch_executable(net-batchnorm src/net_batchnorm.c)
    target_link_libraries(net-batchnorm kernels layers utils)

    add_snitch_executable(net-maxpool src/net_maxpool.c)
    target_link_libraries(net-maxpool kernels layers utils)

    add_snitch_executable(net-conv2d src/net_conv2d.c)
    target_link_libraries(net-conv2d kernels layers utils)

    add_snitch_executable(net-gemm src/net_gemm.c)
    target_link_libraries(net-gemm kernels utils)

    add_snitch_executable(fusedconv src/fusedconv.c)
    target_link_libraries(fusedconv kernels utils)
endif()
