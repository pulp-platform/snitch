#################
# Configuration #
#################

cmake_minimum_required(VERSION 3.13)
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR})
set(CMAKE_TOOLCHAIN_FILE toolchain-gcc CACHE STRING "Toolchain to use")

project(occamy LANGUAGES C ASM)

set(SNITCH_PREFIX sn)
set(SNITCH_DIR sn_src)
set(SNITCH_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/sn_src)
set(SNITCH_BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR})
set(SNITCH_RUNTIME_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../../../../sw/snRuntime)
set(OCCAMY_RUNTIME_DIR ${CMAKE_CURRENT_SOURCE_DIR}/occamyRuntime)

#############
# Libraries #
#############

# snRuntime
set(SNRT_LIB ${SNRT_BUILD_DIR}/libsnRuntime-cluster.a)
set(SNRT_BUILD_COMMAND make -C ${CMAKE_CURRENT_SOURCE_DIR} -f snRuntime.mk update-lib)
if(DEBUG)
  string(APPEND SNRT_BUILD_COMMAND DEBUG=ON)
endif()
add_custom_command(OUTPUT ${SNRT_LIB} COMMAND ${SNRT_BUILD_COMMAND})
add_custom_target(sn_runtime_lib_target DEPENDS ${SNRT_LIB})

########################
# Functions and macros #
########################

# Creates the dump of an executable
function(dump_executable name)
  add_custom_command(
    OUTPUT ${name}.dump
    COMMAND ${CVA6_OBJDUMP} -D ${name} > ${name}.dump
    DEPENDS ${name}
  )
  add_custom_target(dump-${name} ALL DEPENDS ${name}.dump)
endfunction()

# Creates a host executable which includes common sources.
# You can include a Snitch binary in the CVA6 binary by
# providing a 3rd optional argument to the function.
function(add_host_executable name srcs)
	# Variables
  set(CVA6_COMMON_SRCS
    ${OCCAMY_RUNTIME_DIR}/start_host.S
    ${OCCAMY_RUNTIME_DIR}/host.c)
  set(CVA6_INCLUDE_FLAGS
    -I${OCCAMY_RUNTIME_DIR}
    -I${CMAKE_CURRENT_SOURCE_DIR}/include)
  # Get optional function arguments
  if(${ARGC} GREATER 2)
    list(GET ARGN 0 SN_BINARY)
  endif()
  # Make source file paths absolute
  list(TRANSFORM srcs PREPEND ${CMAKE_CURRENT_SOURCE_DIR}/)
  # Command to compile CVA6 binary
  add_custom_command(
    OUTPUT ${name}
    COMMAND ${CVA6_C_COMPILER}
            ${CVA6_C_FLAGS} ${CVA6_INCLUDE_FLAGS}
            -DSNITCH_BINARY=\\"${SN_BINARY}\\"
            ${CVA6_COMMON_SRCS} ${srcs}
            ${CVA6_LD_FLAGS}
            -o ${name}
    DEPENDS ${CVA6_COMMON_SRCS} ${srcs} ${SN_BINARY}
  )
  # Add a target to build the CVA6 binary
  add_custom_target(build-${name} ALL DEPENDS ${name})
  # Create a dump of the CVA6 binary
  dump_executable(${name})
endfunction()

# Creates an executable with program code for both CVA6 and Snitch cores.
# Snitch code is additionally linked against snRuntime library.
# You can pass additional options to the Snitch binary compilation
# command, e.g. -I flags, via a 4th optional argument.
function(add_heterogeneous_executable name srcs sn_srcs)
  # Variables
	set(SNITCH_ELF       ${SNITCH_PREFIX}_${name}.elf)
	set(SNITCH_BIN       ${SNITCH_PREFIX}_${name}.bin)
	set(SNITCH_TARGET    ${SNITCH_PREFIX}_${name})
	set(SN_INCLUDE_FLAGS
    -I${SNITCH_RUNTIME_DIR}/include
    -I${SNITCH_RUNTIME_DIR}/vendor
    -I${SNITCH_RUNTIME_DIR}/vendor/riscv-opcodes
    -I${CMAKE_CURRENT_SOURCE_DIR}/occamyRuntime
    -I${CMAKE_CURRENT_SOURCE_DIR}/include
  )
	set(SN_COMMON_SRCS   ${OCCAMY_RUNTIME_DIR}/start_device.S)
  # Get optional function arguments
  if(${ARGC} GREATER 3)
    list(GET ARGN 0 ADD_SN_C_FLAGS)
  endif()
  # Make source file paths absolute
  list(TRANSFORM sn_srcs PREPEND ${CMAKE_CURRENT_SOURCE_DIR}/)
	# Compile Snitch ELF
	add_custom_command(
    OUTPUT ${SNITCH_ELF}
    COMMAND ${SN_C_COMPILER}
            ${SN_C_FLAGS} ${ADD_SN_C_FLAGS} ${SN_INCLUDE_FLAGS}
            ${SN_COMMON_SRCS} ${sn_srcs}
            ${SN_LD_FLAGS}
            -o ${SNITCH_ELF}
    DEPENDS sn_runtime_lib_target ${sn_srcs_ext}
  )
  # Copy the ELF contents to a binary and to a human-readable dump file
	add_custom_command(
    OUTPUT ${SNITCH_BIN}
    COMMAND ${SN_OBJCOPY} ${SN_OJBCOPY_FLAGS} ${SNITCH_ELF} ${SNITCH_BIN}
    DEPENDS ${SNITCH_ELF}
  )
  dump_executable(${SNITCH_ELF})
  # Add a target to build the Snitch binary
	add_custom_target(
    ${SNITCH_TARGET}
    DEPENDS ${SNITCH_BIN}
  )

	# Hybrid target is a CVA6 executable with a dependency
  # on the previously created Snitch binary
	add_host_executable(${name} ${srcs} ${SNITCH_BINARY_DIR}/${SNITCH_BIN})
endfunction()

######################
# Executable targets #
######################

add_host_executable(hello_world src/hello_world.c)
