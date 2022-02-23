# Copyright 2020 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

#include "../../start.S"

# Function to determine the initial cluster layout to setup the initial stack.
# See `hw/system/snitch_cluster/test/tb_lib.hh` for details of the bootdata
# layout.
#
# Expecting:
# - a0: mhartid
# - a1: device tree ptr ("bootdata" in `tb_lib.hh`)
_snrt_init_core_info:
    .globl _snrt_init_core_info
    mv        a4, a1
    lw        a1, 4(a4)  # load the number of cores per cluster
    lw        t0, 8(a4)  # load cluster's hartid offset
    lw        a2, 12(a4) # start address of the TCDM
    lw        t1, 16(a4) # size of TCDM address space
    lw        t2, 20(a4) # offset between cluster TCDMs
    sub       a0, a0, t0
    div       t3, a0, a1 # calculate cluster index
    mul       t4, t3, t2 # calculate cluster TCDM offset
    add       a2, a2, t4 # start address of current cluster TCDM
    add       a3, a2, t1 # end address of current cluster TCDM
    remu      a0, a0, a1 # calculate cluster-local core id
    ret

# Must leave a0 untouched.
_snrt_cluster_barrier:
    .globl _snrt_cluster_barrier
    addi      sp, sp, -4
    sw        ra, 0(sp)
    call      _snrt_barrier_reg_ptr
    lw        a0, 0(a0)
    mv        zero, a0
    lw        ra, 0(sp)
    addi      sp, sp, 4
    ret

# Mustn't use any non-temporary registers
# Expecting:
# - a0: device tree ptr ("bootdata" in `tb_lib.hh`)
# a0 = bootdata->hartid_base
_snrt_get_base_hartid:
    .globl _snrt_get_base_hartid
    lw        a0, 8(a0)  # load cluster's hartid offset
    ret
