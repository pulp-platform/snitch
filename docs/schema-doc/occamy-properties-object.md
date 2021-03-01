# object Schema

```txt
http://pulp-platform.org/snitch/snitch_cluster_tb.schema.json#/properties/s1_quadrant
```



| Abstract            | Extensible | Status         | Identifiable | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                       |
| :------------------ | :--------- | :------------- | :----------- | :---------------- | :-------------------- | :------------------ | :--------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | No           | Forbidden         | Allowed               | none                | [occamy.schema.json*](occamy.schema.json "open original schema") |

## s1\_quadrant Type

unknown ([object](occamy-properties-object.md))

# object Properties

| Property                    | Type      | Required | Nullable       | Defined by                                                                                                                                                                                |
| :-------------------------- | :-------- | :------- | :------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [nr_clusters](#nr_clusters) | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-object-properties-nr_clusters.md "http://pulp-platform.org/snitch/snitch_cluster_tb.schema.json#/properties/s1_quadrant/properties/nr_clusters") |
| [const_cache](#const_cache) | `object`  | Optional | cannot be null | [Occamy System Schema](occamy-properties-object-properties-const_cache.md "http://pulp-platform.org/snitch/snitch_cluster_tb.schema.json#/properties/s1_quadrant/properties/const_cache") |

## nr_clusters

Number of clusters in an S1 quadrant.

`nr_clusters`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-object-properties-nr_clusters.md "http://pulp-platform.org/snitch/snitch_cluster_tb.schema.json#/properties/s1\_quadrant/properties/nr_clusters")

### nr_clusters Type

`integer`

### nr_clusters Default Value

The default value is:

```json
4
```

## const_cache

Constant cache configuration.

`const_cache`

*   is optional

*   Type: `object` ([Details](occamy-properties-object-properties-const_cache.md))

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-object-properties-const_cache.md "http://pulp-platform.org/snitch/snitch_cluster_tb.schema.json#/properties/s1\_quadrant/properties/const_cache")

### const_cache Type

`object` ([Details](occamy-properties-object-properties-const_cache.md))
