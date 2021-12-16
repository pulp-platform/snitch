# S1 Quadrant Properties Schema

```txt
http://pulp-platform.org/snitch/occamy.schema.json#/properties/s1_quadrant
```



| Abstract            | Extensible | Status         | Identifiable | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                       |
| :------------------ | :--------- | :------------- | :----------- | :---------------- | :-------------------- | :------------------ | :--------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | No           | Forbidden         | Allowed               | none                | [occamy.schema.json*](occamy.schema.json "open original schema") |

## s1\_quadrant Type

`object` ([S1 Quadrant Properties](occamy-properties-s1-quadrant-properties.md))

# S1 Quadrant Properties Properties

| Property                                              | Type      | Required | Nullable       | Defined by                                                                                                                                                                                                               |
| :---------------------------------------------------- | :-------- | :------- | :------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [nr_clusters](#nr_clusters)                           | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-s1-quadrant-properties-properties-nr_clusters.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/s1_quadrant/properties/nr_clusters")                           |
| [ro_cache_cfg](#ro_cache_cfg)                         | `object`  | Optional | cannot be null | [Occamy System Schema](occamy-properties-s1-quadrant-properties-properties-ro_cache_cfg.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/s1_quadrant/properties/ro_cache_cfg")                         |
| [wide_xbar](#wide_xbar)                               | `object`  | Optional | cannot be null | [Occamy System Schema](occamy-properties-axi-crossbar-schema-1.md "http://pulp-platform.org/snitch/axi_xbar.schema.json#/properties/s1_quadrant/properties/wide_xbar")                                                   |
| [wide_xbar_slv_id_width](#wide_xbar_slv_id_width)     | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-s1-quadrant-properties-properties-wide_xbar_slv_id_width.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/s1_quadrant/properties/wide_xbar_slv_id_width")     |
| [narrow_xbar](#narrow_xbar)                           | `object`  | Optional | cannot be null | [Occamy System Schema](occamy-properties-axi-crossbar-schema-1.md "http://pulp-platform.org/snitch/axi_xbar.schema.json#/properties/s1_quadrant/properties/narrow_xbar")                                                 |
| [narrow_xbar_slv_id_width](#narrow_xbar_slv_id_width) | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-s1-quadrant-properties-properties-narrow_xbar_slv_id_width.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/s1_quadrant/properties/narrow_xbar_slv_id_width") |

## nr_clusters

Number of clusters in an S1 quadrant.

`nr_clusters`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-s1-quadrant-properties-properties-nr_clusters.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/s1\_quadrant/properties/nr_clusters")

### nr_clusters Type

`integer`

### nr_clusters Default Value

The default value is:

```json
4
```

## ro_cache_cfg

Constant cache configuration.

`ro_cache_cfg`

*   is optional

*   Type: `object` ([Details](occamy-properties-s1-quadrant-properties-properties-ro_cache_cfg.md))

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-s1-quadrant-properties-properties-ro_cache_cfg.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/s1\_quadrant/properties/ro_cache_cfg")

### ro_cache_cfg Type

`object` ([Details](occamy-properties-s1-quadrant-properties-properties-ro_cache_cfg.md))

## wide_xbar

AXI Crossbar Properties

`wide_xbar`

*   is optional

*   Type: `object` ([AXI Crossbar Schema](occamy-properties-axi-crossbar-schema-1.md))

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-axi-crossbar-schema-1.md "http://pulp-platform.org/snitch/axi_xbar.schema.json#/properties/s1\_quadrant/properties/wide_xbar")

### wide_xbar Type

`object` ([AXI Crossbar Schema](occamy-properties-axi-crossbar-schema-1.md))

## wide_xbar_slv_id_width

ID width of incoming slave ports.

`wide_xbar_slv_id_width`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-s1-quadrant-properties-properties-wide_xbar_slv_id_width.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/s1\_quadrant/properties/wide_xbar_slv_id_width")

### wide_xbar_slv_id_width Type

`integer`

### wide_xbar_slv_id_width Default Value

The default value is:

```json
2
```

## narrow_xbar

AXI Crossbar Properties

`narrow_xbar`

*   is optional

*   Type: `object` ([AXI Crossbar Schema](occamy-properties-axi-crossbar-schema-1.md))

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-axi-crossbar-schema-1.md "http://pulp-platform.org/snitch/axi_xbar.schema.json#/properties/s1\_quadrant/properties/narrow_xbar")

### narrow_xbar Type

`object` ([AXI Crossbar Schema](occamy-properties-axi-crossbar-schema-1.md))

## narrow_xbar_slv_id_width

ID width of incoming slave ports.

`narrow_xbar_slv_id_width`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-s1-quadrant-properties-properties-narrow_xbar_slv_id_width.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/s1\_quadrant/properties/narrow_xbar_slv_id_width")

### narrow_xbar_slv_id_width Type

`integer`

### narrow_xbar_slv_id_width Default Value

The default value is:

```json
4
```
