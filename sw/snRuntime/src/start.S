# Copyright 2020 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

# This file defines the `_start` symbol and initializes the global pointer. This
# is common among all bare runtimes.


# Expected from bootloader:
# - a0: mhartid
# - a1: device tree ptr
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

snrt.crt0.init_core_info:
    # Information passed into the call:
    # - a0: mhartid (from bootloader)
    # - a1: device tree ptr (from bootloader)
    call      _snrt_init_core_info
    # Information needed after the call:
    # - a0: cluster-local core id
    # - a1: cluster-local core count
    # - a2: TCDM start ptr
    # - a3: TCDM end ptr
    # - a4: device tree ptr

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

    # Set 8 bytes aside for the main return value and clear that to zero.
    addi      a3, a3, -8
    sw        zero, 0(a3)

    # Set space aside for the root team structure.
    lw        t0, _snrt_team_size
    sub       a3, a3, t0
    mv        a5, a3

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

    # Allocate thread-local storage at the top of the stack and set tp
    # to the base of the tls
snrt.crt0.init_tls:
    la        t0, __tdata_start
    la        t1, __tdata_end
    la        t2, __tbss_start
    la        t3, __tbss_end
    add       sp, sp, t0   # subtract sp to make room for TLS and align
    sub       sp, sp, t1
    add       sp, sp, t2
    sub       sp, sp, t3
    andi      sp, sp, ~0x7
    mv        tp, sp       # palce tp at start of TLS
    andi      sp, sp, ~0x7 # align stack to 8B

    # Copy __tdata_start to __tdata_end.
    mv        t4, tp
    bge       t0, t1, 2f
1:  lw        t5, 0(t0)
    sw        t5, 0(t4)
    addi      t0, t0, 4
    addi      t4, t4, 4
    blt       t0, t1, 1b
2:

    # Clear from _tdata_end to _tbss_end.
    la        t0, __tbss_start
    la        t1, __tbss_end
    bge       t0, t1, 2f
1:  sw        zero, 0(t4)
    addi      t0, t0, 4
    addi      t4, t4, 4
    blt       t0, t2, 1b
2:

    # Initialize the root team.
snrt.crt0.init_team:
    addi      sp, sp, -20
    sw        a0, 0(sp)
    sw        a1, 4(sp)
    sw        a2, 8(sp)
    sw        a3, 12(sp)
    sw        a4, 16(sp)
    call      _snrt_init_team
    lw        a0, 0(sp)
    lw        a1, 4(sp)
    lw        a2, 8(sp)
    lw        a3, 12(sp)
    lw        a4, 16(sp)
    addi      sp, sp, 20

    # Synchronize cores.
snrt.crt0.pre_barrier:
    call      _snrt_cluster_barrier

    # Execute the main function.
snrt.crt0.main:
    call      main  # main(int core_id, int core_num, void *spm_start, void *spm_end)
    # lw        s0, tcdm_end_address_reg  # add return value to special slot
    # addi      s0, s0, -8
    # amoadd.w  zero, a0, (s0)

    # Synchronize cores.
snrt.crt0.post_barrier:
    call      _snrt_cluster_barrier

    # Write execution result to EOC register.
snrt.crt0.end:
    call      _snrt_exit
1:
    wfi
    j       1b
