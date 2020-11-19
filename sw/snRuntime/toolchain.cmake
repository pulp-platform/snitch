set(CMAKE_C_COMPILER riscv32-unknown-elf-gcc)
set(CMAKE_CXX_COMPILER riscv32-unknown-elf-g++)
set(CMAKE_OBJCOPY riscv32-unknown-elf-objcopy)
set(CMAKE_OBJDUMP riscv32-unknown-elf-objdump)

add_compile_options(-march=rv32imafd)
add_link_options(-march=rv32imafd -nostdlib -Wl,-Ttext-segment=0x80000000)
# add_link_options(-Wl,--verbose)
