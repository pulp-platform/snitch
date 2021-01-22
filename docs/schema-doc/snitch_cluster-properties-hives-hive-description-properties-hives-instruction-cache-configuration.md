# Hive's instruction cache configuration. Schema

```txt
http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/icache
```

Detailed configuration of the current Hive's instruction cache.

| Abstract            | Extensible | Status         | Identifiable | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                                       |
| :------------------ | :--------- | :------------- | :----------- | :---------------- | :-------------------- | :------------------ | :------------------------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | No           | Forbidden         | Allowed               | none                | [snitch_cluster.schema.json*](snitch_cluster.schema.json "open original schema") |

## icache Type

`object` ([Hive's instruction cache configuration.](snitch_cluster-properties-hives-hive-description-properties-hives-instruction-cache-configuration.md))

## icache Default Value

The default value is:

```json
{
  "size": 8,
  "sets": 2,
  "cacheline": 128
}
```

# Hive's instruction cache configuration. Properties

| Property                | Type     | Required | Nullable       | Defined by                                                                                                                                                                                                                                                                     |
| :---------------------- | :------- | :------- | :------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [size](#size)           | `number` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-hives-instruction-cache-configuration-properties-size.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/icache/properties/size")           |
| [sets](#sets)           | `number` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-hives-instruction-cache-configuration-properties-sets.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/icache/properties/sets")           |
| [cacheline](#cacheline) | `number` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-hives-instruction-cache-configuration-properties-cacheline.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/icache/properties/cacheline") |

## size

Total instruction cache size in KiByte.

`size`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-hives-instruction-cache-configuration-properties-size.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/icache/properties/size")

### size Type

`number`

## sets

Number of ways.

`sets`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-hives-instruction-cache-configuration-properties-sets.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/icache/properties/sets")

### sets Type

`number`

## cacheline

Cacheline/Word size in bits.

`cacheline`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-hives-hive-description-properties-hives-instruction-cache-configuration-properties-cacheline.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/hives/items/properties/icache/properties/cacheline")

### cacheline Type

`number`
