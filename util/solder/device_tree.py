# Copyright 2020 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Florian Zaruba <zarubaf@iis.ee.ethz.ch>

# Utility function to generate a device tree based on Solder AddressMap.


class DeviceTree(object):
    def __init__(self):
        self.cpus = list()
        self.mem = ""
        self.chosen = list()
        self.devices = list()

    def license(self):
        """Print license"""
        license = """
        // Copyright 2021 ETH Zurich and University of Bologna.
        // Licensed under the Apache License, Version 2.0, see LICENSE for details.
        // SPDX-License-Identifier: Apache-2.0
        """
        license = license.split("\n")
        return "\n".join([lic.strip() for lic in license[1:]])

    def get_reg(self, am):
        """Get a 'reg' device tree entry"""
        return "reg = <{:#x} {:#x} {:#x} {:#x}>;\n".format(
            (am.bases[0] >> 32), (am.bases[0] & (2**32 - 1)), (am.size >> 32),
            (am.size & (2**32 - 1)))

    def add_cpu(self,
                compatible,
                isa="rv64fimafd",
                mmu="sv39",
                status="okay",
                clock_freq=50000000):
        """Add a CPU node"""
        cpu = "      device_type = \"cpu\";\n"
        cpu += "      status = \"{}\";\n".format(status)
        cpu += "      compatible = \"{}\", \"riscv\";\n".format(compatible)
        cpu += "      clock-frequency = <{}>;\n".format(clock_freq)
        cpu += "      riscv,isa = \"{}\";\n".format(isa)
        cpu += "      mmu-type = \"riscv,{}\";\n".format(mmu)
        cpu += "      tlb-split;\n"
        self.cpus.append(cpu)

    def add_device(self, name, compatible, am, props=[], phandle=None):
        """Add a generic device, can have any number of additional properties"""
        if phandle:
            phandle += ": "
        name = "{}@{:x}".format(name, am.bases[0])
        dev = ""
        dev += "    {}{} {{\n".format(phandle or "", name)
        dev += "      compatible = \"{}\";\n".format(compatible)
        for prop in props:
            dev += "      {};\n".format(prop)
        dev += "      {}".format(self.get_reg(am))
        dev += "    };\n"
        self.devices.append(dev)
        return "/soc/{}".format(name)

    def add_clint(self, hartids, am):
        """Add a RISC-V Core Local Interrupt Controller"""
        interrupt_sources = " ".join([
            "&CPU{0}_intc 3 &CPU{0}_intc 7".format(hartid)
            for hartid in hartids
        ])
        return self.add_device("clint", "riscv,clint0", am, [
            "interrupts-extended = <{}>".format(interrupt_sources),
            "reg-names = \"control\""
        ])

    def add_plic(self, hartids, am):
        """Add a RISC-V Platform Level Interrupt Controller"""
        interrupt_sources = " ".join([
            "&CPU{0}_intc 11 &CPU{0}_intc 9".format(hartid)
            for hartid in hartids
        ])
        return self.add_device("interrupt-controller", "riscv,plic0", am, [
            "#address-cells = <0>", "#interrupt-cells = <1>",
            "interrupt-controller",
            "interrupts-extended = <{}>".format(interrupt_sources),
            "riscv,max-priority = <7>", "riscv,ndev = <30>"
        ], "PLIC0")

    # Main memory node.
    def add_memory(self, am):
        """Add a main memory node."""
        self.mem += "  memory@{:x} {{\n".format(am.bases[0])
        self.mem += "    device_type = \"memory\";\n"
        self.mem += "    {}".format(self.get_reg(am))
        self.mem += "  };\n"

    def addr_cells(self, ident=2, address=2, size=2):
        "Add address cell properties"
        addr_cell = "{}#address-cells = <{}>;\n".format(ident * " ", address)
        addr_cell += "{}#size-cells = <{}>;\n".format(ident * " ", size)
        return addr_cell

    def add_chosen(self, choice):
        """Add choice to chosen"""
        self.chosen.append(choice)

    def emit(self):
        """Emit the device tree."""
        dts = self.license()
        dts += "\n"
        dts += "// Auto-generated, please edit script instead.\n"
        dts += "/dts-v1/;\n"
        dts += "/ {\n"
        dts += self.addr_cells()
        dts += "  chosen {\n"
        for choice in self.chosen:
            dts += "    {}\n".format(choice)
        dts += "  };\n"
        dts += self.mem
        dts += "  cpus {\n"
        dts += self.addr_cells(ident=4, address=1, size=0)
        dts += "    timebase-frequency = <25000000>;\n"
        for i, cpu in enumerate(self.cpus):
            dts += "    CPU{0}: cpu@{0} {{\n".format(i)
            dts += cpu
            dts += "      reg = <0>;\n"
            # Add an interrupt controller if necessary
            dts += "      CPU{}_intc: interrupt-controller {{\n".format(i)
            dts += "        #interrupt-cells = <1>;\n"
            dts += "        interrupt-controller;\n"
            dts += "        compatible = \"riscv,cpu-intc\";\n"
            dts += "      };\n"
            dts += "    };\n"
        dts += "  };\n"
        dts += "  soc: soc {\n"
        dts += self.addr_cells(4)
        dts += "    compatible = \"simple-bus\";\n"
        dts += "    ranges;\n"
        for device in self.devices:
            dts += device
        dts += "  };\n"
        dts += "};\n"
        return dts
