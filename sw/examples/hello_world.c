// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "snrt.h"
#include "printf.h"

int main() {

	// printf("Hello World!\n");
	printf("# 0 hart %d global core %d(%d) ", snrt_hartid(), snrt_global_core_idx(), snrt_global_core_num());
	printf("in cluster %d(%d) ", snrt_cluster_idx(), snrt_cluster_num());
	printf("cluster core %d(%d) ", snrt_cluster_core_idx(), snrt_cluster_core_num());
	printf("compute core %d(%d) ", snrt_cluster_compute_core_idx(), snrt_cluster_compute_core_num());
	printf("dm core %d(%d) ", snrt_cluster_dm_core_idx(), snrt_cluster_dm_core_num());
	printf("compute: %d dm: %d ", snrt_is_compute_core(), snrt_is_dm_core());
	printf("\n");
	
	printf("# 1 global mem [%#llx:%#llx] cluster mem [%#llx:%#llx] ", 
		snrt_global_memory().start, snrt_global_memory().end,
		snrt_cluster_memory().start, snrt_cluster_memory().end);
	printf("\n");
    // printf("core_id    %#x\n", core_id);
    // printf("core_num   %#x\n", core_num);
    // printf("spm_start  %#x\n", spm_start);
    // printf("spm_end    %#x\n", spm_end);

	return 0;
}
