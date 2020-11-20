#include "start.S"

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

.section .rodata
.balign 4
snrt_stack_size:
    .weak snrt_stack_size
    .word 8

# TODO(fschuiki): This should be made to not pollute the symbol space with
# "barrier_reg". It would be better to provide short snippets of
# platform-specific code where stuff like this can go, together with a proper
# symbol name like `_snrt_banshee_barrier_reg`.
.globl barrier_reg
