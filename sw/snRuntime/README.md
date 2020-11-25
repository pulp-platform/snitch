# Snitch Runtime Library

This library implements a minimal runtime for Snitch systems, which is responsible for the following:

- Detecting the hardware configuration (cores, clusters, ISA extensions, TCDM)
- Passing a descriptor struct to the executable
- Synchronization across cores and clusters
- Team-based multithreading and work splitting

## General Runtime

The general runtime (`libsnRuntime`) relies on a bootloader or operating system to load the executable. This usually requires virtual memory to map the segments to the correct addresses. The general runtime does not provide any startup code in this scenario, but is more like a regular library providing some useful API.

## Bare Runtime

The bare runtimes (`libsnRuntime-<platform>`) assumes that the executable it is being linked into will run in a bare-metal fashion with no convenient bootloader or virtual memory setup. For this scenario, the runtime provides the `_start` symbol and implements a basic crt0.

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
