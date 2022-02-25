// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "layer.h"

/**
 * @brief batchnorm layer that handles data transfers in a double buffered
 * fashion
 *
 * @param l conv_layer struct that holds addresses and parameters
 */
void batchnorm_layer(const conv_layer *l);
