# Banshee

> The Banshee (Old Irish spelling ben síde) is a Dark creature native to Ireland. Banshees are malevolent spirits that have the appearance of women and their cries are fatal to anyone that hears them. The Laughing Potion is effective defence against them.

## Usage

Run a binary as follows:

    cargo run -- path/to/riscv/bin

If you make any changes to `src/runtime.rs` or the `../riscv-opcodes`, run `make` to update the `src/runtime.ll` and `src/riscv.rs` files.

Unit tests are in `../banshee-tests` and can be compiled and built as follows (compilation requires a riscv toolchain):

    make -C ../banshee-tests
    make test

    # or run an individual test `../banshee-tests/bin/dummy`
    make test-dummy

An `lldb` session with one of the unit tests can be started as follows:

    # for test `../banshee-tests/bin/dummy`
    make debug-dummy

To enable debug output, set the `SNITCH_LOG` environment variable to `error`, `warn`, `info`, `debug`, or `trace`. More detailed [configurations](https://docs.rs/env_logger) are possible.

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
