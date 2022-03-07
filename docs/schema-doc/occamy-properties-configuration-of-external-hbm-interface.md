# Configuration of external HBM interface Schema

```txt
http://pulp-platform.org/snitch/occamy.schema.json#/properties/hbm
```



| Abstract            | Extensible | Status         | Identifiable | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                       |
| :------------------ | :--------- | :------------- | :----------- | :---------------- | :-------------------- | :------------------ | :--------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | No           | Forbidden         | Allowed               | none                | [occamy.schema.json*](occamy.schema.json "open original schema") |

## hbm Type

`object` ([Configuration of external HBM interface](occamy-properties-configuration-of-external-hbm-interface.md))

# Configuration of external HBM interface Properties

| Property                                        | Type          | Required | Nullable       | Defined by                                                                                                                                                                                                                  |
| :---------------------------------------------- | :------------ | :------- | :------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [address_1](#address_1)                         | `integer`     | Optional | cannot be null | [Occamy System Schema](occamy-properties-configuration-of-external-hbm-interface-properties-address_1.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/hbm/properties/address_1")                         |
| [address_2](#address_2)                         | `integer`     | Optional | cannot be null | [Occamy System Schema](occamy-properties-configuration-of-external-hbm-interface-properties-address_2.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/hbm/properties/address_2")                         |
| [channel_size](#channel_size)                   | `integer`     | Optional | cannot be null | [Occamy System Schema](occamy-properties-configuration-of-external-hbm-interface-properties-channel_size.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/hbm/properties/channel_size")                   |
| [nr_channels_total](#nr_channels_total)         | `integer`     | Optional | cannot be null | [Occamy System Schema](occamy-properties-configuration-of-external-hbm-interface-properties-nr_channels_total.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/hbm/properties/nr_channels_total")         |
| [nr_channels_address_0](#nr_channels_address_0) | `integer`     | Optional | cannot be null | [Occamy System Schema](occamy-properties-configuration-of-external-hbm-interface-properties-nr_channels_address_0.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/hbm/properties/nr_channels_address_0") |
| [cfg_regions](#cfg_regions)                     | Not specified | Optional | cannot be null | [Occamy System Schema](occamy-properties-configuration-of-external-hbm-interface-properties-cfg_regions.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/hbm/properties/cfg_regions")                     |

## address\_1

Start of HBM address region 1.

`address_1`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-configuration-of-external-hbm-interface-properties-address\_1.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/hbm/properties/address\_1")

### address\_1 Type

`integer`

### address\_1 Constraints

**minimum**: the value of this number must greater than or equal to: `0`

## address\_2

Start of HBM address region 1.

`address_2`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-configuration-of-external-hbm-interface-properties-address\_2.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/hbm/properties/address\_2")

### address\_2 Type

`integer`

### address\_2 Constraints

**minimum**: the value of this number must greater than or equal to: `0`

## channel_size

Size of single HBM channel region.

`channel_size`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-configuration-of-external-hbm-interface-properties-channel_size.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/hbm/properties/channel_size")

### channel_size Type

`integer`

### channel_size Constraints

**minimum**: the value of this number must greater than or equal to: `0`

## nr_channels_total

Total number of HBM channels.

`nr_channels_total`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-configuration-of-external-hbm-interface-properties-nr_channels_total.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/hbm/properties/nr_channels_total")

### nr_channels_total Type

`integer`

### nr_channels_total Constraints

**minimum**: the value of this number must greater than or equal to: `0`

## nr_channels_address\_0

Number of lower HBM channels accessible over address region 1

`nr_channels_address_0`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-configuration-of-external-hbm-interface-properties-nr_channels_address\_0.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/hbm/properties/nr_channels_address\_0")

### nr_channels_address\_0 Type

`integer`

### nr_channels_address\_0 Constraints

**minimum**: the value of this number must greater than or equal to: `0`

## cfg_regions



`cfg_regions`

*   is optional

*   Type: unknown

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-configuration-of-external-hbm-interface-properties-cfg_regions.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/hbm/properties/cfg_regions")

### cfg_regions Type

unknown
