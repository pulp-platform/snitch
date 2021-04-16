# Untitled number in Snitch Cluster Schema Schema

```txt
http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/ssrs/items/properties/pointer_width
```

Internal bitwidth of pointers in address generator; must be larger than the TCDM word address mask.

| Abstract            | Extensible | Status         | Identifiable            | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                                       |
| :------------------ | :--------- | :------------- | :---------------------- | :---------------- | :-------------------- | :------------------ | :------------------------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | Unknown identifiability | Forbidden         | Allowed               | none                | [snitch_cluster.schema.json*](snitch_cluster.schema.json "open original schema") |

## pointer_width Type

`number`

## pointer_width Constraints

**maximum**: the value of this number must smaller than or equal to: `32`

## pointer_width Default Value

The default value is:

```json
18
```
