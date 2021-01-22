# DRAM Schema

```txt
http://pulp-platform.org/snitch/snitch_cluster_tb.schema.json#/properties/dram
```

Main, off-chip DRAM.

| Abstract            | Extensible | Status         | Identifiable | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                                             |
| :------------------ | :--------- | :------------- | :----------- | :---------------- | :-------------------- | :------------------ | :------------------------------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | No           | Forbidden         | Allowed               | none                | [snitch_cluster_tb.schema.json*](snitch_cluster_tb.schema.json "open original schema") |

## dram Type

`object` ([DRAM](snitch_cluster_tb-properties-dram.md))

# DRAM Properties

| Property            | Type     | Required | Nullable       | Defined by                                                                                                                                                                              |
| :------------------ | :------- | :------- | :------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [address](#address) | `number` | Required | cannot be null | [Snitch Cluster TB Schema](snitch_cluster_tb-properties-dram-properties-address.md "http://pulp-platform.org/snitch/snitch_cluster_tb.schema.json#/properties/dram/properties/address") |
| [length](#length)   | `number` | Required | cannot be null | [Snitch Cluster TB Schema](snitch_cluster_tb-properties-dram-properties-length.md "http://pulp-platform.org/snitch/snitch_cluster_tb.schema.json#/properties/dram/properties/length")   |

## address

Start address of DRAM.

`address`

*   is required

*   Type: `number`

*   cannot be null

*   defined in: [Snitch Cluster TB Schema](snitch_cluster_tb-properties-dram-properties-address.md "http://pulp-platform.org/snitch/snitch_cluster_tb.schema.json#/properties/dram/properties/address")

### address Type

`number`

### address Constraints

**minimum**: the value of this number must greater than or equal to: `0`

## length

Total size of DRAM in bytes.

`length`

*   is required

*   Type: `number`

*   cannot be null

*   defined in: [Snitch Cluster TB Schema](snitch_cluster_tb-properties-dram-properties-length.md "http://pulp-platform.org/snitch/snitch_cluster_tb.schema.json#/properties/dram/properties/length")

### length Type

`number`

### length Constraints

**minimum**: the value of this number must greater than or equal to: `0`
