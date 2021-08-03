# Snitch Software Examples

Build the examples with

```bash
mkdir build; cd build
cmake -DCMAKE_TOOLCHAIN_FILE=toolchain-llvm -DSNITCH_RUNTIME=snRuntime-banshee ..
make
```

Where
- `CMAKE_TOOLCHAIN_FILE` can choose between the LLVM toolchain (`toolchain-llvm`) or GNU GCC (`toolchain-gcc`)
- `SNITCH_RUNTIME` to choose between banshee simulator (`snRuntime-banshee`, default) and RTL simulator (`snRuntime-cluster`)

To run with banshee
```bash
banshee --no-opt-llvm --no-opt-jit hello_world --num-cores=4 --num-clusters=1
```

To run with verilator RTL simulator
```bash
../../../hw/system/snitch_cluster/bin/snitch_cluster.vlt  hello_world
```
