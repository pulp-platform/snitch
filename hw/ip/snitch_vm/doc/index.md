# Virtual Memory

This IP contains common components for virtual memory and memory protection in
Snitch-based systems.

## Testbenches

This folder provides tests for:

- The page table walker (PTW): Random (and mostly legal) multi-level page table
  entries are generated. Resulting virtual addresses are driven on the request
  side and the response is compared to the golden model (generated during the
  randomization step). All ports are randomly delayed.
- The L0 TLBs: Random requests are generated. The golden model saves all
  requests, if a new request comes in it is either sourced from memory (if it
  exists) or re-generated based on constraint randomization. Response from the
  DUT are compared to the golden model.
- The L0 cache used in Snitch: Core instruction requests are randomly generated
  (except for branches and jumps which are taken). Refill (cache lines) are
  randomly generated making sure that instructions are RISC-V aligned (end in
  `2'b11`) and sometimes inferring ctrl flow changes. Requests are changing
  periodically to avoid infinite looping.
