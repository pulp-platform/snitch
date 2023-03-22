// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

extern __thread cls_t* _cls_ptr;

inline cls_t* cls() { return _cls_ptr; }
