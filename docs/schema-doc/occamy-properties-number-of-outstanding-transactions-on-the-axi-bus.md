# Number of outstanding transactions on the AXI bus Schema

```txt
http://pulp-platform.org/snitch/occamy.schema.json#/properties/txns
```



| Abstract            | Extensible | Status         | Identifiable | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                       |
| :------------------ | :--------- | :------------- | :----------- | :---------------- | :-------------------- | :------------------ | :--------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | No           | Forbidden         | Allowed               | none                | [occamy.schema.json*](occamy.schema.json "open original schema") |

## txns Type

`object` ([Number of outstanding transactions on the AXI bus](occamy-properties-number-of-outstanding-transactions-on-the-axi-bus.md))

# Number of outstanding transactions on the AXI bus Properties

| Property                            | Type      | Required | Nullable       | Defined by                                                                                                                                                                                                                 |
| :---------------------------------- | :-------- | :------- | :------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [wide_and_inter](#wide_and_inter)   | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-outstanding-transactions-on-the-axi-bus-properties-wide_and_inter.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/txns/properties/wide_and_inter")   |
| [wide_to_hbm](#wide_to_hbm)         | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-outstanding-transactions-on-the-axi-bus-properties-wide_to_hbm.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/txns/properties/wide_to_hbm")         |
| [narrow_and_wide](#narrow_and_wide) | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-outstanding-transactions-on-the-axi-bus-properties-narrow_and_wide.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/txns/properties/narrow_and_wide") |
| [rmq](#rmq)                         | `integer` | Optional | cannot be null | [Occamy System Schema](occamy-properties-number-of-outstanding-transactions-on-the-axi-bus-properties-rmq.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/txns/properties/rmq")                         |

## wide_and_inter

inter xbar -> wide xbar & wide xbar -> inter xbar

`wide_and_inter`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-number-of-outstanding-transactions-on-the-axi-bus-properties-wide_and_inter.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/txns/properties/wide_and_inter")

### wide_and_inter Type

`integer`

### wide_and_inter Default Value

The default value is:

```json
4
```

## wide_to_hbm

wide xbar -> hbm xbar

`wide_to_hbm`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-number-of-outstanding-transactions-on-the-axi-bus-properties-wide_to_hbm.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/txns/properties/wide_to_hbm")

### wide_to_hbm Type

`integer`

### wide_to_hbm Default Value

The default value is:

```json
4
```

## narrow_and_wide

narrow xbar -> wide xbar & wide xbar -> narrow xbar

`narrow_and_wide`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-number-of-outstanding-transactions-on-the-axi-bus-properties-narrow_and_wide.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/txns/properties/narrow_and_wide")

### narrow_and_wide Type

`integer`

### narrow_and_wide Default Value

The default value is:

```json
4
```

## rmq

Remote Quadrant mux/demux

`rmq`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [Occamy System Schema](occamy-properties-number-of-outstanding-transactions-on-the-axi-bus-properties-rmq.md "http://pulp-platform.org/snitch/occamy.schema.json#/properties/txns/properties/rmq")

### rmq Type

`integer`

### rmq Default Value

The default value is:

```json
4
```
