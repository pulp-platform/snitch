// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#![allow(non_upper_case_globals)]
#![allow(non_snake_case)]
#![allow(non_camel_case_types)]

include!("./bindings.rs");

/// FLEXFLOAT FORMATS
pub const FP64EXP: u8 = 11;
pub const FP64MAN: u8 = 52;

pub const FP32EXP: u8 = 8;
pub const FP32MAN: u8 = 23;

pub const FP16EXP: u8 = 5;
pub const FP16MAN: u8 = 10;

pub const FP16ALTEXP: u8 = 8;
pub const FP16ALTMAN: u8 = 7;

pub const FP8EXP: u8 = 5;
pub const FP8MAN: u8 = 2;

pub const FP8ALTEXP: u8 = 4;
pub const FP8ALTMAN: u8 = 3;


/// FLEXFLOAT ENVIRONMENTS
pub const env_fp64 : flexfloat_desc_t = flexfloat_desc_t {
    exp_bits:  FP64EXP,
    frac_bits: FP64MAN,
};

pub const env_fp32 : flexfloat_desc_t = flexfloat_desc_t {
    exp_bits:  FP32EXP,
    frac_bits: FP32MAN,
};

pub const env_fp16 : flexfloat_desc_t = flexfloat_desc_t {
    exp_bits: FP16EXP,
    frac_bits: FP16MAN,
};

pub const env_fp16alt : flexfloat_desc_t = flexfloat_desc_t {
    exp_bits: FP16ALTEXP,
    frac_bits: FP16ALTMAN,
};

pub const env_fp8 : flexfloat_desc_t = flexfloat_desc_t {
    exp_bits: FP8EXP,
    frac_bits: FP8MAN,
};

pub const env_fp8alt : flexfloat_desc_t = flexfloat_desc_t {
    exp_bits: FP8ALTEXP,
    frac_bits: FP8ALTMAN,
};

/// Helper functions

pub fn flexfloat_sign(a: *const flexfloat_t) -> bool
{
    unsafe{
        (ff_get_double(a) as u64 >> (NUM_BITS-1)) != 0
    }
}
