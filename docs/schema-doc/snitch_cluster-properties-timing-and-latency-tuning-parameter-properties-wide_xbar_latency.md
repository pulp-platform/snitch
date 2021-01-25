# Untitled string in Snitch Cluster Schema Schema

```txt
http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing/properties/wide_xbar_latency
```

Latency mode of the DMA crossbar.

| Abstract            | Extensible | Status         | Identifiable            | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                                       |
| :------------------ | :--------- | :------------- | :---------------------- | :---------------- | :-------------------- | :------------------ | :------------------------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | Unknown identifiability | Forbidden         | Allowed               | none                | [snitch_cluster.schema.json*](snitch_cluster.schema.json "open original schema") |

## wide_xbar_latency Type

`string`

## wide_xbar_latency Constraints

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

## wide_xbar_latency Default Value

The default value is:

```json
"CUT_ALL_PORTS"
```
