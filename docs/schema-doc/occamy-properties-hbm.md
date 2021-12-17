# Untitled undefined type in Occamy System Schema Schema

```txt
http://pulp-platform.org/snitch/occamy.schema.json#/properties/hbm
```

High Bandwidth Memory (HBM).

| Abstract            | Extensible | Status         | Identifiable | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                       |
| :------------------ | :--------- | :------------- | :----------- | :---------------- | :-------------------- | :------------------ | :--------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | No           | Forbidden         | Allowed               | none                | [occamy.schema.json*](occamy.schema.json "open original schema") |

## hbm Type

unknown

# undefined Properties

| Property                                        | Type     | Required | Nullable       | Defined by                                                                                                                                                                              |
| :---------------------------------------------- | :------- | :------- | :------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [address_0](#address_0)                         | `number` | Optional | cannot be null | [Occamy System Schema](occamy-properties-hbm-properties-address_0.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/hbm/properties/address_0")                         |
| [address_1](#address_1)                         | `number` | Optional | cannot be null | [Occamy System Schema](occamy-properties-hbm-properties-address_1.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/hbm/properties/address_1")                         |
| [nr_channels_total](#nr_channels_total)         | `number` | Optional | cannot be null | [Occamy System Schema](occamy-properties-hbm-properties-nr_channels_total.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/hbm/properties/nr_channels_total")         |
| [nr_channels_address_0](#nr_channels_address_0) | `number` | Optional | cannot be null | [Occamy System Schema](occamy-properties-hbm-properties-nr_channels_address_0.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/hbm/properties/nr_channels_address_0") |
| [channel_size](#channel_size)                   | `number` | Optional | cannot be null | [Occamy System Schema](occamy-properties-hbm-properties-channel_size.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/hbm/properties/channel_size")                   |

## address\_0

Start address of first memory region of HBM.

`address_0`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-hbm-properties-address\_0.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/hbm/properties/address\_0")

### address\_0 Type

`number`

### address\_0 Constraints

**minimum**: the value of this number must greater than or equal to: `0`

## address\_1

Start address of second memory region of HB.

`address_1`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-hbm-properties-address\_1.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/hbm/properties/address\_1")

### address\_1 Type

`number`

### address\_1 Constraints

**minimum**: the value of this number must greater than or equal to: `0`

## nr_channels_total

Total number of HBM channels (all are mapped onto region of address\_1.

`nr_channels_total`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-hbm-properties-nr_channels_total.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/hbm/properties/nr_channels_total")

### nr_channels_total Type

`number`

### nr_channels_total Constraints

**minimum**: the value of this number must greater than or equal to: `0`

## nr_channels_address\_0

Number of HBM channels mapped onto address\_0.

`nr_channels_address_0`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-hbm-properties-nr_channels_address\_0.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/hbm/properties/nr_channels_address\_0")

### nr_channels_address\_0 Type

`number`

### nr_channels_address\_0 Constraints

**minimum**: the value of this number must greater than or equal to: `0`

## channel_size

Size of a single HBM channel in bytes.

`channel_size`

*   is optional

*   Type: `number`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-hbm-properties-channel_size.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/hbm/properties/channel_size")

### channel_size Type

`number`

### channel_size Constraints

**minimum**: the value of this number must greater than or equal to: `0`
