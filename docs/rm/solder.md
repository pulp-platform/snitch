# Solder

Solder generates (complex) interconnects, their respective address maps, and SystemVerilog description from a simple, imperative Python description. The user specifies the topology and high-level address map of the system using Solder's API. Solder will take of generating the underlying graph representations, propagating address maps, calculating routes and performing various sanity checks. Finally, the hardware description is generated.

## Graph Representations

Under the hood Solder maintains several different graph representations:

**Hardware instance graph**
: This representation contains all hardware blocks which need to be instantiated. This includes crossbars, converter modules and peripherals.

**Address Map Graph**
: Provides an abstract view of the memory map. Components which do not change the topology (router nodes) or routing decisions (filters and leafs) are stripped from the representation.

