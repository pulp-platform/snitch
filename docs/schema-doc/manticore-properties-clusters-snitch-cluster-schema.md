# Snitch Cluster Schema Schema

```txt
http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/clusters/items
```

Base description of a Snitch cluster and its internal structure and configuration.


| Abstract            | Extensible | Status         | Identifiable | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                              |
| :------------------ | ---------- | -------------- | ------------ | :---------------- | --------------------- | ------------------- | ----------------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | No           | Forbidden         | Allowed               | none                | [manticore.schema.json\*](manticore.schema.json "open original schema") |

## items Type

`object` ([Snitch Cluster Schema](manticore-properties-clusters-snitch-cluster-schema.md))

# Snitch Cluster Schema Properties

| Property                                                          | Type     | Required | Nullable       | Defined by                                                                                                                                                                                        |
| :---------------------------------------------------------------- | -------- | -------- | -------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| [boot_address](#boot_address)                                     | `number` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-boot_address.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/boot_address")                                     |
| [cluster_base_address](#cluster_base_address)                     | `number` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-cluster_base_address.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/cluster_base_address")                     |
| [addr_len](#addr_len)                                             | `number` | Required | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-addr_len.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/addr_len")                                             |
| [data_len](#data_len)                                             | `number` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-data_len.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/data_len")                                             |
| [dma_data_len](#dma_data_len)                                     | `number` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-dma_data_len.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/dma_data_len")                                     |
| [cluster_xbar_latency](#cluster_xbar_latency)                     | `string` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-cluster_xbar_latency.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/cluster_xbar_latency")                     |
| [dma_xbar_latency](#dma_xbar_latency)                             | `string` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-dma_xbar_latency.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/dma_xbar_latency")                             |
| [base_hart_id](#base_hart_id)                                     | `number` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-base_hart_id.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/base_hart_id")                                     |
| [mode](#mode)                                                     | `string` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-mode.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/mode")                                                     |
| [vm](#vm)                                                         | `string` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-vm.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/vm")                                                         |
| [ssr_nr_credits](#ssr_nr_credits)                                 | `number` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-ssr_nr_credits.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/ssr_nr_credits")                                 |
| [num_int_outstanding_loads](#num_int_outstanding_loads)           | `number` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-num_int_outstanding_loads.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/num_int_outstanding_loads")           |
| [num_fpu_outstanding_loads](#num_fpu_outstanding_loads)           | `number` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-num_fpu_outstanding_loads.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/num_fpu_outstanding_loads")           |
| [num_fpu_sequencer_instructions](#num_fpu_sequencer_instructions) | `number` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-num_fpu_sequencer_instructions.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/num_fpu_sequencer_instructions") |
| [num_ipu_sequencer_instructions](#num_ipu_sequencer_instructions) | `number` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-num_ipu_sequencer_instructions.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/num_ipu_sequencer_instructions") |
| [num_itlb_entries](#num_itlb_entries)                             | `number` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-num_itlb_entries.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/num_itlb_entries")                             |
| [num_dtlb_entries](#num_dtlb_entries)                             | `number` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-num_dtlb_entries.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/num_dtlb_entries")                             |
| [dma_axi_req_fifo_depth](#dma_axi_req_fifo_depth)                 | `number` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-dma_axi_req_fifo_depth.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/dma_axi_req_fifo_depth")                 |
| [dma_req_fifo_depth](#dma_req_fifo_depth)                         | `number` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-dma_req_fifo_depth.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/dma_req_fifo_depth")                         |
| [lat_comp_fp32](#lat_comp_fp32)                                   | `number` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-lat_comp_fp32.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/lat_comp_fp32")                                   |
| [lat_comp_fp64](#lat_comp_fp64)                                   | `number` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-lat_comp_fp64.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/lat_comp_fp64")                                   |
| [lat_comp_fp16](#lat_comp_fp16)                                   | `number` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-lat_comp_fp16.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/lat_comp_fp16")                                   |
| [lat_comp_fp16_alt](#lat_comp_fp16_alt)                           | `number` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-lat_comp_fp16_alt.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/lat_comp_fp16_alt")                           |
| [lat_comp_fp8](#lat_comp_fp8)                                     | `number` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-lat_comp_fp8.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/lat_comp_fp8")                                     |
| [lat_noncomp](#lat_noncomp)                                       | `number` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-lat_noncomp.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/lat_noncomp")                                       |
| [lat_conv](#lat_conv)                                             | `number` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-lat_conv.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/lat_conv")                                             |
| [fpu_pipe_config](#fpu_pipe_config)                               | `string` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-fpu_pipe_config.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/fpu_pipe_config")                               |
| [cores](#cores)                                                   | `array`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-cores.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/cores")                                                   |

## boot_address

Address from which all harts of the cluster start to boot. The default setting is `0x8000_0000`.


`boot_address`

-   is optional
-   Type: `number`
-   cannot be null
-   defined in: [Snitch Cluster Schema](snitch_cluster-properties-boot_address.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/boot_address")

### boot_address Type

`number`

### boot_address Default Value

The default value is:

```json
2147483648
```

## cluster_base_address

Base address of this cluster.


`cluster_base_address`

-   is optional
-   Type: `number`
-   cannot be null
-   defined in: [Snitch Cluster Schema](snitch_cluster-properties-cluster_base_address.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/cluster_base_address")

### cluster_base_address Type

`number`

## addr_len

Length of the address, should be greater than 30. If the address is larger than 34 the data bus needs to be 64 bits in size.


`addr_len`

-   is required
-   Type: `number`
-   cannot be null
-   defined in: [Snitch Cluster Schema](snitch_cluster-properties-addr_len.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/addr_len")

### addr_len Type

`number`

### addr_len Default Value

The default value is:

```json
48
```

## data_len

Data bus size of the integer core (everything except the DMA), must be 32 or 64. A double precision FPU requires 64 bit data length.


`data_len`

-   is optional
-   Type: `number`
-   cannot be null
-   defined in: [Snitch Cluster Schema](snitch_cluster-properties-data_len.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/data_len")

### data_len Type

`number`

### data_len Default Value

The default value is:

```json
64
```

## dma_data_len

Data bus size of DMA. Usually this is larger than the integer core as the DMA is used to efficiently transfer bulk of data.


`dma_data_len`

-   is optional
-   Type: `number`
-   cannot be null
-   defined in: [Snitch Cluster Schema](snitch_cluster-properties-dma_data_len.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/dma_data_len")

### dma_data_len Type

`number`

### dma_data_len Default Value

The default value is:

```json
512
```

## cluster_xbar_latency

Latency mode of the cluster crossbar.


`cluster_xbar_latency`

-   is optional
-   Type: `string`
-   cannot be null
-   defined in: [Snitch Cluster Schema](snitch_cluster-properties-cluster_xbar_latency.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/cluster_xbar_latency")

### cluster_xbar_latency Type

`string`

### cluster_xbar_latency Constraints

**enum**: the value of this property must be equal to one of the following values:

| Value             | Explanation |
| :---------------- | ----------- |
| `"NO_LATENCY"`    |             |
| `"CUT_SLV_AX"`    |             |
| `"CUT_MST_AX"`    |             |
| `"CUT_ALL_AX"`    |             |
| `"CUT_SLV_PORTS"` |             |
| `"CUT_MST_PORTS"` |             |
| `"CUT_ALL_PORTS"` |             |

### cluster_xbar_latency Default Value

The default value is:

```json
"CUT_ALL_PORTS"
```

## dma_xbar_latency

Latency mode of the DMA crossbar.


`dma_xbar_latency`

-   is optional
-   Type: `string`
-   cannot be null
-   defined in: [Snitch Cluster Schema](snitch_cluster-properties-dma_xbar_latency.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/dma_xbar_latency")

### dma_xbar_latency Type

`string`

### dma_xbar_latency Constraints

**enum**: the value of this property must be equal to one of the following values:

| Value             | Explanation |
| :---------------- | ----------- |
| `"NO_LATENCY"`    |             |
| `"CUT_SLV_AX"`    |             |
| `"CUT_MST_AX"`    |             |
| `"CUT_ALL_AX"`    |             |
| `"CUT_SLV_PORTS"` |             |
| `"CUT_MST_PORTS"` |             |
| `"CUT_ALL_PORTS"` |             |

### dma_xbar_latency Default Value

The default value is:

```json
"CUT_ALL_PORTS"
```

## base_hart_id

Base hart id of the cluster. All cores get the respective cluster id plus their cluster position as the final `hart_id`.


`base_hart_id`

-   is optional
-   Type: `number`
-   cannot be null
-   defined in: [Snitch Cluster Schema](snitch_cluster-properties-base_hart_id.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/base_hart_id")

### base_hart_id Type

`number`

## mode

Supported mode by the processor, can be msu.


`mode`

-   is optional
-   Type: `string`
-   cannot be null
-   defined in: [Snitch Cluster Schema](snitch_cluster-properties-mode.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/mode")

### mode Type

`string`

## vm

Supported virtual memory mode, can be XSv32.


`vm`

-   is optional
-   Type: `string`
-   cannot be null
-   defined in: [Snitch Cluster Schema](snitch_cluster-properties-vm.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/vm")

### vm Type

`string`

### vm Constraints

**enum**: the value of this property must be equal to one of the following values:

| Value     | Explanation |
| :-------- | ----------- |
| `"Sv32"`  |             |
| `"XSv48"` |             |

### vm Default Value

The default value is:

```json
"XSv48"
```

## ssr_nr_credits

Number of credits and buffer depth of SSR FIFOs.


`ssr_nr_credits`

-   is optional
-   Type: `number`
-   cannot be null
-   defined in: [Snitch Cluster Schema](snitch_cluster-properties-ssr_nr_credits.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/ssr_nr_credits")

### ssr_nr_credits Type

`number`

### ssr_nr_credits Default Value

The default value is:

```json
4
```

## num_int_outstanding_loads

Number of outstanding integer loads. Determines the buffer size in the core's load/store unit.


`num_int_outstanding_loads`

-   is optional
-   Type: `number`
-   cannot be null
-   defined in: [Snitch Cluster Schema](snitch_cluster-properties-num_int_outstanding_loads.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/num_int_outstanding_loads")

### num_int_outstanding_loads Type

`number`

### num_int_outstanding_loads Default Value

The default value is:

```json
1
```

## num_fpu_outstanding_loads

Number of outstanding floating-point loads. Determines the buffer size in the FPU's load/store unit.


`num_fpu_outstanding_loads`

-   is optional
-   Type: `number`
-   cannot be null
-   defined in: [Snitch Cluster Schema](snitch_cluster-properties-num_fpu_outstanding_loads.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/num_fpu_outstanding_loads")

### num_fpu_outstanding_loads Type

`number`

### num_fpu_outstanding_loads Default Value

The default value is:

```json
4
```

## num_fpu_sequencer_instructions

Amount of floating-point instruction the floating-point sequence buffer can hold.


`num_fpu_sequencer_instructions`

-   is optional
-   Type: `number`
-   cannot be null
-   defined in: [Snitch Cluster Schema](snitch_cluster-properties-num_fpu_sequencer_instructions.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/num_fpu_sequencer_instructions")

### num_fpu_sequencer_instructions Type

`number`

### num_fpu_sequencer_instructions Default Value

The default value is:

```json
16
```

## num_ipu_sequencer_instructions

Amount of integer instruction the integer sequence buffer can hold.


`num_ipu_sequencer_instructions`

-   is optional
-   Type: `number`
-   cannot be null
-   defined in: [Snitch Cluster Schema](snitch_cluster-properties-num_ipu_sequencer_instructions.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/num_ipu_sequencer_instructions")

### num_ipu_sequencer_instructions Type

`number`

### num_ipu_sequencer_instructions Default Value

The default value is:

```json
16
```

## num_itlb_entries

Number of ITLB entries. Determines the core's size.


`num_itlb_entries`

-   is optional
-   Type: `number`
-   cannot be null
-   defined in: [Snitch Cluster Schema](snitch_cluster-properties-num_itlb_entries.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/num_itlb_entries")

### num_itlb_entries Type

`number`

### num_itlb_entries Default Value

The default value is:

```json
1
```

## num_dtlb_entries

Number of DTLB entries. Determines the core's size.


`num_dtlb_entries`

-   is optional
-   Type: `number`
-   cannot be null
-   defined in: [Snitch Cluster Schema](snitch_cluster-properties-num_dtlb_entries.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/num_dtlb_entries")

### num_dtlb_entries Type

`number`

### num_dtlb_entries Default Value

The default value is:

```json
2
```

## dma_axi_req_fifo_depth

Number of AXI FIFO entries of the DMA engine.


`dma_axi_req_fifo_depth`

-   is optional
-   Type: `number`
-   cannot be null
-   defined in: [Snitch Cluster Schema](snitch_cluster-properties-dma_axi_req_fifo_depth.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/dma_axi_req_fifo_depth")

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

-   is optional
-   Type: `number`
-   cannot be null
-   defined in: [Snitch Cluster Schema](snitch_cluster-properties-dma_req_fifo_depth.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/dma_req_fifo_depth")

### dma_req_fifo_depth Type

`number`

### dma_req_fifo_depth Default Value

The default value is:

```json
3
```

## lat_comp_fp32

Latency setting (number of pipeline stages) for FP32.


`lat_comp_fp32`

-   is optional
-   Type: `number`
-   cannot be null
-   defined in: [Snitch Cluster Schema](snitch_cluster-properties-lat_comp_fp32.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/lat_comp_fp32")

### lat_comp_fp32 Type

`number`

### lat_comp_fp32 Default Value

The default value is:

```json
3
```

## lat_comp_fp64

Latency setting (number of pipeline stages) for FP64.


`lat_comp_fp64`

-   is optional
-   Type: `number`
-   cannot be null
-   defined in: [Snitch Cluster Schema](snitch_cluster-properties-lat_comp_fp64.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/lat_comp_fp64")

### lat_comp_fp64 Type

`number`

### lat_comp_fp64 Default Value

The default value is:

```json
3
```

## lat_comp_fp16

Latency setting (number of pipeline stages) for FP16.


`lat_comp_fp16`

-   is optional
-   Type: `number`
-   cannot be null
-   defined in: [Snitch Cluster Schema](snitch_cluster-properties-lat_comp_fp16.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/lat_comp_fp16")

### lat_comp_fp16 Type

`number`

### lat_comp_fp16 Default Value

The default value is:

```json
1
```

## lat_comp_fp16_alt

Latency setting (number of pipeline stages) for FP16alt (brainfloat).


`lat_comp_fp16_alt`

-   is optional
-   Type: `number`
-   cannot be null
-   defined in: [Snitch Cluster Schema](snitch_cluster-properties-lat_comp_fp16_alt.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/lat_comp_fp16_alt")

### lat_comp_fp16_alt Type

`number`

### lat_comp_fp16_alt Default Value

The default value is:

```json
2
```

## lat_comp_fp8

Latency setting (number of pipeline stages) for FP32 (fp8).


`lat_comp_fp8`

-   is optional
-   Type: `number`
-   cannot be null
-   defined in: [Snitch Cluster Schema](snitch_cluster-properties-lat_comp_fp8.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/lat_comp_fp8")

### lat_comp_fp8 Type

`number`

### lat_comp_fp8 Default Value

The default value is:

```json
1
```

## lat_noncomp

Latency setting (number of pipeline stages) for floating-point non-computational instructions (except conversions), i.e., `classify`, etc.


`lat_noncomp`

-   is optional
-   Type: `number`
-   cannot be null
-   defined in: [Snitch Cluster Schema](snitch_cluster-properties-lat_noncomp.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/lat_noncomp")

### lat_noncomp Type

`number`

### lat_noncomp Default Value

The default value is:

```json
1
```

## lat_conv

Latency setting (number of pipeline stages) for floating-point conversion instructions.


`lat_conv`

-   is optional
-   Type: `number`
-   cannot be null
-   defined in: [Snitch Cluster Schema](snitch_cluster-properties-lat_conv.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/lat_conv")

### lat_conv Type

`number`

### lat_conv Default Value

The default value is:

```json
1
```

## fpu_pipe_config

Pipeline configuration (i.e., position of the registers) of the FPU.


`fpu_pipe_config`

-   is optional
-   Type: `string`
-   cannot be null
-   defined in: [Snitch Cluster Schema](snitch_cluster-properties-fpu_pipe_config.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/fpu_pipe_config")

### fpu_pipe_config Type

`string`

### fpu_pipe_config Constraints

**enum**: the value of this property must be equal to one of the following values:

| Value           | Explanation |
| :-------------- | ----------- |
| `"BEFORE"`      |             |
| `"AFTER"`       |             |
| `"INSIDE"`      |             |
| `"DISTRIBUTED"` |             |

### fpu_pipe_config Default Value

The default value is:

```json
"BEFORE"
```

## cores

List of all cores in the respective cluster.


`cores`

-   is optional
-   Type: `object[]` ([Core Description](snitch_cluster-properties-cores-core-description.md))
-   cannot be null
-   defined in: [Snitch Cluster Schema](snitch_cluster-properties-cores.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/cores")

### cores Type

`object[]` ([Core Description](snitch_cluster-properties-cores-core-description.md))

### cores Constraints

**minimum number of items**: the minimum number of items for this array is: `1`
