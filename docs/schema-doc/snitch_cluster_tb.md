# Snitch Cluster TB Schema Schema

```txt
http://pulp-platform.org/snitch/snitch_cluster_tb.schema.json
```

Description for a very simple single-cluster testbench. That is the most minimal system available. Most of the hardware is emulated by the testbench.

| Abstract            | Extensible | Status         | Identifiable | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                                            |
| :------------------ | :--------- | :------------- | :----------- | :---------------- | :-------------------- | :------------------ | :------------------------------------------------------------------------------------ |
| Can be instantiated | No         | Unknown status | No           | Forbidden         | Allowed               | none                | [snitch_cluster_tb.schema.json](snitch_cluster_tb.schema.json "open original schema") |

## Snitch Cluster TB Schema Type

`object` ([Snitch Cluster TB Schema](snitch_cluster_tb.md))

# Snitch Cluster TB Schema Properties

| Property            | Type     | Required | Nullable       | Defined by                                                                                                                                              |
| :------------------ | :------- | :------- | :------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------ |
| [cluster](#cluster) | `object` | Required | cannot be null | [Snitch Cluster TB Schema](occamy-properties-snitch-cluster-schema.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/cluster") |
| [dram](#dram)       | `object` | Required | cannot be null | [Snitch Cluster TB Schema](snitch_cluster_tb-properties-dram.md "http://pulp-platform.org/snitch/snitch_cluster_tb.schema.json#/properties/dram")       |

## cluster

Base description of a Snitch cluster and its internal structure and configuration.

`cluster`

*   is required

*   Type: `object` ([Snitch Cluster Schema](occamy-properties-snitch-cluster-schema.md))

*   cannot be null

*   defined in: [Snitch Cluster TB Schema](occamy-properties-snitch-cluster-schema.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/cluster")

### cluster Type

`object` ([Snitch Cluster Schema](occamy-properties-snitch-cluster-schema.md))

## dram

Main, off-chip DRAM.

`dram`

*   is required

*   Type: `object` ([DRAM](snitch_cluster_tb-properties-dram.md))

*   cannot be null

*   defined in: [Snitch Cluster TB Schema](snitch_cluster_tb-properties-dram.md "http://pulp-platform.org/snitch/snitch_cluster_tb.schema.json#/properties/dram")

### dram Type

`object` ([DRAM](snitch_cluster_tb-properties-dram.md))
