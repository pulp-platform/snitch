# Copyright 2020 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

#include "start.S"

# Function to determine the initial cluster layout to setup the initial stack.
#
# Expecting:
# - a0: mhartid
# - a1: device tree ptr
_snrt_init_core_info:
    .globl _snrt_init_core_info
    mv        a4, a1
    lw        t0, cluster_base_hart_id_reg  # load cluster's hartid offset
    csrr      a0, mhartid  # shift core's hartid such that first core is 0
    sub       a0, a0, t0
    lw        a1, nr_cores_address_reg   # load the number of cores per cluster
    remu      a0, a0, a1                 # calculate cluster-local core id
    lw        a2, tcdm_start_address_reg # start address of the TCDM
    lw        a3, tcdm_end_address_reg   # end address of the TCDM
    ret

# Must leave a0 untouched.
_snrt_cluster_barrier:
    .globl _snrt_cluster_barrier
    lw        t0, barrier_reg
    mv        zero, t0
    ret

# Function to terminate execution.
#
# Expecting:
# - a0: exit code
_snrt_exit:
    .globl _snrt_exit
    lw        t0, cluster_base_hart_id_reg
    csrr      t1, mhartid
    bne       t0, t1, 1f  # only first core writes to EOC address
    slli      a0, a0, 1
    ori       a0, a0, 1
    la        t0, scratch_reg
    sw        a0, 0(t0)
1:  ret

.set tcdm_start_address_reg, 0x40000000
.set tcdm_end_address_reg, 0x40000008
.set nr_cores_address_reg, 0x40000010
.set scratch_reg, 0x40000020
.set barrier_reg, 0x40000038
.set cluster_base_hart_id_reg, 0x40000040

# Platform-specific symbols
.set _snrt_banshee_cluster_core_num, nr_cores_address_reg
.set _snrt_banshee_cluster_base_hartid, cluster_base_hart_id_reg
.set _snrt_banshee_cluster_num, 0x40000048
.set _snrt_banshee_cluster_id, 0x40000050
.globl _snrt_banshee_cluster_core_num
.globl _snrt_banshee_cluster_base_hartid
.globl _snrt_banshee_cluster_num
.globl _snrt_banshee_cluster_id

# TODO(fschuiki): This should be made to not pollute the symbol space with
# "barrier_reg". It would be better to provide short snippets of
# platform-specific code where stuff like this can go, together with a proper
# symbol name like `_snrt_banshee_barrier_reg`.
.globl barrier_reg
