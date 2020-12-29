# Snitch Cluster

This ip contains a cluster of Snitch cores, arranged in a specific (but
configurable fashion).


## Memory Map

The memory map of the cluster is determined by the `cluster_base_addr_i` signal.
Depending on the amount of memory the `TCDM` and `Periph` regions will be scaled
accordingly. The peripheral region will always be the same size as the `TCDM`.

- Let `TCDMSize` denote the size of the `TCDM`.
- Let `PeripheralSize` denote the size of the cluster peripheral address space.
- Let `TCDMEndAddress = cluster_base_addr_i + TCDMSize`
- Let `SocEndAddress = TCDMEndAddress + PeripheralSize`


| Range                                      | Dest   | Description                                                                 |
| ------------------------------------------ | ------ | --------------------------------------------------------------------------- |
| [`SocEndAddress` - )                       | SoC    | Routed out of the cluster. Address range depends on available address bits. |
| [`TCDMEndAddress` - `SocEndAddress`)       | Periph | Cluster local peripherals.                                                  |
| [`cluster_base_addr_i` - `TCDMEndAddress`) | TCDM   | Cluster local tightly coupled data memory.                                  |
| [`0x0` - `cluster_base_addr_i`)            | SoC    | Routed out of the cluster.                                                  |


!!! info
    Because the address check on each core's LSU path is quite critical, we rely
    on a simplified checking scheme were we revert to checking the address
    against a mask and base combination. This makes the hardware less expensive
    (and faster) as no complicated adder circuits are needed and a couple of
    `and` gates are enough. (In comparison to a full address check where two
    adders are need)

    ```verilog
    assign match = (addr_base & addr_mask) == (addr_to_check & addr_mask);
    ```

    As a consequence the `cluster_base_addr_i` has to be aligned to the the
    `TCDM` size, otherwise this check can't distinguish between routing to the
    `TCDM` or `SoC`/`Periph`. A static assertion checks that this holds true.
