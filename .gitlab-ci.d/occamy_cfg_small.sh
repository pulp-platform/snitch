#!/bin/bash
# Copyright 2022 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

# Makes the occamy system smaller so that it fits on a VCU128 FPGA board

occamg_cfg="hw/system/occamy/src/occamy_cfg.hjson"

# nr_s1_quadrant -> 1
sed -i 's|nr_s1_quadrant.*|nr_s1_quadrant: 1,|' ${occamg_cfg}

# nr_clusters: -> 1
sed -i 's|nr_clusters.*|nr_clusters: 1,|' ${occamg_cfg}

# Only a single core in the cluster. { $ref: "#/compute_core_template" },
# Comment-out all compute cores and add a new one before the DMA
# sed -i 's|{ $ref: "#/compute_core_template" },|//{ $ref: "#/compute_core_template" },|' ${occamg_cfg}
# sed -i '/{ $ref: "#\/dma_core_template" },/i { $ref: "#\/compute_core_template" },' ${occamg_cfg}
