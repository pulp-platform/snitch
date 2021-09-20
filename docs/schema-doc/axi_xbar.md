# AXI Crossbar Schema Schema

```txt
http://pulp-platform.org/snitch/axi_xbar.schema.json
```

AXI Crossbar Properties

| Abstract            | Extensible | Status         | Identifiable | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                          |
| :------------------ | :--------- | :------------- | :----------- | :---------------- | :-------------------- | :------------------ | :------------------------------------------------------------------ |
| Can be instantiated | No         | Unknown status | No           | Forbidden         | Allowed               | none                | [axi_xbar.schema.json](axi_xbar.schema.json "open original schema") |

## AXI Crossbar Schema Type

`object` ([AXI Crossbar Schema](axi_xbar.md))

# AXI Crossbar Schema Properties

| Property                        | Type      | Required | Nullable       | Defined by                                                                                                                                   |
| :------------------------------ | :-------- | :------- | :------------- | :------------------------------------------------------------------------------------------------------------------------------------------- |
| [max_slv_trans](#max_slv_trans) | `integer` | Optional | cannot be null | [AXI Crossbar Schema](axi_xbar-properties-max_slv_trans.md "http://pulp-platform.org/snitch/axi_xbar.schema.json#/properties/max_slv_trans") |
| [max_mst_trans](#max_mst_trans) | `integer` | Optional | cannot be null | [AXI Crossbar Schema](axi_xbar-properties-max_mst_trans.md "http://pulp-platform.org/snitch/axi_xbar.schema.json#/properties/max_mst_trans") |
| [fall_through](#fall_through)   | `boolean` | Optional | cannot be null | [AXI Crossbar Schema](axi_xbar-properties-fall_through.md "http://pulp-platform.org/snitch/axi_xbar.schema.json#/properties/fall_through")   |

## max_slv_trans

Maximum outstanding transaction on the slave port.

`max_slv_trans`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [AXI Crossbar Schema](axi_xbar-properties-max_slv_trans.md "http://pulp-platform.org/snitch/axi_xbar.schema.json#/properties/max_slv_trans")

### max_slv_trans Type

`integer`

### max_slv_trans Default Value

The default value is:

```json
4
```

## max_mst_trans

Maximum outstanding transaction on the master port.

`max_mst_trans`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [AXI Crossbar Schema](axi_xbar-properties-max_mst_trans.md "http://pulp-platform.org/snitch/axi_xbar.schema.json#/properties/max_mst_trans")

### max_mst_trans Type

`integer`

### max_mst_trans Default Value

The default value is:

```json
4
```

## fall_through

Configure crossbar to be fall-through (zero latency).

`fall_through`

*   is optional

*   Type: `boolean`

*   cannot be null

*   defined in: [AXI Crossbar Schema](axi_xbar-properties-fall_through.md "http://pulp-platform.org/snitch/axi_xbar.schema.json#/properties/fall_through")

### fall_through Type

`boolean`
