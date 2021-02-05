# Copyright 2020 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

#include "start.S"

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
    lw        a3, 16(a4) # end address of the TCDM
    sub       a0, a0, t0
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

# Function to terminate execution.
#
# Expecting:
# - a0: exit code
# - a1: device tree ptr
_snrt_exit:
    .globl _snrt_exit
    # Determine global core index.
    addi      sp, sp, -8
    sw        a0, 0(sp)
    sw        ra, 4(sp)
    call      snrt_global_core_idx
    lw        t0, 0(sp)
    lw        ra, 4(sp)
    addi      sp, sp, 8

    # Only first core triggers exit.
    bnez      a0, 1f
    slli      t0, t0, 1
    ori       t0, t0, 1
    la        t1, .tohost
    sw        t0, 0(t1)
1:  ret

.set tcdm_start_address_reg, 0x40000000
.set tcdm_end_address_reg, 0x40000008
.set nr_cores_address_reg, 0x40000010
.set scratch_reg, 0x40000020
.set barrier_reg, 0x40000038
.set cluster_base_hart_id_reg, 0x40000040

# Platform-specific symbols
.set _snrt_cluster_cluster_core_num, nr_cores_address_reg
.set _snrt_cluster_cluster_base_hartid, cluster_base_hart_id_reg
.set _snrt_cluster_cluster_num, 0x40000048
.set _snrt_cluster_cluster_id, 0x40000050
.globl _snrt_cluster_cluster_core_num
.globl _snrt_cluster_cluster_base_hartid
.globl _snrt_cluster_cluster_num
.globl _snrt_cluster_cluster_id

# TODO(fschuiki): This should be made to not pollute the symbol space with
# "barrier_reg". It would be better to provide short snippets of
# platform-specific code where stuff like this can go, together with a proper
# symbol name like `_snrt_cluster_barrier_reg`.
.globl barrier_reg

# HTIF sections
.pushsection .tohost,"aw",@progbits;
.align 6; .global tohost; tohost: .dword 0;
.align 6; .global fromhost; fromhost: .dword 0;
