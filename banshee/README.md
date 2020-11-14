# Banshee

> The Banshee (Old Irish spelling ben síde) is a Dark creature native to Ireland. Banshees are malevolent spirits that have the appearance of women and their cries are fatal to anyone that hears them. The Laughing Potion is effective defence against them.

## Usage

Run a binary as follows:

    cargo run -- path/to/riscv/bin

If you make any changes to `src/runtime.rs` or the `../riscv-opcodes`, run `make` to update the `src/runtime.ll` and `src/riscv.rs` files.

To enable logging output, set the `SNITCH_LOG` environment variable to `error`, `warn`, `info`, `debug`, or `trace`. More detailed [configurations](https://docs.rs/env_logger) are possible.

### Unit Tests

Unit tests are in `../banshee-tests` and can be compiled and built as follows (compilation requires a riscv toolchain):

    make -C ../banshee-tests
    make test

    # or run an individual test `../banshee-tests/bin/dummy`
    make test-dummy

An `lldb` session with one of the unit tests can be started as follows:

    # for test `../banshee-tests/bin/dummy`
    make debug-dummy

### Debugging

You can debug the RISC-V binary execution using GDB. First, execute banshee within GDB:

    gdb --args banshee <banshee args>
    (gdb) b execute_binary
    # respond with "y" to "Make breakpoint pending..."
    (gdb) r

Banshee tries to annotate the translated binary with the PC and disassembly of the original program. This is fairly brittle due to how GDB and debuggers work: The disassembly is annotated as an inlined function. This also means that `n` generally steps over the instruction:

    (gdb) n
    0x00007ffff7fc6003 in execute_binary ()

To ensure you see the instructions annotated, use `ni` to step based on instructions. This is tedious, because you need to step through every x86 instruction that corresponds to a RISC-V instruction in the binary, but ensures you see everything:

    (gdb)
    0x8001001c slli rd=5 rs1=a shamt=3 () at <binary>:8
    8   in <binary>
    (gdb)
    0x80010020 sub rd=2 rs1=2 rs2=5 () at <binary>:9
    9   in <binary>
    (gdb)
    0x00007ffff7fc60bb  9   in <binary>
    (gdb)
    0x80010024 slli rd=5 rs1=5 shamt=6 () at <binary>:10
    10   in <binary>
    (gdb)
    0x80010028 sub rd=2 rs1=2 rs2=5 () at <binary>:11
    11  in <binary>
    (gdb)

The line numbers (8 to 11) indicate that these are the 8th to 11th instructions in the binary, counted in order of appearance in the ELF file.

A more convenient trick to step through the program on RISC-V instruction granularity is to use `n` to step to the next instruction (which places you "in front" of the instruction, not seeing its debug info yet), and then using `s` to step into it.

    (gdb) n
    execute_binary () at binary.riscv:35
    35  in binary.riscv
    (gdb) s
    0x80010088 lui imm20=5f5e rd=d () at binary.riscv:35
    35  in binary.riscv

The arguably best debugging experience is to switch GDB into `layout asm` and use `ni` to step through the instructions. This still requires stepping through every x86 instruction, but the output is comfortably readable.

You can set breakpoints on instructions in the RISC-V binary based on their index in the file (useful if you have a disassembly open and can count the number of instructions):

    (gdb) b binary.riscv:9
    Breakpoint 2 at 0x7ffff7fc60b8: file binary.riscv, line 9.
    (gdb) c
    Breakpoint 2, 0x80010020 () at binary.riscv:9

## Limitations

- Static translation only at the moment
- Float rounding modes are ignored

## Todo

- [x] Add instruction tracing
- [x] Add SSR support
- [ ] Add DMA support
- [ ] Add FREP support
- [x] Add fast local memory / memory hierarchy
- [ ] Add multi-core execution
- [ ] Add multi-cluster execution
- [ ] Replace all `self.declare_func(..)` in `tran.rs` with decls in `jit.ll`
- [ ] Replace state type in `tran.rs` with decl in `jit.ll`
- [ ] Replace all GEP on state ptr in `tran.rs` with calls into `jit.rs`
