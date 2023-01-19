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

First, the default configuration of Occamy (4k cores) is too large for the VCU128. Therefore, open `hw/system/occamy/src/occamy_cfg.hjson`, and reduce `nr_s1_quadrant` and `nr_clusters` (both to `1`). To make the changes effective, navigate to `hw/system/occamy` and run the following command:

```
make update-sources
```

### Compiling the bootrom

To compile the bootrom you will need a riscv64 toolchain as well as u-boot pre-compiled.
Add the hero toolchain to your PATH and compile the bootrom with u-boot path :
```bash
cd bootrom
export $HERO_INSTALL path_to_your_hero_repository/install
export PATH=$HERO_INSTALL/share:$HERO_INSTALL/bin:$PATH
UBOOT_SPL_BIN=path_to_your_hero_repository/output/br-hrv-occamy/images/u-boot-spl.bin make all
```
If you use an other toolchain, change CROSS_COMPILE in `bootrom/Makefile`.

### Compiling Occamy

To compile Occamy for the VCU128, run the following command from this directory:

__Attention:__ By default use EXT_JTAG=0, if you have the correct FMC debug card you can use EXT_JTAG=1, or set up your own GPIO for JTAG. 
```
make occamy_vcu128 [EXT_JTAG=1] [DEBUG=1]
```
The DEBUG option instanciates ILAs to follow waveform of selected signals with (* mark_debug = "true" *).

The EXT_JTAG option redirects the debug module's JTAG signals to GPIOs to be used externally. This way it is possible to use both Vivado ILAs and CVA6 debug module simultaneously. If you have EXT_JTAG=0 you will need to kill vivado hw_server before starting openOCD.

This was tested with VCU128 and a FMC XM105 Debug Card (used to add GPIOs) with a Digilent JTAG HS2 USB Dongle (used to add a JTAG chain on these GPIOs, to connect to the debug module), see the related connections on `occamy_vcu128_impl_ext_jtag.xdc`.

At IIS Vivado HW server is located on the bordcomputer :
```
ssh bordcomputer
/home/vcu128-02/hw_server.sh
```

Open `occamy_vcu128/occamy_vcu128.xpr` in your Vivado client and program the FPGA. (__Attention:__ The FPGA core may be reset by default (oops), open hw_vio_1 and set \*_rst_\* signals to 0). Then, still in Vivado, overwrite the bootrom by sourcing `bootrom/bootrom-spl.tcl`.

---

### OpenOCD

You can later use OpenOCD to debug CVA6.

```bash
# Without EXT_JTAG
openocd -f openocd_configs/vcu128-2.cfg 
# With    EXT_JTAG
openocd -f openocd_configs/digilent-HS2.cfg 

riscv64-hero-linux-gnu-gdb -ex "target extended-remote :3334"
```

We recomment waiting for the boot to be done before startnig openocd, if you need to test connectivity to your debug module you can as well set BOOTMODE to JTAG in `bootrom/src/main.c` before re-programming the bootrom (see previous section).


## Running Hero

First you need to flash u-boot in the SPI :

```bash
UBOOT_ITB=path_to_your_hero_repository/output/br-hrv-occamy/images/u-boot.itb VCU=02 make flash-u-boot
# In IIS we use VCU= to hold FPGA infos,
# you may modify FPGA_ID and HW_SERVER in the Makefile
```

Goto HERO's branch `occamy_ci_2` and follow the `README.md` there.

## Running Linux

This is the current boot flow for Linux on Occamy:

1. All cores start fetching from ROM. The worker cores (Snitches) are parked, whereas the manager core (Ariane) starts loading U-Boot SPL from ROM into DRAM, passes the hart-ID and device tree pointer and jumps to the U-Boot SPL start address in DRAM.

2. U-Boot SPL initialises the VCU128's flash, and loads the image containing OpenSBI + U-Boot into DRAM.

3. OpenSBI sets up the M-mode environment and drops to U-Boot in S-mode.

4. U-Boot loads the Linux image from a TFTP server into DRAM, decompresses and boots it.


### Compiling Linux and U-Boot

## Using Buildroot

We use [buildroot](https://buildroot.org/) to generate a cross-compile toolchain and compile the images in `output/br-hrv-vcu128`:

- u-boot SPL secondary program loader (`u-boot-spl.bin`)
- OpenSBI M-Mode firmware (`fw_dynamic.bin`)
- u-boot proper (`u-boot.bin`) packaged together with OpenSBI in a FIT image for SPL (`u-boot.itb`)
- Linux image with rootfs (`Image`)

Everything is generated with a single command

```
make br-hrv-vcu218
```
First, we need to compile the required SW binaries and images, including Linux, OpenSBI and U-Boot. For that, navigate to a suitable location, clone and build the `occamy` branch of [CVA6 SDK](https://github.com/openhwgroup/cva6-sdk/tree/occamy) as follows:


At IIS, you can download a cached version with the following command:

```
memora get br-hrv-vcu218
```

## Using the CVA6 SDK

```
git clone --recursive git@github.com:openhwgroup/cva6-sdk.git
cd cva6-sdk
git checkout occamy
make u-boot/u-boot.itb
make uImage
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
