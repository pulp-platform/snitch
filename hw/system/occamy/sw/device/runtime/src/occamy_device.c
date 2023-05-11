// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

extern void post_wakeup_cl();

extern comm_buffer_t* get_communication_buffer();

extern uint32_t elect_director(uint32_t num_participants);

extern void return_to_cva6(sync_t sync);
