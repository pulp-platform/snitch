# Applications

This subdirectory contains some applications or benchmarks specifically implemented and optimized for Snitch.

## Contents
- Data generation:
    - `datagen.py`: script to generate data and expected results for various benchmarks
    - `data`: output folder of `datagen.py` which also contains the configuration to generate the data
- `src`:
    - `kernels`: basic kernels, currently contains `GEMM`, `BatchNorm`, `Maxpool`, `Fusedconv`
    - `layers`: wraps the kernel to form a DNN layer. Manages data-movement, synchronization, double buffering etc.
    - `utils`: some helpful functions for benchmarking, verification, fast `memset`
    - `net_layer.c`: various ready tests to run layers.
- `include`: includes `layer` struct.

## SW Testbenches
There are currently a few tests for various layer types. Some additional information about these tests is given below:
- `net_maxpool.c`: Naive implementation of a maxpooling layer, not optimized in any way due to memory-boundness
- `net-batchnorm.c`: Implementation of a batchnorm layer with SSR streams (both read and write)
- `net-conv2d.c`: Implementation and tiling of a 2D convolution that can be distributed to multiple clusters. The convolution is implemented as an `im2col` transformation (performed by 2D DMA transfers) + optimized GEMM. The memory layout of input and output feature map is Height x Width x Channels. The convolution is globally parallelized over output channels. Inside a cluster, the output pixels are distributed among the cores. There is an option to load the feature map from a different cluster instead of the main memory by setting `cluster2cluster` in the layer struct to `1`. Currently only `fp64` is implemented, but the data movement for `fp32` or lower precision SIMD should be analogously.
- `net-gemm.c`: Testbench to benchmark the optimized GEMM implementation for different memory layouts, dimensions and precisions.
- `net-fusedconv.c`: Implementation of a fused kernel with Conv2d + BatchNorm + ReLU. The interface of the kernel is compatible with DORY. Parameters of a tile can be specified in `data/fusedconv_param.hjson`. Supported paramters are input/output dimension, padding, kernel dimension & stride, flags for BatchNorm and ReLU. Further there are two additional specialized kernels 1) a CHW kernel for input layers with very few input channels, the output of this kernel is in the HWC layout again 2) A depthwise kernel

## Usage
To run a specific benchmark, first configure the dimensions and the desired precision `data/app_params.hjson`.
```
{
    kernel: "GEMM"
    M: 16,
    N: 16,
    K: 16,
    alpha: 0,
    transpose_A: false,
    transpose_B: true,
    prec: 16
}
```

The file will be automatically generated with a `cmake` macro and is stored in `data/data_app.h`. The result will also be checked. Reference is a golden model written in `python` with help of the `torch`.

The applications are compiled into a folder which can be enabled by adding `add_subdirectory(${SNITCH_SOFTWARE_DIR}/applications` to `CMakeLists.txt` in the specific `sw` folder.

## Requirements
- `torch`



