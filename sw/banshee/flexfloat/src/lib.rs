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
pub enum FlexfloatOpCvt {
    Fmvx2f,
    // Fmvf2x,
    Fcvtw2f,
    Fcvtwu2f,
    // Fcvtf2u,
    // Fcvtf2wu,
    // FcpkAhS,
    // FcpkAhD,
    FcpkS2,
    FcpkD2,
}

#[derive(Debug, Clone, Copy)]
#[repr(C)]
pub enum FlexfloatOpCmp {
    Feq,
    Flt,
    Fle,
    Fge,
    Fgt,
    Fne
}

/// return the sign of the flexfloat
pub fn flexfloat_sign(a: *const flexfloat_t) -> bool
{
    unsafe{
        (ff_get_double(a) as u64 >> (NUM_BITS-1)) != 0
    }
}

/// fp8 and fp8alt conversion instruction emulation
pub unsafe fn ff_instruction_cvt_b(rs1: u64, op: FlexfloatOpCvt, alt: bool) -> u8 {

    let env_dst : flexfloat_desc_t = if alt {
        env_fp8alt
    } else {
        env_fp8
    };

    let ff_a8: *mut flexfloat_t = &mut flexfloat_t {
        value: 0.0,
        desc: env_dst
    };
    let ff_a32: *mut flexfloat_t = &mut flexfloat_t {
        value: 0.0,
        desc: env_fp32
    };
    let ff_a64: *mut flexfloat_t = &mut flexfloat_t {
        value: 0.0,
        desc: env_fp64
    };
    let ff_res: *mut flexfloat_t = &mut flexfloat_t {
        value: 0.0,
        desc: env_dst
    };

    flexfloat_set_bits(ff_a8, rs1 as u64);
    flexfloat_set_bits(ff_a32, rs1 as u64);
    flexfloat_set_bits(ff_a64, rs1 as u64);

    match op {
        FlexfloatOpCvt::FcpkS2   => ff_cast(ff_res, ff_a32, env_dst),
        FlexfloatOpCvt::FcpkD2   => ff_cast(ff_res, ff_a64, env_dst),
        FlexfloatOpCvt::Fmvx2f   => ff_cast(ff_res, ff_a8, env_dst),
        // FlexfloatOpCvt::Fmvf2x   => ff_cast(ff_res, ff_a, env_dst),
        FlexfloatOpCvt::Fcvtw2f  => ff_cast(ff_res, ff_a32, env_dst),
        FlexfloatOpCvt::Fcvtwu2f => ff_cast(ff_res, ff_a32, env_dst),
        // FlexfloatOpCvt::Fcvtf2u  => ff_cast(ff_res, ff_a, env_dst),
        // FlexfloatOpCvt::Fcvtf2wu => ff_cast(ff_res, ff_a16, env_dst),
    };

    let rd = flexfloat_get_bits(ff_res);
    rd as u8
}

/// fp16 and fp16alt conversion instruction emulation
pub unsafe fn ff_instruction_cvt_h(rs1: u64, op: FlexfloatOpCvt, alt: bool) -> u16 {

    let env_dst : flexfloat_desc_t = if alt {
        env_fp16alt
    } else {
        env_fp16
    };

    let ff_a16: *mut flexfloat_t = &mut flexfloat_t {
        value: 0.0,
        desc: env_dst
    };
    let ff_a32: *mut flexfloat_t = &mut flexfloat_t {
        value: 0.0,
        desc: env_fp32
    };
    let ff_a64: *mut flexfloat_t = &mut flexfloat_t {
        value: 0.0,
        desc: env_fp64
    };
    let ff_res: *mut flexfloat_t = &mut flexfloat_t {
        value: 0.0,
        desc: env_dst
    };

    flexfloat_set_bits(ff_a16, rs1 as u64);
    flexfloat_set_bits(ff_a32, rs1 as u64);
    flexfloat_set_bits(ff_a64, rs1 as u64);

    match op {
        FlexfloatOpCvt::FcpkS2   => ff_cast(ff_res, ff_a32, env_dst),
        FlexfloatOpCvt::FcpkD2   => ff_cast(ff_res, ff_a64, env_dst),
        FlexfloatOpCvt::Fmvx2f   => ff_cast(ff_res, ff_a16, env_dst),
        // FlexfloatOpCvt::Fmvf2x   => ff_cast(ff_res, ff_a, env_dst),
        FlexfloatOpCvt::Fcvtw2f  => ff_cast(ff_res, ff_a32, env_dst),
        FlexfloatOpCvt::Fcvtwu2f => ff_cast(ff_res, ff_a32, env_dst),
        // FlexfloatOpCvt::Fcvtf2u  => ff_cast(ff_res, ff_a, env_dst),
        // FlexfloatOpCvt::Fcvtf2wu => ff_cast(ff_res, ff_a16, env_dst),
    };

    let rd = flexfloat_get_bits(ff_res);
    rd as u16
}

/// fp8 and fp8alt comparison instruction emulation
pub unsafe fn ff_instruction_cmp_b(rs1: u8, rs2: u8, op: FlexfloatOpCmp, alt: bool) -> bool {

    let ff_a : *mut flexfloat_t = if alt {
        &mut flexfloat_t {
            value: 0.0,
            desc: env_fp8alt
        }
    } else {
        &mut flexfloat_t {
            value: 0.0,
            desc: env_fp8
        }
    };

    let ff_b : *mut flexfloat_t = if alt {
        &mut flexfloat_t {
            value: 0.0,
            desc: env_fp8alt
        }
    } else {
        &mut flexfloat_t {
            value: 0.0,
            desc: env_fp8
        }
    };

    flexfloat_set_bits(ff_a, rs1 as u64);
    flexfloat_set_bits(ff_b, rs2 as u64);

    let res : bool = match op {
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
pub unsafe fn ff_instruction_cmp_h(rs1: u16, rs2: u16, op: FlexfloatOpCmp, alt: bool) -> bool {

    let ff_a : *mut flexfloat_t = if alt {
        &mut flexfloat_t {
            value: 0.0,
            desc: env_fp16alt
        }
    } else {
        &mut flexfloat_t {
            value: 0.0,
            desc: env_fp16
        }
    };

    let ff_b : *mut flexfloat_t = if alt {
        &mut flexfloat_t {
            value: 0.0,
            desc: env_fp16alt
        }
    } else {
        &mut flexfloat_t {
            value: 0.0,
            desc: env_fp16
        }
    };

    flexfloat_set_bits(ff_a, rs1 as u64);
    flexfloat_set_bits(ff_b, rs2 as u64);

    let res : bool = match op {
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
pub unsafe fn ff_instruction_b(rs1: u8, rs2: u8, rs3: u8, op: FlexfloatOp, alt: bool) -> u8 {

    let ff_a : *mut flexfloat_t = if alt {
        &mut flexfloat_t {
            value: 0.0,
            desc: env_fp8alt
        }
    } else {
        &mut flexfloat_t {
            value: 0.0,
            desc: env_fp8
        }
    };

    let ff_b : *mut flexfloat_t = if alt {
        &mut flexfloat_t {
            value: 0.0,
            desc: env_fp8alt
        }
    } else {
        &mut flexfloat_t {
            value: 0.0,
            desc: env_fp8
        }
    };

    let ff_c : *mut flexfloat_t = if alt {
        &mut flexfloat_t {
            value: 0.0,
            desc: env_fp8alt
        }
    } else {
        &mut flexfloat_t {
            value: 0.0,
            desc: env_fp8
        }
    };

    let ff_res : *mut flexfloat_t = if alt {
        &mut flexfloat_t {
            value: 0.0,
            desc: env_fp8alt
        }
    } else {
        &mut flexfloat_t {
            value: 0.0,
            desc: env_fp8
        }
    };

    flexfloat_set_bits(ff_a, rs1 as u64);
    flexfloat_set_bits(ff_b, rs2 as u64);
    flexfloat_set_bits(ff_c, rs3 as u64);

    match op {
        FlexfloatOp::Fmadd   => ff_fma(ff_res, ff_a, ff_b, ff_c),
        FlexfloatOp::Fmsub   => {
            ff_inverse(ff_c, ff_c);
            ff_fma(ff_res, ff_a, ff_b, ff_c);
        },
        FlexfloatOp::Fnmadd  => {
            ff_fma(ff_res, ff_a, ff_b, ff_c);
            ff_inverse(ff_res, ff_res);
        },
        FlexfloatOp::Fnmsub  => {
            ff_inverse(ff_a, ff_a);
            ff_fma(ff_res, ff_a, ff_b, ff_c);
        },
        FlexfloatOp::Fadd    => ff_add(ff_res, ff_a, ff_b),
        FlexfloatOp::Fsub    => ff_sub(ff_res, ff_a, ff_b),
        FlexfloatOp::Fmul    => ff_mul(ff_res, ff_a, ff_b),
        FlexfloatOp::Fdiv    => ff_div(ff_res, ff_a, ff_b),
        FlexfloatOp::Fmin    => ff_min(ff_res, ff_a, ff_b), // 1 or 0 to int reg
        FlexfloatOp::Fmax    => ff_max(ff_res, ff_a, ff_b), // 1 or 0 to int reg
        FlexfloatOp::Fsgnj   => {
            flexfloat_set_bits( ff_res,
                                           flexfloat_pack( env_fp8alt,
                                                                      flexfloat_sign(ff_b),
                                                                      flexfloat_exp(ff_a),
                                                                      flexfloat_frac(ff_a)
                                                                    ) as u64 );

        },
        FlexfloatOp::Fsgnjn  => {
            flexfloat_set_bits( ff_res,
                                           flexfloat_pack( env_fp8alt,
                                                                      !flexfloat_sign(ff_b),
                                                                      flexfloat_exp(ff_a),
                                                                      flexfloat_frac(ff_a)
                                                                    ) as u64 );
        },
        FlexfloatOp::Fsgnjx  => {
            flexfloat_set_bits( ff_res,
                                           flexfloat_pack( env_fp8alt,
                                                                      flexfloat_sign(ff_a)^flexfloat_sign(ff_b),
                                                                      flexfloat_exp(ff_a),
                                                                      flexfloat_frac(ff_a)
                                                                    ) as u64 );
        },
    };

    let rd = flexfloat_get_bits(ff_res);
    rd as u8
}


/// fp16 and fp16alt instruction emulation
pub unsafe fn ff_instruction_h(rs1: u16, rs2: u16, rs3: u16, op: FlexfloatOp, alt: bool) -> u16 {

    let ff_a : *mut flexfloat_t = if alt {
        &mut flexfloat_t {
            value: 0.0,
            desc: env_fp16alt
        }
    } else {
        &mut flexfloat_t {
            value: 0.0,
            desc: env_fp16
        }
    };

    let ff_b : *mut flexfloat_t = if alt {
        &mut flexfloat_t {
            value: 0.0,
            desc: env_fp16alt
        }
    } else {
        &mut flexfloat_t {
            value: 0.0,
            desc: env_fp16
        }
    };

    let ff_c : *mut flexfloat_t = if alt {
        &mut flexfloat_t {
            value: 0.0,
            desc: env_fp16alt
        }
    } else {
        &mut flexfloat_t {
            value: 0.0,
            desc: env_fp16
        }
    };

    let ff_res : *mut flexfloat_t = if alt {
        &mut flexfloat_t {
            value: 0.0,
            desc: env_fp16alt
        }
    } else {
        &mut flexfloat_t {
            value: 0.0,
            desc: env_fp16
        }
    };

    flexfloat_set_bits(ff_a, rs1 as u64);
    flexfloat_set_bits(ff_b, rs2 as u64);
    flexfloat_set_bits(ff_c, rs3 as u64);

    match op {
        FlexfloatOp::Fmadd   => ff_fma(ff_res, ff_a, ff_b, ff_c),
        FlexfloatOp::Fmsub   => {
            ff_inverse(ff_c, ff_c);
            ff_fma(ff_res, ff_a, ff_b, ff_c);
        },
        FlexfloatOp::Fnmadd  => {
            ff_fma(ff_res, ff_a, ff_b, ff_c);
            ff_inverse(ff_res, ff_res);
        },
        FlexfloatOp::Fnmsub  => {
            ff_inverse(ff_a, ff_a);
            ff_fma(ff_res, ff_a, ff_b, ff_c);
        },
        FlexfloatOp::Fadd    => ff_add(ff_res, ff_a, ff_b),
        FlexfloatOp::Fsub    => ff_sub(ff_res, ff_a, ff_b),
        FlexfloatOp::Fmul    => ff_mul(ff_res, ff_a, ff_b),
        FlexfloatOp::Fdiv    => ff_div(ff_res, ff_a, ff_b),
        FlexfloatOp::Fmin    => ff_min(ff_res, ff_a, ff_b), // 1 or 0 to int reg
        FlexfloatOp::Fmax    => ff_max(ff_res, ff_a, ff_b), // 1 or 0 to int reg
        FlexfloatOp::Fsgnj   => {
            flexfloat_set_bits( ff_res,
                                            flexfloat_pack( env_fp16alt,
                                                                        flexfloat_sign(ff_b),
                                                                        flexfloat_exp(ff_a),
                                                                        flexfloat_frac(ff_a)
                                                                    ) as u64 );
        },
        FlexfloatOp::Fsgnjn  => {
            flexfloat_set_bits( ff_res,
                                            flexfloat_pack( env_fp16alt,
                                                                        !flexfloat_sign(ff_b),
                                                                        flexfloat_exp(ff_a),
                                                                        flexfloat_frac(ff_a)
                                                                    ) as u64 );
        },
        FlexfloatOp::Fsgnjx  => {
            flexfloat_set_bits( ff_res,
                                            flexfloat_pack( env_fp16alt,
                                                                        flexfloat_sign(ff_a)^flexfloat_sign(ff_b),
                                                                        flexfloat_exp(ff_a),
                                                                        flexfloat_frac(ff_a)
                                                                    ) as u64 );
        },
    };

    let rd = flexfloat_get_bits(ff_res);
    rd as u16
}
