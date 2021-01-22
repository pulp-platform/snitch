# Untitled object in Snitch Cluster Schema Schema

```txt
http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/tcdm
```

Configuration of the Tightly Coupled Data Memory of this cluster.

| Abstract            | Extensible | Status         | Identifiable | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                                       |
| :------------------ | :--------- | :------------- | :----------- | :---------------- | :-------------------- | :------------------ | :------------------------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | No           | Forbidden         | Allowed               | none                | [snitch_cluster.schema.json*](snitch_cluster.schema.json "open original schema") |

## tcdm Type

`object` ([Details](snitch_cluster-properties-tcdm.md))

## tcdm Default Value

The default value is:

```json
{
  "size": 128,
  "banks": 32
}
```

# undefined Properties

| Property        | Type     | Required | Nullable       | Defined by                                                                                                                                                                 |
| :-------------- | :------- | :------- | :------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [size](#size)   | `number` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-tcdm-properties-size.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/tcdm/properties/size")   |
| [banks](#banks) | `number` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-tcdm-properties-banks.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/tcdm/properties/banks") |

## size

Size of TCDM in KiByte. Divided in `n` banks. The total size must be divisible by the number of banks.

`size`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-tcdm-properties-size.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/tcdm/properties/size")

### size Type

`number`

### size Examples

```json
128
```

```json
64
```

## banks

Number of banks.

`banks`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-tcdm-properties-banks.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/tcdm/properties/banks")

### banks Type

`number`

### banks Examples

```json
16
```

```json
32
```
