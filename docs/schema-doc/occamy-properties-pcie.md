# Untitled undefined type in Occamy System Schema Schema

```txt
http://pulp-platform.org/snitch/occamy.schema.json#/properties/pcie
```

Peripheral Component Interconnect Express or simply a Serial Link.

| Abstract            | Extensible | Status         | Identifiable | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                       |
| :------------------ | :--------- | :------------- | :----------- | :---------------- | :-------------------- | :------------------ | :--------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | No           | Forbidden         | Allowed               | none                | [occamy.schema.json*](occamy.schema.json "open original schema") |

## pcie Type

unknown

# undefined Properties

| Property                  | Type     | Required | Nullable       | Defined by                                                                                                                                                          |
| :------------------------ | :------- | :------- | :------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| [address_io](#address_io) | `number` | Optional | cannot be null | [Occamy System Schema](occamy-properties-pcie-properties-address_io.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/pcie/properties/address_io") |
| [address_mm](#address_mm) | `number` | Optional | cannot be null | [Occamy System Schema](occamy-properties-pcie-properties-address_mm.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/pcie/properties/address_mm") |
| [length](#length)         | `number` | Optional | cannot be null | [Occamy System Schema](occamy-properties-pcie-properties-length.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/pcie/properties/length")         |

## address_io

Start address of PCIE IO mapped region.

`address_io`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-pcie-properties-address_io.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/pcie/properties/address_io")

### address_io Type

`number`

### address_io Constraints

**minimum**: the value of this number must greater than or equal to: `0`

## address_mm

Start address of PCIE memory mapped region.

`address_mm`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-pcie-properties-address_mm.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/pcie/properties/address_mm")

### address_mm Type

`number`

### address_mm Constraints

**minimum**: the value of this number must greater than or equal to: `0`

## length

Size of both PCIE address regions.

`length`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-pcie-properties-length.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/pcie/properties/length")

### length Type

`number`

### length Constraints

**minimum**: the value of this number must greater than or equal to: `0`
