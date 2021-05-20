# Untitled undefined type in Occamy System Schema Schema

```txt
http://pulp-platform.org/snitch/snitch_cluster_tb.schema.json#/properties/spm
```



| Abstract            | Extensible | Status         | Identifiable | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                       |
| :------------------ | :--------- | :------------- | :----------- | :---------------- | :-------------------- | :------------------ | :--------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | No           | Forbidden         | Allowed               | none                | [occamy.schema.json*](occamy.schema.json "open original schema") |

## spm Type

unknown

## spm Default Value

The default value is:

```json
{
  "size": 128,
  "banks": 8
}
```

# undefined Properties

| Property        | Type     | Required | Nullable       | Defined by                                                                                                                                                         |
| :-------------- | :------- | :------- | :------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [size](#size)   | `number` | Optional | cannot be null | [Occamy System Schema](occamy-properties-spm-properties-size.md "http://pulp-platform.org/snitch/snitch_cluster_tb.schema.json#/properties/spm/properties/size")   |
| [banks](#banks) | `number` | Optional | cannot be null | [Occamy System Schema](occamy-properties-spm-properties-banks.md "http://pulp-platform.org/snitch/snitch_cluster_tb.schema.json#/properties/spm/properties/banks") |

## size

Size of SPM in KiByte. Divided in `n` banks. The total size must be divisible by the number of banks.

`size`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-spm-properties-size.md "http://pulp-platform.org/snitch/snitch_cluster_tb.schema.json#/properties/spm/properties/size")

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

*   defined in: [Occamy System Schema](occamy-properties-spm-properties-banks.md "http://pulp-platform.org/snitch/snitch_cluster_tb.schema.json#/properties/spm/properties/banks")

### banks Type

`number`

### banks Examples

```json
16
```

```json
32
```
