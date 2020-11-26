# Virtual Memory

This IP contains common components for virtual memory and memory protection in
Snitch-based systems. Currently the only shared component is the page table walker.

## Testbenches

This folder provides tests for:

- The page table walker (PTW): Random (and mostly legal) multi-level page table
  entries are generated. Resulting virtual addresses are driven on the request
  side and the response is compared to the golden model (generated during the
  randomization step). All ports are randomly delayed.
