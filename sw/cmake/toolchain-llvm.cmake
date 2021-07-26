set(CMAKE_C_COMPILER riscv32-unknown-elf-clang)
set(CMAKE_CXX_COMPILER riscv32-unknown-elf-clang++)
set(CMAKE_OBJCOPY llvm-objcopy)
set(CMAKE_OBJDUMP llvm-objdump --mcpu=snitch)
set(CMAKE_AR llvm-ar)
set(CMAKE_STRIP llvm-strip)
set(CMAKE_RANLIB llvm-ranlib)

# LTO
set(CMAKE_INTERPROCEDURAL_OPTIMIZATION false)

# -march=rv32imafd -mabi=ilp32d
add_compile_options(-mcpu=snitch -mcmodel=medany -ffast-math -fno-builtin-printf -fno-common)
add_link_options(-mcpu=snitch -nostartfiles -fuse-ld=lld -Wl,--image-base=0x80000000)
# add_link_options(-Wl,--verbose)

link_libraries(-lm)

add_compile_options(-ffunction-sections)
add_compile_options(-Wextra)
