# Manticore Schema Schema

```txt
http://pulp-platform.org/snitch/manticore.schema.json
```

Manticore system description


| Abstract            | Extensible | Status         | Identifiable | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                            |
| :------------------ | ---------- | -------------- | ------------ | :---------------- | --------------------- | ------------------- | --------------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | No           | Forbidden         | Allowed               | none                | [manticore.schema.json](manticore.schema.json "open original schema") |

## Manticore Schema Type

`object` ([Manticore Schema](manticore.md))

# Manticore Schema Properties

| Property              | Type    | Required | Nullable       | Defined by                                                                                                                             |
| :-------------------- | ------- | -------- | -------------- | :------------------------------------------------------------------------------------------------------------------------------------- |
| [clusters](#clusters) | `array` | Required | cannot be null | [Manticore Schema](manticore-properties-clusters.md "http&#x3A;//pulp-platform.org/snitch/manticore.schema.json#/properties/clusters") |

## clusters

An array of snitch clusters.


`clusters`

-   is required
-   Type: `object[]` ([Snitch Cluster Schema](manticore-properties-clusters-snitch-cluster-schema.md))
-   cannot be null
-   defined in: [Manticore Schema](manticore-properties-clusters.md "http&#x3A;//pulp-platform.org/snitch/manticore.schema.json#/properties/clusters")

### clusters Type

`object[]` ([Snitch Cluster Schema](manticore-properties-clusters-snitch-cluster-schema.md))
