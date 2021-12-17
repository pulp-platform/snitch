# Untitled undefined type in Occamy System Schema Schema

```txt
http://pulp-platform.org/snitch/occamy.schema.json#/properties/hbi
```



| Abstract            | Extensible | Status         | Identifiable | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                       |
| :------------------ | :--------- | :------------- | :----------- | :---------------- | :-------------------- | :------------------ | :--------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | No           | Forbidden         | Allowed               | none                | [occamy.schema.json*](occamy.schema.json "open original schema") |

## hbi Type

unknown

## hbi Default Value

The default value is:

```json
{
  "size": 128
}
```

# undefined Properties

| Property            | Type     | Required | Nullable       | Defined by                                                                                                                                                  |
| :------------------ | :------- | :------- | :------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [address](#address) | `number` | Optional | cannot be null | [Occamy System Schema](occamy-properties-hbi-properties-address.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/hbi/properties/address") |
| [length](#length)   | `number` | Optional | cannot be null | [Occamy System Schema](occamy-properties-hbi-properties-length.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/hbi/properties/length")   |

## address

Start address of SPM (Scratchpad Memory).

`address`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-hbi-properties-address.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/hbi/properties/address")

### address Type

`number`

### address Constraints

**minimum**: the value of this number must greater than or equal to: `0`

## length

Size of SPM based on the address range. The full address range will be mapped to SPM.

`length`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-hbi-properties-length.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/hbi/properties/length")

### length Type

`number`

### length Constraints

**minimum**: the value of this number must greater than or equal to: `0`

### length Examples

```json
131072
```
