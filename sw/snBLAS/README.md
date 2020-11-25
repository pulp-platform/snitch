# Snitch BLAS Library

This is an implementation of the Basic Linear Algebra Subprograms for the Snitch system.

## Usage

The runtime library can be compiled as follows:

    mkdir build
    cd build
    cmake ..
    make

The tests can be executed as follows:

    make test

Interesting CMake options that can be set via `-D<option>=<value>`:

- `SNITCH_BANSHEE`: The banshee simulator binary to use for test execution.
- `CMAKE_TOOLCHAIN_FILE`: The compiler toolchain configuration to use. Acceptable values:
    - `toolchain-gcc` for a GNU tolchain
    - `toolchain-llvm` for a LLVM/Clang toolchain (coming soon)
    - Your own custom `<toolchain>.cmake` file; see `../cmake/toolchain-gcc.cmake` for reference
