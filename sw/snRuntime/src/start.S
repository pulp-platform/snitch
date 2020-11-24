# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

# This file defines the `_start` symbol and initializes the global pointer. This
# is common among all bare runtimes.

.section .init
_start:
    .globl _start

    # Initialize global pointer
snrt.crt0.init_global_pointer:
    .option push
    .option norelax
1:  auipc     gp, %pcrel_hi(__global_pointer$)
    addi      gp, gp, %pcrel_lo(1b)
    .option pop

    # Read hartid and number of cores in the cluster.
snrt.crt0.init_core_info:
    lw        t0, cluster_base_hart_id_reg  # load cluster's hartid offset
    csrr      a0, mhartid  # shift core's hartid such that first core is 0
    sub       a0, a0, t0
    lw        a1, nr_cores_address_reg  # load the number of cores per cluster

    # Clear the bss segment.
snrt.crt0.init_bss:
    bnez      a0, 2f  # only core 0 (TODO: this should be one core globally, not per cluster)
    la        t0, _edata
    la        t1, _end
    bge       t0, t1, 2f
1:  sw        zero, 0(t0)
    addi      t0, t0, 4
    blt       t0, t1, 1b
2:

    # Read hartid and number of cores in the cluster.
snrt.crt0.init_stack:
    # Load TCDM start and end addresses.
    lw        a2, tcdm_start_address_reg
    lw        a3, tcdm_end_address_reg

    # Set 8 bytes aside for the main return value and clear that to zero.
    addi      a3, a3, -8
    sw        zero, 0(a3)

    # Set space aside for the root team structure.
    lw        t0, _snrt_team_size
    sub       a3, a3, t0
    mv        a4, a3

    # Compute the stack top for this hart, and the cluster-wide stack bottom.
    lw        t2, snrt_stack_size  # load stack size (overridable by binary)

    sll       t0, a0, t2  # this hart
    sll       t1, a1, t2  # all harts
    sub       sp, a3, t0
    sub       a3, a3, t1

    # Misalign stacks in the TCDM to reduce banking conflicts
    slli      t0, a0, 3  # this hart
    slli      t1, a1, 3  # all harts
    add       sp, sp, t0
    add       a3, a3, t1

    # Allocate thread-local storage at the top of the stack.
snrt.crt0.init_tls:
    la        t0, __tdata_start
    la        t1, __tdata_end
    la        t2, __tbss_end
    add       sp, sp, t0
    sub       sp, sp, t2
    mv        tp, sp

    # Copy __tdata_start to __tdata_end.
    mv        t3, tp
    bge       t0, t1, 2f
1:  lw        t4, 0(t0)
    sw        t4, 0(t3)
    addi      t0, t0, 4
    addi      t3, t3, 4
    blt       t0, t1, 1b
2:

    # Clear from _tdata_end to _tbss_end.
    bge       t0, t2, 2f
1:  sw        zero, 0(t3)
    addi      t0, t0, 4
    addi      t3, t3, 4
    blt       t0, t2, 1b
2:

    # Initialize the root team.
snrt.crt0.init_team:
    addi      sp, sp, -16
    sw        a0, 0(sp)
    sw        a1, 4(sp)
    sw        a2, 8(sp)
    sw        a3, 12(sp)
    call      _snrt_init_team
    lw        a0, 0(sp)
    lw        a1, 4(sp)
    lw        a2, 8(sp)
    lw        a3, 12(sp)
    addi      sp, sp, 16

    # Synchronize cores.
snrt.crt0.pre_barrier:
    lw        t0, barrier_reg
    mv        zero, t0

    # Execute the main function.
snrt.crt0.main:
    call      main  # main(int core_id, int core_num, void *spm_start, void *spm_end)
    # lw        s0, tcdm_end_address_reg  # add return value to special slot
    # addi      s0, s0, -8
    # amoadd.w  zero, a0, (s0)

    # Synchronize cores.
snrt.crt0.post_barrier:
    lw        t0, barrier_reg
    mv        zero, t0

    # Write execution result to EOC register.
snrt.crt0.end:
    lw        t0, cluster_base_hart_id_reg
    csrr      t1, mhartid
    bne       t0, t1, 1f  # only first core writes to EOC address
    slli      a0, a0, 1
    ori       a0, a0, 1
    la        t0, scratch_reg
    sw        a0, 0(t0)
1:
    wfi
    j       1b

# The following is a super ugly hack to determine the end of the .tbss section.
.section ".tdata"
__tdata_end:
    .globl __tdata_end
.section ".tbss"
__tbss_end:
    .globl __tbss_end
