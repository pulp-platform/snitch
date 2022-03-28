# Timing and Latency Tuning Parameter Schema

```txt
http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing
```



| Abstract            | Extensible | Status         | Identifiable | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                                       |
| :------------------ | :--------- | :------------- | :----------- | :---------------- | :-------------------- | :------------------ | :------------------------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | No           | Forbidden         | Allowed               | none                | [snitch_cluster.schema.json*](snitch_cluster.schema.json "open original schema") |

## timing Type

`object` ([Timing and Latency Tuning Parameter](snitch_cluster-properties-timing-and-latency-tuning-parameter.md))

# Timing and Latency Tuning Parameter Properties

| Property                                      | Type      | Required | Nullable       | Defined by                                                                                                                                                                                                                                |
| :-------------------------------------------- | :-------- | :------- | :------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [iso_crossings](#iso_crossings)               | `boolean` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-timing-and-latency-tuning-parameter-properties-iso_crossings.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing/properties/iso_crossings")               |
| [narrow_xbar_latency](#narrow_xbar_latency)   | `string`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-timing-and-latency-tuning-parameter-properties-narrow_xbar_latency.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing/properties/narrow_xbar_latency")   |
| [wide_xbar_latency](#wide_xbar_latency)       | `string`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-timing-and-latency-tuning-parameter-properties-wide_xbar_latency.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing/properties/wide_xbar_latency")       |
| [register_offload_req](#register_offload_req) | `boolean` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-timing-and-latency-tuning-parameter-properties-register_offload_req.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing/properties/register_offload_req") |
| [register_offload_rsp](#register_offload_rsp) | `boolean` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-timing-and-latency-tuning-parameter-properties-register_offload_rsp.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing/properties/register_offload_rsp") |
| [register_core_req](#register_core_req)       | `boolean` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-timing-and-latency-tuning-parameter-properties-register_core_req.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing/properties/register_core_req")       |
| [register_core_rsp](#register_core_rsp)       | `boolean` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-timing-and-latency-tuning-parameter-properties-register_core_rsp.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing/properties/register_core_rsp")       |
| [register_fpu_req](#register_fpu_req)         | `boolean` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-timing-and-latency-tuning-parameter-properties-register_fpu_req.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing/properties/register_fpu_req")         |
| [register_fpu_in](#register_fpu_in)           | `boolean` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-timing-and-latency-tuning-parameter-properties-register_fpu_in.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing/properties/register_fpu_in")           |
| [register_fpu_out](#register_fpu_out)         | `boolean` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-timing-and-latency-tuning-parameter-properties-register_fpu_out.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing/properties/register_fpu_out")         |
| [register_tcdm_cuts](#register_tcdm_cuts)     | `boolean` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-timing-and-latency-tuning-parameter-properties-register_tcdm_cuts.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing/properties/register_tcdm_cuts")     |
| [register_ext_wide](#register_ext_wide)       | `boolean` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-timing-and-latency-tuning-parameter-properties-register_ext_wide.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing/properties/register_ext_wide")       |
| [register_ext_narrow](#register_ext_narrow)   | `boolean` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-timing-and-latency-tuning-parameter-properties-register_ext_narrow.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing/properties/register_ext_narrow")   |
| [register_sequencer](#register_sequencer)     | `boolean` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-timing-and-latency-tuning-parameter-properties-register_sequencer.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing/properties/register_sequencer")     |
| [lat_comp_fp32](#lat_comp_fp32)               | `number`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-timing-and-latency-tuning-parameter-properties-lat_comp_fp32.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing/properties/lat_comp_fp32")               |
| [lat_comp_fp64](#lat_comp_fp64)               | `number`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-timing-and-latency-tuning-parameter-properties-lat_comp_fp64.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing/properties/lat_comp_fp64")               |
| [lat_comp_fp16](#lat_comp_fp16)               | `number`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-timing-and-latency-tuning-parameter-properties-lat_comp_fp16.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing/properties/lat_comp_fp16")               |
| [lat_comp_fp16_alt](#lat_comp_fp16_alt)       | `number`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-timing-and-latency-tuning-parameter-properties-lat_comp_fp16_alt.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing/properties/lat_comp_fp16_alt")       |
| [lat_comp_fp8](#lat_comp_fp8)                 | `number`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-timing-and-latency-tuning-parameter-properties-lat_comp_fp8.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing/properties/lat_comp_fp8")                 |
| [lat_comp_fp8alt](#lat_comp_fp8alt)           | `number`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-timing-and-latency-tuning-parameter-properties-lat_comp_fp8alt.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing/properties/lat_comp_fp8alt")           |
| [lat_noncomp](#lat_noncomp)                   | `number`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-timing-and-latency-tuning-parameter-properties-lat_noncomp.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing/properties/lat_noncomp")                   |
| [lat_conv](#lat_conv)                         | `number`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-timing-and-latency-tuning-parameter-properties-lat_conv.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing/properties/lat_conv")                         |
| [lat_sdotp](#lat_sdotp)                       | `number`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-timing-and-latency-tuning-parameter-properties-lat_sdotp.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing/properties/lat_sdotp")                       |
| [fpu_pipe_config](#fpu_pipe_config)           | `string`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-timing-and-latency-tuning-parameter-properties-fpu_pipe_config.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing/properties/fpu_pipe_config")           |

## iso_crossings

Enable isochronous crossings, this clocks the integer core at half the speed of the rest of the system.

`iso_crossings`

*   is optional

*   Type: `boolean`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-timing-and-latency-tuning-parameter-properties-iso_crossings.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing/properties/iso_crossings")

### iso_crossings Type

`boolean`

## narrow_xbar_latency

Latency mode of the cluster crossbar.

`narrow_xbar_latency`

*   is optional

*   Type: `string`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-timing-and-latency-tuning-parameter-properties-narrow_xbar_latency.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing/properties/narrow_xbar_latency")

### narrow_xbar_latency Type

`string`

### narrow_xbar_latency Constraints

**enum**: the value of this property must be equal to one of the following values:

| Value             | Explanation |
| :---------------- | :---------- |
| `"NO_LATENCY"`    |             |
| `"CUT_SLV_AX"`    |             |
| `"CUT_MST_AX"`    |             |
| `"CUT_ALL_AX"`    |             |
| `"CUT_SLV_PORTS"` |             |
| `"CUT_MST_PORTS"` |             |
| `"CUT_ALL_PORTS"` |             |

### narrow_xbar_latency Default Value

The default value is:

```json
"CUT_ALL_PORTS"
```

## wide_xbar_latency

Latency mode of the DMA crossbar.

`wide_xbar_latency`

*   is optional

*   Type: `string`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-timing-and-latency-tuning-parameter-properties-wide_xbar_latency.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing/properties/wide_xbar_latency")

### wide_xbar_latency Type

`string`

### wide_xbar_latency Constraints

**enum**: the value of this property must be equal to one of the following values:

| Value             | Explanation |
| :---------------- | :---------- |
| `"NO_LATENCY"`    |             |
| `"CUT_SLV_AX"`    |             |
| `"CUT_MST_AX"`    |             |
| `"CUT_ALL_AX"`    |             |
| `"CUT_SLV_PORTS"` |             |
| `"CUT_MST_PORTS"` |             |
| `"CUT_ALL_PORTS"` |             |

### wide_xbar_latency Default Value

The default value is:

```json
"CUT_ALL_PORTS"
```

## register_offload_req

Insert Pipeline registers into off-loading path (request).

`register_offload_req`

*   is optional

*   Type: `boolean`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-timing-and-latency-tuning-parameter-properties-register_offload_req.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing/properties/register_offload_req")

### register_offload_req Type

`boolean`

## register_offload_rsp

Insert Pipeline registers into off-loading path (response).

`register_offload_rsp`

*   is optional

*   Type: `boolean`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-timing-and-latency-tuning-parameter-properties-register_offload_rsp.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing/properties/register_offload_rsp")

### register_offload_rsp Type

`boolean`

## register_core_req

Insert Pipeline registers into data memory request path.

`register_core_req`

*   is optional

*   Type: `boolean`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-timing-and-latency-tuning-parameter-properties-register_core_req.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing/properties/register_core_req")

### register_core_req Type

`boolean`

## register_core_rsp

Insert Pipeline registers into data memory response path.

`register_core_rsp`

*   is optional

*   Type: `boolean`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-timing-and-latency-tuning-parameter-properties-register_core_rsp.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing/properties/register_core_rsp")

### register_core_rsp Type

`boolean`

## register_fpu_req

Insert Pipeline register into the FPU request data path

`register_fpu_req`

*   is optional

*   Type: `boolean`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-timing-and-latency-tuning-parameter-properties-register_fpu_req.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing/properties/register_fpu_req")

### register_fpu_req Type

`boolean`

## register_fpu_in

Insert Pipeline registers immediately before FPU datapath

`register_fpu_in`

*   is optional

*   Type: `boolean`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-timing-and-latency-tuning-parameter-properties-register_fpu_in.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing/properties/register_fpu_in")

### register_fpu_in Type

`boolean`

## register_fpu_out

Insert Pipeline registers immediately after FPU datapath

`register_fpu_out`

*   is optional

*   Type: `boolean`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-timing-and-latency-tuning-parameter-properties-register_fpu_out.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing/properties/register_fpu_out")

### register_fpu_out Type

`boolean`

## register_tcdm_cuts

Insert Pipeline registers after each memory cut.

`register_tcdm_cuts`

*   is optional

*   Type: `boolean`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-timing-and-latency-tuning-parameter-properties-register_tcdm_cuts.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing/properties/register_tcdm_cuts")

### register_tcdm_cuts Type

`boolean`

## register_ext_wide

Decouple wide external AXI plug.

`register_ext_wide`

*   is optional

*   Type: `boolean`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-timing-and-latency-tuning-parameter-properties-register_ext_wide.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing/properties/register_ext_wide")

### register_ext_wide Type

`boolean`

## register_ext_narrow

Decouple narrow external AXI plug.

`register_ext_narrow`

*   is optional

*   Type: `boolean`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-timing-and-latency-tuning-parameter-properties-register_ext_narrow.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing/properties/register_ext_narrow")

### register_ext_narrow Type

`boolean`

## register_sequencer

Insert Pipeline registers after sequencer.

`register_sequencer`

*   is optional

*   Type: `boolean`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-timing-and-latency-tuning-parameter-properties-register_sequencer.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing/properties/register_sequencer")

### register_sequencer Type

`boolean`

## lat_comp_fp32

Latency setting (number of pipeline stages) for FP32.

`lat_comp_fp32`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-timing-and-latency-tuning-parameter-properties-lat_comp_fp32.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing/properties/lat_comp_fp32")

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

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-timing-and-latency-tuning-parameter-properties-lat_comp_fp64.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing/properties/lat_comp_fp64")

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

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-timing-and-latency-tuning-parameter-properties-lat_comp_fp16.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing/properties/lat_comp_fp16")

### lat_comp_fp16 Type

`number`

### lat_comp_fp16 Default Value

The default value is:

```json
1
```

## lat_comp_fp16\_alt

Latency setting (number of pipeline stages) for FP16alt (brainfloat).

`lat_comp_fp16_alt`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-timing-and-latency-tuning-parameter-properties-lat_comp_fp16\_alt.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing/properties/lat_comp_fp16\_alt")

### lat_comp_fp16\_alt Type

`number`

### lat_comp_fp16\_alt Default Value

The default value is:

```json
2
```

## lat_comp_fp8

Latency setting (number of pipeline stages) for FP8.

`lat_comp_fp8`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-timing-and-latency-tuning-parameter-properties-lat_comp_fp8.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing/properties/lat_comp_fp8")

### lat_comp_fp8 Type

`number`

### lat_comp_fp8 Default Value

The default value is:

```json
1
```

## lat_comp_fp8alt

Latency setting (number of pipeline stages) for FP8alt.

`lat_comp_fp8alt`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-timing-and-latency-tuning-parameter-properties-lat_comp_fp8alt.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing/properties/lat_comp_fp8alt")

### lat_comp_fp8alt Type

`number`

### lat_comp_fp8alt Default Value

The default value is:

```json
1
```

## lat_noncomp

Latency setting (number of pipeline stages) for floating-point non-computational instructions (except conversions), i.e., `classify`, etc.

`lat_noncomp`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-timing-and-latency-tuning-parameter-properties-lat_noncomp.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing/properties/lat_noncomp")

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

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-timing-and-latency-tuning-parameter-properties-lat_conv.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing/properties/lat_conv")

### lat_conv Type

`number`

### lat_conv Default Value

The default value is:

```json
1
```

## lat_sdotp

Latency setting (number of pipeline stages) for floating-point expanding dot product with accumulation.

`lat_sdotp`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-timing-and-latency-tuning-parameter-properties-lat_sdotp.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing/properties/lat_sdotp")

### lat_sdotp Type

`number`

### lat_sdotp Default Value

The default value is:

```json
2
```

## fpu_pipe_config

Pipeline configuration (i.e., position of the registers) of the FPU.

`fpu_pipe_config`

*   is optional

*   Type: `string`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-timing-and-latency-tuning-parameter-properties-fpu_pipe_config.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing/properties/fpu_pipe_config")

### fpu_pipe_config Type

`string`

### fpu_pipe_config Constraints

**enum**: the value of this property must be equal to one of the following values:

| Value           | Explanation |
| :-------------- | :---------- |
| `"BEFORE"`      |             |
| `"AFTER"`       |             |
| `"INSIDE"`      |             |
| `"DISTRIBUTED"` |             |

### fpu_pipe_config Default Value

The default value is:

```json
"BEFORE"
```
