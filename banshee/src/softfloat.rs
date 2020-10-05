//! Berkeley SoftFloat bindings.
//!
//! These are partial bindings, and only part of the SoftFloat package is actually linked into the
//! library. Some of the names have been altered to be more in line with Rust naming.

// This file is modified from bindings generated by `bindgen` based on
// `softfloat.h`. It contains only the parts we use.

#![allow(dead_code)]

use std::mem::transmute;

/// Round to nearest, ties to even.
pub const ROUND_NEAR_EVEN: u8 = 0;
/// Round towards 0.
pub const ROUND_MIN_MAG: u8 = 1;
/// Round towards -∞.
pub const ROUND_MIN: u8 = 2;
/// Round towards +∞.
pub const ROUND_MAX: u8 = 3;
/// Round to nearest, ties away from 0.
pub const ROUND_NEAR_MAXMAG: u8 = 4;

/// Inexact result exception.
pub const FLAG_INEXACT: u8 = 1;
/// Underflow exception.
pub const FLAG_UNDERFLOW: u8 = 2;
/// Overflow exception.
pub const FLAG_OVERFLOW: u8 = 4;
/// Result is infinity (division by zero).
pub const FLAG_INFINITE: u8 = 8;
/// Invalid operation (result is NaN).
pub const FLAG_INVALID: u8 = 16;

/// A single-precision soft-float. Internally represented as `u32`.
///
/// With the `serialize` crate feature, this structure is serializable using Serde.
#[repr(C)]
#[derive(Clone, Copy, Debug)]
#[cfg_attr(feature = "serialize", derive(Serialize, Deserialize))]
pub struct Sf32(pub u32);

impl Sf32 {
    /// The canonical NaN value.
    pub const NAN: Sf32 = Sf32(0x7fc0_0000);

    /// Negate the value / flip the sign bit.
    pub fn negate(self) -> Sf32 {
        Sf32(self.0 ^ 0x8000_0000)
    }
}

impl From<f32> for Sf32 {
    /// Conversion that simply transmutes the value.
    fn from(x: f32) -> Sf32 {
        unsafe { transmute(x) }
    }
}

impl From<Sf32> for f32 {
    /// Conversion that simply transmutes the value.
    fn from(x: Sf32) -> f32 {
        unsafe { transmute(x) }
    }
}

/// A double-precision soft-float. Internally represented as `u64`.
///
/// With the `serialize` crate feature, this structure is serializable using Serde.
#[repr(C)]
#[derive(Clone, Copy, Debug)]
#[cfg_attr(feature = "serialize", derive(Serialize, Deserialize))]
pub struct Sf64(pub u64);

impl Sf64 {
    /// The canonical NaN value.
    pub const NAN: Sf64 = Sf64(0x7ff8_0000_0000_0000);

    /// Negate the value / flip the sign bit.
    pub fn negate(self) -> Sf64 {
        Sf64(self.0 ^ 0x8000_0000_0000_0000)
    }
}

impl From<f64> for Sf64 {
    /// Conversion that simply transmutes the value.
    fn from(x: f64) -> Sf64 {
        unsafe { transmute(x) }
    }
}

impl From<Sf64> for f64 {
    /// Conversion that simply transmutes the value.
    fn from(x: Sf64) -> f64 {
        unsafe { transmute(x) }
    }
}

impl From<Sf32> for Sf64 {
    /// Conversion that adds NaN-boxing.
    fn from(x: Sf32) -> Sf64 {
        Sf64(0xffff_ffff_0000_0000 | u64::from(x.0))
    }
}

impl From<Sf64> for Sf32 {
    /// Conversion that discards the upper-bits, which are assumed to be NaN-boxing.
    fn from(x: Sf64) -> Sf32 {
        Sf32(x.0 as u32)
    }
}

impl From<f32> for Sf64 {
    /// Conversion that transmutes the value, then adds NaN-boxing.
    fn from(x: f32) -> Sf64 {
        Sf32::from(x).into()
    }
}

impl From<Sf64> for f32 {
    /// Conversion that discards the upper-bits, which are assumed to be NaN-boxing, then
    /// transmutes the value.
    fn from(x: Sf64) -> f32 {
        Sf32::from(x).into()
    }
}

extern "C" {
    /// Get the exception flags from thread-local storage.
    #[link_name = "softfloat_getFlags"]
    pub fn get_flags() -> u8;
    /// Set the exception flags.
    #[link_name = "softfloat_setFlags"]
    pub fn set_flags(arg1: u8);
    /// Add to the exception flags.
    #[link_name = "softfloat_raiseFlags"]
    pub fn raise_flags(arg1: u8);

    /// Get the current rounding mode from thread-local storage.
    #[link_name = "softfloat_getRoundingMode"]
    pub fn get_rounding_mode() -> u8;
    /// Set the rounding mode.
    #[link_name = "softfloat_setRoundingMode"]
    pub fn set_rounding_mode(arg1: u8);

    /// Convert a `u32` to a single-precision value.
    #[link_name = "ui32_to_f32"]
    pub fn u32_to_f32(arg1: u32) -> Sf32;
    /// Convert a `u32` to a double-precision value.
    #[link_name = "ui32_to_f64"]
    pub fn u32_to_f64(arg1: u32) -> Sf64;
    /// Convert an `i32` to a single-precision value.
    pub fn i32_to_f32(arg1: i32) -> Sf32;
    /// Convert an `i32` to a double-precision value.
    pub fn i32_to_f64(arg1: i32) -> Sf64;

    /// Convert a single-precision value to a `u32`.
    #[link_name = "f32_to_ui32"]
    pub fn f32_to_u32(arg1: Sf32, arg2: u8, arg3: bool) -> u32;
    /// Convert a single-precision value to an `i32`.
    pub fn f32_to_i32(arg1: Sf32, arg2: u8, arg3: bool) -> i32;
    /// Convert a single-precision value to a double-precision value.
    pub fn f32_to_f64(arg1: Sf32) -> Sf64;
    /// Addition with single-precision values.
    pub fn f32_add(arg1: Sf32, arg2: Sf32) -> Sf32;
    /// Subtraction with single-precision values.
    pub fn f32_sub(arg1: Sf32, arg2: Sf32) -> Sf32;
    /// Multiplication with single-precision values.
    pub fn f32_mul(arg1: Sf32, arg2: Sf32) -> Sf32;
    /// Fused multiplication and addition with single-precision values.
    pub fn f32_mulAdd(arg1: Sf32, arg2: Sf32, arg3: Sf32) -> Sf32;
    /// Division with single-precision values.
    pub fn f32_div(arg1: Sf32, arg2: Sf32) -> Sf32;
    /// Modulus / remainder with single-precision values.
    pub fn f32_rem(arg1: Sf32, arg2: Sf32) -> Sf32;
    /// Square root of a single-precision value.
    pub fn f32_sqrt(arg1: Sf32) -> Sf32;
    /// Test equality with single-precision values.
    pub fn f32_eq(arg1: Sf32, arg2: Sf32) -> bool;
    /// Test less-than-or-equal with single-precision values.
    pub fn f32_le(arg1: Sf32, arg2: Sf32) -> bool;
    /// Test less-than with single-precision values.
    pub fn f32_lt(arg1: Sf32, arg2: Sf32) -> bool;
    /// Whether the single-precision value is a signalling NaN.
    #[link_name = "f32_isSignalingNaN"]
    pub fn f32_is_signaling_nan(arg1: Sf32) -> bool;

    /// Convert a double-precision value to a `u32`.
    #[link_name = "f64_to_ui32"]
    pub fn f64_to_u32(arg1: Sf64, arg2: u8, arg3: bool) -> u32;
    /// Convert a double-precision value to an `i32`.
    pub fn f64_to_i32(arg1: Sf64, arg2: u8, arg3: bool) -> i32;
    /// Convert a double-precision value to a single-precision value.
    pub fn f64_to_f32(arg1: Sf64) -> Sf32;
    /// Addition with double-precision values.
    pub fn f64_add(arg1: Sf64, arg2: Sf64) -> Sf64;
    /// Subtraction with double-precision values.
    pub fn f64_sub(arg1: Sf64, arg2: Sf64) -> Sf64;
    /// Multiplication with double-precision values.
    pub fn f64_mul(arg1: Sf64, arg2: Sf64) -> Sf64;
    /// Fused multiplication and addition with double-precision values.
    pub fn f64_mulAdd(arg1: Sf64, arg2: Sf64, arg3: Sf64) -> Sf64;
    /// Division with double-precision values.
    pub fn f64_div(arg1: Sf64, arg2: Sf64) -> Sf64;
    /// Modulus / remainder with double-precision values.
    pub fn f64_rem(arg1: Sf64, arg2: Sf64) -> Sf64;
    /// Square root of a double-precision value.
    pub fn f64_sqrt(arg1: Sf64) -> Sf64;
    /// Test equality with double-precision values.
    pub fn f64_eq(arg1: Sf64, arg2: Sf64) -> bool;
    /// Test less-than-or-equal with double-precision values.
    pub fn f64_le(arg1: Sf64, arg2: Sf64) -> bool;
    /// Test less-than with double-precision values.
    pub fn f64_lt(arg1: Sf64, arg2: Sf64) -> bool;
    /// Whether the double-precision value is a signalling NaN.
    #[link_name = "f64_isSignalingNaN"]
    pub fn f64_is_signaling_nan(arg1: Sf64) -> bool;
}
