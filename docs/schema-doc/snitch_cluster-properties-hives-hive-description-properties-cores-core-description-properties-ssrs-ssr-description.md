# SSR Description Schema

```txt
http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/ssrs/items
```

Description of a single Stream Semantic Register.

| Abstract            | Extensible | Status         | Identifiable | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                                       |
| :------------------ | :--------- | :------------- | :----------- | :---------------- | :-------------------- | :------------------ | :------------------------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | No           | Forbidden         | Allowed               | none                | [snitch_cluster.schema.json*](snitch_cluster.schema.json "open original schema") |

## items Type

`object` ([SSR Description](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-ssrs-ssr-description.md))

# SSR Description Properties

| Property                            | Type      | Required | Nullable       | Defined by                                                                                                                                                                                                                                                                                                                             |
| :---------------------------------- | :-------- | :------- | :------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [reg_idx](#reg_idx)                 | `number`  | Optional | can be null    | [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-ssrs-ssr-description-properties-reg_idx.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/ssrs/items/properties/reg_idx")                 |
| [indirection](#indirection)         | `boolean` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-ssrs-ssr-description-properties-indirection.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/ssrs/items/properties/indirection")         |
| [indir_out_spill](#indir_out_spill) | `boolean` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-ssrs-ssr-description-properties-indir_out_spill.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/ssrs/items/properties/indir_out_spill") |
| [num_loops](#num_loops)             | `number`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-ssrs-ssr-description-properties-num_loops.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/ssrs/items/properties/num_loops")             |
| [index_credits](#index_credits)     | `number`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-ssrs-ssr-description-properties-index_credits.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/ssrs/items/properties/index_credits")     |
| [data_credits](#data_credits)       | `number`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-ssrs-ssr-description-properties-data_credits.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/ssrs/items/properties/data_credits")       |
| [mux_resp_depth](#mux_resp_depth)   | `number`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-ssrs-ssr-description-properties-mux_resp_depth.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/ssrs/items/properties/mux_resp_depth")   |
| [index_width](#index_width)         | `number`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-ssrs-ssr-description-properties-index_width.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/ssrs/items/properties/index_width")         |
| [pointer_width](#pointer_width)     | `number`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-ssrs-ssr-description-properties-pointer_width.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/ssrs/items/properties/pointer_width")     |
| [shift_width](#shift_width)         | `number`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-ssrs-ssr-description-properties-shift_width.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/ssrs/items/properties/shift_width")         |
| [rpt_width](#rpt_width)             | `number`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-ssrs-ssr-description-properties-rpt_width.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/ssrs/items/properties/rpt_width")             |

## reg_idx

The floating-point register index this SSR is assigned to. If not assigned, the next available index counting from 0 is chosen.

`reg_idx`

*   is optional

*   Type: `number`

*   can be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-ssrs-ssr-description-properties-reg_idx.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/ssrs/items/properties/reg_idx")

### reg_idx Type

`number`

### reg_idx Constraints

**maximum**: the value of this number must smaller than or equal to: `31`

**minimum**: the value of this number must greater than or equal to: `0`

## indirection

Enable indirection extension.

`indirection`

*   is optional

*   Type: `boolean`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-ssrs-ssr-description-properties-indirection.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/ssrs/items/properties/indirection")

### indirection Type

`boolean`

## indir_out_spill

Whether to cut timing paths with a spill register at the address generator output; added only if indirection extension enabled.

`indir_out_spill`

*   is optional

*   Type: `boolean`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-ssrs-ssr-description-properties-indir_out_spill.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/ssrs/items/properties/indir_out_spill")

### indir_out_spill Type

`boolean`

### indir_out_spill Default Value

The default value is:

```json
true
```

## num_loops

Number of nested hardware loops in address generator.

`num_loops`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-ssrs-ssr-description-properties-num_loops.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/ssrs/items/properties/num_loops")

### num_loops Type

`number`

### num_loops Constraints

**maximum**: the value of this number must smaller than or equal to: `4`

**minimum**: the value of this number must greater than or equal to: `1`

### num_loops Default Value

The default value is:

```json
4
```

## index_credits

Number of credits and buffer depth of the index word FIFO.

`index_credits`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-ssrs-ssr-description-properties-index_credits.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/ssrs/items/properties/index_credits")

### index_credits Type

`number`

### index_credits Constraints

**minimum**: the value of this number must greater than or equal to: `1`

### index_credits Default Value

The default value is:

```json
3
```

## data_credits

Number of credits and buffer depth of the data word FIFO.

`data_credits`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-ssrs-ssr-description-properties-data_credits.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/ssrs/items/properties/data_credits")

### data_credits Type

`number`

### data_credits Constraints

**minimum**: the value of this number must greater than or equal to: `1`

### data_credits Default Value

The default value is:

```json
4
```

## mux_resp_depth

Depth of response buffer in the TCDM multiplexer arbitrating between data and indices.

`mux_resp_depth`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-ssrs-ssr-description-properties-mux_resp_depth.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/ssrs/items/properties/mux_resp_depth")

### mux_resp_depth Type

`number`

### mux_resp_depth Constraints

**minimum**: the value of this number must greater than or equal to: `1`

### mux_resp_depth Default Value

The default value is:

```json
3
```

## index_width

Internal bitwidth of indices in address generator.

`index_width`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-ssrs-ssr-description-properties-index_width.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/ssrs/items/properties/index_width")

### index_width Type

`number`

### index_width Constraints

**maximum**: the value of this number must smaller than or equal to: `32`

**minimum**: the value of this number must greater than or equal to: `1`

### index_width Default Value

The default value is:

```json
16
```

## pointer_width

Internal bitwidth of pointers in address generator; must be larger than the TCDM word address mask.

`pointer_width`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-ssrs-ssr-description-properties-pointer_width.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/ssrs/items/properties/pointer_width")

### pointer_width Type

`number`

### pointer_width Constraints

**maximum**: the value of this number must smaller than or equal to: `32`

### pointer_width Default Value

The default value is:

```json
18
```

## shift_width

Internal bitwidth of additional left shift amount for indirect indices.

`shift_width`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-ssrs-ssr-description-properties-shift_width.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/ssrs/items/properties/shift_width")

### shift_width Type

`number`

### shift_width Constraints

**maximum**: the value of this number must smaller than or equal to: `32`

**minimum**: the value of this number must greater than or equal to: `1`

### shift_width Default Value

The default value is:

```json
3
```

## rpt_width

Internal bitwidth of repetition counter for read streams.

`rpt_width`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores-core-description-properties-ssrs-ssr-description-properties-rpt_width.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/ssrs/items/properties/rpt_width")

### rpt_width Type

`number`

### rpt_width Constraints

**maximum**: the value of this number must smaller than or equal to: `32`

**minimum**: the value of this number must greater than or equal to: `1`

### rpt_width Default Value

The default value is:

```json
4
```
