# Untitled object in Snitch Cluster Schema Schema

```txt
http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/sram_cfg_fields
```

The names and widths of memory cut configuration inputs needed for implementation

| Abstract            | Extensible | Status         | Identifiable            | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                                       |
| :------------------ | :--------- | :------------- | :---------------------- | :---------------- | :-------------------- | :------------------ | :------------------------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | Unknown identifiability | Forbidden         | Allowed               | none                | [snitch_cluster.schema.json*](snitch_cluster.schema.json "open original schema") |

## sram_cfg_fields Type

`object` ([Details](snitch_cluster-properties-sram_cfg_fields.md))

## sram_cfg_fields Constraints

**minimum number of properties**: the minimum number of properties for this object is: `1`

## sram_cfg_fields Default Value

The default value is:

```json
{
  "reserved": 1
}
```

# undefined Properties

| Property              | Type     | Required | Nullable       | Defined by                                                                                                                                                                                               |
| :-------------------- | :------- | :------- | :------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Additional Properties | `number` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-sram_cfg_fields-additionalproperties.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/sram_cfg_fields/additionalProperties") |

## Additional Properties

Additional properties are allowed, as long as they follow this schema:



*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Snitch Cluster Schema](snitch_cluster-properties-sram_cfg_fields-additionalproperties.md "http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/sram_cfg_fields/additionalProperties")

### additionalProperties Type

`number`

### additionalProperties Constraints

**minimum**: the value of this number must greater than or equal to: `1`
