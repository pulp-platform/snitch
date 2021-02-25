# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased
### Added
- Add basic support for AMOs
- Add support for wfi

## 0.5.0 - 2020-12-14
### Added
- Add basic support for frep

## 0.4.1 - 2020-11-24
### Fixed
- Fix long branches overflowing their immediate
- Fix sb, sh instructions (properly align and mask)

## 0.4.0 - 2020-11-23
### Added
- Add cluster ID and count registers
- Add support for indirect jumps to any translated instruction
- Add dummy stdout printing via address `0xF00B8000`

### Fixed
- Fix lb, lbu, lh, lhu instructions (properly align and truncate)

## 0.3.0 - 2020-11-18
### Added
- Add test case blacklists
- Add `TEST_ARGS` to pass additional arguments to banshee during testing
- Add support for the cluster hardware barrier
- Add `-L` option to forward arguments to LLVM
- Add proper optimization for tanslated binary after runtime linking

### Fixed
- Fix crash on missing `banshee_ssr_next`
- Fix matmul tests

## 0.2.0 - 2020-11-14
### Added
- Add multi-cluster support
- Add multi-core support
- Add cluster_base_hartid register
- Add debug info to translated binary; allows debugging using gdb
- Add basic support for dm.stat, dm.strt, dm.src, dm.dst

## 0.1.0 - 2020-11-14
### Added
- Add basic SSR support
- Forward return code from executed binary
- Add fast direct-access TCDM model
- Add tracing support
- Add basic integer and float instruction support
- Add illegal inst/branch and escape aborts
