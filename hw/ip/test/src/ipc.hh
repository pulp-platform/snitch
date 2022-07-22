// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Paul Scheffler <paulsc@iis.ee.ethz.ch>

#pragma once

#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include <algorithm>
#include <tb_lib.hh>

class IpcIface {
   private:
    static const int IPC_BUF_SIZE = 4096;
    static const int IPC_BUF_SIZE_STRB = IPC_BUF_SIZE / 8 + 1;
    static const int IPC_ERR_DOUBLE_ARG = 30;
    static const long IPC_POLL_PERIOD_NS = 100000L;

    // Possible IPC operations
    enum ipc_opcode_e {
        Read = 0,
        Write = 1,
        Poll = 2,
    };

    // Operations are 3 doubles, followed by data streams in either direction
    typedef struct {
        uint64_t opcode;
        uint64_t addr;
        uint64_t len;
    } ipc_op_t;

    // Args passed to IPC thread
    typedef struct {
        char* tx;
        char* rx;
    } ipc_targs_t;

    // Thread to asynchronously handle FIFOs
    ipc_targs_t targs;
    pthread_t thread;
    bool active;

    static void* ipc_thread_handle(void* in) {
        ipc_targs_t* targs = (ipc_targs_t*)in;
        // Open FIFOs
        FILE* tx = fopen(targs->tx, "rb");
        FILE* rx = fopen(targs->rx, "wb");
        // Prepare data and full-strobe array
        uint8_t buf_data[IPC_BUF_SIZE];
        uint8_t buf_strb[IPC_BUF_SIZE_STRB];
        std::fill_n(buf_strb, IPC_BUF_SIZE_STRB, 0xFF);
        // Handle commands
        ipc_op_t op;
        while (fread(&op, sizeof(ipc_op_t), 1, tx)) {
            switch (op.opcode) {
                case Read:
                    // Read full blocks until one full block or less left
                    printf("[IPC] Read from 0x%x len %d ...\n", op.addr,
                           op.len);
                    for (uint64_t i = op.len; i > IPC_BUF_SIZE;
                         i -= IPC_BUF_SIZE) {
                        sim::MEM.read(op.addr, IPC_BUF_SIZE, buf_data);
                        fwrite(buf_data, IPC_BUF_SIZE, 1, rx);
                    }
                    sim::MEM.read(op.addr, op.len, buf_data);
                    fwrite(buf_data, op.len, 1, rx);
                    fflush(rx);
                    break;
                case Write:
                    // Write full blocks until one full block or less left
                    printf("[IPC] Write to 0x%x len %d ...\n", op.addr, op.len);
                    for (uint64_t i = op.len; i > IPC_BUF_SIZE;
                         i -= IPC_BUF_SIZE) {
                        fread(buf_data, IPC_BUF_SIZE, 1, tx);
                        sim::MEM.write(op.addr, IPC_BUF_SIZE, buf_data,
                                       buf_strb);
                    }
                    fread(buf_data, op.len, 1, tx);
                    sim::MEM.write(op.addr, op.len, buf_data, buf_strb);
                    break;
                case Poll:
                    // Unpack 32b checking mask and expected value from length
                    uint32_t mask = op.len & 0xFFFFFFFF;
                    uint32_t expected = (op.len >> 32) & 0xFFFFFFFF;
                    printf("[IPC] Poll on 0x%x mask 0x%x expected 0x%x ...\n",
                           op.addr, mask, expected);
                    uint32_t read;
                    do {
                        sim::MEM.read(op.addr, sizeof(uint32_t),
                                      (uint8_t*)(void*)&read);
                        nanosleep(
                            (const struct timespec[]){{0, IPC_POLL_PERIOD_NS}},
                            NULL);
                    } while (read & mask == expected & mask);
                    // Send back read 32b word
                    fwrite(&read, sizeof(uint32_t), 1, rx);
                    fflush(rx);
                    break;
            }
            printf("[IPC] ... done\n");
        }
        // TX FIFO closed at other end: close both FIFOs and join main thread
        fclose(tx);
        fclose(rx);
        pthread_exit(NULL);
    }

   public:
    // Conditionally construct IPC iff any arguments specify it
    IpcIface(int argc, char** argv) {
        static constexpr char IPC_FLAG[6] = "--ipc";
        active = false;
        for (auto i = 1; i < argc; ++i) {
            if (strncmp(argv[i], IPC_FLAG, strlen(IPC_FLAG)) == 0) {
                // Check for duplicate args
                if (active) {
                    fprintf(stderr, "[IPC] Duplicate IPC thread args: %s",
                            argv[i]);
                    exit(IPC_ERR_DOUBLE_ARG);
                }
                // Parse IPC thread arguments
                char* ipc_args = argv[i] + strlen(IPC_FLAG) + 1;
                targs.tx = strtok(ipc_args, ",");
                targs.rx = strtok(NULL, ",");
                // Initialize IO thread which will handle TX, RX pipes
                pthread_create(&thread, NULL, *ipc_thread_handle,
                               (void*)&targs);
                printf(
                    "[IPC] Thread launched with TX FIFO `%s`, RX FIFO `%s`\n",
                    targs.tx, targs.rx);
                active = true;
            }
        }
    }

    // Conditionally destroy IPC iff it is enabled
    ~IpcIface() {
        if (active) {
            pthread_join(thread, NULL);
            printf("[IPC] Thread joined\n");
            active = false;
        }
    }
};
