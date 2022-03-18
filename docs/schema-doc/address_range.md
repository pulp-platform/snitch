# Address Range Schema Schema

```txt
http://pulp-platform.org/snitch/address_range.schema.json
```

Description of a generic address range

| Abstract            | Extensible | Status         | Identifiable | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                                    |
| :------------------ | :--------- | :------------- | :----------- | :---------------- | :-------------------- | :------------------ | :---------------------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | No           | Forbidden         | Allowed               | none                | [address_range.schema.json](address_range.schema.json "open original schema") |

## Address Range Schema Type

`object` ([Address Range Schema](address_range.md))

# Address Range Schema Properties

| Property            | Type      | Required | Nullable       | Defined by                                                                                                                                  |
| :------------------ | :-------- | :------- | :------------- | :------------------------------------------------------------------------------------------------------------------------------------------ |
| [address](#address) | `integer` | Required | cannot be null | [Address Range Schema](address_range-properties-address.md "http://pulp-platform.org/snitch/address_range.schema.json#/properties/address") |
| [length](#length)   | `integer` | Required | cannot be null | [Address Range Schema](address_range-properties-length.md "http://pulp-platform.org/snitch/address_range.schema.json#/properties/length")   |

## address

Base address of range.

`address`

*   is required

*   Type: `integer`

*   cannot be null

*   defined in: [Address Range Schema](address_range-properties-address.md "http://pulp-platform.org/snitch/address_range.schema.json#/properties/address")

### address Type

`integer`

### address Constraints

**minimum**: the value of this number must greater than or equal to: `0`

## length

Size in bytes of range.

`length`

*   is required

*   Type: `integer`

*   cannot be null

*   defined in: [Address Range Schema](address_range-properties-length.md "http://pulp-platform.org/snitch/address_range.schema.json#/properties/length")

### length Type

`integer`

### length Constraints

**minimum**: the value of this number must greater than or equal to: `0`
