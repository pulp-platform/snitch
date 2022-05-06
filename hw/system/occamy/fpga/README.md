# Occamy on FPGA

We currently support the Xilinx VCU128 evaluation board.


---

## Features

- Boot through SPI flash and TFTP
- Generation of all images through buildroot with upstream versions and patches (`br2_external/patch`)
- SSH into the Linux running on the VCU128 with `ssh root@hero-vcu128-02.ee.ethz.ch`

---

## Generating the Bitstream

To create the bitstream for Occamy on the VCU128, you currently need to follow three steps.


### Reducing Occamy's Size

First, the default configuration of Occamy (4k cores) is too large for the VCU128. Therefore, open `hw/system/occamy/src/occamy_cfg.hjson`, and reduce `nr_s1_quadrant` and `nr_clusters` (e.g. both to `1`). To make the changes effective, navigate to `hw/system/occamy` and run the following command:

```
make update-sources
```


### Compiling Occamy IP

To package the Occamy IP for use in Vivado (and run an elaboration to check for syntax errors), run the following command from this directory:

```
make -C vivado_ips
```


### Compiling Occamy

To compile Occamy for the VCU128, run the following command from this directory:

```
make occamy_vcu128
```

At IIS, you can download a cached version with the following command:

```
memora get occamy_vcu128
```

---

## Running Linux

This is the current boot flow for Linux on Occamy:

1. All cores start fetching from ROM. The worker cores (Snitches) are parked, whereas the manager core (Ariane) starts loading U-Boot SPL from ROM into DRAM, passes the hart-ID and device tree pointer and jumps to the U-Boot SPL start address in DRAM.

2. U-Boot SPL initialises the VCU128's flash, and loads the image containing OpenSBI + U-Boot into DRAM.

3. OpenSBI sets up the M-mode environment and drops to U-Boot in S-mode.

4. U-Boot loads the Linux image from a TFTP server into DRAM, decompresses and boots it.


### Compiling Linux and U-Boot

We use [buildroot](https://buildroot.org/) to generate a cross-compile toolchain and compile the images in `output/br-hrv-vcu128`:

- u-boot SPL secondary program loader (`u-boot-spl.bin`)
- OpenSBI M-Mode firmware (`fw_dynamic.bin`)
- u-boot proper (`u-boot.bin`) packaged together with OpenSBI in a FIT image for SPL (`u-boot.itb`)
- Linux image with rootfs (`Image`)

Everything is generated with a single command

```
make br-hrv-vcu218
```

At IIS, you can download a cached version with the following command:

```
memora get br-hrv-vcu218
```

### Preparing the VCU128's Flash

Next, we need to load the required image into the VCU128's SPI flash: `u-boot.itb` is expected at address `0x6000000`.

For flashing, we provide an example Vivado script (`occamy_vcu128_flash.tcl`). At IIS, you can use the following `make` targets to load the images to the appropriate location in flash:

```
make VCU=[01|02] flash
```

`VCU` specifies which VCU128 we want to target (`vcu-01` or `vcu-02`, default `01`).


### Preparing the Linux image on the TFTP server

Next, we need to load the required Linux image onto the TFTP server. At IIS, you can use the following `make` target to generate the image and upload it to the appropriate location:

```
make linux-image
make upload-linux-image
```

The URL is currently hard-coded to `bordcomputer.ee.ethz.ch:/srv/tftp/vcu128-01` since this is where the u-boot configuration will load it from.

### Programming the FPGA

Finally, we can program the FPGA with the bitstream generated earlier. At IIS, this can be done with the following `make` command:

```
make VCU=[01|02] program
```

Linux should now boot in the sequence described above. Observe the serial port on `bordcomputer` with the following command:

```
screen /dev/serial/by-id/usb-Xilinx_VCU128_091847100576-if01-port0 115200 # For VCU=01
screen /dev/serial/by-id/usb-Xilinx_VCU128_091847100638-if01-port0 115200 # For VCU=02
```
