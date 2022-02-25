# Snitch Software

This subdirectory contains the various bits and pieces of software for the Snitch ecosystem.

## Contents

### Simulator

The `banshee` directory contains an LLVM-based binary translation simulator for Snitch systems that is capable of specifically emulating the custom instruction set extensions. See `banshee/README.md` for more details.

### Libraries

- `applications`: Contains applications and kernels, mostly NN-related with SW testbenches for performance profiling.
- `cmake`: Bits and pieces for integration with the CMake build system.
- `snRuntime`: The fundamental, bare-metal runtime for Snitch systems. Exposes a minimal API to manage execution of code across the available cores and clusters, query information about a thread's context, and to coordinate and exchange data with other threads.
- `snBLAS`: A minimal reference implementation of the basic linear algebra subprograms that demonstrates the use of Snitch and its extensions.

### Tests

- `benchmark`: Benchmarking executables that evaluate the performance characteristics of a system.
- `test`: Unit tests for various aspects of a system, including the instruction set extensions. These complement the library-specific unit tests that live within the library directories proper.

### Third-Party

The `vendor` directory contains third-party tools that we inline into this repository for ease of use.

- `vendor/riscv-opcodes`: Utilities to manage instruction encodings and generate functions and data structurse for parsing and representation in various languages.
