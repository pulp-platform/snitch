# Untitled undefined type in Occamy System Schema Schema

```txt
http://pulp-platform.org/snitch/occamy.schema.json#/properties/dram
```

DRAM memory. DRAM address range usually corresponds to 'hbm address\_0' and 'nr_channels_address\_0'.

| Abstract            | Extensible | Status         | Identifiable | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                       |
| :------------------ | :--------- | :------------- | :----------- | :---------------- | :-------------------- | :------------------ | :--------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | No           | Forbidden         | Allowed               | none                | [occamy.schema.json*](occamy.schema.json "open original schema") |

## dram Type

unknown

# undefined Properties

| Property            | Type     | Required | Nullable       | Defined by                                                                                                                                                    |
| :------------------ | :------- | :------- | :------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| [address](#address) | `number` | Optional | cannot be null | [Occamy System Schema](occamy-properties-dram-properties-address.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/dram/properties/address") |
| [length](#length)   | `number` | Optional | cannot be null | [Occamy System Schema](occamy-properties-dram-properties-length.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/dram/properties/length")   |

## address

Start address of DRAM address region.

`address`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-dram-properties-address.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/dram/properties/address")

### address Type

`number`

### address Constraints

**minimum**: the value of this number must greater than or equal to: `0`

## length

Size of DRAM address region.

`length`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-dram-properties-length.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/dram/properties/length")

### length Type

`number`

### length Constraints

**minimum**: the value of this number must greater than or equal to: `0`
