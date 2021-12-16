# Snitch Cluster Schema Schema

```txt
http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/cluster
```

Base description of a Snitch cluster and its internal structure and configuration.

| Abstract            | Extensible | Status         | Identifiable | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                       |
| :------------------ | :--------- | :------------- | :----------- | :---------------- | :-------------------- | :------------------ | :--------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | No           | Forbidden         | Allowed               | none                | [occamy.schema.json*](occamy.schema.json "open original schema") |

## cluster Type

`object` ([Snitch Cluster Schema](occamy-properties-snitch-cluster-schema.md))

# Snitch Cluster Schema Properties

| Property                                          | Type      | Required | Nullable       | Defined by                                                                                                                                                                   |
| :------------------------------------------------ | :-------- | :------- | :------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [name](#name)                                     | `string`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-name.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/name")                                     |
| [boot_addr](#boot_addr)                           | `number`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-boot_addr.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/boot_addr")                           |
| [cluster_base_addr](#cluster_base_addr)           | `number`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-cluster_base_addr.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/cluster_base_addr")           |
| [tcdm](#tcdm)                                     | `object`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-tcdm.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/tcdm")                                     |
| [addr_width](#addr_width)                         | `number`  | Required | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-addr_width.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/addr_width")                         |
| [data_width](#data_width)                         | `number`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-data_width.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/data_width")                         |
| [dma_data_width](#dma_data_width)                 | `number`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-dma_data_width.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/dma_data_width")                 |
| [id_width_in](#id_width_in)                       | `number`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-id_width_in.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/id_width_in")                       |
| [dma_id_width_in](#dma_id_width_in)               | `number`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-dma_id_width_in.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/dma_id_width_in")               |
| [hart_base_id](#hart_base_id)                     | `number`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-hart_base_id.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hart_base_id")                     |
| [mode](#mode)                                     | `string`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-mode.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/mode")                                     |
| [vm](#vm)                                         | `string`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-vm.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/vm")                                         |
| [dma_axi_req_fifo_depth](#dma_axi_req_fifo_depth) | `number`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-dma_axi_req_fifo_depth.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/dma_axi_req_fifo_depth") |
| [dma_req_fifo_depth](#dma_req_fifo_depth)         | `number`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-dma_req_fifo_depth.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/dma_req_fifo_depth")         |
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

## vm

Supported virtual memory mode, can be XSv32.

> Currently ignored.

`vm`

*   is optional

*   Type: `string`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-vm.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/vm")

### vm Type

`string`

### vm Constraints

**enum**: the value of this property must be equal to one of the following values:

| Value     | Explanation |
| :-------- | :---------- |
| `"Sv32"`  |             |
| `"XSv48"` |             |

### vm Default Value

The default value is:

```json
"XSv48"
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
