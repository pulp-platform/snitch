# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).


## Unreleased

### Added

### Changed

### Fixed


## 0.2.0 - 2020-03-13

### Added
- Add clocked `APB_DV` interface for design verification.
- Define macros for APB typedefs.
- Define macros for assigning APB interfaces.
- Add `apb_regs` read-write registers with APB interface with optional read only mapping.
- Add basic test infrastructure for APB modules.
- Add contribution guidelines.
- Add RTL testbenches for modules.
- Add synthesis and simulation scripts.
- `synth_bench`: add synthesis bench.

### Changed
- Rename `APB_BUS` interface to `APB`, change its parameters to constants, and remove `in` and `out` modports.


## 0.1.0 - 2018-09-12
### Changed
- Open source release.

### Added
- Initial commit.
