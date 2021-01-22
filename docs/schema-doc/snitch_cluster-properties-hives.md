# Hives Schema

```txt
http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives
```

Cores in a hive share an instruction cache and other shared infrastructure such as the PTW or the multiply/divide unit.

| Abstract            | Extensible | Status         | Identifiable            | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                                       |
| :------------------ | :--------- | :------------- | :---------------------- | :---------------- | :-------------------- | :------------------ | :------------------------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | Unknown identifiability | Forbidden         | Allowed               | none                | [snitch_cluster.schema.json*](snitch_cluster.schema.json "open original schema") |

## hives Type

`object[]` ([Hive Description](snitch_cluster-properties-hives-hive-description.md))

## hives Constraints

**minimum number of items**: the minimum number of items for this array is: `1`
