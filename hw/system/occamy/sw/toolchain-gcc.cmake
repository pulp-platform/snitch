option(DEBUG "Produce debugging symbols during compilation" OFF)

########## CVA6 toolchain ###########

set(CVA6_C_COMPILER riscv64-unknown-elf-gcc)
set(CVA6_CXX_COMPILER riscv64-unknown-elf-g++)
set(CVA6_OBJCOPY riscv64-unknown-elf-objcopy)
set(CVA6_OBJDUMP riscv64-unknown-elf-objdump)

set(CVA6_C_FLAGS
  -march=rv64imafdc
  -mabi=lp64d
  -mcmodel=medany
  -ffast-math
  -fno-builtin-printf
  -fno-common
  -O2
  -ffunction-sections
  -Wextra
  -Werror
)
if(DEBUG)
  list(APPEND CVA6_C_FLAGS -g)
endif()
set(CVA6_LD_FLAGS
  -lm
  -lgcc
  -nostartfiles
  -Wl,-T${CMAKE_CURRENT_SOURCE_DIR}/occamy.ld
)

########## Snitch toolchain ###########

# Paths relative to build directory
set(SNITCH_DIR ../sn_src)
set(SNRT_BUILD_DIR ../../../../../sw/snRuntime/build)
set(SN_C_COMPILER riscv32-unknown-elf-gcc)
set(SN_OBJCOPY riscv32-unknown-elf-objcopy)
set(SN_C_FLAGS
  -march=rv32imafd
  -mabi=ilp32d
  -mcmodel=medany
  -mno-fdiv
  -ffast-math
  -fno-builtin-printf
  -fno-common
  -O2
)
if(DEBUG)
  list(APPEND SN_C_FLAGS -g)
endif()
set(SN_LD_FLAGS
  -L${SNRT_BUILD_DIR}
  -lsnRuntime-cluster
  -nostartfiles
  -lm
  -lgcc
  -T ${CMAKE_CURRENT_SOURCE_DIR}/snitch.ld
)
set(SN_OJBCOPY_FLAGS
  -O binary
  --remove-section=.comment
  --remove-section=.riscv.attributes
  --remove-section=.debug_info
  --remove-section=.debug_abbrev
  --remove-section=.debug_line
  --remove-section=.debug_str
  --remove-section=.debug_aranges
)