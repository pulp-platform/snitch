# Copyright 2020 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

from .cluster import Generator, PMA, PMACfg, SnitchCluster


class Occamy(Generator):
    """
    Generate an Occamy system.
    """
    def __init__(self, cfg):
        super().__init__("snitch_cluster.schema.json")
        # Validate the schema.
        self.validate(cfg)
        # from here we know that we have a valid object.
        # and construct a new SnitchClusterTB object.
        self.cfg = cfg
        pma_cfg = PMACfg()
        # TODO(zarubaf): Check dram start address is aligned to its length.
        # For this example system make the entire dram cacheable.
        pma_cfg.add_region(PMA.CACHED, 0, 0)
        # Store Snitch cluster config in separate variable
        self.cluster = SnitchCluster(cfg, pma_cfg)
        self.cfg['tie_ports'] = False

    def render_wrapper(self):
        return self.cluster.render_wrapper()
