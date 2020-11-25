# Snitch System Generator

The Snitch project is an open-source RISC-V hardware research project of ETH Zurich and University of Bologna targeting highest possible energy-efficiency. The system is designed around a versatile and small integer core, which we call Snitch. The system is ought to be highly parameterizable and suitable for many use-cases, ranging from small, control-only cores, to large many-core system made for pure number crunching in the HPC domain.

## Getting Started

TODO(zarubaf) TBD once the system stabilizes.

## Documentation

The documentation is built from the latest master and hosted at github pages: [https://pulp-platform.github.io/snitch](https://pulp-platform.github.io/snitch).

## About this Repository

This repository is developed as a monorepo, external dependencies are "vendored-in" and checked in. Keeping it a monolithic repository helps to keep the hardware dependencies under control and enables precise snapshotting (invaluable when you are taping-out chips).

## Licensing

Snitch is being made available under permissive open source licenses. See the `README.md` for a more detailed break-down.
