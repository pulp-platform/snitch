# Scratch Pad Memory (SPM) Interface

TODO: Re-name to mem and move to common cells.

* Request:
  * `valid`: Transaction is valid.
  * `ready`: Slave accepted the transaction.
  * `we`: Transaction is a write.
  * `data`: Data to be written to memory.
  * `strb`: Byte-enable mask (one byte are 8 bit).
* Response:
  * `data`: Read-data.
  * `rvalid`: Read-data valid or write-transaction committed.
