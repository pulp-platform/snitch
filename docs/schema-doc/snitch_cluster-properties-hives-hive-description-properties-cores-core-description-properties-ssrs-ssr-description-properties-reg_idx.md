# Untitled undefined type in Snitch Cluster Schema Schema

```txt
http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores/items/properties/ssrs/items/properties/reg_idx
```

The floating-point register index this SSR is assigned to. If not assigned, the next available index counting from 0 is chosen.

| Abstract            | Extensible | Status         | Identifiable            | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                                       |
| :------------------ | :--------- | :------------- | :---------------------- | :---------------- | :-------------------- | :------------------ | :------------------------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | Unknown identifiability | Forbidden         | Allowed               | none                | [snitch_cluster.schema.json*](snitch_cluster.schema.json "open original schema") |

## reg_idx Type

`number`

## reg_idx Constraints

**maximum**: the value of this number must smaller than or equal to: `31`

**minimum**: the value of this number must greater than or equal to: `0`
