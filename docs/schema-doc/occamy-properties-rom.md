# Untitled object in Occamy System Schema Schema

```txt
http://pulp-platform.org/snitch/occamy.schema.json#/properties/rom
```

Read-only memory from which *all* harts of the system start to boot.

| Abstract            | Extensible | Status         | Identifiable            | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                       |
| :------------------ | :--------- | :------------- | :---------------------- | :---------------- | :-------------------- | :------------------ | :--------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | Unknown identifiability | Forbidden         | Allowed               | none                | [occamy.schema.json*](occamy.schema.json "open original schema") |

## rom Type

`object` ([Details](occamy-properties-rom.md))

## rom Default Value

The default value is:

```json
{
  "address": 16777216,
  "length": 131072
}
```
