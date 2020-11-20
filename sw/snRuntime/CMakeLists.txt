cmake_minimum_required(VERSION 3.10)
set(CMAKE_TOOLCHAIN_FILE toolchain.cmake)
project(snRuntime C ASM)

macro(add_snitch_library name)
    add_library(${ARGV})
    add_custom_command(
        TARGET ${name}
        POST_BUILD
        COMMAND ${CMAKE_OBJDUMP} -dh $<TARGET_FILE:${name}> > $<TARGET_FILE:${name}>.s)
endmacro()

macro(add_snitch_executable name)
    add_executable(${ARGV})
    add_custom_command(
        TARGET ${name}
        POST_BUILD
        COMMAND ${CMAKE_OBJDUMP} -dh $<TARGET_FILE:${name}> > $<TARGET_FILE:${name}>.s)
endmacro()

macro(add_snitch_test name)
    add_snitch_executable(test-${name} ${ARGN})
    target_link_libraries(test-${name} snRuntime-banshee)
    add_test(NAME ${name} COMMAND banshee $<TARGET_FILE:test-${name}> --trace)
endmacro()

include_directories(include)

# Generic Runtime (requiring bootloader/OS)
add_snitch_library(snRuntime src/start.S)

# Bare Runtimes (with startup code)
add_snitch_library(snRuntime-banshee src/start_banshee.S)
add_snitch_library(snRuntime-billywig src/start_billywig.S)
add_snitch_library(snRuntime-bowtruckle src/start_bowtruckle.S)
add_snitch_library(snRuntime-lethifold src/start_lethifold.S)
add_snitch_library(snRuntime-thestral src/start_thestral.S)

# Unit tests
enable_testing()
add_snitch_test(tls tests/tls.c)
add_snitch_test(simple tests/simple.c)
