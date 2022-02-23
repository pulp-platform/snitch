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

| Property                                  | Type      | Required | Nullable       | Defined by                                                                                                                                                                                                   |
| :---------------------------------------- | :-------- | :------- | :------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [narrow_to_quad](#narrow_to_quad)         | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-narrow_to_quad.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/narrow_to_quad")         |
| [quad_to_narrow](#quad_to_narrow)         | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-quad_to_narrow.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/quad_to_narrow")         |
| [quad_to_pre](#quad_to_pre)               | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-quad_to_pre.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/quad_to_pre")               |
| [pre_to_inter](#pre_to_inter)             | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-pre_to_inter.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/pre_to_inter")             |
| [inter_to_quad](#inter_to_quad)           | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-inter_to_quad.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/inter_to_quad")           |
| [narrow_to_cva6](#narrow_to_cva6)         | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-narrow_to_cva6.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/narrow_to_cva6")         |
| [narrow_conv_to_spm](#narrow_conv_to_spm) | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-narrow_conv_to_spm.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/narrow_conv_to_spm") |
| [narrow_and_pcie](#narrow_and_pcie)       | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-narrow_and_pcie.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/narrow_and_pcie")       |
| [narrow_and_wide](#narrow_and_wide)       | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-narrow_and_wide.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/narrow_and_wide")       |
| [wide_to_hbm](#wide_to_hbm)               | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-wide_to_hbm.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/wide_to_hbm")               |
| [wide_and_inter](#wide_and_inter)         | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-wide_and_inter.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/wide_and_inter")         |
| [wide_and_hbi](#wide_and_hbi)             | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-wide_and_hbi.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/wide_and_hbi")             |
| [narrow_and_hbi](#narrow_and_hbi)         | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-narrow_and_hbi.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/narrow_and_hbi")         |
| [pre_to_hbmx](#pre_to_hbmx)               | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-pre_to_hbmx.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/pre_to_hbmx")               |
| [hbmx_to_hbm](#hbmx_to_hbm)               | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-hbmx_to_hbm.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/hbmx_to_hbm")               |
| [periph_regbus](#periph_regbus)           | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-periph_regbus.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/periph_regbus")           |
| [periph_axi_lite](#periph_axi_lite)       | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-periph_axi_lite.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/periph_axi_lite")       |

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

## narrow_conv_to_spm

narrow -> SPM

`narrow_conv_to_spm`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-narrow_conv_to_spm.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/narrow_conv_to_spm")

### narrow_conv_to_spm Type

`integer`

### narrow_conv_to_spm Default Value

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

## periph_regbus

soc narrow -> periph regbus

`periph_regbus`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus-properties-periph_regbus.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts/properties/periph_regbus")

### periph_regbus Type

`integer`

### periph_regbus Default Value

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
