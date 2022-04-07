# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

# Locate the banshee simulator for test execution.
set(SNITCH_BANSHEE "banshee" CACHE PATH "Path to the banshee simulator for testing")
set(BANSHEE_TIMEOUT "360" CACHE STRING "Timeout when running tests on banshee")
set(RUN_BANSHEE_ARGS "--num-cores=9" CACHE PATH "Arguments passed to the banshee sim for the run-banshee target")
set(SNITCH_RUNTIME "snRuntime-banshee" CACHE STRING "Target name of the snRuntime flavor to link against")
set(SNITCH_SIMULATOR "" CACHE PATH "Command to run a binary in an RTL simulation")
set(SIMULATOR_TIMEOUT "1800" CACHE STRING "Timeout when running tests on RTL simulation")
set(SPIKE_DASM "spike-dasm" CACHE PATH "Path to the spike-dasm for generating traces")
set(RUNTIME_TRACE OFF CACHE BOOL "Enable runtime trace output")
set(SNITCH_TEST_PREFIX "")
message(STATUS "Check for Banshee")
execute_process(COMMAND ${SNITCH_BANSHEE} --version OUTPUT_VARIABLE SNITCH_BANSHEE_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
message(STATUS "Using Banshee simulator: ${SNITCH_BANSHEE} - version ${SNITCH_BANSHEE_VERSION}")
if (SNITCH_SIMULATOR)
    message(STATUS "Using RTL simulator: ${SNITCH_SIMULATOR}")
endif()
message(STATUS "Using runtime: ${SNITCH_RUNTIME}")

# Toolchain to use
set(CMAKE_TOOLCHAIN_FILE toolchain-gcc CACHE STRING "Toolchain to use")

# Select to build the tests
set(BUILD_TESTS OFF CACHE BOOL "Build test executables")

macro(add_snitch_library name)
    add_library(${ARGV})
    add_custom_command(
        TARGET ${name}
        POST_BUILD
        COMMAND ${CMAKE_OBJDUMP} -dhS $<TARGET_FILE:${name}> > $<TARGET_FILE:${name}>.s)
endmacro()

macro(add_snitch_executable name)
    add_executable(${ARGV})
    target_link_libraries(${name} ${SNITCH_RUNTIME})
    target_link_options(${name} PRIVATE "SHELL:-T ${LINKER_SCRIPT}")
    add_custom_command(
        TARGET ${name}
        POST_BUILD
        COMMAND ${CMAKE_OBJDUMP} -dhS $<TARGET_FILE:${name}> > $<TARGET_FILE:${name}>.s)
    # Run target for banshee
    if (SNITCH_RUNTIME STREQUAL "snRuntime-banshee")
        add_custom_target( run-banshee-${name}
            COMMAND ${SNITCH_BANSHEE} --no-opt-llvm --no-opt-jit ${RUN_BANSHEE_ARGS} --configuration ${CMAKE_CURRENT_SOURCE_DIR}/../banshee/config/snitch_cluster.yaml --trace $<TARGET_FILE:${name}> > $<TARGET_FILE:${name}>.trace
            COMMAND cat $<TARGET_FILE:${name}>.trace | ${SPIKE_DASM} > $<TARGET_FILE:${name}>.trace.txt
            COMMAND awk -F\" \" '{print>\"${name}\"$$3\".txt\"}' $<TARGET_FILE:${name}>.trace.txt
            DEPENDS $<TARGET_FILE:${name}>)
    endif()
    # Run target for RTL simulator
    if (SNITCH_SIMULATOR AND SNITCH_RUNTIME STREQUAL "snRuntime-cluster")
        add_custom_target( run-rtl-${name}
            COMMAND ${SNITCH_SIMULATOR} $<TARGET_FILE:${name}>
            COMMAND for f in logs/trace_hart_*.dasm\; do ${SPIKE_DASM} < $$f | ${PYTHON} ${SNRUNTIME_SRC_DIR}/../../util/gen_trace.py > $$\(echo $$f | sed 's/\\.dasm/\\.txt/'\)\; done
            DEPENDS $<TARGET_FILE:${name}>)
    endif()
endmacro()

macro(add_snitch_test_executable name)
    if (BUILD_TESTS)
        add_snitch_executable(test-${SNITCH_TEST_PREFIX}${name} ${ARGN})
    endif()
endmacro()

macro(add_snitch_raw_test_args test_name target_name)
    if (SNITCH_RUNTIME STREQUAL "snRuntime-banshee" AND BUILD_TESTS)
        add_test(NAME ${SNITCH_TEST_PREFIX}${test_name} COMMAND ${SNITCH_BANSHEE} $<TARGET_FILE:${target_name}> ${ARGN})
        set_property(TEST ${SNITCH_TEST_PREFIX}${test_name}
        PROPERTY LABELS ${SNITCH_TEST_PREFIX})
        set_tests_properties(${SNITCH_TEST_PREFIX}${test_name} PROPERTIES TIMEOUT ${BANSHEE_TIMEOUT})
    endif()
endmacro()

macro(add_snitch_test_args executable_name test_name)
    if (SNITCH_RUNTIME STREQUAL "snRuntime-banshee")
        add_snitch_raw_test_args(${test_name} test-${SNITCH_TEST_PREFIX}${executable_name} ${ARGN})
    endif()
endmacro()

macro(add_snitch_raw_test_rtl test_name target_name)
    if ((NOT SNITCH_RUNTIME STREQUAL "snRuntime-banshee") AND BUILD_TESTS)
        add_test(NAME ${SNITCH_TEST_PREFIX}rtl-${test_name} COMMAND ${SNITCH_SIMULATOR} $<TARGET_FILE:${target_name}>)
        set_property(TEST ${SNITCH_TEST_PREFIX}rtl-${test_name}
        PROPERTY LABELS ${SNITCH_TEST_PREFIX})
        set_tests_properties(${SNITCH_TEST_PREFIX}rtl-${test_name} PROPERTIES TIMEOUT ${SIMULATOR_TIMEOUT})
    endif()
endmacro()

macro(add_snitch_test_rtl name)
    if (NOT SNITCH_RUNTIME STREQUAL "snRuntime-banshee")
        add_snitch_raw_test_rtl(${SNITCH_TEST_PREFIX}rtl-${name} test-${SNITCH_TEST_PREFIX}${name})
    endif()
endmacro()

macro(add_snitch_test name)
    if (BUILD_TESTS)
        message(STATUS "Adding test: ${name}")
        add_snitch_test_executable(${ARGV})
        if (SNITCH_RUNTIME STREQUAL "snRuntime-banshee")
            add_snitch_test_args(${name} ${name}-snitch --configuration ${CMAKE_CURRENT_SOURCE_DIR}/../banshee/config/snitch_cluster.yaml)
        elseif (SNITCH_SIMULATOR)
            add_snitch_test_rtl(${name})
        endif()
    endif()
endmacro()
