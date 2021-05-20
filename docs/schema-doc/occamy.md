# Occamy System Schema Schema

```txt
http://pulp-platform.org/snitch/snitch_cluster_tb.schema.json
```

Description for a very simple single-cluster testbench. That is the most minimal system available. Most of the hardware is emulated by the testbench.

| Abstract            | Extensible | Status         | Identifiable | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                      |
| :------------------ | :--------- | :------------- | :----------- | :---------------- | :-------------------- | :------------------ | :-------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | No           | Forbidden         | Allowed               | none                | [occamy.schema.json](occamy.schema.json "open original schema") |

## Occamy System Schema Type

`object` ([Occamy System Schema](occamy.md))

# Occamy System Schema Properties

| Property                          | Type          | Required | Nullable       | Defined by                                                                                                                                                     |
| :-------------------------------- | :------------ | :------- | :------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [cluster](#cluster)               | `object`      | Required | cannot be null | [Occamy System Schema](occamy-properties-snitch-cluster-schema.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/cluster")            |
| [rom](#rom)                       | `object`      | Optional | cannot be null | [Occamy System Schema](occamy-properties-rom.md "http://pulp-platform.org/snitch/snitch_cluster_tb.schema.json#/properties/rom")                               |
| [spm](#spm)                       | Not specified | Optional | cannot be null | [Occamy System Schema](occamy-properties-spm.md "http://pulp-platform.org/snitch/snitch_cluster_tb.schema.json#/properties/spm")                               |
| [nr_s1_quadrant](#nr_s1_quadrant) | `integer`     | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-s1-quadrants.md "http://pulp-platform.org/snitch/snitch_cluster_tb.schema.json#/properties/nr_s1_quadrant") |
| [s1_quadrant](#s1_quadrant)       | Not specified | Optional | cannot be null | [Occamy System Schema](occamy-properties-object.md "http://pulp-platform.org/snitch/snitch_cluster_tb.schema.json#/properties/s1_quadrant")                    |

## cluster

Base description of a Snitch cluster and its internal structure and configuration.

`cluster`

*   is required

*   Type: `object` ([Snitch Cluster Schema](occamy-properties-snitch-cluster-schema.md))

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-snitch-cluster-schema.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/cluster")

### cluster Type

`object` ([Snitch Cluster Schema](occamy-properties-snitch-cluster-schema.md))

## rom

Read-only memory from which *all* harts of the system start to boot.

`rom`

*   is optional

*   Type: `object` ([Details](occamy-properties-rom.md))

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-rom.md "http://pulp-platform.org/snitch/snitch_cluster_tb.schema.json#/properties/rom")

### rom Type

`object` ([Details](occamy-properties-rom.md))

### rom Default Value

The default value is:

```json
{
  "address": 16777216,
  "length": 131072
}
```

## spm



`spm`

*   is optional

*   Type: unknown

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-spm.md "http://pulp-platform.org/snitch/snitch_cluster_tb.schema.json#/properties/spm")

### spm Type

unknown

### spm Default Value

The default value is:

```json
{
  "size": 128,
  "banks": 8
}
```

## nr_s1\_quadrant



`nr_s1_quadrant`

*   is optional

*   Type: `integer` ([Number of S1 Quadrants](occamy-properties-number-of-s1-quadrants.md))

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-number-of-s1-quadrants.md "http://pulp-platform.org/snitch/snitch_cluster_tb.schema.json#/properties/nr_s1\_quadrant")

### nr_s1\_quadrant Type

`integer` ([Number of S1 Quadrants](occamy-properties-number-of-s1-quadrants.md))

### nr_s1\_quadrant Default Value

The default value is:

```json
8
```

## s1\_quadrant



`s1_quadrant`

*   is optional

*   Type: unknown ([object](occamy-properties-object.md))

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-object.md "http://pulp-platform.org/snitch/snitch_cluster_tb.schema.json#/properties/s1\_quadrant")

### s1\_quadrant Type

unknown ([object](occamy-properties-object.md))
