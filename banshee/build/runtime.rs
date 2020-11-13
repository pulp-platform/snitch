use std::path::Path;
use std::process::Command;

pub fn build() {
    // Determine where things come from and where they need to go.
    let out_dir = std::env::var_os("OUT_DIR").unwrap();
    let src_path = Path::new("src/runtime/jit.rs");
    let dst_path = Path::new(&out_dir).join("jit_generated.ll");
    println!("cargo:rerun-if-changed={}", src_path.display());

    // Generate the JIT LLVM IR.
    Command::new(std::env::var_os("RUSTC").unwrap())
        .arg(&src_path)
        .arg("-o")
        .arg(&dst_path)
        .args(&[
            "--emit=llvm-ir",
            "--crate-type=staticlib",
            "-Copt-level=3",
            "-Cdebuginfo=0",
            "-Cpanic=abort",
        ])
        .status()
        .unwrap();

    println!("Compiled {} to {}", src_path.display(), dst_path.display());
}
