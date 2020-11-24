# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

# Locate the banshee simulator for test execution.
set(SNITCH_BANSHEE "banshee" CACHE PATH "Path to the banshee simulator for testing")
message(STATUS "Check for Banshee")
execute_process(COMMAND ${SNITCH_BANSHEE} --version OUTPUT_VARIABLE SNITCH_BANSHEE_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
message(STATUS "Using simulator: ${SNITCH_BANSHEE} - version ${SNITCH_BANSHEE_VERSION}")

macro(add_snitch_library name)
    add_library(${ARGV})
    add_custom_command(
        TARGET ${name}
        POST_BUILD
        COMMAND ${CMAKE_OBJDUMP} -dhS "--source-comment=\# " $<TARGET_FILE:${name}> > $<TARGET_FILE:${name}>.s)
endmacro()

macro(add_snitch_executable name)
    add_executable(${ARGV})
    add_custom_command(
        TARGET ${name}
        POST_BUILD
        COMMAND ${CMAKE_OBJDUMP} -dhS "--source-comment=\# " $<TARGET_FILE:${name}> > $<TARGET_FILE:${name}>.s)
endmacro()

macro(add_snitch_test_custom name)
    add_snitch_executable(test-${name} ${ARGN})
    target_link_libraries(test-${name} snRuntime-banshee)
endmacro()

macro(add_snitch_test name)
    add_snitch_test_custom(${ARGV})
    add_test(NAME ${name}-core COMMAND ${SNITCH_BANSHEE} $<TARGET_FILE:test-${name}> --base-hartid=3)
    add_test(NAME ${name}-cluster COMMAND ${SNITCH_BANSHEE} $<TARGET_FILE:test-${name}> --base-hartid=3 --num-cores=8)
    add_test(NAME ${name}-system COMMAND ${SNITCH_BANSHEE} $<TARGET_FILE:test-${name}> --base-hartid=3 --num-cores=8 --num-clusters=4)
endmacro()
