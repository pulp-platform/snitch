set(CMAKE_C_COMPILER riscv32-unknown-elf-clang)
set(CMAKE_CXX_COMPILER riscv32-unknown-elf-clang++)
set(CMAKE_OBJCOPY llvm-objcopy)
set(CMAKE_OBJDUMP llvm-objdump --mcpu=snitch)
set(CMAKE_AR llvm-ar)
set(CMAKE_STRIP llvm-strip)
set(CMAKE_RANLIB llvm-ranlib)

# LTO
set(CMAKE_INTERPROCEDURAL_OPTIMIZATION false)

##
## Compile options
##
add_compile_options(-mcpu=snitch -mcmodel=medany -ffast-math -fno-builtin-printf -fno-common)
add_compile_options(-ffunction-sections)
add_compile_options(-Wextra)
add_compile_options(-static)

##
## Link options
##

add_link_options(-mcpu=snitch -nostartfiles -fuse-ld=lld -Wl,--image-base=0x80000000)
add_link_options(-static)
# LLD defaults to -z relro which we don't want in a static ELF
add_link_options(-Wl,-z,norelro)
add_link_options(-Wl,--gc-sections)
add_link_options(-Wl,--no-relax)
# add_link_options(-Wl,--verbose)

# Libraries
link_libraries(-lm)

# Add preprocessor definition to indicate LLD is used
add_compile_definitions(__LINK_LLD)
