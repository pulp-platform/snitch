# Untitled number in Snitch Cluster Schema Schema

```txt
http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/ssrs/items/properties/isect_slave_credits
```

Number of elements by which intersected indices may outrun corresponding data; added only if this SSR is an intersection slave.

| Abstract            | Extensible | Status         | Identifiable            | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                                       |
| :------------------ | :--------- | :------------- | :---------------------- | :---------------- | :-------------------- | :------------------ | :------------------------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | Unknown identifiability | Forbidden         | Allowed               | none                | [snitch_cluster.schema.json*](snitch_cluster.schema.json "open original schema") |

## isect_slave_credits Type

`number`

## isect_slave_credits Constraints

**minimum**: the value of this number must greater than or equal to: `2`

## isect_slave_credits Default Value

The default value is:

```json
8
```
