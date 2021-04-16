# Untitled number in Snitch Cluster Schema Schema

```txt
http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/ssrs/items/properties/num_loops
```

Number of nested hardware loops in address generator.

| Abstract            | Extensible | Status         | Identifiable            | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                                       |
| :------------------ | :--------- | :------------- | :---------------------- | :---------------- | :-------------------- | :------------------ | :------------------------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | Unknown identifiability | Forbidden         | Allowed               | none                | [snitch_cluster.schema.json*](snitch_cluster.schema.json "open original schema") |

## num_loops Type

`number`

## num_loops Constraints

**maximum**: the value of this number must smaller than or equal to: `4`

**minimum**: the value of this number must greater than or equal to: `1`

## num_loops Default Value

The default value is:

```json
4
```
