# Default on system path of prefixed clang as default LLVM
if (DEFINED ENV{LLVM_SNITCH_BINROOT})
    set (LLVM_SNITCH_BINROOT $ENV{LLVM_SNITCH_BINROOT})
else ()
    find_path(LLVM_SNITCH_BINROOT riscv32-unknown-elf-clang)
endif()
message(STATUS "Using LLVM_SNITCH_BINROOT=${LLVM_SNITCH_BINROOT}")

set(CMAKE_C_COMPILER ${LLVM_SNITCH_BINROOT}/clang)
set(CMAKE_CXX_COMPILER ${LLVM_SNITCH_BINROOT}/clang++)
set(CMAKE_OBJCOPY ${LLVM_SNITCH_BINROOT}/llvm-objcopy --mcpu=snitch)
set(CMAKE_OBJDUMP ${LLVM_SNITCH_BINROOT}/llvm-objdump --mcpu=snitch)
# No LTO support in LLVM (yet)
# set(CMAKE_INTERPROCEDURAL_OPTIMIZATION true)

add_compile_options(-mcpu=snitch -march=rv32imafd -mabi=ilp32d -mcmodel=medany -ffast-math -fno-builtin-printf -fno-common)
add_link_options(-mcpu=snitch -march=rv32imafd -mabi=ilp32d -nostartfiles)
# TODO: use GNU LD default linker script, as LLD does not define __tdata_start (why?)
# add_link_options(-fuse-ld=${LLVM_SNITCH_BINROOT}/ld.lld -Wl,--image-base=0x80000000)
find_path(GCC_SNITCH_BINROOT riscv32-unknown-elf-gcc)
add_link_options(-fuse-ld=${GCC_SNITCH_BINROOT}/riscv32-unknown-elf-ld -Wl,-Ttext-segment=0x80000000)
#add_link_options(-Wl,--verbose)

link_libraries(-lm)

add_compile_options(-ffunction-sections)
add_compile_options(-Wextra)
