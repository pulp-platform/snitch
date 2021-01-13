# Fixed Response Latency Memory Interface

A simplistic two channel memory interface with fixed latency (`N`) responses.

The addresses are word addresses (w/o byte offset). Bus accesses must always be
aligned.

!!! note
    There is no error mechanism provisioned.

## Channels

The interface contains two channels. The `q` channel is fully hand-shaked, while
the response channel `p` does not contain any back-pressure mechanism. Every
response comes with a given fixed-latency (`N`) answer on the `p` channel. Every
transaction on the `q` channel triggers a response on the `p` channel.

When connecting two interfaces of such kind the response latency must be
identical. Modules which increase the response latency must taken into account
when attaching down-stream circuitry.

# Memory Interface

Very similar to the TCDM but the back path provides no arbitration. The response
always comes with a fixed latency. Additionally, the address is used for
word-address (no sub-word addresses are possible).

* Request `q`:
  * `valid`: Transaction is valid.
  * `ready`: Slave accepted the transaction.
  * `write`: Transaction is a write.
  * `amo`: Atomic memory operations. Defined in the `reqrsp` interface.
  * `data`: Data to be written to memory.
  * `strb`: Byte-enable mask (one byte are 8 bit).
  * `user`: User signals, routed as additional payload.
* Response `p`:
  * `data`: Read-data.
