# Core Description Schema

```txt
http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items
```

Description of a single core.

| Abstract            | Extensible | Status         | Identifiable | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                                       |
| :------------------ | :--------- | :------------- | :----------- | :---------------- | :-------------------- | :------------------ | :------------------------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | No           | Forbidden         | Allowed               | none                | [snitch_cluster.schema.json*](snitch_cluster.schema.json "open original schema") |

## items Type

`object` ([Core Description](snitch_cluster-properties-hives-hive-description-properties-cores-core-description.md))

# Core Description Properties

| Property                                                  | Type      | Required | Nullable       | Defined by                                                                                                                                                                                                                                                                                             |
| :-------------------------------------------------------- | :-------- | :------- | :------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [isa](#isa)                                               | `string`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-isa-string-containing-risc-v-standard-extensions.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/isa")  |
| [xssr](#xssr)                                             | `boolean` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-enable-xssr-extension.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/xssr")                            |
| [xfrep](#xfrep)                                           | `boolean` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-enable-xfrep-extension.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/xfrep")                          |
| [xdma](#xdma)                                             | `boolean` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-xdma-extension.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/xdma")                                   |
| [xf8](#xf8)                                               | `boolean` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-xf8-16-bit-float-extension.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/xf8")                        |
| [xf16](#xf16)                                             | `boolean` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-xf16-16-bit-float-extension.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/xf16")                      |
| [xf16alt](#xf16alt)                                       | `boolean` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-xf16alt-16-bit-brain-float-extension.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/xf16alt")          |
| [xfvec](#xfvec)                                           | `boolean` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-xfvec-extension.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/xfvec")                                 |
| [num_int_outstanding_loads](#num_int_outstanding_loads)   | `number`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-num_int_outstanding_loads.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/num_int_outstanding_loads")   |
| [num_int_outstanding_mem](#num_int_outstanding_mem)       | `number`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-num_int_outstanding_mem.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/num_int_outstanding_mem")       |
| [num_fp_outstanding_loads](#num_fp_outstanding_loads)     | `number`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-num_fp_outstanding_loads.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/num_fp_outstanding_loads")     |
| [num_fp_outstanding_mem](#num_fp_outstanding_mem)         | `number`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-num_fp_outstanding_mem.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/num_fp_outstanding_mem")         |
| [num_sequencer_instructions](#num_sequencer_instructions) | `number`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-num_sequencer_instructions.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/num_sequencer_instructions") |
| [num_itlb_entries](#num_itlb_entries)                     | `number`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-num_itlb_entries.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/num_itlb_entries")                     |
| [num_dtlb_entries](#num_dtlb_entries)                     | `number`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-num_dtlb_entries.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/num_dtlb_entries")                     |
| [ssr_mux_resp_depth](#ssr_mux_resp_depth)                 | `number`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-ssr_mux_resp_depth.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/ssr_mux_resp_depth")                 |
| [ssrs](#ssrs)                                             | `array`   | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-ssrs.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/ssrs")                                             |

## isa

ISA string as defined by the RISC-V standard. Only contain the standardized ISA extensions.

`isa`

*   is optional

*   Type: `string` ([ISA String containing RISC-V standard extensions.](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-isa-string-containing-risc-v-standard-extensions.md))

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-isa-string-containing-risc-v-standard-extensions.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/isa")

### isa Type

`string` ([ISA String containing RISC-V standard extensions.](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-isa-string-containing-risc-v-standard-extensions.md))

### isa Default Value

The default value is:

```json
"rv32imafd"
```

### isa Examples

```json
"rv32imafd"
```

## xssr

Stream Semantic Registers (Xssr) custom extension.

`xssr`

*   is optional

*   Type: `boolean` ([Enable Xssr Extension](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-enable-xssr-extension.md))

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-enable-xssr-extension.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/xssr")

### xssr Type

`boolean` ([Enable Xssr Extension](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-enable-xssr-extension.md))

### xssr Default Value

The default value is:

```json
true
```

## xfrep

Floating-point repetition buffer (Xfrep) custom extension.

`xfrep`

*   is optional

*   Type: `boolean` ([Enable Xfrep Extension](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-enable-xfrep-extension.md))

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-enable-xfrep-extension.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/xfrep")

### xfrep Type

`boolean` ([Enable Xfrep Extension](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-enable-xfrep-extension.md))

### xfrep Default Value

The default value is:

```json
true
```

## xdma

Direct memory access (Xdma) custom extension.

`xdma`

*   is optional

*   Type: `boolean` ([Xdma Extension](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-xdma-extension.md))

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-xdma-extension.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/xdma")

### xdma Type

`boolean` ([Xdma Extension](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-xdma-extension.md))

## xf8

Enable Smallfloat Xf8 extension (IEEE 8-bit float).

`xf8`

*   is optional

*   Type: `boolean` ([Xf8 16-bit Float Extension](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-xf8-16-bit-float-extension.md))

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-xf8-16-bit-float-extension.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/xf8")

### xf8 Type

`boolean` ([Xf8 16-bit Float Extension](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-xf8-16-bit-float-extension.md))

## xf16

Enable Smallfloat Xf16 extension (IEEE 16-bit float).

`xf16`

*   is optional

*   Type: `boolean` ([Xf16 16-bit Float Extension](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-xf16-16-bit-float-extension.md))

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-xf16-16-bit-float-extension.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/xf16")

### xf16 Type

`boolean` ([Xf16 16-bit Float Extension](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-xf16-16-bit-float-extension.md))

## xf16alt

Enable Smallfloat Xf16alt extension, also known as brain-float.

`xf16alt`

*   is optional

*   Type: `boolean` ([Xf16alt 16-bit Brain-Float Extension](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-xf16alt-16-bit-brain-float-extension.md))

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-xf16alt-16-bit-brain-float-extension.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/xf16alt")

### xf16alt Type

`boolean` ([Xf16alt 16-bit Brain-Float Extension](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-xf16alt-16-bit-brain-float-extension.md))

## xfvec

Enable Smallfloat vector extension (SIMD).

`xfvec`

*   is optional

*   Type: `boolean` ([Xfvec Extension](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-xfvec-extension.md))

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-xfvec-extension.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/xfvec")

### xfvec Type

`boolean` ([Xfvec Extension](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-xfvec-extension.md))

## num_int_outstanding_loads

Number of outstanding integer loads. Determines the buffer size in the core's load/store unit.

`num_int_outstanding_loads`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-num_int_outstanding_loads.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/num_int_outstanding_loads")

### num_int_outstanding_loads Type

`number`

### num_int_outstanding_loads Default Value

The default value is:

```json
1
```

## num_int_outstanding_mem

Number of outstanding memory operations. Determines the buffer size in the core's load/store unit.

`num_int_outstanding_mem`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-num_int_outstanding_mem.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/num_int_outstanding_mem")

### num_int_outstanding_mem Type

`number`

### num_int_outstanding_mem Default Value

The default value is:

```json
1
```

## num_fp_outstanding_loads

Number of outstanding floating-point loads. Determines the buffer size in the FPU's load/store unit.

`num_fp_outstanding_loads`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-num_fp_outstanding_loads.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/num_fp_outstanding_loads")

### num_fp_outstanding_loads Type

`number`

### num_fp_outstanding_loads Default Value

The default value is:

```json
4
```

## num_fp_outstanding_mem

Number of outstanding memory operations. Determines the buffer size in the core's load/store unit.

`num_fp_outstanding_mem`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-num_fp_outstanding_mem.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/num_fp_outstanding_mem")

### num_fp_outstanding_mem Type

`number`

### num_fp_outstanding_mem Default Value

The default value is:

```json
1
```

## num_sequencer_instructions

Amount of floating-point instruction the floating-point sequence buffer can hold.

`num_sequencer_instructions`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-num_sequencer_instructions.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/num_sequencer_instructions")

### num_sequencer_instructions Type

`number`

### num_sequencer_instructions Default Value

The default value is:

```json
16
```

## num_itlb_entries

Number of ITLB entries. Determines the core's size.

`num_itlb_entries`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-num_itlb_entries.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/num_itlb_entries")

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

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-num_dtlb_entries.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/num_dtlb_entries")

### num_dtlb_entries Type

`number`

### num_dtlb_entries Default Value

The default value is:

```json
2
```

## ssr_mux_resp_depth

Depth of response buffer in the TCDM multiplexer arbitrating between core and SSR 0.

`ssr_mux_resp_depth`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-ssr_mux_resp_depth.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/ssr_mux_resp_depth")

### ssr_mux_resp_depth Type

`number`

### ssr_mux_resp_depth Default Value

The default value is:

```json
4
```

## ssrs

List of all SSRs in the respective core.

`ssrs`

*   is optional

*   Type: `object[]` ([SSR Description](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-ssrs-ssr-description.md))

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-ssrs.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/ssrs")

### ssrs Type

`object[]` ([SSR Description](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-ssrs-ssr-description.md))

### ssrs Constraints

**minimum number of items**: the minimum number of items for this array is: `0`

### ssrs Default Value

The default value is:

```json
[
  {},
  {},
  {}
]
```
