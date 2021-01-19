# Untitled string in Snitch Cluster Schema Schema

```txt
http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/vm
```

Supported virtual memory mode, can be XSv32.


> Currently ignored.
>

| Abstract            | Extensible | Status         | Identifiable            | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                                        |
| :------------------ | ---------- | -------------- | ----------------------- | :---------------- | --------------------- | ------------------- | --------------------------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | Unknown identifiability | Forbidden         | Allowed               | none                | [snitch_cluster.schema.json\*](snitch_cluster.schema.json "open original schema") |

## vm Type

`string`

## vm Constraints

**enum**: the value of this property must be equal to one of the following values:

| Value     | Explanation |
| :-------- | ----------- |
| `"Sv32"`  |             |
| `"XSv48"` |             |

## vm Default Value

The default value is:

```json
"XSv48"
```
