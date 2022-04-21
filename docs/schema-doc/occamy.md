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

| Property                                                              | Type      | Required | Nullable       | Defined by                                                                                                                                                                      |
| :-------------------------------------------------------------------- | :-------- | :------- | :------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| [cluster](#cluster)                                                   | `object`  | Required | cannot be null | [Occamy System Schema](occamy-properties-snitch-cluster-schema.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/cluster")                             |
| [quadrant_pre_xbar](#quadrant_pre_xbar)                               | `object`  | Optional | cannot be null | [Occamy System Schema](occamy-properties-axi-crossbar-schema.md "http://pulp-platform.org/snitch/axi_xbar.schema.json#/properties/quadrant_pre_xbar")                           |
| [pre_xbar_slv_id_width_no_rocache](#pre_xbar_slv_id_width_no_rocache) | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-pre_xbar_slv_id_width_no_rocache.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/pre_xbar_slv_id_width_no_rocache") |
| [wide_xbar](#wide_xbar)                                               | `object`  | Optional | cannot be null | [Occamy System Schema](occamy-properties-axi-crossbar-schema-1.md "http://pulp-platform.org/snitch/axi_xbar.schema.json#/properties/wide_xbar")                                 |
| [quadrant_inter_xbar](#quadrant_inter_xbar)                           | `object`  | Optional | cannot be null | [Occamy System Schema](occamy-properties-axi-crossbar-schema-2.md "http://pulp-platform.org/snitch/axi_xbar.schema.json#/properties/quadrant_inter_xbar")                       |
| [hbm_xbar](#hbm_xbar)                                                 | `object`  | Optional | cannot be null | [Occamy System Schema](occamy-properties-axi-crossbar-schema-3.md "http://pulp-platform.org/snitch/axi_xbar.schema.json#/properties/hbm_xbar")                                  |
| [narrow_xbar](#narrow_xbar)                                           | `object`  | Optional | cannot be null | [Occamy System Schema](occamy-properties-axi-crossbar-schema-4.md "http://pulp-platform.org/snitch/axi_xbar.schema.json#/properties/narrow_xbar")                               |
| [narrow_xbar_slv_id_width](#narrow_xbar_slv_id_width)                 | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-narrow_xbar_slv_id_width.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/narrow_xbar_slv_id_width")                 |
| [nr_s1_quadrant](#nr_s1_quadrant)                                     | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-s1-quadrants.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/nr_s1_quadrant")                             |
| [narrow_tlb_cfg](#narrow_tlb_cfg)                                     | `object`  | Optional | cannot be null | [Occamy System Schema](occamy-properties-axi-tlb-schema.md "http://pulp-platform.org/snitch/axi_tlb.schema.json#/properties/narrow_tlb_cfg")                                    |
| [wide_tlb_cfg](#wide_tlb_cfg)                                         | `object`  | Optional | cannot be null | [Occamy System Schema](occamy-properties-axi-tlb-schema-1.md "http://pulp-platform.org/snitch/axi_tlb.schema.json#/properties/wide_tlb_cfg")                                    |
| [cuts](#cuts)                                                         | `object`  | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts")                                |
| [txns](#txns)                                                         | `object`  | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-outstanding-transactions-on-the-axi-bus.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/txns")            |
| [is_remote_quadrant](#is_remote_quadrant)                             | `boolean` | Optional | cannot be null | [Occamy System Schema](occamy-properties-is_remote_quadrant.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/is_remote_quadrant")                             |
| [remote_quadrants](#remote_quadrants)                                 | `array`   | Optional | cannot be null | [Occamy System Schema](occamy-properties-remote-quadrants.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/remote_quadrants")                                 |
| [s1_quadrant](#s1_quadrant)                                           | `object`  | Optional | cannot be null | [Occamy System Schema](occamy-properties-s1-quadrant-properties.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/s1_quadrant")                                |
| [spm_narrow](#spm_narrow)                                             | `object`  | Optional | cannot be null | [Occamy System Schema](occamy-properties-address-range-schema.md "http://pulp-platform.org/snitch/address_range.schema.json#/properties/spm_narrow")                            |
| [spm_wide](#spm_wide)                                                 | `object`  | Optional | cannot be null | [Occamy System Schema](occamy-properties-address-range-schema-1.md "http://pulp-platform.org/snitch/address_range.schema.json#/properties/spm_wide")                            |
| [wide_zero_mem](#wide_zero_mem)                                       | `object`  | Optional | cannot be null | [Occamy System Schema](occamy-properties-address-range-schema-2.md "http://pulp-platform.org/snitch/address_range.schema.json#/properties/wide_zero_mem")                       |
| [pcie](#pcie)                                                         | `object`  | Optional | cannot be null | [Occamy System Schema](occamy-properties-configuration-of-external-pcie-port.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/pcie")                          |
| [hbi](#hbi)                                                           | `object`  | Optional | cannot be null | [Occamy System Schema](occamy-properties-address-range-schema-3.md "http://pulp-platform.org/snitch/address_range.schema.json#/properties/hbi")                                 |
| [hbm](#hbm)                                                           | `object`  | Optional | cannot be null | [Occamy System Schema](occamy-properties-configuration-of-external-hbm-interface.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/hbm")                       |
| [peripherals](#peripherals)                                           | `object`  | Optional | cannot be null | [Occamy System Schema](occamy-properties-peripherals-schema.md "http://pulp-platform.org/snitch/peripherals.schema.json#/properties/peripherals")                               |

## cluster

Base description of a Snitch cluster and its internal structure and configuration.

`cluster`

*   is required

*   Type: `object` ([Snitch Cluster Schema](occamy-properties-snitch-cluster-schema.md))

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-snitch-cluster-schema.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/cluster")

### cluster Type

`object` ([Snitch Cluster Schema](occamy-properties-snitch-cluster-schema.md))

## quadrant_pre_xbar

AXI Crossbar Properties

`quadrant_pre_xbar`

*   is optional

*   Type: `object` ([AXI Crossbar Schema](occamy-properties-axi-crossbar-schema-4.md))

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-axi-crossbar-schema-4.md "http://pulp-platform.org/snitch/axi_xbar.schema.json#/properties/quadrant_pre_xbar")

### quadrant_pre_xbar Type

`object` ([AXI Crossbar Schema](occamy-properties-axi-crossbar-schema-4.md))

## pre_xbar_slv_id_width_no_rocache

ID width of quadrant pre-crossbar slave ports assuming no read-only cache.

`pre_xbar_slv_id_width_no_rocache`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-pre_xbar_slv_id_width_no_rocache.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/pre_xbar_slv_id_width_no_rocache")

### pre_xbar_slv_id_width_no_rocache Type

`integer`

### pre_xbar_slv_id_width_no_rocache Default Value

The default value is:

```json
3
```

## wide_xbar

AXI Crossbar Properties

`wide_xbar`

*   is optional

*   Type: `object` ([AXI Crossbar Schema](occamy-properties-axi-crossbar-schema-4.md))

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-axi-crossbar-schema-4.md "http://pulp-platform.org/snitch/axi_xbar.schema.json#/properties/wide_xbar")

### wide_xbar Type

`object` ([AXI Crossbar Schema](occamy-properties-axi-crossbar-schema-4.md))

## quadrant_inter_xbar

AXI Crossbar Properties

`quadrant_inter_xbar`

*   is optional

*   Type: `object` ([AXI Crossbar Schema](occamy-properties-axi-crossbar-schema-4.md))

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-axi-crossbar-schema-4.md "http://pulp-platform.org/snitch/axi_xbar.schema.json#/properties/quadrant_inter_xbar")

### quadrant_inter_xbar Type

`object` ([AXI Crossbar Schema](occamy-properties-axi-crossbar-schema-4.md))

## hbm_xbar

AXI Crossbar Properties

`hbm_xbar`

*   is optional

*   Type: `object` ([AXI Crossbar Schema](occamy-properties-axi-crossbar-schema-4.md))

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-axi-crossbar-schema-4.md "http://pulp-platform.org/snitch/axi_xbar.schema.json#/properties/hbm_xbar")

### hbm_xbar Type

`object` ([AXI Crossbar Schema](occamy-properties-axi-crossbar-schema-4.md))

## narrow_xbar

AXI Crossbar Properties

`narrow_xbar`

*   is optional

*   Type: `object` ([AXI Crossbar Schema](occamy-properties-axi-crossbar-schema-4.md))

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-axi-crossbar-schema-4.md "http://pulp-platform.org/snitch/axi_xbar.schema.json#/properties/narrow_xbar")

### narrow_xbar Type

`object` ([AXI Crossbar Schema](occamy-properties-axi-crossbar-schema-4.md))

## narrow_xbar_slv_id_width

ID width of narrow crossbar slave ports.

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

## narrow_tlb_cfg

AXI TLB Properties

`narrow_tlb_cfg`

*   is optional

*   Type: `object` ([AXI TLB Schema](occamy-properties-axi-tlb-schema-1.md))

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-axi-tlb-schema-1.md "http://pulp-platform.org/snitch/axi_tlb.schema.json#/properties/narrow_tlb_cfg")

### narrow_tlb_cfg Type

`object` ([AXI TLB Schema](occamy-properties-axi-tlb-schema-1.md))

## wide_tlb_cfg

AXI TLB Properties

`wide_tlb_cfg`

*   is optional

*   Type: `object` ([AXI TLB Schema](occamy-properties-axi-tlb-schema-1.md))

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-axi-tlb-schema-1.md "http://pulp-platform.org/snitch/axi_tlb.schema.json#/properties/wide_tlb_cfg")

### wide_tlb_cfg Type

`object` ([AXI TLB Schema](occamy-properties-axi-tlb-schema-1.md))

## cuts



`cuts`

*   is optional

*   Type: `object` ([Number of cuts on the AXI bus](occamy-properties-number-of-cuts-on-the-axi-bus.md))

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-number-of-cuts-on-the-axi-bus.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/cuts")

### cuts Type

`object` ([Number of cuts on the AXI bus](occamy-properties-number-of-cuts-on-the-axi-bus.md))

## txns



`txns`

*   is optional

*   Type: `object` ([Number of outstanding transactions on the AXI bus](occamy-properties-number-of-outstanding-transactions-on-the-axi-bus.md))

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-number-of-outstanding-transactions-on-the-axi-bus.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/txns")

### txns Type

`object` ([Number of outstanding transactions on the AXI bus](occamy-properties-number-of-outstanding-transactions-on-the-axi-bus.md))

## is_remote_quadrant

Set if this is a remote quadrant. Only quadrant ant remote interconnect is generated

`is_remote_quadrant`

*   is optional

*   Type: `boolean`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-is_remote_quadrant.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/is_remote_quadrant")

### is_remote_quadrant Type

`boolean`

## remote_quadrants

List of attached remote quadrants

`remote_quadrants`

*   is optional

*   Type: `object[]` ([Remote Quadrant Description](occamy-properties-remote-quadrants-remote-quadrant-description.md))

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-remote-quadrants.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/remote_quadrants")

### remote_quadrants Type

`object[]` ([Remote Quadrant Description](occamy-properties-remote-quadrants-remote-quadrant-description.md))

### remote_quadrants Constraints

**minimum number of items**: the minimum number of items for this array is: `0`

## s1\_quadrant



`s1_quadrant`

*   is optional

*   Type: `object` ([S1 Quadrant Properties](occamy-properties-s1-quadrant-properties.md))

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-s1-quadrant-properties.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/s1\_quadrant")

### s1\_quadrant Type

`object` ([S1 Quadrant Properties](occamy-properties-s1-quadrant-properties.md))

## spm_narrow

Description of a generic address range

`spm_narrow`

*   is optional

*   Type: `object` ([Address Range Schema](occamy-properties-address-range-schema-3.md))

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-address-range-schema-3.md "http://pulp-platform.org/snitch/address_range.schema.json#/properties/spm_narrow")

### spm_narrow Type

`object` ([Address Range Schema](occamy-properties-address-range-schema-3.md))

## spm_wide

Description of a generic address range

`spm_wide`

*   is optional

*   Type: `object` ([Address Range Schema](occamy-properties-address-range-schema-3.md))

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-address-range-schema-3.md "http://pulp-platform.org/snitch/address_range.schema.json#/properties/spm_wide")

### spm_wide Type

`object` ([Address Range Schema](occamy-properties-address-range-schema-3.md))

## wide_zero_mem

Description of a generic address range

`wide_zero_mem`

*   is optional

*   Type: `object` ([Address Range Schema](occamy-properties-address-range-schema-3.md))

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-address-range-schema-3.md "http://pulp-platform.org/snitch/address_range.schema.json#/properties/wide_zero_mem")

### wide_zero_mem Type

`object` ([Address Range Schema](occamy-properties-address-range-schema-3.md))

## pcie



`pcie`

*   is optional

*   Type: `object` ([Configuration of external PCIe port](occamy-properties-configuration-of-external-pcie-port.md))

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-configuration-of-external-pcie-port.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/pcie")

### pcie Type

`object` ([Configuration of external PCIe port](occamy-properties-configuration-of-external-pcie-port.md))

## hbi

Description of a generic address range

`hbi`

*   is optional

*   Type: `object` ([Address Range Schema](occamy-properties-address-range-schema-3.md))

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-address-range-schema-3.md "http://pulp-platform.org/snitch/address_range.schema.json#/properties/hbi")

### hbi Type

`object` ([Address Range Schema](occamy-properties-address-range-schema-3.md))

## hbm



`hbm`

*   is optional

*   Type: `object` ([Configuration of external HBM interface](occamy-properties-configuration-of-external-hbm-interface.md))

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-configuration-of-external-hbm-interface.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/hbm")

### hbm Type

`object` ([Configuration of external HBM interface](occamy-properties-configuration-of-external-hbm-interface.md))

## peripherals

Description of an a peripheral sub-system.

`peripherals`

*   is optional

*   Type: `object` ([Peripherals Schema](occamy-properties-peripherals-schema.md))

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-peripherals-schema.md "http://pulp-platform.org/snitch/peripherals.schema.json#/properties/peripherals")

### peripherals Type

`object` ([Peripherals Schema](occamy-properties-peripherals-schema.md))
