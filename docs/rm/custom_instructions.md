# Instruction Set Extensions

For efficient execution we have defined a number of custom instructions. This
document gives a brief overview of their encoding.

## "Xssr" Extension for Stream Semantic Registers

The "Xssr" extension assigns stream semantics to a handful of the processor's registers. If enabled, reading and writing these registers translates into corresponding memory reads and writes. The addresses for these memory accesses are derived from a hardware address generator.

### Configuration Register Operations

| imm[11:4] | imm[4:0] | rs1    | funct3 | rd    | opcode     | operation |
|:---------:|:--------:|:------:|:------:|:-----:|:----------:|:---------:|
| 7         | 5        | 5      | 3      | 5     | 7          |           |
| addr      | ssr      | 000000 | 100    | dest  | OP-CUSTOM1 | SCFGR     |
| addr      | ssr      | value  | 101    | 00000 | OP-CUSTOM1 | SCFGW     |

SCFGR reads a value from an SSR configuration register, and SCFGW writes a value to an SSR configuration register. The argument *addr* specifies the index of the register, *ssr* specifies which SSR should be accessed. SCFGR places the read value in *rd*. SCFGW moves the value in *rs1* to the selected SSR configuration register.


## "Xfrep" Extension for Floating-Point Repetition

## "Xdma" Extension for Asynchronous Data Movement

The "Xdma" extension provides custom instructions to control an asynchronous data movement engine tightly coupled to the processor core.

### Address Operations

| funct7  | rs2   | rs1   | funct3 | rd    | opcode     | operation |
|:-------:|:-----:|:-----:|:------:|:-----:|:----------:|:---------:|
| 7       | 5     | 5     | 3      | 5     | 7          |           |
| 0000000 | ptrhi | ptrlo | 000    | 00000 | OP-CUSTOM1 | DMSRC     |
| 0000001 | ptrhi | ptrlo | 000    | 00000 | OP-CUSTOM1 | DMDST     |

DMSRC and DMDST specify the source and destination address pointers for the next data movement operation. The arguments *ptrhi* and *ptrlo* are truncated to 32-bit values, and concatenated to form a 64-bit value, and truncated to PLEN.

### Stride Operations

| funct7  | rs2     | rs1     | funct3 | rd    | opcode     | operation |
|:-------:|:-------:|:-------:|:------:|:-----:|:----------:|:---------:|
| 7       | 5       | 5       | 3      | 5     | 7          |           |
| 0000101 | dststrd | srcstrd | 000    | 00000 | OP-CUSTOM1 | DMSTRD    |
| 0000110 | 00000   | reps    | 000    | 00000 | OP-CUSTOM1 | DMREPS    |

DMSTRD configures the stride for two-dimensional transfers. The value in registers *rs1* and *rs2* are sign-extended to PLEN and configured as the source and destination stride, respectively. After each transfer of the innermost dimension, the strides are added to the respective address pointers.

DMREPS configures the value in register *rs1* as the size of the outer dimension for two-dimensional transfers.

### Control Operations

| funct7  | rs2    | rs1   | funct3 | rd    | opcode     | operation |
|:-------:|:------:|:-----:|:------:|:-----:|:----------:|:---------:|
| 7       | 5      | 5     | 3      | 5     | 7          |           |
| 0000010 | config | size  | 000    | dest  | OP-CUSTOM1 | DMSTRT    |
| 0000011 | status | 00000 | 000    | 00000 | OP-CUSTOM1 | DMSTAT    |
| 0000100 | error  | 00000 | 000    | 00000 | OP-CUSTOM1 | DMERR     |

| imm[11:0] | rs1    | funct3 | rd    | opcode     | operation |
|:---------:|:------:|:------:|:-----:|:----------:|:---------:|
| 12        | 5      | 3      | 5     | 7          |           |
| config    | size   | 001    | dest  | OP-CUSTOM1 | DMSTRTI   |
| status    | 00000  | 010    | dest  | OP-CUSTOM1 | DMSTATI   |
| error     | 00000  | 011    | dest  | OP-CUSTOM1 | DMERRI    |

DMSTRT and DMSTRTI initiate an asynchronous data movement with the parameters configured by the previous DM* instructions. A transfer id is placed in register *rd*, which is necessary to later check for transfer completion. *size* contains the number of consecutive bytes to transfer. For multi-dimensional transfers this is the size of the innermost dimension. *config* determines the following parameters of the transfer:

| Bits         | Value       | Description
|--------------|-------------|-------------
| config[0]    | decouple_rw | Decouple the handshakes of the read and write channels
| config[1]    | enable_2d   | Enable two-dimensional transfer
| config[3:2]  | 0b10        | Reserved (Source burst type)
| config[5:4]  | 0b10        | Reserved (Destination burst type)
| config[6]    | deburst     | Split bursts into individual bus transfers

DMSTAT and DMSTATI place the selected *status* flag of the DMA into register *rd*. The following *status* flags are supported:

| status | Name         | Description
|--------|--------------|-------------
| 0      | completed_id | Id of last completed transfer
| 1      | next_id      | Id allocated to the next transfer
| 2      | busy         | At least one transfer in progress
| 3      | would_block  | Next DMSTRT[I] blocks (transfer queue full)

The DMSTATI instruction can be used to implement a blocking wait for the completion of a specific DMA transfer:

        dmstrti a0, ...
    1:  dmstati t0, 0
        bltu a0, t0, 1b

Similarly, waiting for the completion of *all* DMA transfers:

    1:  dmstati t0, 2
        bnez t0, zero, 1b

DMERR and DMERRI read the specified *error* status from the DMA and place the result in register *rd*. Placeholder; always sets *rd* to 0.
