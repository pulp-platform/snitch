# Core Description Schema

```txt
http://pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/cores/items
```

Description of a single core.


| Abstract            | Extensible | Status         | Identifiable | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                                        |
| :------------------ | ---------- | -------------- | ------------ | :---------------- | --------------------- | ------------------- | --------------------------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | No           | Forbidden         | Allowed               | none                | [snitch_cluster.schema.json\*](snitch_cluster.schema.json "open original schema") |

## items Type

`object` ([Core Description](snitch_cluster-properties-cores-core-description.md))

# Core Description Properties

| Property        | Type     | Required | Nullable       | Defined by                                                                                                                                                                                                         |
| :-------------- | -------- | -------- | -------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [isa](#isa)     | `string` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-cores-core-description-properties-isa-string.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/cores/items/properties/isa")        |
| [xssr](#xssr)   | `object` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-cores-core-description-properties-xssr-extension.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/cores/items/properties/xssr")   |
| [xfrep](#xfrep) | `object` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-cores-core-description-properties-xfrep-extension.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/cores/items/properties/xfrep") |
| [xdma](#xdma)   | `object` | Optional | cannot be null | [Snitch Cluster Schema](snitch_cluster-properties-cores-core-description-properties-xdma-extension.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/cores/items/properties/xdma")   |

## isa

ISA string as defined by the RISC-V standard. Only contain the standardized ISA extensions.


`isa`

-   is optional
-   Type: `string` ([ISA String](snitch_cluster-properties-cores-core-description-properties-isa-string.md))
-   cannot be null
-   defined in: [Snitch Cluster Schema](snitch_cluster-properties-cores-core-description-properties-isa-string.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/cores/items/properties/isa")

### isa Type

`string` ([ISA String](snitch_cluster-properties-cores-core-description-properties-isa-string.md))

### isa Examples

```json
"rv32imafd"
```

## xssr

Stream Semantic Registers (SSR) custom extension.


`xssr`

-   is optional
-   Type: `object` ([Xssr Extension](snitch_cluster-properties-cores-core-description-properties-xssr-extension.md))
-   cannot be null
-   defined in: [Snitch Cluster Schema](snitch_cluster-properties-cores-core-description-properties-xssr-extension.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/cores/items/properties/xssr")

### xssr Type

`object` ([Xssr Extension](snitch_cluster-properties-cores-core-description-properties-xssr-extension.md))

## xfrep

Floating-point repetition buffer (FREP) custom extension.


`xfrep`

-   is optional
-   Type: `object` ([Xfrep Extension](snitch_cluster-properties-cores-core-description-properties-xfrep-extension.md))
-   cannot be null
-   defined in: [Snitch Cluster Schema](snitch_cluster-properties-cores-core-description-properties-xfrep-extension.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/cores/items/properties/xfrep")

### xfrep Type

`object` ([Xfrep Extension](snitch_cluster-properties-cores-core-description-properties-xfrep-extension.md))

## xdma

Direct memory access (DMA) custom extension.


`xdma`

-   is optional
-   Type: `object` ([Xdma Extension](snitch_cluster-properties-cores-core-description-properties-xdma-extension.md))
-   cannot be null
-   defined in: [Snitch Cluster Schema](snitch_cluster-properties-cores-core-description-properties-xdma-extension.md "http&#x3A;//pulp-platform.org/snitch/snitch_cluster.schema.json#/properties/cores/items/properties/xdma")

### xdma Type

`object` ([Xdma Extension](snitch_cluster-properties-cores-core-description-properties-xdma-extension.md))
