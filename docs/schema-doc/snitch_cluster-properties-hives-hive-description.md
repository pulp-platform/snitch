# Hive Description Schema

```txt
http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items
```

Configuration of a Hive

| Abstract            | Extensible | Status         | Identifiable | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                                       |
| :------------------ | :--------- | :------------- | :----------- | :---------------- | :-------------------- | :------------------ | :------------------------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | No           | Forbidden         | Allowed               | none                | [snitch_cluster.schema.json*](snitch_cluster.schema.json "open original schema") |

## items Type

`object` ([Hive Description](snitch_cluster-properties-hives-hive-description.md))

# Hive Description Properties

| Property          | Type     | Required | Nullable       | Defined by                                                                                                                                                                                                                           |
| :---------------- | :------- | :------- | :------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [icache](#icache) | `object` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-hives-instruction-cache-configuration.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/icache") |
| [cores](#cores)   | `array`  | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores")                                  |

## icache

Detailed configuration of the current Hive's instruction cache.

`icache`

*   is optional

*   Type: `object` ([Hive's instruction cache configuration.](snitch_cluster-properties-hives-hive-description-properties-hives-instruction-cache-configuration.md))

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-hives-instruction-cache-configuration.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/icache")

### icache Type

`object` ([Hive's instruction cache configuration.](snitch_cluster-properties-hives-hive-description-properties-hives-instruction-cache-configuration.md))

### icache Default Value

The default value is:

```json
{
  "size": 8,
  "sets": 2,
  "cacheline": 128
}
```

## cores

List of all cores in the respective hive.

`cores`

*   is optional

*   Type: `object[]` ([Core Description](snitch_cluster-properties-hives-hive-description-properties-cores-core-description.md))

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-cores.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/cores")

### cores Type

`object[]` ([Core Description](snitch_cluster-properties-hives-hive-description-properties-cores-core-description.md))

### cores Constraints

**minimum number of items**: the minimum number of items for this array is: `1`
