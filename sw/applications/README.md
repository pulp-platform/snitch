### Applications

This subdirectory contains some applications or benchmarks specifically implemented and optimized for Snitch.

## Contents
- Data generation:
    - `data_gen.py`: script to generate data and expected results for various benchmarks
    - `data`: output folder of `data_gen.py` which also contains the configuration to generate the data
- `src`:
    - `kernels`: basic kernels, currently contains `GEMM`, `BatchNorm`, `Maxpool`
    - `layers`: wraps the kernel to form a DNN layer. Manages data-movement, synchronization, double buffering etc.
    - `utils`: some helpful functions for benchmarking, verification, fast `memset`
    - `net_layer.c`: various ready tests to run layers.
- `include`: includes `layer` struct.

## Tests
There are currently a few tests for various layer types. Some additional information about these tests is given below:
- `net_maxpool.c`: Naive implementation of a maxpooling layer, not optimized in any way due to memory-boundness
- `net-batchnorm.c`: Implementation of a batchnorm layer with SSR streams (both read and write)
- `net-conv2d.c`: Implementation and tiling of a 2D convolution that can be distributed to multiple clusters. The convolution is implemented as an `im2col` transformation (performed by 2D DMA transfers) + optimized GEMM. The memory layout of input and output feature map is Height x Width x Channels. The convolution is globally parallelized over output channels. Inside a cluster, the output pixels are distributed among the cores. There is an option to load the feature map from a different cluster instead of the main memory by setting `cluster2cluster` in the layer struct to `1`. Currently only `fp64` is implemented, but the data movement for `fp32` or lower precision SIMD should be analogously.
- `net-gemm.c`: Testbench to benchmark the optimized GEMM implementation for different memory layouts, dimensions and precisions.

## Usage
To run a specific benchmark, first configure the dimensions and the desired precision `data/app_params.hjson`.
```
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

Then run the generation script:

```
python data_gen.py -c data/app_params.hjson
```

The applications are compiled into a folder which can be enabled by adding `add_subdirectory(${SNITCH_SOFTWARE_DIR}/applications` to `CMakeLists.txt` in the specific `sw` folder.



