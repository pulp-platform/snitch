# Untitled object in Occamy System Schema Schema

```txt
http://pulp-platform.org/snitch/occamy.schema.json#/properties/s1_quadrant/properties/ro_cache_cfg
```

Constant cache configuration.

| Abstract            | Extensible | Status         | Identifiable | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                       |
| :------------------ | :--------- | :------------- | :----------- | :---------------- | :-------------------- | :------------------ | :--------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | No           | Forbidden         | Allowed               | none                | [occamy.schema.json*](occamy.schema.json "open original schema") |

## ro_cache_cfg Type

`object` ([Details](occamy-properties-s1-quadrant-properties-properties-ro_cache_cfg.md))

# undefined Properties

| Property                            | Type      | Required | Nullable       | Defined by                                                                                                                                                                                                                                             |
| :---------------------------------- | :-------- | :------- | :------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [max_trans](#max_trans)             | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-s1-quadrant-properties-properties-ro_cache_cfg-properties-max_trans.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/s1_quadrant/properties/ro_cache_cfg/properties/max_trans")             |
| [width](#width)                     | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-s1-quadrant-properties-properties-ro_cache_cfg-properties-width.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/s1_quadrant/properties/ro_cache_cfg/properties/width")                     |
| [count](#count)                     | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-s1-quadrant-properties-properties-ro_cache_cfg-properties-count.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/s1_quadrant/properties/ro_cache_cfg/properties/count")                     |
| [sets](#sets)                       | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-s1-quadrant-properties-properties-ro_cache_cfg-properties-sets.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/s1_quadrant/properties/ro_cache_cfg/properties/sets")                       |
| [address_regions](#address_regions) | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-s1-quadrant-properties-properties-ro_cache_cfg-properties-address_regions.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/s1_quadrant/properties/ro_cache_cfg/properties/address_regions") |

## max_trans

Maximum Outstanding Transaction

`max_trans`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-s1-quadrant-properties-properties-ro_cache_cfg-properties-max_trans.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/s1\_quadrant/properties/ro_cache_cfg/properties/max_trans")

### max_trans Type

`integer`

### max_trans Default Value

The default value is:

```json
4
```

## width

Cache Line Width

`width`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-s1-quadrant-properties-properties-ro_cache_cfg-properties-width.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/s1\_quadrant/properties/ro_cache_cfg/properties/width")

### width Type

`integer`

## count

The number of cache lines per set. Power of two; >= 2.

`count`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-s1-quadrant-properties-properties-ro_cache_cfg-properties-count.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/s1\_quadrant/properties/ro_cache_cfg/properties/count")

### count Type

`integer`

## sets

The set associativity of the cache. Power of two; >= 1.

`sets`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-s1-quadrant-properties-properties-ro_cache_cfg-properties-sets.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/s1\_quadrant/properties/ro_cache_cfg/properties/sets")

### sets Type

`integer`

## address_regions

Number of programmable address regions.

`address_regions`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-s1-quadrant-properties-properties-ro_cache_cfg-properties-address_regions.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/s1\_quadrant/properties/ro_cache_cfg/properties/address_regions")

### address_regions Type

`integer`

### address_regions Default Value

The default value is:

```json
1
```
