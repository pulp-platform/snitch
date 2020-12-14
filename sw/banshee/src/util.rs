// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

//! Utilities

/// Convenient SI-prefixed unit formatting.
pub trait SiUnit {
    fn si_unit<'a>(&'a self, unit: &'a str) -> SiUnitDisplay<'a, Self> {
        self.si_unit_prec(unit, 3)
    }

    fn si_unit_prec<'a>(&'a self, unit: &'a str, prec: usize) -> SiUnitDisplay<'a, Self>;
}

pub struct SiUnitDisplay<'a, T: ?Sized>(&'a T, &'a str, usize);

impl<T> SiUnit for T {
    fn si_unit_prec<'a>(&'a self, unit: &'a str, prec: usize) -> SiUnitDisplay<'a, Self> {
        SiUnitDisplay(self, unit, prec)
    }
}

impl<T> std::fmt::Display for SiUnitDisplay<'_, T>
where
    T: std::str::FromStr
        + std::fmt::Display
        + std::ops::Mul<Output = T>
        + std::ops::Div<Output = T>
        + std::ops::Neg<Output = T>
        + PartialOrd
        + Clone,
    <T as std::str::FromStr>::Err: std::fmt::Debug,
{
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        let oom: T = "1000".parse().unwrap();
        let one: T = "1".parse().unwrap();
        let zero: T = "0".parse().unwrap();
        let (neg, mut value) = if self.0.clone() < zero.clone() {
            (true, -self.0.clone())
        } else {
            (false, self.0.clone())
        };
        if value.clone() >= oom.clone() {
            let mut prefices = ["k", "M", "G", "T", "P", "E"].iter();
            let mut prefix = prefices.next().unwrap();
            value = value / oom.clone();
            for p in prefices {
                if value.clone() < oom.clone() {
                    break;
                }
                prefix = p;
                value = value / oom.clone();
            }
            if neg {
                value = -value;
            }
            write!(f, "{:.width$} {}{}", value, prefix, self.1, width = self.2)
        } else if value.clone() < one.clone() && value.clone() > zero.clone() {
            let mut prefices = ["m", "µ", "n", "p", "f", "a"].iter();
            let mut prefix = prefices.next().unwrap();
            value = value * oom.clone();
            for p in prefices {
                if value.clone() >= one.clone() {
                    break;
                }
                prefix = p;
                value = value * oom.clone();
            }
            if neg {
                value = -value;
            }
            write!(f, "{:.width$} {}{}", value, prefix, self.1, width = self.2)
        } else {
            write!(f, "{:.width$} {}", self.0, self.1, width = self.2)
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn si_unit_int_pos() {
        assert_eq!(0isize.si_unit("B").to_string(), "0 B");
        assert_eq!(1isize.si_unit("B").to_string(), "1 B");
        assert_eq!(10isize.si_unit("B").to_string(), "10 B");
        assert_eq!(100isize.si_unit("B").to_string(), "100 B");
        assert_eq!(1000isize.si_unit("B").to_string(), "1 kB");
        assert_eq!(10000isize.si_unit("B").to_string(), "10 kB");
        assert_eq!(100000isize.si_unit("B").to_string(), "100 kB");
        assert_eq!(1000000isize.si_unit("B").to_string(), "1 MB");
        assert_eq!(10000000isize.si_unit("B").to_string(), "10 MB");
        assert_eq!(100000000isize.si_unit("B").to_string(), "100 MB");
        assert_eq!(1000000000isize.si_unit("B").to_string(), "1 GB");
        assert_eq!(10000000000isize.si_unit("B").to_string(), "10 GB");
        assert_eq!(100000000000isize.si_unit("B").to_string(), "100 GB");
        assert_eq!(1000000000000isize.si_unit("B").to_string(), "1 TB");
        assert_eq!(10000000000000isize.si_unit("B").to_string(), "10 TB");
        assert_eq!(100000000000000isize.si_unit("B").to_string(), "100 TB");
    }

    #[test]
    fn si_unit_int_neg() {
        assert_eq!((-1isize).si_unit("B").to_string(), "-1 B");
        assert_eq!((-10isize).si_unit("B").to_string(), "-10 B");
        assert_eq!((-100isize).si_unit("B").to_string(), "-100 B");
        assert_eq!((-1000isize).si_unit("B").to_string(), "-1 kB");
        assert_eq!((-10000isize).si_unit("B").to_string(), "-10 kB");
        assert_eq!((-100000isize).si_unit("B").to_string(), "-100 kB");
        assert_eq!((-1000000isize).si_unit("B").to_string(), "-1 MB");
        assert_eq!((-10000000isize).si_unit("B").to_string(), "-10 MB");
        assert_eq!((-100000000isize).si_unit("B").to_string(), "-100 MB");
        assert_eq!((-1000000000isize).si_unit("B").to_string(), "-1 GB");
        assert_eq!((-10000000000isize).si_unit("B").to_string(), "-10 GB");
        assert_eq!((-100000000000isize).si_unit("B").to_string(), "-100 GB");
        assert_eq!((-1000000000000isize).si_unit("B").to_string(), "-1 TB");
        assert_eq!((-10000000000000isize).si_unit("B").to_string(), "-10 TB");
        assert_eq!((-100000000000000isize).si_unit("B").to_string(), "-100 TB");
    }

    #[test]
    fn si_unit_float_pos() {
        assert_eq!(0f64.si_unit("B").to_string(), "0.000 B");
        assert_eq!(1.234e-19f64.si_unit("B").to_string(), "0.123 aB");
        assert_eq!(1.234e-18f64.si_unit("B").to_string(), "1.234 aB");
        assert_eq!(1.234e-17f64.si_unit("B").to_string(), "12.340 aB");
        assert_eq!(1.234e-16f64.si_unit("B").to_string(), "123.400 aB");
        assert_eq!(1.234e-15f64.si_unit("B").to_string(), "1.234 fB");
        assert_eq!(1.234e-14f64.si_unit("B").to_string(), "12.340 fB");
        assert_eq!(1.234e-13f64.si_unit("B").to_string(), "123.400 fB");
        assert_eq!(1.234e-12f64.si_unit("B").to_string(), "1.234 pB");
        assert_eq!(1.234e-11f64.si_unit("B").to_string(), "12.340 pB");
        assert_eq!(1.234e-10f64.si_unit("B").to_string(), "123.400 pB");
        assert_eq!(1.234e-09f64.si_unit("B").to_string(), "1.234 nB");
        assert_eq!(1.234e-08f64.si_unit("B").to_string(), "12.340 nB");
        assert_eq!(1.234e-07f64.si_unit("B").to_string(), "123.400 nB");
        assert_eq!(1.234e-06f64.si_unit("B").to_string(), "1.234 µB");
        assert_eq!(1.234e-05f64.si_unit("B").to_string(), "12.340 µB");
        assert_eq!(1.234e-04f64.si_unit("B").to_string(), "123.400 µB");
        assert_eq!(1.234e-03f64.si_unit("B").to_string(), "1.234 mB");
        assert_eq!(1.234e-02f64.si_unit("B").to_string(), "12.340 mB");
        assert_eq!(1.234e-01f64.si_unit("B").to_string(), "123.400 mB");
        assert_eq!(1.234e00f64.si_unit("B").to_string(), "1.234 B");
        assert_eq!(1.234e01f64.si_unit("B").to_string(), "12.340 B");
        assert_eq!(1.234e02f64.si_unit("B").to_string(), "123.400 B");
        assert_eq!(1.234e03f64.si_unit("B").to_string(), "1.234 kB");
        assert_eq!(1.234e04f64.si_unit("B").to_string(), "12.340 kB");
        assert_eq!(1.234e05f64.si_unit("B").to_string(), "123.400 kB");
        assert_eq!(1.234e06f64.si_unit("B").to_string(), "1.234 MB");
        assert_eq!(1.234e07f64.si_unit("B").to_string(), "12.340 MB");
        assert_eq!(1.234e08f64.si_unit("B").to_string(), "123.400 MB");
        assert_eq!(1.234e09f64.si_unit("B").to_string(), "1.234 GB");
        assert_eq!(1.234e10f64.si_unit("B").to_string(), "12.340 GB");
        assert_eq!(1.234e11f64.si_unit("B").to_string(), "123.400 GB");
        assert_eq!(1.234e12f64.si_unit("B").to_string(), "1.234 TB");
        assert_eq!(1.234e13f64.si_unit("B").to_string(), "12.340 TB");
        assert_eq!(1.234e14f64.si_unit("B").to_string(), "123.400 TB");
        assert_eq!(1.234e15f64.si_unit("B").to_string(), "1.234 PB");
        assert_eq!(1.234e16f64.si_unit("B").to_string(), "12.340 PB");
        assert_eq!(1.234e17f64.si_unit("B").to_string(), "123.400 PB");
        assert_eq!(1.234e18f64.si_unit("B").to_string(), "1.234 EB");
        assert_eq!(1.234e19f64.si_unit("B").to_string(), "12.340 EB");
        assert_eq!(1.234e20f64.si_unit("B").to_string(), "123.400 EB");
        assert_eq!(1.234e21f64.si_unit("B").to_string(), "1234.000 EB");
    }

    #[test]
    fn si_unit_float_neg() {
        assert_eq!((-1.234e-19f64).si_unit("B").to_string(), "-0.123 aB");
        assert_eq!((-1.234e-18f64).si_unit("B").to_string(), "-1.234 aB");
        assert_eq!((-1.234e-17f64).si_unit("B").to_string(), "-12.340 aB");
        assert_eq!((-1.234e-16f64).si_unit("B").to_string(), "-123.400 aB");
        assert_eq!((-1.234e-15f64).si_unit("B").to_string(), "-1.234 fB");
        assert_eq!((-1.234e-14f64).si_unit("B").to_string(), "-12.340 fB");
        assert_eq!((-1.234e-13f64).si_unit("B").to_string(), "-123.400 fB");
        assert_eq!((-1.234e-12f64).si_unit("B").to_string(), "-1.234 pB");
        assert_eq!((-1.234e-11f64).si_unit("B").to_string(), "-12.340 pB");
        assert_eq!((-1.234e-10f64).si_unit("B").to_string(), "-123.400 pB");
        assert_eq!((-1.234e-09f64).si_unit("B").to_string(), "-1.234 nB");
        assert_eq!((-1.234e-08f64).si_unit("B").to_string(), "-12.340 nB");
        assert_eq!((-1.234e-07f64).si_unit("B").to_string(), "-123.400 nB");
        assert_eq!((-1.234e-06f64).si_unit("B").to_string(), "-1.234 µB");
        assert_eq!((-1.234e-05f64).si_unit("B").to_string(), "-12.340 µB");
        assert_eq!((-1.234e-04f64).si_unit("B").to_string(), "-123.400 µB");
        assert_eq!((-1.234e-03f64).si_unit("B").to_string(), "-1.234 mB");
        assert_eq!((-1.234e-02f64).si_unit("B").to_string(), "-12.340 mB");
        assert_eq!((-1.234e-01f64).si_unit("B").to_string(), "-123.400 mB");
        assert_eq!((-1.234e00f64).si_unit("B").to_string(), "-1.234 B");
        assert_eq!((-1.234e01f64).si_unit("B").to_string(), "-12.340 B");
        assert_eq!((-1.234e02f64).si_unit("B").to_string(), "-123.400 B");
        assert_eq!((-1.234e03f64).si_unit("B").to_string(), "-1.234 kB");
        assert_eq!((-1.234e04f64).si_unit("B").to_string(), "-12.340 kB");
        assert_eq!((-1.234e05f64).si_unit("B").to_string(), "-123.400 kB");
        assert_eq!((-1.234e06f64).si_unit("B").to_string(), "-1.234 MB");
        assert_eq!((-1.234e07f64).si_unit("B").to_string(), "-12.340 MB");
        assert_eq!((-1.234e08f64).si_unit("B").to_string(), "-123.400 MB");
        assert_eq!((-1.234e09f64).si_unit("B").to_string(), "-1.234 GB");
        assert_eq!((-1.234e10f64).si_unit("B").to_string(), "-12.340 GB");
        assert_eq!((-1.234e11f64).si_unit("B").to_string(), "-123.400 GB");
        assert_eq!((-1.234e12f64).si_unit("B").to_string(), "-1.234 TB");
        assert_eq!((-1.234e13f64).si_unit("B").to_string(), "-12.340 TB");
        assert_eq!((-1.234e14f64).si_unit("B").to_string(), "-123.400 TB");
        assert_eq!((-1.234e15f64).si_unit("B").to_string(), "-1.234 PB");
        assert_eq!((-1.234e16f64).si_unit("B").to_string(), "-12.340 PB");
        assert_eq!((-1.234e17f64).si_unit("B").to_string(), "-123.400 PB");
        assert_eq!((-1.234e18f64).si_unit("B").to_string(), "-1.234 EB");
        assert_eq!((-1.234e19f64).si_unit("B").to_string(), "-12.340 EB");
        assert_eq!((-1.234e20f64).si_unit("B").to_string(), "-123.400 EB");
        assert_eq!((-1.234e21f64).si_unit("B").to_string(), "-1234.000 EB");
    }
}
