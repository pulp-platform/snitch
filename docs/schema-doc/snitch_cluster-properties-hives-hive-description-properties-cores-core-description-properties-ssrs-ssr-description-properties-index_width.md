# Untitled number in Snitch Cluster Schema Schema

```txt
http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/ssrs/items/properties/index_width
```

Internal bitwidth of indices in address generator.

| Abstract            | Extensible | Status         | Identifiable            | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                                       |
| :------------------ | :--------- | :------------- | :---------------------- | :---------------- | :-------------------- | :------------------ | :------------------------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | Unknown identifiability | Forbidden         | Allowed               | none                | [snitch_cluster.schema.json*](snitch_cluster.schema.json "open original schema") |

## index_width Type

`number`

## index_width Constraints

**maximum**: the value of this number must smaller than or equal to: `32`

**minimum**: the value of this number must greater than or equal to: `1`

## index_width Default Value

The default value is:

```json
16
```
