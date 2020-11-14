# Banshee

> The Banshee (Old Irish spelling ben síde) is a Dark creature native to Ireland. Banshees are malevolent spirits that have the appearance of women and their cries are fatal to anyone that hears them. The Laughing Potion is effective defence against them.

## Usage

    cargo run -- -h

Run a binary as follows:

    cargo run -- path/to/riscv/bin

If you make any changes to `src/runtime.rs` or the `../riscv-opcodes`, run `make` to update the `src/runtime.ll` and `src/riscv.rs` files.

To enable logging output, set the `SNITCH_LOG` environment variable to `error`, `warn`, `info`, `debug`, or `trace`. More detailed [configurations](https://docs.rs/env_logger) are possible.

### Tracing

Instructions can be traced as they execute using the `--trace` option:

    $ banshee path/to/riscv/bin --trace
    # cycle  hart pc        accesses            dasm
    00000001 0005 80010000  x10=00000005      # DASM(f1402573)
    00000002 0005 80010004  x10:00000005 […]  # DASM(00351293)
    00000003 0005 80010008  x6=20000000       # DASM(20000337)
    00000004 0005 8001000c  x5:00000028 […]   # DASM(006282b3)
    00000005 0005 80010010  x5:20000028 […]   # DASM(00a2a023)
    00000006 0005 80010014                    # DASM(10500073)

Piping the output into `sort` will cause the trace to be sorted by cycle and hartid, which is convenient. Piping into `spike-dasm` will provide further inline disassembly:

    $ banshee path/to/riscv/bin --trace | sort | spike-dasm
    # cycle  hart pc        accesses            dasm
    00000001 0005 80010000  x10=00000005      # csrr    a0, mhartid
    00000002 0005 80010004  x10:00000005 […]  # slli    t0, a0, 3
    00000003 0005 80010008  x6=20000000       # lui     t1, 0x20000
    00000004 0005 8001000c  x5:00000028 […]   # add     t0, t0, t1
    00000005 0005 80010010  x5:20000028 […]   # sw      a0, 0(t0)
    00000006 0005 80010014                    # wfi (args unknown)

**Caution:** Piping the stdout through `spike-dasm` can cause the instruction trace to look delayed with respect to debug and trace logs (which run through stderr), if you have them enabled in `SNITCH_LOG`. This is just a visual artifact.

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

## Dependencies

Banshee currently requires LLVM 10 to be installed on the system. It is *technically* possible to support multiple LLVM versions through the use of cargo features, but that is not yet implemented.

As a hacky workaround, try changing the `llvm-sys = "100"` line to whatever major version you have times 10, and hope for the best. Be prepared that this breaks the build due to some API changes in LLVM.

## Limitations

- Static translation only at the moment
- Float rounding modes are ignored

## Todo

- [x] Add instruction tracing
- [x] Add SSR support
- [ ] Add DMA support
- [ ] Add FREP support
- [x] Add fast local memory / memory hierarchy
- [x] Add multi-core execution
- [x] Add multi-cluster execution
- [ ] Replace all `self.declare_func(..)` in `tran.rs` with decls in `jit.ll`
- [ ] Replace state type in `tran.rs` with decl in `jit.ll`
- [ ] Replace all GEP on state ptr in `tran.rs` with calls into `jit.rs`
- [ ] Read the DWARF data in the RISC-V binary, and emit that again as part of the translated LLVM IR; which should allow GDB to debug the original source code of the RISC-V binary
