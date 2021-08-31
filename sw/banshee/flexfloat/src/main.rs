// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

extern crate flexfloat;

// SOFTFLOAT FORMATS
pub const FP16EXP: u8 = 5;
pub const FP16MAN: u8 = 10;

fn main() {
    println!("Hello, world!");

    unsafe {
        let env = flexfloat::flexfloat_desc_t {
            exp_bits: FP16EXP,
            frac_bits: FP16MAN,
        };

        let ff_a: *mut flexfloat::flexfloat_t = &mut flexfloat::flexfloat_t {
            value: 1.0,
            desc: env,
        };
        let ff_b: *mut flexfloat::flexfloat_t = &mut flexfloat::flexfloat_t {
            value: 1.0,
            desc: env,
        };
        let ff_res: *mut flexfloat::flexfloat_t = &mut flexfloat::flexfloat_t {
            value: 0.0,
            desc: env,
        };

        flexfloat::ff_add(ff_res, ff_a, ff_b);
    };

    println!("Flexfloat integrated!");
}
