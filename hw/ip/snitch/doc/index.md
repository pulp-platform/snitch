# Snitch

This folder contains the main Snitch core, incl. L0 translation lookaside buffer
(TLB), register file and load store unit (LSU).

## Testbench

- The L0 TLBs: Random requests are generated. The golden model saves all
  requests, if a new request comes in it is either sourced from memory (if it
  exists) or re-generated based on constraint randomization. Response from the
  DUT are compared to the golden model.
