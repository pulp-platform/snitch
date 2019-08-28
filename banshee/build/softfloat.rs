use cc::Build;

const SOURCE_DIR: &str = "vendor/SoftFloat-3e/source";

const SOURCE_FILES: &[&str] = &[
    // Primitives
    "s_shiftRightJam128.c",
    "s_approxRecipSqrt_1Ks.c",
    "s_approxRecipSqrt32_1.c",
    // Others
    "s_roundToUI32.c",
    "s_roundToI32.c",
    "s_normSubnormalF32Sig.c",
    "s_roundPackToF32.c",
    "s_normRoundPackToF32.c",
    "s_addMagsF32.c",
    "s_subMagsF32.c",
    "s_mulAddF32.c",
    "s_normSubnormalF64Sig.c",
    "s_roundPackToF64.c",
    "s_normRoundPackToF64.c",
    "s_addMagsF64.c",
    "s_subMagsF64.c",
    "s_mulAddF64.c",
    "ui32_to_f32.c",
    "ui32_to_f64.c",
    "i32_to_f32.c",
    "i32_to_f64.c",
    "f32_to_ui32.c",
    "f32_to_i32.c",
    "f32_to_f64.c",
    "f32_add.c",
    "f32_sub.c",
    "f32_mul.c",
    "f32_mulAdd.c",
    "f32_div.c",
    "f32_rem.c",
    "f32_sqrt.c",
    "f32_eq.c",
    "f32_le.c",
    "f32_lt.c",
    "f32_isSignalingNaN.c",
    "f64_to_ui32.c",
    "f64_to_i32.c",
    "f64_to_f32.c",
    "f64_add.c",
    "f64_sub.c",
    "f64_mul.c",
    "f64_mulAdd.c",
    "f64_div.c",
    "f64_rem.c",
    "f64_sqrt.c",
    "f64_eq.c",
    "f64_le.c",
    "f64_lt.c",
    "f64_isSignalingNaN.c",
];

const SPECIALIZATION_FILES: &[&str] = &[
    // Specializations
    "softfloat_raiseFlags.c",
    "softfloat_state.c",
    "s_f32UIToCommonNaN.c",
    "s_commonNaNToF32UI.c",
    "s_propagateNaNF32UI.c",
    "s_f64UIToCommonNaN.c",
    "s_commonNaNToF64UI.c",
    "s_propagateNaNF64UI.c",
];

fn main() {
    println!("# building softfloat library");

    let source_files = SOURCE_FILES
        .iter()
        .map(|f| format!("vendor/SoftFloat-3e/source/{}", f));
    let specialization_files = SPECIALIZATION_FILES
        .iter()
        .map(|f| format!("build/softfloat/{}", f));

    let all_files = source_files.chain(specialization_files).collect::<Vec<_>>();

    Build::new()
        .files(all_files)
        .flag("-std=c11")
        .include("build/softfloat")
        .include(format!("{}/include", SOURCE_DIR))
        .define("INLINE_LEVEL", "5")
        .define("SOFTFLOAT_FAST_DIV64TO32", None)
        .define("SOFTFLOAT_FAST_INT64", None)
        .warnings(false)
        .compile("softfloat");
}
