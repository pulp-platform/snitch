# Tightly Coupled Data Memory Interface

A simplistic two channel memory interface. It is a custom interface and
compatible to the original `lint` (logarithmic interface). This merely serves as
a common specification of the channel and signal names.

Sub-word accesses are not allowed. Fewer words can be written by using the
`strb` signal. The entire bus word is accessed during reads.

!!! note
    There is no error mechanism provisioned.

## Channels

The interface contains two channels. The `q` channel is fully hand-shaked, while
the response channel `p` only contains a valid signal without any back-pressure
mechanisms. Every transaction on the `q` channel triggers a response on the `p`
channel.

* Request `q`:
  * `valid`: Transaction is valid.
  * `ready`: Slave accepted the transaction.
  * `write`: Transaction is a write.
  * `amo`: Atomic memory operations. Defined in the `reqrsp` interface.
  * `data`: Data to be written to memory.
  * `strb`: Byte-enable mask (one byte are 8 bit).
  * `user`: User signals, routed as additional payload.
* Response `p`:
  * `valid`: Response data is valid.
  * `data`: Read-data.

!!! note
    The `q` handshake adheres to AXI-style handshaking rules, i.e., `valid`
    must not depend on `ready`.

## Modules

| Name             | Description                                                                   | Status |
| ---------------- | ----------------------------------------------------------------------------- | ------ |
| `axi_to_tcdm`    | Translates from AXI4+ATOP to `tcdm` using `axi_to_reqrsp` and `reqrsp_to_mem` | active |
| `reqrsp_to_tcdm` | Translates from `reqrsp` to `tcdm`.                                           | active |
| `tcdm_intf`      | Systemverilog interface definition of `tcdm` interface.                       | active |
| `tcdm_mux`       | Arbitrate multiple ports based on round-robin arbitration.                    | active |
| `tcdm_test`      | Common test infrastructure for the `tcdm` protocol.                           | active |
