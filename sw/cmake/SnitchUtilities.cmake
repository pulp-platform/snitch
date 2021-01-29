# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

# Locate the banshee simulator for test execution.
set(SNITCH_BANSHEE "banshee" CACHE PATH "Path to the banshee simulator for testing")
set(SNITCH_RUNTIME "snRuntime-banshee" CACHE PATH "Target name of the snRuntime flavor to link against")
message(STATUS "Check for Banshee")
execute_process(COMMAND ${SNITCH_BANSHEE} --version OUTPUT_VARIABLE SNITCH_BANSHEE_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
message(STATUS "Using simulator: ${SNITCH_BANSHEE} - version ${SNITCH_BANSHEE_VERSION}")

macro(add_snitch_library name)
    add_library(${ARGV})
    add_custom_command(
        TARGET ${name}
        POST_BUILD
        COMMAND ${CMAKE_OBJDUMP} -dhS $<TARGET_FILE:${name}> > $<TARGET_FILE:${name}>.s)
endmacro()

macro(add_snitch_executable name)
    add_executable(${ARGV})
    add_custom_command(
        TARGET ${name}
        POST_BUILD
        COMMAND ${CMAKE_OBJDUMP} -dhS $<TARGET_FILE:${name}> > $<TARGET_FILE:${name}>.s)
endmacro()

macro(add_snitch_test_executable name)
    add_snitch_executable(test-${name} ${ARGN})
    target_link_libraries(test-${name} ${SNITCH_RUNTIME})
endmacro()

macro(add_snitch_test_args executable_name test_name)
    add_test(NAME ${test_name} COMMAND ${SNITCH_BANSHEE} $<TARGET_FILE:test-${executable_name}> ${ARGN})
endmacro()

macro(add_snitch_test name)
    add_snitch_test_executable(${ARGV})
    add_snitch_test_args(${name} ${name}-core --base-hartid=3)
    add_snitch_test_args(${name} ${name}-cluster --base-hartid=3 --num-cores=8)
    add_snitch_test_args(${name} ${name}-system --base-hartid=3 --num-cores=8 --num-clusters=4)
endmacro()
