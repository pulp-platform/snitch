// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

__thread cls_t* _cls_ptr;

cls_t __attribute__((section(".cbss"))) _cls;
