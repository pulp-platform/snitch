# Occamy System Schema Schema

```txt
http://pulp-platform.org/snitch/occamy.schema.json
```

Description of an Occamy-based system.

| Abstract            | Extensible | Status         | Identifiable | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                      |
| :------------------ | :--------- | :------------- | :----------- | :---------------- | :-------------------- | :------------------ | :-------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | No           | Forbidden         | Allowed               | none                | [occamy.schema.json](occamy.schema.json "open original schema") |

## Occamy System Schema Type

`object` ([Occamy System Schema](occamy.md))

# Occamy System Schema Properties

| Property                                                                | Type          | Required | Nullable       | Defined by                                                                                                                                                                        |
| :---------------------------------------------------------------------- | :------------ | :------- | :------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [cluster](#cluster)                                                     | `object`      | Required | cannot be null | [Occamy System Schema](occamy-properties-snitch-cluster-schema.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/cluster")                               |
| [wide_xbar](#wide_xbar)                                                 | `object`      | Optional | cannot be null | [Occamy System Schema](occamy-properties-axi-crossbar-schema.md "http://pulp-platform.org/snitch/axi_xbar.schema.json#/properties/wide_xbar")                                     |
| [wide_xbar_slv_id_width_no_rocache](#wide_xbar_slv_id_width_no_rocache) | `integer`     | Optional | cannot be null | [Occamy System Schema](occamy-properties-wide_xbar_slv_id_width_no_rocache.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/wide_xbar_slv_id_width_no_rocache") |
| [narrow_xbar](#narrow_xbar)                                             | `object`      | Optional | cannot be null | [Occamy System Schema](occamy-properties-axi-crossbar-schema-1.md "http://pulp-platform.org/snitch/axi_xbar.schema.json#/properties/narrow_xbar")                                 |
| [narrow_xbar_slv_id_width](#narrow_xbar_slv_id_width)                   | `integer`     | Optional | cannot be null | [Occamy System Schema](occamy-properties-narrow_xbar_slv_id_width.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/narrow_xbar_slv_id_width")                   |
| [nr_s1_quadrant](#nr_s1_quadrant)                                       | `integer`     | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-s1-quadrants.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/nr_s1_quadrant")                               |
| [s1_quadrant](#s1_quadrant)                                             | `object`      | Optional | cannot be null | [Occamy System Schema](occamy-properties-s1-quadrant-properties.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/s1_quadrant")                                  |
| [debug](#debug)                                                         | `object`      | Optional | cannot be null | [Occamy System Schema](occamy-properties-debug.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/debug")                                                         |
| [rom](#rom)                                                             | `object`      | Optional | cannot be null | [Occamy System Schema](occamy-properties-rom.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/rom")                                                             |
| [soc_ctrl](#soc_ctrl)                                                   | `object`      | Optional | cannot be null | [Occamy System Schema](occamy-properties-soc_ctrl.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/soc_ctrl")                                                   |
| [clk_mgr](#clk_mgr)                                                     | `object`      | Optional | cannot be null | [Occamy System Schema](occamy-properties-clk_mgr.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/clk_mgr")                                                     |
| [uart](#uart)                                                           | `object`      | Optional | cannot be null | [Occamy System Schema](occamy-properties-uart.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/uart")                                                           |
| [GPIO](#gpio)                                                           | `object`      | Optional | cannot be null | [Occamy System Schema](occamy-properties-gpio.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/GPIO")                                                           |
| [I2C](#i2c)                                                             | `object`      | Optional | cannot be null | [Occamy System Schema](occamy-properties-i2c.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/I2C")                                                             |
| [chip_ctrl](#chip_ctrl)                                                 | `object`      | Optional | cannot be null | [Occamy System Schema](occamy-properties-chip_ctrl.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/chip_ctrl")                                                 |
| [timer](#timer)                                                         | `object`      | Optional | cannot be null | [Occamy System Schema](occamy-properties-timer.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/timer")                                                         |
| [spim](#spim)                                                           | `object`      | Optional | cannot be null | [Occamy System Schema](occamy-properties-spim.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/spim")                                                           |
| [clint](#clint)                                                         | `object`      | Optional | cannot be null | [Occamy System Schema](occamy-properties-clint.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/clint")                                                         |
| [pcie_cfg](#pcie_cfg)                                                   | `object`      | Optional | cannot be null | [Occamy System Schema](occamy-properties-pcie_cfg.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/pcie_cfg")                                                   |
| [hbi_cfg](#hbi_cfg)                                                     | `object`      | Optional | cannot be null | [Occamy System Schema](occamy-properties-hbi_cfg.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/hbi_cfg")                                                     |
| [hbi_ctl](#hbi_ctl)                                                     | `object`      | Optional | cannot be null | [Occamy System Schema](occamy-properties-hbi_ctl.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/hbi_ctl")                                                     |
| [hbm_cfg](#hbm_cfg)                                                     | `object`      | Optional | cannot be null | [Occamy System Schema](occamy-properties-hbm_cfg.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/hbm_cfg")                                                     |
| [hbm_phy_cfg](#hbm_phy_cfg)                                             | `object`      | Optional | cannot be null | [Occamy System Schema](occamy-properties-hbm_phy_cfg.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/hbm_phy_cfg")                                             |
| [hbm_seq](#hbm_seq)                                                     | `object`      | Optional | cannot be null | [Occamy System Schema](occamy-properties-hbm_seq.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/hbm_seq")                                                     |
| [plic](#plic)                                                           | `object`      | Optional | cannot be null | [Occamy System Schema](occamy-properties-plic.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/plic")                                                           |
| [spm](#spm)                                                             | Not specified | Optional | cannot be null | [Occamy System Schema](occamy-properties-spm.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/spm")                                                             |
| [pcie](#pcie)                                                           | Not specified | Optional | cannot be null | [Occamy System Schema](occamy-properties-pcie.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/pcie")                                                           |
| [hbi](#hbi)                                                             | Not specified | Optional | cannot be null | [Occamy System Schema](occamy-properties-hbi.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/hbi")                                                             |
| [hbm](#hbm)                                                             | Not specified | Optional | cannot be null | [Occamy System Schema](occamy-properties-hbm.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/hbm")                                                             |
| [dram](#dram)                                                           | Not specified | Optional | cannot be null | [Occamy System Schema](occamy-properties-dram.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/dram")                                                           |

## cluster

Base description of a Snitch cluster and its internal structure and configuration.

`cluster`

*   is required

*   Type: `object` ([Snitch Cluster Schema](occamy-properties-snitch-cluster-schema.md))

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-snitch-cluster-schema.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/cluster")

### cluster Type

`object` ([Snitch Cluster Schema](occamy-properties-snitch-cluster-schema.md))

## wide_xbar

AXI Crossbar Properties

`wide_xbar`

*   is optional

*   Type: `object` ([AXI Crossbar Schema](occamy-properties-axi-crossbar-schema-1.md))

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-axi-crossbar-schema-1.md "http://pulp-platform.org/snitch/axi_xbar.schema.json#/properties/wide_xbar")

### wide_xbar Type

`object` ([AXI Crossbar Schema](occamy-properties-axi-crossbar-schema-1.md))

## wide_xbar_slv_id_width_no_rocache

ID width of incoming slave ports.

`wide_xbar_slv_id_width_no_rocache`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-wide_xbar_slv_id_width_no_rocache.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/wide_xbar_slv_id_width_no_rocache")

### wide_xbar_slv_id_width_no_rocache Type

`integer`

### wide_xbar_slv_id_width_no_rocache Default Value

The default value is:

```json
3
```

## narrow_xbar

AXI Crossbar Properties

`narrow_xbar`

*   is optional

*   Type: `object` ([AXI Crossbar Schema](occamy-properties-axi-crossbar-schema-1.md))

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-axi-crossbar-schema-1.md "http://pulp-platform.org/snitch/axi_xbar.schema.json#/properties/narrow_xbar")

### narrow_xbar Type

`object` ([AXI Crossbar Schema](occamy-properties-axi-crossbar-schema-1.md))

## narrow_xbar_slv_id_width

ID width of incoming slave ports.

`narrow_xbar_slv_id_width`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-narrow_xbar_slv_id_width.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/narrow_xbar_slv_id_width")

### narrow_xbar_slv_id_width Type

`integer`

### narrow_xbar_slv_id_width Default Value

The default value is:

```json
4
```

## nr_s1\_quadrant



`nr_s1_quadrant`

*   is optional

*   Type: `integer` ([Number of S1 Quadrants](occamy-properties-number-of-s1-quadrants.md))

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-number-of-s1-quadrants.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/nr_s1\_quadrant")

### nr_s1\_quadrant Type

`integer` ([Number of S1 Quadrants](occamy-properties-number-of-s1-quadrants.md))

### nr_s1\_quadrant Default Value

The default value is:

```json
8
```

## s1\_quadrant



`s1_quadrant`

*   is optional

*   Type: `object` ([S1 Quadrant Properties](occamy-properties-s1-quadrant-properties.md))

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-s1-quadrant-properties.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/s1\_quadrant")

### s1\_quadrant Type

`object` ([S1 Quadrant Properties](occamy-properties-s1-quadrant-properties.md))

## debug

Debug module.

`debug`

*   is optional

*   Type: `object` ([Details](occamy-properties-debug.md))

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-debug.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/debug")

### debug Type

`object` ([Details](occamy-properties-debug.md))

## rom

Read-only memory from which *all* harts of the system start to boot.

`rom`

*   is optional

*   Type: `object` ([Details](occamy-properties-rom.md))

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-rom.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/rom")

### rom Type

`object` ([Details](occamy-properties-rom.md))

## soc_ctrl

Registerfile to control the SoC area of the system.

`soc_ctrl`

*   is optional

*   Type: `object` ([Details](occamy-properties-soc_ctrl.md))

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-soc_ctrl.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/soc_ctrl")

### soc_ctrl Type

`object` ([Details](occamy-properties-soc_ctrl.md))

## clk_mgr

Memory-mapped Clock Manager to configure the FLLs/PLLs.

`clk_mgr`

*   is optional

*   Type: `object` ([Details](occamy-properties-clk_mgr.md))

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-clk_mgr.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/clk_mgr")

### clk_mgr Type

`object` ([Details](occamy-properties-clk_mgr.md))

## uart

Universal Asynchronous Receiver-Transmitter (UART).

`uart`

*   is optional

*   Type: `object` ([Details](occamy-properties-uart.md))

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-uart.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/uart")

### uart Type

`object` ([Details](occamy-properties-uart.md))

## GPIO

General Purpose Input/Output.

`GPIO`

*   is optional

*   Type: `object` ([Details](occamy-properties-gpio.md))

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-gpio.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/GPIO")

### GPIO Type

`object` ([Details](occamy-properties-gpio.md))

## I2C

I2C controller.

`I2C`

*   is optional

*   Type: `object` ([Details](occamy-properties-i2c.md))

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-i2c.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/I2C")

### I2C Type

`object` ([Details](occamy-properties-i2c.md))

## chip_ctrl

Registerfile to control the SoC area of the system.

`chip_ctrl`

*   is optional

*   Type: `object` ([Details](occamy-properties-chip_ctrl.md))

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-chip_ctrl.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/chip_ctrl")

### chip_ctrl Type

`object` ([Details](occamy-properties-chip_ctrl.md))

## timer

32-bit wide timer.

`timer`

*   is optional

*   Type: `object` ([Details](occamy-properties-timer.md))

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-timer.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/timer")

### timer Type

`object` ([Details](occamy-properties-timer.md))

## spim

Serial Peripheral Interface Master.

`spim`

*   is optional

*   Type: `object` ([Details](occamy-properties-spim.md))

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-spim.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/spim")

### spim Type

`object` ([Details](occamy-properties-spim.md))

## clint

Core-local Interrupt Controller (CLINT).

`clint`

*   is optional

*   Type: `object` ([Details](occamy-properties-clint.md))

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-clint.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/clint")

### clint Type

`object` ([Details](occamy-properties-clint.md))

## pcie_cfg

Registerfile to configure the PCIE / serial link.

`pcie_cfg`

*   is optional

*   Type: `object` ([Details](occamy-properties-pcie_cfg.md))

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-pcie_cfg.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/pcie_cfg")

### pcie_cfg Type

`object` ([Details](occamy-properties-pcie_cfg.md))

## hbi_cfg

Registerfile to configure the High-Bandwidth Interconnect.

`hbi_cfg`

*   is optional

*   Type: `object` ([Details](occamy-properties-hbi_cfg.md))

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-hbi_cfg.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/hbi_cfg")

### hbi_cfg Type

`object` ([Details](occamy-properties-hbi_cfg.md))

## hbi_ctl

Registerfile to control the High-Bandwidth Interconnect.

`hbi_ctl`

*   is optional

*   Type: `object` ([Details](occamy-properties-hbi_ctl.md))

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-hbi_ctl.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/hbi_ctl")

### hbi_ctl Type

`object` ([Details](occamy-properties-hbi_ctl.md))

## hbm_cfg

Registerfile to control the High Bandwidth Memory controller.

`hbm_cfg`

*   is optional

*   Type: `object` ([Details](occamy-properties-hbm_cfg.md))

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-hbm_cfg.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/hbm_cfg")

### hbm_cfg Type

`object` ([Details](occamy-properties-hbm_cfg.md))

## hbm_phy_cfg

Registerfile to control the High Bandwidth Memory PHY.

`hbm_phy_cfg`

*   is optional

*   Type: `object` ([Details](occamy-properties-hbm_phy_cfg.md))

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-hbm_phy_cfg.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/hbm_phy_cfg")

### hbm_phy_cfg Type

`object` ([Details](occamy-properties-hbm_phy_cfg.md))

## hbm_seq

Registerfile to control the High Bandwidth Memory Sequencer.

`hbm_seq`

*   is optional

*   Type: `object` ([Details](occamy-properties-hbm_seq.md))

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-hbm_seq.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/hbm_seq")

### hbm_seq Type

`object` ([Details](occamy-properties-hbm_seq.md))

## plic

Platform-Level Interrupt Controller (PLIC).

`plic`

*   is optional

*   Type: `object` ([Details](occamy-properties-plic.md))

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-plic.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/plic")

### plic Type

`object` ([Details](occamy-properties-plic.md))

## spm

Scratchpad Memory (SPM).

`spm`

*   is optional

*   Type: unknown

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-spm.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/spm")

### spm Type

unknown

## pcie

Peripheral Component Interconnect Express or simply a Serial Link.

`pcie`

*   is optional

*   Type: unknown

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-pcie.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/pcie")

### pcie Type

unknown

## hbi

High-Bandwidth Interconnect (HBI).

`hbi`

*   is optional

*   Type: unknown

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-hbi.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/hbi")

### hbi Type

unknown

## hbm

High Bandwidth Memory (HBM).

`hbm`

*   is optional

*   Type: unknown

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-hbm.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/hbm")

### hbm Type

unknown

## dram

DRAM memory. DRAM address range usually corresponds to 'hbm address\_0' and 'nr_channels_address\_0'.

`dram`

*   is optional

*   Type: unknown

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-dram.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/dram")

### dram Type

unknown
