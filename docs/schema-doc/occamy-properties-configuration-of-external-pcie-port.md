# Configuration of external PCIe port Schema

```txt
http://pulp-platform.org/snitch/occamy.schema.json#/properties/pcie
```



| Abstract            | Extensible | Status         | Identifiable | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                       |
| :------------------ | :--------- | :------------- | :----------- | :---------------- | :-------------------- | :------------------ | :--------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | No           | Forbidden         | Allowed               | none                | [occamy.schema.json*](occamy.schema.json "open original schema") |

## pcie Type

`object` ([Configuration of external PCIe port](occamy-properties-configuration-of-external-pcie-port.md))

# Configuration of external PCIe port Properties

| Property                  | Type      | Required | Nullable       | Defined by                                                                                                                                                                                         |
| :------------------------ | :-------- | :------- | :------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [address_io](#address_io) | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-configuration-of-external-pcie-port-properties-address_io.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/pcie/properties/address_io") |
| [address_mm](#address_mm) | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-configuration-of-external-pcie-port-properties-address_mm.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/pcie/properties/address_mm") |
| [length](#length)         | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-configuration-of-external-pcie-port-properties-length.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/pcie/properties/length")         |

## address_io

Base address of PCIe IO range.

`address_io`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-configuration-of-external-pcie-port-properties-address_io.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/pcie/properties/address_io")

### address_io Type

`integer`

### address_io Constraints

**minimum**: the value of this number must greater than or equal to: `0`

## address_mm

Base address of PCIe memory-mapped range.

`address_mm`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-configuration-of-external-pcie-port-properties-address_mm.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/pcie/properties/address_mm")

### address_mm Type

`integer`

### address_mm Constraints

**minimum**: the value of this number must greater than or equal to: `0`

## length

Size in bytes of all PCIe ranges.

`length`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-configuration-of-external-pcie-port-properties-length.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/pcie/properties/length")

### length Type

`integer`

### length Constraints

**minimum**: the value of this number must greater than or equal to: `0`
