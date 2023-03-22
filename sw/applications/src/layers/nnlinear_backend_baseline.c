// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "nnlinear_backend_baseline.h"

#include "network.h"
#include "nnlinear_baseline.h"
#include "printf.h"
#include "snrt.h"
#include "utils.h"

// define which parts of the network to run
#define RUN_FEEDFORWARD 1
#define RUN_GRADIENT_UPDATE 1
#define RUN_TRAINING_STEP 1 
#define GET_ACCURACY 1
#define GET_LOSS 1
#define RUN_RTL 0
#define NUM_EPOCHS 1
#define BATCH_SIZE 256
#define DATASET_SIZE 512//60000
#define INFO 1

void nnlinear_backend_baseline(const network_fp32_t *n) {
    
    uint32_t cluster_num = snrt_cluster_num();                          // Total number of clusters
    uint32_t cluster_core_num = snrt_cluster_core_num();                // Total cores per cluster
    uint32_t cluster_id = snrt_cluster_idx();                           // Cluster ID
    uint32_t compute_num = snrt_cluster_compute_core_num();             // Number of compute cores per cluster 
    uint32_t global_compute_num = snrt_global_core_num();               // Total cores incl. DM core per cluster 
    uint32_t compute_id = snrt_cluster_compute_core_idx();              // Core ID of each compute core
    uint32_t dm_id = snrt_cluster_dm_core_idx();                        // DM core ID of each cluster
uint32_t global_compute_id = snrt_global_core_idx();                    // Core ID of each core on all clusters

    if (INFO == 1) {
        if (compute_id == 0) {
            printf("======================== System Info ========================\n");
            printf("Total number of clusters: %d\n", cluster_num);
            printf("Total cores per cluster: %d\n", cluster_core_num);
            printf("Number of compute cores per cluster: %d\n", compute_num);
            printf("Total cores incl. DM core per cluster: %d\n", global_compute_num);
            printf("=============================================================\n");
        }

    }

    snrt_cluster_hw_barrier();

    uint32_t weights_size = NUM_CLASSES * IN_CH * n->dtype;
    uint32_t biases_size = NUM_CLASSES * n->dtype;
    uint32_t activations_size = NUM_CLASSES * n->dtype;
    uint32_t image_size = IN_CH * n->dtype;
    uint32_t loss_size = n->dtype;
    uint32_t labels_size = sizeof(uint32_t);

    // cluster 0 variabels:
    float *weights;
    float *weight_grads;
    float *biases;
    float *bias_grads;
    float *images;
    float *activations;
    float *loss;
    uint32_t *targets; 

    void *tcdm_ptr = (float *)snrt_cluster_memory().start;

    // cluster 0 memory map
    weights = tcdm_ptr;
    tcdm_ptr += weights_size;
    weight_grads = tcdm_ptr;
    tcdm_ptr += weights_size;
    biases = tcdm_ptr;
    tcdm_ptr += biases_size;
    activations = tcdm_ptr;
    tcdm_ptr += activations_size;
    bias_grads = tcdm_ptr;
    tcdm_ptr += biases_size;
    images = tcdm_ptr;
    tcdm_ptr += image_size;
    loss = tcdm_ptr;
    tcdm_ptr += loss_size;
    targets = tcdm_ptr;
    tcdm_ptr += labels_size;

    // DRAM pointers to images and targets
    uint32_t *images_dram = (void *)0x80040000;
    uint32_t *targets_dram = (void *)0x80108000;

    if (snrt_is_dm_core()) {
        snrt_dma_txid_t txid_B = snrt_dma_start_1d(biases, 
                                                    n->b, 
                                                    biases_size);
        snrt_dma_wait_all();
        snrt_dma_txid_t txid_W = snrt_dma_start_2d(weights,
                                                    n->W,
                                                    IN_CH * n->dtype,
                                                    IN_CH * n->dtype,
                                                    IN_CH * n->dtype,
                                                    NUM_CLASSES);
    }

    snrt_cluster_hw_barrier();

    uint32_t number_of_images = 256;
    int correct = 0;
    int predict = 0;
    int epoch_count = 0;
    float epoch_loss, epoch_acc = 0;
    float mean_epoch_loss, mean_epoch_acc = 0;
    float batch_acc = 0;
    float batch_loss = 0;
    loss[0] = 0.0f;

    int batches = DATASET_SIZE / BATCH_SIZE;

    for (int epoch = 0; epoch < NUM_EPOCHS; epoch++){
        if (INFO == 1) {
            if (compute_id == 0) {
                printf("======================== EPOCH [%d/%d] start. ========================\n", (epoch + 1), NUM_EPOCHS);
            }
        }
        for(int batch = 0; batch < batches; batch++){
            batch_loss = 0;
            batch_acc = 0;
            correct = 0;
            if(snrt_is_compute_core()) {
                if (INFO == 1) {
                    printf("======================== BATCH [%d/%d] start. ========================\n", (batch + 1), batches);
                }
                /* Zero out the gradients 
                * TODO: make this more efficient!
                */
                for (int i = 0; i < NUM_CLASSES; i++) {
                    bias_grads[i] = 0;
                    for (int j = 0; j < IN_CH; j++) {
                        weight_grads[i * IN_CH + j] = 0;
                    }

                }

                if (INFO == 1) {
                    printf("INFO: Gradients have been zeroed out.\n");
                }

                snrt_cluster_hw_barrier();

            } else if(!snrt_is_compute_core()) {
                snrt_cluster_hw_barrier();
            }
            for(uint32_t image = 0; image < BATCH_SIZE; image++){
                uint32_t volatile curr_img = image * IN_CH + batch * BATCH_SIZE * IN_CH;
                // printf("======================== Image %d ========================\n", curr_img / 784);
                uint32_t volatile curr_target = image + batch * BATCH_SIZE;
                if (snrt_is_dm_core()) {
                        float img_checksum = 0;
                        snrt_dma_start_tracking();
                        snrt_dma_txid_t txid_img = 
                                snrt_dma_start_1d(images,                                   // destination
                                                &images_dram[curr_img],                     // source
                                                n->dtype * IN_CH);                          // size
                        snrt_dma_wait_all();
                        snrt_dma_txid_t txid_target = 
                                snrt_dma_start_1d(targets,                                  // destination
                                                &targets_dram[curr_target],                 // source
                                                sizeof(uint32_t));                          // size
                        snrt_dma_wait_all();
                }

                snrt_cluster_hw_barrier();

                if (snrt_is_compute_core() && snrt_cluster_compute_core_idx() < compute_num) {

                    GradientUpdate_baseline(images, activations, biases, weights, weight_grads, bias_grads, targets[0], loss); 
                    snrt_cluster_hw_barrier();
                    batch_loss += *loss;
                    /* Accuracy Calculation */
                    float max_activation = activations[0];
                    predict = 0;
                    for (int i = 0; i < NUM_CLASSES; i++) {
                        if(max_activation < activations[i]) {
                            max_activation = activations[i];
                            predict = i;
                        }
                    }

                    if(predict == targets[0]) {
                        correct++;
                    }
                    snrt_cluster_hw_barrier();

                    // printf("pred = %d, target = %d\n", predict, targets[0]);


                } else if (!snrt_is_compute_core()) {
                    snrt_cluster_hw_barrier();
                    snrt_cluster_hw_barrier();
                    snrt_cluster_hw_barrier();
                    snrt_cluster_hw_barrier();
                }
            }

            snrt_cluster_hw_barrier();

            // After one epoch we update the weights
            if (snrt_is_compute_core() && snrt_cluster_compute_core_idx() < compute_num) {
                
                batch_acc = (float)correct / (float)BATCH_SIZE;
                epoch_acc += batch_acc;
                epoch_loss += batch_loss / BATCH_SIZE;
                if (INFO == 1) {
                    printf("A total of [%d/%d] images were predicted correctly in batch %d\n", correct, BATCH_SIZE, batch + 1);
                    printf("batch acc = %.6f\n", batch_acc * 100);
                    printf("batch loss = %.6f\n", batch_loss / BATCH_SIZE);
                }

                TrainingStep_baseline(biases, weights, weight_grads, bias_grads, n->learning_rate);
                
                if(batch%(batches - 1)==0 && batch!=0) {

                    epoch_count++;
                    mean_epoch_loss = epoch_loss/batches;
                    mean_epoch_acc = epoch_acc/batches;
                    if (INFO == 1) {
                        printf("===========================  EPOCH %u done. ===========================\n", epoch_count);
                        printf("===========================  Epoch  Acc %.3f  ===========================\n", mean_epoch_acc * 100);
                        printf("===========================  Epoch  Loss %.3f  ===========================\n", mean_epoch_loss);
                    }
                    epoch_loss = 0;
                    epoch_acc = 0;

                }


            } else if (!snrt_is_compute_core()) {

                snrt_cluster_hw_barrier();

            }

            snrt_cluster_hw_barrier();


        }
    }
    snrt_global_barrier();

}