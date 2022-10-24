// Copyright 2021 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#pragma once

// Data for testing the knn library

#include <stdint.h>

static uint32_t knn_k3_N50_nrs8_input_size = 50;
static uint32_t knn_k3_N50_nrs8_k_size = 3;
static uint32_t knn_k3_N50_nrs8_nr_samples = 8;
static double knn_k3_N50_nrs8_samples[8] = {
    130.9866116770785, 226.25392339018188, 0.03592513012802889, 94.96266106366087,
    46.09602530565521, 29.00355261687939,  58.504332393726436,  108.5406243642213};
static double knn_k3_N50_nrs8_output_checksum[8] = {288.972, 314.1,   160.191, 251.28,
                                                    204.165, 185.319, 216.729, 266.985};
static uint32_t knn_k3_N100_nrs24_input_size = 100;
static uint32_t knn_k3_N100_nrs24_k_size = 3;
static uint32_t knn_k3_N100_nrs24_nr_samples = 24;
static double knn_k3_N100_nrs24_samples[24] = {
    261.973223354157,   452.50784678036376, 0.07185026025605779, 189.92532212732175,
    92.19205061131042,  58.00710523375878,  117.00866478745287,  217.0812487284426,
    249.24932731170688, 338.48467230090887, 263.3379939481498,   430.45489014924436,
    128.43690328133926, 551.6333735407919,  17.20488604693722,   421.1876898940723,
    262.15087684702917, 350.9689502296212,  88.19107482552586,   124.44735544312087,
    503.02773804197216, 608.2619218669256,  196.89306871963637,  434.9170671634631};
static double knn_k3_N100_nrs24_output_checksum[24] = {574.803,
                                                       628.2,
                                                       317.241,
                                                       502.56,
                                                       405.189,
                                                       370.638,
                                                       430.317,
                                                       530.829,
                                                       562.239,
                                                       628.2,
                                                       577.944,
                                                       628.2,
                                                       442.88100000000003,
                                                       628.2,
                                                       329.805,
                                                       628.2,
                                                       574.803,
                                                       628.2,
                                                       402.048,
                                                       439.74,
                                                       628.2,
                                                       628.2,
                                                       511.983,
                                                       628.2};
