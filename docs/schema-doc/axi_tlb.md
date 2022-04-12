# AXI TLB Schema Schema

```txt
http://pulp-platform.org/snitch/axi_tlb.schema.json
```

AXI TLB Properties

| Abstract            | Extensible | Status         | Identifiable | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                        |
| :------------------ | :--------- | :------------- | :----------- | :---------------- | :-------------------- | :------------------ | :---------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | No           | Forbidden         | Allowed               | none                | [axi_tlb.schema.json](axi_tlb.schema.json "open original schema") |

## AXI TLB Schema Type

`object` ([AXI TLB Schema](axi_tlb.md))

# AXI TLB Schema Properties

| Property                          | Type      | Required | Nullable       | Defined by                                                                                                                              |
| :-------------------------------- | :-------- | :------- | :------------- | :-------------------------------------------------------------------------------------------------------------------------------------- |
| [max_trans](#max_trans)           | `integer` | Optional | cannot be null | [AXI TLB Schema](axi_tlb-properties-max_trans.md "http://pulp-platform.org/snitch/axi_tlb.schema.json#/properties/max_trans")           |
| [l1_num_entries](#l1_num_entries) | `integer` | Optional | cannot be null | [AXI TLB Schema](axi_tlb-properties-l1_num_entries.md "http://pulp-platform.org/snitch/axi_tlb.schema.json#/properties/l1_num_entries") |
| [l1_cut_ax](#l1_cut_ax)           | `boolean` | Optional | cannot be null | [AXI TLB Schema](axi_tlb-properties-l1_cut_ax.md "http://pulp-platform.org/snitch/axi_tlb.schema.json#/properties/l1_cut_ax")           |

## max_trans

Maximum outstanding transactions the TLB can handle.

`max_trans`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [AXI TLB Schema](axi_tlb-properties-max_trans.md "http://pulp-platform.org/snitch/axi_tlb.schema.json#/properties/max_trans")

### max_trans Type

`integer`

### max_trans Default Value

The default value is:

```json
32
```

## l1\_num_entries

Number of TLB translation entries.

`l1_num_entries`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [AXI TLB Schema](axi_tlb-properties-l1\_num_entries.md "http://pulp-platform.org/snitch/axi_tlb.schema.json#/properties/l1\_num_entries")

### l1\_num_entries Type

`integer`

### l1\_num_entries Default Value

The default value is:

```json
8
```

## l1\_cut_ax

Insert spill register on TLB request channels, cutting timing paths.

`l1_cut_ax`

*   is optional

*   Type: `boolean`

*   cannot be null

*   defined in: [AXI TLB Schema](axi_tlb-properties-l1\_cut_ax.md "http://pulp-platform.org/snitch/axi_tlb.schema.json#/properties/l1\_cut_ax")

### l1\_cut_ax Type

`boolean`

### l1\_cut_ax Default Value

The default value is:

```json
true
```
