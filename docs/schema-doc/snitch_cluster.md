# Snitch Cluster Schema Schema

```txt
http://pulp-platform.org/snitch/snitch_cluster.schema.json
```

Base description of a Snitch cluster and its internal structure and configuration.

| Abstract            | Extensible | Status         | Identifiable | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                                      |
| :------------------ | :--------- | :------------- | :----------- | :---------------- | :-------------------- | :------------------ | :------------------------------------------------------------------------------ |
| Can be instantiated | No         | Unknown status | No           | Forbidden         | Allowed               | none                | [snitch_cluster.schema.json](snitch_cluster.schema.json "open original schema") |

## Snitch Cluster Schema Type

`object` ([Snitch Cluster Schema](snitch_cluster.md))

# Snitch Cluster Schema Properties

| Property                                          | Type      | Required | Nullable       | Defined by                                                                                                                                                                   |
| :------------------------------------------------ | :-------- | :------- | :------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [name](#name)                                     | `string`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-name.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/name")                                     |
| [boot_addr](#boot_addr)                           | `number`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-boot_addr.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/boot_addr")                           |
| [cluster_base_addr](#cluster_base_addr)           | `number`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-cluster_base_addr.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/cluster_base_addr")           |
| [tcdm](#tcdm)                                     | `object`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-tcdm.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/tcdm")                                     |
| [cluster_periph_size](#cluster_periph_size)       | `number`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-cluster_periph_size.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/cluster_periph_size")       |
| [zero_mem_size](#zero_mem_size)                   | `number`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-zero_mem_size.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/zero_mem_size")                   |
| [addr_width](#addr_width)                         | `number`  | Required | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-addr_width.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/addr_width")                         |
| [data_width](#data_width)                         | `number`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-data_width.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/data_width")                         |
| [dma_data_width](#dma_data_width)                 | `number`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-dma_data_width.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/dma_data_width")                 |
| [narrow_trans](#narrow_trans)                     | `number`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-narrow_trans.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/narrow_trans")                     |
| [wide_trans](#wide_trans)                         | `number`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-wide_trans.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/wide_trans")                         |
| [id_width_in](#id_width_in)                       | `number`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-id_width_in.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/id_width_in")                       |
| [dma_id_width_in](#dma_id_width_in)               | `number`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-dma_id_width_in.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/dma_id_width_in")               |
| [user_width](#user_width)                         | `number`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-user_width.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/user_width")                         |
| [dma_user_width](#dma_user_width)                 | `number`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-dma_user_width.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/dma_user_width")                 |
| [hart_base_id](#hart_base_id)                     | `number`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-hart_base_id.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hart_base_id")                     |
| [mode](#mode)                                     | `string`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-mode.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/mode")                                     |
| [vm_support](#vm_support)                         | `boolean` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-vm_support.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/vm_support")                         |
| [dma_axi_req_fifo_depth](#dma_axi_req_fifo_depth) | `number`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-dma_axi_req_fifo_depth.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/dma_axi_req_fifo_depth") |
| [dma_req_fifo_depth](#dma_req_fifo_depth)         | `number`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-dma_req_fifo_depth.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/dma_req_fifo_depth")         |
| [enable_debug](#enable_debug)                     | `boolean` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-enable_debug.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/enable_debug")                     |
| [sram_cfg_expose](#sram_cfg_expose)               | `boolean` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-sram_cfg_expose.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/sram_cfg_expose")               |
| [sram_cfg_fields](#sram_cfg_fields)               | `object`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-sram_cfg_fields.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/sram_cfg_fields")               |
| [timing](#timing)                                 | `object`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-timing-and-latency-tuning-parameter.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing")    |
| [hives](#hives)                                   | `array`   | Required | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-hives.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives")                                   |

## name

Optional name for the generated wrapper.

`name`

*   is optional

*   Type: `string`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-name.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/name")

### name Type

`string`

### name Default Value

The default value is:

```json
"snitch_cluster"
```

## boot_addr

Address from which all harts of the cluster start to boot. The default setting is `0x8000_0000`.

`boot_addr`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-boot_addr.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/boot_addr")

### boot_addr Type

`number`

### boot_addr Default Value

The default value is:

```json
2147483648
```

## cluster_base_addr

Base address of this cluster.

`cluster_base_addr`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-cluster_base_addr.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/cluster_base_addr")

### cluster_base_addr Type

`number`

## tcdm

Configuration of the Tightly Coupled Data Memory of this cluster.

`tcdm`

*   is optional

*   Type: `object` ([Details](snitch_cluster-properties-tcdm.md))

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-tcdm.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/tcdm")

### tcdm Type

`object` ([Details](snitch_cluster-properties-tcdm.md))

### tcdm Default Value

The default value is:

```json
{
  "size": 128,
  "banks": 32
}
```

## cluster_periph_size

Address region size reserved for cluster peripherals in KiByte.

`cluster_periph_size`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-cluster_periph_size.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/cluster_periph_size")

### cluster_periph_size Type

`number`

### cluster_periph_size Examples

```json
128
```

```json
64
```

## zero_mem_size

Address region size reserved for the Zero-Memory in KiByte.

`zero_mem_size`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-zero_mem_size.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/zero_mem_size")

### zero_mem_size Type

`number`

### zero_mem_size Examples

```json
128
```

```json
64
```

## addr_width

Length of the address, should be greater than 30. If the address is larger than 34 the data bus needs to be 64 bits in size.

`addr_width`

*   is required

*   Type: `number`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-addr_width.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/addr_width")

### addr_width Type

`number`

### addr_width Default Value

The default value is:

```json
48
```

## data_width

Data bus size of the integer core (everything except the DMA), must be 32 or 64. A double precision FPU requires 64 bit data length.

`data_width`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-data_width.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/data_width")

### data_width Type

`number`

### data_width Default Value

The default value is:

```json
64
```

## dma_data_width

Data bus size of DMA. Usually this is larger than the integer core as the DMA is used to efficiently transfer bulk of data.

`dma_data_width`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-dma_data_width.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/dma_data_width")

### dma_data_width Type

`number`

### dma_data_width Default Value

The default value is:

```json
512
```

## narrow_trans

Outstanding transactions on the narrow AXI network

`narrow_trans`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-narrow_trans.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/narrow_trans")

### narrow_trans Type

`number`

### narrow_trans Default Value

The default value is:

```json
4
```

## wide_trans

Outstanding transactions on the wide AXI network

`wide_trans`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-wide_trans.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/wide_trans")

### wide_trans Type

`number`

### wide_trans Default Value

The default value is:

```json
4
```

## id_width_in

Id width of the narrower AXI plug into the cluster.

`id_width_in`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-id_width_in.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/id_width_in")

### id_width_in Type

`number`

### id_width_in Default Value

The default value is:

```json
2
```

## dma_id_width_in

Id width of the wide AXI plug into the cluster.

`dma_id_width_in`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-dma_id_width_in.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/dma_id_width_in")

### dma_id_width_in Type

`number`

### dma_id_width_in Default Value

The default value is:

```json
1
```

## user_width

User width of the narrower AXI plug into the cluster.

`user_width`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-user_width.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/user_width")

### user_width Type

`number`

### user_width Default Value

The default value is:

```json
1
```

## dma_user_width

User width of the wide AXI plug into the cluster.

`dma_user_width`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-dma_user_width.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/dma_user_width")

### dma_user_width Type

`number`

### dma_user_width Default Value

The default value is:

```json
1
```

## hart_base_id

Base hart id of the cluster. All cores get the respective cluster id plus their cluster position as the final `hart_id`.

`hart_base_id`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-hart_base_id.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hart_base_id")

### hart_base_id Type

`number`

## mode

Supported mode by the processor, can be msu.

> Currently ignored.

`mode`

*   is optional

*   Type: `string`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-mode.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/mode")

### mode Type

`string`

## vm_support

Whether to provide virtual memory support (Sv32).

`vm_support`

*   is optional

*   Type: `boolean`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-vm_support.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/vm_support")

### vm_support Type

`boolean`

### vm_support Default Value

The default value is:

```json
true
```

## dma_axi_req_fifo_depth

Number of AXI FIFO entries of the DMA engine.

`dma_axi_req_fifo_depth`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-dma_axi_req_fifo_depth.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/dma_axi_req_fifo_depth")

### dma_axi_req_fifo_depth Type

`number`

### dma_axi_req_fifo_depth Default Value

The default value is:

```json
3
```

## dma_req_fifo_depth

Number of request entries the DMA can keep

`dma_req_fifo_depth`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-dma_req_fifo_depth.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/dma_req_fifo_depth")

### dma_req_fifo_depth Type

`number`

### dma_req_fifo_depth Default Value

The default value is:

```json
3
```

## enable_debug

Whether to provide a debug request input and external debug features

`enable_debug`

*   is optional

*   Type: `boolean`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-enable_debug.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/enable_debug")

### enable_debug Type

`boolean`

### enable_debug Default Value

The default value is:

```json
true
```

## sram_cfg_expose

Whether to expose memory cut configuration inputs for implementation

`sram_cfg_expose`

*   is optional

*   Type: `boolean`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-sram_cfg_expose.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/sram_cfg_expose")

### sram_cfg_expose Type

`boolean`

## sram_cfg_fields

The names and widths of memory cut configuration inputs needed for implementation

`sram_cfg_fields`

*   is optional

*   Type: `object` ([Details](snitch_cluster-properties-sram_cfg_fields.md))

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-sram_cfg_fields.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/sram_cfg_fields")

### sram_cfg_fields Type

`object` ([Details](snitch_cluster-properties-sram_cfg_fields.md))

### sram_cfg_fields Constraints

**minimum number of properties**: the minimum number of properties for this object is: `1`

### sram_cfg_fields Default Value

The default value is:

```json
{
  "reserved": 1
}
```

## timing



`timing`

*   is optional

*   Type: `object` ([Timing and Latency Tuning Parameter](snitch_cluster-properties-timing-and-latency-tuning-parameter.md))

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-timing-and-latency-tuning-parameter.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing")

### timing Type

`object` ([Timing and Latency Tuning Parameter](snitch_cluster-properties-timing-and-latency-tuning-parameter.md))

## hives

Cores in a hive share an instruction cache and other shared infrastructure such as the PTW or the multiply/divide unit.

`hives`

*   is required

*   Type: `object[]` ([Hive Description](snitch_cluster-properties-hives-hive-description.md))

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-hives.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives")

### hives Type

`object[]` ([Hive Description](snitch_cluster-properties-hives-hive-description.md))

### hives Constraints

**minimum number of items**: the minimum number of items for this array is: `1`
