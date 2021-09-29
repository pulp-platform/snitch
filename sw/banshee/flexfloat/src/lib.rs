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
pub const env_fp64: flexfloat_desc_t = flexfloat_desc_t {
    exp_bits: FP64EXP,
    frac_bits: FP64MAN,
};

pub const env_fp32: flexfloat_desc_t = flexfloat_desc_t {
    exp_bits: FP32EXP,
    frac_bits: FP32MAN,
};

pub const env_fp16: flexfloat_desc_t = flexfloat_desc_t {
    exp_bits: FP16EXP,
    frac_bits: FP16MAN,
};

pub const env_fp16alt: flexfloat_desc_t = flexfloat_desc_t {
    exp_bits: FP16ALTEXP,
    frac_bits: FP16ALTMAN,
};

pub const env_fp8: flexfloat_desc_t = flexfloat_desc_t {
    exp_bits: FP8EXP,
    frac_bits: FP8MAN,
};

pub const env_fp8alt: flexfloat_desc_t = flexfloat_desc_t {
    exp_bits: FP8ALTEXP,
    frac_bits: FP8ALTMAN,
};

/// Flexfloat: which operations is emulated
#[derive(Debug, Clone, Copy)]
#[repr(C)]
pub enum FlexfloatFormat {
    Fp16,
    Fp16alt,
    Fp8,
    Fp8alt,
}

/// Flexfloat: which operations is emulated
#[derive(Debug, Clone, Copy)]
#[repr(C)]
pub enum FlexfloatOp {
    Fmadd,
    Fmsub,
    Fnmadd,
    Fnmsub,
    Fadd,
    Fsub,
    Fmul,
    Fdiv,
    // Fsqrt, // Not implemented ?
    Fsgnj,
    Fsgnjn,
    Fsgnjx,
    Fmin,
    Fmax,
    // Fclass, // Not implemented ?
}

#[derive(Debug, Clone, Copy)]
#[repr(C)]
pub enum FfOpCvt {
    Fmvx2f,
    // Fmvf2x,
    Fcvtw2f,
    Fcvtwu2f,
    Fcvtf2w,
    Fcvtf2wu,
    // FcpkAhS,
    // FcpkAhD,
    FcpkS2,
    FcpkD2,
    Fcvt64f2f,
    Fcvt32f2f,
    Fcvt16f2f,
    Fcvt8f2f,
}

#[derive(Debug, Clone, Copy)]
#[repr(C)]
pub enum FlexfloatOpCmp {
    Feq,
    Flt,
    Fle,
    Fge,
    Fgt,
    Fne,
}

#[derive(Debug, Clone, Copy)]
#[repr(C)]
pub enum FlexfloatOpExp {
    FaddexSH,
    FmulexSH,
    FmacexSH,
    FmulexSB,
    FaddexHB,
    FmulexHB,
    FmacexHB,
}

/// return the sign of the flexfloat
pub fn flexfloat_sign(a: *const flexfloat_t) -> bool {
    unsafe { (((*a).value as uint_t) >> (NUM_BITS - 1)) != 0 }
    // (sign as uint_t)<<(NUM_BITS-1) as uint_t
    // unsafe{
    //     (ff_get_double(a) as uint_t >> (NUM_BITS-1)) as uint_t != 0
    // }
}

/// conversions to fp8 and fp8alt
pub unsafe fn ff_instruction_cvt_to_b(
    rs1: u64,
    op: FfOpCvt,
    fpmode_src: bool,
    fpmode_dst: bool,
) -> u8 {
    let env_fp8_src: flexfloat_desc_t = if fpmode_src { env_fp8alt } else { env_fp8 };
    let env_fp16_src: flexfloat_desc_t = if fpmode_src { env_fp16alt } else { env_fp16 };

    let env_dst: flexfloat_desc_t = if fpmode_dst { env_fp8alt } else { env_fp8 };

    let ff_a8: *mut flexfloat_t = &mut flexfloat_t {
        value: 0.0,
        desc: env_fp8_src,
    };
    let ff_a16: *mut flexfloat_t = &mut flexfloat_t {
        value: 0.0,
        desc: env_fp16_src,
    };
    let ff_a32: *mut flexfloat_t = &mut flexfloat_t {
        value: 0.0,
        desc: env_fp32,
    };
    let ff_a64: *mut flexfloat_t = &mut flexfloat_t {
        value: 0.0,
        desc: env_fp64,
    };
    let ff_res: *mut flexfloat_t = &mut flexfloat_t {
        value: 0.0,
        desc: env_dst,
    };

    flexfloat_set_bits(ff_a8, rs1 as u64);
    flexfloat_set_bits(ff_a16, rs1 as u64);
    flexfloat_set_bits(ff_a32, rs1 as u64);
    flexfloat_set_bits(ff_a64, rs1 as u64);

    match op {
        FfOpCvt::FcpkS2 => ff_cast(ff_res, ff_a32, env_dst),
        FfOpCvt::FcpkD2 => ff_cast(ff_res, ff_a64, env_dst),
        FfOpCvt::Fmvx2f => ff_cast(ff_res, ff_a8, env_dst),
        FfOpCvt::Fcvtw2f => {
            ff_init_int(ff_res, (rs1 & 0xffffffff) as i32, env_dst);
        }
        FfOpCvt::Fcvtwu2f => {
            ff_init_long(ff_res, (rs1 & 0xffffffff) as i64, env_dst);
        }
        FfOpCvt::Fcvt8f2f => ff_cast(ff_res, ff_a8, env_dst),
        FfOpCvt::Fcvt16f2f => ff_cast(ff_res, ff_a16, env_dst),
        FfOpCvt::Fcvt32f2f => ff_cast(ff_res, ff_a32, env_dst),
        FfOpCvt::Fcvt64f2f => ff_cast(ff_res, ff_a64, env_dst),
        _ => (),
    };

    let rd = flexfloat_get_bits(ff_res);
    rd as u8
}

/// conversions from fp8 and fp8alt
pub unsafe fn ff_instruction_cvt_from_b(
    rs1: u64,
    op: FfOpCvt,
    _fpmode_src: bool,
    fpmode_dst: bool,
) -> i32 {
    let ff_a8: *mut flexfloat_t = if fpmode_dst {
        &mut flexfloat_t {
            value: 0.0,
            desc: env_fp8alt,
        }
    } else {
        &mut flexfloat_t {
            value: 0.0,
            desc: env_fp8,
        }
    };

    flexfloat_set_bits(ff_a8, rs1 as u64);

    let rd = match op {
        FfOpCvt::Fcvtf2w => double_to_int((*ff_a8).value),
        FfOpCvt::Fcvtf2wu => (double_to_uint((*ff_a8).value) as i32),
        _ => 0,
    };

    rd as i32
}

/// conversions to fp16 and fp16alt
pub unsafe fn ff_instruction_cvt_to_h(
    rs1: u64,
    op: FfOpCvt,
    fpmode_src: bool,
    fpmode_dst: bool,
) -> u16 {
    let env_fp8_src: flexfloat_desc_t = if fpmode_src { env_fp8alt } else { env_fp8 };
    let env_fp16_src: flexfloat_desc_t = if fpmode_src { env_fp16alt } else { env_fp16 };

    let env_dst: flexfloat_desc_t = if fpmode_dst { env_fp16alt } else { env_fp16 };

    let ff_a8: *mut flexfloat_t = &mut flexfloat_t {
        value: 0.0,
        desc: env_fp8_src,
    };
    let ff_a16: *mut flexfloat_t = &mut flexfloat_t {
        value: 0.0,
        desc: env_fp16_src,
    };
    let ff_a32: *mut flexfloat_t = &mut flexfloat_t {
        value: 0.0,
        desc: env_fp32,
    };
    let ff_a64: *mut flexfloat_t = &mut flexfloat_t {
        value: 0.0,
        desc: env_fp64,
    };
    let ff_res: *mut flexfloat_t = &mut flexfloat_t {
        value: 0.0,
        desc: env_dst,
    };

    flexfloat_set_bits(ff_a8, rs1 as u64);
    flexfloat_set_bits(ff_a16, rs1 as u64);
    flexfloat_set_bits(ff_a32, rs1 as u64);
    flexfloat_set_bits(ff_a64, rs1 as u64);

    match op {
        FfOpCvt::FcpkS2 => ff_cast(ff_res, ff_a32, env_dst),
        FfOpCvt::FcpkD2 => ff_cast(ff_res, ff_a64, env_dst),
        FfOpCvt::Fmvx2f => ff_cast(ff_res, ff_a16, env_dst),
        FfOpCvt::Fcvtw2f => {
            ff_init_int(ff_res, (rs1 & 0xffffffff) as i32, env_dst);
        }
        FfOpCvt::Fcvtwu2f => {
            ff_init_long(ff_res, (rs1 & 0xffffffff) as i64, env_dst);
        }
        FfOpCvt::Fcvt8f2f => ff_cast(ff_res, ff_a8, env_dst),
        FfOpCvt::Fcvt16f2f => ff_cast(ff_res, ff_a16, env_dst),
        FfOpCvt::Fcvt32f2f => ff_cast(ff_res, ff_a32, env_dst),
        FfOpCvt::Fcvt64f2f => ff_cast(ff_res, ff_a64, env_dst),
        _ => (),
    };

    let rd = flexfloat_get_bits(ff_res);
    rd as u16
}

/// conversions from fp16 and fp16alt
pub unsafe fn ff_instruction_cvt_from_h(
    rs1: u64,
    op: FfOpCvt,
    _fpmode_src: bool,
    fpmode_dst: bool,
) -> i32 {
    let ff_a16: *mut flexfloat_t = if fpmode_dst {
        &mut flexfloat_t {
            value: 0.0,
            desc: env_fp16alt,
        }
    } else {
        &mut flexfloat_t {
            value: 0.0,
            desc: env_fp16,
        }
    };

    flexfloat_set_bits(ff_a16, rs1 as u64);

    let rd = match op {
        // FfOpCvt::Fmvf2x   => ff_cast(ff_res, ff_a, env_dst),
        FfOpCvt::Fcvtf2w => double_to_int((*ff_a16).value),
        FfOpCvt::Fcvtf2wu => (double_to_uint((*ff_a16).value) as i32),
        _ => 0,
    };

    rd as i32
}

/// conversions to fp32
pub unsafe fn ff_instruction_cvt_to_s(
    rs1: u64,
    op: FfOpCvt,
    fpmode_src: bool,
    _fpmode_dst: bool,
) -> i32 {
    let env_fp8_src: flexfloat_desc_t = if fpmode_src { env_fp8alt } else { env_fp8 };
    let env_fp16_src: flexfloat_desc_t = if fpmode_src { env_fp16alt } else { env_fp16 };

    let ff_a8: *mut flexfloat_t = &mut flexfloat_t {
        value: 0.0,
        desc: env_fp8_src,
    };
    let ff_a16: *mut flexfloat_t = &mut flexfloat_t {
        value: 0.0,
        desc: env_fp16_src,
    };
    let ff_res: *mut flexfloat_t = &mut flexfloat_t {
        value: 0.0,
        desc: env_fp32,
    };

    flexfloat_set_bits(ff_a8, rs1 as u64);
    flexfloat_set_bits(ff_a16, rs1 as u64);

    match op {
        FfOpCvt::Fcvt8f2f => ff_cast(ff_res, ff_a8, env_fp32),
        FfOpCvt::Fcvt16f2f => ff_cast(ff_res, ff_a16, env_fp32),
        _ => (),
    };

    let rd = flexfloat_get_bits(ff_res);
    rd as i32
}

/// conversions to fp64
pub unsafe fn ff_instruction_cvt_to_d(
    rs1: u64,
    op: FfOpCvt,
    fpmode_src: bool,
    _fpmode_dst: bool,
) -> u64 {
    let env_fp8_src: flexfloat_desc_t = if fpmode_src { env_fp8alt } else { env_fp8 };
    let env_fp16_src: flexfloat_desc_t = if fpmode_src { env_fp16alt } else { env_fp16 };

    let ff_a8: *mut flexfloat_t = &mut flexfloat_t {
        value: 0.0,
        desc: env_fp8_src,
    };
    let ff_a16: *mut flexfloat_t = &mut flexfloat_t {
        value: 0.0,
        desc: env_fp16_src,
    };
    let ff_res: *mut flexfloat_t = &mut flexfloat_t {
        value: 0.0,
        desc: env_fp64,
    };

    flexfloat_set_bits(ff_a8, rs1 as u64);
    flexfloat_set_bits(ff_a16, rs1 as u64);

    match op {
        FfOpCvt::Fcvt8f2f => ff_cast(ff_res, ff_a8, env_fp64),
        FfOpCvt::Fcvt16f2f => ff_cast(ff_res, ff_a16, env_fp64),
        _ => (),
    };

    let rd = flexfloat_get_bits(ff_res);
    rd as u64
}

/// fp8 and fp8alt comparison instruction emulation
pub unsafe fn ff_instruction_cmp_b(rs1: u8, rs2: u8, op: FlexfloatOpCmp, fpmode_dst: bool) -> bool {
    let env_fp8_dst: flexfloat_desc_t = if fpmode_dst { env_fp8alt } else { env_fp8 };

    let ff_a: *mut flexfloat_t = &mut flexfloat_t {
        value: 0.0,
        desc: env_fp8_dst,
    };
    let ff_b: *mut flexfloat_t = &mut flexfloat_t {
        value: 0.0,
        desc: env_fp8_dst,
    };

    flexfloat_set_bits(ff_a, rs1 as u64);
    flexfloat_set_bits(ff_b, rs2 as u64);

    let res: bool = match op {
        FlexfloatOpCmp::Feq => ff_eq(ff_a, ff_b), // 1 or 0 to int reg (32bit)
        FlexfloatOpCmp::Flt => ff_lt(ff_a, ff_b), // 1 or 0 to int reg (32bit)
        FlexfloatOpCmp::Fle => ff_le(ff_a, ff_b), // 1 or 0 to int reg (32bit)
        FlexfloatOpCmp::Fge => ff_ge(ff_a, ff_b), // 1 or 0 to int reg (32bit)
        FlexfloatOpCmp::Fgt => ff_gt(ff_a, ff_b), // 1 or 0 to int reg (32bit)
        FlexfloatOpCmp::Fne => ff_neq(ff_a, ff_b), // 1 or 0 to int reg (32bit)
    };

    res
}

/// fp16 and fp16alt comparison instruction emulation
pub unsafe fn ff_instruction_cmp_h(
    rs1: u16,
    rs2: u16,
    op: FlexfloatOpCmp,
    fpmode_dst: bool,
) -> bool {
    let env_fp16_dst: flexfloat_desc_t = if fpmode_dst { env_fp16alt } else { env_fp16 };

    let ff_a: *mut flexfloat_t = &mut flexfloat_t {
        value: 0.0,
        desc: env_fp16_dst,
    };
    let ff_b: *mut flexfloat_t = &mut flexfloat_t {
        value: 0.0,
        desc: env_fp16_dst,
    };

    flexfloat_set_bits(ff_a, rs1 as u64);
    flexfloat_set_bits(ff_b, rs2 as u64);

    let res: bool = match op {
        FlexfloatOpCmp::Feq => ff_eq(ff_a, ff_b), // 1 or 0 to int reg (32bit)
        FlexfloatOpCmp::Flt => ff_lt(ff_a, ff_b), // 1 or 0 to int reg (32bit)
        FlexfloatOpCmp::Fle => ff_le(ff_a, ff_b), // 1 or 0 to int reg (32bit)
        FlexfloatOpCmp::Fge => ff_ge(ff_a, ff_b), // 1 or 0 to int reg (32bit)
        FlexfloatOpCmp::Fgt => ff_gt(ff_a, ff_b), // 1 or 0 to int reg (32bit)
        FlexfloatOpCmp::Fne => ff_neq(ff_a, ff_b), // 1 or 0 to int reg (32bit)
    };

    res
}

/// fp8 and fp8alt instruction emulation
pub unsafe fn ff_instruction_b(rs1: u8, rs2: u8, rs3: u8, op: FlexfloatOp, fpmode_dst: bool) -> u8 {
    let env: flexfloat_desc_t = if fpmode_dst { env_fp8alt } else { env_fp8 };

    let ff_a: *mut flexfloat_t = if fpmode_dst {
        &mut flexfloat_t {
            value: 0.0,
            desc: env_fp8alt,
        }
    } else {
        &mut flexfloat_t {
            value: 0.0,
            desc: env_fp8,
        }
    };

    let ff_b: *mut flexfloat_t = if fpmode_dst {
        &mut flexfloat_t {
            value: 0.0,
            desc: env_fp8alt,
        }
    } else {
        &mut flexfloat_t {
            value: 0.0,
            desc: env_fp8,
        }
    };

    let ff_c: *mut flexfloat_t = if fpmode_dst {
        &mut flexfloat_t {
            value: 0.0,
            desc: env_fp8alt,
        }
    } else {
        &mut flexfloat_t {
            value: 0.0,
            desc: env_fp8,
        }
    };

    let ff_res: *mut flexfloat_t = if fpmode_dst {
        &mut flexfloat_t {
            value: 0.0,
            desc: env_fp8alt,
        }
    } else {
        &mut flexfloat_t {
            value: 0.0,
            desc: env_fp8,
        }
    };

    let ff_zero: *mut flexfloat_t = if fpmode_dst {
        &mut flexfloat_t {
            value: 0.0,
            desc: env_fp8alt,
        }
    } else {
        &mut flexfloat_t {
            value: 0.0,
            desc: env_fp8,
        }
    };

    let ff_tmp: *mut flexfloat_t = &mut flexfloat_t {
        value: 0.0,
        desc: env_fp64,
    };
    flexfloat_set_bits(ff_a, rs1 as u64);
    flexfloat_set_bits(ff_b, rs2 as u64);
    flexfloat_set_bits(ff_c, rs3 as u64);

    match op {
        FlexfloatOp::Fmadd => ff_fma(ff_res, ff_a, ff_b, ff_c),
        FlexfloatOp::Fmsub => {
            ff_inverse(ff_c, ff_c);
            ff_fma(ff_res, ff_a, ff_b, ff_c);
        }
        FlexfloatOp::Fnmadd => {
            ff_fma(ff_res, ff_a, ff_b, ff_c);
            ff_inverse(ff_res, ff_res);
        }
        FlexfloatOp::Fnmsub => {
            ff_inverse(ff_a, ff_a);
            ff_fma(ff_res, ff_a, ff_b, ff_c);
        }
        FlexfloatOp::Fadd => ff_add(ff_res, ff_a, ff_b),
        FlexfloatOp::Fsub => ff_sub(ff_res, ff_a, ff_b),
        FlexfloatOp::Fmul => ff_mul(ff_res, ff_a, ff_b),
        FlexfloatOp::Fdiv => ff_div(ff_res, ff_a, ff_b),
        FlexfloatOp::Fmin => ff_min(ff_res, ff_a, ff_b), // 1 or 0 to int reg
        FlexfloatOp::Fmax => ff_max(ff_res, ff_a, ff_b), // 1 or 0 to int reg
        FlexfloatOp::Fsgnj => {
            let res: u64 = flexfloat_pack_custom(
                env,
                ff_lt(ff_b, ff_zero),
                flexfloat_exp(ff_a),
                flexfloat_frac(ff_a),
            );
            flexfloat_set_bits(ff_tmp, res as u64);
            ff_cast(ff_res, ff_tmp, env);
        }
        FlexfloatOp::Fsgnjn => {
            let res: u64 = flexfloat_pack_custom(
                env,
                !ff_lt(ff_b, ff_zero),
                flexfloat_exp(ff_a),
                flexfloat_frac(ff_a),
            );
            flexfloat_set_bits(ff_tmp, res as u64);
            ff_cast(ff_res, ff_tmp, env);
        }
        FlexfloatOp::Fsgnjx => {
            let res: u64 = flexfloat_pack_custom(
                env,
                ff_lt(ff_b, ff_zero) ^ ff_lt(ff_a, ff_zero),
                flexfloat_exp(ff_a),
                flexfloat_frac(ff_a),
            );
            flexfloat_set_bits(ff_tmp, res as u64);
            ff_cast(ff_res, ff_tmp, env);
        }
    };

    let rd = flexfloat_get_bits(ff_res);
    rd as u8
}

/// fp16 and fp16alt instruction emulation
pub unsafe fn ff_instruction_h(
    rs1: u16,
    rs2: u16,
    rs3: u16,
    op: FlexfloatOp,
    fpmode_dst: bool,
) -> u16 {
    let env: flexfloat_desc_t = if fpmode_dst { env_fp16alt } else { env_fp16 };

    let ff_a: *mut flexfloat_t = if fpmode_dst {
        &mut flexfloat_t {
            value: 0.0,
            desc: env_fp16alt,
        }
    } else {
        &mut flexfloat_t {
            value: 0.0,
            desc: env_fp16,
        }
    };

    let ff_b: *mut flexfloat_t = if fpmode_dst {
        &mut flexfloat_t {
            value: 0.0,
            desc: env_fp16alt,
        }
    } else {
        &mut flexfloat_t {
            value: 0.0,
            desc: env_fp16,
        }
    };

    let ff_c: *mut flexfloat_t = if fpmode_dst {
        &mut flexfloat_t {
            value: 0.0,
            desc: env_fp16alt,
        }
    } else {
        &mut flexfloat_t {
            value: 0.0,
            desc: env_fp16,
        }
    };

    let ff_res: *mut flexfloat_t = if fpmode_dst {
        &mut flexfloat_t {
            value: 0.0,
            desc: env_fp16alt,
        }
    } else {
        &mut flexfloat_t {
            value: 0.0,
            desc: env_fp16,
        }
    };

    let ff_zero: *mut flexfloat_t = if fpmode_dst {
        &mut flexfloat_t {
            value: 0.0,
            desc: env_fp16alt,
        }
    } else {
        &mut flexfloat_t {
            value: 0.0,
            desc: env_fp16,
        }
    };

    let ff_tmp: *mut flexfloat_t = &mut flexfloat_t {
        value: 0.0,
        desc: env_fp64,
    };

    flexfloat_set_bits(ff_a, rs1 as u64);
    flexfloat_set_bits(ff_b, rs2 as u64);
    flexfloat_set_bits(ff_c, rs3 as u64);

    match op {
        FlexfloatOp::Fmadd => ff_fma(ff_res, ff_a, ff_b, ff_c),
        FlexfloatOp::Fmsub => {
            ff_inverse(ff_c, ff_c);
            ff_fma(ff_res, ff_a, ff_b, ff_c);
        }
        FlexfloatOp::Fnmadd => {
            ff_fma(ff_res, ff_a, ff_b, ff_c);
            ff_inverse(ff_res, ff_res);
        }
        FlexfloatOp::Fnmsub => {
            ff_inverse(ff_a, ff_a);
            ff_fma(ff_res, ff_a, ff_b, ff_c);
        }
        FlexfloatOp::Fadd => ff_add(ff_res, ff_a, ff_b),
        FlexfloatOp::Fsub => ff_sub(ff_res, ff_a, ff_b),
        FlexfloatOp::Fmul => ff_mul(ff_res, ff_a, ff_b),
        FlexfloatOp::Fdiv => ff_div(ff_res, ff_a, ff_b),
        FlexfloatOp::Fmin => ff_min(ff_res, ff_a, ff_b), // 1 or 0 to int reg
        FlexfloatOp::Fmax => ff_max(ff_res, ff_a, ff_b), // 1 or 0 to int reg
        FlexfloatOp::Fsgnj => {
            let res: u64 = flexfloat_pack_custom(
                env,
                ff_lt(ff_b, ff_zero),
                flexfloat_exp(ff_a),
                flexfloat_frac(ff_a),
            );
            flexfloat_set_bits(ff_tmp, res as u64);
            ff_cast(ff_res, ff_tmp, env);
        }
        FlexfloatOp::Fsgnjn => {
            let res: u64 = flexfloat_pack_custom(
                env,
                !ff_lt(ff_b, ff_zero),
                flexfloat_exp(ff_a),
                flexfloat_frac(ff_a),
            );
            flexfloat_set_bits(ff_tmp, res as u64);
            ff_cast(ff_res, ff_tmp, env);
        }
        FlexfloatOp::Fsgnjx => {
            let res: u64 = flexfloat_pack_custom(
                env,
                ff_lt(ff_b, ff_zero) ^ ff_lt(ff_a, ff_zero),
                flexfloat_exp(ff_a),
                flexfloat_frac(ff_a),
            );
            flexfloat_set_bits(ff_tmp, res as u64);
            ff_cast(ff_res, ff_tmp, env);
        }
    };

    let rd = flexfloat_get_bits(ff_res);
    rd as u16
}

// fp16 to fp32 expansion instructions
pub unsafe fn ff_fp16_to_fp32_op(
    rs1: u16,
    rs2: u16,
    rs3: f32,
    op: FlexfloatOpExp,
    fpmode_src: bool,
) -> f32 {
    let env: flexfloat_desc_t = if fpmode_src { env_fp16alt } else { env_fp16 };

    let ff_a: *mut flexfloat_t = &mut flexfloat_t {
        value: 0.0,
        desc: env,
    };

    let ff_b: *mut flexfloat_t = &mut flexfloat_t {
        value: 0.0,
        desc: env,
    };
    let ff_c: *mut flexfloat_t = &mut flexfloat_t {
        value: 0.0,
        desc: env_fp32,
    };

    let ff_res: *mut flexfloat_t = &mut flexfloat_t {
        value: 0.0,
        desc: env_fp32,
    };

    flexfloat_set_bits(ff_a, rs1 as u64);
    flexfloat_set_bits(ff_b, rs2 as u64);
    ff_init_float(ff_c, rs3, env_fp32);

    match op {
        FlexfloatOpExp::FaddexSH => ff_add_any(ff_res, ff_a, ff_b),
        FlexfloatOpExp::FmulexSH => ff_mul_any(ff_res, ff_a, ff_b),
        FlexfloatOpExp::FmacexSH => ff_fma_any(ff_res, ff_a, ff_b, ff_c),
        _ => (),
    };

    let rd = ff_get_float(ff_res);
    rd as f32
}

// fp8 to fp16 expansion instructions
pub unsafe fn ff_fp8_to_fp16_op(
    rs1: u8,
    rs2: u8,
    rs3: u16,
    op: FlexfloatOpExp,
    fpmode_src: bool,
    fpmode_dst: bool,
) -> u16 {
    let env8: flexfloat_desc_t = if fpmode_src { env_fp8alt } else { env_fp8 };

    let env16: flexfloat_desc_t = if fpmode_dst { env_fp16alt } else { env_fp16 };

    let ff_a: *mut flexfloat_t = &mut flexfloat_t {
        value: 0.0,
        desc: env8,
    };

    let ff_b: *mut flexfloat_t = &mut flexfloat_t {
        value: 0.0,
        desc: env8,
    };
    let ff_c: *mut flexfloat_t = &mut flexfloat_t {
        value: 0.0,
        desc: env16,
    };

    let ff_res: *mut flexfloat_t = &mut flexfloat_t {
        value: 0.0,
        desc: env16,
    };

    flexfloat_set_bits(ff_a, rs1 as u64);
    flexfloat_set_bits(ff_b, rs2 as u64);
    flexfloat_set_bits(ff_c, rs3 as u64);

    match op {
        FlexfloatOpExp::FaddexHB => ff_add_any(ff_res, ff_a, ff_b),
        FlexfloatOpExp::FmulexHB => ff_mul_any(ff_res, ff_a, ff_b),
        FlexfloatOpExp::FmacexHB => ff_fma_any(ff_res, ff_a, ff_b, ff_c),
        _ => (),
    };

    let rd = flexfloat_get_bits(ff_res);
    rd as u16
}

pub unsafe fn ff_fp8_to_fp32_op(
    rs1: u8,
    rs2: u8,
    _rs3: f32,
    op: FlexfloatOpExp,
    fpmode_src: bool,
) -> f32 {
    let env8: flexfloat_desc_t = if fpmode_src { env_fp8alt } else { env_fp8 };

    let ff_a: *mut flexfloat_t = &mut flexfloat_t {
        value: 0.0,
        desc: env8,
    };

    let ff_b: *mut flexfloat_t = &mut flexfloat_t {
        value: 0.0,
        desc: env8,
    };
    // let ff_c : *mut flexfloat_t = &mut flexfloat_t {
    //         value: 0.0,
    //         desc: env_fp32
    // };

    let ff_res: *mut flexfloat_t = &mut flexfloat_t {
        value: 0.0,
        desc: env_fp32,
    };

    flexfloat_set_bits(ff_a, rs1 as u64);
    flexfloat_set_bits(ff_b, rs2 as u64);

    match op {
        FlexfloatOpExp::FmulexSB => ff_mul_any(ff_res, ff_a, ff_b),
        _ => (),
    };

    let rd = ff_get_float(ff_res);
    rd as f32
}
/// convert double to int
pub unsafe fn double_to_int(dbl_orig: f64) -> i32 {
    let dbl: f64 = if dbl_orig >= 0.0 {
        dbl_orig.floor()
    } else {
        dbl_orig.ceil()
    };
    if dbl < 2.0 * ((INT32_MAX / 2 + 1) as f64) {
        // NO OVERFLOW
        if dbl.ceil() >= (INT32_MIN as f64) {
            // NO UNDERFLOW
            dbl as i32
        } else {
            // UNDERFLOW
            INT32_MIN as i32
        }
    } else {
        // OVERFLOW OR NAN
        INT32_MAX as i32
    }
}

/// convert double to uint
pub unsafe fn double_to_uint(dbl_orig: f64) -> u32 {
    let dbl: f64 = if dbl_orig >= 0.0 {
        dbl_orig.floor()
    } else {
        dbl_orig.ceil()
    };
    if dbl < 2.0 * ((UINT32_MAX / 2 + 1) as f64) {
        // NO OVERFLOW
        if dbl.ceil() >= 0.0 {
            // NO UNDERFLOW
            dbl as u32
        } else {
            // UNDERFLOW
            0
        }
    } else {
        // OVERFLOW OR NAN
        UINT32_MAX as u32
    }
}

/// custom flexfloat pack function
pub unsafe fn flexfloat_pack_custom(
    desc: flexfloat_desc_t,
    sign: bool,
    exp: int_fast16_t,
    frac: uint_t,
) -> u64 {
    let bias: int_fast16_t = flexfloat_bias_custom(desc);
    let inf_exp: int_fast16_t = flexfloat_inf_exp_custom(desc);

    let exp: int_fast16_t = if exp == inf_exp
    // Inf or NaN
    {
        INF_EXP as int_fast16_t
    } else {
        ((exp - bias) + (BIAS as i64)) as int_fast16_t
    };
    let tmp1 = (sign as uint_t) << (NUM_BITS - 1) as uint_t;
    let tmp2 = ((exp as uint_t) << NUM_BITS_FRAC) as uint_t;
    let tmp3 = ((frac as u64) << ((NUM_BITS_FRAC as u64) - (desc.frac_bits as u64))) as uint_t;
    let res: u64 = (tmp1 as u64) + (tmp2 as u64) + (tmp3 as u64);
    res
}

/// compute the bias for a flexfloat format
pub unsafe fn flexfloat_bias_custom(desc: flexfloat_desc_t) -> int_fast16_t {
    let tmp1: int_fast16_t = ((1 as int_fast16_t) << (desc.exp_bits - 1)) as int_fast16_t;
    let tmp2: int_fast16_t = (tmp1 - 1) as int_fast16_t;
    tmp2
}

/// compute the inf exponent for a flexfloat format
pub unsafe fn flexfloat_inf_exp_custom(desc: flexfloat_desc_t) -> int_fast16_t {
    let tmp1: int_fast16_t = ((1 as int_fast16_t) << desc.exp_bits) as int_fast16_t;
    let tmp2: int_fast16_t = (tmp1 - 1) as int_fast16_t;
    tmp2
}
