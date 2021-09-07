# Getting Started

## Quick Start

This will take you through the necessary steps to get a sample program running on a cluster of Snitch cores.

1. Clone the repository.
   ```
   git clone https://github.com/pulp-platform/snitch.git
   ```
2. Start the Docker container containing all necessary development tools. If you
   do not want (or can not) use Docker please see the
   [prerequisites](#prerequisites) sections on how to obtain all required tools.
    ```
    docker run -it -v `pwd`/snitch:/repo -w /repo ghcr.io/pulp-platform/snitch
    ```
3. To simulate a cluster of Snitch cores go to `hw/system/snitch_cluster` and build the Verilator model for the Snitch cluster.
    ```
    cd hw/system/snitch_cluster
    make bin/snitch_cluster.vlt
    ```
4. Build the software.
    ```
    mkdir sw/build
    cd sw/build
    cmake ..
    make
    ```
5. Run a sample application on the Verilator model.
    ```
    ./bin/snitch_cluster.vlt sw/build/benchmark/benchmark-matmul-all
    ```
6. Generate the annotated traces and inspect the trace for core 0.
    ```
    make traces
    less trace_hart_00000000.txt
    ```
    Optionally you can inspect the dumped waveforms (`snitch_cluster.vcd`).
7. Visualize the traces with the `util/trace/tracevis.py` script.
    ```
    ./util/trace/tracevis.py -o trace.json sw/build/benchmark/benchmark-matmul-all hw/system/snitch_cluster/logs/trace_hart_*.txt
    ```
    The generated JSON file can be visualized with [Trace-Viewer](https://github.com/catapult-project/catapult/tree/master/tracing), or by loading it into Chrome's `about:tracing`. You can check out an example trace [here](../example_trace.html).
8. Annotate the traces with the `util/trace/annotate.py` script.
    ```
    ./util/trace/annotate.py -o annotated.s sw/build/benchmark/benchmark-matmul-all hw/system/snitch_cluster/logs/trace_hart_00001.txt
    ```
    The generated `annotated.s` interleaves source code with retired instructions.

## Prerequisites

We recommend using the Docker container. If that should not be possible (because
of missing privileges for example) you can install the required tools and
components yourself.

We recommend a reasonable new Linux distribution, for example, Ubuntu 18.04:

- Install essential packages:
    ```
    sudo apt-get install build-essential python3 python3-pip python3-setuptools python3-wheel
    ```
- Install the Python requirements using:
    ```
    pip3 install --user -r python-requirements.txt
    ```
- We are using `Bender` for file list generation. The easiest way to obtain `Bender` is through its binary release channel:
    ```
    curl --proto '=https' --tlsv1.2 https://pulp-platform.github.io/bender/init -sSf | sh
    ```
- Finally, get a RISC-V toolchain. We recommend obtaining binary releases for your operating system from [SiFive's SW site](https://www.sifive.com/software).
    - Unpack the toolchain to a location of your choice (assuming `$RISCV` here). For example for Ubuntu you do:
      ```
      mkdir -p $RISCV && tar -x -f riscv64-unknown-elf-gcc-8.3.0-2020.04.0-x86_64-linux-ubuntu14.tar.gz --strip-components=1 -C $RISCV
      ```
    - Add the `$RISCV/bin` folder to your path variable.
      ```
      export PATH=$RISCV/bin:$PATH
      ```
    - The downloaded toolchain is a multi-lib toolchain, nevertheless our SW scripts currently expect binaries named `riscv32-*`. You can just alias `riscv64-*` to `riscv32-*` using:
      ```
      cd $RISCV/bin && for file in riscv64-*; do ln -s $file $(echo "$file" | sed 's/^riscv64/riscv32/g'); done
      ```

An alternative way, if you have Rust installed, is `cargo install bender`.

### Tool Requirements

- `bender >= 0.21`
- `verilator >= 4.100`

### Software Development

- The `banshee` simulator is built using Rust. We recommend [`rustup`](https://rustup.rs/) if you haven't installed Rust already.
- C/C++ code is formatted using `clang-format`.

### Hardware Development

- We use `verible` for style linting. Either build it from [source](https://github.com/google/verible) or, if available for your platform,  use one of the [pre-built images](https://github.com/google/verible/releases).
- We support simulation with Verilator, VCS and Modelsim.

