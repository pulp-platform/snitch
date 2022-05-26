# Number of cuts on the AXI bus Schema

```txt
http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts
```



| Abstract            | Extensible | Status         | Identifiable | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                       |
| :------------------ | :--------- | :------------- | :----------- | :---------------- | :-------------------- | :------------------ | :--------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | No           | Forbidden         | Allowed               | none                | [occamy.schema.json*](occamy.schema.json "open original schema") |

## cuts Type

`object` ([Number of cuts on the AXI bus](occamy-properties-number-of-cuts-on-the-axi-bus.md))

# Number of cuts on the AXI bus Properties

| Property                                                                        | Type      | Required | Nullable       | Defined by                                                                                                                                                                                                                                         |
| :------------------------------------------------------------------------------ | :-------- | :------- | :------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [narrow_to_quad](#narrow_to_quad)                                               | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-narrow_to_quad.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/narrow_to_quad")                                               |
| [quad_to_narrow](#quad_to_narrow)                                               | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-quad_to_narrow.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/quad_to_narrow")                                               |
| [quad_to_pre](#quad_to_pre)                                                     | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-quad_to_pre.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/quad_to_pre")                                                     |
| [pre_to_inter](#pre_to_inter)                                                   | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-pre_to_inter.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/pre_to_inter")                                                   |
| [inter_to_quad](#inter_to_quad)                                                 | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-inter_to_quad.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/inter_to_quad")                                                 |
| [narrow_to_cva6](#narrow_to_cva6)                                               | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-narrow_to_cva6.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/narrow_to_cva6")                                               |
| [narrow_conv_to_spm_narrow_pre](#narrow_conv_to_spm_narrow_pre)                 | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-narrow_conv_to_spm_narrow_pre.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/narrow_conv_to_spm_narrow_pre")                 |
| [narrow_conv_to_spm_narrow](#narrow_conv_to_spm_narrow)                         | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-narrow_conv_to_spm_narrow.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/narrow_conv_to_spm_narrow")                         |
| [narrow_and_pcie](#narrow_and_pcie)                                             | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-narrow_and_pcie.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/narrow_and_pcie")                                             |
| [narrow_and_wide](#narrow_and_wide)                                             | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-narrow_and_wide.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/narrow_and_wide")                                             |
| [wide_conv_to_spm_wide](#wide_conv_to_spm_wide)                                 | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-wide_conv_to_spm_wide.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/wide_conv_to_spm_wide")                                 |
| [wide_to_wide_zero_mem](#wide_to_wide_zero_mem)                                 | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-wide_to_wide_zero_mem.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/wide_to_wide_zero_mem")                                 |
| [wide_to_hbm](#wide_to_hbm)                                                     | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-wide_to_hbm.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/wide_to_hbm")                                                     |
| [wide_and_inter](#wide_and_inter)                                               | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-wide_and_inter.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/wide_and_inter")                                               |
| [wide_and_hbi](#wide_and_hbi)                                                   | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-wide_and_hbi.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/wide_and_hbi")                                                   |
| [narrow_and_hbi](#narrow_and_hbi)                                               | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-narrow_and_hbi.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/narrow_and_hbi")                                               |
| [pre_to_hbmx](#pre_to_hbmx)                                                     | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-pre_to_hbmx.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/pre_to_hbmx")                                                     |
| [hbmx_to_hbm](#hbmx_to_hbm)                                                     | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-hbmx_to_hbm.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/hbmx_to_hbm")                                                     |
| [atomic_adapter_narrow](#atomic_adapter_narrow)                                 | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-atomic_adapter_narrow.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/atomic_adapter_narrow")                                 |
| [atomic_adapter_narrow_wide](#atomic_adapter_narrow_wide)                       | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-atomic_adapter_narrow_wide.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/atomic_adapter_narrow_wide")                       |
| [periph_axi_lite_narrow](#periph_axi_lite_narrow)                               | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-periph_axi_lite_narrow.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/periph_axi_lite_narrow")                               |
| [periph_axi_lite](#periph_axi_lite)                                             | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-periph_axi_lite.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/periph_axi_lite")                                             |
| [periph_axi_lite_narrow_hbm_xbar_cfg](#periph_axi_lite_narrow_hbm_xbar_cfg)     | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-periph_axi_lite_narrow_hbm_xbar_cfg.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/periph_axi_lite_narrow_hbm_xbar_cfg")     |
| [periph_axi_lite_narrow_hbi_wide_cfg](#periph_axi_lite_narrow_hbi_wide_cfg)     | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-periph_axi_lite_narrow_hbi_wide_cfg.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/periph_axi_lite_narrow_hbi_wide_cfg")     |
| [periph_axi_lite_narrow_hbi_narrow_cfg](#periph_axi_lite_narrow_hbi_narrow_cfg) | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-periph_axi_lite_narrow_hbi_narrow_cfg.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/periph_axi_lite_narrow_hbi_narrow_cfg") |
| [periph_axi_lite_narrow_pcie_cfg](#periph_axi_lite_narrow_pcie_cfg)             | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-periph_axi_lite_narrow_pcie_cfg.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/periph_axi_lite_narrow_pcie_cfg")             |
| [periph_axi_lite_narrow_hbm_cfg](#periph_axi_lite_narrow_hbm_cfg)               | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-periph_axi_lite_narrow_hbm_cfg.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/periph_axi_lite_narrow_hbm_cfg")               |
| [periph_axi_lite_narrow_clint_cfg](#periph_axi_lite_narrow_clint_cfg)           | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-periph_axi_lite_narrow_clint_cfg.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/periph_axi_lite_narrow_clint_cfg")           |
| [periph_axi_lite_narrow_soc_ctrl_cfg](#periph_axi_lite_narrow_soc_ctrl_cfg)     | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-periph_axi_lite_narrow_soc_ctrl_cfg.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/periph_axi_lite_narrow_soc_ctrl_cfg")     |
| [periph_axi_lite_narrow_chip_ctrl_cfg](#periph_axi_lite_narrow_chip_ctrl_cfg)   | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-periph_axi_lite_narrow_chip_ctrl_cfg.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/periph_axi_lite_narrow_chip_ctrl_cfg")   |
| [periph_axi_lite_narrow_uart_cfg](#periph_axi_lite_narrow_uart_cfg)             | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-periph_axi_lite_narrow_uart_cfg.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/periph_axi_lite_narrow_uart_cfg")             |
| [periph_axi_lite_narrow_bootrom_cfg](#periph_axi_lite_narrow_bootrom_cfg)       | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-periph_axi_lite_narrow_bootrom_cfg.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/periph_axi_lite_narrow_bootrom_cfg")       |
| [periph_axi_lite_narrow_fll_system_cfg](#periph_axi_lite_narrow_fll_system_cfg) | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-periph_axi_lite_narrow_fll_system_cfg.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/periph_axi_lite_narrow_fll_system_cfg") |
| [periph_axi_lite_narrow_fll_periph_cfg](#periph_axi_lite_narrow_fll_periph_cfg) | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-periph_axi_lite_narrow_fll_periph_cfg.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/periph_axi_lite_narrow_fll_periph_cfg") |
| [periph_axi_lite_narrow_fll_hbm2e_cfg](#periph_axi_lite_narrow_fll_hbm2e_cfg)   | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-periph_axi_lite_narrow_fll_hbm2e_cfg.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/periph_axi_lite_narrow_fll_hbm2e_cfg")   |
| [periph_axi_lite_narrow_plic_cfg](#periph_axi_lite_narrow_plic_cfg)             | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-periph_axi_lite_narrow_plic_cfg.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/periph_axi_lite_narrow_plic_cfg")             |
| [periph_axi_lite_narrow_spim_cfg](#periph_axi_lite_narrow_spim_cfg)             | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-periph_axi_lite_narrow_spim_cfg.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/periph_axi_lite_narrow_spim_cfg")             |
| [periph_axi_lite_narrow_gpio_cfg](#periph_axi_lite_narrow_gpio_cfg)             | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-periph_axi_lite_narrow_gpio_cfg.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/periph_axi_lite_narrow_gpio_cfg")             |
| [periph_axi_lite_narrow_i2c_cfg](#periph_axi_lite_narrow_i2c_cfg)               | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-periph_axi_lite_narrow_i2c_cfg.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/periph_axi_lite_narrow_i2c_cfg")               |
| [periph_axi_lite_narrow_timer_cfg](#periph_axi_lite_narrow_timer_cfg)           | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-periph_axi_lite_narrow_timer_cfg.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/periph_axi_lite_narrow_timer_cfg")           |

## narrow_to_quad

narrow xbar -> quad

`narrow_to_quad`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-narrow_to_quad.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/narrow_to_quad")

### narrow_to_quad Type

`integer`

### narrow_to_quad Default Value

The default value is:

```json
3
```

## quad_to_narrow

quad -> narrow xbar

`quad_to_narrow`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-quad_to_narrow.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/quad_to_narrow")

### quad_to_narrow Type

`integer`

### quad_to_narrow Default Value

The default value is:

```json
3
```

## quad_to_pre

quad -> pre xbar

`quad_to_pre`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-quad_to_pre.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/quad_to_pre")

### quad_to_pre Type

`integer`

### quad_to_pre Default Value

The default value is:

```json
1
```

## pre_to_inter

pre xbar -> inter xbar

`pre_to_inter`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-pre_to_inter.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/pre_to_inter")

### pre_to_inter Type

`integer`

### pre_to_inter Default Value

The default value is:

```json
1
```

## inter_to_quad

inter xbar -> quad

`inter_to_quad`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-inter_to_quad.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/inter_to_quad")

### inter_to_quad Type

`integer`

### inter_to_quad Default Value

The default value is:

```json
3
```

## narrow_to_cva6

narrow -> cva6

`narrow_to_cva6`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-narrow_to_cva6.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/narrow_to_cva6")

### narrow_to_cva6 Type

`integer`

### narrow_to_cva6 Default Value

The default value is:

```json
1
```

## narrow_conv_to_spm_narrow_pre

narrow -> SPM pre atomic adapter

`narrow_conv_to_spm_narrow_pre`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-narrow_conv_to_spm_narrow_pre.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/narrow_conv_to_spm_narrow_pre")

### narrow_conv_to_spm_narrow_pre Type

`integer`

### narrow_conv_to_spm_narrow_pre Default Value

The default value is:

```json
1
```

## narrow_conv_to_spm_narrow

narrow -> SPM post atomic adapter

`narrow_conv_to_spm_narrow`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-narrow_conv_to_spm_narrow.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/narrow_conv_to_spm_narrow")

### narrow_conv_to_spm_narrow Type

`integer`

### narrow_conv_to_spm_narrow Default Value

The default value is:

```json
1
```

## narrow_and_pcie

PCIe in and out

`narrow_and_pcie`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-narrow_and_pcie.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/narrow_and_pcie")

### narrow_and_pcie Type

`integer`

### narrow_and_pcie Default Value

The default value is:

```json
1
```

## narrow_and_wide

narrow xbar -> wide xbar & wide xbar -> narrow xbar

`narrow_and_wide`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-narrow_and_wide.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/narrow_and_wide")

### narrow_and_wide Type

`integer`

## wide_conv_to_spm_wide

wide xbar -> wide spm

`wide_conv_to_spm_wide`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-wide_conv_to_spm_wide.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/wide_conv_to_spm_wide")

### wide_conv_to_spm_wide Type

`integer`

### wide_conv_to_spm_wide Default Value

The default value is:

```json
1
```

## wide_to_wide_zero_mem

wide xbar -> wide zero memory

`wide_to_wide_zero_mem`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-wide_to_wide_zero_mem.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/wide_to_wide_zero_mem")

### wide_to_wide_zero_mem Type

`integer`

## wide_to_hbm

wide xbar -> hbm xbar

`wide_to_hbm`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-wide_to_hbm.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/wide_to_hbm")

### wide_to_hbm Type

`integer`

### wide_to_hbm Default Value

The default value is:

```json
6
```

## wide_and_inter

inter xbar -> wide xbar & wide xbar -> inter xbar

`wide_and_inter`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-wide_and_inter.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/wide_and_inter")

### wide_and_inter Type

`integer`

### wide_and_inter Default Value

The default value is:

```json
3
```

## wide_and_hbi

hbi <-> wide xbar

`wide_and_hbi`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-wide_and_hbi.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/wide_and_hbi")

### wide_and_hbi Type

`integer`

### wide_and_hbi Default Value

The default value is:

```json
3
```

## narrow_and_hbi

hbi <-> narrow xbar

`narrow_and_hbi`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-narrow_and_hbi.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/narrow_and_hbi")

### narrow_and_hbi Type

`integer`

### narrow_and_hbi Default Value

The default value is:

```json
3
```

## pre_to_hbmx

pre xbar -> hbm xbar

`pre_to_hbmx`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-pre_to_hbmx.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/pre_to_hbmx")

### pre_to_hbmx Type

`integer`

### pre_to_hbmx Default Value

The default value is:

```json
3
```

## hbmx_to_hbm

hbmx -> hbm

`hbmx_to_hbm`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-hbmx_to_hbm.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/hbmx_to_hbm")

### hbmx_to_hbm Type

`integer`

### hbmx_to_hbm Default Value

The default value is:

```json
3
```

## atomic_adapter_narrow

narrow spm atomic adapter internal cuts

`atomic_adapter_narrow`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-atomic_adapter_narrow.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/atomic_adapter_narrow")

### atomic_adapter_narrow Type

`integer`

### atomic_adapter_narrow Default Value

The default value is:

```json
1
```

## atomic_adapter_narrow_wide

narrow_to_wide atomic adapter internal cuts

`atomic_adapter_narrow_wide`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-atomic_adapter_narrow_wide.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/atomic_adapter_narrow_wide")

### atomic_adapter_narrow_wide Type

`integer`

### atomic_adapter_narrow_wide Default Value

The default value is:

```json
1
```

## periph_axi_lite_narrow

soc narrow -> periph regbus

`periph_axi_lite_narrow`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-periph_axi_lite_narrow.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/periph_axi_lite_narrow")

### periph_axi_lite_narrow Type

`integer`

### periph_axi_lite_narrow Default Value

The default value is:

```json
3
```

## periph_axi_lite

soc narrow -> periph axilite

`periph_axi_lite`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-periph_axi_lite.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/periph_axi_lite")

### periph_axi_lite Type

`integer`

### periph_axi_lite Default Value

The default value is:

```json
3
```

## periph_axi_lite_narrow_hbm_xbar_cfg

axi lite narrow cuts before regbus translation for hbm_xbar_cfg

`periph_axi_lite_narrow_hbm_xbar_cfg`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-periph_axi_lite_narrow_hbm_xbar_cfg.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/periph_axi_lite_narrow_hbm_xbar_cfg")

### periph_axi_lite_narrow_hbm_xbar_cfg Type

`integer`

### periph_axi_lite_narrow_hbm_xbar_cfg Default Value

The default value is:

```json
3
```

## periph_axi_lite_narrow_hbi_wide_cfg

axi lite narrow cuts before regbus translation for hbi_wide_cfg

`periph_axi_lite_narrow_hbi_wide_cfg`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-periph_axi_lite_narrow_hbi_wide_cfg.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/periph_axi_lite_narrow_hbi_wide_cfg")

### periph_axi_lite_narrow_hbi_wide_cfg Type

`integer`

### periph_axi_lite_narrow_hbi_wide_cfg Default Value

The default value is:

```json
3
```

## periph_axi_lite_narrow_hbi_narrow_cfg

axi lite narrow cuts before regbus translation for hbi_narrow_cfg

`periph_axi_lite_narrow_hbi_narrow_cfg`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-periph_axi_lite_narrow_hbi_narrow_cfg.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/periph_axi_lite_narrow_hbi_narrow_cfg")

### periph_axi_lite_narrow_hbi_narrow_cfg Type

`integer`

### periph_axi_lite_narrow_hbi_narrow_cfg Default Value

The default value is:

```json
3
```

## periph_axi_lite_narrow_pcie_cfg

axi lite narrow cuts before regbus translation for pcie_cfg

`periph_axi_lite_narrow_pcie_cfg`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-periph_axi_lite_narrow_pcie_cfg.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/periph_axi_lite_narrow_pcie_cfg")

### periph_axi_lite_narrow_pcie_cfg Type

`integer`

### periph_axi_lite_narrow_pcie_cfg Default Value

The default value is:

```json
2
```

## periph_axi_lite_narrow_hbm_cfg

axi lite narrow cuts before regbus translation for hbm_cfg

`periph_axi_lite_narrow_hbm_cfg`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-periph_axi_lite_narrow_hbm_cfg.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/periph_axi_lite_narrow_hbm_cfg")

### periph_axi_lite_narrow_hbm_cfg Type

`integer`

### periph_axi_lite_narrow_hbm_cfg Default Value

The default value is:

```json
3
```

## periph_axi_lite_narrow_clint_cfg

axi lite narrow cuts before regbus translation for clint_cfg

`periph_axi_lite_narrow_clint_cfg`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-periph_axi_lite_narrow_clint_cfg.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/periph_axi_lite_narrow_clint_cfg")

### periph_axi_lite_narrow_clint_cfg Type

`integer`

### periph_axi_lite_narrow_clint_cfg Default Value

The default value is:

```json
1
```

## periph_axi_lite_narrow_soc_ctrl_cfg

axi lite narrow cuts before regbus translation for soc_ctrl_cfg

`periph_axi_lite_narrow_soc_ctrl_cfg`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-periph_axi_lite_narrow_soc_ctrl_cfg.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/periph_axi_lite_narrow_soc_ctrl_cfg")

### periph_axi_lite_narrow_soc_ctrl_cfg Type

`integer`

### periph_axi_lite_narrow_soc_ctrl_cfg Default Value

The default value is:

```json
1
```

## periph_axi_lite_narrow_chip_ctrl_cfg

axi lite narrow cuts before regbus translation for chip_ctrl_cfg

`periph_axi_lite_narrow_chip_ctrl_cfg`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-periph_axi_lite_narrow_chip_ctrl_cfg.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/periph_axi_lite_narrow_chip_ctrl_cfg")

### periph_axi_lite_narrow_chip_ctrl_cfg Type

`integer`

### periph_axi_lite_narrow_chip_ctrl_cfg Default Value

The default value is:

```json
1
```

## periph_axi_lite_narrow_uart_cfg

axi lite narrow cuts before regbus translation for uart_cfg

`periph_axi_lite_narrow_uart_cfg`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-periph_axi_lite_narrow_uart_cfg.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/periph_axi_lite_narrow_uart_cfg")

### periph_axi_lite_narrow_uart_cfg Type

`integer`

### periph_axi_lite_narrow_uart_cfg Default Value

The default value is:

```json
2
```

## periph_axi_lite_narrow_bootrom_cfg

axi lite narrow cuts before regbus translation for bootrom_cfg

`periph_axi_lite_narrow_bootrom_cfg`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-periph_axi_lite_narrow_bootrom_cfg.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/periph_axi_lite_narrow_bootrom_cfg")

### periph_axi_lite_narrow_bootrom_cfg Type

`integer`

### periph_axi_lite_narrow_bootrom_cfg Default Value

The default value is:

```json
3
```

## periph_axi_lite_narrow_fll_system_cfg

axi lite narrow cuts before regbus translation for fll_system_cfg

`periph_axi_lite_narrow_fll_system_cfg`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-periph_axi_lite_narrow_fll_system_cfg.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/periph_axi_lite_narrow_fll_system_cfg")

### periph_axi_lite_narrow_fll_system_cfg Type

`integer`

### periph_axi_lite_narrow_fll_system_cfg Default Value

The default value is:

```json
3
```

## periph_axi_lite_narrow_fll_periph_cfg

axi lite narrow cuts before regbus translation for fll_periph_cfg

`periph_axi_lite_narrow_fll_periph_cfg`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-periph_axi_lite_narrow_fll_periph_cfg.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/periph_axi_lite_narrow_fll_periph_cfg")

### periph_axi_lite_narrow_fll_periph_cfg Type

`integer`

### periph_axi_lite_narrow_fll_periph_cfg Default Value

The default value is:

```json
3
```

## periph_axi_lite_narrow_fll_hbm2e_cfg

axi lite narrow cuts before regbus translation for fll_hbm2e_cfg

`periph_axi_lite_narrow_fll_hbm2e_cfg`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-periph_axi_lite_narrow_fll_hbm2e_cfg.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/periph_axi_lite_narrow_fll_hbm2e_cfg")

### periph_axi_lite_narrow_fll_hbm2e_cfg Type

`integer`

### periph_axi_lite_narrow_fll_hbm2e_cfg Default Value

The default value is:

```json
3
```

## periph_axi_lite_narrow_plic_cfg

axi lite narrow cuts before regbus translation for plic_cfg

`periph_axi_lite_narrow_plic_cfg`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-periph_axi_lite_narrow_plic_cfg.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/periph_axi_lite_narrow_plic_cfg")

### periph_axi_lite_narrow_plic_cfg Type

`integer`

### periph_axi_lite_narrow_plic_cfg Default Value

The default value is:

```json
1
```

## periph_axi_lite_narrow_spim_cfg

axi lite narrow cuts before regbus translation for spim_cfg

`periph_axi_lite_narrow_spim_cfg`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-periph_axi_lite_narrow_spim_cfg.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/periph_axi_lite_narrow_spim_cfg")

### periph_axi_lite_narrow_spim_cfg Type

`integer`

### periph_axi_lite_narrow_spim_cfg Default Value

The default value is:

```json
32
```

## periph_axi_lite_narrow_gpio_cfg

axi lite narrow cuts before regbus translation for gpio_cfg

`periph_axi_lite_narrow_gpio_cfg`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-periph_axi_lite_narrow_gpio_cfg.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/periph_axi_lite_narrow_gpio_cfg")

### periph_axi_lite_narrow_gpio_cfg Type

`integer`

### periph_axi_lite_narrow_gpio_cfg Default Value

The default value is:

```json
2
```

## periph_axi_lite_narrow_i2c_cfg

axi lite narrow cuts before regbus translation for i2c_cfg

`periph_axi_lite_narrow_i2c_cfg`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-periph_axi_lite_narrow_i2c_cfg.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/periph_axi_lite_narrow_i2c_cfg")

### periph_axi_lite_narrow_i2c_cfg Type

`integer`

### periph_axi_lite_narrow_i2c_cfg Default Value

The default value is:

```json
2
```

## periph_axi_lite_narrow_timer_cfg

axi lite narrow cuts before regbus translation for timer_cfg

`periph_axi_lite_narrow_timer_cfg`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-periph_axi_lite_narrow_timer_cfg.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/periph_axi_lite_narrow_timer_cfg")

### periph_axi_lite_narrow_timer_cfg Type

`integer`

### periph_axi_lite_narrow_timer_cfg Default Value

The default value is:

```json
1
```
