# Untitled string in Snitch Cluster Schema Schema

```txt
http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/timing/properties/fpu_pipe_config
```

Pipeline configuration (i.e., position of the registers) of the FPU.

| Abstract            | Extensible | Status         | Identifiable            | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                                       |
| :------------------ | :--------- | :------------- | :---------------------- | :---------------- | :-------------------- | :------------------ | :------------------------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | Unknown identifiability | Forbidden         | Allowed               | none                | [snitch_cluster.schema.json*](snitch_cluster.schema.json "open original schema") |

## fpu_pipe_config Type

`string`

## fpu_pipe_config Constraints

**enum**: the value of this property must be equal to one of the following values:

| Value           | Explanation |
| :-------------- | :---------- |
| `"BEFORE"`      |             |
| `"AFTER"`       |             |
| `"INSIDE"`      |             |
| `"DISTRIBUTED"` |             |

## fpu_pipe_config Default Value

The default value is:

```json
"BEFORE"
```
