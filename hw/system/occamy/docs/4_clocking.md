# Clocking and Reset Strategy

## General
In Occamy we have four high-level reset and clocking domains, three of them are open-source:

* **SoC:** first wake-up domain, contains CVA6, narrow and wide SPM, all peripherals
* **6x Group domains:** Each Group can be kept individually in reset, being clock gated and isolated from the global interconnects
* **Die-to-die Serial Links:** Each serial link (Narrow and Wide) can be kept individually in reset, being clock gated and isolated from the global interconnects

## Reset Strategy
In the following we describe the reset strategy to assert and de-assert various clock/reset domains.

### Global Async Reset – SoC Domain

The global reset is asynchronous and is assumed to be asserted for multiple cycles while the FLL’s or bypassed clocks are slow.
This should ensure that any FF (async or sync resetable) is reseted and put into an known state.
Most likely the clocks need to be disable to de-assert the global reset to ensure the reset de-assertion has propagated to each register before we re-enable the reset.

### Group Domains
The Group domains is not reset with the global reset, but contains three control registers to control the isolation from the AXI interconnect, the clock gating and the reset.
The global reset ensures that the each Group domain is:

- AXI isolated and stays AXI isolated
- Clock gated
- Reset is de-asserted to avoid large current spikes

CVA6 is the reset controller and can wake up the domain with the following sequence:

1. Assert reset (synchronous)
2. De-assert reset (synchronous)
3. Enable clock
4. De-isolate

### Die-to-Die Serial Link Domains
The Die2Die domains is not reset with the global reset, but contains three control registers to control the isolation from the AXI interconnect, the clock gating and the reset.
The global reset ensures that the each Die2Die domain is:

- AXI isolated and stays AXI isolated
- Clock gated
- Reset is de-asserted to avoid large current spikes

CVA6 is the reset controller and can wake up the domain with the following sequence:

1. Assert reset (synchronous)
2. De-assert reset (synchronous)
3. Enable clock
4. De-isolate

## Clocking Strategy

We have three main clock domains, two of them are open-source. Each of which is driven by the output clock of an FLL instance on the taped-out system. The (open-source) clock domains are listed in the following table:

| Clock domain                                 | Nominal Frequency [GHz] |
| -------------------------------------------- | ----------------------- |
| System (CVA6, Cluster, Groups, Serial Links) |                       1 |
| Peripheral                                   |                     0.3 |
