# Peripherals Schema Schema

```txt
http://pulp-platform.org/snitch/peripherals.schema.json#/properties/peripherals
```

Description of an a peripheral sub-system.

| Abstract            | Extensible | Status         | Identifiable | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                       |
| :------------------ | :--------- | :------------- | :----------- | :---------------- | :-------------------- | :------------------ | :--------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | No           | Forbidden         | Allowed               | none                | [occamy.schema.json*](occamy.schema.json "open original schema") |

## peripherals Type

`object` ([Peripherals Schema](occamy-properties-peripherals-schema.md))

# Peripherals Schema Properties

| Property                                      | Type     | Required | Nullable       | Defined by                                                                                                                                                      |
| :-------------------------------------------- | :------- | :------- | :------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [rom](#rom)                                   | `object` | Optional | cannot be null | [Peripherals Schema](peripherals-properties-rom.md "http://pulp-platform.org/snitch/peripherals.schema.json#/properties/rom")                                   |
| [clint](#clint)                               | `object` | Optional | cannot be null | [Peripherals Schema](peripherals-properties-clint.md "http://pulp-platform.org/snitch/peripherals.schema.json#/properties/clint")                               |
| [axi_lite_peripherals](#axi_lite_peripherals) | `array`  | Optional | cannot be null | [Peripherals Schema](peripherals-properties-axi_lite_peripherals.md "http://pulp-platform.org/snitch/peripherals.schema.json#/properties/axi_lite_peripherals") |
| [regbus_peripherals](#regbus_peripherals)     | `array`  | Optional | cannot be null | [Peripherals Schema](peripherals-properties-regbus_peripherals.md "http://pulp-platform.org/snitch/peripherals.schema.json#/properties/regbus_peripherals")     |

## rom

Read-only memory from which *all* harts of the system start to boot.

`rom`

*   is optional

*   Type: `object` ([Details](peripherals-properties-rom.md))

*   cannot be null

*   defined in: [Peripherals Schema](peripherals-properties-rom.md "http://pulp-platform.org/snitch/peripherals.schema.json#/properties/rom")

### rom Type

`object` ([Details](peripherals-properties-rom.md))

### rom Default Value

The default value is:

```json
{
  "address": 16777216,
  "length": 131072
}
```

## clint

Core-local Interrupt Controller (CLINT) peripheral.

`clint`

*   is optional

*   Type: `object` ([Details](peripherals-properties-clint.md))

*   cannot be null

*   defined in: [Peripherals Schema](peripherals-properties-clint.md "http://pulp-platform.org/snitch/peripherals.schema.json#/properties/clint")

### clint Type

`object` ([Details](peripherals-properties-clint.md))

### clint Default Value

The default value is:

```json
{
  "address": 67108864,
  "length": 1048576
}
```

## axi_lite_peripherals



`axi_lite_peripherals`

*   is optional

*   Type: unknown\[]

*   cannot be null

*   defined in: [Peripherals Schema](peripherals-properties-axi_lite_peripherals.md "http://pulp-platform.org/snitch/peripherals.schema.json#/properties/axi_lite_peripherals")

### axi_lite_peripherals Type

unknown\[]

### axi_lite_peripherals Constraints

**unique items**: all items in this array must be unique. Duplicates are not allowed.

## regbus_peripherals



`regbus_peripherals`

*   is optional

*   Type: unknown\[]

*   cannot be null

*   defined in: [Peripherals Schema](peripherals-properties-regbus_peripherals.md "http://pulp-platform.org/snitch/peripherals.schema.json#/properties/regbus_peripherals")

### regbus_peripherals Type

unknown\[]

### regbus_peripherals Constraints

**unique items**: all items in this array must be unique. Duplicates are not allowed.
