# Interrupts and Synchronization

## Interrupts

### Software and Timer Interrupts
The system-level CLINT implements machine-level **timer** and **software-generated** interrupts, in compliance with the RISC-V priviliged specification. It is described in detail in the `system_clint` section.

### Cluster Interrupts
Additionally, each Snitch cluster provides a Cluster-Local CLINT (CL-CLINT) to efficiently raise inter-processor interrupts within each cluster. These **cluster interrupts** are implemented as a custom machine-level interrupt source, using the reserved register bits indicated by the RISC-V priviliged specification.

The CL-CLINT is a Snitch cluster peripheral and is exposed by the `CL_CLINT_SET` and `CL_CLINT_CLEAR` registers. As the names imply, these registers can be used to (atomically) set and clear the cluster-interrupt pending bits within the cluster.


## Synchronization

Synchronization among harts in Occamy can be implemented purely in software by exploiting either of two underlying hardware mechanisms:

* **Inter-processor interrupts (IPIs)**
* **Atomics**

Several convenience functions are provided in the `CVA6Runtime` and `SnRuntime` which make use of these features under the hood, e.g. to implement mutex or barrier primitives.

#### Cluster hardware barrier unit

In addition to the software-based synchronization methods, every Snitch cluster provides a hardware barrier unit to efficiently synchronize the cores in a cluster. The hardware barrier unit is a Snitch cluster peripheral and is mapped to the `HW_BARRIER` register.

To synchronize the cores, each core issues a load instruction to the `HW_BARRIER` register. The register load is blocking, i.e. it stalls the core, until all cores have arrived at the barrier, i.e. have issued the load instruction. Barrier departure occurs as a result of receiving a return value from the load instruction, thus retiring the load instruction.
