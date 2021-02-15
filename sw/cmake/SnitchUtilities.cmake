# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

# Locate the banshee simulator for test execution.
set(SNITCH_BANSHEE "banshee" CACHE PATH "Path to the banshee simulator for testing")
set(SNITCH_RUNTIME "snRuntime-banshee" CACHE PATH "Target name of the snRuntime flavor to link against")
set(SNITCH_SIMULATOR "" CACHE PATH "Command to run a binary in an RTL simulation")
set(SNITCH_TEST_PREFIX "")
message(STATUS "Check for Banshee")
execute_process(COMMAND ${SNITCH_BANSHEE} --version OUTPUT_VARIABLE SNITCH_BANSHEE_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
message(STATUS "Using simulator: ${SNITCH_BANSHEE} - version ${SNITCH_BANSHEE_VERSION}")
if (SNITCH_SIMULATOR)
    message(STATUS "Using RTL simulator: ${SNITCH_SIMULATOR}")
endif()

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
    add_custom_command(
        TARGET ${name}
        POST_BUILD
        COMMAND ${CMAKE_OBJDUMP} -dhS $<TARGET_FILE:${name}> > $<TARGET_FILE:${name}>.s)
endmacro()

macro(add_snitch_test_executable name)
    add_snitch_executable(test-${SNITCH_TEST_PREFIX}${name} ${ARGN})
endmacro()

macro(add_snitch_test_args executable_name test_name)
    if (SNITCH_RUNTIME STREQUAL "snRuntime-banshee")
        add_test(NAME ${SNITCH_TEST_PREFIX}${test_name} COMMAND ${SNITCH_BANSHEE} $<TARGET_FILE:test-${SNITCH_TEST_PREFIX}${executable_name}> ${ARGN})
    endif()
endmacro()

macro(add_snitch_test_rtl name)
    if (NOT SNITCH_RUNTIME STREQUAL "snRuntime-banshee")
        add_test(NAME ${SNITCH_TEST_PREFIX}rtl-${name} COMMAND ${SNITCH_SIMULATOR} $<TARGET_FILE:test-${SNITCH_TEST_PREFIX}${name}>)
    endif()
endmacro()

macro(add_snitch_test name)
    add_snitch_test_executable(${ARGV})
    if (SNITCH_RUNTIME STREQUAL "snRuntime-banshee")
        add_snitch_test_args(${name} ${name}-core --base-hartid=3)
        add_snitch_test_args(${name} ${name}-cluster --base-hartid=3 --num-cores=8)
        add_snitch_test_args(${name} ${name}-system --base-hartid=3 --num-cores=8 --num-clusters=4)
    elseif (SNITCH_SIMULATOR)
        add_snitch_test_rtl(${name})
    endif()
endmacro()
