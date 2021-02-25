# Untitled object in Occamy System Schema Schema

```txt
http://pulp-platform.org/snitch/snitch_cluster_tb.schema.json#/properties/s1_quadrant/properties/const_cache
```

Constant cache configuration.

| Abstract            | Extensible | Status         | Identifiable | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                       |
| :------------------ | :--------- | :------------- | :----------- | :---------------- | :-------------------- | :------------------ | :--------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | No           | Forbidden         | Allowed               | none                | [occamy.schema.json*](occamy.schema.json "open original schema") |

## const_cache Type

`object` ([Details](occamy-properties-object-properties-const_cache.md))

# undefined Properties

| Property        | Type      | Required | Nullable       | Defined by                                                                                                                                                                                                                  |
| :-------------- | :-------- | :------- | :------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [width](#width) | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-object-properties-const_cache-properties-width.md "http://pulp-platform.org/snitch/snitch_cluster_tb.schema.json#/properties/s1_quadrant/properties/const_cache/properties/width") |
| [count](#count) | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-object-properties-const_cache-properties-count.md "http://pulp-platform.org/snitch/snitch_cluster_tb.schema.json#/properties/s1_quadrant/properties/const_cache/properties/count") |
| [sets](#sets)   | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-object-properties-const_cache-properties-sets.md "http://pulp-platform.org/snitch/snitch_cluster_tb.schema.json#/properties/s1_quadrant/properties/const_cache/properties/sets")   |

## width

Cache Line Width

`width`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-object-properties-const_cache-properties-width.md "http://pulp-platform.org/snitch/snitch_cluster_tb.schema.json#/properties/s1\_quadrant/properties/const_cache/properties/width")

### width Type

`integer`

## count

The number of cache lines per set. Power of two; >= 2.

`count`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-object-properties-const_cache-properties-count.md "http://pulp-platform.org/snitch/snitch_cluster_tb.schema.json#/properties/s1\_quadrant/properties/const_cache/properties/count")

### count Type

`integer`

## sets

The set associativity of the cache. Power of two; >= 1.

`sets`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-object-properties-const_cache-properties-sets.md "http://pulp-platform.org/snitch/snitch_cluster_tb.schema.json#/properties/s1\_quadrant/properties/const_cache/properties/sets")

### sets Type

`integer`
