# Remote Quadrant Description Schema

```txt
http://pulp-platform.org/snitch/occamy.schema.json#/properties/remote_quadrants/items
```

Description of a remote quadrant

| Abstract            | Extensible | Status         | Identifiable | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                       |
| :------------------ | :--------- | :------------- | :----------- | :---------------- | :-------------------- | :------------------ | :--------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | No           | Forbidden         | Allowed               | none                | [occamy.schema.json*](occamy.schema.json "open original schema") |

## items Type

`object` ([Remote Quadrant Description](occamy-properties-remote-quadrants-remote-quadrant-description.md))

# Remote Quadrant Description Properties

| Property                              | Type      | Required | Nullable       | Defined by                                                                                                                                                                                                                                |
| :------------------------------------ | :-------- | :------- | :------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [nr_clusters](#nr_clusters)           | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-remote-quadrants-remote-quadrant-description-properties-nr_clusters.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/remote_quadrants/items/properties/nr_clusters")           |
| [nr_cluster_cores](#nr_cluster_cores) | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-remote-quadrants-remote-quadrant-description-properties-nr_cluster_cores.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/remote_quadrants/items/properties/nr_cluster_cores") |

## nr_clusters

Number of clusters in an S1 quadrant.

`nr_clusters`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-remote-quadrants-remote-quadrant-description-properties-nr_clusters.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/remote_quadrants/items/properties/nr_clusters")

### nr_clusters Type

`integer`

### nr_clusters Default Value

The default value is:

```json
4
```

## nr_cluster_cores

Number of cores in a cluster

`nr_cluster_cores`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-remote-quadrants-remote-quadrant-description-properties-nr_cluster_cores.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/remote_quadrants/items/properties/nr_cluster_cores")

### nr_cluster_cores Type

`integer`

### nr_cluster_cores Default Value

The default value is:

```json
8
```
