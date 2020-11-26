# Snitch Instruction Cache

This folder contains components for the Snitch instruction cache. The
instruction cache consists of a private L0 cache, usually made out of latches or
flip-flops. The L0 cache is small is used to serve requests in the same cycle as
it has been requested (the L0 sits in the core's only pipeline stage).

## Testbench

- The L0 cache used in Snitch: Core instruction requests are randomly generated
  (except for branches and jumps which are taken). Refill (cache lines) are
  randomly generated making sure that instructions are RISC-V aligned (end in
  `2'b11`) and sometimes inferring ctrl flow changes. Requests are changing
  periodically to avoid infinite looping.
