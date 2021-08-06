// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#![allow(non_upper_case_globals)]
#![allow(non_snake_case)]
#![allow(non_camel_case_types)]

include!("./bindings.rs");

/// FLEXFLOAT FORMATS
pub const FP16EXP: u8 = 5;
pub const FP16MAN: u8 = 10;

pub const FP16ALTEXP: u8 = 8;
pub const FP16ALTMAN: u8 = 7;

pub const FP8EXP: u8 = 5;
pub const FP8MAN: u8 = 2;

pub const FP8ALTEXP: u8 = 4;
pub const FP8ALTMAN: u8 = 3;
