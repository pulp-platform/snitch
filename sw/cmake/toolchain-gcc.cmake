set(CMAKE_C_COMPILER riscv32-unknown-elf-gcc)
set(CMAKE_CXX_COMPILER riscv32-unknown-elf-g++)
set(CMAKE_OBJCOPY riscv32-unknown-elf-objcopy)
set(CMAKE_OBJDUMP riscv32-unknown-elf-objdump)
set(CMAKE_INTERPROCEDURAL_OPTIMIZATION true)

add_compile_options(-march=rv32imafd -mabi=ilp32d -mcmodel=medany -mno-fdiv -ffast-math -fno-builtin-printf -fno-common)
add_link_options(-march=rv32imafd -mabi=ilp32d -nostartfiles -Wl,-Ttext-segment=0x80000000)
# add_link_options(-Wl,--verbose)

link_libraries(-lm -lgcc)

add_compile_options(-ffunction-sections)
add_compile_options(-Wextra)

# Add preprocessor definition to indicate LD is used
add_compile_definitions(__LINK_LD)
