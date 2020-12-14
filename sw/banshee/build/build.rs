// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

mod runtime;
mod softfloat;

fn main() {
    // Prevent cargo from re-building everything by default.
    // Other subcommands can still emit their own rerun-if-changed lines.
    println!("cargo:rerun-if-changed=build/softfloat.rs");

    // Build the components.
    softfloat::build();
    runtime::build();
}
