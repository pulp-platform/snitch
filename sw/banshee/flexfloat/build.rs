// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

const FLEXFLOAT_DIR: &str = "../vendor/flexfloat";

fn main() {
    let src = ["../vendor/flexfloat/src/flexfloat.c"];

    // Ensure that we rebuild whenever any of the input files changes.
    for f in &src {
        println!("cargo:rerun-if-changed={}", f);
    }

    let mut builder = cc::Build::new();
    let build = builder
        .files(src.iter())
        .include(format!("{}/include", FLEXFLOAT_DIR))
        .flag("-std=c11")
        .flag("-O3")
        .warnings(false);
    // .define("FLEXFLOAT_FLAGS", None);

    build.compile("flexfloat");
}
