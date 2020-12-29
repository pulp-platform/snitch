# Core Description Schema

```txt
http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/cores/items
```

Description of a single core.


| Abstract            | Extensible | Status         | Identifiable | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                                        |
| :------------------ | ---------- | -------------- | ------------ | :---------------- | --------------------- | ------------------- | --------------------------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | No           | Forbidden         | Allowed               | none                | [snitch_cluster.schema.json\*](snitch_cluster.schema.json "open original schema") |

## items Type

`object` ([Core Description](snitch_cluster-properties-hives-items-cores-core-description.md))

# Core Description Properties

| Property                                                          | Type     | Required | Nullable       | Defined by                                                                                                                                                                                                                                                                         |
| :---------------------------------------------------------------- | -------- | -------- | -------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [isa](#isa)                                                       | `string` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-hives-items-cores-core-description-properties-isa-string-containing-risc-v-standard-extensions.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/cores/items/properties/isa")          |
| [xssr](#xssr)                                                     | `bool`   | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-hives-items-cores-core-description-properties-enable-xssr-extension.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/cores/items/properties/xssr")                                    |
| [xfrep](#xfrep)                                                   | `bool`   | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-hives-items-cores-core-description-properties-enable-xfrep-extension.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/cores/items/properties/xfrep")                                  |
| [xdma](#xdma)                                                     | `bool`   | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-hives-items-cores-core-description-properties-xdma-extension.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/cores/items/properties/xdma")                                           |
| [ssr_nr_credits](#ssr_nr_credits)                                 | `number` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-hives-items-cores-core-description-properties-ssr_nr_credits.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/cores/items/properties/ssr_nr_credits")                                 |
| [num_int_outstanding_loads](#num_int_outstanding_loads)           | `number` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-hives-items-cores-core-description-properties-num_int_outstanding_loads.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/cores/items/properties/num_int_outstanding_loads")           |
| [num_int_outstanding_mem](#num_int_outstanding_mem)               | `number` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-hives-items-cores-core-description-properties-num_int_outstanding_mem.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/cores/items/properties/num_int_outstanding_mem")               |
| [num_fpu_outstanding_loads](#num_fpu_outstanding_loads)           | `number` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-hives-items-cores-core-description-properties-num_fpu_outstanding_loads.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/cores/items/properties/num_fpu_outstanding_loads")           |
| [num_fp_outstanding_mem](#num_fp_outstanding_mem)                 | `number` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-hives-items-cores-core-description-properties-num_fp_outstanding_mem.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/cores/items/properties/num_fp_outstanding_mem")                 |
| [num_fpu_sequencer_instructions](#num_fpu_sequencer_instructions) | `number` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-hives-items-cores-core-description-properties-num_fpu_sequencer_instructions.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/cores/items/properties/num_fpu_sequencer_instructions") |
| [num_ipu_sequencer_instructions](#num_ipu_sequencer_instructions) | `number` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-hives-items-cores-core-description-properties-num_ipu_sequencer_instructions.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/cores/items/properties/num_ipu_sequencer_instructions") |
| [num_itlb_entries](#num_itlb_entries)                             | `number` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-hives-items-cores-core-description-properties-num_itlb_entries.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/cores/items/properties/num_itlb_entries")                             |
| [num_dtlb_entries](#num_dtlb_entries)                             | `number` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-hives-items-cores-core-description-properties-num_dtlb_entries.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/cores/items/properties/num_dtlb_entries")                             |

## isa

ISA string as defined by the RISC-V standard. Only contain the standardized ISA extensions.


`isa`

-   is optional
-   Type: `string` ([ISA String containing RISC-V standard extensions.](snitch_cluster-properties-hives-items-cores-core-description-properties-isa-string-containing-risc-v-standard-extensions.md))
-   cannot be null
-   defined in: [Snitch Cluster Schema](snitch_cluster-properties-hives-items-cores-core-description-properties-isa-string-containing-risc-v-standard-extensions.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/cores/items/properties/isa")

### isa Type

`string` ([ISA String containing RISC-V standard extensions.](snitch_cluster-properties-hives-items-cores-core-description-properties-isa-string-containing-risc-v-standard-extensions.md))

### isa Examples

```json
"rv32imafd"
```

## xssr

Stream Semantic Registers (SSR) custom extension.


`xssr`

-   is optional
-   Type: `bool` ([Enable Xssr Extension](snitch_cluster-properties-hives-items-cores-core-description-properties-enable-xssr-extension.md))
-   cannot be null
-   defined in: [Snitch Cluster Schema](snitch_cluster-properties-hives-items-cores-core-description-properties-enable-xssr-extension.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/cores/items/properties/xssr")

### xssr Type

`bool` ([Enable Xssr Extension](snitch_cluster-properties-hives-items-cores-core-description-properties-enable-xssr-extension.md))

## xfrep

Floating-point repetition buffer (FREP) custom extension.


`xfrep`

-   is optional
-   Type: `bool` ([Enable Xfrep Extension](snitch_cluster-properties-hives-items-cores-core-description-properties-enable-xfrep-extension.md))
-   cannot be null
-   defined in: [Snitch Cluster Schema](snitch_cluster-properties-hives-items-cores-core-description-properties-enable-xfrep-extension.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/cores/items/properties/xfrep")

### xfrep Type

`bool` ([Enable Xfrep Extension](snitch_cluster-properties-hives-items-cores-core-description-properties-enable-xfrep-extension.md))

## xdma

Direct memory access (DMA) custom extension.


`xdma`

-   is optional
-   Type: `bool` ([Xdma Extension](snitch_cluster-properties-hives-items-cores-core-description-properties-xdma-extension.md))
-   cannot be null
-   defined in: [Snitch Cluster Schema](snitch_cluster-properties-hives-items-cores-core-description-properties-xdma-extension.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/cores/items/properties/xdma")

### xdma Type

`bool` ([Xdma Extension](snitch_cluster-properties-hives-items-cores-core-description-properties-xdma-extension.md))

## ssr_nr_credits

Number of credits and buffer depth of SSR FIFOs.


`ssr_nr_credits`

-   is optional
-   Type: `number`
-   cannot be null
-   defined in: [Snitch Cluster Schema](snitch_cluster-properties-hives-items-cores-core-description-properties-ssr_nr_credits.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/cores/items/properties/ssr_nr_credits")

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
-   defined in: [Snitch Cluster Schema](snitch_cluster-properties-hives-items-cores-core-description-properties-num_int_outstanding_loads.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/cores/items/properties/num_int_outstanding_loads")

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

-   is optional
-   Type: `number`
-   cannot be null
-   defined in: [Snitch Cluster Schema](snitch_cluster-properties-hives-items-cores-core-description-properties-num_int_outstanding_mem.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/cores/items/properties/num_int_outstanding_mem")

### num_int_outstanding_mem Type

`number`

### num_int_outstanding_mem Default Value

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
-   defined in: [Snitch Cluster Schema](snitch_cluster-properties-hives-items-cores-core-description-properties-num_fpu_outstanding_loads.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/cores/items/properties/num_fpu_outstanding_loads")

### num_fpu_outstanding_loads Type

`number`

### num_fpu_outstanding_loads Default Value

The default value is:

```json
4
```

## num_fp_outstanding_mem

Number of outstanding memory operations. Determines the buffer size in the core's load/store unit.


`num_fp_outstanding_mem`

-   is optional
-   Type: `number`
-   cannot be null
-   defined in: [Snitch Cluster Schema](snitch_cluster-properties-hives-items-cores-core-description-properties-num_fp_outstanding_mem.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/cores/items/properties/num_fp_outstanding_mem")

### num_fp_outstanding_mem Type

`number`

### num_fp_outstanding_mem Default Value

The default value is:

```json
1
```

## num_fpu_sequencer_instructions

Amount of floating-point instruction the floating-point sequence buffer can hold.


`num_fpu_sequencer_instructions`

-   is optional
-   Type: `number`
-   cannot be null
-   defined in: [Snitch Cluster Schema](snitch_cluster-properties-hives-items-cores-core-description-properties-num_fpu_sequencer_instructions.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/cores/items/properties/num_fpu_sequencer_instructions")

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
-   defined in: [Snitch Cluster Schema](snitch_cluster-properties-hives-items-cores-core-description-properties-num_ipu_sequencer_instructions.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/cores/items/properties/num_ipu_sequencer_instructions")

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
-   defined in: [Snitch Cluster Schema](snitch_cluster-properties-hives-items-cores-core-description-properties-num_itlb_entries.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/cores/items/properties/num_itlb_entries")

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
-   defined in: [Snitch Cluster Schema](snitch_cluster-properties-hives-items-cores-core-description-properties-num_dtlb_entries.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/cores/items/properties/num_dtlb_entries")

### num_dtlb_entries Type

`number`

### num_dtlb_entries Default Value

The default value is:

```json
2
```
