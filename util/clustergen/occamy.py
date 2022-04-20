# Copyright 2020 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

from .cluster import Generator, PMA, PMACfg, SnitchCluster, clog2


class Occamy(Generator):
    """
    Generate an Occamy system.
    """
    def __init__(self, cfg):
        super().__init__("occamy.schema.json")
        # Validate the schema.
        self.validate(cfg)
        # from here we know that we have a valid object.
        # and construct a new Occamy object.
        self.cfg = cfg
        # PMA Configuration for Snitch clusters only; for CVA6, see its SV template.
        pma_cfg = PMACfg()
        addr_width = cfg["cluster"]['addr_width']
        # Make the entire HBM, but not HBI cacheable
        pma_cfg.add_region_length(PMA.CACHED,
                                  cfg["hbm"]["address_0"],
                                  cfg["hbm"]["nr_channels_address_0"] * cfg["hbm"]["channel_size"],
                                  addr_width)
        pma_cfg.add_region_length(PMA.CACHED,
                                  cfg["hbm"]["address_1"],
                                  cfg["hbm"]["nr_channels_total"] * cfg["hbm"]["channel_size"],
                                  addr_width)
        # Make the SPM cacheable
        pma_cfg.add_region_length(PMA.CACHED,
                                  cfg["spm_narrow"]["address"],
                                  cfg["spm_narrow"]["length"],
                                  addr_width)
        # Make the boot ROM cacheable
        pma_cfg.add_region_length(PMA.CACHED,
                                  cfg["peripherals"]["rom"]["address"],
                                  cfg["peripherals"]["rom"]["length"],
                                  addr_width)

        # Store Snitch cluster config in separate variable
        self.cluster = SnitchCluster(cfg["cluster"], pma_cfg)
        # Overwrite boot address with base of bootrom
        self.cluster.cfg["boot_addr"] = self.cfg["peripherals"]["rom"]["address"]

        self.cluster.cfg['tie_ports'] = False

        if "ro_cache_cfg" in self.cfg["s1_quadrant"]:
            ro_cache = self.cfg["s1_quadrant"]["ro_cache_cfg"]
            ro_tag_width = self.cluster.cfg['addr_width'] - clog2(
                ro_cache['width'] // 8) - clog2(ro_cache['count']) + 3
            self.cluster.add_mem(ro_cache["count"],
                                 ro_cache["width"],
                                 desc="ro cache data",
                                 byte_enable=False,
                                 speed_optimized=True,
                                 density_optimized=True)
            self.cluster.add_mem(ro_cache["count"],
                                 ro_tag_width,
                                 desc="ro cache tag",
                                 byte_enable=False,
                                 speed_optimized=True,
                                 density_optimized=True)

        self.cluster.add_mem(cfg["spm_narrow"]["length"] // 8,
                             64,
                             desc="SPM Narrow",
                             speed_optimized=False,
                             density_optimized=True)

        self.cluster.add_mem(cfg["spm_wide"]["length"] // 64,
                             512,
                             desc="SPM Wide",
                             speed_optimized=False,
                             density_optimized=True)

        # CVA6
        self.cluster.add_mem(256,
                             128,
                             desc="cva6 data cache array",
                             byte_enable=True,
                             speed_optimized=True,
                             density_optimized=False)
        self.cluster.add_mem(256,
                             128,
                             desc="cva6 instruction cache array",
                             byte_enable=True,
                             speed_optimized=True,
                             density_optimized=False)
        self.cluster.add_mem(256,
                             44,
                             desc="cva6 data cache tag",
                             byte_enable=True,
                             speed_optimized=True,
                             density_optimized=False)
        self.cluster.add_mem(256,
                             45,
                             desc="cva6 instruction cache tag",
                             byte_enable=True,
                             speed_optimized=True,
                             density_optimized=False)
        self.cluster.add_mem(256,
                             64,
                             desc="cva6 data cache valid and dirty",
                             byte_enable=True,
                             speed_optimized=True,
                             density_optimized=False)
        # HBM
        self.cluster.add_mem(2**6,
                             16,
                             byte_enable=False,
                             desc="HBM Re-order",
                             speed_optimized=True,
                             density_optimized=False,
                             dual_port=True)
        self.cluster.add_mem(2**6,
                             14,
                             byte_enable=False,
                             desc="HBM Fifo",
                             speed_optimized=True,
                             density_optimized=False,
                             dual_port=True)
        self.cluster.add_mem(2**4,
                             32,
                             byte_enable=False,
                             desc="HBM WR Fifo",
                             speed_optimized=True,
                             density_optimized=False,
                             dual_port=True)
        self.cluster.add_mem(2**4,
                             102,
                             byte_enable=False,
                             desc="HBM RD Fifo",
                             speed_optimized=True,
                             density_optimized=False,
                             dual_port=True)
        self.cluster.add_mem(2**6,
                             48,
                             byte_enable=False,
                             desc="HBM Test",
                             speed_optimized=True,
                             density_optimized=False,
                             dual_port=True)
        self.cluster.add_mem(2**4,
                             576,
                             byte_enable=False,
                             desc="HBM Test/W Data",
                             speed_optimized=True,
                             density_optimized=False,
                             dual_port=True)
        self.cluster.add_mem(2**4,
                             64,
                             byte_enable=False,
                             desc="HBM Test",
                             speed_optimized=True,
                             density_optimized=False,
                             dual_port=True)
        self.cluster.add_mem(2**4,
                             204,
                             byte_enable=False,
                             desc="HBM Analyzer",
                             speed_optimized=True,
                             density_optimized=False,
                             dual_port=True)

        self.cluster.add_mem(2**3,
                             56,
                             desc="HBM RD CMD",
                             byte_enable=False,
                             speed_optimized=True,
                             density_optimized=False,
                             dual_port=True)
        self.cluster.add_mem(2**4,
                             74,
                             desc="HBM WR CMD",
                             byte_enable=False,
                             speed_optimized=True,
                             density_optimized=False,
                             dual_port=True)
        self.cluster.add_mem(2**4,
                             11,
                             desc="HBM BID",
                             byte_enable=False,
                             speed_optimized=True,
                             density_optimized=False,
                             dual_port=True)
        self.cluster.add_mem(2**7,
                             585,
                             desc="HBM RD ID",
                             byte_enable=False,
                             speed_optimized=True,
                             density_optimized=False,
                             dual_port=True)
        self.cluster.add_mem(2**6,
                             6,
                             desc="HBM RD ID",
                             byte_enable=False,
                             speed_optimized=True,
                             density_optimized=False,
                             dual_port=True)
        self.cluster.add_mem(2**7,
                             641,
                             desc="HBM ReOrd",
                             byte_enable=False,
                             speed_optimized=True,
                             density_optimized=False,
                             dual_port=True)

    def render_wrapper(self):
        return self.cluster.render_wrapper()
