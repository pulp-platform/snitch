#include "start.S"

.set tcdm_start_address_reg, 0x40000000
.set tcdm_end_address_reg, 0x40000008
.set nr_cores_address_reg, 0x40000010
.set scratch_reg, 0x40000020
.set barrier_reg, 0x40000038
.set cluster_base_hart_id_reg, 0x40000040

.section .rodata
.balign 4
snrt_stack_size:
    .weak snrt_stack_size
    .word 8
