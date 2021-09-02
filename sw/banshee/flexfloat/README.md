# Flexfloat

The code from the directory ```../vendor/flexfloat``` comes from the open-source C/C++ library [FlexFloat](https://github.com/oprecomp/flexfloat).
The directory here implements a seperate Rust project (crate) which implements the *FFI* (Foreign Function Interface) bindings needed by Banshee (implemented in Rust) to include the C/C++ library **FlexFloat**.

Used configuration (see ```../vendor/flexfloat/include/flexfloat_config.h```):
- -DFLEXFLOAT_ON_DOUBLE
- -DFLEXFLOAT_NO_ROUNDING


## Bindgen

[Bindgen](https://github.com/rust-lang/rust-bindgen) was used to generate the FFI file ```bindings.rs```:

```bash
bindgen ../vendor/flexfloat/include/flexfloat.h -o src/bindings.rs
```

Manually applied changes to generated ```bindings.rs```:
- commented out all functions which use *longdouble*: ```u128``` for getting rid of warnings

## Supported Instructions
The supported formats are defined in ```lib.rs```.
