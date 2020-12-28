# Copyright 2020 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

# Docker container for Snitch development.

# 1. Stage
FROM ubuntu:18.04 AS builder

ARG SPIKE_VERSION=641d7d03e6a8d822b720fcb1a19f261813c00c4a

COPY apt-requirements.txt /tmp/apt-requirements.txt
RUN apt-get update && \
    sed 's/#.*//' /tmp/apt-requirements.txt \
        | xargs apt-get install -y && \
    apt-get install -y \
        build-essential \
        curl \
        git \
        gnupg2 \
        lsb-release \
        software-properties-common \
        unzip \
        wget \
        zlib1g-dev

# Build Rust tools
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH "/root/.cargo/bin:${PATH}"
RUN cargo install bender

# Get LLVM 10
RUN wget https://apt.llvm.org/llvm.sh
RUN chmod +x llvm.sh
RUN ./llvm.sh 10

# Install `banshee`
COPY sw/banshee /tmp/banshee
RUN cargo install --path /tmp/banshee

# Build `riscv-isa-sim`
RUN git clone https://github.com/riscv/riscv-isa-sim.git
RUN cd riscv-isa-sim && git checkout ${SPIKE_VERSION} && ./configure --prefix=/root/riscv && make install -s

# 2. Stage
FROM ubuntu:18.04 AS snitch
ARG RISCV_GCC_VERSION=8.3.0-2020.04.0
ARG VERIBLE_VERSION=0.0-776-g09e0b87
ARG VERILATOR_VERSION=4.100

LABEL version="0.1"
LABEL description="Snitch container for hardware and software development."
LABEL maintainer="zarubaf@iis.ee.ethz.ch"
LABEL org.opencontainers.image.source https://github.com/pulp-platform/snitch

WORKDIR /tools

# Install (and cleanup) required packages (from apt-requirements.txt)
# The list of extra packages is leftover from before this Dockerfile used
# apt-requirements.txt
#
COPY apt-requirements.txt /tmp/apt-requirements.txt
RUN apt-get update && \
    sed 's/#.*//' /tmp/apt-requirements.txt \
        | xargs apt-get install -y && \
    apt-get install -y --no-install-recommends \
        gnupg2 \
        curl \
        wget \
        git && \
    apt-get clean ; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

# Install Verilator
RUN echo 'deb http://download.opensuse.org/repositories/home:/phiwag:/edatools/xUbuntu_18.04/ /' | tee /etc/apt/sources.list.d/home:phiwag:edatools.list && \
    curl -fsSL https://download.opensuse.org/repositories/home:phiwag:edatools/xUbuntu_18.04/Release.key | gpg2 --dearmor | tee /etc/apt/trusted.gpg.d/home_phiwag_edatools.gpg > /dev/null && \
    apt-get update && apt-get install -y verilator-${VERILATOR_VERSION} && \
    apt-get clean ; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

# Copy repository into tmp directory to execute additional install steps.
COPY python-requirements.txt /tmp/python-requirements.txt
RUN pip3 install -r /tmp/python-requirements.txt

# Get the precompiled toolchain
RUN wget https://static.dev.sifive.com/dev-tools/riscv64-unknown-elf-gcc-${RISCV_GCC_VERSION}-x86_64-linux-ubuntu14.tar.gz && \
    mkdir -p riscv && tar -x -f riscv64-unknown-elf-gcc-${RISCV_GCC_VERSION}-x86_64-linux-ubuntu14.tar.gz --strip-components=1 -C riscv && \
    rm -rf riscv64-unknown-elf-gcc-${RISCV_GCC_VERSION}-x86_64-linux-ubuntu14.tar.gz
ENV PATH "/tools/riscv/bin:${PATH}"

# Install Verible
RUN wget https://github.com/google/verible/releases/download/v${VERIBLE_VERSION}/verible-v${VERIBLE_VERSION}-Ubuntu-18.04-bionic-x86_64.tar.gz && \
    tar -x -f verible-v${VERIBLE_VERSION}-Ubuntu-18.04-bionic-x86_64.tar.gz --strip-components=1 -C . && \
    rm -rf verible-v${VERIBLE_VERSION}-Ubuntu-18.04-bionic-x86_64.tar.gz
ENV PATH "/tools/bin:${PATH}"

COPY --from=builder /root/.cargo/bin/banshee bin/
COPY --from=builder /root/.cargo/bin/bender bin/
COPY --from=builder /root/riscv riscv/
