# Copyright 2020 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Fabian Schuiki <fschuiki@iis.ee.ethz.ch>
# Florian Zaruba <zarubaf@iis.ee.ethz.ch>

import math
import pathlib
import logging

from copy import copy
from mako.lookup import TemplateLookup
from . import util

templates = TemplateLookup(directories=[pathlib.Path(__file__).parent],
                           output_encoding="utf-8")

xbars = list()
code_package = ""
code_module = dict()


# An address map.
class AddrMap(object):
    def __init__(self):
        self.entries = list()
        self.leaves = list()
        self.nodes = list()
        pass

    def new_leaf(self, *args, **kwargs):
        x = AddrMapLeaf(*args, **kwargs)
        self.add_leaf(x)
        return x

    def new_node(self, *args, **kwargs):
        x = AddrMapNode(*args, **kwargs)
        self.add_node(x)
        return x

    def add_leaf(self, leaf):
        self.entries.append(leaf)
        self.leaves.append(leaf)

    def add_node(self, node):
        self.entries.append(node)
        self.nodes.append(node)

    def print_cheader(self):
        out = "#pragma once\n\n"
        for entry in self.entries:
            if not isinstance(entry, AddrMapLeaf):
                continue
            out += entry.print_cheader()
        return out

    def render_graphviz(self):
        out = "digraph {\n"
        # out += "    rankdir = LR;\n"
        out += "    edge [fontname=\"monospace\", fontsize=10];\n"
        out += "    node [fontname=\"monospace\"];\n"
        for entry in self.entries:
            out += entry.render_graphviz()
        out += "}\n"
        return out


class AddrMapEntry(object):
    next_id = 0

    def __init__(self, name):
        self.name = name
        self.id = AddrMapEntry.next_id
        AddrMapEntry.next_id += 1

    def attach_to(self, *nodes):
        for node in nodes:
            node.attach(self)
        return self

    def get_ranges(self, origin):
        return self.get_ranges_inner({origin})

    def get_ranges_inner(self, seen):
        return []


# A leaf node in the address map.
class AddrMapLeaf(AddrMapEntry):
    def __init__(self, name, size, *bases):
        super().__init__(name)
        self.size = size
        self.bases = bases

    def get_ranges_inner(self, seen):
        return [
            AddrMapRoute(base, base + self.size, target=self)
            for base in self.bases
        ]

    def print_cheader(self):
        out = ""
        for i, base in enumerate(self.bases):
            idx = i if len(self.bases) > 1 else ""
            out += "#define {}{}_BASE_ADDR 0x{:08x}\n".format(
                self.name.upper(), idx, base)
        return out

    def render_graphviz(self):
        label = self.name
        label += "<font point-size=\"10\">"
        for base in self.bases:
            label += "<br/>[{:08x}, {:08x}]".format(base, base + self.size - 1)
        label += "</font>"
        return "    N{ptr} [shape=rectangle, label=<{label}>];\n".format(
            ptr=self.id, label=label)


# An interconnect node in the address map.
class AddrMapNode(AddrMapEntry):
    def __init__(self, name):
        super().__init__(name)
        self.entries = list()
        self.invalidate_routes()

    def attach(self, *entries):
        for entry in entries:
            self.entries.append(entry)
        self.invalidate_routes()
        return self

    def get_ranges_inner(self, seen):
        # pfx = " - " * len(seen)

        # Break recursions that occur when crossbars are cross-connected.
        if self in seen:
            # print(pfx + "`{}`: Breaking recursion".format(self.name))
            return []
        # print(pfx + "`{}`: Looking up nodes in xbar".format(self.name))

        # Gather the address ranges of all attached child nodes.
        r = list()
        seen.add(self)
        for entry in self.entries:
            # print(pfx + "`{}`: - Entering `{}`".format(self.name, entry.name))
            r += [route.inc_depth() for route in entry.get_ranges_inner(seen)]
            # print(pfx + "`{}`: - Leaving `{}`".format(self.name, entry.name))
        seen.remove(self)

        # print(pfx + "`{}`: Finalized address ranges:".format(self.name))
        # for lo, hi, entry, depth in r:
        # 	print(pfx + "`{}`: - [0x{:08x}, 0x{:08x}]: `{}` @ {}"
        #               .format(self.name, lo, hi, entry.name, depth))
        return r

    def invalidate_routes(self):
        self.routes = None

    def get_routes(self):
        if self.routes is not None:
            return self.routes

        # Collect all routes for this node.
        routes = list()
        for port in self.entries:
            routes += (route.with_port(port)
                       for route in port.get_ranges(self))

        # Sort the routes by lower address to allow for easier processing later.
        routes.sort(key=lambda a: a.lo)
        logging.info("Routes for `{}`:".format(self.name))
        for route in routes:
            logging.info("  - {}".format(route))

        # Simplify the address map by replacing redundant paths to the same
        # desintation with the port that takes the least number of hops. Also
        # check for address map collisions at this point.
        done = list()
        done.append(routes[0])
        for route in routes[1:]:
            last = done[-1]

            # Check if the routse have an identical address mapping and target,
            # in which case we pick the shortest route.
            if last.lo == route.lo and last.hi == route.hi and last.target == route.target:
                logging.info("Collapsing redundant routes to `{}`".format(
                    route.target.name))
                if last.depth > route.depth:
                    done[-1] = route
                continue

            # Check if the rules overlap.
            if last.lo < route.hi and route.lo < last.hi:
                msg = "Address collision in `{}` between the following routes:\n".format(
                    self.name)
                msg += "  - {}\n".format(last)
                msg += "  - {}".format(route)
                raise Exception(msg)

            # Just keep this rule.
            done.append(route)

        logging.info("Simplified routes for `{}`:".format(self.name))
        for route in done:
            logging.info("  - {}".format(route))

        # Compress the routes by collapsing adjacent address ranges that map to
        # the same port.
        compressed = list()
        compressed.append(done[0])
        for route in done[1:]:
            last = compressed[-1]

            # If the previous rule mapped to the same port, simply create a
            # union rule here. This does not create any collisions since the
            # routes are sorted by address, which means that there are no other
            # mappings in between the ports which would be "shadowed" by mapping
            # the additional gap between the two rules.
            if last.port == route.port:
                compressed[-1] = last.unified_with(route)
                continue

            # Just keep this rule.
            compressed.append(route)

        logging.info("Compressed routes for `{}`:".format(self.name))
        for route in compressed:
            logging.info("  - {}".format(route))

        self.routes = compressed
        return compressed

    def render_graphviz(self):
        out = "    N{ptr} [label=\"{name}\"];\n".format(ptr=self.id,
                                                        name=self.name)
        for route in self.get_routes():
            if isinstance(route.port, AddrMapLeaf):
                label = ""
            else:
                label = "{:08x}\\n{:08x}".format(route.lo, route.hi - 1)
            out += "    N{ptr} -> N{to} [label=\"{label}\"];\n".format(
                ptr=self.id, to=route.port.id, label=label)
        return out


# A route within an address map node.
class AddrMapRoute(object):
    def __init__(self, lo, hi, port=None, target=None, depth=0):
        self.lo = lo
        self.hi = hi
        self.port = port
        self.target = target
        self.depth = depth

    def __str__(self):
        out = "[0x{:08x}, 0x{:08x}]".format(self.lo, self.hi)
        if self.port is not None:
            out += " via `{}`".format(self.port.name)
        if self.target is not None:
            ts = self.target if isinstance(self.target,
                                           list) else [self.target]
            out += " -> {}".format(", ".join(
                ["`{}`".format(x.name) for x in ts]))
        out += " @ {}".format(self.depth)
        return out

    def inc_depth(self):
        x = copy(self)
        x.depth += 1
        return x

    def with_port(self, port):
        x = copy(self)
        x.port = port
        return x

    # Create a new route which unifies two other routes.
    def unified_with(self, other):
        assert (self.port == other.port)
        x = copy(self)
        t1 = self.target if isinstance(self.target, list) else [self.target]
        t2 = other.target if isinstance(other.target, list) else [other.target]
        x.lo = min(self.lo, other.lo)
        x.hi = max(self.hi, other.hi)
        x.target = t1 + t2
        x.depth = 0
        return x


# An address range.
class AddrRange(object):
    def __init__(self, lo, hi):
        self.lo = lo
        self.hi = hi


# A parameter.
class Param(object):
    def __init__(self):
        pass


# AXI struct emission.
class AxiStruct:
    configs = dict()

    def emit(aw, dw, iw, uw):
        global code_package
        key = (aw, dw, iw, uw)
        if key in AxiStruct.configs:
            return AxiStruct.configs[key]
        name = "axi_a{}_d{}_i{}_u{}".format(*key)
        code = "// AXI bus with {} bit address, {} bit data, {} bit IDs, and {} bit user data.\n".format(
            *key)
        code += "`AXI_TYPEDEF_ALL({}, logic [{}:0], logic [{}:0], logic [{}:0], logic [{}:0], logic [{}:0])\n".format(
            name, aw - 1, iw - 1, dw - 1, (dw + 7) // 8 - 1, max(0, uw - 1))
        code_package += "\n" + code
        AxiStruct.configs[key] = name
        return name


# AXI-Lite struct emission.
class AxiLiteStruct:
    configs = dict()

    def emit(aw, dw):
        global code_package
        key = (aw, dw)
        if key in AxiLiteStruct.configs:
            return AxiLiteStruct.configs[key]
        name = "axi_lite_a{}_d{}".format(*key)
        code = "// AXI-Lite bus with {} bit address and {} bit data.\n".format(
            *key)
        code += "`AXI_LITE_TYPEDEF_ALL({}, logic [{}:0], logic [{}:0], logic [{}:0])\n".format(
            name, aw - 1, dw - 1, (dw + 7) // 8 - 1)
        code_package += "\n" + code
        AxiLiteStruct.configs[key] = name
        return name


# Register bus struct emission
class RegStruct:
    configs = dict()

    def emit(aw, dw):
        global code_package
        key = (aw, dw)
        if key in RegStruct.configs:
            return RegStruct.configs[key]
        name = "reg_a{}_d{}".format(*key)
        code = "// Register bus with {} bit address and {} bit data.\n".format(
            *key)
        code += "`REG_BUS_TYPEDEF_ALL({}, logic [{}:0], logic [{}:0], logic [{}:0])\n".format(
            name, aw - 1, dw - 1, (dw + 7) // 8 - 1)
        code_package += "\n" + code
        RegStruct.configs[key] = name
        return name


# An AXI bus.
class AxiBus(object):
    def __init__(self,
                 clk,
                 rst,
                 aw,
                 dw,
                 iw,
                 uw,
                 name,
                 name_suffix=None,
                 type_prefix=None,
                 declared=False):
        self.clk = clk
        self.rst = rst
        self.aw = aw
        self.dw = dw
        self.iw = iw
        self.uw = uw
        self.type_prefix = type_prefix or self.emit_struct()
        self.name = name
        self.name_suffix = name_suffix
        self.declared = declared

    def copy(self, name=None):
        return AxiBus(self.clk,
                      self.rst,
                      self.aw,
                      self.dw,
                      self.iw,
                      self.uw,
                      name or self.name,
                      declared=False)

    def emit_struct(self):
        return AxiStruct.emit(self.aw, self.dw, self.iw, self.uw)

    def emit_flat_master_port(self, name=None):
        tpl = templates.get_template("solder.axi_flatten_port.sv.tpl")
        return tpl.render_unicode(
                mst_dir="output",
                slv_dir="input",
                prefix="m_axi_{}".format(name or ""),
                bus=self
            )

    def emit_flat_slave_port(self, name=None):
        tpl = templates.get_template("solder.axi_flatten_port.sv.tpl")
        return tpl.render_unicode(
                mst_dir="input",
                slv_dir="output",
                prefix="s_axi_{}".format(name or ""),
                bus=self
            )

    def declare(self, context):
        if self.declared:
            return
        context.write("  {} {};\n".format(self.req_type(), self.req_name()))
        context.write("  {} {};\n\n".format(self.rsp_type(), self.rsp_name()))
        self.declared = True
        return self

    def req_name(self):
        return "{}_req{}".format(self.name, self.name_suffix or "")

    def rsp_name(self):
        return "{}_rsp{}".format(self.name, self.name_suffix or "")

    def req_type(self):
        return "{}_req_t".format(self.type_prefix)

    def rsp_type(self):
        return "{}_resp_t".format(self.type_prefix)

    def addr_type(self):
        return "logic [{}:0]".format(self.aw - 1)

    def id_type(self):
        return "logic [{}:0]".format(self.iw - 1)

    def data_type(self):
        return "logic [{}:0]".format(self.dw - 1)

    def strb_type(self):
        return "logic [{}:0]".format((self.dw + 7) // 8 - 1)

    def user_type(self):
        return "logic [{}:0]".format(max(0, self.uw - 1))

    def change_iw(self, context, target_iw, name, inst_name=None, to=None):
        if self.iw == target_iw:
            return self

        # Generate the new bus.
        if to is None:
            bus = copy(self)
            bus.declared = False
            bus.iw = target_iw
            bus.type_prefix = bus.emit_struct()
            bus.name = name
            bus.name_suffix = None
        else:
            bus = to

        # Check bus properties.
        assert (bus.clk == self.clk)
        assert (bus.rst == self.rst)
        assert (bus.aw == self.aw)
        assert (bus.dw == self.dw)
        assert (bus.iw == target_iw)
        assert (bus.uw == self.uw)

        # Emit the remapper instance.
        bus.declare(context)
        tpl = templates.get_template("solder.axi_change_iw.sv.tpl")
        context.write(
            tpl.render_unicode(
                axi_in=self,
                axi_out=bus,
                name=inst_name or "i_{}".format(name),
            ) + "\n")
        return bus

    def change_dw(self, context, target_dw, name, inst_name=None, to=None):
        if self.dw == target_dw:
            return self

        # Generate the new bus.
        if to is None:
            bus = copy(self)
            bus.declared = False
            bus.dw = target_dw
            bus.type_prefix = bus.emit_struct()
            bus.name = name
            bus.name_suffix = None
        else:
            bus = to

        # Check bus properties.
        assert (bus.clk == self.clk)
        assert (bus.rst == self.rst)
        assert (bus.aw == self.aw)
        assert (bus.dw == target_dw)
        assert (bus.iw == self.iw)
        assert (bus.uw == self.uw)

        # Emit the remapper instance.
        bus.declare(context)
        tpl = templates.get_template("solder.axi_change_dw.sv.tpl")
        context.write(
            tpl.render_unicode(
                axi_in=self,
                axi_out=bus,
                name=inst_name or "i_{}".format(name),
            ) + "\n")
        return bus

    def cut(self, context, nr_cuts=1, name=None, inst_name=None, to=None):
        if nr_cuts == 0:
            return self

        name = name or "{}_cut".format(self.name)

        # Generate the new bus.
        if to is None:
            bus = copy(self)
            bus.declared = False
            bus.type_prefix = bus.emit_struct()
            bus.name = name
            bus.name_suffix = None
        else:
            bus = to

        assert (bus.clk == self.clk)
        assert (bus.rst == self.rst)
        assert (bus.aw == self.aw)
        assert (bus.dw == self.dw)
        assert (bus.iw == self.iw)
        assert (bus.uw == self.uw)

        # Emit the cut instance.
        bus.declare(context)
        tpl = templates.get_template("solder.axi_multicut.sv.tpl")
        context.write(
            tpl.render_unicode(
                bus_in=self,
                bus_out=bus,
                nr_cuts=nr_cuts,
                name=inst_name or "i_{}".format(name),
            ) + "\n")
        return bus

    def cdc(self,
            context,
            target_clk,
            target_rst,
            name,
            inst_name=None,
            to=None,
            log_depth=2):
        if self.clk == target_clk and self.rst == target_rst:
            return self

        # Generate the new bus.
        if to is None:
            bus = copy(self)
            bus.declared = False
            bus.clk = target_clk
            bus.rst = target_rst
            bus.type_prefix = bus.emit_struct()
            bus.name = name
            bus.name_suffix = None
        else:
            bus = to

        # Check bus properties.
        assert (bus.clk == target_clk)
        assert (bus.rst == target_rst)
        assert (bus.aw == self.aw)
        assert (bus.dw == self.dw)
        assert (bus.iw == self.iw)
        assert (bus.uw == self.uw)

        # Emit the CDC instance.
        bus.declare(context)
        tpl = templates.get_template("solder.axi_cdc.sv.tpl")
        context.write(
            tpl.render_unicode(
                bus_in=self,
                bus_out=bus,
                name=inst_name or "i_{}".format(name),
                log_depth=log_depth,
            ) + "\n")
        return bus

    def isolate(self,
                context,
                isolate,
                name,
                inst_name=None,
                to=None,
                num_pending=128,
                isolated=None):

        # Generate the new bus.
        if to is None:
            bus = copy(self)
            bus.declared = False
            bus.dw = self.dw
            bus.type_prefix = bus.emit_struct()
            bus.name = name
            bus.name_suffix = None
        else:
            bus = to

        # Check bus properties.
        assert (bus.clk == self.clk)
        assert (bus.rst == self.rst)
        assert (bus.aw == self.aw)
        assert (bus.dw == self.dw)
        assert (bus.iw == self.iw)
        assert (bus.uw == self.uw)

        # Emit the remapper instance.
        bus.declare(context)
        tpl = templates.get_template("solder.axi_isolate.sv.tpl")
        context.write(
            tpl.render_unicode(axi_in=self,
                               axi_out=bus,
                               name=inst_name or "i_{}".format(name),
                               isolate=isolate,
                               isolated=isolated or "",
                               num_pending=num_pending) + "\n")
        return bus

    def to_axi_lite(self, context, name, inst_name=None, to=None):
        # Generate the new bus.
        if to is None:
            bus = AxiLiteBus(self.clk, self.rst, self.aw, self.dw, name)
            bus.name_suffix = None
        else:
            bus = to

        # Check bus properties.
        assert (bus.clk == self.clk)
        assert (bus.rst == self.rst)
        assert (bus.aw == self.aw)
        assert (bus.dw == self.dw)

        # Emit the remapper instance.
        bus.declare(context)
        tpl = templates.get_template("solder.axi_to_axi_lite.sv.tpl")
        context.write(
            tpl.render_unicode(
                bus_in=self,
                bus_out=bus,
                name=inst_name or "i_{}_pc".format(name),
            ) + "\n")
        return bus

    def add_const_cache(self,
                        context,
                        name,
                        line_width,
                        line_count,
                        set_count,
                        flush_valid=None,
                        flush_ready=None,
                        start_addr=None,
                        end_addr=None,
                        inst_name=None,
                        to=None):
        # Generate the new bus.
        if to is None:
            bus = copy(self)
            bus.declared = False
            bus.iw = self.iw + 1
            bus.type_prefix = bus.emit_struct()
            bus.name = name
            bus.name_suffix = None
        else:
            bus = to

        # Check bus properties.
        assert (bus.clk == self.clk)
        assert (bus.rst == self.rst)
        assert (bus.aw == self.aw)
        assert (bus.dw == self.dw)
        assert (bus.iw == self.iw + 1)
        assert (bus.uw == self.uw)

        # Emit the remapper instance.
        bus.declare(context)
        tpl = templates.get_template("solder.snitch_const_cache.sv.tpl")
        context.write(
            tpl.render_unicode(
                axi_in=self,
                axi_out=bus,
                line_width=line_width,
                line_count=line_count,
                set_count=set_count,
                flush_valid=flush_valid or "1'b0",
                flush_ready=flush_ready or "",
                start_addr=start_addr or "'0",
                end_addr=end_addr or "'1",
                name=inst_name or "i_{}".format(name),
            ) + "\n")
        return bus


# An AXI-Lite bus.
class AxiLiteBus(object):
    def __init__(self,
                 clk,
                 rst,
                 aw,
                 dw,
                 name,
                 name_suffix=None,
                 type_prefix=None,
                 declared=False):
        self.clk = clk
        self.rst = rst
        self.aw = aw
        self.dw = dw
        self.type_prefix = type_prefix or self.emit_struct()
        self.name = name
        self.name_suffix = name_suffix
        self.declared = declared

    def emit_struct(self):
        return AxiLiteStruct.emit(self.aw, self.dw)

    def declare(self, context):
        if self.declared:
            return
        context.write("  {} {};\n".format(self.req_type(), self.req_name()))
        context.write("  {} {};\n\n".format(self.rsp_type(), self.rsp_name()))
        self.declared = True
        return self

    def req_name(self):
        return "{}_req{}".format(self.name, self.name_suffix or "")

    def rsp_name(self):
        return "{}_rsp{}".format(self.name, self.name_suffix or "")

    def req_type(self):
        return "{}_req_t".format(self.type_prefix)

    def rsp_type(self):
        return "{}_rsp_t".format(self.type_prefix)

    def cdc(self,
            context,
            target_clk,
            target_rst,
            name,
            inst_name=None,
            to=None,
            log_depth=2):
        if self.clk == target_clk and self.rst == target_rst:
            return self

        # Generate the new bus.
        if to is None:
            bus = copy(self)
            bus.declared = False
            bus.clk = target_clk
            bus.rst = target_rst
            bus.type_prefix = bus.emit_struct()
            bus.name = name
            bus.name_suffix = None
        else:
            bus = to

        # Check bus properties.
        assert (bus.clk == target_clk)
        assert (bus.rst == target_rst)
        assert (bus.aw == self.aw)
        assert (bus.dw == self.dw)

        # Emit the CDC instance.
        bus.declare(context)
        tpl = templates.get_template("solder.axi_cdc.sv.tpl")
        context.write(
            tpl.render_unicode(
                bus_in=self,
                bus_out=bus,
                name=inst_name or "i_{}".format(name),
                log_depth=log_depth,
            ) + "\n")
        return bus

    def to_axi(self, context, name, iw=0, uw=0, inst_name=None, to=None):
        # Generate the new bus.
        if to is None:
            bus = AxiBus(self.aw, self.dw, iw, uw)
            bus.name = name
            bus.name_suffix = None
        else:
            bus = to

        # Check bus properties.
        assert (bus.clk == self.clk)
        assert (bus.rst == self.rst)
        assert (bus.aw == self.aw)
        assert (bus.dw == self.dw)

        # Emit the remapper instance.
        bus.declare(context)
        tpl = templates.get_template("solder.axi_lite_to_axi.sv.tpl")
        context.write(
            tpl.render_unicode(
                bus_in=self,
                bus_out=bus,
                name=inst_name or "i_{}_pc".format(name),
            ) + "\n")
        return bus

    def to_reg(self, context, name, inst_name=None, to=None):
        # Generate the new bus.
        if to is None:
            bus = RegBus(self.clk, self.rst, self.aw, self.dw, name=name)
        else:
            bus = to

        # Check bus properties.
        assert (bus.clk == self.clk)
        assert (bus.rst == self.rst)
        assert (bus.aw == self.aw)
        assert (bus.dw == self.dw)

        # Emit the converter instance.
        bus.declare(context)
        tpl = templates.get_template("solder.axi_lite_to_reg.sv.tpl")
        context.write(
            tpl.render_unicode(
                bus_in=self,
                bus_out=bus,
                name=inst_name or "i_{}_pc".format(name),
            ) + "\n")
        return bus


# A register bus.
class RegBus(object):
    def __init__(self,
                 clk,
                 rst,
                 aw,
                 dw,
                 name,
                 name_suffix=None,
                 type_prefix=None,
                 declared=False):
        self.clk = clk
        self.rst = rst
        self.aw = aw
        self.dw = dw
        self.type_prefix = type_prefix or self.emit_struct()
        self.name = name
        self.name_suffix = name_suffix
        self.declared = declared

    def emit_struct(self):
        return RegStruct.emit(self.aw, self.dw)

    def declare(self, context):
        if self.declared:
            return
        context.write("  {} {};\n".format(self.req_type(), self.req_name()))
        context.write("  {} {};\n\n".format(self.rsp_type(), self.rsp_name()))
        self.declared = True
        return self

    def req_name(self):
        return "{}_req{}".format(self.name, self.name_suffix or "")

    def rsp_name(self):
        return "{}_rsp{}".format(self.name, self.name_suffix or "")

    def req_type(self):
        return "{}_req_t".format(self.type_prefix)

    def rsp_type(self):
        return "{}_rsp_t".format(self.type_prefix)

    def addr_type(self):
        return "logic [{}:0]".format(self.aw - 1)

    def data_type(self):
        return "logic [{}:0]".format(self.dw - 1)

    def strb_type(self):
        return "logic [{}:0]".format((self.dw + 7) // 8 - 1)

    def to_axi_lite(self, context, name, inst_name=None, to=None):
        # Generate the new bus.
        if to is None:
            bus = AxiLiteBus(self.clk, self.rst, self.aw, self.dw, name=name)
        else:
            bus = to

        # Check bus properties.
        assert (bus.clk == self.clk)
        assert (bus.rst == self.rst)
        assert (bus.aw == self.aw)
        assert (bus.dw == self.dw)

        # Emit the converter instance.
        bus.declare(context)
        tpl = templates.get_template("solder.reg_to_axi_lite.sv.tpl")
        context.write(
            tpl.render_unicode(
                bus_in=self,
                bus_out=bus,
                name=inst_name or "i_{}_pc".format(name),
            ) + "\n")
        return bus


# A crossbar.
class Xbar(object):
    count = 0

    def __init__(self,
                 name=None,
                 clk="clk_i",
                 rst="rst_ni",
                 node=None,
                 context="default"):
        self.emitted = False
        self.inputs = list()
        self.outputs = list()
        self.clk = clk
        self.rst = rst
        self.name = name or "xbar_{}".format(self.count)
        self.count += 1
        self.node = node
        self.context = context
        xbars.append(self)


# An AXI crossbar.
class AxiXbar(Xbar):
    configs = dict()

    def __init__(self, aw, dw, iw, uw=0, no_loopback=False, **kwargs):
        super().__init__(**kwargs)
        self.aw = aw
        self.dw = dw
        self.iw = iw
        self.uw = uw
        self.no_loopback = no_loopback
        self.symbolic_addrmap = list()
        self.addrmap = list()

    def add_input(self, name):
        self.inputs.append(name)

    def add_output(self, name, addrs, default=False):
        idx = len(self.outputs)
        for lo, hi in addrs:
            if hi >> self.aw == 1:
                hi -= 1
            self.addrmap.append((idx, lo, hi))
        self.outputs.append(name)

    def add_output_symbolic(self, name, base, length):
        idx = len(self.outputs)
        self.symbolic_addrmap.append((idx, base, length))
        self.outputs.append(name)

    def add_output_entry(self, name, entry):
        self.add_output(name,
                        [(r.lo, r.hi)
                         for r in self.node.get_routes() if r.port == entry])

    def addr_map_len(self):
        return len(self.addrmap) + len(self.symbolic_addrmap)

    def emit(self):
        global code_module
        global code_package
        if self.emitted:
            return
        self.emitted = True
        code_module.setdefault(self.context, "")
        # Compute the ID widths.
        iw_in = self.iw
        iw_out = self.iw + int(math.ceil(math.log2(max(1, len(self.inputs)))))

        # Emit the input enum into the package.
        input_enum_name = "{}_inputs_e".format(self.name)
        input_enum = "/// Inputs of the `{}` crossbar.\n".format(self.name)
        input_enum += "typedef enum int {\n"
        input_enums = list()
        for name in self.inputs:
            x = "{}_in_{}".format(self.name, name).upper()
            input_enums.append(x)
            input_enum += "  {},\n".format(x)
        input_enum += "  {}_NUM_INPUTS\n".format(self.name.upper())
        input_enum += "}} {};\n".format(input_enum_name)
        code_package += "\n" + input_enum

        # Emit the output enum into the package.
        output_enum_name = "{}_outputs_e".format(self.name)
        output_enum = "/// Outputs of the `{}` crossbar.\n".format(self.name)
        output_enum += "typedef enum int {\n"
        output_enums = list()
        for name in self.outputs:
            x = "{}_out_{}".format(self.name, name).upper()
            output_enums.append(x)
            output_enum += "  {},\n".format(x)
        output_enum += "  {}_NUM_OUTPUTS\n".format(self.name.upper())
        output_enum += "}} {};\n".format(output_enum_name)
        code_package += "\n" + output_enum

        # Emit the configuration struct into the package.
        self.cfg_name = util.pascalize("{}_cfg".format(self.name))
        cfg = "/// Configuration of the `{}` crossbar.\n".format(self.name)
        cfg += "localparam axi_pkg::xbar_cfg_t {} = '{{\n".format(
            self.cfg_name)
        cfg += "  NoSlvPorts:         {}_NUM_INPUTS,\n".format(
            self.name.upper())
        cfg += "  NoMstPorts:         {}_NUM_OUTPUTS,\n".format(
            self.name.upper())
        cfg += "  MaxSlvTrans:        4,\n"
        cfg += "  MaxMstTrans:        4,\n"
        cfg += "  FallThrough:        0,\n"
        cfg += "  LatencyMode:        axi_pkg::CUT_ALL_PORTS,\n"
        cfg += "  AxiIdWidthSlvPorts: {},\n".format(self.iw)
        cfg += "  AxiIdUsedSlvPorts:  {},\n".format(self.iw)
        cfg += "  AxiAddrWidth:       {},\n".format(self.aw)
        cfg += "  AxiDataWidth:       {},\n".format(self.dw)
        cfg += "  NoAddrRules:        {}\n".format(self.addr_map_len())
        cfg += "};\n"

        code_package += "\n" + cfg

        # Emit the address map into the package.
        addrmap_name = util.pascalize("{}_addrmap".format(self.name))
        addrmap = "/// Address map of the `{}` crossbar.\n".format(self.name)
        addrmap += "xbar_rule_{}_t [{}:0] {};\n".format(
            self.aw,
            self.addr_map_len() - 1, addrmap_name)
        addrmap += "assign {} = '{{\n".format(addrmap_name)
        for i in range(len(self.addrmap)):
            addrmap += "  '{{ idx: {}, start_addr: {aw}'h{:08x}, end_addr: {aw}'h{:08x} }}".format(
                *self.addrmap[i], aw=self.aw)
            if i != len(self.addrmap) - 1 or len(self.symbolic_addrmap) > 0:
                addrmap += ",\n"
            else:
                addrmap += "\n"
        for i, (idx, base, length) in enumerate(self.symbolic_addrmap):
            addrmap += "  '{{ idx: {}, start_addr: {}[{i}], end_addr: {}[{i}] + {} }}".format(
                idx, base, base, length, i=i)
            if i != len(self.symbolic_addrmap) - 1:
                addrmap += ",\n"
            else:
                addrmap += "\n"
        addrmap += "};\n"

        code_module[self.context] += "\n" + addrmap

        # Emit the AXI structs into the package.
        self.input_struct = AxiStruct.emit(self.aw, self.dw, iw_in, self.uw)
        self.output_struct = AxiStruct.emit(self.aw, self.dw, iw_out, self.uw)

        code_package += "\n"
        for tds in [
                "req", "resp", "aw_chan", "w_chan", "b_chan", "ar_chan",
                "r_chan"
        ]:
            code_package += "typedef {}_{tds}_t {}_in_{tds}_t;\n".format(
                self.input_struct, self.name, tds=tds)
            code_package += "typedef {}_{tds}_t {}_out_{tds}_t;\n".format(
                self.output_struct, self.name, tds=tds)

        # Emit the characteristics of the AXI plugs into the package.
        code_package += "\n"
        code_package += "// verilog_lint: waive parameter-name-style \n"
        code_package += "localparam int {}_IW_IN = {};\n".format(
            self.name.upper(), iw_in)
        code_package += "// verilog_lint: waive parameter-name-style \n"
        code_package += "localparam int {}_IW_OUT = {};\n".format(
            self.name.upper(), iw_out)

        # Emit the input and output signals.
        code = ""
        code += "{}_in_req_t [{}:0] {}_in_req;\n".format(
            self.name,
            len(self.inputs) - 1, self.name)
        code += "{}_in_resp_t [{}:0] {}_in_rsp;\n".format(
            self.name,
            len(self.inputs) - 1, self.name)
        code += "{}_out_req_t [{}:0] {}_out_req;\n".format(
            self.name,
            len(self.outputs) - 1, self.name)
        code += "{}_out_resp_t [{}:0] {}_out_rsp;\n".format(
            self.name,
            len(self.outputs) - 1, self.name)
        code_module[self.context] += "\n" + code

        for name, enum in zip(self.inputs, input_enums):
            bus = AxiBus(
                self.clk,
                self.rst,
                self.aw,
                self.dw,
                iw_in,
                self.uw,
                "{}_in".format(self.name),
                "[{}]".format(enum),
                type_prefix=self.input_struct,
                declared=True,
            )
            self.__dict__["in_" + name] = bus

        for name, enum in zip(self.outputs, output_enums):
            bus = AxiBus(
                self.clk,
                self.rst,
                self.aw,
                self.dw,
                iw_out,
                self.uw,
                "{}_out".format(self.name),
                "[{}]".format(enum),
                type_prefix=self.output_struct,
                declared=True,
            )
            self.__dict__["out_" + name] = bus

        # Emit the crossbar instance itself.
        code = "axi_xbar #(\n"
        code += "  .Cfg           ( {cfg_name} ),\n".format(
            cfg_name=self.cfg_name)
        code += "  .Connectivity  ( {} ), \n".format(self.connectivity())
        code += "  .slv_aw_chan_t ( {}_aw_chan_t ),\n".format(
            self.input_struct)
        code += "  .mst_aw_chan_t ( {}_aw_chan_t ),\n".format(
            self.output_struct)
        code += "  .w_chan_t      ( {}_w_chan_t ),\n".format(self.input_struct)
        code += "  .slv_b_chan_t  ( {}_b_chan_t ),\n".format(self.input_struct)
        code += "  .mst_b_chan_t  ( {}_b_chan_t ),\n".format(
            self.output_struct)
        code += "  .slv_ar_chan_t ( {}_ar_chan_t ),\n".format(
            self.input_struct)
        code += "  .mst_ar_chan_t ( {}_ar_chan_t ),\n".format(
            self.output_struct)
        code += "  .slv_r_chan_t  ( {}_r_chan_t ),\n".format(self.input_struct)
        code += "  .mst_r_chan_t  ( {}_r_chan_t ),\n".format(
            self.output_struct)
        code += "  .slv_req_t     ( {}_req_t ),\n".format(self.input_struct)
        code += "  .slv_resp_t    ( {}_resp_t ),\n".format(self.input_struct)
        code += "  .mst_req_t     ( {}_req_t ),\n".format(self.output_struct)
        code += "  .mst_resp_t    ( {}_resp_t ),\n".format(self.output_struct)
        code += "  .rule_t        ( xbar_rule_{}_t )\n".format(self.aw)
        code += ") i_{name} (\n".format(name=self.name)
        code += "  .clk_i  ( {clk} ),\n".format(clk=self.clk)
        code += "  .rst_ni ( {rst} ),\n".format(rst=self.rst)
        code += "  .test_i ( test_mode_i ),\n"
        code += "  .slv_ports_req_i  ( {name}_in_req  ),\n".format(
            name=self.name)
        code += "  .slv_ports_resp_o ( {name}_in_rsp  ),\n".format(
            name=self.name)
        code += "  .mst_ports_req_o  ( {name}_out_req ),\n".format(
            name=self.name)
        code += "  .mst_ports_resp_i ( {name}_out_rsp ),\n".format(
            name=self.name)
        code += "  .addr_map_i       ( {addrmap_name} ),\n".format(
            addrmap_name=addrmap_name)
        code += "  .en_default_mst_port_i ( '1 ),\n"
        code += "  .default_mst_port_i    ( '0 )\n"
        code += ");\n"

        code_module[self.context] += "\n" + code

    def connectivity(self):
        """Generate a connectivity matrix"""
        length = len(self.outputs) * len(self.inputs)
        connectivity = ""
        # check if port names match and disable that route
        if self.no_loopback:
            for i in self.inputs:
                for o in self.outputs:
                    if (i == o):
                        connectivity += "0"
                    else:
                        connectivity += "1"
        else:
            connectivity += "1" * length

        connectivity = "{}'b{}".format(length, connectivity[::-1])

        return connectivity


# An AXI-Lite crossbar.
class AxiLiteXbar(Xbar):
    tpl = templates.get_template("solder.axi_lite_xbar.sv.tpl")

    def __init__(self, aw, dw, **kwargs):
        super().__init__(**kwargs)
        self.aw = aw
        self.dw = dw
        self.addrmap = list()

    def add_input(self, name):
        self.inputs.append(name)

    def add_output(self, name, addrs, default=False):
        idx = len(self.outputs)
        for lo, hi in addrs:
            if hi >> self.aw == 1:
                hi -= 1
            self.addrmap.append((idx, lo, hi))
        self.outputs.append(name)

    def add_output_entry(self, name, entry):
        self.add_output(name,
                        [(r.lo, r.hi)
                         for r in self.node.get_routes() if r.port == entry])

    def emit(self):
        global code_module
        global code_package
        if self.emitted:
            return
        self.emitted = True
        code_module.setdefault(self.context, "")
        (pkg,
         mod) = self.tpl.render_unicode(xbar=self,
                                        AxiLiteBus=AxiLiteBus,
                                        AxiLiteStruct=AxiLiteStruct,
                                        util=util).split("// ----- 8< -----")
        code_package += "\n" + pkg.strip() + "\n"
        code_module[self.context] += "\n" + mod.strip() + "\n"


# Register bus "XBar" (well, not really - just one master to n slaves)
class RegBusXbar(Xbar):
    tpl = templates.get_template("solder.regbus_xbar.sv.tpl")

    def __init__(self, aw, dw, **kwargs):
        super().__init__(**kwargs)
        self.aw = aw
        self.dw = dw
        self.addrmap = list()

    def add_input(self, name):
        # For now the limitation is one input per regbus
        assert (len(self.inputs) == 0)
        self.inputs.append(name)

    def add_output(self, name, addrs, default=False):
        idx = len(self.outputs)
        for lo, hi in addrs:
            if hi >> self.aw == 1:
                hi -= 1
            self.addrmap.append((idx, lo, hi))
        self.outputs.append(name)

    def add_output_entry(self, name, entry):
        self.add_output(name,
                        [(r.lo, r.hi)
                         for r in self.node.get_routes() if r.port == entry])

    def emit(self):
        global code_module
        global code_package
        if self.emitted:
            return
        self.emitted = True
        code_module.setdefault(self.context, "")
        (pkg,
         mod) = self.tpl.render_unicode(xbar=self, RegBus=RegBus,
                                        util=util).split("// ----- 8< -----")
        code_package += "\n" + pkg.strip() + "\n"
        code_module[self.context] += "\n" + mod.strip() + "\n"


# Generate the code.
def render():
    global code_package
    global code_module

    code_package = ""
    code_module = dict()

    for xbar in xbars:
        xbar.emit()

    # Clean things up.
    # code_module = code_module.strip()
    code_package = code_package.strip()
