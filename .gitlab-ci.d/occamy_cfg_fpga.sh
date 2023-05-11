#!/bin/bash
# Copyright 2022 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

# Makes the occamy system smaller so that it fits on a VCU128 FPGA board

occamy_cfg="hw/system/occamy/cfg/full.hjson"

# nr_s1_quadrant -> 1
sed -i 's|nr_s1_quadrant.*|nr_s1_quadrant: 1,|' ${occamy_cfg}

# nr_clusters: -> 1
sed -i 's|nr_clusters.*|nr_clusters: 1,|' ${occamy_cfg}

# distributed pipeline registers in the FPU to meet timing (vivado is bad at retiming)
sed -i 's|fpu_pipe_config.*|fpu_pipe_config: "DISTRIBUTED"|' ${occamy_cfg}

# Only a single core in the cluster. { $ref: "#/compute_core_template" },
# Comment-out all compute cores and add a new one before the DMA
# sed -i 's|{ $ref: "#/compute_core_template" },|//{ $ref: "#/compute_core_template" },|' ${occamy_cfg}
# sed -i '/{ $ref: "#\/dma_core_template" },/i { $ref: "#\/compute_core_template" },' ${occamy_cfg}

# Set all multicuts to `NoCuts=1` to reduce FF and routing since timing is not an issue
in_cuts=0
line=0
while read p; do
  line=$((line+1))
  [ "$p" = "cuts: {" ] && in_cuts=1 ||:
  [ "$in_cuts" -eq 1 ] && [ "$p" = "}" ] && in_cuts=0 ||:
  [ "$in_cuts" -eq 1 ] && sed -i "${line}s|\(.*\): [1-9][0-9]*,|\1: 1,|" $occamy_cfg ||:
done <$occamy_cfg
