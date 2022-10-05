# Occamy on FPGA

We currently support the Xilinx VCU128 evaluation board.


---

## Features

_tbd._


---

## Generating the Bitstream

To create the bitstream for Occamy on the VCU128, you currently need to follow two steps.


### Reducing Occamy's Size

First, the default configuration of Occamy (4k cores) is too large for the VCU128. Therefore, open `hw/system/occamy/src/occamy_cfg.hjson`, and reduce `nr_s1_quadrant` and `nr_clusters` (e.g. both to `1`). To make the changes effective, navigate to `hw/system/occamy` and run the following command:

```
make update-sources
```


### Compiling Occamy

To compile Occamy for the VCU128, run the following command from this directory:

```
make occamy_vcu128
```


---

## Running Linux

This is the current boot flow for Linux on Occamy:

1. All cores start fetching from ROM. The worker cores (Snitches) are parked, whereas the manager core (Ariane) starts loading U-Boot SPL from ROM into DRAM, passes the hart-ID and device tree pointer and jumps to the U-Boot SPL start address in DRAM.

2. U-Boot SPL initialises the VCU128's flash, and loads the image containing OpenSBI + U-Boot into DRAM.

3. OpenSBI sets up the M-mode environment and drops to U-Boot in S-mode.

4. U-Boot loads the Linux image from the SPI flash into DRAM, decompresses and boots it.


### Compiling Linux and U-Boot

First, we need to compile the required SW binaries and images, including Linux, OpenSBI and U-Boot. For that, navigate to a suitable location, clone and build the `occamy` branch of [CVA6 SDK](https://github.com/openhwgroup/cva6-sdk/tree/occamy) as follows:

```
git clone --recursive git@github.com:openhwgroup/cva6-sdk.git
cd cva6-sdk
git checkout occamy
make u-boot/u-boot.itb
make uImage
```
`u-boot.itb` ist the image containing OpenSBI + U-Boot, `uImage` is the Linux image in U-Boot format.


### Preparing the VCU128's Flash

Next, we need to load the required images into the VCU128's SPI flash. `u-boot.itb` is expected at address `0x6000000` of the flash, `uImage` at `0x6100000`.

For flashing, we provide an example Vivado script (`occamy_vcu128_flash.tcl`). At IIS, after starting `hw_server` on bordcomputer, you can use the following `make` targets to load the images to the appropriate location in flash:

```
make flash-u-boot VCU=[01|02] CVA6_SDK=path/to/cva6-sdk
make flash-uimage VCU=[01|02] CVA6_SDK=path/to/cva6-sdk
```

`VCU` specifies which VCU128 we want to target (`vcu-01` or `vcu-02`, default `01`). `CVA6_SDK` defaults to `path/to/snitch/../cva6-sdk`.


### Programming the FPGA

Finally, we can program the FPGA with the bitstream generated earlier. At IIS, this can be done with the following `make` command:

```
make program VCU=[01|02]
```

Linux should now boot in the sequence described above.
