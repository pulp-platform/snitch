mod runtime;
mod softfloat;

fn main() {
    // Prevent cargo from re-building everything by default.
    // Other subcommands can still emit their own rerun-if-changed lines.
    println!("cargo:rerun-if-changed=build/softfloat.rs");

    // Build the components.
    softfloat::build();
    runtime::build();
}
